#!/bin/bash
TYPE="noise";
echo "10" > "$TYPE status";
luajit som_tester.lua ../../dbs/noise/N10.arff 10 "$TYPE";
echo "30" > "$TYPE status";
luajit som_tester.lua ../../dbs/noise/N30.arff 10 "$TYPE";
echo "50" > "$TYPE status";
luajit som_tester.lua ../../dbs/noise/N50.arff 10 "$TYPE";
echo "70" > "$TYPE status";
luajit som_tester.lua ../../dbs/noise/N70.arff 10 "$TYPE";
echo "done" > "$TYPE status";
