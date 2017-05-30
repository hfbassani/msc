#!/bin/bash
mkdir ../output
nohup ./s1.sh &
nohup ./s2.sh &
nohup ./s3.sh &
nohup ./s4.sh &
