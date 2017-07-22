import random
import sys

def pick(lo, hi, s):
	step = (hi-lo)/s
	return [lo + i*step + random.random()*step
			for i in range(s)]

#ranges is a list, where every element is a list with two numbers, the sampling range of that parameter
#s is the number of samples
def lhs(ranges, s):
	rn = len(ranges)
	samples = [pick(r[0], r[1], s) for r in ranges]
	for i in range(rn):
		random.shuffle(samples[i])
	return [[samples[i][j] for i in range(rn)]
			for j in range(s)]

