#!/bin/bash

set -e

dir=$(dirname $(realpath $0))
build_dir="$dir/_build"

mkdir -p "$build_dir"
cd "$build_dir"

cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=1 ..
cmake --build .

if ! [ -e $dir/compile_commands.json ]; then
  ln -s $build_dir/compile_commands.json $dir/compile_commands.json
fi
