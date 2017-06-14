#!/bin/bash
mkdir ../lhs_orig_500
mkdir ../lhs_orig_500/results
mkdir ../lhs_orig_500/tmp
mkdir ../error
nohup ./s_0.sh 0 &> ../error/err_0 &
nohup ./s_0.sh 1 &> ../error/err_1 &
nohup ./s_0.sh 2 &> ../error/err_2 &
nohup ./s_0.sh 3 &> ../error/err_3 &
