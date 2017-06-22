from larfdssom_tester import run_files
import sys

def get_params_file(name):
	if name[:1] == 'D':
		return 'dim'
	return name

def get_maxn(name):
	if name[:1] == 'D':
		return 8
	return int(name[1:])

if __name__ == '__main__':
	name = sys.argv[4]
	input_folder = '../dbs2'
	params_file = '../best_params2/' + get_params_file(name)
	f = [name, input_folder, params_file, True, get_maxn(name)]
	run_files([f])

