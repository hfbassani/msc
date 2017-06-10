#!/bin/bash
mkdir ../lua_output
mkdir ../lua_output/results
time python s_10.py "luajit larfdssom_runner.lua" 1 "../lua_output"
#mkdir ../c_output
#mkdir ../c_output/results
#time python s_10.py "../larfdssom" 1 "../c_output"
