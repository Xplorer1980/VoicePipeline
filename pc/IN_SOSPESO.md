<!-- NOTA DI RICOSTRUZIONE (non fa parte del file originale)
LA LISTA DI OLTRE 200 COSE IN SOSPESO NON E' STATA TROVATA nei trascritti delle sessioni 82ff1c66 (n.165), 6687da7b e
b0f25c5a (dal 24/11 07:00 in poi). Nessuna uscita di fili_aperti.py e nessun file elenca oltre 200 voci.
La sessione n.165 ha ricevuto la richiesta alle 12:50 ma non l'ha eseguita.
Qui sotto c'e' il file piu' vicino: B:\DB_260922\LAVORO\SOSPESI_RIPRISTINO_20261124.md.
Lo ha scritto Gancio b0f25c5a alle 12:48 su tua richiesta delle 12:44 ("todolist e tutte le cose rimaste in sospeso").
E' COMPLETO: e' il contenuto esatto della Write andata a buon fine. Contiene 8 lavori aperti e le domande A-H e K.
-->
# Sospesi del ripristino, 24/11/2026 ore 12:48

Fatto da Gancio b0f25c5a su richiesta di Raf delle 12:44 ("todolist e tutte le cose rimaste in sospeso").
Fonti lette adesso: stato\sala\in_corso.txt, LAVORO\DA_CHIEDERE_A_RAF.md, lavagna fino a C131 (12:17),
log `LOG_MODIFICHE_SENZA_CONSENSO_20261124.md` (righe 46-143), REGISTRO.md fino alle 12:25.
Catena: b0f25c5a (fino 11:07) -> 6687da7b (testimone n.164, fino 12:0x) -> 82ff1c66 (testimone n.165, attiva).
Cartella Vault = B:\Sethis_Vault\Working\CONFRONTO_HOOK_20261123\

## 1. Da fare (lavoro, nessuno fatto)
- [ ] ID_FISSI.tsv (B:\DB_261109\INFRASTRUTTURA\) ha i due ID vecchi di Gancio e Codex: da riallineare con la tua procedura PRIMA del prossimo passaggio, se no il problema si ripete (Codex C129, C131).
- [ ] no_annidate: l'eccezione oltre il 70% usa 700.000 token fissi; Codex vuole la capacità vera della sessione, che nessun dato dell'app mostra (C126, C130). Aperta.
- [ ] raf_giu: doppie risposte (log, riga 68). Aperta.
- [ ] Ripristino oltre gli hook e oltre le ultime due settimane: le ~16.000 righe dal 22/09 nei programmi lanciati a mano (3.652 righe in blocchi senza tuo ordine, BLOCCHI.tsv). Letti: hook, automatici, A-M e N-Z dei manuali; non letti blocco per blocco gli altri. Aspetta la domanda H.
- [ ] Sveglia: provata davvero alle 12:14 (G-C132, C131). La v2 sta ancora nel Vault (CANDIDATO_SVEGLIA\sveglia_lavoro_v2.py), non installata in PYTHON\SISTEMA\sessioni; la v1 è superata.
- [ ] Salute di Warburg delle 14:00: controllare se il filtro sui DETTAGLI_TECNICI ha rimesso a posto i risultati (SALUTE_WARBURG_GANCIO_20261124).
- [ ] Guardiano della posta di Codex rotto dal 19/11 (file di stato pieni di zeri): domanda G.
- [ ] Sessioni vecchie da archiviare (skill testimone, "Chi arriva" passo 4): 27e2b4ea, 445260c1, questa b0f25c5a, e la 6687da7b. Rinominate, non archiviate.

## 2. Da chiedere a te (LAVORO\DA_CHIEDERE_A_RAF.md, aperte)
- A. Togliere dalle attività di Windows i 4 promemoria scaduti a settembre?
- B. Warburg cerca solo dalle chat di agosto 2026 ("per ora", 12/10): allargarlo a tutte?
- C. Lettura a pezzi solo per le chat: allargarla a ogni file lungo?
- D. Quattro hook miei (storia, barre_bash, negato, ora_registro): restano?
- E. no_annidate e lettura_comune: restano?
- F. dove_eravamo e registro_sql nel giro di fine risposta: tolti? (dove_eravamo è già tolto da fine_turno alle 10:36)
- G. Guardiano della posta di Codex: lo ripara Gancio o Codex?
- H. Le altre ~16.000 modifiche: da dove si riparte, per data o per cartella?
- K. Proposte nuove (NON fatte, sono modifiche nuove): richiesta_raf anche su settings.json, regole.tsv e DB\RAF\*.tsv; frase RICHIESTA solo nel tuo ultimo messaggio; confronto con la prima versione una volta a settimana alle 6; lettura a pezzi per ogni file lungo.
(I e J decise col tuo mandato delle 11:16: I installata come RITIRO CITAZIONE dentro universale 64c187af; J resta com'è.)

## 3. Fatto oggi, con la prova (per non rifarlo)
| file | cosa | SHA prima -> dopo | chi |
|---|---|---|---|
| fine_turno.py | tolti titoli_nuovi e dove_eravamo | aa3a0cb5 -> 035af44f | b0f25c5a |
| cerca_prima.py | tolto tieni_raf; 3 fonti; `--senza-tecnici` | 4a8cead0 -> b51b4854 | b0f25c5a |
| ricerca\cerca.py | opzione `--senza-tecnici` | fc361b87 -> 41bbf6ad | b0f25c5a |
| hook\no_annidate_da_approvare.py | start_session oltre il 70% | 2d772c35 -> 2f30253f | b0f25c5a |
| trova_caldo.py, warburg.py, critico.py | rimessi come prima | -> 1f15ef49, 74424a67, 463b09db | 6687da7b + Codex |
| ora_registro.py, universale.py | riparati (universale con RITIRO di FATTO e CITAZIONE) | -> b2dbac5f, 64c187af | 6687da7b + Codex |
| fili_aperti.py | uscita DI FILA ("TUTTO ASPETTA RAF") | 59998488 -> acb565b9 | 82ff1c66 + Codex |
Copie di prima: B:\DB_260922\ARCHIVIO\ e Vault INSTALLATI_20261124\. Ogni cambio ha la sua riga in REGISTRO.md.

## 4. Log e file creati oggi
- Resoconto per te: Vault RESOCONTO_PER_RAF_20261124.md
- Log delle mie modifiche senza consenso: Vault LOG_MODIFICHE_SENZA_CONSENSO_20261124.md (comune con Codex)
- Resoconto di Codex: Vault RESOCONTO_RIPRISTINO.md
- Lavagna: B:\Sethis_Vault\Working\LAVAGNA_GANCIO_CODEX.md
- Confronti: Vault RIPRISTINO_DA_ISTANTANEA\ (CONFRONTO.tsv, PRIMA_COPIA.tsv, BLOCCHI.tsv, BLOCCHI_DIFF\)
- Copia di tutti gli hook prima di oggi: B:\DB_260922\ARCHIVIO\HOOK_DI_GANCIO_20261124_0800\
- Testimoni: TESTIMONE_SESSIONE.md (n.165), ARCHIVIO\TESTIMONE_SESSIONE.n164.md; passaggi in stato\passaggi\
- Stato a programma: stato\sala\in_corso.txt

## Limiti (NON PROVATO)
- Questo elenco l'ho scritto io leggendo i file sopra: non è controllato da un programma.
- Non ho riletto la chat della 82ff1c66 dopo le 12:25: se ha fatto altro dopo, qui non c'è.
