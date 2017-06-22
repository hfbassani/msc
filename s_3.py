from larfdssom_tester import run_files
import sys

if __name__ == '__main__':
	files = [
		['C008', 8], ['C016', 16], ['C032', 32], ['C064', 64], ['C128', 128],
		['D0032', 8], ['D0064', 8], ['D0128', 8], ['D0256', 8],
		['D0512', 8],
		['D1024', 8],
		['D2048', 8],
		['D4096', 8]
	]
	input_folder = '../dbs2'
	params_file = '../lhs_500'
	files = [[f[0], input_folder, params_file, True, f[1]]
			for f in files]

	slices = [
		[0, 5],
		[5, 9],
		[9, 10],
		[10, 11],
		[11, 12],
		[12, 13]
	]
	mode = int(sys.argv[4])
	rng = slices[mode]
	files = files[rng[0]:rng[1]]

	run_files(files)

