#!/bin/bash

# This script manually watches for changes to app.css using fswatch.
#
# Why not use tailwind's built-in --watch flag?
# Tailwind's --watch only monitors "application" files (HTML, JS, templates, etc.)
# to detect when new utility classes are used in the codebase. However, it does NOT
# watch the input CSS file itself (app.css).
#
# This means that changes to app.css — such as adding custom CSS rules, @apply
# directives, or modifying @layer definitions — would not trigger a rebuild.
#
# By using fswatch, we explicitly watch app.css for any modifications and
# trigger a fresh tailwind build whenever the file changes.

set -e

cd assets

build_css() {
  ../_build/tailwind-macos-arm64 --input=css/app.css --output=../priv/static/assets/app.css
}

# Initial build
build_css

# Watch for changes to app.css and rebuild
fswatch -o css/app.css | while read -r; do
  build_css
done
