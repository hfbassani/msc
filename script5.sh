#!/bin/bash
mkdir ../dim_output
mkdir ../dim_output/results
mkdir ../dim_output/tmp
mkdir ../dim_output/error
nohup ./s_4.sh "D0032 D0064 D0128 D0256 D0512 D1024 D2048 D4096" "../dim_output" &> ../dim_output/error/err &
