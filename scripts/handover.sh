#!/usr/bin/env bash
# handover.sh - Prepara il passaggio di consegne al successore.
#
# Fa tre cose, in quest'ordine, e si ferma al primo errore:
#   1. VALIDA   il documento di consegna (niente template vuoti, niente sezioni mancanti)
#   2. METTE AL SICURO lo stato: commit + push sul branch di lavoro
#   3. GENERA   il prompt di avvio del successore e i parametri esatti di create_session
#
# NON crea il successore: la creazione passa dal tool MCP create_session, che
# solo l'agente puo' chiamare. Questo script prepara tutto perche' quella
# chiamata sia una formalita' e non un atto di improvvisazione.
#
# Uso:  ./scripts/handover.sh --reason "contesto esaurito" [--session session_xxx] [--dry-run]
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

STATE=".claude/state"
HANDOVER="$STATE/HANDOVER.md"
BOOT="$STATE/BOOT_PROMPT.md"
BRANCH="$(git rev-parse --abbrev-ref HEAD)"
REPO_URL="$(git config --get remote.origin.url)"
REPO_SLUG="$(printf '%s' "$REPO_URL" | sed -E 's#(https://github\.com/|git@github\.com:)##; s#\.git$##')"

REASON=""; SESSION=""; DRY=0
while [ $# -gt 0 ]; do
  case "$1" in
    --reason)  REASON="${2:-}"; shift 2 ;;
    --session) SESSION="${2:-}"; shift 2 ;;
    --dry-run) DRY=1; shift ;;
    -h|--help) sed -n '2,16p' "$0"; exit 0 ;;
    *) echo "ERRORE: argomento sconosciuto: $1" >&2; exit 2 ;;
  esac
done

fail() { printf '\nERRORE: %s\n' "$1" >&2; exit 1; }
step() { printf '\n[%s] %s\n' "$1" "$2"; }

[ -n "$REASON" ] || fail "--reason e' obbligatorio. Il successore deve sapere PERCHE' e' nato."

# ═══════════════════════════════════════════════════════ 1. validazione
step "1/3" "Validazione del documento di consegna"

[ -f "$HANDOVER" ] || fail "$HANDOVER non esiste. Copialo da $STATE/TEMPLATE_HANDOVER.md e compilalo."

if grep -q 'TEMPLATE-NON-COMPILATO' "$HANDOVER"; then
  fail "$HANDOVER e' ancora il template non compilato.
       Un successore che eredita un template vuoto riparte da zero: e' il
       fallimento esatto che questo sistema esiste per impedire."
fi

MISSING=""
for sec in "1. Missione" "2. Stato attuale" "3. Prossime azioni" \
           "4. Decisioni prese" "5. Vicoli ciechi" "6. Contesto operativo"; do
  if ! grep -qF "## $sec" "$HANDOVER"; then
    MISSING="$MISSING\n         - $sec"
  else
    # la sezione esiste: controlla che abbia corpo (righe non vuote, non commenti)
    BODY="$(awk -v s="## $sec" '
      index($0, s) == 1 {inside=1; next}
      /^## / {inside=0}
      inside && !/^[[:space:]]*$/ && !/^[[:space:]]*>/ && !/^<!--/ {n++}
      END {print n+0}' "$HANDOVER")"
    [ "$BODY" -gt 0 ] || MISSING="$MISSING\n         - $sec (presente ma vuota)"
  fi
done
[ -z "$MISSING" ] || fail "sezioni obbligatorie incomplete in $HANDOVER:$(printf "$MISSING")"

ACTIONS="$(awk '/^## 3\. Prossime azioni/{i=1;next} /^## /{i=0} i && /^[[:space:]]*[0-9]+\.[[:space:]]*[^[:space:]]/{n++} END{print n+0}' "$HANDOVER")"
[ "$ACTIONS" -gt 0 ] || fail "\"Prossime azioni\" non contiene nessuna azione numerata.
       Il successore deve poter iniziare senza fare domande."
printf '      documento completo: %s azioni in coda\n' "$ACTIONS"

# timbro: aggiorna i metadati in testa al documento
TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
[ -n "$SESSION" ] || SESSION="$(python3 scripts/lineage.py current 2>/dev/null | python3 -c 'import json,sys; print(json.load(sys.stdin)["session_id"])' 2>/dev/null || echo "")"
python3 - "$HANDOVER" "$TS" "$SESSION" "$BRANCH" <<'PY'
import re, sys
path, ts, sess, branch = sys.argv[1:5]
s = open(path, encoding="utf-8").read()
def stamp(text, label, value):
    if not value: return text
    pat = re.compile(rf"^\*\*{label}:\*\*.*$", re.M)
    line = f"**{label}:** {value}"
    return pat.sub(line, text) if pat.search(text) else text
s = stamp(s, "Aggiornato", ts)
s = stamp(s, "Sessione", sess)
s = stamp(s, "Branch", branch)
open(path, "w", encoding="utf-8").write(s)
PY
printf '      timbrato: %s | sessione %s | branch %s\n' "$TS" "${SESSION:-?}" "$BRANCH"

# ═══════════════════════════════════════════════════════ 2. messa in sicurezza
step "2/3" "Messa in sicurezza dello stato su origin/$BRANCH"

