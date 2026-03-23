#!/usr/bin/env bash
# Script to fetch the Bullet Physics Engine sources, build same
#    using the 'buildBulletCMake.sh' script, and then build BulletSim
#    .so's using 'buildBulletSim.sh'.
# This captures the steps needed and will be replaced by better scripts
#    and Github actions.
#
# This can build two versions of Bullet: one of current version and another
#    of Bullet version 2.86 which is the version of Bullet that was
#    used in the BulletSim binaries distributed with OpenSimulator
#    from 2015 to 2022.
# This also applies the BulletSim patches to the Bullet sources.

set -euo pipefail

# Script directory so the script can be launched from anywhere.
BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$BASE"

if ! command -v git >/dev/null 2>&1 ; then
    echo "ERROR: required command not found: git"
    exit 1
fi

if ! command -v patch >/dev/null 2>&1 ; then
    echo "ERROR: required command not found: patch"
    exit 1
fi

# Set these values to 'yes' or 'no' to enable/disable fetching and building
FETCHBULLETSOURCES=${FETCHBULLETSOURCES:-no}
BUILDBULLET2=${BUILDBULLET2:-no}    # usually don't need the old version
BUILDBULLET3=${BUILDBULLET3:-yes}
# Optional explicit list of Bullet source directories to build, e.g.:
#   BULLET_BUILD_DIRS="bullet286 bullet3"
BULLET_BUILD_DIRS=${BULLET_BUILD_DIRS:-}

# Note that Bullet3 sources are build in "bullet3/" and the
#     these are copied into "bullet2/" and checkouted to the version 2 sources.

if [[ "$FETCHBULLETSOURCES" == "yes" ]] ; then
    cd "$BASE"
    rm -rf bullet3

    echo "=== Fetching Bullet Physics Engine sources into bullet3/"
    git clone https://github.com/bulletphysics/bullet3.git

    if [[ "$BUILDBULLET2" == "yes" ]] ; then
        cd "$BASE"
        echo "=== Creating bullet2/ of Bullet version 2.86"
        rm -rf bullet2
        cp -r bullet3 bullet2
        cd bullet2
        git checkout tags/2.86 -b tag-2.86
    fi

    echo "=== Applying BulletSim patches to bullet3"
    cd "$BASE/bullet3"
    shopt -s nullglob
    bullet3_patches=("$BASE"/000*)
    if (( ${#bullet3_patches[@]} == 0 )); then
        echo "ERROR: no patch files matching 000* were found in $BASE"
        exit 1
    fi
    for file in "${bullet3_patches[@]}" ; do
        patch -p1 < "$file"
    done
    shopt -u nullglob

    if [[ "$BUILDBULLET2" == "yes" ]] ; then
        echo "=== Applying BulletSim patches to bullet2"
        cd "$BASE/bullet2"
        shopt -s nullglob
        bullet2_patches=("$BASE"/2.86-00*)
        if (( ${#bullet2_patches[@]} == 0 )); then
            echo "ERROR: no patch files matching 2.86-00* were found in $BASE"
            exit 1
        fi
        for file in "${bullet2_patches[@]}" ; do
            patch -p1 < "$file"
        done
        shopt -u nullglob
    fi
fi

cd "$BASE"

build_dirs=()
if [[ -n "$BULLET_BUILD_DIRS" ]]; then
    # shellcheck disable=SC2206
    build_dirs=($BULLET_BUILD_DIRS)
else
    if [[ "$BUILDBULLET2" == "yes" ]] ; then
        build_dirs+=(bullet2)
    fi
    if [[ "$BUILDBULLET3" == "yes" ]] ; then
        build_dirs+=(bullet3)
    fi
fi

if (( ${#build_dirs[@]} == 0 )); then
    echo "ERROR: no Bullet directories selected to build. Set BULLET_BUILD_DIRS or BUILDBULLET2/BUILDBULLET3."
    exit 1
fi

for bullet_dir in "${build_dirs[@]}" ; do
    if [[ ! -d "$BASE/$bullet_dir" ]]; then
        echo "ERROR: selected Bullet directory does not exist: $BASE/$bullet_dir"
        exit 1
    fi
done

echo "=== Setting environment variables"
BuildDate=$(date +%Y%m%d)
BulletSimVersion=$(cat VERSION)
BulletSimGitVersion=$(git rev-parse HEAD)
BulletSimGitVersionShort=$(git rev-parse --short HEAD)
export BuildDate BulletSimVersion BulletSimGitVersion BulletSimGitVersionShort
first_bullet_dir="${build_dirs[0]}"
cd "$first_bullet_dir"
BulletVersion=$(cat VERSION)
BulletGitVersion=$(git rev-parse HEAD)
BulletGitVersionShort=$(git rev-parse --short HEAD)
export BulletVersion BulletGitVersion BulletGitVersionShort

echo "=== Creating version information file"
cd "$BASE"
rm -f BulletSimVersionInfo
touch BulletSimVersionInfo
echo "BuildDate=$BuildDate" > BulletSimVersionInfo
echo "BulletSimVersion=$BulletSimVersion" >> BulletSimVersionInfo
echo "BulletSimGitVersion=$BulletSimGitVersion" >> BulletSimVersionInfo
echo "BulletSimGitVersionShort=$BulletSimGitVersionShort" >> BulletSimVersionInfo
echo "BulletVersion=$BulletVersion" >> BulletSimVersionInfo
echo "BulletGitVersion=$BulletGitVersion" >> BulletSimVersionInfo
echo "BulletGitVersionShort=$BulletGitVersionShort" >> BulletSimVersionInfo
cat BulletSimVersionInfo

echo "=== removing libBulletSim-*"
rm -f libBulletSim-*.so

for bullet_dir in "${build_dirs[@]}" ; do
    echo "=== building ${bullet_dir}"
    cd "$BASE"
    # Build the Bullet physics engine
    BULLETDIR="$bullet_dir" bash ./buildBulletCMake.sh
    # Build the BulletSim glue/wrapper statically linked to Bullet
    bash ./buildBulletSim.sh
done
