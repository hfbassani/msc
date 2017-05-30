from larfdssom_tester import run_files

if __name__ == '__main__':
	files = [
		["../dbs/synth_noisescale/N10.arff", 10, '../lhs_500'],
		["../dbs/synth_noisescale/N30.arff", 10, '../lhs_500'],
		["../dbs/synth_noisescale/N50.arff", 10, '../lhs_500'],
		["../dbs/synth_noisescale/N70.arff", 10, '../lhs_500']
	]
	run_files(files)

