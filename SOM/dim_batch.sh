#!/bin/bash
TYPE="dim";
echo "5" > "$TYPE status";
luajit som_tester.lua ../../dbs/dim/D05.arff 10 "$TYPE";
echo "10" > "$TYPE status";
luajit som_tester.lua ../../dbs/dim/D10.arff 10 "$TYPE";
echo "15" > "$TYPE status";
luajit som_tester.lua ../../dbs/dim/D15.arff 10 "$TYPE";
echo "20" > "$TYPE status";
luajit som_tester.lua ../../dbs/dim/D20.arff 10 "$TYPE";
echo "25" > "$TYPE status";
luajit som_tester.lua ../../dbs/dim/D25.arff 10 "$TYPE";
echo "50" > "$TYPE status";
luajit som_tester.lua ../../dbs/dim/D50.arff 10 "$TYPE";
echo "75" > "$TYPE status";
luajit som_tester.lua ../../dbs/dim/D75.arff 10 "$TYPE";
echo "done" > "$TYPE status";
