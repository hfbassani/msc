require 'io'
require 'math'
require 'torch'

require 'data_file_helper'
require 'LARFDSSOM'

input_file = ""
params = {
	tmax = 100,
	nmax = 20,
	at = 0.975,
	lp = 0.06,
	maxcomp = 10,
	eb = 0.0005,
	en = 0.000001,
	beta = 0.1,
	slope = 0.001,
	conn_thr = 0.5,

	projected = false,
	noise_filter = true
}
seed = 0

argc, ai = table.getn(arg), 1
while ai <= argc do
	local flag = arg[ai]
	ai = ai+1

	if flag == '-P' then
		params.projected = true
	elseif flag == '-o' then
		params.noise_filter = false
	else
		if ai > argc then
			io.write('wrong usage\n')
			os.exit()
		end
		local val = arg[ai]
		ai = ai+1

		if flag == '-f' then
			input_file = val
		else
			val = tonumber(val)
			if flag == '-m' then
				params.nmax = val
			elseif flag == '-n' or flag == '-t' then
				params.tmax = val
			elseif flag == '-v' then
				params.at = val
			elseif flag == '-l' then
				params.lp = val
			elseif flag == '-s' then
				params.beta = val
			elseif flag == '-i' then
				params.maxcomp = val
			elseif flag == '-e' then
				params.eb = val
			elseif flag == '-g' then
				params.en = val
			elseif flag == '-p' then
				params.slope = val
			elseif flag == '-w' then
				params.conn_thr = val
			elseif flag == '-r' then
				seed = val
			else
				io.write('wrong usage\n')
				os.exit()
			end
		end
	end
end

output_file = input_file..'.results'
torch.manualSeed(seed)

--read data
data = read_arff_data(input_file)
dn, dim = data:size(1), data:size(2)
params.maxcomp = math.floor(params.maxcomp * dn + 0.5)
params.tmax = params.tmax * dn

--run algorithm
larfdssom = LARFDSSOM:new(params)
assignments = larfdssom:process(data)
cn = larfdssom.n

--save results
write_results_file(output_file, assignments, larfdssom.relevances, cn, dim)

