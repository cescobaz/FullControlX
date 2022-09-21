#!/bin/bash

gcc \
  -x objective-c \
  -framework CoreFoundation \
  -framework CoreGraphics \
  -framework AppKit \
  -o exe \
  main.m
