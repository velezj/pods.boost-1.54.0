#!/bin/bash

bn=$(basename $1)
nn=$2/lib/pkgconfig/$3$bn
echo $1 $nn
echo "prefix=$2" > $nn
cat $1 >> $nn

