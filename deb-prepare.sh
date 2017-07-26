#!/bin/bash

# Prepares debian directory before dpkg-buildpackage can be run.
#
# Arguments:
#     $1 = customer (only for customized build)
#     $2 = debian release, i.e. distribution name

DEB_CUSTOMER=$1
DEB_RELEASE=$2

# forces symlink, no special case handling
function link() {
    ln -sfT $1 debian;
}

# expands template from debian/templates
function expand_template() {
    variant="${1}"
    template="${2}"
    base=$(basename "${template}" .template)
    src="debian/${variant}/${base}"
    dst="debian/${base}"
    header="${src}.header"
    footer="${src}.footer"

    if ! test -f "${src}"; then
        echo "There is no source file ${src} to fill in data in template ${template}." >/dev/stderr
        exit 1
    fi

    (
        # we are using {{{ and }}} to quote text in M4 macros these trigraphs
        # are probably not expected to be in sane text
        echo "m4_changequote({{{,}}})m4_dnl"

        # include source file, with variable (i.e. macro) definitions
        echo "m4_include(${src})m4_dnl"

        # output:

        # add specialized header template if exists
        test -f "${header}" && echo "m4_include(${header})m4_dnl"
        # template itself
        echo "m4_include(${template})m4_dnl"
        # add specialized footer template if exists
        test -f "${footer}" && echo "m4_include(${footer})m4_dnl"
    ) | m4 -P - > "${dst}"
}

# expands all templates from debian/templates
function expand_templates() {
    variant="${1}"
    for template in $(compgen -G "debian/templates/*.template"); do
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
    exit 0
fi

# check all possible release-based variants
VARIANTS="${DEB_CUSTOMER}.${DEB_RELEASE} ${DEB_RELEASE} ${DEB_CUSTOMER}"

for variant in ${VARIANTS}; do
    if test -d "debian.${variant}"; then
        link "debian.${variant}"
        exit 0
    fi
done
