#!/bin/bash

set -e

dir=$(dirname $(realpath $0))
build_dir="$dir/_build"

mkdir -p "$build_dir"
cd "$build_dir"

cmake ..
cmake --build .
