#!/usr/bin/env bash
# Script to build Bullet on a target system.

set -euo pipefail

STARTDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$STARTDIR"

ECHOLINE="____________________________________________________________________________________________"
SCRIPT_START_TIME=$(date +%s)

# Farben für bessere Lesbarkeit
COLOR_INFO='\033[1;36m'    # Cyan
COLOR_SUCCESS='\033[1;32m'  # Grün
COLOR_ERROR='\033[1;31m'    # Rot
COLOR_RESET='\033[0m'       # Zurücksetzen

print_section() {
    echo ""
    echo "$ECHOLINE"
    echo -e "${COLOR_INFO}$1${COLOR_RESET}"
    echo "$ECHOLINE"
    echo ""
}

# The UNAME is either "Darwin" or otherwise. Note that env variable overrides
UNAME=${BULLETUNAME:-$(uname)}
# The MACH is either 'x86_64', 'aarch64', or assumed generic. Note env variable overrides.
MACH=${BULLETMACH:-$(uname -m)}
# Note that this sets BULLETDIR unless there is an environment variable of the same name
BULLETDIR=${BULLETDIR:-bullet3}
BULLET_REQUIRED_VERSION=${BULLET_REQUIRED_VERSION:-}

BUILDDIR=bullet-build

if ! command -v cmake >/dev/null 2>&1 ; then
    echo "$ECHOLINE"
    echo -e "${COLOR_ERROR}ERROR: required command not found: cmake${COLOR_RESET}"
    echo "$ECHOLINE"
    exit 1
fi

if ! command -v git >/dev/null 2>&1 ; then
    echo "$ECHOLINE"
    echo -e "${COLOR_ERROR}ERROR: required command not found: git${COLOR_RESET}"
    echo "$ECHOLINE"
    exit 1
fi

if [[ ! -d "$BULLETDIR" ]]; then
    echo "$ECHOLINE"
    echo "=== BULLETDIR not found. Cloning Bullet into $BULLETDIR"
    echo "$ECHOLINE"
    git clone --depth 1 --single-branch --branch master https://github.com/bulletphysics/bullet3.git "$BULLETDIR"
fi

if [[ ! -f "$BULLETDIR/VERSION" ]]; then
    echo "$ECHOLINE"
    echo -e "${COLOR_ERROR}ERROR: missing VERSION file in $BULLETDIR${COLOR_RESET}"
    echo "$ECHOLINE"
    exit 1
fi

BULLET_VERSION=$(cat "$BULLETDIR/VERSION")
BULLET_MAJOR=${BULLET_VERSION%%.*}
if [[ "$BULLET_MAJOR" != "3" ]]; then
    echo "$ECHOLINE"
    echo -e "${COLOR_ERROR}ERROR: expected Bullet major version 3.x but found ${BULLET_VERSION} in ${BULLETDIR}${COLOR_RESET}"
    echo "$ECHOLINE"
    exit 1
fi

if [[ -n "$BULLET_REQUIRED_VERSION" && "$BULLET_VERSION" != "$BULLET_REQUIRED_VERSION" ]]; then
    echo "$ECHOLINE"
    echo -e "${COLOR_ERROR}ERROR: expected Bullet version ${BULLET_REQUIRED_VERSION} but found ${BULLET_VERSION} in ${BULLETDIR}${COLOR_RESET}"
    echo "$ECHOLINE"
    exit 1
fi

cd "${BULLETDIR}"
mkdir -p "${BUILDDIR}"
cd "${BUILDDIR}"

print_section "PHASE 1: CMake Configuration für ${UNAME} / ${MACH}"

