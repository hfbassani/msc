--TODO: add number of nodes as parameter
--TODO: check changes in the data_file_helper
--[[
usage: luajit dssom_tester.lua data_folder file_name qty_categories target_error output_folder [--exact_n]
data_folder: data file folder
file_name: input .arff file name
qty_categories: amount of real clusters
target_error: clustering error value you want to achieve
output_folder: folder for output and temporary files
--exact_n: test only qty_categories as the amount of nodes
]]--

require 'io'

require 'data_file_helper'
require 'DSSOM'

function debug(f, tab, key)
	f:write(key, " = ", tab[key], "\n")
end

test_vars, params = {}, {}

function write_status()
	local file = assert(io.open(test_vars.status_file, "w"))
	debug(file, test_vars, "file_name")
	debug(file, test_vars, "min_error")
	debug(file, params, "w")
	debug(file, params, "dist_cr")
	debug(file, params, "rel_thr")
	debug(file, params, "kmax")
	debug(file, params, "win_thr")
	file:close()
end

function eval_score()
	write_status()

	local t0 = os.time()
	local dssom = DSSOM:new(params)
	local clusters = dssom:get_clusters(test_vars.data)
	local t1 = os.time()
	write_result_file(test_vars.tmp1, clusters, params.w, params.dim)

	local error = os.execute("python ../subspace_clustering_error.py "
		..test_vars.data_file
		.." "..test_vars.tmp1
		.." "..test_vars.qty_categories
		.." > "..test_vars.tmp2)
	assert(error ~= nil)
	local file = assert(io.open(test_vars.tmp2, "r"))
	local ce = tonumber(file:read())
	file:close()

	file = assert(io.open(test_vars.result_file, "a"))
	file:write(params.w, ",")
	file:write(params.dist_cr, ",")
	file:write(params.rel_thr, ",")
	file:write(params.kmax, ",")
	file:write(params.win_thr, ",")
	file:write(ce, ",")
	file:write(os.difftime(t1, t0), "\n")
	file:close()

	if ce < test_vars.min_error then
		test_vars.min_error = ce
	end
end

function target_achieved()
	return test_vars.min_error <= test_vars.target_error
end

function iterate_win_thr()
	local win_thr = 0
	for i = 1, 2 do
		params.win_thr = win_thr
		eval_score()
		if target_achieved() then return end
		win_thr = win_thr + 0.985
	end
end

function iterate_kmax()
	local kmax = 1
	for i = 1, 2 do
		params.kmax = kmax
		iterate_win_thr()
		if target_achieved() then return end
		kmax = kmax + 1
	end
end

function iterate_rel_thr()
	local rel_thr = 0.85
	for i = 1, 3 do
		params.rel_thr = rel_thr
		iterate_kmax()
		if target_achieved() then return end
		rel_thr = rel_thr + 0.05
	end
end

function iterate_dist_cr()
	local dist_cr = 0.025
	for i = 1, 3 do
		params.dist_cr = dist_cr
		iterate_rel_thr()
		if target_achieved() then return end
		dist_cr = dist_cr * 2
	end
end

function iterate_N()
	local n = 2
	for i = 1, 6 do
		params.w = n
		iterate_dist_cr()
		if target_achieved() then return end
		n = n * 2
	end
end

function run_tests(df, fn, qc, te, of, en)
	test_vars = {
		data_file = df.."/"..fn,
		file_name = fn,
		qty_categories = qc,
		target_error = tonumber(te),
		min_error = 1e20,

		status_file = of.."/status",
		result_file = of.."/"..fn..".result",
		tmp1 = of.."/tmp",
		tmp2 = of.."/tmp2"
	}
	test_vars.data = read_arff_data(test_vars.data_file, true)

	params = {
		dim = table.getn(test_vars.data[1]),
		h = 1
	}

	local file = assert(io.open(test_vars.result_file, "w"))
	file:write("w,dist_cr,rel_thr,kmax,win_thr,ce,time\n")
	file:close()

	if en == "--exact_n" then
		params.w = qc
		iterate_dist_cr()
	else
		iterate_N()
	end

	debug(io.stdout, test_vars, "file_name")
	debug(io.stdout, test_vars, "min_error")
end

run_tests(arg[1], arg[2], arg[3], arg[4], arg[5], arg[6])

