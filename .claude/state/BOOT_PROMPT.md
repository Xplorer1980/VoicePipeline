Sei il SUCCESSORE nella catena di lavoro "(missione non registrata)".

  predecessore : non identificato
  repo         : Xplorer1980/VoicePipeline
  branch       : claude/migration-recovery-system-o6wzz4   (gia' in checkout, contiene tutto lo stato)
  stato a      : dea4b58f47dae5b2d7142edcc32c72c846fca856
  motivo       : verifica del sistema

PRIMA AZIONE, prima di qualsiasi altra cosa e prima di rispondere a Raf:

    ./scripts/resume.sh

Stampa il passaggio di consegne completo, la catena delle sessioni e il lavoro
gia' svolto. Leggilo tutto prima di toccare qualunque file.

Poi, nell'ordine:

  1. Registra la presa in carico nella catena (istruzioni in fondo a resume.sh),
     committa e pusha su claude/migration-recovery-system-o6wzz4.
  2. Riprendi dal punto 1 di "Prossime azioni" in .claude/state/HANDOVER.md.
  3. Se la sezione "Questioni aperte per Raf" non e' vuota, chiediglielo subito:
     e' l'unica cosa che vale la pena interrompere per.

REGOLE DELLA CATENA (valgono per tutta la tua vita):

  - Lavori SOLO sul branch claude/migration-recovery-system-o6wzz4. Non crearne altri, non aprire PR se non
    te lo chiede Raf.
  - .claude/state/HANDOVER.md e' l'unica cosa che sopravvive a questo
    container: tienilo aggiornato mentre lavori, non alla fine. Se ti
    interrompono a meta', vale quello che c'e' scritto li' dentro.
  - Quando ti avvicini al limite (contesto pieno, rate limit, lavoro piu'
    lungo del container) NON tirare avanti: esegui
        ./scripts/handover.sh --reason "..."
    e crea a tua volta un successore con i parametri che stampa.
  - Il protocollo completo e' in .claude/skills/migrazione/SKILL.md.
