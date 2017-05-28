"""
combines normal .arff and .true files into a normalized .arff file with class labels bitmask

.arff
?*[@bla bla bla]
@data
rows*[dim*[attr,] class_id]

.true
bla bla bla
clusters*[dim*[0|1] k k*[pattern_id]]

output .arff
@data
rows*[dim*[attr,] dec(bin_classes)]
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

def combine(arff, true, out):
	# .arff file
	data = read_arff.read_arff(arff, ',')
	data = normalize(data)
	r, d = data.shape[0], data.shape[1]-1

	# .true file
	masks = [0 for i in range(r)]
	truefile = open(true, 'r')
	truefile.readline()
	for line in truefile:
		# update current masks
		for i in range(r):
			masks[i] <<= 1

		values = line.split(' ')
		k = int(values[d])
		for i in range(k):
			# sets the new bit for every pattern in this cluster
			pid = values[d+1+i]
			masks[int(pid)] |= 1
	truefile.close()

	# output file
	outfile = open(out, 'w')
	outfile.write('@data\n')
	for i in range(r):
		for j in range(d):
			outfile.write(str(data[i][j]) + ',')
		outfile.write(str(masks[i])+'\n')
	outfile.close()

if __name__ == '__main__':
	# input files folder
	path1 = sys.argv[1]
	# output file folder
	path2 = sys.argv[2]
	# files name
	name = sys.argv[3]

	combine(path1+name+'.arff', path1+name+'.true', path2+name+".arff")

