#!/bin/bash
TYPE="size2";
mkdir "$TYPE";
echo "3500" > "$TYPE/status";
luajit som_tester.lua ../../dbs/size/S3500.arff 10 0.25 "$TYPE";
echo "4500" > "$TYPE/status";
luajit som_tester.lua ../../dbs/size/S4500.arff 10 0.25 "$TYPE";
echo "done" > "$TYPE/status";
