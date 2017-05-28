from larfdssom_tester import test_files

if __name__ == '__main__':
	files = [
		["../dbs/real_world_data/breast.arff", 2],
		["../dbs/real_world_data/diabetes.arff", 2],
		["../dbs/real_world_data/glass.arff", 6],
		["../dbs/real_world_data/liver.arff", 2],
		["../dbs/real_world_data/pendigits.arff", 10],
		["../dbs/real_world_data/shape.arff", 9],
		["../dbs/real_world_data/vowel.arff", 11]
	]
	test_files(files)

