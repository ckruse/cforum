#!/bin/bash

base_dir="$*"

for dir in $base_dir/*; do
    year=$(basename $dir)
    ./script/import-old-archive.rb $dir 1>~/$year.log 2>&1 &
done

# eof
