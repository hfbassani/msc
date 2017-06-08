#!/bin/bash
mkdir ../output
mkdir ../error
nohup ./s0.sh &> ../error/err_0 &
nohup ./s1.sh &> ../error/err_1 &
nohup ./s2.sh &> ../error/err_2 &
nohup ./s3.sh &> ../error/err_3 &
nohup ./s4.sh &> ../error/err_4 &
