#!/bin/bash
nohup ./dim1_batch.sh &> dim1/out &;
nohup ./dim2_batch.sh &> dim2/out &;
nohup ./noise_batch.sh &> noise/out &;
nohup ./real_batch.sh &> real/out &;
nohup ./size1_batch.sh &> size1/out &;
nohup ./size2_batch.sh &> size2/out &;
