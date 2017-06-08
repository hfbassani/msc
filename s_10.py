from larfdssom_tester import run_files

if __name__ == '__main__':
	files = [
		'D05', 'D10', 'D15', 'D20', 'D25', 'D50', 'D75',
		'N10', 'N30', 'N50', 'N70',
		'S1500', 'S2500', 'S3500', 'S4500', 'S5500',
		'breast', 'diabetes', 'glass', 'liver', 'pendigits', 'shape', 'vowel'
	]
	input_folder = '../dbs'
	params_folder = '../best_params'
	files = [[f, input_folder, params_folder + '/' + f]
			for f in files]
	run_files(files)

