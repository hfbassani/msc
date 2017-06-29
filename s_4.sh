#!/bin/bash
#mkdir "$2/lua";
#mkdir "$2/lua/results";
#mkdir "$2/lua/tmp";
langs="c lua";
for i in $langs;
do
  mkdir "$2/$i";
  mkdir "$2/$i/results";
  mkdir "$2/$i/tmp";
done
for i in $1;
do
  time python s_4.py "../larfdssom" 30 "$2/c" $i;
  time python s_4.py "th larfdssom_runner.lua" 30 "$2/lua" $i;
done
