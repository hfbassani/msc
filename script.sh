#!/bin/bash
mkdir ../output
nohup ./s1.sh &> ../output/err_dim &
nohup ./s2.sh &> ../output/err_noise &
nohup ./s3.sh &> ../output/err_real &
nohup ./s4.sh &> ../output/err_size &
