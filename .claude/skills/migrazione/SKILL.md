---
name: migrazione
description: Protocollo di migrazione e ripresa del lavoro tra sessioni. Usa questa skill quando devi riprendere un lavoro iniziato da un'altra sessione, quando ti stai avvicinando a un limite (contesto pieno, rate limit, container che sta per essere reclamato, lavoro piu' lungo di una sessione), quando devi creare una sessione successore, o quando Raf chiede "riprendi da dove eravamo", "passa il testimone", "crea un successore", "chi ci ha lavorato". Copre anche come tenere aggiornato il passaggio di consegne mentre si lavora.
---

# Migrazione e ripresa

Il container e' effimero, il repo no. Tutto quello che il tuo successore deve
sapere sta committato sul branch di lavoro, o non esiste.

## Il principio

Una sessione non e' proprietaria del lavoro: ne e' l'affittuaria. Puo' essere
sfrattata in qualsiasi momento — contesto esaurito, rate limit, container
reclamato, crash. Il lavoro deve sopravvivere allo sfratto, e deve
sopravvivere **senza che Raf rispieghi niente**.

Tre file, sul branch, sono lo stato:

| file | cosa contiene |
|---|---|
| `.claude/state/HANDOVER.md` | il testimone: missione, stato, prossime azioni, decisioni, vicoli ciechi |
| `.claude/state/lineage.json` | la catena: chi ha lavorato, quando, chi ha passato a chi |
| `.claude/state/BOOT_PROMPT.md` | il prompt di avvio dell'ultimo successore generato |

## A. Sei una sessione nuova (ripresa)

**Prima azione, prima di rispondere a Raf e prima di toccare qualunque file:**

```bash
./scripts/resume.sh
```

Stampa consegne, catena e lavoro svolto. Leggilo tutto: e' l'unico modo di
sapere cosa e' gia' stato provato e non funziona.

Poi registrati nella catena — serve a Raf per sapere chi sta lavorando, e
serve a `validate` per accorgersi delle biforcazioni:

```bash
python3 scripts/lineage.py adopt --session <TUO_SESSION_ID> \
  --model claude-opus-5 --permission-mode auto --title "<titolo>"
./scripts/push_state.sh "chain: presa in carico <TUO_SESSION_ID>"
```

Usa sempre `push_state.sh` e non `git push` diretto per lo stato di catena:
predecessore e successore convivono per qualche minuto e pushano sullo stesso
branch, quindi il push va riallineato prima di essere ritentato. Se la tua
voce risulta gia' "dichiarata" dal predecessore, `adopt` la promuove ad attiva
invece di duplicarla.

Il tuo session id lo ottieni dal tool `get_session` (campo `ccr.id`).

Se "Questioni aperte per Raf" non e' vuota, chiediglielo **subito**: e' l'unica
cosa per cui vale la pena interrompere prima di iniziare.

## B. Stai lavorando (manutenzione del testimone)

Aggiorna `HANDOVER.md` **mentre lavori, a ogni blocco chiuso**, non alla fine.
Il motivo e' brutale: se ti interrompono a meta', vale solo quello che c'e'
scritto li' dentro. Un documento aggiornato "quando ho finito" e' un documento
che non verra' mai aggiornato.

Le due sezioni che fanno risparmiare piu' tempo al successore:

- **Vicoli ciechi** — cosa hai provato e non funziona, con il perche'. Senza,
  il successore ripete i tuoi errori con entusiasmo.
- **Decisioni prese** — cosa e' chiuso e non va ridiscusso. Senza, il
  successore rimette in discussione scelte gia' pagate.

## C. Ti stai avvicinando al limite (consegna)

### Quando migrare

Migra **prima** di essere costretto. Una consegna preparata con calma vale
dieci volte una consegna scritta con il contesto agli sgoccioli.

| segnale | come lo vedi |
|---|---|
| contesto oltre ~70% | il sistema te lo segnala; anche "sto riassumendo spesso" e' un sintomo |
| rate limit vicino | `get_session` → `external_metadata.rate_limit_info` (`status`, `resetsAt`, `isUsingOverage`) |
| lavoro piu' lungo del container | stima onesta: se non finisci in questa sessione, consegna adesso |
| Raf te lo chiede | esplicito |

**Non tirare avanti fino all'ultimo token.** Una sessione che muore senza
consegna e' lavoro perso, non lavoro rimandato.

### Come consegnare

