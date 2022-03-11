#!/bin/bash

TO_REMOVE="${1}"

if test -z "${TO_REMOVE}"; then
    exit 0
fi

rm -f $1 || exit 0
rmdir --ignore-fail-on-non-empty -p $(dirname $1) || exit 0
