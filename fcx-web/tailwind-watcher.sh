#!/bin/bash

set -e

cd assets
../_build/tailwind-linux-x64 --config=tailwind.config.js --input=css/app.css --output=../priv/static/assets/app.css --watch
