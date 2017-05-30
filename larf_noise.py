from larfdssom_tester import test_files

if __name__ == '__main__':
	files = [
		["../dbs/synth_noisescale/N10.arff", 10, '../lhs_orig_500/results/N10.arff'],
		["../dbs/synth_noisescale/N30.arff", 10, '../lhs_orig_500/results/N30.arff'],
		["../dbs/synth_noisescale/N50.arff", 10, '../lhs_orig_500/results/N50.arff'],
		["../dbs/synth_noisescale/N70.arff", 10, '../lhs_orig_500/results/N70.arff']
	]
	test_files(files)

