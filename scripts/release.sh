#!/usr/bin/env bash
# Crea un tag di release su main e lo pusha su origin.
# La GitHub Actions pipeline si attiva automaticamente al push del tag
# e genera l'APK release allegato alla GitHub Release.
#
# Uso: ./scripts/release.sh <versione>
# Esempio: ./scripts/release.sh 1.2.0

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

# ── Aggiorna develop ──────────────────────────────────────────────────────────

echo "Aggiornamento develop..."
git checkout develop
git pull origin develop

# ── Aggiorna main e mergia develop ────────────────────────────────────────────

echo "Aggiornamento main..."
git checkout main
git pull origin main

echo "Merge develop → main..."
git merge --no-ff develop -m "chore: merge develop into main for ${TAG}"

# ── Aggiorna la versione in pubspec.yaml ──────────────────────────────────────

BUILD=$(git rev-list --count HEAD)
sed -i "s/^version: .*/version: ${VERSION}+${BUILD}/" pubspec.yaml

# ── Commit di release e tag ───────────────────────────────────────────────────

git add pubspec.yaml
git commit -m "chore: release ${TAG}"

echo "Creazione tag ${TAG}..."
git tag "$TAG"

echo "Push main e tag su origin..."
git push origin main
git push origin "$TAG"

# ── Merge main → develop ──────────────────────────────────────────────────────

echo "Merge main → develop..."
git checkout develop
git merge --no-ff main -m "chore: merge main into develop after ${TAG}"
git push origin develop

echo ""
echo "Tag ${TAG} pushato e branch sincronizzati. La pipeline GitHub Actions sta buildando l'APK."
echo "Segui il progresso su: https://github.com/$(git remote get-url origin | sed 's/.*github.com[:/]\(.*\)\.git/\1/')/actions"
