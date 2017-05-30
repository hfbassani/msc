from larfdssom_tester import test_files

if __name__ == '__main__':
	files = [
		["../dbs/synth_dbsizescale/S1500.arff", 10, '../lhs_orig_500/results/S1500.arff'],
		["../dbs/synth_dbsizescale/S2500.arff", 10, '../lhs_orig_500/results/S2500.arff'],
		["../dbs/synth_dbsizescale/S3500.arff", 10, '../lhs_orig_500/results/S3500.arff'],
		["../dbs/synth_dbsizescale/S4500.arff", 10, '../lhs_orig_500/results/S4500.arff'],
		["../dbs/synth_dbsizescale/S5500.arff", 10, '../lhs_orig_500/results/S5500.arff']
	]
	test_files(files)

