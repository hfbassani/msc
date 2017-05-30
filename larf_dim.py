from larfdssom_tester import test_files

if __name__ == '__main__':
	files = [
		["../dbs/synth_dimscale/D05.arff", 10, '../lhs_orig_500/results/D05.arff'],
		["../dbs/synth_dimscale/D10.arff", 10, '../lhs_orig_500/results/D10.arff'],
		["../dbs/synth_dimscale/D15.arff", 10, '../lhs_orig_500/results/D15.arff'],
		["../dbs/synth_dimscale/D20.arff", 10, '../lhs_orig_500/results/D20.arff'],
		["../dbs/synth_dimscale/D25.arff", 10, '../lhs_orig_500/results/D25.arff'],
		["../dbs/synth_dimscale/D50.arff", 10, '../lhs_orig_500/results/D50.arff'],
		["../dbs/synth_dimscale/D75.arff", 10, '../lhs_orig_500/results/D75.arff']
	]
	test_files(files)

