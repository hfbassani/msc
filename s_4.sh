#!/bin/bash
for i in $1;
do
  time python s_4.py "../larfdssom" 30 $2 $i;
  time python s_4.py "th larfdssom_runner.lua" 30 $2 $i;
done
