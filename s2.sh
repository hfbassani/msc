#!/bin/bash
time python larf_noise.py "luajit larfdssom_runner.lua" 1 "../output" &> ../output/err_noise