1. Aggiorna `HANDOVER.md` per bene. Sii spietato sullo stato reale: un
   successore che eredita un ottimismo sbagliato perde ore.
2. Esegui:
   ```bash
   ./scripts/handover.sh --reason "motivo della consegna" --session <TUO_ID>
   ```
   Valida il documento (rifiuta template vuoti e sezioni incomplete), committa,
   pusha con retry, e stampa i parametri esatti di `create_session`.
   **Se il push fallisce lo script si ferma: non creare il successore**,
   nascerebbe senza stato.
3. Crea il successore con `create_session` (MCP `claude-code-remote`), usando
   i parametri stampati. Vedi sotto.
4. Registra il successore e pusha:
   ```bash
   python3 scripts/lineage.py handoff --session <TUO_ID> \
     --successor <NUOVO_ID> --reason "..."
   ./scripts/push_state.sh "chain: consegna a <NUOVO_ID>"
   ```
5. **Comunica a Raf l'url del successore**: `https://claude.ai/code/<NUOVO_ID>`.
   Una sessione che non sa raggiungere non gli serve a niente.

## D. Creare il successore: i parametri che contano

```
create_session(
  title           = "[#N] <missione>"            # N = posizione nella catena
  prompt          = <contenuto di .claude/state/BOOT_PROMPT.md, integrale>
  source_url      = https://github.com/<owner>/<repo>
  source_revision = <branch di lavoro>           # cosi' nasce con lo stato gia' in checkout
  outcome_branch  = <branch di lavoro>           # senza, pusha su un branch derivato e la catena si biforca
  tags            = ["catena", "<repo>"]         # per ritrovarla con list_sessions
  # environment_id, permission_mode, model: OMETTERE per ereditare
)
```

Le quattro trappole, in ordine di quanto fanno male:

1. **`outcome_branch` mancante** → il successore pusha su un branch derivato
   dal suo session id, e la catena si spezza in silenzio. E' l'errore peggiore
   perche' sembra funzionare.
2. **`source_revision` mancante** → nasce sul branch di default, senza lo
   stato, e riparte da zero.
3. **`permission_mode` riscritto** → non si puo' salire sopra i permessi del
   predecessore, solo scendere. Se lo scrivi a mano rischi di degradare la
   catena in modo irreversibile: ogni successore eredita il tetto piu' basso.
   Ometterlo e' sempre giusto.
4. **Prompt riassunto invece che integrale** → il successore parte con la tua
   sintesi al posto dello stato. Passa il file cosi' com'e'.

## E. Regole permanenti della catena

- **Una sola sessione attiva per catena.** Due successori sullo stesso branch
  si sovrascrivono. `python3 scripts/lineage.py validate` lo intercetta.
- **Un branch, una catena.** Non cambiare branch a meta' catena.
- **Il successore non puo' rispondere.** Riceve messaggi (`SendMessage`) ma non
  ne manda indietro. La comunicazione di ritorno passa dal repo o da Raf: non
  progettare niente che aspetti una risposta.
- **Mai stato in `/tmp`.** Sparisce con il container.
- **La catena e' append-only.** Le sessioni passate si chiudono, non si
  riscrivono: e' la memoria di chi ha fatto cosa.

## F. Piu' catene in parallelo

Un branch diverso = una catena diversa, con il suo `HANDOVER.md` e il suo
`lineage.json`. E' voluto: due lavori indipendenti non devono condividere il
testimone, altrimenti ogni consegna e' un merge conflict.

Se serve dividere il lavoro *dentro* la stessa sessione, usa i subagent
(`Agent`): vivono e muoiono dentro il tuo contesto e non entrano nella catena.
La catena registra solo le sessioni, che sono le cose che sopravvivono.

## G. Diagnostica

```bash
./scripts/push_state.sh "msg"         # commit + push dello stato, a prova di corsa
python3 scripts/lineage.py show       # chi ha lavorato, quando, chi ha passato a chi
python3 scripts/lineage.py validate   # biforcazioni, predecessori orfani, duplicati
python3 scripts/lineage.py current    # sessione attiva, in json
./scripts/resume.sh                   # stato completo (sola lettura, sempre sicuro)
./scripts/handover.sh --reason x --dry-run   # valida senza committare
```

Se `validate` segnala una biforcazione: decidi quale sessione prosegue, chiudi
l'altra a mano in `lineage.json` (`status: "abandoned"`), committa. Non
lasciare due sessioni attive: si sovrascrivono a vicenda e la prossima
consegna eredita uno stato incoerente.
