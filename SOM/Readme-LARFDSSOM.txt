THIS README HAS BEEN TOTALLY COPIED FROM THE ORIGINAL LARFDSSOM IMPLEMENTATION
the usage is exactly the same as the original LARFDSSOM executable, but on luajit
example: th larfdssom_runner.lua -f ../dbs/synth_dbsizescale/S1500.arff -r 12345 -m 70 -n 1000 -v 0.824569341891 -l 0.00200674777625 -s 0.0826954444161 -i 30.5653456648 -e 0.0374727572594 -g 0.0036315339349 -p 0.0609407351856 -w 0.0808439119647

This is the README of the Local Adaptive Receptive Field Dimension Selective Self-Organizing Maps - LARFDSSOM

LARFDSSOM is a time-variant topology Self-Organizing Map (SOM) that improves over DSSOM in terms of clustering quality, computational cost and parameterization. This enables the method to identify the correct number of clusters and their respective relevant dimensions, and it thus presents nearly perfect results in synthetic datasets and surpasses our previous method in most of the real world datasets considered.

This program takes as input ".csv" or ".arff" (such as those used in Weka: http://www.cs.waikato.ac.nz/ml/weka/) files in which the last column is the ground truth index of the groups (which is ignored). The other columns of the dataset should be normalized to the [0,1] interval.

The output is an ".result" file containing: (i) the number of clusters found and dimensions in the dataset (ii) a list containing the relevances that each node applies for each input dimension; and (iii) the assignment of each input sample to one or more of the clusters found;

DSSOM Parameters:

-f : The name of a .arff or .csv file

-m :limits the number of nodes in the map. Default value is 20;

-e (e_b) and -g (e_n): learning rate of the winner node and of its neighbors. Default:
 (e_b = 0.0005) and (e_n = 0.002\times e_b);

-s (beta): change rate of the moving average used to compute the relevance vector. Higher values make the nodes adapt faster to the relevant dimensions. Excessively high values provoke instability. Default: 0.01;

-p (s): this parameter represents the slope of the logistic function to calculate relevances. Values lower than 0.001 produce a sharp slope while values around 0.1 produce a smoother slope. Values higher than 1.0 yield similar relevances for all dimensions. Default: 0.05;

-w (c): this parameter is a connection threshold. It defines the required level of similarity between the relevance vectors of two nodes if they are to be connected. When (c < 0) no connections are created, when (c > 1) the map is fully connected, and when (c = 0.5) only pairs of nodes with differences up to half the maximum are connected. Default: 0.5;

-i (maxcomp): periodicity in terms of number of competitions, to remove nodes from the map and to update the neighborhood. The value ranges from 5 to 100 times the number of patterns in the dataset (S). Standard value: (10\times S;

-n -t (t_{max}): number of epochs. Default: 100 times the number of patterns in the dataset (S);

-v (a_t): activation threshold. During training, if the activation of the winner node is below this level, a new node is inserted to define a new cluster. During the clustering procedure this parameter is seen as an outlier threshold and affects the number of winners per input pattern. This parameter is dependent on the dataset and greatly affects the results.

-l (lp): percentage of input patterns that a node has to cluster, if it is to remain in the map. This parameter is dependent on the dataset and affects the results significantly.

-P : this flag disables the subspace clustering mode. With this flag each sample will be assigned to a single cluster.

-o : this flag disables the noisy filtering and all samples will be assigned to a cluster.

For more information see:

BASSANI, H.F. ; ARAUJO, A. F. R.; Dimension Selective Self-organizing Maps with Time-varying Structure for Subspace and Projected Clustering. IEEE Transactions on Neural Networks and Learning Systems, 2014. to appear.
