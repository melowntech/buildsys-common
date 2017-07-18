#!/bin/bash

# this little script generates default excludes for given directory called from
# deb.mk's debsrc target

echo -I
echo -I$1/debian.*
echo -I$1/build
echo -I$1/build.*
echo -I$1/lib
echo -I$1/bin
