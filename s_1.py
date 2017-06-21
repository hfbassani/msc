from larfdssom_tester import run_files

if __name__ == '__main__':
	files = [
		'breast', 'diabetes', 'glass', 'liver', 'pendigits', 'shape', 'vowel',
		'D05', 'D10', 'D15', 'D20', 'D25', 'D50', 'D75',
		'N10', 'N30', 'N50', 'N70',
		'S1500', 'S2500', 'S3500', 'S4500', 'S5500'
	]
	input_folder = '../dbs'
	params_folder = '../best_params'
	files = [[f, input_folder, params_folder + '/' + f, False, 70]
			for f in files]
	for i in range(7):
		files[i][3] = True

	files = files[7:]
	run_files(files)

