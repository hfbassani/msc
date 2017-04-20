--[[
usage: som_tester data_file qty_categories
data_file: input file name
qty_categories: number of categories
]]--

require 'io'

require 'DSSOM'

--custom arff file to work with the python scripts
function read_arff_file(path)
	local rows = {}

	local capture = "([^,]+)"
	local file = assert(io.open(path, "r"))
	for line in file:lines() do
		if line ~= "" and line ~= "@data" then
			local row = {}
			for value in line:gmatch(capture) do
				table.insert(row, value)
			end
			--remove class column
			table.remove(row)
			table.insert(rows, row)
		end
	end
	file:close()

	--maximum and minimum for every attribute
	local min, max = {}, {}
	local rn, dn = table.getn(rows), table.getn(rows[1])
	for i = 1, dn do
		min[i] = math.huge
		max[i] = -math.huge
	end
	for i = 1, rn do
		for j = 1, dn do
			local v = rows[i][j]
			min[j] = math.min(min[j], v)
			max[j] = math.max(max[j], v)
		end
	end

	--normalize
	for i = 1, rn do
		for j = 1, dn do
			local v = rows[i][j]
			local rng = max[j]-min[j]
			rows[i][j] = (rng > 1e-12) and ((v-min[j])/rng) or 0
		end
	end

	return rows
end

--results file without cluster descriptions
function write_result_file(path, clusters, params)
	local dn = table.getn(clusters)
	local any_pat = false
	local file = assert(io.open(path, "w"))
	file:write(params.w, " ", params.dim, "\n")
	for i = 1, dn do
		local cl = clusters[i]
		local cn = table.getn(cl)
		for j = 1, cn do
			file:write(i-1, " ", cl[j][2]-1, "\n")
			any_pat = true
		end
	end

	--rare case when there is no pattern-cluster pair at all, we must write at least one
	if not any_pat then
		file:write("0 0\n")
	end
	file:close()
end

function debug(f, tab, key)
	f:write(key, " = ", tab[key], "\n")
end

test_vars = {}

function write_status(params, path)
	local file = assert(io.open(path, "w"))
	debug(file, test_vars, "min_error")
	debug(file, params, "w")
	debug(file, params, "dist_cr")
	debug(file, params, "rel_thr")
	debug(file, params, "kmax")
	debug(file, params, "win_thr")
	file:close()
end

function eval_score(params)
	write_status(params, test_vars.temp_file.."_params")
	local tmp1, tmp2 = test_vars.temp_file.."_tmp", test_vars.temp_file.."_tmp2"

	local dssom = DSSOM:new(params)
	local clusters = dssom:get_clusters(test_vars.data)
	write_result_file(tmp1, clusters, params)

	local error = os.execute("python ../cluster_functions.py "..(test_vars.data_file).." "..tmp1.." "..(test_vars.qty_categories).." > "..tmp2)
	assert(error ~= nil)
	local file = assert(io.open(tmp2, "r"))
	local ce = tonumber(file:read())
	file:close()

	if test_vars.min_error > ce then
		test_vars.min_error = ce
		test_vars.best_params = {
			n = params.w,
			dist_cr = params.dist_cr,
			rel_thr = params.rel_thr,
			kmax = params.kmax,
			win_thr = params.win_thr
		}
	end
end

function iterate_win_thr(params)
	local win_thr = 0
	for i = 1, 2 do
		params.win_thr = win_thr
		eval_score(params)
		win_thr = win_thr + 0.985
	end
end

function iterate_kmax(params)
	local kmax = 1
	for i = 1, 2 do
		params.kmax = kmax
		iterate_win_thr(params)
		kmax = kmax + 1
	end
end

function iterate_rel_thr(params)
	local rel_thr = 0.85
	for i = 1, 3 do
		params.rel_thr = rel_thr
		iterate_kmax(params)
		rel_thr = rel_thr + 0.05
	end
end

function iterate_dist_cr(params)
	local dist_cr = 0.025
	for i = 1, 3 do
		params.dist_cr = dist_cr
		iterate_rel_thr(params)
		dist_cr = dist_cr * 2
	end
end

function iterate_N(params)
	local n = 2
	for i = 1, 3 do--should be 6
		params.h = 1
		params.w = n
		iterate_dist_cr(params)
		n = n * 2
	end
end

function run_tests(df, qc, tf)
	test_vars.data_file = df
	test_vars.qty_categories = qc
	test_vars.temp_file = tf
	test_vars.data = read_arff_file(test_vars.data_file)
	test_vars.min_error = 1e20

	local params = { dim = table.getn(test_vars.data[1]) }
	iterate_N(params)

	debug(io.stdout, test_vars, "data_file")
	debug(io.stdout, test_vars, "min_error")
	debug(io.stdout, test_vars.best_params, "n")
	debug(io.stdout, test_vars.best_params, "dist_cr")
	debug(io.stdout, test_vars.best_params, "rel_thr")
	debug(io.stdout, test_vars.best_params, "kmax")
	debug(io.stdout, test_vars.best_params, "win_thr")
end

run_tests(arg[1], arg[2], arg[3])

