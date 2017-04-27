#!/bin/bash
TYPE="size1";
mkdir "$TYPE";
luajit som_tester.lua ../../dbs/size S1500.arff 10 0.26 "$TYPE";
luajit som_tester.lua ../../dbs/size S2500.arff 10 0.26 "$TYPE";
luajit som_tester.lua ../../dbs/size S3500.arff 10 0.25 "$TYPE";
echo "done" > "$TYPE/status";
