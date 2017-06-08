from larfdssom_tester import run_files

def run_files2(files):
	input_folder = '../dbs'
	params_file = '../lhs_500'
	run_files([[f[0], input_folder, params_file]
			for f in files])

