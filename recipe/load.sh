#!/bin/bash
set -e
echo "$@"
output_dir=$(dirname $1)
mkdir -p $SRC_DIR/saved-$(basename $1)
cp -rf $SRC_DIR/saved-$(basename $1)/*.txt $output_dir/
cp -rf $SRC_DIR/saved-$(basename $1)/*.xml $output_dir/
