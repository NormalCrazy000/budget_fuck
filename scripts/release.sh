#!/usr/bin/env bash
# Crea un tag di release sul branch main e lo pusha su origin.
# La GitHub Actions pipeline si attiva automaticamente al push del tag
# e genera l'APK release allegato alla GitHub Release.
#
# Uso: ./scripts/tag_release.sh <versione>
# Esempio: ./scripts/tag_release.sh 1.2.0

set -euo pipefail

# ── Validazione argomenti ──────────────────────────────────────────────────────

if [[ $# -ne 1 ]]; then
  echo "Uso: $0 <versione>  (es. 1.2.0)"
  exit 1
fi

VERSION="$1"
TAG="v${VERSION}"

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

# ── Aggiorna la versione in pubspec.yaml ──────────────────────────────────────

# Sostituisce la riga "version: x.y.z+build" con la nuova versione.
# Il build number viene derivato dal numero di commit sul branch corrente.
BUILD=$(git rev-list --count HEAD)
sed -i "s/^version: .*/version: ${VERSION}+${BUILD}/" pubspec.yaml

# ── Commit di release ─────────────────────────────────────────────────────────

git add pubspec.yaml
git commit -m "chore: release ${TAG}"

# ── Crea e pusha il tag ───────────────────────────────────────────────────────

echo "Creazione tag ${TAG} su $(git rev-parse --abbrev-ref HEAD)..."
git tag "$TAG"

echo "Push del commit e del tag su origin..."
git push origin HEAD
git push origin "$TAG"

echo ""
echo "Tag ${TAG} pushato. La pipeline GitHub Actions sta buildando l'APK."
echo "Segui il progresso su: https://github.com/$(git remote get-url origin | sed 's/.*github.com[:/]\(.*\)\.git/\1/')/actions"