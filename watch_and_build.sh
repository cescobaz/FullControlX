#!/bin/bash

fswatch -e '.*' -i '\.c$' . | xargs -n 2 "$(pwd)/build.sh"
