require 'math'
require 'torch'
--require 'cutorch'

torch.setdefaulttensortype('torch.FloatTensor')

--[[
todo
tentar fazer operacoes in-place
conferir problemas com atribuicoes e referencias

melhorias
precalcular soma das relevances?

escolher direitinho quais tensores botar na gpu
half-precision floats
aproveitar localidade da cache guardando os dados de um neuronio juntos
]]--

LARFDSSOM = {}
LARFDSSOM.__index = LARFDSSOM
LARFDSSOM.eps = 1e-9

function LARFDSSOM:new(params)
	local o = {
		tmax = params.tmax,
		_nmax = params.nmax,
		at = params.at,
		lp = params.lp,
		maxcomp = params.maxcomp,
		eb = params.eb,
		en = params.en,
		beta = params.beta,
		slope = params.slope,
		_conn_thr = params.conn_thr,

		--projected = params.projected or false,
		cuda = params.cuda or false
	}
	setmetatable(o, self)
	return o
end

function LARFDSSOM:allocate_tensors()
	--allocate maximum size, but don't necessarily use it all
	if self.cuda then
		self._protos = torch.CudaTensor(self.nmax, self.dim)
		self._distances = torch.CudaTensor(self.nmax, self.dim)
		self._relevances = torch.CudaTensor(self.nmax, self.dim)
		self._wins = torch.CudaIntTensor(self.nmax)
		self._neighbors = torch.CudaByteTensor(self.nmax, self.nmax)
	else
		self._protos = torch.Tensor(self.nmax, self.dim)
		self._distances = torch.Tensor(self.nmax, self.dim)
		self._relevances = torch.Tensor(self.nmax, self.dim)
		self._wins = torch.IntTensor(self.nmax)
		self._neighbors = torch.ByteTensor(self.nmax, self.nmax)
	end
	self:resize(0)
end

function LARFDSSOM:resize(n)
	self.n = n
	if n == 0 then return end

	self.protos = self._protos:narrow(1, 1, n)
	self.distances = self._distances:narrow(1, 1, n)
	self.relevances = self._relevances:narrow(1, 1, n)
	self.wins = self._wins:narrow(1, 1, n)
	self.neighbors = self._neighbors
		:narrow(1, 1, n)
		:narrow(2, 1, n)
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

--select a subset of the rows of a tensor
function LARFDSSOM:filter(tns, idxs)
	local n = idxs:size(1)
	local tmp = tns:index(1, idxs)
	tns:narrow(1, 1, n)
		:copy(tmp)
end

function LARFDSSOM:remove_nodes(rounds)
	local idxs = self.wins:ge(self.lp*rounds):nonzero()
	--must have at least one neuron
	if idxs:nElement() == 0 then
		if self.cuda then
			idxs = torch.CudaLongTensor({1})
		else
			idxs = torch.LongTensor({1})
		end
	else
		idxs = idxs:squeeze(2)
	end

	self:filter(self.protos, idxs)
	self:filter(self.distances, idxs)
	self:filter(self.relevances, idxs)

	self:resize(idxs:size(1))
	self:update_all_connections()
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
	self.neighbors[i][i] = 1
	if i == 1 then return end
	local rel = self.relevances
		:narrow(1, i, 1)
		:expand(i-1, self.dim)

	local r_dif = self.relevances:narrow(1, 1, i-1) - rel
	local r_dist = r_dif:norm(2, 2):squeeze(2)

	local neigh = r_dist:lt(self.conn_thr)
	self.neighbors:select(1, i)
		:narrow(1, 1, i-1)
		:copy(neigh)
	self.neighbors:select(2, i)
		:narrow(1, 1, i-1)
		:copy(neigh)
end
--[[
function LARFDSSOM:update_connections(i)
	self.neighbors[i][i] = 1
	for j = 1, i-1 do
		local dif = self.relevances[i] - self.relevances[j]
		local neigh = (dif:norm() < self.conn_thr) and 1 or 0
		self.neighbors[i][j] = neigh
		self.neighbors[j][i] = neigh
	end
end
]]--

function LARFDSSOM:update_all_connections()
	local t1 = self.relevances:view(self.n, 1, self.dim)
		:expand(self.n, self.n, self.dim)
	local t2 = self.relevances:view(1, self.n, self.dim)
		:expand(self.n, self.n, self.dim)

	local norm = (t1-t2):norm(2, 3):squeeze(3)
	local neigh = norm:lt(self.conn_thr)
	self.neighbors:copy(neigh)
