import csv
import math
import os
import string
import sys
import time

from cluster_functions import multilabelresults2clustering_error

def sq(x):
	return x*x

def run(script, n):
	times = [0]*n
	for i in range(n):
		t0 = time.time()
		os.system(script)
		t1 = time.time()
		times[i] = (t1-t0)
	avg = sum(times)/n
	stdev = sum([sq(t-avg) for t in times])/max(1, n-1)
	return avg, stdev

def eval_error(input_file, qt_cat):
	ce, outconf = multilabelresults2clustering_error(input_file, input_file+'.results', qt_cat)
	return ce

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
rn = len(flags)

def build_script(program, input_file, params):
	script = program + ' -f ' + input_file + ' -r 12345 -m 70 -n 1000'
	for j in range(rn):
		script += ' -' + flags[j] + ' ' + params[j]
	return script + ' > /dev/null'

def run_tests(program, n_exec, output_folder, input_file, qt_cat, params_path):
	params = []
	with open(params_path, 'r') as params_file:
		reader = csv.reader(params_file, delimiter=',')
		params = [row for row in reader]
	s = len(params)

	slash_idx = string.rfind(input_file, '/')
	output_path = output_folder + input_file[slash_idx:]
	with open(output_path, 'w') as output:
		output.write('#' + input_file + '\n')

		sum_time = 0
		for i in range(s):
			for j in range(rn):
				output.write(params[i][j] + ',')

			# execute
			script = build_script(program, input_file, params[i])
			avg, stdev = run(script, n_exec)
			ce = eval_error(input_file, qt_cat)
			sum_time += avg
			output.write(str(ce) + ',' + str(avg) + ',' + str(stdev) + '\n')

		# finish
		output.write('#' + str(sum_time/s) + '\n')

def test_files(files):
	# program to execute
	program = sys.argv[1]
	# amount of executions to measure time
	n_exec = int(sys.argv[2])
	# output folder
	output_folder = sys.argv[3]

	os.system("mkdir " + output_folder)
	for f in files:
		run_tests(program, n_exec, output_folder, f[0], f[1], f[2])

