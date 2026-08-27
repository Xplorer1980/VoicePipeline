#!/usr/bin/env bash
# resume.sh - Ricostruisce il contesto di lavoro in una sessione nuova.
#
# E' la PRIMA cosa che una sessione erede deve eseguire, prima di leggere
# qualunque altro file e prima di toccare qualunque cosa. Non modifica nulla:
# e' sola lettura, idempotente, eseguibile quante volte serve.
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

STATE=".claude/state"
HANDOVER="$STATE/HANDOVER.md"
BRANCH="$(git rev-parse --abbrev-ref HEAD)"

rule() { printf '\n%s\n' "────────────────────────────────────────────────────────────────────────"; }
head_() { rule; printf '  %s\n' "$1"; rule; }

head_ "RIPRESA LAVORO — branch: $BRANCH"

# ---------------------------------------------------------------- 1. sincronia
printf '\n[1/5] Sincronia con origin\n\n'
REMOTE_REF="$(git ls-remote --heads origin "$BRANCH" 2>/dev/null || echo "__NETFAIL__")"
if [ "$REMOTE_REF" = "__NETFAIL__" ]; then
  printf '      !! origin irraggiungibile. NON creare successori finche%s non torna:\n' "'"
  printf '         nascerebbero senza lo stato. Verifica la rete e riprova.\n'
elif [ -z "$REMOTE_REF" ]; then
  printf '      il branch %s non esiste ancora su origin.\n' "$BRANCH"
  printf '      Normale per la prima sessione della catena: lo creera%s il primo push.\n' "'"
else
  git fetch origin "$BRANCH" --quiet 2>/dev/null || true
  LOCAL="$(git rev-parse HEAD)"
  REMOTE="$(git rev-parse "origin/$BRANCH" 2>/dev/null || echo "$LOCAL")"
  if [ "$LOCAL" = "$REMOTE" ]; then
    printf '      allineato con origin/%s (%s)\n' "$BRANCH" "${LOCAL:0:8}"
  else
    BEHIND="$(git rev-list --count "HEAD..origin/$BRANCH" 2>/dev/null || echo '?')"
    AHEAD="$(git rev-list --count "origin/$BRANCH..HEAD" 2>/dev/null || echo '?')"
    printf '      !! DIVERGENZA con origin/%s — %s commit indietro, %s avanti\n' "$BRANCH" "$BEHIND" "$AHEAD"
    printf '         locale : %s\n         remoto : %s\n' "${LOCAL:0:8}" "${REMOTE:0:8}"
    printf '         Risolvi PRIMA di lavorare: git pull origin %s\n' "$BRANCH"
  fi
fi

DIRTY="$(git status --porcelain | wc -l | tr -d ' ')"
if [ "$DIRTY" != "0" ]; then
  printf '\n      !! %s file non committati — il predecessore potrebbe essere\n' "$DIRTY"
  printf '         stato interrotto a meta%s. Ispeziona prima di sovrascrivere:\n' "'"
  git status --short | sed 's/^/         /'
fi

# ---------------------------------------------------------------- 2. catena
printf '\n[2/5] Catena delle sessioni\n'
if [ -f "$STATE/lineage.json" ]; then
  python3 scripts/lineage.py show 2>/dev/null || printf '      (lineage illeggibile)\n'
  python3 scripts/lineage.py validate 2>/dev/null || true
else
  printf '\n      Nessuna catena registrata: sei la radice.\n'
  printf '      Inizializzala con:\n'
  printf '        python3 scripts/lineage.py init --mission "..." --session <TUO_ID>\n'
fi

# ---------------------------------------------------------------- 3. consegne
head_ "[3/5] PASSAGGIO DI CONSEGNE — leggilo per intero"
if [ -f "$HANDOVER" ]; then
  if grep -q 'TEMPLATE-NON-COMPILATO' "$HANDOVER"; then
    printf '\n      !! HANDOVER.md e%s ancora il template vuoto.\n' "'"
    printf '         Nessuno stato da ereditare: parti dalle istruzioni di Raf.\n\n'
  fi
  cat "$HANDOVER"
else
  printf '\n      Nessun %s: prima sessione della catena.\n' "$HANDOVER"
  printf '      Crealo copiando %s/TEMPLATE_HANDOVER.md\n\n' "$STATE"
fi

# ---------------------------------------------------------------- 4. storia
printf '\n[4/5] Lavoro svolto sul branch (ultimi 15 commit)\n\n'
git log --oneline --decorate -15 | sed 's/^/      /'

LAST_HANDOFF="$(python3 - <<'PY' 2>/dev/null || true
import json, pathlib
p = pathlib.Path(".claude/state/lineage.json")
if p.exists():
    chain = json.load(p.open(encoding="utf-8"))["chain"]
    done = [l for l in chain if l.get("head_at_handover")]
    if done:
        print(done[-1]["head_at_handover"])
PY
)"
if [ -n "${LAST_HANDOFF:-}" ] && git cat-file -e "$LAST_HANDOFF" 2>/dev/null; then
  N="$(git rev-list --count "$LAST_HANDOFF"..HEAD 2>/dev/null || echo 0)"
  printf '\n      %s commit dopo l%sultima consegna (%s)\n' "$N" "'" "${LAST_HANDOFF:0:8}"
fi

# ---------------------------------------------------------------- 5. istruzioni
head_ "[5/5] COSA DEVI FARE ORA"
cat <<INSTR

  1. Ricava il tuo session id:  tool get_session (campo ccr.id)
  2. Registra la presa in carico:
       python3 scripts/lineage.py adopt --session <TUO_ID> \\
         --model <modello> --permission-mode <modo> --title "<titolo>"
       git add -A && git commit -m "chain: presa in carico <TUO_ID>"
       git push -u origin $BRANCH
  3. Riprendi dal punto 1 di "Prossime azioni" qui sopra.
  4. Mantieni HANDOVER.md aggiornato mentre lavori: e' l'unica cosa che
     sopravvive a questo container.
  5. Prima di esaurirti (contesto pieno, rate limit, lavoro lungo):
       ./scripts/handover.sh --reason "..."
     e crea il successore con le istruzioni che stampa.

  Branch di lavoro, non crearne altri: $BRANCH

INSTR
