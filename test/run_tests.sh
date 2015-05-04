#!/bin/bash
export LD_LIBRARY_PATH=/usr/local/lib
export GI_TYPELIB_PATH=/usr/local/lib/girepository-1.0/
python3 test/test-gtkflow.py -v

