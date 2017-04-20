"""
combines normal .arff and .true files to the weird .arff pattern used in this repository

.arff
?*[@bla bla bla]
@data
rows*[dim*[attr] class_id]

.true
bla bla bla
clusters*[dim*[0|1] k k*[pattern id]]

.arff used here
?*[@bla bla bla]
@data
rows*[din*[attr] dec(bin_classes)]
"""

import sys
import read_arff

def combine(arff, true, out, sep_a, sep_t):
	data = read_arff.read_arff(arff, sep_a)
	r = data.shape[0]
	d = data.shape[1]-1
	masks = [0 for i in range(r)]

	truefile = open(true, 'r')
	truefile.readline()
	for line in truefile:
		# update current masks
		for i in range(r):
			masks[i] <<= 1

		values = line.split(sep_t)
		k = int(values[d])
		for i in range(k):
			# sets the new bit for every pattern in this cluster
			pid = values[d+1+i]
			masks[int(pid)] |= 1

	outfile = open(out, 'w')
	outfile.write('@data\n')
	for i in range(r):
		for j in range(d):
			outfile.write(str(data[i][j]) + ',')
		outfile.write(str(masks[i])+'\n')

if __name__ == '__main__':
	# input files folder
	path1 = sys.argv[1]
	# output file folder
	path2 = sys.argv[2]
	# files name
	name = sys.argv[3]

	combine(path1+name+'.arff', path1+name+'.true', path2+name+".arff", ',', ' ')

