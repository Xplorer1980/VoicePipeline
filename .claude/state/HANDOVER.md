# Passaggio di consegne

**Aggiornato:** 2026-08-27T06:56:32Z
**Sessione:** session_014mwzUqCmwUr7mQLNZ4NsB3
**Branch:** claude/migration-recovery-system-o6wzz4

## 1. Missione

Fare in modo che nessuna sessione di lavoro su VoicePipeline muoia portandosi
via il contesto. Un container viene reclamato, un contesto si esaurisce, un
rate limit scatta: il lavoro deve poter proseguire in una sessione nuova senza
che Raf debba rispiegare da capo cosa si stava facendo e perche'.

Questo repo ospita il meccanismo. Il lavoro di dominio (VoicePipeline vero e
proprio) arriva sopra, e usa lo stesso meccanismo per sopravvivere.

## 2. Stato attuale

FATTO E VERIFICATO in questa sessione:

- `scripts/lineage.py` — registro della catena delle sessioni (init/adopt/
  handoff/show/current/validate). Verificato: init + show + validate girano,
  la validazione intercetta catene biforcate e predecessori inesistenti.
- `scripts/resume.sh` — ricostruzione del contesto in una sessione nuova.
  Sola lettura, idempotente. Verificato: gira su repo pulito e su repo sporco.
- `scripts/handover.sh` — validazione + messa in sicurezza + generazione del
  prompt di avvio del successore. Verificato con tre test negativi: rifiuta il
  template non compilato, rifiuta le sezioni vuote, rifiuta le azioni
  numerate senza testo. Il push ha retry esponenziale (2/4/8/16s) e in caso di
  fallimento BLOCCA la creazione del successore.
- `scripts/push_state.sh` — commit + push dello stato resistente alle corse
  (fetch, rebase, retry 2/4/8/16s). Verificato sul campo: al primo utilizzo
  reale ha riallineato un push concorrente del successore senza perdere nulla.
- `scripts/lineage.py repair` — fonde voci duplicate e chiude biforcazioni.
  Verificato: ha riparato un duplicato reale generato dalla convivenza
  predecessore/successore.
- `.claude/skills/migrazione/SKILL.md` — protocollo operativo completo.
- `CLAUDE.md` — memoria di repo: ogni sessione futura vede il protocollo
  senza doverlo cercare.

VERIFICATO DALLA SESSIONE #2 (sul campo, non a tavolino):

- `push_state.sh` e `lineage.py repair` funzionano davvero: all'avvio di
  questa sessione la catena era duplicata (declared + active) per un push
  incrociato, e `repair` l'ha riparata. La rimozione della doppia scrittura in
  `handoff` toglie la causa. Confermato: `validate` torna integro e la voce
  fusa conserva `environment_id` dal predecessore e `head_at_open` dal
  successore.
- Nota per chi verra': la sessione #2 aveva scritto un `dedupe` proprio, in
  parallelo e senza saperlo, mentre la #1 scriveva `repair`. E' stato scartato
  a favore di `repair`, piu' completo (copre anche la biforcazione). Lezione
  gia' pagata: **prima di scrivere, guarda cosa e' arrivato su origin.**

IN CORSO / NON ANCORA FATTO:

