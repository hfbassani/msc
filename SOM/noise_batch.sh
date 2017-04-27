#!/bin/bash
TYPE="noise";
mkdir "$TYPE";
luajit som_tester.lua ../../dbs/noise N10.arff 10 0.25 "$TYPE";
luajit som_tester.lua ../../dbs/noise N30.arff 10 0.25 "$TYPE";
luajit som_tester.lua ../../dbs/noise N50.arff 10 0.23 "$TYPE";
luajit som_tester.lua ../../dbs/noise N70.arff 10 0.22 "$TYPE";
echo "done" > "$TYPE/status";
