#!/usr/bin/env bash
# Script to build Bullet on a target system.

set -euo pipefail

STARTDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$STARTDIR"

# The UNAME is either "Darwin" or otherwise. Note that env variable overrides
UNAME=${BULLETUNAME:-$(uname)}
# The MACH is either 'x86_64', 'aarch64', or assumed generic. Note env variable overrides.
MACH=${BULLETMACH:-$(uname -m)}
# Note that this sets BULLETDIR unless there is an environment variable of the same name
BULLETDIR=${BULLETDIR:-bullet3}
BULLET_REQUIRED_VERSION=${BULLET_REQUIRED_VERSION:-}

BUILDDIR=bullet-build

if ! command -v cmake >/dev/null 2>&1 ; then
    echo "ERROR: required command not found: cmake"
    exit 1
fi

if ! command -v git >/dev/null 2>&1 ; then
    echo "ERROR: required command not found: git"
    exit 1
fi

if ! command -v dotnet >/dev/null 2>&1 ; then
    echo "ERROR: required command not found: dotnet"
    exit 1
fi

DOTNET_REQUIRED_MAJOR=${DOTNET_REQUIRED_MAJOR:-8}
DOTNET_VERSION=$(dotnet --version)
DOTNET_MAJOR=${DOTNET_VERSION%%.*}
if (( DOTNET_MAJOR < DOTNET_REQUIRED_MAJOR )); then
    echo "ERROR: dotnet SDK ${DOTNET_REQUIRED_MAJOR}+ required. Found: ${DOTNET_VERSION}"
    exit 1
fi

if [[ ! -d "$BULLETDIR" ]]; then
    echo "=== BULLETDIR not found. Cloning Bullet into $BULLETDIR"
    git clone --depth 1 --single-branch --branch master https://github.com/bulletphysics/bullet3.git "$BULLETDIR"
fi

if [[ ! -f "$BULLETDIR/VERSION" ]]; then
    echo "ERROR: missing VERSION file in $BULLETDIR"
    exit 1
fi

BULLET_VERSION=$(cat "$BULLETDIR/VERSION")
BULLET_MAJOR=${BULLET_VERSION%%.*}
if [[ "$BULLET_MAJOR" != "3" ]]; then
    echo "ERROR: expected Bullet major version 3.x but found ${BULLET_VERSION} in ${BULLETDIR}"
    exit 1
fi

if [[ -n "$BULLET_REQUIRED_VERSION" && "$BULLET_VERSION" != "$BULLET_REQUIRED_VERSION" ]]; then
    echo "ERROR: expected Bullet version ${BULLET_REQUIRED_VERSION} but found ${BULLET_VERSION} in ${BULLETDIR}"
    exit 1
fi

cd "${BULLETDIR}"
mkdir -p "${BUILDDIR}"
cd "${BUILDDIR}"

echo "=== Building Bullet in dir ${BULLETDIR} for uname ${UNAME} and arch ${MACH} into ${BUILDDIR}"

if [[ "$UNAME" == "Darwin" ]] ; then
    echo "=== Running cmake for Darwin"
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
        echo "=== Running cmake for arch $MACH"
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
        echo "=== Running cmake for arch $MACH"
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
                -DBUILD_ENET=OFF \
                -DBUILD_PYBULLET=OFF \
                -DBUILD_UNIT_TESTS=OFF \
                -DBUILD_SHARED_LIBS=OFF \
                -DINSTALL_EXTRA_LIBS=ON \
                -DINSTALL_LIBS=ON \
                -DCMAKE_CXX_FLAGS="-fPIC" \
                -DCMAKE_BUILD_TYPE=Release
    else
        echo "=== Running cmake for generic arch"
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

if [[ -e Makefile ]] ; then
    echo "=== Building Makefile"
    make -j4
fi
if [[ -e "BULLET_PHYSICS.sln" ]] ; then
    echo "=== Building BULLET_PHYSICS.sln"
    dotnet build -c Release BULLET_PHYSICS.sln
fi

# make install

# As an alternative to installation, move the .a files in to a local directory
#    Good as it doesn't require admin privilages
echo "=== Cleaning out any existing lib and include directories"
cd "$STARTDIR"
rm -rf lib
rm -rf include

echo "=== Moving .a files into ../lib"
cd "$STARTDIR"
mkdir -p lib
while IFS= read -r -d '' afile ; do
    cp "$afile" lib
done < <(find "${BULLETDIR}/${BUILDDIR}" -name '*.a' -print0)

echo "=== Moving .h files into ../include"
cd "$STARTDIR"
mkdir -p include
cd "${BULLETDIR}/src"
while IFS= read -r -d '' file ; do
    xxxx="${STARTDIR}/include/$(dirname "$file")"
    mkdir -p "$xxxx"
    cp "$file" "$xxxx"
done < <(find . -name '*.h' -print0)

# Move Bullet's VERSION file into lib/ so BulletSim can reference it
echo "=== Moving Bullet's VERSION file into ../lib"
cd "$STARTDIR"
mkdir -p lib
cp "${BULLETDIR}/VERSION" lib/

echo "=== Moving .h files from Extras into ../include"
cd "$STARTDIR"
cd "${BULLETDIR}/Extras"
while IFS= read -r -d '' file ; do
    xxxx="${STARTDIR}/include/$(dirname "$file")"
    mkdir -p "$xxxx"
    cp "$file" "$xxxx"
done < <(find . -name '*.h' -print0)
echo "=== Moving .inl files from Extras into ../include"
while IFS= read -r -d '' file ; do
    xxxx="${STARTDIR}/include/$(dirname "$file")"
    mkdir -p "$xxxx"
    cp "$file" "$xxxx"
done < <(find . -name '*.inl' -print0)
