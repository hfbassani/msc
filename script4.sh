#!/bin/bash
folder="../clus_output"
mkdir $folder
#C008 C016 C032 C064 C128
nohup ./s_4.sh "C256" $folder &> "$folder/error" &
