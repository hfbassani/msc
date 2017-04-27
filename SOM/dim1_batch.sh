#!/bin/bash
TYPE="dim1";
mkdir "$TYPE";
luajit dssom_tester.lua ../../dbs/dim D05.arff 10 0.3 "$TYPE";
luajit dssom_tester.lua ../../dbs/dim D10.arff 10 0.33 "$TYPE";
luajit dssom_tester.lua ../../dbs/dim D15.arff 10 0.27 "$TYPE";
luajit dssom_tester.lua ../../dbs/dim D20.arff 10 0.3 "$TYPE";
echo "done" > "$TYPE/status";
