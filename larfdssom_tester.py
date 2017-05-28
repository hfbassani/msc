import os
import random
import string
import sys
import time

import my_lhs
from cluster_functions import multilabelresults2clustering_error

"""
import statistics

def measure_time(script):
	times, turns = [], 30
	for i in range(turns):
		t0 = time.time()
		os.system(script)
		t1 = time.time()
		#stdout.write(str(t1-t0) + '\n')
		times.append(t1-t0)

	avg = statistics.mean(times)
	return avg, statistics.stdev(times, avg)
"""

def run(script, n_exec):
	tsum = 0
	for _ in range(n_exec):
		t0 = time.time()
		os.system(script)
		t1 = time.time()
		tsum += (t1-t0)
	return tsum/n_exec

def eval_error(input_file, qt_cat):
	ce, outconf = multilabelresults2clustering_error(input_file, input_file+'.results', qt_cat)
	return ce

def run_tests(program, s, n_exec, output_folder, input_file, qt_cat):
	ranges = [
		[0.7, 0.999, 'v'],#at
		[0.001, 0.1, 'l'],#lp
		[0.001, 0.1, 's'],#beta
		[1.0, 100.0, 'i'],#maxcomp
		[0.001, 0.1, 'e'],#eb
		[0.0001, 0.5, 'g'],#en/eb
		[0.01, 0.1, 'p'],#s
		[0, 0.5, 'w']#c
	]
	rn = len(ranges)
	params = my_lhs.lhs(ranges, s)
	# adjust neighbor learning rate
	for i in range(s):
		params[i][5] *= params[i][4]

	slash_idx = string.rfind(input_file, '/')
	output = open(output_folder + input_file[slash_idx:], 'w')
	output.write('#' + str(s) + ' ' + input_file + '\n')

	avg_time = 0
	for i in range(s):
		# build script
		script = program + ' -f ' + input_file + ' -r 12345 -m 70 -n 1000'
		for j in range(rn):
			v = params[i][j]
			script += ' -' + str(ranges[j][2]) + ' ' + str(v)
			output.write(str(v) + ',')
		script += ' > /dev/null'

		# execute
		run_time = run(script, n_exec)
		avg_time += run_time
		ce = eval_error(input_file, qt_cat)
		output.write(str(run_time) + ',' + str(ce) + '\n')

	# finish
	output.write('#' + str(avg_time/s) + '\n')
	output.close()

def test_files(files):
	# program to execute
	program = sys.argv[1]
	# number of samples of lhs
	s = int(sys.argv[2])
	# amount of executions
	n_exec = int(sys.argv[3])
	# output folder
	output_folder = sys.argv[4]
	# input file
	#input_file = sys.argv[3]
	# amount of real clusters
	#qt_cat = sys.argv[4]

	os.system("mkdir " + output_folder)
	random.seed(12345)
	for f in files:
		run_tests(program, s, n_exec, output_folder, f[0], f[1])

