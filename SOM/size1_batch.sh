#!/bin/bash
TYPE="size1";
mkdir "$TYPE";
#echo "1500" > "$TYPE/status";
#luajit som_tester.lua ../../dbs/size/S1500.arff 10 0.26 "$TYPE";
echo "2500" > "$TYPE/status";
luajit som_tester.lua ../../dbs/size/S2500.arff 10 0.26 "$TYPE";
echo "5500" > "$TYPE/status";
luajit som_tester.lua ../../dbs/size/S5500.arff 10 0.25 "$TYPE";
echo "done" > "$TYPE/status";
