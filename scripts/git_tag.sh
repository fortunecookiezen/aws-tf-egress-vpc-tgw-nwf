#!/usr/bin/env bash
set -euf -o pipefail
VERSION=$1
git tag -a v$VERSION -m "Releasing version v$VERSION"

git push origin v$VERSION

echo "Module versions are: "
git tag -l -n3
