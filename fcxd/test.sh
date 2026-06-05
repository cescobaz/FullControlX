#!/bin/sh

set -e

dir=$(dirname $(realpath $0))

"$dir/zig-out/bin/FullControlX" < "$dir/test/test.input"
