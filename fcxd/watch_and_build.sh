#!/bin/bash

fswatch -e '.*' -i '\.c$' -i '\.m$' -i '\.sh$' . | xargs -n 2 "$(pwd)/build.sh"
