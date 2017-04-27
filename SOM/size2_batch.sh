#!/bin/bash
TYPE="size2";
mkdir "$TYPE";
luajit som_tester.lua ../../dbs/size S4500.arff 10 0.25 "$TYPE";
luajit som_tester.lua ../../dbs/size S5500.arff 10 0.25 "$TYPE";
echo "done" > "$TYPE/status";
