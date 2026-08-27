# VoicePipeline

## Sistema di migrazione e ripresa

Una sessione di lavoro AI puo' finire in qualsiasi momento: il contesto si
esaurisce, scatta un rate limit, il container viene reclamato. Senza un
meccanismo, quando succede il contesto se ne va con lei e si riparte da capo.

Questo repo ne ha uno. Il principio e' uno solo:

> **Il container e' effimero, il repo no.**
> Tutto quello che serve per riprendere il lavoro sta committato sul branch,
> o non esiste.

### I tre file di stato

| file | ruolo |
|---|---|
| `.claude/state/HANDOVER.md` | il testimone: missione, stato reale, prossime azioni, decisioni prese, vicoli ciechi |
| `.claude/state/lineage.json` | la catena: chi ha lavorato, quando, su cosa, chi ha passato a chi |
| `.claude/state/BOOT_PROMPT.md` | il prompt con cui e' nato l'ultimo successore |

### I tre comandi

```bash
./scripts/resume.sh                     # ripresa: cosa deve fare una sessione nuova
./scripts/handover.sh --reason "..."    # consegna: valida, mette al sicuro, prepara il successore
python3 scripts/lineage.py show         # chi ha lavorato e chi ha passato a chi
```

### Come funziona una consegna

1. La sessione uscente aggiorna `HANDOVER.md` e lancia `handover.sh`.
2. Lo script **valida** il documento — rifiuta template vuoti, sezioni
   incomplete, liste di azioni senza azioni — poi committa e pusha con retry.
   Se il push fallisce si ferma: meglio nessun successore che un successore
   senza stato.
3. Stampa i parametri esatti per `create_session`, incluso il prompt di avvio.
4. La sessione uscente crea il successore, lo registra nella catena e **ne
   comunica l'url a Raf**.
5. Il successore nasce con il branch gia' in checkout, esegue `resume.sh` e
   riprende dal primo punto aperto.

Nessuna dipendenza esterna: bash, git, python3 da stdlib.

### Per Raf

Ogni successore e' una sessione normale, visibile nella tua lista su
`claude.ai/code`, raggiungibile a `https://claude.ai/code/<session_id>`.
La catena completa e' sempre ricostruibile dal repo — anche se perdi tutte le
chat — con `python3 scripts/lineage.py show`.

Protocollo operativo completo: [`.claude/skills/migrazione/SKILL.md`](.claude/skills/migrazione/SKILL.md).
