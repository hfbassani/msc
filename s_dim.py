from larfdssom_tester import run_files

if __name__ == '__main__':
	files = [
		["../dbs/synth_dimscale/D05.arff", 10, '../lhs_500'],
		["../dbs/synth_dimscale/D10.arff", 10, '../lhs_500'],
		["../dbs/synth_dimscale/D15.arff", 10, '../lhs_500'],
		["../dbs/synth_dimscale/D20.arff", 10, '../lhs_500'],
		["../dbs/synth_dimscale/D25.arff", 10, '../lhs_500'],
		["../dbs/synth_dimscale/D50.arff", 10, '../lhs_500'],
		["../dbs/synth_dimscale/D75.arff", 10, '../lhs_500']
	]
	run_files(files)

