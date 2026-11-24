# To-do e incombenze aperte

## File dal PC (ricostruiti dalle chat del 24/11, link pubblici)

- **Sospesi e todolist** (`B:\DB_260922\LAVORO\SOSPESI_RIPRISTINO_20261124.md`, completo): https://github.com/Xplorer1980/VoicePipeline/blob/claude/beautiful-ptolemy-hgm1bg/pc/IN_SOSPESO.md
- **Log** (`LOG_MODIFICHE_SENZA_CONSENSO_20261124.md`, parziale: mancano una decina di righe scritte da Codex; le 4 proposte sono alle righe 47-49 e 94): https://github.com/Xplorer1980/VoicePipeline/blob/claude/beautiful-ptolemy-hgm1bg/pc/LOG.md
- **Resoconto** (`RESOCONTO_PER_RAF_20261124.md`, quasi completo): https://github.com/Xplorer1980/VoicePipeline/blob/claude/beautiful-ptolemy-hgm1bg/pc/RESOCONTO.md

La lista di oltre 200 cose in sospeso non compare in nessuna chat: va presa dal PC.

Aggiornato: martedì 24/11/2026, ~12:45 (ora del PC)

Ricostruito leggendo le ultime sessioni dal PC (Gancio 82ff1c66 "testimone n.165"
e Gancio 6687da7b "n.164") e il branch `claude/migration-recovery-system-o6wzz4`
di questa repo. **Non ho accesso al disco B: del PC**: i file citati (log,
lavagna, ID_FISSI.tsv) li conosco solo da quello che le sessioni hanno scritto,
non dal loro contenuto.

---

## A. Aspettano te (decisioni tue)

Fonte: la sessione n.165, ultimo messaggio delle 12:36: *"TUTTO ASPETTA RAF"*.

- [ ] **Riallineare `ID_FISSI.tsv`**: contiene ancora i due ID vecchi. Va
      riallineato **con la tua procedura** prima del prossimo passaggio di
      sessione (lavagna C129).
- [ ] **`no_annidate`, misurare la memoria vera di una sessione**: Codex vuole
      sapere quanto contesto ha davvero una sessione (C126/C130: "capacità del
      contesto, non 700.000 fisso"). Nessuno l'ha ancora misurato. La sessione
      dice: **NON PROVATO**, né nel DB né sul web.
- [ ] **`raf_giu`, doppie risposte**: il problema delle risposte doppie è ancora
      aperto.
- [ ] **Le 4 proposte del log**: sono in
      `LOG_MODIFICHE_SENZA_CONSENSO_20261124.md` (nel Vault). Il testo delle
      proposte non è nelle trascrizioni: va letto lì, dal PC.
- [ ] **`passa_mano.py --controlla`**: il blocco `esegui_verifica` l'ha fermato
      perché serve **un tuo ordine scritto alla lettera** per lanciarlo.
- [ ] **`mie_risposte_n165_nuova.md`**: la scrittura nel DB è stata bloccata, il
      file non esiste. Le risposte stanno solo nello scratchpad della sessione
      (`mie_risposte_n165.md`): decidi se salvarle nel DB.
- [ ] **Lettura dei file lunghi**: è ancora "proposta"
      (`01767a3e.md:459`, RISPOSTA162), non decisa.
- [ ] **Numerazione dei testimoni**: la 163 è stata saltata. La sessione 162
      ha avvisato la 164 che non rinumera senza un tuo via libera. Da decidere se
      lasciare il buco o rinumerare.

## B. Da controllare / sistemare

- [ ] **Prova n.165: 2 risposte giuste su 3.** La n.2 è giusta solo a metà:
      la `v2b` guardava l'ora del trascritto invece che quella della lavagna. Da
      correggere.
- [ ] **La sveglia v2e sta ancora girando** sul PC: si riarma ogni ~10 minuti.
      L'ultimo suono è alle 12:36, senza novità da Codex. Fermala quando non
      serve più.
- [ ] **Sessioni da riordinare in claude.ai/code**: diverse sessioni "Gancio"
      (n.162, n.164, b0f25c5a…) sono chiuse ma non archiviate, e hanno messaggi
      non letti. Se vuoi le archivio io.

## C. Repo VoicePipeline (domande ferme da agosto)

Branch `claude/migration-recovery-system-o6wzz4`, `.claude/state/HANDOVER.md` §7:

- [ ] **Qual è il "caso tipo"** di cui avevi parlato ("questa parte è
      generica, poi parleremo di un caso tipo")? Oggi la repo contiene solo il
      sistema di migrazione/ripresa: nessun codice VoicePipeline vero.
- [ ] **Il lavoro di dominio** va su quel branch o su uno nuovo?
- [ ] Il branch `main` è stato azzerato ("Repo reset: keep README"). Il sistema
      di migrazione esiste solo sul branch `claude/migration-recovery-system-o6wzz4`.
      Va deciso se riportarlo su main.

---

## Già chiuso oggi (per memoria, non serve fare niente)

- N-Z e i 286 chiusi con Codex (C125, C127). `nota_recupero.py` e `righe.py`
  restano.
- DI FILA installata in `fili_aperti.py` (59998488 → acb565b9). Passa 13 prove
  su 13 e Codex l'ha confermata (C128). Copia per tornare indietro:
  `ARCHIVIO\fili_aperti.py.prima_di_fila_20261124`.
- Sveglia v2e provata davvero: alle 12:14 è suonata e la sessione è ripartita
  da sola. Confermato da Codex (C131) insieme alle 6 installazioni.
