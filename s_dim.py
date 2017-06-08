from larfdssom_tester import run_files

if __name__ == '__main__':
	files = [
		['D05'],
		['D10'],
		['D15'],
		['D20'],
		['D25'],
		['D50'],
		['D75']
	]
	input_folder = '../dbs'
	params_file = '../lhs_500'
	files = [[f[0], input_folder, params_file]
			for f in files]

	run_files(files)

