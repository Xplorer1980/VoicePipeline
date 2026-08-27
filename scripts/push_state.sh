#!/usr/bin/env bash
# push_state.sh - Committa e pusha lo stato di catena resistendo alle corse.
#
# Predecessore e successore vivono per qualche minuto insieme e pushano sullo
# stesso branch: senza riallineamento uno dei due si vede rifiutare il push.
# Questo script riallinea e riprova, invece di fallire.
#
# Uso:  ./scripts/push_state.sh "messaggio di commit"
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

MSG="${1:?uso: push_state.sh \"messaggio di commit\"}"
BRANCH="$(git rev-parse --abbrev-ref HEAD)"

if [ -n "$(git status --porcelain)" ]; then
  git add -A
  git commit -q -m "$MSG" -m "Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
  printf 'commit: %s\n' "$(git rev-parse --short HEAD)"
else
  printf 'niente da committare\n'
fi

for delay in 0 2 4 8 16; do
  [ "$delay" = "0" ] || { printf 'push rifiutato, riallineo e riprovo fra %ss...\n' "$delay"; sleep "$delay"; }

  git fetch origin "$BRANCH" --quiet 2>/dev/null || true
  if git rev-parse --verify "origin/$BRANCH" >/dev/null 2>&1; then
    if ! git rebase "origin/$BRANCH" --quiet 2>/dev/null; then
      # conflitto: quasi sempre su lineage.json, dove le voci sono append-only
      if git rebase --abort 2>/dev/null; then
        printf '!! conflitto durante il riallineamento su origin/%s.\n' "$BRANCH"
        printf '   Risolvilo a mano, poi verifica con: python3 scripts/lineage.py validate\n'
        exit 1
      fi
    fi
  fi

  if git push -u origin "$BRANCH" --quiet 2>/dev/null; then
    printf 'push OK -> origin/%s (%s)\n' "$BRANCH" "$(git rev-parse --short HEAD)"
    exit 0
  fi
done

printf 'ERRORE: push su origin/%s fallito dopo 5 tentativi.\n' "$BRANCH" >&2
exit 1
