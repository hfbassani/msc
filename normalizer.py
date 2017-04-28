"""
copy and normalize a .arff data file
"""

import numpy as np
import read_arff
import sys

def normalize(orig_data):
	data = np.copy(orig_data)
	n, d = data.shape[0], data.shape[1]-1
	maxi = [max([data[i, j] for i in range(n)])
			for j in range(d)]
	mini = [min([data[i, j] for i in range(n)])
			for j in range(d)]

	for j in range(d):
		rng = maxi[j]-mini[j]
		if rng < 1e-12:
			for i in range(n):
				data[i, j] = 0
		else:
			for i in range(n):
				data[i, j] = (data[i, j] - mini[j])/rng
	return data

if __name__ == '__main__':
	# input file
	input_file = sys.argv[1]
	# output file
	output_file = sys.argv[2]

	data = read_arff.read_arff(input_file, ',')
	data = normalize(data)
	n, d = data.shape[0], data.shape[1]-1

	outfile = open(output_file, 'w')
	outfile.write('@data\n')
	for i in range(n):
		for j in range(d):
			outfile.write(str(data[i][j]) + ',')
		outfile.write(str(data[i][d]) + '\n')
	outfile.close()

