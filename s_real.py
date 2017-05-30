from larfdssom_tester import test_files

if __name__ == '__main__':
	files = [
		["../dbs/real_world_data/breast.arff", 2, '../lhs_orig_500/results/breast.arff'],
		["../dbs/real_world_data/diabetes.arff", 2, '../lhs_orig_500/results/diabetes.arff'],
		["../dbs/real_world_data/glass.arff", 6, '../lhs_orig_500/results/glass.arff'],
		["../dbs/real_world_data/liver.arff", 2, '../lhs_orig_500/results/liver.arff'],
		["../dbs/real_world_data/pendigits.arff", 10, '../lhs_orig_500/results/pendigits.arff'],
		["../dbs/real_world_data/shape.arff", 9, '../lhs_orig_500/results/shape.arff'],
		["../dbs/real_world_data/vowel.arff", 11, '../lhs_orig_500/results/vowel.arff']
	]
	test_files(files)

