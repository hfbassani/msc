import sys
from cluster_functions import multilabelresults2clustering_error

if __name__ == '__main__':
	data_file = sys.argv[1]
	results_file = sys.argv[2]
	qty_categories = int(sys.argv[3])

	ce, outconf = multilabelresults2clustering_error(data_file, results_file, qty_categories)
	print ce

