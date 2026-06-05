#!/bin/bash

set -e

dir=$(dirname $(realpath $0))
cd "$dir"

zig build "$@"
