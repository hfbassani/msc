#!/bin/bash
TYPE="real";
echo "breast" > "$TYPE status";
luajit som_tester.lua ../../dbs/real/breast.arff 2 "$TYPE";
echo "diabetes" > "$TYPE status";
luajit som_tester.lua ../../dbs/real/diabetes.arff 2 "$TYPE";
echo "glass" > "$TYPE status";
luajit som_tester.lua ../../dbs/real/glass.arff 6 "$TYPE";
echo "liver" > "$TYPE status";
luajit som_tester.lua ../../dbs/real/liver.arff 2 "$TYPE";
echo "pendigits" > "$TYPE status";
luajit som_tester.lua ../../dbs/real/pendigits.arff 10 "$TYPE";
echo "shape" > "$TYPE status";
luajit som_tester.lua ../../dbs/real/shape.arff 9 "$TYPE";
echo "vowel" > "$TYPE status";
luajit som_tester.lua ../../dbs/real/vowel.arff 11 "$TYPE";
echo "done" > "$TYPE status";
