require 'math'
require 'torch'
--require 'cutorch'

--[[
duvidas
como fica a contagem de vitorias na fase de convergencia?
comparar com a implementacao original

conferir
atribuicoes, o que pode tar sendo alterado sem querer em todas as operacoes
maxcomp relativo ao dataset size

melhoras
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

--update all connections between node n and previous nodes
function LARFDSSOM:update_connections(n)
	local thr = self.conn_thr*math.sqrt(self.dim)
	for i = 1, n-1 do
		local dif = self._relevance[n] - self._relevance[i]
		local neigh = (torch.norm(dif) < thr) and 1 or 0
		self._neighbors[n][i] = neigh
		self._neighbors[i][n] = neigh
	end
	self._neighbors[n][n] = 0
end

function LARFDSSOM:new_node(row, wins)
	self.n = self.n + 1
	local n = self.n
	self._protos[n]:copy(row)
	self._distances[n]:fill(0)
	self._relevances[n]:fill(1)
	self._wins[n] = wins
end

function LARFDSSOM:calculate_activation(pattern)
	local s, as, act = 0, -1, torch.Tensor(self.n)
	for i = 1, self.n do
		local dif = torch.pow(pattern - self._protos[i], 2)
		local rel = self._relevances[i]
		dif:cmul(rel)
		local dw = math.sqrt(torch.sum(dif))
		local rel_norm = torch.sum(torch.pow(rel, 2))
		local ai = 1/(1 + dw/(rel_norm + self.eps))

		act[i] = ai
		if ai > as then
			s, as = i, ai
		end
	end
	return s, as, act
end

function LARFDSSOM:remove_nodes()
	local n = 0
	for i = 1, self.n do
		if self._wins[i] >= self.lp*self.maxcomp then
			n = n+1
			if n ~= i then
				self._protos[n]:copy(self._protos[i])
				self._distances[n]:copy(self._distances[i])
				self._relevances[n]:copy(self._relevances[i])
			end
		end
	end
	self.n = n
end

function LARFDSSOM:interp(a, b, r)
	return (a*(1-r)) + (b*r)
end

function LARFDSSOM:get_learning_rate(s, i)
	if i == s then return eb
	elseif self._neighbors[s][i] ~= 0 then return en
	else return nil end
end

function LARFDSSOM:update_distances(pattern, s)
	for i = 1, n do
		local e = self:get_learning_rate(s, i)
		if e != nil then
			local dif = torch.abs(pattern - self._protos[i])
			self._distances[i]:copy(self:interp(self._distances[i], dif, e*beta))
		end
	end
end

function LARFDSSOM:update_relevance(pattern, s)
	for i = 1, n do
		if i == s or self._neighbors[s][i] ~= 0 then
			local dist = self._distances[i]
			local mean, rng = torch.mean(dist), torch.max(dist) - torch.min(dist)
			if rng < self.eps then
				dist:fill(1)
			else
				dist = -dist + mean
				dist = dist/(self.slope * rng)
				dist = torch.exp(dist) + 1
				dist:cinv()
			end
		end
	end
end

function LARFDSSOM:update_protos(pattern, s)
	for i = 1, n do
		local e = self:get_learning_rate(s, i)
		if e != nil then
			self._protos[i]:copy(self:interp(self._protos[i], pattern, e))
		end
	end
end

function LARFDSSOM:update_winner(pattern, s)
	self:update_distances(pattern, s)
	self:update_relevances(pattern, s)
	self:update_protos(pattern, s)
	self._wins[s] = self._wins[s] + 1
end

--complete
function LARFDSSOM:organization(data)
	local dn = data:size(1)
	self:new_node(data[1], 0)
	self._neighbors[1][1] = 0
	self.n_wins = 1

	for t = 1, self.tmax do
		local pattern = data[torch.random(1, dn)]
		local s, as = self:calculate_activation(pattern)

		if as < self.at and self.n < self.nmax then
			self:new_node(pattern, lp*self.n_wins)
			self:update_connections(self.n)
		else
			self:update_winner(pattern, s)
		end

		if self.nwins == self.maxcomp then
			self:remove_nodes()
			for i = 1, self.n do
				self:update_connections(i)
			end
			self._wins:fill(0)
			self.nwins = 0
		end
		self.nwins = self.nwins + 1
	end

end

function LARFDSSOM:convergence(data)
	while true do
		local oldn = self.n
		--remove nodes
		if self.n == oldn or self.n == 1 then return end

		for i = 1, self.n do
			self:update_connections(i)
		end
		self._wins:fill(0)

		for t = 1, self.tmax do
			local pattern = data[torch.random(1, dn)]
			local s, as = self:calculate_activation(pattern)
			self:update_winner(pattern, s)
		end
	end
end

--complete
function LARFDSSOM:classify(pattern)
	local s, as, act = self:calculate_activation(pattern)
	if as < self.at then
		--outlier
		return {}
	elseif self.projected then
		--single winner
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
	local data = torch.Tensor(raw_data)
	self.dim = data:size(2)

	self.n = 0
	--allocate maximum size, but don't necessarily use it all
	self._protos = torch.Tensor(self.nmax, self.dim)
	self._distances = torch.Tensor(self.nmax, self.dim)
	self._relevances = torch.Tensor(self.nmax, self.dim)
	self._wins = torch.IntTensor(self.nmax)
	self._neighbors = torch.ByteTensor(self.nmax, self.nmax)

	self:organization(data)
	self:convergence(data)

	local clusters, dn = {}, data:size(1)
	for i = 1, dn do
		table.insert(clusters, self:classify(data[i]))
	end
	return clusters
end

