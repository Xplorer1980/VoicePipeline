#!/usr/bin/env python3
"""Registro della catena di sessioni (lineage).

Il file .claude/state/lineage.json e' la memoria strutturata del sistema di
migrazione: chi ha lavorato, quando, su cosa, e a chi ha passato il testimone.
E' append-only per costruzione: le sessioni passate non vengono mai riscritte,
solo chiuse.

Uso:
  lineage.py init    --mission "..." --session <id> [--branch b] [--env e] ...
  lineage.py adopt   --session <id> [--parent <id>] [--url ...]   # presa in carico
  lineage.py handoff --session <id> --successor <id> --reason "..."
  lineage.py show                                                  # catena leggibile
  lineage.py current                                               # sessione attiva (json)
  lineage.py validate                                              # integrita' della catena
"""
from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

SCHEMA = 1
STATE_DIR = Path(".claude/state")
LINEAGE = STATE_DIR / "lineage.json"
SESSION_URL = "https://claude.ai/code/{}"


def now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def repo_root() -> Path:
    try:
        out = subprocess.run(
            ["git", "rev-parse", "--show-toplevel"],
            capture_output=True, text=True, check=True,
        ).stdout.strip()
        return Path(out)
    except (subprocess.CalledProcessError, FileNotFoundError):
        return Path.cwd()


def git(*args: str, default: str = "") -> str:
    try:
        return subprocess.run(
            ["git", *args], capture_output=True, text=True, check=True
        ).stdout.strip()
    except (subprocess.CalledProcessError, FileNotFoundError):
        return default


def load() -> dict:
    if not LINEAGE.exists():
        die(f"{LINEAGE} non esiste. Esegui prima: scripts/lineage.py init --mission ... --session ...")
    with LINEAGE.open(encoding="utf-8") as fh:
        return json.load(fh)


def save(data: dict) -> None:
    STATE_DIR.mkdir(parents=True, exist_ok=True)
    tmp = LINEAGE.with_suffix(".json.tmp")
    with tmp.open("w", encoding="utf-8") as fh:
        json.dump(data, fh, indent=2, ensure_ascii=False)
        fh.write("\n")
    tmp.replace(LINEAGE)


def die(msg: str, code: int = 1):
    print(f"ERRORE: {msg}", file=sys.stderr)
    sys.exit(code)


def find(data: dict, session_id: str):
    for link in data["chain"]:
        if link["session_id"] == session_id:
            return link
    return None


def new_link(seq: int, session_id: str, role: str, parent, args) -> dict:
    return {
        "seq": seq,
        "session_id": session_id,
        "url": SESSION_URL.format(session_id),
        "role": role,
        "parent": parent,
        "status": "active",
        "branch": args.branch or git("rev-parse", "--abbrev-ref", "HEAD", default="?"),
        "environment_id": args.env or os.environ.get("CLAUDE_ENV_ID", ""),
        "model": args.model or "",
        "permission_mode": args.permission_mode or "",
        "title": args.title or "",
        "opened_at": now(),
        "head_at_open": git("rev-parse", "HEAD", default=""),
        "closed_at": None,
        "handover_reason": None,
        "head_at_handover": None,
        "successor": None,
    }


# ---------------------------------------------------------------- comandi

def cmd_init(args):
    if LINEAGE.exists() and not args.force:
        die(f"{LINEAGE} esiste gia'. Usa 'adopt' per aggiungerti alla catena, o --force per ricominciare.")
    data = {
        "schema": SCHEMA,
        "mission": args.mission,
        "repo": args.repo or git("config", "--get", "remote.origin.url", default=""),
        "created_at": now(),
        "chain": [new_link(1, args.session, "root", None, args)],
    }
    save(data)
    print(f"Catena inizializzata. Radice: {args.session}")
    cmd_show(args)


def cmd_adopt(args):
    data = load()
    existing = find(data, args.session)
    if existing is not None:
        # il predecessore puo' averci gia' dichiarati prima di morire: promuoviamo
        if existing["status"] == "declared":
            existing["status"] = "active"
            existing["opened_at"] = now()
            existing["head_at_open"] = git("rev-parse", "HEAD", default="")
            for field, value in (("model", args.model), ("permission_mode", args.permission_mode),
                                 ("title", args.title), ("environment_id", args.env)):
                if value:
                    existing[field] = value
            save(data)
            print(f"Presa in carico confermata: #{existing['seq']} {args.session} (era dichiarata dal predecessore)")
        else:
            print(f"La sessione {args.session} e' gia' attiva nella catena: nessuna modifica.")
        cmd_show(args)
        return
    parent = args.parent
    if parent is None:
        actives = [l for l in data["chain"] if l["status"] in ("active", "handed_over")]
        if actives:
            parent = actives[-1]["session_id"]
    seq = max((l["seq"] for l in data["chain"]), default=0) + 1
    link = new_link(seq, args.session, "successor", parent, args)
    data["chain"].append(link)
    # il predecessore che aveva dichiarato questo successore risulta consegnato
    if parent:
        p = find(data, parent)
        if p and p["status"] == "active":
            p["status"] = "handed_over"
            p["closed_at"] = p["closed_at"] or now()
            p["successor"] = args.session
    save(data)
    print(f"Presa in carico registrata: #{seq} {args.session} (predecessore: {parent or 'nessuno'})")
    cmd_show(args)


