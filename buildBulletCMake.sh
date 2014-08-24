#! /bin/bash
# Script to build Bullet on a target system.

STARTDIR=$(pwd)

UNAME=$(uname)
MACH=$(uname -m)
BULLET=bullet-2.82

cd $BULLET
mkdir -p bullet-build
cd bullet-build

if [[ "$UNAME" == "Darwin" ]] ; then
    cmake .. -G "Xcode" \
            -DBUILD_EXTRAS=on \
            -DBUILD_DEMOS=off \
            -DBUILD_SHARED_LIBS=off \
            -DINSTALL_LIBS=on \
            -DINSTALL_EXTRA_LIBS=on \
            -DCMAKE_OSX_ARCHITECTURES='ppc;i386;x86_64' \
            -DCMAKE_CXX_FLAGS="-fPIC" \
            -DCMAKE_BUILD_TYPE=Release
else
    if [[ "$MACH" == "x86_64" ]] ; then
        cmake .. -G "Unix Makefiles" \
                -DBUILD_EXTRAS=on \
                -DBUILD_DEMOS=off \
                -DBUILD_SHARED_LIBS=off \
                -DINSTALL_LIBS=on \
                -DINSTALL_EXTRA_LIBS=on \
                -DCMAKE_CXX_FLAGS="-fPIC" \
                -DCMAKE_BUILD_TYPE=Release
    else
        cmake .. -G "Unix Makefiles" \
                -DBUILD_EXTRAS=on \
                -DBUILD_DEMOS=off \
                -DBUILD_SHARED_LIBS=off \
                -DINSTALL_LIBS=on \
                -DINSTALL_EXTRA_LIBS=on \
                -DCMAKE_BUILD_TYPE=Release
    fi
fi

make -j4

# make install

# As an alternative, move the .a files in to a local directory
#    Good as it doesn't require admin privilages
cd "$STARTDIR"
mkdir -p lib
cd "${BULLET}/bullet-build"
cp */*/*.a */*/*/*.a ../../lib

cd "$STARTDIR"
mkdir -p include
cd "${BULLET}/src"
cp *.h ../../include
for file in $(find . -name \*.h) ; do xxxx="../../include/$(dirname $file)" ; mkdir -p "$xxxx"; cp "$file" "$xxxx" ; done
cd ../Extras
for file in $(find . -name \*.h) ; do xxxx="../../include/$(dirname $file)" ; mkdir -p "$xxxx"; cp "$file" "$xxxx" ; done
for file in $(find . -name \*.inl) ; do xxxx="../../include/$(dirname $file)" ; mkdir -p "$xxxx"; cp "$file" "$xxxx" ; done


