from larfdssom_tester import run_files

if __name__ == '__main__':
	files = [
		['breast'],
		['diabetes'],
		['glass'],
		['liver'],
		['pendigits'],
		['shape'],
		['vowel'],
		['S5500']
	]
	input_folder = '../dbs'
	params_file = '../lhs_500'
	files = [[f[0], input_folder, params_file]
			for f in files]

	run_files(files)

