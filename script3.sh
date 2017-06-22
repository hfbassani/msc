#!/bin/bash
mkdir ../lhs_new_500
mkdir ../lhs_new_500/results
mkdir ../lhs_new_500/tmp
mkdir ../lhs_new_500/error
for i in `seq 0 5`;
do
  nohup ./s_3.sh $i &> ../lhs_new_500/error/err_$i &
done
