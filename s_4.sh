#!/bin/bash
langs="c lua";
for i in $langs;
do
  mkdir "$2/$i";
  mkdir "$2/$i/results";
  mkdir "$2/$i/tmp";
done
time python s_4.py "../larfdssom" 30 "$2/c" "D8192";
for i in $1;
do
  time python s_4.py "../larfdssom" 30 "$2/c" $i;
  time python s_4.py "th larfdssom_runner.lua" 30 "$2/lua" $i;
done
