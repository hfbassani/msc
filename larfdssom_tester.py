import math
import os
import random
import string
import sys
import time

from cluster_functions import multilabelresults2clustering_error

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

def eval_error(input_file, qt_cat):
	ce, outconf = multilabelresults2clustering_error(input_file, input_file+'.results', qt_cat)
	return 1.0 - ce

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

def build_script(program, input_file, seed, params):
	script = program + ' -f ' + input_file + ' -r ' + str(seed) + ' -m 70 -n 1000'
	for i in range(fn):
		script += ' -' + flags[i] + ' ' + params[i]
	return script + ' > /dev/null'

def execute(program, input_file, seed, params, qt_cat):
	script = build_script(program, input_file, seed, params)
	t0 = time.time()
	os.system(script)
	t1 = time.time()
	return [eval_error(input_file, qt_cat), (t1-t0)]

def run_file(program, seeds, output_folder, output, all_params, input_file, qt_cat):
	n_exec = len(seeds)
	output.write('#' + input_file + ' ' + str(len(all_params)) + ' configs ' + str(n_exec) + 'x\n')
	for params in all_params:
		# execute
		results = [execute(program, input_file, seeds[i], params, qt_cat)
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
	# "luajit larfdssom_runner.lua"
	program = sys.argv[1]
	# amount of executions to measure time and clustering error
	n_exec = int(sys.argv[2])
	# output folder
	output_folder = sys.argv[3]

	print(program + ' ' + str(n_exec) + ' ' + output_folder)

	os.system("mkdir " + output_folder)

	random.seed(12345)
	seeds = [0]*n_exec
	for i in range(n_exec):
		seeds[i] = int(random.getrandbits(30))

	for f in files:
		all_params = read_data(f[2])
		slash_idx = string.rfind(f[0], '/')
		output_path = output_folder + input_file[slash_idx:]
		with open(output_path, 'w') as output:
			run_file(program, seeds, output_folder, output, all_params, f[0], f[1])

