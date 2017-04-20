require 'math'
require 'torch'

--[[duvidas
economizar na parte da neighborhood
]]--

eps = 1e-9

function square_norm(dx, dy)
	return math.sqrt(dx*dx + dy*dy)
end

DSSOM = {}
DSSOM.__index = DSSOM

function DSSOM:new(params)
	o = {
		map_h = params.h,
		map_w = params.w,

		tmax = params.tmax or 2000,
		nmax = params.nmax,
		kmax = params.kmax,
		rel_thr = params.rel_thr,
		win_thr = params.win_thr,
		nei_sz = params.nei_sz or 2,

		nei_r0 = params.nei_r0 or 0.4,
		nei_r_c = params.nei_r_c or 0.1,

		pro_lr0 = params.pro_lr0 or 0.4,
		pro_lr_c = params.pro_lr_c or 0.15,

		dist_cr = params.dist_cr,

		min_rel = params.min_rel or 0
	}
	setmetatable(o, self)
	return o
end

function key(i, j)
	return i..","..j
end

function DSSOM:addWinner(bi, bj)
	self.winners[key(bi, bj)] = true
end

function DSSOM:hasWinner(bi, bj)
	return self.winners[key(bi, bj)]
end

function DSSOM:calculate_activation(pattern, global_rel)
	local bi, bj, max_a = 0, 0, 0
	for i = 1, self.map_h do
		for j = 1, self.map_w do
			if not self:hasWinner(i, j) then
				local rel = (global_rel ~= nil) and global_rel or self.relevance[i][j]
				local dif = torch.cmul(pattern - self.proto[i][j], rel)
				local dist = torch.norm(dif)
				local sum = torch.sum(rel)

				local activ = sum/(dist + sum + eps)
				if activ > max_a then
					bi, bj, max_a = i, j, activ
				end
			end
		end
	end
	return bi, bj, max_a
end

function DSSOM:neighborhood(i, j, bi, bj)
	local denom = (2*math.pow(self.nei_r, 2))
	if denom < 1e-30 then
		return 0
	else
		return math.exp(-square_norm(i-bi, j-bj)/denom)
	end
end

function DSSOM:neigh_range(bi, bj)
	local li = math.max(bi - self.nei_sz, 1)
	local hi = math.min(bi + self.nei_sz, self.map_h)
	local lj = math.max(bj - self.nei_sz, 1)
	local hj = math.min(bj + self.nei_sz, self.map_w)
	return li, hi, lj, hj
end

function DSSOM:update_distance(pattern, bi, bj)
	local li, hi, lj, hj = self:neigh_range(bi, bj)
	for i = li, hi do
		for j = lj, hj do
			local w = self.proto[i][j]
			local d = self.distance[i][j]
			local b = self.dist_cr*self:neighborhood(i, j, bi, bj)
			self.distance[i][j] = d*b + torch.abs(pattern-w)*(1-b)
		end
	end
end

function DSSOM:update_relevance(pattern, bi, bj)
	local li, hi, lj, hj = self:neigh_range(bi, bj)
	for i = li, hi do
		for j = lj, hj do
			local d = self.distance[i][j]
			local dmx = torch.max(d)

			local r = torch.ones(self.dim)
			if dmx > 0 then
				r = r - torch.div(d, dmx)
			end
			self.relevance[i][j] = torch.cmax(r, self.min_rel)
		end
	end
end

function DSSOM:update_protos(pattern, bi, bj)
	local li, hi, lj, hj = self:neigh_range(bi, bj)
	for i = li, hi do
		for j = lj, hj do
			local w = self.proto[i][j]
			local neigh = self:neighborhood(i, j, bi, bj)
			self.proto[i][j] = w + (pattern - w)*self.pro_lr*neigh
		end
	end
end

function DSSOM:organization(data)
	self.proto = torch.rand(self.map_h, self.map_w, self.dim)
	self.relevance = torch.ones(self.map_h, self.map_w, self.dim)
	self.distance = torch.zeros(self.map_h, self.map_w, self.dim)

	local dn = data:size(1)

	self.pro_lr = self.pro_lr0
	self.nei_r = self.nei_r0

	local nmax = self.nmax or dn
	for t = 1, self.tmax do
		for n = 1, nmax do
			local global_rel = torch.ones(self.dim)
			local pattern = data[torch.random(1, dn)]
			self.winners = {}
			k = 1
			while (torch.max(global_rel) > self.rel_thr and k <= self.kmax) do
				local rel = (k == 1) and nil or global_rel
				local bi, bj = self:calculate_activation(pattern, rel)
				self:addWinner(bi, bj)

				self:update_distance(pattern, bi, bj)
				self:update_relevance(pattern, bi, bj)
				self:update_protos(pattern, bi, bj)
				global_rel:cmul(torch.ones(self.dim) - self.relevance[bi][bj])
				k = k+1
			end
		end

		self.pro_lr = self.pro_lr0*math.exp(-t/self.pro_lr_c)
		self.nei_r = self.nei_r0*math.exp(-t/self.nei_r_c)
	end
end

--list of belonging clusters: if empty, pattern is an outlier
function DSSOM:classify(pattern)
	local global_rel = torch.ones(self.dim)
	local clusters = {}
	self.winners = {}
	k = 1
	while (torch.max(global_rel) > self.rel_thr and k <= self.kmax) do
		local bi, bj = 0, 0
		if k == 1 then
			bi, bj, ac = self:calculate_activation(pattern, nil)
			if ac < self.win_thr then
				return {}
			end
		else
			bi, bj = self:calculate_activation(pattern, global_rel)
		end

		self:addWinner(bi, bj)
		table.insert(clusters, { bi, bj })
		global_rel:cmul(torch.ones(self.dim) - self.relevance[bi][bj])
		k = k+1
	end
	return clusters
end

function DSSOM:get_clusters(raw_data)
	local data = torch.Tensor(raw_data)
	local dn = data:size(1)
	self.dim = data:size(2)
	self:organization(data)

	local clusters = {}
	for i = 1, dn do
		table.insert(clusters, self:classify(data[i]))
	end
	return clusters
end

