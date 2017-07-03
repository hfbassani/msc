#!/bin/bash
mkdir ../lhs_new_500_2
mkdir ../lhs_new_500_2/results
mkdir ../lhs_new_500_2/tmp
mkdir ../lhs_new_500_2/error
for i in `seq 0 1`;
do
  nohup ./s_3.sh $i &> ../lhs_new_500_2/error/err_$i &
done
