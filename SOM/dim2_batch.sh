#!/bin/bash
TYPE="dim2";
mkdir "$TYPE";
luajit dssom_tester.lua ../../dbs/dim D25.arff 10 0.3 "$TYPE";
luajit dssom_tester.lua ../../dbs/dim D50.arff 10 0.35 "$TYPE";
luajit dssom_tester.lua ../../dbs/dim D75.arff 10 0.37 "$TYPE";
echo "done" > "$TYPE/status";
