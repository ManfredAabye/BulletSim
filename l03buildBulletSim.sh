#!/usr/bin/env bash
# Script to build BulletSim Linux binaries.
# This presumes the bins and includes for Bullet are in BLIBDIR and BINCLUDEDIR

set -euo pipefail

# Script directory so this can be run from anywhere.
BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$BASE"

ECHOLINE="____________________________________________________________________________________________"

# Farben für bessere Lesbarkeit
COLOR_INFO='\033[1;36m'    # Cyan
COLOR_SUCCESS='\033[1;32m'  # Grün
COLOR_ERROR='\033[1;31m'    # Rot
COLOR_RESET='\033[0m'       # Zurücksetzen

BLIBDIR=${BLIBDIR:-"$BASE/lib"}
BINCLUDEDIR=${BINCLUDEDIR:-"$BASE/include"}

# Output file is ${TARGETBASE}-${BULLETVERSION}-${BUILDDATE}-${ARCH}.so
TARGETBASE=${TARGETBASE:-libBulletSim}

# CC=gcc
# CC=/usr/bin/g++
CC=${CC:-c++}
# LD=/usr/bin/g++
LD=${LD:-c++}

UNAME=${UNAME:-$(uname)}
ARCH=${ARCH:-$(uname -m)}

if [[ ! -f "${BLIBDIR}/VERSION" ]]; then
    echo "$ECHOLINE"
    echo -e "${COLOR_ERROR}✗ ERROR: missing ${BLIBDIR}/VERSION. Bullet zuerst bauen (l02buildBulletCMake.sh).${COLOR_RESET}"
    echo "$ECHOLINE"
    exit 1
fi

if [[ ! -f "$BASE/VERSION" ]]; then
    echo "$ECHOLINE"
    echo -e "${COLOR_ERROR}✗ ERROR: missing $BASE/VERSION${COLOR_RESET}"
    echo "$ECHOLINE"
    exit 1
fi

if ! command -v "$CC" >/dev/null 2>&1 ; then
    echo "$ECHOLINE"
    echo -e "${COLOR_ERROR}✗ ERROR: Compiler nicht gefunden: $CC${COLOR_RESET}"
    echo "$ECHOLINE"
    exit 1
fi

if ! command -v "$LD" >/dev/null 2>&1 ; then
    echo "$ECHOLINE"
    echo -e "${COLOR_ERROR}✗ ERROR: Linker nicht gefunden: $LD${COLOR_RESET}"
    echo "$ECHOLINE"
    exit 1
fi

# Version of the Bullet engine that is being statically linked
BULLETVERSION=$(cat "${BLIBDIR}/VERSION")
# Version of the BulletSim glue that is being built and included
BULLETSIMVERSION=$(cat "VERSION")

BUILDDATE=$(date "+%Y%m%d")

# Kludge for building libBulletSim.so with different library dependencies
#    As of 20130424, 64bit Ubuntu needs to wrap memcpy so it doesn't pull in glibc 2.14.
#    The wrap is not needed on Ubuntu 32bit and, in fact, causes crashes.
if [[ "$ARCH" == "x86_64" ]] ; then
    WRAPMEMCPY=-Wl,--wrap=memcpy
else
    WRAPMEMCPY=
fi

# Pass version information into compilations as C++ variables
VERSIONCFLAGS=("-DBULLETVERSION=$BULLETVERSION" "-DBULLETSIMVERSION=$BULLETSIMVERSION")
case $UNAME in
    "Linux")
        TARGET=${TARGETBASE}-${BULLETVERSION}-${BUILDDATE}-${ARCH}.so
        CFLAGS=(-I"${BINCLUDEDIR}" -fPIC -g -fpermissive "${VERSIONCFLAGS[@]}")
        LFLAGS=(-shared "-Wl,-soname,${TARGET}" -o "${TARGET}")
        if [[ -n "$WRAPMEMCPY" ]] ; then
            LFLAGS=("$WRAPMEMCPY" "${LFLAGS[@]}")
        fi
        ;;
    "Darwin")
        CC=gcc
        LD=g++
        TARGET=${TARGETBASE}-${BULLETVERSION}-${BUILDDATE}-universal.dylib
        CFLAGS=(-arch arm64 -arch x86_64 -O3 -I"${BINCLUDEDIR}" -g "${VERSIONCFLAGS[@]}")
        LFLAGS=(-v -dynamiclib -arch arm64 -arch x86_64 -o "${TARGET}")
        ;;
    *)
        TARGET=${TARGETBASE}-${BULLETVERSION}-${BUILDDATE}-${ARCH}.so
        CFLAGS=(-I"${BINCLUDEDIR}" -fPIC -g -fpermissive "${VERSIONCFLAGS[@]}")
        LFLAGS=(-shared "-Wl,-soname,${TARGET}" -o "${TARGET}")
        if [[ -n "$WRAPMEMCPY" ]] ; then
            LFLAGS=("$WRAPMEMCPY" "${LFLAGS[@]}")
        fi
        ;;
esac

# All of the Bullet bin files
# BULLETLIBS=$(ls ${BLIBDIR}/*.a)
BULLETLIBS=(
    "${BLIBDIR}/libBulletDynamics.a"
    "${BLIBDIR}/libBulletCollision.a"
    "${BLIBDIR}/libLinearMath.a"
    "${BLIBDIR}/libHACD.a"
)

# Just build everything
echo "$ECHOLINE"
echo -e "${COLOR_INFO}=== Erstelle $TARGET${COLOR_RESET}"
echo -e "${COLOR_INFO}    BulletSim-Version: ${BULLETSIMVERSION}${COLOR_RESET}"
echo -e "${COLOR_INFO}    Bullet-Version: ${BULLETVERSION}${COLOR_RESET}"
echo "$ECHOLINE"
"$CC" "${CFLAGS[@]}" -c API2.cpp
"$CC" "${CFLAGS[@]}" -c BulletSim.cpp
"$LD" "${LFLAGS[@]}" API2.o BulletSim.o "${BULLETLIBS[@]}"

echo "$ECHOLINE"
echo -e "${COLOR_SUCCESS}✓ BUILD ERFOLGREICH${COLOR_RESET}"
echo -e "${COLOR_SUCCESS}✓ Output: $TARGET${COLOR_RESET}"
echo "$ECHOLINE"
echo ""
