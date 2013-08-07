#!/bin/bash

bn=$(basename $1)
nn=$2/lib/pkgconfig/$3$bn
rm $nn
