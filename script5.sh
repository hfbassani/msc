#!/bin/bash
folder="../dim_output"
mkdir $folder
nohup ./s_4.sh "D0032 D0064 D0128 D0256 D0512 D1024 D2048 D4096 D8192 D16384 D32768" $folder &> "$folder/error" &
