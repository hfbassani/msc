from larfdssom_tester import test_files

if __name__ == '__main__':
	files = [
		["../dbs/real_world_data/breast.arff", 2, '../lhs_100'],
		["../dbs/real_world_data/diabetes.arff", 2, '../lhs_100'],
		["../dbs/real_world_data/glass.arff", 6, '../lhs_100'],
		["../dbs/real_world_data/liver.arff", 2, '../lhs_100'],
		["../dbs/real_world_data/pendigits.arff", 10, '../lhs_100'],
		["../dbs/real_world_data/shape.arff", 9, '../lhs_100'],
		["../dbs/real_world_data/vowel.arff", 11, '../lhs_100']
	]
	test_files(files)

