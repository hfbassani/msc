from larfdssom_tester import run_files

if __name__ == '__main__':
	files = [
		['N10', 10],
		['N30', 10],
		['N50', 10],
		['N70', 10]
	]
	input_folder = '../dbs/synth_noisescale/'
	params_folder = '../orig_lhs_500_5x/best_params/'
	files = [
			[input_folder + f[0] + '.arff',
			f[1],
			params_folder + f[0] + '.arff']
			for f in files]

	run_files(files)

