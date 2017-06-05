from larfdssom_tester import run_files

if __name__ == '__main__':
	files = [
		['D05', 10],
		['D10', 10],
		['D15', 10],
		['D20', 10],
		['D25', 10],
		['D50', 10],
		['D75', 10]
	]
	input_folder = '../dbs/synth_dimscale/'
	params_folder = '../orig_lhs_500_5x/best_params/'
	files = [
			[input_folder + f[0] + '.arff',
			f[1],
			params_folder + f[0] + '.arff']
			for f in files]

	run_files(files)