end
--[[
function LARFDSSOM:update_all_connections()
	for i = 1, self.n do
		self:update_connections(i)
	end
end
]]--


function LARFDSSOM:calculate_activation(pattern)
	pattern = pattern:view(1, self.dim)
		:expand(self.n, self.dim)

	local p_dif = pattern - self.protos
	p_dif:pow(2)
	p_dif:cmul(self.relevances)
	local act = p_dif:sum(2):squeeze(2)
	local rel_norm = self.relevances:sum(2):squeeze(2) + self.eps
	act:cdiv(rel_norm)
	act:add(1)
	act:cinv()

	return act
end
--[[
function LARFDSSOM:calculate_activation(pattern)
	local act = nil
	if self.cuda then
		act = torch.CudaTensor(self.n)
	else
		act = torch.Tensor(self.n)
	end

	for i = 1, self.n do
		local dif = pattern - self.protos[i]
		dif:pow(2)
		local rel = self.relevances[i]
		dif:cmul(rel)
		local dw = dif:sum()--math.sqrt()
		local rel_norm = rel:sum() + self.eps--torch.pow(rel, 2))
		act[i] = 1/(1 + dw/rel_norm)
	end

	return act
end
]]--

function LARFDSSOM:get_neighborhood(s)
	local idx = self.neighbors[s]:nonzero()
	if idx:nElement() == 0 then
		if self.cuda then
			idx = torch.CudaLongTensor({s})
		else
			idx = torch.LongTensor({s})
		end
	else
		idx = idx:squeeze(2)
	end
	local nn, sidx = idx:size(1), 1
	while idx[sidx] ~= s do sidx = sidx+1 end
	local lr = nil
	if self.cuda then
		lr = torch.CudaTensor(nn)
	else
		lr = torch.Tensor(nn)
	end
	lr:fill(self.en)
	lr[sidx] = self.eb
	return idx, lr, nn
end

function LARFDSSOM:get_learning_rates(s)
	local lr = self.neighbors[s]:type('torch.FloatTensor')
	if self.cuda then
		lr = lr:cuda()
	end
	lr:mul(self.en)
	lr[s] = self.eb
	return lr
end

function LARFDSSOM:interp(a, b, r)
	return (a*(1-r)) + (b*r)
end

function LARFDSSOM:update_relevances(distances, relevances)
	local mx = distances:max(2)
	local mn = distances:min(2)
	mx, mn = mx:squeeze(2), mn:squeeze(2)
	local rng = mx-mn

	local idx = rng:lt(self.eps):nonzero()
	if idx:nElement() > 0 then
		idx = idx:squeeze(2)
		relevances:indexFill(1, idx, 1)
	end

	local idx = rng:ge(self.eps):nonzero()
	if idx:nElement() > 0 then
		idx = idx:squeeze(2)
		local nn = idx:size(1)
		distances = distances:index(1, idx)
		local mean = distances:mean(2)
			:expand(nn, self.dim)
		rng = rng:index(1, idx)
			:view(nn, 1)
			:expand(nn, self.dim)
		rng:mul(self.slope)

		local rel = distances
		rel:csub(mean)
		rel:cdiv(rng)
		rel:exp()
		rel:add(1)
		rel:cinv()
		relevances:indexCopy(1, idx, rel)
	end
end
--[[
function LARFDSSOM:update_relevances(distances, relevances)
	local nn = relevances:size(1)
	local mean = distances:mean(2):squeeze(2)
	local mx = distances:max(2)
	local mn = distances:min(2)
	mx, mn = mx:squeeze(2), mn:squeeze(2)
	local rng = mx-mn

	for i = 1, nn do
		local rel = relevances[i]
		if rng[i] < self.eps then rel:fill(1)
		else
			rel = distances[i] - mean[i]--opposit of article
			rel:div(self.slope * rng[i])
			rel:exp()
			rel:add(1)
			rel:cinv()
			relevances[i]:copy(rel)
		end
	end
end
]]--


function LARFDSSOM:update_winner(pattern, s)
	local idx, lr, nn = self:get_neighborhood(s)
	lr = lr:view(nn, 1)
		:expand(nn, self.dim)
	local neigh_distances = self.distances:index(1, idx)
	local neigh_relevances = self.relevances:index(1, idx)
	local neigh_protos = self.protos:index(1, idx)

	pattern = pattern:view(1, self.dim)
		:expand(nn, self.dim)
	local dif = torch.abs(pattern - neigh_protos)
	neigh_distances:addcmul(self.beta, dif - neigh_distances, lr)

	self:update_relevances(neigh_distances, neigh_relevances)

	neigh_protos:addcmul(pattern - neigh_protos, lr)

	self.distances:indexCopy(1, idx, neigh_distances)
	self.relevances:indexCopy(1, idx, neigh_relevances)
	self.protos:indexCopy(1, idx, neigh_protos)
