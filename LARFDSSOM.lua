require 'math'
require 'torch'
require 'cutorch'

torch.setdefaulttensortype('torch.FloatTensor')

--[[
tmp tensors
talvez tirar os que tem dimensao dn_or_n

todo
tentar fazer operacoes in-place
conferir problemas com atribuicoes e referencias

half-precision floats
escolher direitinho quais tensores botar na gpu
aproveitar localidade da cache guardando os dados de um neuronio juntos
atualizar separadamente o vencedor e os vizinhos
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

		projected = params.projected,
		noise_filter = params.noise_filter,
		tmp = {},
		cuda = params.cuda or true
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
		self._relevance_sums = torch.CudaTensor(self.nmax)
		self._wins = torch.CudaIntTensor(self.nmax)
		self._neighbors = torch.CudaByteTensor(self.nmax, self.nmax)
	else
		self._protos = torch.Tensor(self.nmax, self.dim)
		self._distances = torch.Tensor(self.nmax, self.dim)
		self._relevances = torch.Tensor(self.nmax, self.dim)
		self._relevance_sums = torch.Tensor(self.nmax)
		self._wins = torch.IntTensor(self.nmax)
		self._neighbors = torch.ByteTensor(self.nmax, self.nmax)
	end
	self:resize(0)
end

function LARFDSSOM:alloc(id, sizes)
	local lt = torch.LongStorage(sizes)
	if self.cuda then self.tmp[id] = torch.CudaTensor(lt)
	else self.tmp[id] = torch.Tensor(lt)
	end
end

--next tmp: 23
function LARFDSSOM:allocate_temp_tensors()
	local dn_or_n = math.max(self.dn, self.nmax)
	self:alloc(1, {self.nmax, self.dim})
	self:alloc(2, {self.nmax, 1})
	self:alloc(3, {dn_or_n, self.nmax, self.dim})
	self:alloc(4, {dn_or_n, self.nmax, 1})
	self:alloc(5, {self.nmax, self.dim})
	self:alloc(6, {self.nmax, 1})
	self:alloc(7, {self.nmax})
	self:alloc(8, {dn_or_n, 1})
	self:alloc(9, {self.nmax, 1})
	self:alloc(11, {self.nmax})
	self:alloc(12, {self.nmax, self.dim})
	self:alloc(13, {self.nmax, 1})
	self:alloc(14, {self.nmax})
	self:alloc(15, {self.nmax, self.dim})
	self:alloc(16, {self.nmax, self.dim})
	self:alloc(17, {self.nmax, self.dim})
	self:alloc(18, {self.nmax, self.dim})
	self:alloc(19, {self.nmax, 1})

	if self.cuda then
		self.tmp[10] = torch.CudaLongTensor(dn_or_n, 1)
		self.tmp[20] = torch.CudaByteTensor(self.nmax)
		self.tmp[21] = torch.CudaByteTensor(self.nmax, self.nmax)
		self.tmp[22] = torch.CudaLongTensor(dn_or_n, 1)
	else
		self.tmp[10] = torch.LongTensor(dn_or_n, 1)
		self.tmp[20] = torch.ByteTensor(self.nmax)
		self.tmp[21] = torch.ByteTensor(self.nmax, self.nmax)
		self.tmp[22] = torch.LongTensor(dn_or_n, 1)
	end
end

function LARFDSSOM:get_tmp1(id, m)
	return self.tmp[id]
		:narrow(1, 1, m)
end

function LARFDSSOM:get_tmp2(id, m, n)
	return self.tmp[id]
		:narrow(1, 1, m)
		:narrow(2, 1, n)
end

function LARFDSSOM:get_tmp3(id, m, n, o)
	return self.tmp[id]
		:narrow(1, 1, m)
		:narrow(2, 1, n)
		:narrow(3, 1, o)
end

function LARFDSSOM:resize(n)
	self.n = n
	if n == 0 then return end

	self.protos = self._protos:narrow(1, 1, n)
	self.distances = self._distances:narrow(1, 1, n)
	self.relevances = self._relevances:narrow(1, 1, n)
	self.relevance_sums = self._relevance_sums:narrow(1, 1, n)
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
	self.relevance_sums[i] = self.dim
	self.wins[i] = math.ceil(wins)
	self:update_connections(i)
end

--select a subset of the rows of a tensor
function LARFDSSOM:filter(tns, idxs, tmp)
	local n = idxs:size(1)
	tmp:index(tns, 1, idxs)
	tns:narrow(1, 1, n):copy(tmp)
end

--tmp tensors: 7, 10, 15 (reutilizing), 20
function LARFDSSOM:remove_nodes(rounds)
	local ge = self:get_tmp1(20, self.n)
	local idxs = self:get_tmp1(10, self.n)

	self.wins.ge(ge, self.wins, self.lp*rounds)
	ge.nonzero(idxs, ge)
	--must keep at least one neuron
	if idxs:nElement() == 0 then
		self:resize(1)
		self.neighbors[1][1] = 1
	else
		idxs = idxs:squeeze(2)
		local n = idxs:size(1)
		local tmp1 = self:get_tmp1(7, n)
		local tmp2 = self:get_tmp1(15, n)

		self:filter(self.protos, idxs, tmp2)
		self:filter(self.distances, idxs, tmp2)
		self:filter(self.relevances, idxs, tmp2)
		self:filter(self.relevance_sums, idxs, tmp1)

		self:resize(n)
		self:update_all_connections()
	end
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
				self.relevance_sums[i] = self.relevance_sums[n]
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

--tmp tensors: 20 (reutilizing), 1-2
--update all connections between node i and previous nodes
function LARFDSSOM:update_connections(i)
	self.neighbors[i][i] = 1
	if i == 1 then return end
	local rel = self.relevances
		:narrow(1, i, 1)
		:expand(i-1, self.dim)
	local rels = self.relevances
		:narrow(1, 1, i-1)

	local r_dif = self:get_tmp1(1, i-1)
	local r_dist = self:get_tmp1(2, i-1)
	r_dif:csub(rel, rels)
	r_dist:norm(r_dif, 2, 2)
	r_dist = r_dist:squeeze(2)

	local neigh = self:get_tmp1(20, i-1)
	r_dist.lt(neigh, r_dist, self.conn_thr)
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

--tmp tensors: 3-4, 21
function LARFDSSOM:update_all_connections()
	local t1 = self.relevances:view(self.n, 1, self.dim)
		:expand(self.n, self.n, self.dim)
	local t2 = self.relevances:view(1, self.n, self.dim)
		:expand(self.n, self.n, self.dim)

	local df = self:get_tmp2(3, self.n, self.n)
	local norm = self:get_tmp2(4, self.n, self.n)
	local neigh = self:get_tmp2(21, self.n, self.n)
	df:csub(t1, t2)
	norm:norm(df, 2, 3)
	norm = norm:squeeze(3)
	norm.lt(neigh, norm, self.conn_thr)
	self.neighbors:copy(neigh)
end
--[[
function LARFDSSOM:update_all_connections()
	for i = 1, self.n do
		self:update_connections(i)
	end
end
]]--

--tmp tensors: 5-6
function LARFDSSOM:calculate_activation(pattern)
	pattern = pattern:view(1, self.dim)
		:expand(self.n, self.dim)

	local p_dif = self:get_tmp1(5, self.n)
	local act = self:get_tmp1(6, self.n)
	p_dif:csub(pattern, self.protos)
	p_dif:pow(2)
	p_dif:cmul(self.relevances)
	act:sum(p_dif, 2)
	act = act:squeeze(2)
	act:cdiv(self.relevance_sums)
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
		local rel_norm = self.relevance_sums[i]--torch.pow(rel, 2))
		act[i] = 1/(1 + dw/rel_norm)
	end

	return act
end
]]--

