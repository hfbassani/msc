#!/bin/bash
nohup ./dim1_batch.sh &> dim1_out &
nohup ./dim2_batch.sh &> dim2_out &
nohup ./noise_batch.sh &> noise_out &
nohup ./real_batch.sh &> real_out &
nohup ./size1_batch.sh &> size1_out &
nohup ./size2_batch.sh &> size2_out &