end
--[[
function LARFDSSOM:update_winner(pattern, s)
	local lr = self:get_learning_rates(s)
		:view(self.n, 1)
		:expand(self.n, self.dim)

	pattern = pattern:view(1, self.dim)
		:expand(self.n, self.dim)
	local dif = torch.abs(pattern - self.protos)
	self.distances:addcmul(self.beta, dif - self.distances, lr)

	local mean = self.distances:mean(2):squeeze(2)
	local mx = self.distances:max(2)
	local mn = self.distances:min(2)
	mx, mn = mx:squeeze(2), mn:squeeze(2)
	local rng = mx-mn

	for i = 1, self.n do
		if self.neighbors[s][i] ~= 0 then
			local rel = self.relevances[i]
			if rng[i] < self.eps then rel:fill(1)
			else
				rel = self.distances[i] - mean[i]--opposit of article
				rel:div(self.slope * rng[i])
				rel:exp()
				rel:add(1)
				rel:cinv()
				self.relevances[i]:copy(rel)
			end
		end
	end

	self.protos:addcmul(pattern - self.protos, lr)
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
				rel:exp()
				rel:add(1)
				rel:cinv()
				self.relevances[i]:copy(rel)
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

	local act = self:calculate_activation(pattern)
	local mx, mi = act:max(1)
	local as, s = mx[1], mi[1]
	--[[local as, s = -1, 0
	for i = 1, self.n do
		if act[i] > as then
			as, s = act[i], i
		end
	end]]--

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
--[[
same as article
function LARFDSSOM:convergence()
	while true do
		local oldn = self.n
		--TODO: remove nodes
		if self.n == oldn or self.n == 1 then return end

		self:update_all_connections()
		self.wins:fill(0)

		for t = 1, self.tmax do
			local idx = torch.random(1, self.dn)
			local pattern = self.data[idx]
			local act = self:calculate_activation(pattern)
			local mx, mi = act:max(1)
			local as, s = mx[1], mi[1]
			self:update_winner(pattern, s)
			self.wins[s] = self.wins[s] + 1
		end
	end
end
]]--

--calculates activation for all data patterns
function LARFDSSOM:get_assignments()
	local data = self.data
		:view(self.dn, 1, self.dim)
		:expand(self.dn, self.n, self.dim)
	local protos = self.protos
		:view(1, self.n, self.dim)
		:expand(self.dn, self.n, self.dim)
	local rel = self.relevances
		:view(1, self.n, self.dim)
		:expand(self.dn, self.n, self.dim)

	local dif = data - protos
	dif:pow(2)
	dif:cmul(rel)
	local act = dif:sum(3):squeeze(3)
	local rel_norm = self.relevances:sum(2) + self.eps
	rel_norm = rel_norm
		:view(1, self.n)
		:expand(self.dn, self.n)
	act:cdiv(rel_norm)
	act:add(1)
	act:cinv()

	return act:ge(self.at):nonzero()
end

function LARFDSSOM:normalize_data()
	local mx = self.data:max(1)
	local mn = self.data:min(1)
	local rng = mx-mn

	--deal with columns with equal values
	local rng_flat = rng:squeeze(1)
	local zero_cols = rng_flat
		:lt(self.eps):nonzero()
	zero_cols:apply(function(i)
		self.data:select(2, i):fill(0)
		rng_flat[i] = 1
	end)

	mn = mn:expand(self.dn, self.dim)
	rng = rng:expand(self.dn, self.dim)
	self.data:csub(mn)
	self.data:cdiv(rng)
end

function LARFDSSOM:process(raw_data)
	if self.cuda then
		self.data = torch.CudaTensor(raw_data)
	else
		self.data = torch.Tensor(raw_data)
	end
	self.dn = self.data:size(1)
	self.dim = self.data:size(2)
	self:normalize_data()

	self.conn_thr = self._conn_thr*math.sqrt(self.dim)
	self.nmax = self._nmax
	self:allocate_tensors()

	--organization
	self:new_node(self.data[1], 0)
	self.nwins = 0
	for t = 1, self.tmax do
		self:training_step()
	end

	--convergence
	self:convergence()

	--clustering
	return self:get_assignments()
end

