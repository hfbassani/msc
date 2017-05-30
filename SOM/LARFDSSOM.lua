require 'math'
require 'torch'
--require 'cutorch'

--[[
melhoras
como atualizar relevances?
testar localidade da cache guardando os dados de um neuronio juntos
]]--

LARFDSSOM = {}
LARFDSSOM.__index = LARFDSSOM
LARFDSSOM.eps = 1e-9

function LARFDSSOM:new(params)
	o = {
		tmax = params.tmax,
		nmax = params.nmax,
		at = params.at,
		lp = params.lp,
		maxcomp = params.maxcomp,
		eb = params.eb,
		en = params.en,
		beta = params.beta,
		slope = params.slope,
		conn_thr = params.conn_thr,

		projected = params.projected or false
	}
	setmetatable(o, self)
	return o
end

function LARFDSSOM:resize(n)
	self.n = n
	if n == 0 then return end

	self.protos = self._protos[{{1, n}}]
	self.distances = self._distances[{{1, n}}]
	self.relevances = self._relevances[{{1, n}}]
	self.wins = self._wins[{{1, n}}]
	self.neighbors = self._neighbors[{{1, n}, {1, n}}]
end

function LARFDSSOM:allocate_data(dim)
	--allocate maximum size, but don't necessarily use it all
	self._protos = torch.Tensor(self.nmax, self.dim)
	self._distances = torch.Tensor(self.nmax, self.dim)
	self._relevances = torch.Tensor(self.nmax, self.dim)
	self._wins = torch.IntTensor(self.nmax)
	self._neighbors = torch.ByteTensor(self.nmax, self.nmax)
	self:resize(0)
end

function LARFDSSOM:new_node(row, wins)
	self:resize(self.n + 1)
	local i = self.n
	self.protos[i]:copy(row)
	self.distances[i]:fill(0)
	self.relevances[i]:fill(1)
	self.wins[i] = math.ceil(wins)
	self:update_connections(i)
end

function LARFDSSOM:reorder(tns, idxs, n)
	local tmp = tns:index(1, idxs)
	tns[{{1, n}}]:copy(tmp)
end

function LARFDSSOM:reorder_connections(idxs, n)
	local tmp = self.neighbors:index(1, idxs)
	self.neighbors[{{1, n}, {}}]:copy(tmp)
	tmp = self.neighbors:index(2, idxs)
	self.neighbors[{{}, {1, n}}]:copy(tmp)
end

function LARFDSSOM:remove_nodes(rounds)
	local idxs = self.wins:ge(self.lp*rounds):nonzero()
	--must have at least one neuron
	if idxs:nElement() == 0 then
		idxs = torch.LongTensor({1})
	end
	local n = idxs:size(1)
	idxs:resize(n)

	self:reorder(self.protos, idxs, n)
	self:reorder(self.distances, idxs, n)
	self:reorder(self.relevances, idxs, n)

	self:reorder_connections(idxs, n)
	self:resize(n)
	--self:resize(n)
	--self:update_all_connections()
end
--[[
function LARFDSSOM:remove_nodes(rounds)
	local i, n = 1, self.n
	while i <= n do
		--should keep at least one
		if (n > 1) and (self.wins[i] < self.lp*rounds) then
			if i ~= n then
				self.protos[i]:copy(self.protos[n])
				self.distances[i]:copy(self.distances[n])
				self.relevances[i]:copy(self.relevances[n])
				self.wins[i] = self.wins[n]
			end
			i, n = i-1, n-1
		end
		i = i+1
	end
	self:resize(n)
	self:update_all_connections()
end
]]--

--update all connections between node i and previous nodes
function LARFDSSOM:update_connections(i)
	if i == 1 then return end
	local rel = self.relevances[i]
	rel:resize(1, self.dim)
	rel = rel:expand(i-1, self.dim)

	local r_dif = self.relevances[{{1, i-1}, {}}] - rel
	local r_dist = torch.norm(r_dif, 2, 2)
	r_dist:resize(i-1)

	local neigh = r_dist:lt(self.conn_thr)
	self.neighbors[{i, {1, i-1}}]:copy(neigh)
	self.neighbors[{{1, i-1}, i}]:copy(neigh)
end
--[[
function LARFDSSOM:update_connections(i)
	for j = 1, i do
		local dif = self.relevances[i] - self.relevances[j]
		local neigh = (torch.norm(dif) < self.conn_thr) and 1 or 0
		self.neighbors[i][j] = neigh
		self.neighbors[j][i] = neigh
	end
end
]]--

function LARFDSSOM:update_all_connections()
	for i = 1, self.n do
		self:update_connections(i)
	end
end

function LARFDSSOM:calculate_activation(pattern)
	pattern:resize(1, self.dim)
	pattern = pattern:expand(self.n, self.dim)

	local p_dif = torch.pow(pattern - self.protos, 2)
	p_dif:cmul(self.relevances)
	local p_dist = torch.sum(p_dif, 2)
	p_dist:resize(self.n)
	local rel_norm = torch.sum(self.relevances, 2)
	rel_norm:resize(self.n)
	local act = torch.cdiv(p_dist, rel_norm + self.eps) + 1
	act:cinv()

	local mx, mi = torch.max(act, 1)
	return mx[1], mi[1], act
