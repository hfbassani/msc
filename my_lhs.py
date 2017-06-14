import random
import sys

def pick(lo, hi, s):
	step = (hi-lo)/s
	return [lo + i*step + random.random()*step
			for i in range(s)]

def lhs(ranges, s):
	rn = len(ranges)
	samples = [pick(r[0], r[1], s) for r in ranges]
	for i in range(rn):
		random.shuffle(samples[i])
	return [[samples[i][j] for i in range(rn)]
			for j in range(s)]

if __name__ == '__main__':
	s = int(sys.argv[1])
	out_path = sys.argv[2]
	seed = int(sys.argv[3])# 12345

	random.seed(seed)

	ranges = [
		[0.9, 0.999],#at
		[0.0001, 0.1],#lp
		[0.0001, 0.5],#beta
		[1.0, 100.0],#maxcomp
		[0.0001, 0.01],#eb
		[0.001, 0.1],#en/eb
		[0.01, 0.05],#s
		[0, 0.5]#c
	]
	rn = len(ranges)

	params = lhs(ranges, s)
	# adjust neighbor learning rate
	for i in range(s):
		params[i][5] *= params[i][4]

	with open(out_path, 'w') as output:
		for i in range(s):
			for j in range(rn):
				if j > 0:
					output.write(',')
				output.write(str(params[i][j]))
			output.write('\n')

