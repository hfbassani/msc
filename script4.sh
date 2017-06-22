#!/bin/bash
mkdir ../clus_output
mkdir ../clus_output/results
mkdir ../clus_output/tmp
mkdir ../clus_output/error
nohup ./s_4.sh "C008 C016 C032 C064 C128" "../clus_output" &> ../clus_output/error/err &