end
--[[
function LARFDSSOM:calculate_activation(pattern)
	local act = torch.Tensor(self.n)
	for i = 1, self.n do
		local dif = torch.pow(pattern - self.protos[i], 2)
		local rel = self.relevances[i]
		dif:cmul(rel)
		local dw = torch.sum(dif)--math.sqrt()
		local rel_norm = torch.sum(rel)--torch.pow(rel, 2))
		act[i] = 1/(1 + dw/(rel_norm + self.eps))
	end

	local s, as = 0, -1
	for i = 1, self.n do
		if act[i] > as then
			s, as = i, act[i]
		end
	end
	return as, s, act
end
]]--

function LARFDSSOM:get_learning_rates(s)
	local lr = self.neighbors[s]:type('torch.DoubleTensor')
	lr:apply(function(x) return x*self.en end)
	lr[s] = self.eb
	return lr
end


function LARFDSSOM:interp(a, b, r)
	return torch.cmul(a, -r + 1) + torch.cmul(b, r)
end

function LARFDSSOM:update_winner(pattern, s)
	local lr = self:get_learning_rates(s)
	lr:resize(self.n, 1)
	lr = lr:expand(self.n, self.dim)

	pattern:resize(1, self.dim)
	pattern = pattern:expand(self.n, self.dim)
	local dif = torch.abs(pattern - self.protos)
	self.distances:copy(self:interp(self.distances, dif, lr*self.beta))

	local mean = self.distances:mean(2)
	mean:resize(self.n)

	mx, mxi = self.distances:max(2)
	mn, mni = self.distances:min(2)
	local rng = mx-mn
	rng:resize(self.n)

	for i = 1, self.n do
		local rel = self.relevances[i]
		if rng[i] < self.eps then rel:fill(1)
		else
			rel = self.distances[i] - mean[i]--opposit of article
			rel:div(self.slope * rng[i])
			rel = torch.exp(rel) + 1
			rel:cinv()
		end
	end

	self.protos:copy(self:interp(self.protos, pattern, lr))
end
--[[
function LARFDSSOM:interp(a, b, r)
	return (a*(1-r)) + (b*r)
end

function LARFDSSOM:update_winner(pattern, s)
	local lr = self:get_learning_rates(s)
	for i = 1, self.n do
		local e = lr[i]
		if e ~= 0 then
			local dist = self.distances[i]
			local rel = self.relevances[i]
			local proto = self.protos[i]

			local dif = torch.abs(pattern - proto)
			dist:copy(self:interp(dist, dif, e*self.beta))

			local mean, rng = dist:mean(), dist:max() - dist:min()
			if rng < self.eps then rel:fill(1)
			else
				rel = dist - mean--opposit of article
				rel:div(self.slope * rng)
				rel = torch.exp(rel) + 1
				rel:cinv()
			end

			proto:copy(self:interp(proto, pattern, e))
		end
	end
end
]]--

function LARFDSSOM:training_step()
	self.nwins = self.nwins + 1
	local idx = torch.random(1, self.dn)
	local pattern = self.data[idx]
	local as, s = self:calculate_activation(pattern)

	if as < self.at then
		if self.n < self.nmax then
			self:new_node(pattern, self.lp*self.nwins)
		end
	else
		self:update_winner(pattern, s)
		self.wins[s] = self.wins[s] + 1
	end

	if self.nwins == self.maxcomp then
		self:remove_nodes(self.nwins)
		self.wins:fill(0)
		self.nwins = 0
	end
end

--same as original implementation
function LARFDSSOM:convergence()
	while self.nwins ~= 0 do
		self:training_step()
	end

	self.nmax = self.n

	self:training_step()
	while self.nwins ~= 0 do
		self:training_step()
	end
end
--[[same as article
function LARFDSSOM:convergence()
	while true do
		local oldn = self.n
		--TODO: remove nodes
		if self.n == oldn or self.n == 1 then return end

		self:update_all_connections()
		self.wins:fill(0)

		for t = 1, self.tmax do
			local pattern = self.data[torch.random(1, self.dn)]
			local as, s = self:calculate_activation(pattern)
			self:update_winner(pattern, s)
			self.wins[s] = self.wins[s] + 1
		end
	end
end
]]--

function LARFDSSOM:classify(pattern)
	local as, s, act = self:calculate_activation(pattern)
	if as < self.at then--outlier
		return {}
	elseif self.projected then--single winner
		return {s}
	else
		local idx, clusters = act:ge(self.at):nonzero(), {}
		idx:apply(function(i)
			table.insert(clusters, i)
		end)
		return clusters
	end
end

function LARFDSSOM:get_clusters(raw_data)
	self.data = torch.Tensor(raw_data)
	self.dn = self.data:size(1)

	self.dim = self.data:size(2)
	self.conn_thr = self.conn_thr*math.sqrt(self.dim)
	self:allocate_data()

	--organization
	self:new_node(self.data[1], 0)
	self.nwins = 0
	for t = 1, self.tmax do
		self:training_step()
	end

	--convergence
	self:convergence()

	local clusters = {}
	for i = 1, self.dn do
		table.insert(clusters, self:classify(self.data[i]))
	end
	return clusters
end

