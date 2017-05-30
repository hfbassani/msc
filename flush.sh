#!/bin/bash
sudo gdb -p "$1" -batch -ex 'call fflush(0)'
