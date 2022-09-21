#!/bin/sh

set -e

dir=$(dirname $(realpath $0))
build_dir="$dir/_build"

$build_dir/FullControlX < "$dir/test/test.input"
