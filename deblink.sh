#!/bin/bash

# this little script creates symlink to proper debian directory based on
# customer setup

DEB_CUSTOMER=$1
DEB_RELEASE=$2

function link() {
    ln -sfT $1 debian;
}

function expand_template() {
    variant="${1}"
    template="${2}"
    base=$(basename "${template}" .template)
    src="debian/${variant}/${base}"
    dst="debian/${base}"

    if ! test -f "${src}"; then
        echo "There is no source file ${src} to fill in data in template ${template}." >/dev/stderr
        exit 1
    fi

    (
        echo "m4_changequote({,})m4_dnl"
        echo "m4_include(${src})m4_dnl"
        echo "m4_include(${template})m4_dnl"
    ) | m4 -P - > "${dst}"
}

function expand_templates() {
    variant="${1}"
    for template in debian/templates/*; do
        expand_template "${variant}" "${template}"
    done
}

# symlink? make room
if /usr/bin/test -h debian; then
    rm debian
fi

# handling for provided debian directory
if test -d debian; then
    expand_templates "${DEB_RELEASE}"
    exit
fi

# check all possible release-based variants
VARIANTS="${DEB_CUSTOMER}.${DEB_RELEASE} ${DEB_RELEASE} ${DEB_CUSTOMER}"

for variant in ${VARIANTS}; do
    if test -d "debian.${variant}"; then
        link "debian.${variant}"
        exit 0
    fi
done
