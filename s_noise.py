from larfdssom_tester import run_files

if __name__ == '__main__':
	files = [
		['N10'],
		['N30'],
		['N50'],
		['N70']
	]
	input_folder = '../dbs/noise/'
	params_file = '../lhs_500'
	files = [[f[0], input_folder, params_file]
			for f in files]

	run_files(files)

