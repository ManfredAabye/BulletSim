#!/usr/bin/env bash
# Script for building "BulletSimVersionInfoFile" which contains application and git
#    version information.
# Also sets this information into the environment
# This file exists as an alternative to the building of the version info file in
#    .github/workflows/build.yml

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

BULLETDIR=${BULLETDIR:-bullet3}

BuildDate=$(date +%Y%m%d)
export BuildDate

BulletSimVersion=$(cat VERSION)
BulletSimGitVersion=$(git rev-parse HEAD)
BulletSimGitVersionShort=$(git rev-parse --short HEAD)
export BulletSimVersion BulletSimGitVersion BulletSimGitVersionShort

if [[ ! -d "$BULLETDIR" ]]; then
	echo "ERROR: BULLETDIR not found: $BULLETDIR"
	exit 1
fi

cd "$BULLETDIR"
BulletVersion=$(cat VERSION)
BulletGitVersion=$(git rev-parse HEAD)
BulletGitVersionShort=$(git rev-parse --short HEAD)
export BulletVersion BulletGitVersion BulletGitVersionShort

cd "$SCRIPT_DIR"
echo "BuildDate=$BuildDate" > BulletSimVersionInfo
echo "BulletSimVersion=$BulletSimVersion" >> BulletSimVersionInfo
echo "BulletSimGitVersion=$BulletSimGitVersion" >> BulletSimVersionInfo
echo "BulletSimGitVersionShort=$BulletSimGitVersionShort" >> BulletSimVersionInfo
echo "BulletVersion=$BulletVersion" >> BulletSimVersionInfo
echo "BulletGitVersion=$BulletGitVersion" >> BulletSimVersionInfo
echo "BulletGitVersionShort=$BulletGitVersionShort" >> BulletSimVersionInfo
