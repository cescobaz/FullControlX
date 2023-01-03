#!/bin/sh

set -e

dir=$(dirname $(realpath $0))

echo "Building fcxd ..."
$dir/fcxd/build.sh

echo "Building fcx-web ..."
cd "$dir/fcx-web"
mix deps.get
mix compile

echo "Starting FullControlX ..."
mix phx.server
