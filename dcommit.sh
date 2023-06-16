#!/bin/bash

set -e

version=$(dpkg-parsechangelog -S Version)
changes=$(dpkg-parsechangelog -S Changes | sed -e 's/^\.\(.*\)/\1/' -e '/^$/d' -e '1,2d' -e 's/[[:space:]]+/ /')
changes="${changes//$'\n'/ }"

tag="debian.${DEB_CUSTOMER}/${version}"

git commit -m "${tag}: ${changes}"