- Il "caso tipo" di cui Raf ha parlato ("questa parte e' generica, poi
  parleremo di un caso tipo") NON e' ancora stato definito. E' la prossima
  cosa che serve da lui.

## 3. Prossime azioni

1. Chiedere a Raf qual e' il caso tipo che voleva affrontare, e riportarlo in
   questo documento sotto "Missione" prima di iniziare a lavorarci.
2. Verificare con lui se il lavoro di dominio va su questo stesso branch o su
   un branch nuovo (in tal caso serve una catena separata: vedi SKILL.md,
   sezione "Piu' catene in parallelo").
3. Aggiornare questo documento a ogni blocco di lavoro chiuso, non alla fine.

## 4. Decisioni prese (non rimetterle in discussione)

- **Il testimone e' git, non la chat.** Il container e' effimero, il repo no.
  Tutto cio' che il successore deve sapere sta committato sul branch di
  lavoro. Nessuno stato vive solo nella conversazione.
- **Il successore non puo' avere piu' permessi del predecessore.** E' un
  vincolo della piattaforma (`create_session` rifiuta l'escalation), non una
  scelta: percio' la regola operativa e' *omettere* `permission_mode` per
  ereditarlo, mai riscriverlo, altrimenti la catena degrada e non risale piu'.
- **Una sola sessione attiva per catena.** `lineage.py validate` segnala la
  biforcazione come errore: due successori sullo stesso branch si sovrascrivono
  a vicenda.
- **La creazione del successore resta un atto dell'agente, non dello script.**
  `create_session` e' un tool MCP: uno script di shell non puo' chiamarlo.
  `handover.sh` prepara tutto e stampa i parametri esatti; la chiamata la fa
  l'agente. Non tentare di automatizzarla via curl.
- **Una voce della catena ha un solo autore.** Il successore crea la propria
  voce con `adopt`; il predecessore registra solo il puntatore. Imparato sul
  campo: quando entrambi scrivevano la stessa voce, il rebase applicava
  entrambe le versioni senza conflitto testuale e la catena si ritrovava con
  un duplicato silenzioso. Non reintrodurre la doppia scrittura.
- **Lo stato di catena si pusha con `push_state.sh`, mai con `git push`
  diretto.** Predecessore e successore convivono per qualche minuto sullo
  stesso branch e le corse sono la norma, non l'eccezione.
- **Documento di consegna in italiano.** Raf lavora in italiano; il documento
  lo legge anche lui, non solo il successore.

## 5. Vicoli ciechi

- **Il successore non puo' rispondere al predecessore.** Una sessione cloud
  riceve messaggi (`SendMessage`) ma non puo' rimandarne indietro. Non
  progettare niente che aspetti una risposta dal successore: la comunicazione
  di ritorno passa dal repo (commit sul branch) o da Raf.
- **`ListAgents` non vede le sessioni cloud finche' non sono avviate.** Subito
  dopo `create_session` la sessione puo' non comparire: non e' un errore, non
  ricrearla.
- **Non usare `/tmp` per lo stato.** Sparisce con il container. Vale anche per
  gli appunti "solo un attimo".
- **`git push` senza `-u origin <branch>` puo' finire sul branch sbagliato.**
  Tutti gli script qui usano la forma esplicita: non "semplificarla".

## 6. Contesto operativo

- Repo: `Xplorer1980/VoicePipeline` — branch di lavoro
  `claude/migration-recovery-system-o6wzz4`.
- Ambiente: `env_01XdV8tRyukwWqwUPFNWLNSf` ("Default — trusted network
  access", cloud Anthropic). Modello `claude-opus-5`, permessi `auto`.
- Comandi:
  - `./scripts/resume.sh` — ripresa (prima cosa da fare in una sessione nuova)
  - `./scripts/handover.sh --reason "..."` — consegna
  - `python3 scripts/lineage.py show|validate|repair` — stato della catena
  - `./scripts/push_state.sh "msg"` — commit + push a prova di corsa
- Nessuna dipendenza esterna: bash, git, python3 (stdlib). Niente da
  installare.
- Credenziali: nessuna in gioco. Il push usa quelle gia' iniettate
  nell'ambiente; non ci sono segreti nel repo e non devono entrarci.

## 7. Questioni aperte per Raf

**Poste dalla sessione #2 il 2026-08-27, in attesa di risposta.**

1. Qual e' il "caso tipo" da affrontare? (Detto a fine primo messaggio, mai
   specificato.) Il repo oggi contiene *solo* il meccanismo di migrazione:
   nessun codice di dominio VoicePipeline. Senza questa risposta non c'e'
   lavoro di dominio da iniziare, e non ha senso inventarlo.
2. Il lavoro di dominio va su questo branch o ne vuole uno separato?
3. **La sessione #1 e' ancora attiva** dopo aver consegnato: alle 07:01 stava
   ancora scrivendo sul branch. Il registro la da' per `handed_over` ed e'
   corretto, ma finche' lavora davvero le sessioni attive sono due e i push si
   incrociano (e' gia' successo due volte in dieci minuti). Raf deve decidere
   chi prosegue: la #2 la considera chiusa e non tocchera' quel che lei
   pusha.
