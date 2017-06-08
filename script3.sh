#!/bin/bash
mkdir ../output
mkdir ../output/results
mkdir ../error
nohup ./s10.sh &> ../error/err_10 &
