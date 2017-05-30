from larfdssom_tester import run_files

if __name__ == '__main__':
	files = [
		["../dbs/real_world_data/breast.arff", 2, '../lhs_500'],
		["../dbs/real_world_data/diabetes.arff", 2, '../lhs_500'],
		["../dbs/real_world_data/glass.arff", 6, '../lhs_500'],
		["../dbs/real_world_data/liver.arff", 2, '../lhs_500'],
		["../dbs/real_world_data/pendigits.arff", 10, '../lhs_500'],
		["../dbs/real_world_data/shape.arff", 9, '../lhs_500'],
		["../dbs/real_world_data/vowel.arff", 11, '../lhs_500']
	]
	run_files(files)

