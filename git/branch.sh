#!/bin/bash

if ! command -v git >/dev/null; then
    exit
fi

git rev-parse --abbrev-ref HEAD 2>/dev/null
