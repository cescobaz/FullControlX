#!/bin/sh

set -e

dir=$(dirname $(realpath $0))

$dir/build.sh && $dir/test.sh
