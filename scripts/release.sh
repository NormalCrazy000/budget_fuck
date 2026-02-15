#!/bin/bash

# Exit on error
set -e

# Check if version argument is provided
if [ -z "$1" ]; then
    echo "Usage: ./scripts/release.sh <version>"
    echo "Example: ./scripts/release.sh 1.0.1"
    exit 1
fi

VERSION=$1

# Ensure we are on develop branch
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "develop" ]; then
    echo "Error: You must be on the 'develop' branch to release."
    exit 1
fi

# Ensure git is clean
if [ -n "$(git status --porcelain)" ]; then
    echo "Error: Git working directory is not clean. Please commit or stash changes."
    exit 1
fi

echo "🚀 Starting release process for version $VERSION..."

# 1. Update version in pubspec.yaml
echo "📝 Updating pubspec.yaml..."
# This regex looks for 'version: x.y.z+n' and replaces it with 'version: $VERSION'
# Start with a simpler replacement assuming standard format
sed -i "s/^version: .*/version: $VERSION/" pubspec.yaml

# 2. Commit the version bump
echo "💾 Committing version bump..."
git add pubspec.yaml
git commit -m "chore(release): bump version to $VERSION"

# 3. Create the tag
echo "🏷️ Creating tag v$VERSION..."
git tag -a "v$VERSION" -m "Release $VERSION"

# 4. Merge to main
echo "🔀 Merging develop into main..."
git checkout main
git pull origin main
git merge develop --no-ff -m "chore(release): merge release v$VERSION from develop"


# 5. Push main and tag
echo "⬆️ Pushing main and tag..."
git push origin main
git push origin "v$VERSION"

# 6. Return to develop
git checkout develop

# 7. Calculate next version (Patch bump + SNAPSHOT)
# Split version by '.'
IFS='.' read -r -a parts <<< "$VERSION"
major=${parts[0]}
minor=${parts[1]}
patch=${parts[2]}

# If patch is missing (e.g. 1.0), default to 0
if [ -z "$patch" ]; then patch=0; fi

next_patch=$((patch + 1))
NEXT_VERSION="$major.$minor.$next_patch-SNAPSHOT"

echo "🔧 Bumping develop to $NEXT_VERSION..."

sed -i "s/^version: .*/version: $NEXT_VERSION/" pubspec.yaml

# 8. Commit snapshot bump
git add pubspec.yaml
git commit -m "chore(release): bump to v$NEXT_VERSION"

# 9. Push develop
echo "⬆️ Pushing develop..."
git push origin develop

echo "✅ Release v$VERSION completed! Develop is now at $NEXT_VERSION."
