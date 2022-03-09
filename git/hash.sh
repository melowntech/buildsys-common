#!/bin/bash

if ! command -v git >/dev/null; then
    exit
fi

git rev-parse --short HEAD
