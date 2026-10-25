#!/usr/bin/env bash
# Creates a release tag on main and pushes it to origin.
# The GitHub Actions pipeline starts automatically on the tag push
# and builds the release APK attached to the GitHub Release.
#
# The tag is annotated: its message holds the release notes, which the
# pipeline uses as the GitHub Release description.
#
# Usage: ./scripts/release.sh <version> [notes-file]
# Examples:
#   ./scripts/release.sh 1.2.0              # notes generated from feat/fix commits
#   ./scripts/release.sh 1.2.0 notes.md     # notes read from the file (Markdown)

set -euo pipefail

# ── Argument validation ──────────────────────────────────────────────────────────

if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo "Usage: $0 <version> [notes-file]  (e.g. 1.2.0 notes.md)"
  exit 1
fi

VERSION="$1"
TAG="v${VERSION}"
NOTES_FILE="${2:-}"

if [[ -n "$NOTES_FILE" && ! -s "$NOTES_FILE" ]]; then
  echo "Error: the notes file '${NOTES_FILE}' does not exist or is empty."
  exit 1
fi

# Check the version follows the x.y.z format
if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Error: the version must follow the x.y.z format (e.g. 1.2.0)"
  exit 1
fi

# ── Pre-tag checks ───────────────────────────────────────────────────────────────

# Check there are no uncommitted changes
if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "Error: there are uncommitted changes. Commit before tagging."
  exit 1
fi

# Check the tag does not exist yet
if git tag | grep -q "^${TAG}$"; then
  echo "Error: tag ${TAG} already exists."
  exit 1
fi

# ── Update main ──────────────────────────────────────────────────────────────────

echo "Updating main..."
git checkout main
git pull origin main

# ── Release notes ────────────────────────────────────────────────────────────────

# Without a notes file, generate them from feat/fix commits since the last tag
# (technical commits such as chore, ci and docs are left out).
NOTES_TMP=$(mktemp)
trap 'rm -f "$NOTES_TMP"' EXIT

if [[ -n "$NOTES_FILE" ]]; then
  cp "$NOTES_FILE" "$NOTES_TMP"
else
  PREV_TAG=$(git describe --tags --abbrev=0 2>/dev/null || true)
  RANGE="${PREV_TAG:+${PREV_TAG}..}HEAD"
  section() {
    git log "$RANGE" --no-merges --format=%s \
      | sed -nE "s/^$1(\([^)]*\))?!?: (.*)/- \2/p"
  }
  FEATS=$(section feat)
  FIXES=$(section fix)
  {
    if [[ -n "$FEATS" ]]; then printf "## What's new\n\n%s\n\n" "$FEATS"; fi
    if [[ -n "$FIXES" ]]; then printf '## Fixes\n\n%s\n\n' "$FIXES"; fi
    if [[ -z "$FEATS$FIXES" ]]; then
      printf 'Maintenance and technical updates.\n'
    fi
  } > "$NOTES_TMP"
fi

echo ""
echo "Release notes for ${TAG}:"
echo "────────────────────────────────────────"
cat "$NOTES_TMP"
echo "────────────────────────────────────────"

# ── Update the version in pubspec.yaml ───────────────────────────────────────────

BUILD=$(git rev-list --count HEAD)
sed -i "s/^version: .*/version: ${VERSION}+${BUILD}/" pubspec.yaml

# ── Release commit and tag ───────────────────────────────────────────────────────

git add pubspec.yaml
git commit -m "chore: release ${TAG}"

echo "Creating tag ${TAG}..."
# --cleanup=verbatim keeps lines starting with "#" (Markdown headings)
git tag -a "$TAG" -F "$NOTES_TMP" --cleanup=verbatim

echo "Pushing main and tag to origin..."
git push origin main
git push origin "$TAG"

echo ""
echo "Tag ${TAG} pushed. The GitHub Actions pipeline is building the APK."
echo "Follow the progress at: https://github.com/$(git remote get-url origin | sed 's/.*github.com[:/]\(.*\)\.git/\1/')/actions"
