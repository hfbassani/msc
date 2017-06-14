from larfdssom_tester import run_files
import sys

if __name__ == '__main__':
	files = [
		'breast', 'diabetes', 'glass', 'liver', 'pendigits', 'shape', 'vowel', 'S5500',
		'D05', 'D10', 'D15', 'D20', 'D25', 'D50', 'D75',
		'N10', 'N30', 'N50', 'N70',
		'S1500', 'S2500', 'S3500', 'S4500'
	]
	input_folder = '../dbs'
	params_file = '../lhs_500'
	files = [[f, input_folder, params_file, False]
			for f in files]
	for i in range(7):
		files[i][3] = True

	mode = int(sys.argv[4])
	if mode == 0:
		files = files[:8]
	elif mode == 1:
		files = files[8:15]
	elif mode == 2:
		files = files[15:19]
	elif mode == 3:
		files = files[19:]
	run_files(files)

