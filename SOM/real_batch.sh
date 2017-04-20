#!/bin/bash
TYPE="real";
mkdir "$TYPE";
echo "breast" > "$TYPE/status";
#luajit som_tester.lua ../../dbs/real/breast.arff 2 0.4 "$TYPE";
echo "diabetes" > "$TYPE/status";
#luajit som_tester.lua ../../dbs/real/diabetes.arff 2 0.33 "$TYPE";
echo "glass" > "$TYPE/status";
luajit som_tester.lua ../../dbs/real/glass.arff 6 0.46 "$TYPE";
echo "liver" > "$TYPE/status";
#luajit som_tester.lua ../../dbs/real/liver.arff 2 0.46 "$TYPE";
echo "pendigits" > "$TYPE/status";
luajit som_tester.lua ../../dbs/real/pendigits.arff 10 0.32 "$TYPE";
echo "shape" > "$TYPE/status";
luajit som_tester.lua ../../dbs/real/shape.arff 9 0.34 "$TYPE";
echo "vowel" > "$TYPE/status";
luajit som_tester.lua ../../dbs/real/vowel.arff 11 0.66 "$TYPE";
echo "done" > "$TYPE/status";