if [[ "$UNAME" == "Darwin" ]] ; then
    echo "$ECHOLINE"
    echo "=== Running cmake for Darwin"
    echo "$ECHOLINE"
    cmake .. -G "Unix Makefiles" \
                -DBUILD_BULLET3=ON \
                -DBUILD_EXTRAS=ON \
                    -DBUILD_INVERSE_DYNAMIC_EXTRA=OFF \
                    -DBUILD_BULLET_ROBOTICS_GUI_EXTRA=OFF \
                    -DBUILD_BULLET_ROBOTICS_EXTRA=OFF \
                    -DBUILD_OBJ2SDF_EXTRA=OFF \
                    -DBUILD_SERIALIZE_EXTRA=OFF \
                    -DBUILD_CONVEX_DECOMPOSITION_EXTRA=ON \
                    -DBUILD_HACD_EXTRA=ON \
                    -DBUILD_GIMPACTUTILS_EXTRA=OFF \
                    -DBUILD_CPU_DEMOS=OFF \
                    -DBUILD_BULLET2_DEMOS=OFF \
                    -DBUILD_OPENGL3_DEMOS=OFF \
                -DBUILD_ENET=OFF \
                -DBUILD_PYBULLET=OFF \
                -DBUILD_UNIT_TESTS=OFF \
                -DBUILD_SHARED_LIBS=OFF \
                -DINSTALL_EXTRA_LIBS=ON \
                -DINSTALL_LIBS=ON \
                -DCMAKE_OSX_ARCHITECTURES="x86_64;arm64" \
                -DCMAKE_CXX_FLAGS="-arch x86_64 -arch arm64" \
                -DCMAKE_C_FLAGS="-arch x86_64 -arch arm64 -fPIC -O2" \
                -DCMAKE_EXE_LINKER_FLAGS="-arch x86_64 -arch arm64" \
                -DCMAKE_VERBOSE_MAKEFILE="on" \
                -DCMAKE_BUILD_TYPE=Release
elif [[ "$UNAME" == MINGW64* || "$UNAME" == MSYS* ]] ; then
    echo "$ECHOLINE"
    echo "=== Running cmake for MINGW64/MSYS (Visual Studio)"
    echo "$ECHOLINE"
    cmake .. -G "Visual Studio 17 2022" \
            -DBUILD_BULLET3=ON \
            -DBUILD_EXTRAS=ON \
                -DBUILD_INVERSE_DYNAMIC_EXTRA=OFF \
                -DBUILD_BULLET_ROBOTICS_GUI_EXTRA=OFF \
                -DBUILD_BULLET_ROBOTICS_EXTRA=OFF \
                -DBUILD_OBJ2SDF_EXTRA=OFF \
                -DBUILD_SERIALIZE_EXTRA=OFF \
                -DBUILD_CONVEX_DECOMPOSITION_EXTRA=ON \
                -DBUILD_HACD_EXTRA=ON \
                -DBUILD_GIMPACTUTILS_EXTRA=OFF \
            -DBUILD_CPU_DEMOS=OFF \
            -DBUILD_BULLET2_DEMOS=OFF \
            -DBUILD_OPENGL3_DEMOS=OFF \
            -DBUILD_ENET=OFF \
            -DBUILD_PYBULLET=OFF \
            -DBUILD_UNIT_TESTS=OFF \
            -DBUILD_SHARED_LIBS=OFF \
            -DINSTALL_EXTRA_LIBS=ON \
            -DINSTALL_LIBS=ON \
            -DCMAKE_CXX_FLAGS="-fPIC" \
            -DCMAKE_BUILD_TYPE=Release
