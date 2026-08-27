# VoicePipeline

## Prima di ogni altra cosa

Questo repo lavora a **catena di sessioni**: il container e' effimero, il lavoro
no. Se sei una sessione appena avviata, la tua prima azione — prima di
rispondere, prima di aprire qualunque file — e':

```bash
./scripts/resume.sh
```

Stampa il passaggio di consegne del predecessore, la catena delle sessioni e il
lavoro gia' svolto. Leggilo tutto: contiene le decisioni gia' prese e i vicoli
ciechi gia' esplorati.

## Mentre lavori

`.claude/state/HANDOVER.md` e' l'unica cosa che sopravvive a questo container.
Aggiornalo a ogni blocco di lavoro chiuso, **non alla fine**: se ti
interrompono a meta', vale solo quello che c'e' scritto li' dentro.

## Prima di esaurirti

Contesto pieno, rate limit vicino, lavoro piu' lungo del container: non tirare
avanti. Consegna finche' hai margine per farlo bene.

```bash
./scripts/handover.sh --reason "motivo"
```

Valida lo stato, lo mette al sicuro su origin e stampa i parametri esatti per
creare il successore con `create_session`. Poi comunica a Raf l'url della nuova
sessione.

Protocollo completo: `.claude/skills/migrazione/SKILL.md` (skill `migrazione`).

## Regole non negoziabili

- Si lavora **solo** sul branch della catena. Non crearne altri, non aprire PR
  se non lo chiede Raf.
- **Una sola sessione attiva** per catena (`scripts/lineage.py validate`).
- Nessuno stato in `/tmp`: sparisce con il container.
- `permission_mode` del successore: **ometterlo sempre**. Non si puo' salire
  sopra i permessi del predecessore, solo scendere, e la degradazione e'
  irreversibile.
- Si parla e si scrive **in italiano**, documenti di consegna compresi.
