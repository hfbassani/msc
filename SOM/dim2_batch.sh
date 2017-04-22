#!/bin/bash
TYPE="dim2";
mkdir "$TYPE";
#echo "25" > "$TYPE/status";
#luajit som_tester.lua ../../dbs/dim/D25.arff 10 0.3 "$TYPE";
#echo "50" > "$TYPE/status";
#luajit som_tester.lua ../../dbs/dim/D50.arff 10 0.35 "$TYPE";
echo "75" > "$TYPE/status";
luajit som_tester.lua ../../dbs/dim/D75.arff 10 0.37 "$TYPE";
echo "done" > "$TYPE/status";
