from larfdssom_tester import run_files

if __name__ == '__main__':
	files = [
		['S1500'],
		['S2500'],
		['S3500'],
		['S4500']
	]
	input_folder = '../dbs'
	params_file = '../lhs_500'
	files = [[f[0], input_folder, params_file]
			for f in files]

	run_files(files)