if [ -n "$SESSION" ] && [ -f "$STATE/lineage.json" ]; then
  python3 scripts/lineage.py handoff --session "$SESSION" --reason "$REASON" >/dev/null 2>&1 \
    && printf '      consegna registrata nella catena\n' \
    || printf '      (catena non aggiornata: sessione non registrata, prosegui comunque)\n'
fi

if [ "$DRY" = "1" ]; then
  printf '      --dry-run: nessun commit, nessun push\n'
else
  if [ -n "$(git status --porcelain)" ]; then
    git add -A
    git commit -q -m "handover: $REASON" \
      -m "Consegna da ${SESSION:-sessione non identificata} su $BRANCH." \
      -m "Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
    printf '      commit: %s\n' "$(git rev-parse --short HEAD)"
  else
    printf '      niente da committare (stato gia%s allineato)\n' "'"
  fi

  PUSHED=0
  for delay in 0 2 4 8 16; do
    [ "$delay" = "0" ] || { printf '      push fallito, riprovo fra %ss...\n' "$delay"; sleep "$delay"; }
    if git push -u origin "$BRANCH" --quiet 2>/dev/null; then PUSHED=1; break; fi
  done
  [ "$PUSHED" = "1" ] || fail "push su origin/$BRANCH fallito dopo 5 tentativi.
       NON creare il successore: nascerebbe senza lo stato e ripartirebbe da zero."
  printf '      push OK -> origin/%s\n' "$BRANCH"
fi

HEAD_SHA="$(git rev-parse HEAD)"

# ═══════════════════════════════════════════════════════ 3. prompt di avvio
step "3/3" "Generazione del prompt di avvio del successore"

MISSION="$(python3 -c "import json;print(json.load(open('$STATE/lineage.json',encoding='utf-8'))['mission'])" 2>/dev/null || echo "(missione non registrata)")"
SEQ="$(python3 -c "import json;print(len(json.load(open('$STATE/lineage.json',encoding='utf-8'))['chain'])+1)" 2>/dev/null || echo "?")"

cat > "$BOOT" <<BOOTEOF
Sei il SUCCESSORE nella catena di lavoro "$MISSION".

  predecessore : ${SESSION:-non identificato}
  repo         : $REPO_SLUG
  branch       : $BRANCH   (gia' in checkout, contiene tutto lo stato)
  stato a      : $HEAD_SHA
  motivo       : $REASON

PRIMA AZIONE, prima di qualsiasi altra cosa e prima di rispondere a Raf:

    ./scripts/resume.sh

Stampa il passaggio di consegne completo, la catena delle sessioni e il lavoro
gia' svolto. Leggilo tutto prima di toccare qualunque file.

Poi, nell'ordine:

  1. Registra la presa in carico nella catena (istruzioni in fondo a resume.sh),
     committa e pusha su $BRANCH.
  2. Riprendi dal punto 1 di "Prossime azioni" in .claude/state/HANDOVER.md.
  3. Se la sezione "Questioni aperte per Raf" non e' vuota, chiediglielo subito:
     e' l'unica cosa che vale la pena interrompere per.

REGOLE DELLA CATENA (valgono per tutta la tua vita):

  - Lavori SOLO sul branch $BRANCH. Non crearne altri, non aprire PR se non
    te lo chiede Raf.
  - .claude/state/HANDOVER.md e' l'unica cosa che sopravvive a questo
    container: tienilo aggiornato mentre lavori, non alla fine. Se ti
    interrompono a meta', vale quello che c'e' scritto li' dentro.
  - Quando ti avvicini al limite (contesto pieno, rate limit, lavoro piu'
    lungo del container) NON tirare avanti: esegui
        ./scripts/handover.sh --reason "..."
    e crea a tua volta un successore con i parametri che stampa.
  - Il protocollo completo e' in .claude/skills/migrazione/SKILL.md.
BOOTEOF

printf '      scritto: %s\n' "$BOOT"

# ---- parametri esatti per create_session --------------------------------
cat <<PARAMEOF

────────────────────────────────────────────────────────────────────────
  PARAMETRI PER create_session  (tool MCP claude-code-remote)
────────────────────────────────────────────────────────────────────────

  title           : "[#$SEQ] $MISSION"
  prompt          : <contenuto integrale di $BOOT>
  source_url      : $REPO_URL
  source_revision : $BRANCH
  outcome_branch  : $BRANCH
  environment_id  : <omettere per ereditare quello del predecessore>
  permission_mode : <omettere per ereditare: non si puo' salire, solo scendere>
  model           : <omettere per ereditare>
  tags            : ["catena", "$(printf '%s' "$REPO_SLUG" | tr 'A-Z/' 'a-z-')"]

  Dopo la creazione, OBBLIGATORIO:
    1. comunicare a Raf l'url  https://claude.ai/code/<nuovo_session_id>
    2. python3 scripts/lineage.py handoff --session ${SESSION:-<TUO_ID>} \\
         --successor <nuovo_session_id> --reason "$REASON"
    3. commit + push: il successore deve trovarsi gia' registrato nella catena.
────────────────────────────────────────────────────────────────────────

PARAMEOF
