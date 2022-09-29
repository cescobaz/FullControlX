#!/bin/sh

set -e

dir=$(dirname $(realpath $0))

$dir/build.sh

cd "$dir/_build"
ctest --output-on-failure
