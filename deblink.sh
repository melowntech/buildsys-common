#!/bin/bash

# this little script creates symlink to proper debian directory based on
# customer setup

DEB_CUSTOMER=$1
DEB_RELEASE=$2

function link() {
    ln -sfT $1 debian;
}

# symlink? make room
if /usr/bin/test -h debian; then
    rm debian
fi

# check all possible variants
VARIANTS="debian.${DEB_CUSTOMER}.${DEB_RELEASE} debian.${DEB_RELEASE} debian.${DEB_CUSTOMER}"

for variant in ${VARIANTS}; do
    if test -d ${variant}; then
        link ${variant}
        exit 0
    fi
done
