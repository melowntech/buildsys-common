#!/bin/bash

function message() {
    echo "tag: $*" > /dev/stderr
}

PACKAGE="$1"
VERSION="$2"
TAGNAME="${PACKAGE}_${VERSION}"
TAGROOT_LOCAL="/tags/deb/${PACKAGE}"

SVN_OPT="-q"

cd ..

message "Updating repo"
svn up ${SVN_OPT}

REPO=$(svn info . | sed -n 's/^Repository Root: *\(.*\)/\1/p')
SRC=$(svn info . | sed -n 's/^URL: *\(.*\)/\1/p')
REVISION=$(svn info . | sed -n 's/^Revision: *\(.*\)/\1/p')

message "Using revision ${REVISION}."

TAGROOT="${REPO}${TAGROOT_LOCAL}"
DST="${TAGROOT}/${TAGNAME}"

if ! svn info "${TAGROOT}" 1>/dev/null 2>&1; then
    message "Creating deb tag root (${TAGROOT})"
    svn ${SVN_OPT} mkdir -m "make dtag: ensuring deb tag root exists" \
        --parents "${TAGROOT}"
fi

if svn info "${DST}" 1>/dev/null 2>&1; then
    message "Removing exiting tag at \"${DST}\"."
    svn ${SVN_OPT} rm -m "make dtag: removing existing tag" "${DST}"
fi

message "Copying \"${SRC}@${REVISION}\" to \"${DST}\"."
svn ${SVN_OPT} cp -m "make dtag: tagging ${TAGNAME} from ${SRC}@${REVISION}" \
    "${SRC}@${REVISION}" "${DST}"

function cleanup() {
    message "cleanup: ${TAGNAME}"
    rm -Rf "${TAGNAME}"
}

# remove local tag checkout files on exit
trap cleanup EXIT

message "Fetching empty tag to allow externals edition."
svn co --depth=empty --ignore-externals "${DST}"

svn pget svn:externals "${TAGNAME}" \
    | gawk -v REVISION="${REVISION}" '/^\^[^[:blank:]@]+[[:blank:]]/ { printf("%s@%s %s\n", $1, REVISION, $2); next } { print; }' \
    | svn pset svn:externals -F - "${TAGNAME}"

(
    cd ${TAGNAME}

    message "Pegging externals to ${REVISION}."
    svn ci -m "make dtag: pegging ${TAGNAME} externals to revision ${REVISION}" \
        --depth empty
)

cleanup
