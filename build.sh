#!/bin/bash

gcc main.c \
  -framework CoreFoundation \
  -framework CoreGraphics \
  -o exe