else
    if [[ "$MACH" == "x86_64" ]] 
    then
        echo "$ECHOLINE"
        echo "=== Running cmake for arch $MACH"
        echo "$ECHOLINE"
        cmake .. -G "Unix Makefiles" \
                -DBUILD_BULLET3=ON \
                -DBUILD_EXTRAS=ON \
                    -DBUILD_INVERSE_DYNAMIC_EXTRA=OFF \
                    -DBUILD_BULLET_ROBOTICS_GUI_EXTRA=OFF \
                    -DBUILD_BULLET_ROBOTICS_EXTRA=OFF \
                    -DBUILD_OBJ2SDF_EXTRA=OFF \
                    -DBUILD_SERIALIZE_EXTRA=OFF \
                    -DBUILD_CONVEX_DECOMPOSITION_EXTRA=ON \
                    -DBUILD_HACD_EXTRA=ON \
                    -DBUILD_GIMPACTUTILS_EXTRA=OFF \
                -DBUILD_CPU_DEMOS=OFF \
                -DBUILD_BULLET2_DEMOS=OFF \
                -DBUILD_OPENGL3_DEMOS=OFF \
                -DBUILD_ENET=OFF \
                -DBUILD_PYBULLET=OFF \
                -DBUILD_UNIT_TESTS=OFF \
                -DBUILD_SHARED_LIBS=OFF \
                -DINSTALL_EXTRA_LIBS=ON \
                -DINSTALL_LIBS=ON \
                -DCMAKE_CXX_FLAGS="-fPIC" \
                -DCMAKE_BUILD_TYPE=Release
    elif [[ "$MACH" == "aarch64" ]] 
    then
        echo "$ECHOLINE"
        echo "=== Running cmake for arch $MACH"
        echo "$ECHOLINE"
        cmake .. -G "Unix Makefiles" \
                -DBUILD_BULLET3=ON \
                -DBUILD_EXTRAS=ON \
                    -DBUILD_INVERSE_DYNAMIC_EXTRA=OFF \
                    -DBUILD_BULLET_ROBOTICS_GUI_EXTRA=OFF \
                    -DBUILD_BULLET_ROBOTICS_EXTRA=OFF \
                    -DBUILD_OBJ2SDF_EXTRA=OFF \
                    -DBUILD_SERIALIZE_EXTRA=OFF \
                    -DBUILD_CONVEX_DECOMPOSITION_EXTRA=ON \
                    -DBUILD_HACD_EXTRA=ON \
                    -DBUILD_GIMPACTUTILS_EXTRA=OFF \
                -DBUILD_CPU_DEMOS=OFF \
                -DBUILD_BULLET2_DEMOS=OFF \
                -DBUILD_OPENGL3_DEMOS=OFF \
                -DBUILD_ENET=OFF \
                -DBUILD_PYBULLET=OFF \
                -DBUILD_UNIT_TESTS=OFF \
                -DBUILD_SHARED_LIBS=OFF \
                -DINSTALL_EXTRA_LIBS=ON \
                -DINSTALL_LIBS=ON \
                -DCMAKE_CXX_FLAGS="-fPIC" \
                -DCMAKE_BUILD_TYPE=Release
    else
        echo "$ECHOLINE"
        echo "=== Running cmake for generic arch"
        echo "$ECHOLINE"
        cmake .. -G "Unix Makefiles" \
                -DBUILD_BULLET3=ON \
                -DBUILD_EXTRAS=ON \
                    -DBUILD_INVERSE_DYNAMIC_EXTRA=OFF \
                    -DBUILD_BULLET_ROBOTICS_GUI_EXTRA=OFF \
                    -DBUILD_BULLET_ROBOTICS_EXTRA=OFF \
                    -DBUILD_OBJ2SDF_EXTRA=OFF \
                    -DBUILD_SERIALIZE_EXTRA=OFF \
                    -DBUILD_CONVEX_DECOMPOSITION_EXTRA=ON \
                    -DBUILD_HACD_EXTRA=ON \
                    -DBUILD_GIMPACTUTILS_EXTRA=OFF \
                -DBUILD_CPU_DEMOS=OFF \
                -DBUILD_BULLET2_DEMOS=OFF \
                -DBUILD_OPENGL3_DEMOS=OFF \
                -DBUILD_ENET=OFF \
                -DBUILD_PYBULLET=OFF \
                -DBUILD_UNIT_TESTS=OFF \
                -DBUILD_SHARED_LIBS=OFF \
                -DINSTALL_EXTRA_LIBS=ON \
                -DINSTALL_LIBS=ON \
                -DCMAKE_CXX_FLAGS="-fPIC" \
                -DCMAKE_BUILD_TYPE=Release
    fi
fi

print_section "PHASE 2: CMake Build - Kompilierung aller Libraries"
echo "$ECHOLINE"
echo "Status: Starte cmake --build mit 4 parallelen Jobs..."
echo "$ECHOLINE"
CMAKE_BUILD_START=$(date +%s)
# shellcheck disable=SC2181
if cmake --build . --config Release --parallel 4 2>&1 | tee /tmp/cmake_build.log ; then
    CMAKE_BUILD_END=$(date +%s)
    CMAKE_BUILD_DURATION=$((CMAKE_BUILD_END - CMAKE_BUILD_START))
    echo "$ECHOLINE"
    echo -e "${COLOR_SUCCESS}✓ Erfolgreich kompiliert (${CMAKE_BUILD_DURATION}s)${COLOR_RESET}"
    echo "$ECHOLINE"
else
    CMAKE_BUILD_END=$(date +%s)
    CMAKE_BUILD_DURATION=$((CMAKE_BUILD_END - CMAKE_BUILD_START))
    echo "$ECHOLINE"
    echo -e "${COLOR_ERROR}✗ Fehler beim Build (${CMAKE_BUILD_DURATION}s)${COLOR_RESET}"
    echo "$ECHOLINE"
    exit 1
fi

# make install

