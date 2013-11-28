#!/bin/bash

usage() { echo "Usage: $0 [-j JOBS]" 1>&2; exit 1; }

MAKEARGS=""

while getopts "j:" o; do
    case "${o}" in
        j)
            MAKEARGS="${MAKEARGS} -j${OPTARG}"
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

# we want to fail if anything fails
set -e
. tarball/config

BUILDROOT=build-tar

make -f tarball/rules clean BUILDROOT=${BUILDROOT}
make -f tarball/rules configure BUILDROOT=${BUILDROOT}
make -f tarball/rules ${MAKEARGS} build BUILDROOT=${BUILDROOT}

DESTDIR=tarball/${NAME}
rm -Rf ${DESTDIR}
mkdir -p ${DESTDIR}
make -f tarball/rules install BUILDROOT=${BUILDROOT} DESTDIR=${DESTDIR}

function pack() {
    TARBALL="$1"
    echo "Packing ${TARBALL} ...";
    tar cvzf "${TARBALL}" -C "${2}" "${NAME}"
    echo "Packing ${TARBALL} ... done.";
}

if test -z "${SUBPACKAGES}"; then
    # just simple package
    pack "${NAME}.tar.gz" "${DESTDIR}"
else
    # just simple package
    for PACKAGE in ${SUBPACKAGES}; do
        pack "${PACKAGE}.tar.gz" "${DESTDIR}/${PACKAGE}"
    done
fi
