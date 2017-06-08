from larfdssom_tester import run_files

if __name__ == '__main__':
	files = [
		['breast'],
		['diabetes'],
		['glass'],
		['liver'],
		['pendigits'],
		['shape'],
		['vowel']
	]
	input_folder = '../dbs/real/'
	params_file = '../lhs_500'
	files = [[f[0], input_folder, params_file]
			for f in files]
	files.append(['S5500', '../dbs/size/', params_file])

	run_files(files)

