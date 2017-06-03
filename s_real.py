from larfdssom_tester import run_files

if __name__ == '__main__':
	files = [
		['breast', 2],
		['diabetes', 2],
		['glass', 6],
		['liver', 2],
		['pendigits', 10],
		['shape', 9],
		['vowel', 11]
	]
	input_folder = '../dbs/real_world_data/'
	params_folder = '../orig_lhs_500_5x/best_params/'
	files = [
			[input_folder + f[0] + '.arff',
			f[1],
			params_folder + f[0] + '.arff']
			for f in files]
	files.append(
			['../dbs/synth_dbsizescale/S5500.arff',
			10,
			params_folder + 'S5500.arff'])

	run_files(files)

