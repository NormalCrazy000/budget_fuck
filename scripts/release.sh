#!/usr/bin/env bash
# Crea un tag di release su main e lo pusha su origin.
# La GitHub Actions pipeline si attiva automaticamente al push del tag
# e genera l'APK release allegato alla GitHub Release.
#
# Il tag è annotato: il suo messaggio contiene le note di rilascio, che la
# pipeline usa come descrizione della GitHub Release.
#
# Uso: ./scripts/release.sh <versione> [file-note]
# Esempi:
#   ./scripts/release.sh 1.2.0              # note generate dai commit feat/fix
#   ./scripts/release.sh 1.2.0 note.md      # note lette dal file (Markdown)

set -euo pipefail

# ── Validazione argomenti ──────────────────────────────────────────────────────

if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo "Uso: $0 <versione> [file-note]  (es. 1.2.0 note.md)"
  exit 1
fi

VERSION="$1"
TAG="v${VERSION}"
NOTES_FILE="${2:-}"

if [[ -n "$NOTES_FILE" && ! -s "$NOTES_FILE" ]]; then
  echo "Errore: il file di note '${NOTES_FILE}' non esiste o è vuoto."
  exit 1
fi

# Verifica che la versione segua il formato x.y.z
if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Errore: la versione deve seguire il formato x.y.z (es. 1.2.0)"
  exit 1
fi

# ── Controlli pre-tag ─────────────────────────────────────────────────────────

# Verifica che non ci siano modifiche non committate
if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "Errore: ci sono modifiche non committate. Committa prima di taggare."
  exit 1
fi

# Verifica che il tag non esista già
if git tag | grep -q "^${TAG}$"; then
  echo "Errore: il tag ${TAG} esiste già."
  exit 1
fi

# ── Aggiorna main ─────────────────────────────────────────────────────────────

echo "Aggiornamento main..."
git checkout main
git pull origin main

# ── Note di rilascio ──────────────────────────────────────────────────────────

# Senza file di note, le genera dai commit feat/fix dall'ultimo tag
# (i commit tecnici come chore, ci e docs non compaiono).
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
echo "Note di rilascio per ${TAG}:"
echo "────────────────────────────────────────"
cat "$NOTES_TMP"
echo "────────────────────────────────────────"

# ── Aggiorna la versione in pubspec.yaml ──────────────────────────────────────

BUILD=$(git rev-list --count HEAD)
sed -i "s/^version: .*/version: ${VERSION}+${BUILD}/" pubspec.yaml

# ── Commit di release e tag ───────────────────────────────────────────────────

git add pubspec.yaml
git commit -m "chore: release ${TAG}"

echo "Creazione tag ${TAG}..."
# --cleanup=verbatim mantiene le righe che iniziano con "#" (titoli Markdown)
git tag -a "$TAG" -F "$NOTES_TMP" --cleanup=verbatim

echo "Push main e tag su origin..."
git push origin main
git push origin "$TAG"

echo ""
echo "Tag ${TAG} pushato. La pipeline GitHub Actions sta buildando l'APK."
echo "Segui il progresso su: https://github.com/$(git remote get-url origin | sed 's/.*github.com[:/]\(.*\)\.git/\1/')/actions"
