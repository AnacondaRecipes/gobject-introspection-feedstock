#!/bin/bash
set -e
echo "$@"
output_dir=$(dirname $1)
eval "$@"
mkdir -p $SRC_DIR/saved-$(basename $1)
cp -rf $output_dir/* $SRC_DIR/saved-$(basename $1)