def cmd_handoff(args):
    data = load()
    link = find(data, args.session)
    if link is None:
        die(f"Sessione {args.session} non presente nella catena. Esegui prima 'adopt'.")
    link["status"] = "handed_over"
    link["closed_at"] = now()
    link["handover_reason"] = args.reason
    link["head_at_handover"] = git("rev-parse", "HEAD", default="")
    if args.successor:
        # Registriamo SOLO il puntatore. La voce del successore la crea il
        # successore stesso con 'adopt': se la creassimo anche noi, due
        # sessioni scriverebbero la stessa voce sullo stesso branch e il
        # riallineamento produrrebbe un duplicato silenzioso.
        link["successor"] = args.successor
    save(data)
    print(f"Consegna registrata per {args.session}: {args.reason}")
    cmd_show(args)


def cmd_show(args):
    data = load()
    glyph = {"active": "*", "handed_over": "v", "declared": "?", "abandoned": "x"}
    print()
    print(f"  MISSIONE : {data['mission']}")
    print(f"  REPO     : {data['repo']}")
    print(f"  CATENA   : {len(data['chain'])} sessione/i")
    print()
    for link in data["chain"]:
        mark = glyph.get(link["status"], "-")
        print(f"  [{mark}] #{link['seq']}  {link['session_id']}   ({link['status']})")
        if link.get("title"):
            print(f"        titolo   : {link['title']}")
        print(f"        url      : {link['url']}")
        print(f"        branch   : {link['branch']}  |  modello: {link['model'] or '?'}  |  permessi: {link['permission_mode'] or '?'}")
        if link["opened_at"]:
            print(f"        aperta   : {link['opened_at']}")
        if link["closed_at"]:
            print(f"        chiusa   : {link['closed_at']}  ({link['handover_reason'] or 'motivo non registrato'})")
        heir = link.get("successor")
        if heir and not find(data, heir):
            print(f"        erede    : {heir} — dichiarato, non ancora presentatosi")
            print(f"                   {SESSION_URL.format(heir)}")
        print()


def cmd_current(args):
    data = load()
    actives = [l for l in data["chain"] if l["status"] == "active"]
    if not actives:
        die("Nessuna sessione attiva nella catena.")
    print(json.dumps(actives[-1], indent=2, ensure_ascii=False))


def cmd_validate(args):
    data = load()
    problems = []
    if data.get("schema") != SCHEMA:
        problems.append(f"schema {data.get('schema')} inatteso (atteso {SCHEMA})")
    seen = set()
    for link in data["chain"]:
        if link["session_id"] in seen:
            problems.append(f"sessione duplicata: {link['session_id']}")
        seen.add(link["session_id"])
        p = link.get("parent")
        if p and not find(data, p):
            problems.append(f"#{link['seq']} punta a un predecessore inesistente: {p}")
    actives = [l for l in data["chain"] if l["status"] == "active"]
    if len(actives) > 1:
        problems.append(
            "catena biforcata: piu' sessioni attive -> "
            + ", ".join(l["session_id"] for l in actives)
        )
    if problems:
        for p in problems:
            print(f"  ! {p}")
        die(f"{len(problems)} problema/i nella catena.")
    print(f"  OK: catena integra ({len(data['chain'])} sessioni, 1 attiva).")


def cmd_repair(args):
    """Fonde le voci duplicate e chiude le biforcazioni."""
    data = load()
    merged, order = {}, []
    for link in data["chain"]:
        sid = link["session_id"]
        if sid not in merged:
            merged[sid] = link
            order.append(sid)
            continue
        # duplicato: teniamo la voce piu' informativa
        keep, drop = merged[sid], link
        rank = {"active": 3, "handed_over": 2, "declared": 1, "abandoned": 0}
        if rank.get(drop["status"], 0) > rank.get(keep["status"], 0):
            keep, drop = drop, keep
        for field, value in drop.items():
            if value not in (None, "", []) and keep.get(field) in (None, "", []):
                keep[field] = value
        merged[sid] = keep
        print(f"  fuse due voci per {sid} -> stato '{keep['status']}'")

    chain = [merged[sid] for sid in order]
    for i, link in enumerate(chain, start=1):
        link["seq"] = i

    actives = [l for l in chain if l["status"] == "active"]
    for stale in actives[:-1]:
        stale["status"] = "handed_over"
        stale["closed_at"] = stale.get("closed_at") or now()
        stale["handover_reason"] = stale.get("handover_reason") or "chiusa da repair: biforcazione"
        print(f"  chiusa sessione attiva sorpassata: {stale['session_id']}")

    data["chain"] = chain
    save(data)
    print("  riparazione completata.")
    cmd_validate(args)


def main():
    os.chdir(repo_root())
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)

    def common(p):
        p.add_argument("--branch"); p.add_argument("--env")
        p.add_argument("--model"); p.add_argument("--permission-mode")
        p.add_argument("--title")

    p = sub.add_parser("init"); p.add_argument("--mission", required=True)
    p.add_argument("--session", required=True); p.add_argument("--repo")
    p.add_argument("--force", action="store_true"); common(p); p.set_defaults(func=cmd_init)

    p = sub.add_parser("adopt"); p.add_argument("--session", required=True)
    p.add_argument("--parent"); common(p); p.set_defaults(func=cmd_adopt)

    p = sub.add_parser("handoff"); p.add_argument("--session", required=True)
    p.add_argument("--successor"); p.add_argument("--reason", required=True)
    common(p); p.set_defaults(func=cmd_handoff)

    for name, fn in (("show", cmd_show), ("current", cmd_current),
                     ("validate", cmd_validate), ("repair", cmd_repair)):
        p = sub.add_parser(name); common(p); p.set_defaults(func=fn)

    args = ap.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
