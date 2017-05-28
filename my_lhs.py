import random

def pick(lo, hi, s):
	step = (hi-lo)/s
	return [lo + i*step + random.random()*step
			for i in range(s)]

def lhs(ranges, s):
	samples = [pick(r[0], r[1], s) for r in ranges]
	rn = len(ranges)
	for i in range(rn):
		random.shuffle(samples[i])
	return [[samples[i][j] for i in range(rn)]
			for j in range(s)]