--tmp tensors: 7, 22
function LARFDSSOM:get_neighborhood(s)
	local idx = self:get_tmp1(22, self.n)
	local neigh_s = self.neighbors[s]
	neigh_s.nonzero(idx, neigh_s)

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

	local lr = self:get_tmp1(7, nn)
	lr:fill(self.en)
	lr[sidx] = self.eb
	return idx, lr, nn
end

--not used
function LARFDSSOM:get_learning_rates(s)
	local lr = self.neighbors[s]:type('torch.FloatTensor')
	if self.cuda then
		lr = lr:cuda()
	end
	lr:mul(self.en)
	lr[s] = self.eb
	return lr
end

--not used
function LARFDSSOM:interp(a, b, r)
	return (a*(1-r)) + (b*r)
end

--tmp tensors: 20 (reutilizing), 8-14
function LARFDSSOM:update_relevances(distances, relevances)
	local n = distances:size(1)
	local mx = self:get_tmp1(8, n)
	local mn = self:get_tmp1(9, n)
	local rng = self:get_tmp1(11, n)
	local bool = self:get_tmp1(20, n)
	local idx = self:get_tmp1(10, n)

	torch.max(mx, idx, distances, 2)
	torch.min(mn, idx, distances, 2)
	mx, mn = mx:squeeze(2), mn:squeeze(2)
	rng:csub(mx, mn)

	rng.lt(bool, rng, self.eps)
	bool.nonzero(idx, bool)
	if idx:nElement() > 0 then
		idx = idx:squeeze(2)
		relevances:indexFill(1, idx, 1)
	end

	rng.ge(bool, rng, self.eps)
	bool.nonzero(idx, bool)
	if idx:nElement() > 0 then
		idx = idx:squeeze(2)
		local nn = idx:size(1)

		local dist2 = self:get_tmp1(12, nn)
		local mean = self:get_tmp1(13, nn)
		local rng2 = self:get_tmp1(14, nn)

		dist2:index(distances, 1, idx)
		mean:mean(dist2, 2)
		mean = mean:expand(nn, self.dim)

		rng2:index(rng, 1, idx)
		rng2:mul(self.slope)
		rng2 = rng2:view(nn, 1)
			:expand(nn, self.dim)

		local rel = dist2
		rel:csub(mean)
		rel:cdiv(rng2)
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

