#!/bin/bash

# Exit on error
set -e

# Check arguments
if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Usage: ./scripts/release.sh <version> <next-version>"
    echo "Example: ./scripts/release.sh 2.2.0 2.2.1-SNAPSHOT"
    exit 1
fi

VERSION=$1
NEXT_VERSION=$2

# Ensure git is clean
if [ -n "$(git status --porcelain)" ]; then
    echo "Error: Git working directory is not clean. Please commit or stash changes."
    exit 1
fi

# Ensure we are on develop
git checkout develop

echo "Starting release $VERSION..."

# 1. Commit release version on develop
sed -i "s/^version: .*/version: $VERSION/" pubspec.yaml
git add pubspec.yaml
git commit -m "bump version to $VERSION"

# 2. Tag
git tag -a "v$VERSION" -m "Release $VERSION"
echo "Tagged v$VERSION"

# 3. Merge develop into main
git checkout main
git pull origin main
git merge develop

# 4. Return to develop and bump to next version
git checkout develop
sed -i "s/^version: .*/version: $NEXT_VERSION/" pubspec.yaml
git add pubspec.yaml
git commit -m "bump to $NEXT_VERSION"

echo ""
echo "Done. Current version: $NEXT_VERSION. Tag v$VERSION created."
echo "Push with: git push origin develop && git push origin main && git push origin v$VERSION"