# As an alternative to installation, move the .a files in to a local directory
#    Good as it doesn't require admin privilages
echo "$ECHOLINE"
echo "=== Cleaning out any existing lib and include directories"
echo "$ECHOLINE"
cd "$STARTDIR"
rm -rf lib
rm -rf include

print_section "PHASE 3: Kopiere .a (statische Bibliotheken) nach ./lib"
cd "$STARTDIR"
mkdir -p lib
A_COUNT=0
while IFS= read -r -d '' afile ; do
    cp "$afile" lib
    A_COUNT=$((A_COUNT + 1))
done < <(find "${BULLETDIR}/${BUILDDIR}" -name '*.a' -print0)
echo "$ECHOLINE"
echo -e "${COLOR_SUCCESS}✓ $A_COUNT statische Bibliotheken kopiert:${COLOR_RESET}"
echo "$ECHOLINE"
find lib -maxdepth 1 -name '*.a' -type f -printf '%f\n' | sort | sed 's|^|  |'
echo ""

print_section "PHASE 4: Kopiere Header-Dateien (.h) nach ./include"
cd "$STARTDIR"
mkdir -p include
H_COUNT=0
echo "Kopiere aus src/..."
cd "${BULLETDIR}/src"
while IFS= read -r -d '' file ; do
    xxxx="${STARTDIR}/include/$(dirname "$file")"
    mkdir -p "$xxxx"
    cp "$file" "$xxxx"
    H_COUNT=$((H_COUNT + 1))
done < <(find . -name '*.h' -print0)
echo "  $H_COUNT Header aus src/"
EXTRA_H=0
echo "Kopiere aus Extras/..."
cd "$STARTDIR"
cd "${BULLETDIR}/Extras"
while IFS= read -r -d '' file ; do
    xxxx="${STARTDIR}/include/$(dirname "$file")"
    mkdir -p "$xxxx"
    cp "$file" "$xxxx"
    EXTRA_H=$((EXTRA_H + 1))
done < <(find . -name '*.h' -print0)
echo "  $EXTRA_H Header aus Extras/"
EXTRA_INL=0
echo "Kopiere .inl aus Extras/..."
while IFS= read -r -d '' file ; do
    xxxx="${STARTDIR}/include/$(dirname "$file")"
    mkdir -p "$xxxx"
    cp "$file" "$xxxx"
    EXTRA_INL=$((EXTRA_INL + 1))
done < <(find . -name '*.inl' -print0)
echo "  $EXTRA_INL .inl Dateien aus Extras/"
TOTAL_H=$((H_COUNT + EXTRA_H + EXTRA_INL))
echo "$ECHOLINE"
echo -e "${COLOR_SUCCESS}✓ Insgesamt $TOTAL_H Header-Dateien kopiert${COLOR_RESET}"
echo "$ECHOLINE"

print_section "PHASE 5: Versionsinfo speichern"
cd "$STARTDIR"
mkdir -p lib
cp "${BULLETDIR}/VERSION" lib/
BULLET_VERSION=$(cat lib/VERSION)
echo -e "${COLOR_SUCCESS}✓ Bullet Version $BULLET_VERSION in lib/VERSION gespeichert${COLOR_RESET}"

print_section "BUILD ABGESCHLOSSEN"
echo "$ECHOLINE"

SCRIPT_END_TIME=$(date +%s)
SCRIPT_TOTAL_DURATION=$((SCRIPT_END_TIME - SCRIPT_START_TIME))

# Statistik sammeln
echo "$ECHOLINE"
echo -e "${COLOR_SUCCESS}✓ BUILD ERFOLGREICH${COLOR_RESET}"
echo "$ECHOLINE"
echo ""
echo "Zusammenfassung:"
echo "  • Bullet Version:        $BULLET_VERSION"
echo "  • Statische Libraries:   $A_COUNT (.a Dateien in ./lib)"
echo "  • Header-Dateien:        $TOTAL_H (.h und .inl in ./include)"
echo "  • Build-Dauer:           ${CMAKE_BUILD_DURATION}s"
echo "  • Gesamt-Dauer:          ${SCRIPT_TOTAL_DURATION}s"
echo ""
echo "Fertig: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""
echo "$ECHOLINE"
echo -e "${COLOR_INFO}Das Bullet Physics Framework ist bereit für BulletSim!${COLOR_RESET}"
echo -e "${COLOR_INFO}Nächster Schritt: ./l03buildBulletSim.sh ausführen${COLOR_RESET}"
echo "$ECHOLINE"
echo ""

