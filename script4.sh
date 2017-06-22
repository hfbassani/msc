#!/bin/bash
folder="../clus_output"
mkdir $folder
nohup ./s_4.sh "C008 C016 C032 C064 C128" $folder &> "$folder/error" &
