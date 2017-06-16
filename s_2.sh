#!/bin/bash
mkdir ../lua_output
mkdir ../lua_output/results
mkdir ../lua_output/tmp
time python s_1.py "th larfdssom_runner.lua" 30 "../lua_output"
