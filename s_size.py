from larfdssom_tester import run_files

if __name__ == '__main__':
	files = [
		['S1500', 10],
		['S2500', 10],
		['S3500', 10],
		['S4500', 10]
	]
	input_folder = '../dbs/synth_dbsizescale/'
	params_folder = '../orig_lhs_500_5x/best_params/'
	files = [
			[input_folder + f[0] + '.arff',
			f[1],
			params_folder + f[0] + '.arff']
			for f in files]

	run_files(files)

