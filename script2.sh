#!/bin/bash
mkdir ../output
mkdir ../error
nohup ./s5.sh &> ../error/err_5 &
nohup ./s6.sh &> ../error/err_6 &
nohup ./s7.sh &> ../error/err_7 &
nohup ./s8.sh &> ../error/err_8 &
nohup ./s9.sh &> ../error/err_9 &