--tmp tensors: 15-19
function LARFDSSOM:update_winner(pattern, s)
	local idx, lr, nn = self:get_neighborhood(s)
	lr = lr:view(nn, 1)
		:expand(nn, self.dim)

	local neigh_distances = self:get_tmp1(15, nn)
	local neigh_relevances = self:get_tmp1(16, nn)
	local neigh_protos = self:get_tmp1(17, nn)
	neigh_distances:index(self.distances, 1, idx)
	neigh_relevances:index(self.relevances, 1, idx)
	neigh_protos:index(self.protos, 1, idx)

	pattern = pattern:view(1, self.dim)
		:expand(nn, self.dim)

	local dif = self:get_tmp1(18, nn)
	dif:csub(pattern, neigh_protos)
	neigh_protos:addcmul(dif, lr)

	dif:abs()
	dif:csub(neigh_distances)
	neigh_distances:addcmul(self.beta, dif, lr)

	self:update_relevances(neigh_distances, neigh_relevances)

	self.distances:indexCopy(1, idx, neigh_distances)
	self.relevances:indexCopy(1, idx, neigh_relevances)
	self.protos:indexCopy(1, idx, neigh_protos)

	local rel_sums = self:get_tmp1(19, nn)
	rel_sums:sum(neigh_relevances, 2)
	rel_sums = rel_sums:squeeze(2)
	rel_sums:add(self.eps)
	self.relevance_sums:indexCopy(1, idx, rel_sums)
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
			if rng[i] < self.eps then
				rel:fill(1)
				self.relevance_sums[i] = self.dim
			else
				rel = self.distances[i] - mean[i]--opposit of article
				rel:div(self.slope * rng[i])
				rel:exp()
				rel:add(1)
				rel:cinv()
				self.relevances[i]:copy(rel)
				self.relevance_sums[i] = rel:sum() + self.eps
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
			if rng < self.eps then
				rel:fill(1)
				self.relevance_sums[i] = self.dim
			else
				rel = dist - mean--opposit of article
				rel:div(self.slope * rng)
				rel:exp()
				rel:add(1)
				rel:cinv()
				self.relevances[i]:copy(rel)
				self.relevance_sums[i] = rel:sum() + self.eps
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

--tmp tensors: 3-4, 8-10 (reutilizing)
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

	local dif = self:get_tmp2(3, self.dn, self.n)
	local act = self:get_tmp2(4, self.dn, self.n)
	dif:csub(data, protos)
	dif:pow(2)
	dif:cmul(rel)
	act:sum(dif, 3)
	act = act:squeeze(3)
	local rel_norm = self.relevance_sums
		:view(1, self.n)
		:expand(self.dn, self.n)
	act:cdiv(rel_norm)
	act:add(1)
	act:cinv()

	local mx = self:get_tmp1(8, self.dn)
	local mi = self:get_tmp1(10, self.dn)
	torch.max(mx, mi, act, 2)
	mx, mi = mx:squeeze(2), mi:squeeze(2)

	if self.projected then
		local result = {}
		for i = 1, self.dn do
			if (not self.noise_filter) or mx[i] >= self.at then
				table.insert(result, {i, mi[i]})
			end
		end
		return torch.Tensor(result)
	else
		local assig_table = act:ge(self.at)
		if not self.noise_filter then
			for i = 1, self.dn do
				assig_table[i][mi[i]] = 1
			end
		end
		return assig_table:nonzero()
	end
end

function LARFDSSOM:normalize_data()
	local mx = self.data:max(1)
	local mn = self.data:min(1)
	local rng = mx-mn

	--deal with columns with equal values
	local rng_flat = rng:squeeze(1)
	local zero_cols = rng_flat
		:lt(self.eps):nonzero()
	if zero_cols:nElement() > 0 then
		zero_cols = zero_cols:squeeze(2)
		local zn = zero_cols:size(1)
		for ii = 1, zn do
			local i = zero_cols[ii]
			self.data:select(2, i):fill(0)
			rng_flat[i] = 1
		end
	end

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
	self:allocate_temp_tensors()

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

