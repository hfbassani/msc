from larfdssom_tester import run_files

if __name__ == '__main__':
	files = [
		["../dbs/synth_dbsizescale/S1500.arff", 10, '../lhs_500'],
		["../dbs/synth_dbsizescale/S2500.arff", 10, '../lhs_500'],
		["../dbs/synth_dbsizescale/S3500.arff", 10, '../lhs_500'],
		["../dbs/synth_dbsizescale/S4500.arff", 10, '../lhs_500'],
		["../dbs/synth_dbsizescale/S5500.arff", 10, '../lhs_500']
	]
	run_files(files)

