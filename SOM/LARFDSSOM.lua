require 'math'
require 'torch'
--require 'cutorch'

--[[
melhoras
ao remover nos, ao inves de "repassar" a lista inteira, trocar elemento retirado pelo ultimo
atualizar vizinhanca de um jeito melhor
pra atualizar protos e distances, fazer de forma x = x + e*delta, pra poder aplicar pra todo mundo
_wins e _neighbors como tensors ou arrays?
pra atualizar relevances, atualizar pra todo mundo e nao so pros vizinhos?
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

--[[
function LARFDSSOM:update_tensors()
	self.protos = torch.Tensor(self.nmax, self.dim)
	self.distances = torch.Tensor(self.nmax, self.dim)
	self.relevances = torch.Tensor(self.nmax, self.dim)
	self.wins = torch.IntTensor(self.nmax)
	self.neighbors = torch.ByteTensor(self.nmax, self.nmax)
end
]]--

--update all connections between node i and previous nodes
function LARFDSSOM:update_connections(i)
	self._neighbors[i][i] = 0
	for j = 1, i-1 do
		local dif = self._relevances[i] - self._relevances[j]
		local neigh = (torch.norm(dif) < self.conn_thr) and 1 or 0
		self._neighbors[i][j] = neigh
		self._neighbors[j][i] = neigh
	end
end

function LARFDSSOM:update_all_connections()
	for i = 1, self.n do
		self:update_connections(i)
	end
end

function LARFDSSOM:new_node(row, wins)
	self.n = self.n + 1
	local n = self.n
	self._protos[n]:copy(row)
	self._distances[n]:fill(0)
	self._relevances[n]:fill(1)
	self._wins[n] = math.ceil(wins)
	self:update_connections(n)
end

function LARFDSSOM:remove_nodes(rounds)
	local n = 0
	for i = 1, self.n do
		--keep at least one
		local keep_this = (i == self.n and n == 0)
		if keep_this or (self._wins[i] >= self.lp*rounds) then
			n = n+1
			if n ~= i then
				self._protos[n]:copy(self._protos[i])
				self._distances[n]:copy(self._distances[i])
				self._relevances[n]:copy(self._relevances[i])
				self._wins[n] = self._wins[i]
			end
		end
	end
	self.n = n
	self:update_all_connections()
end

function LARFDSSOM:calculate_activation(pattern)
	local s, as, act = 0, -1, torch.Tensor(self.n)
	for i = 1, self.n do
		local dif = torch.pow(pattern - self._protos[i], 2)
		local rel = self._relevances[i]
		dif:cmul(rel)
		local dw = torch.sum(dif)--math.sqrt()
		local rel_norm = torch.sum(rel)--torch.pow(rel, 2))
		local ai = 1/(1 + dw/(rel_norm + self.eps))

		act[i] = ai
		if ai > as then
			s, as = i, ai
		end
	end
	return s, as, act
end

function LARFDSSOM:interp(a, b, r)
	return (a*(1-r)) + (b*r)
end

function LARFDSSOM:get_learning_rate(s, i)
	if i == s then return self.eb
	elseif self._neighbors[s][i] ~= 0 then return self.en
	else return 0 end
end

function LARFDSSOM:update_winner(pattern, s)
	for i = 1, self.n do
		local e = self:get_learning_rate(s, i)
		if e ~= 0 then
			local dist = self._distances[i]
			local dif = torch.abs(pattern - self._protos[i])
			dist:copy(self:interp(dist, dif, e*self.beta))

			local rel = self._relevances[i]
			local mean, rng = torch.mean(dist), torch.max(dist) - torch.min(dist)
			if rng < self.eps then
				rel:fill(1)
			else
				rel = dist - mean--oppose than article
				rel:div(self.slope * rng)
				rel = torch.exp(rel) + 1
				rel:cinv()
			end

			local proto = self._protos[i]
			proto:copy(self:interp(proto, pattern, e))
		end
	end
end

function LARFDSSOM:training_step()
	self.nwins = self.nwins + 1
	local idx = torch.random(1, self.dn)
	local pattern = self.data[idx]
	local s, as = self:calculate_activation(pattern)

	if as < self.at then
		if self.n < self.nmax then
			self:new_node(pattern, self.lp*self.nwins)
		end
	else
		self:update_winner(pattern, s)
		self._wins[s] = self._wins[s] + 1
	end

	if self.nwins == self.maxcomp then
		self:remove_nodes(self.nwins)
		self._wins:fill(0)
		self.nwins = 0
	end
end

function LARFDSSOM:organization()
	self:new_node(self.data[1], 0)
	self.nwins = 0

	for t = 1, self.tmax do
		self:training_step()
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

		for i = 1, self.n do
			self:update_connections(i)
		end
		self._wins:fill(0)

		for t = 1, self.tmax do
			local pattern = self.data[torch.random(1, self.dn)]
			local s, as = self:calculate_activation(pattern)
			self:update_winner(pattern, s)
			self._wins[s] = self._wins[s] + 1
		end
	end
end
]]--

function LARFDSSOM:classify(pattern)
	local s, as, act = self:calculate_activation(pattern)
	if as < self.at then--outlier
		return {}
	elseif self.projected then--single winner
		return {s}
	else
		local clusters = {}
		for i = 1, self.n do
			if act[i] >= self.at then
				table.insert(clusters, i)
			end
		end
		return clusters
	end
end

function LARFDSSOM:get_clusters(raw_data)
	self.data = torch.Tensor(raw_data)
	self.dn = self.data:size(1)
	self.dim = self.data:size(2)
	self.conn_thr = self.conn_thr*math.sqrt(self.dim)

	self.n = 0
	--allocate maximum size, but don't necessarily use it all
	self._protos = torch.Tensor(self.nmax, self.dim)
	self._distances = torch.Tensor(self.nmax, self.dim)
	self._relevances = torch.Tensor(self.nmax, self.dim)
	self._wins = torch.IntTensor(self.nmax)
	self._neighbors = torch.ByteTensor(self.nmax, self.nmax)

	self:organization()
	self:convergence()

	local clusters = {}
	for i = 1, self.dn do
		table.insert(clusters, self:classify(self.data[i]))
	end
	return clusters
end

