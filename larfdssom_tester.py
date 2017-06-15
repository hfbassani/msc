import math
import os
import random
import string
import sys
import time

def read_data(filename):
	with open(filename, 'r') as f:
		data = [line.split(',')
			for line in f
			if (line != '' and line[:1] != '#' and line[:1] != '\n')]
		for i in range(len(data)):
			data[i][-1] = data[i][-1].strip()
		return data

def distr(a):
	n = len(a)
	avg = sum(a)/n
	var = sum([(v-avg)**2 for v in a])/max(1, n-1)
	return avg, math.sqrt(var)

flags = [
	'v',#at
	'l',#lp
	's',#beta
	'i',#maxcomp
	'e',#eb
	'g',#en/eb
	'p',#s
	'w'#c
]
fn = len(flags)

def build_script(program, seed, params, input_file, is_real_data):
	script = program + ' -f ' + input_file + ' -r ' + str(seed) + ' -m 70 -n 100'
	for i in range(fn):
		script += ' -' + flags[i] + ' ' + params[i]
	if is_real_data:
		script += ' -P -o'
	return script + ' > /dev/null'

def eval_error(file_name, file_folder, output_folder, is_real_data):
	tmp_file = output_folder + '/tmp/' + file_name
	script = 'java -jar ../ClusteringAnalysis.jar "CE"'
	script += ' "' + file_folder + '/' + file_name + '/"'
	script += ' "' + output_folder + '/results/"'
	script += ' "' + tmp_file + '"'
	if is_real_data:
		script += ' -t'
	script += ' -r 1 > /dev/null'
	os.system(script)
	with open(tmp_file, 'r') as f:
		lines = [line for line in f]
		ce = lines[1][9:]
		return float(ce.strip())

def execute(program, seed, params, file_name, file_folder, output_folder, is_real_data):
	input_file = file_folder + '/' + file_name + '/' + file_name + '.arff'
	results_file = output_folder + '/results/' + file_name + '_0.results'
	script = build_script(program, seed, params, input_file, is_real_data)
	t0 = time.time()
	os.system(script)
	t1 = time.time()
	script = 'mv ' + input_file + '.results ' + results_file
	os.system(script)
	return [eval_error(file_name, file_folder, output_folder, is_real_data), (t1-t0)]

def run_file(program, seeds, output_folder, output, all_params, file_name, file_folder, is_real_data):
	n_exec = len(seeds)
	output.write('#' + file_folder + '/' + file_name + ' ' + str(len(all_params)) + ' configs ' + str(n_exec) + 'x\n')
	for params in all_params:
		# execute
		results = [execute(program, seeds[i], params, file_name, file_folder, output_folder, is_real_data)
				for i in range(n_exec)]

		ces = [results[i][0] for i in range(n_exec)]
		times = [results[i][1] for i in range(n_exec)]
		avg_ce, stdev_ce = distr(ces)
		avg_t, stdev_t = distr(times)

		for i in range(fn):
			output.write(params[i] + ',')
		output.write(str(avg_ce) + ',' + str(stdev_ce) + ',')
		output.write(str(avg_t) + ',' + str(stdev_t) + '\n')
		output.flush()
		os.fsync(output.fileno())

def run_files(files):
	# program to execute, like these:
	# "../larfdssom"
	# "th larfdssom_runner.lua"
	program = sys.argv[1]
	# amount of executions to measure time and clustering error
	n_exec = int(sys.argv[2])
	# output folder
	output_folder = sys.argv[3]
	print(program + ' ' + str(n_exec) + ' ' + output_folder)

	#os.system('mkdir ' + output_folder)
	#os.system('mkdir ' + output_folder + '/results')
	random.seed(12345)
	seeds = [0]*n_exec
	for i in range(n_exec):
		seeds[i] = int(random.getrandbits(30))

	for f in files:
		# file_name, input_folder, params_file
		file_name, file_folder, is_real_data = f[0], f[1], f[3]
		all_params = read_data(f[2])
		output_path = output_folder + '/' + file_name
		with open(output_path, 'w') as output:
			run_file(program, seeds, output_folder, output, all_params, file_name, file_folder, is_real_data)

