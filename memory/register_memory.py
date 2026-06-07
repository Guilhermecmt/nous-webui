# -*- coding: utf-8 -*-
"""
Instala/atualiza a funcao 'Nous Memory' DIRETO no banco do Open WebUI, como
Filter GLOBAL e ATIVO. Sem credenciais, sem navegador, sem painel de admin.

Idempotente: pode rodar a cada inicializacao do Nous. Re-sincroniza o codigo
de nous_memory.py (o arquivo em disco e' a fonte da verdade) e garante que a
funcao continua ativa + global.

USO:
    python memory/register_memory.py [--data-dir <DATA_DIR>] [--filter <arquivo>]
"""
import os
import sys
import time
import json
import argparse
import sqlite3

FUNC_ID = "nous_memory"
FUNC_NAME = "Nous Memory"
DESC = ("Memoria pessoal persistente e 100% local: o Nous lembra de voce entre "
        "conversas. Injeta o que ja sabe e extrai novos fatos automaticamente.")


def resolve_db(data_dir):
    """Acha o webui.db do Open WebUI (DATA_DIR, env, ou via import open_webui)."""
    candidates = []
    if data_dir:
        candidates.append(data_dir)
    for env in ("DATA_DIR", "NOUS_DATA_DIR"):
        v = os.environ.get(env)
        if v:
            candidates.append(v)
    for d in candidates:
        p = os.path.join(d, "webui.db")
        if os.path.isfile(p):
            return p
    try:  # ultimo recurso: pergunta ao proprio open_webui
        from open_webui.env import DATABASE_URL
        if DATABASE_URL.startswith("sqlite") and ":///" in DATABASE_URL:
            p = DATABASE_URL.split(":///", 1)[1]
            if os.path.isfile(p):
                return p
    except Exception:
        pass
    return os.path.join(candidates[0], "webui.db") if candidates else None


def table_exists(cx, name):
    row = cx.execute(
        "SELECT name FROM sqlite_master WHERE type='table' AND name=?", (name,)
    ).fetchone()
    return row is not None


def pick_creator(cx):
    """Usa um admin como 'criador' da funcao (so' metadado). Tolerante a ausencia."""
    try:
        row = cx.execute(
            "SELECT id FROM user WHERE role='admin' ORDER BY created_at LIMIT 1"
        ).fetchone()
        if row:
            return row[0]
        row = cx.execute("SELECT id FROM user ORDER BY created_at LIMIT 1").fetchone()
        if row:
            return row[0]
    except Exception:
        pass
    return "nous-system"  # ainda nao ha conta; global filter funciona mesmo assim


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--data-dir", default=None)
    ap.add_argument("--filter", default=os.path.join(
        os.path.dirname(os.path.abspath(__file__)), "nous_memory.py"))
    a = ap.parse_args()

    if not os.path.isfile(a.filter):
        sys.exit(f"Filter nao encontrado: {a.filter}")
    content = open(a.filter, encoding="utf-8").read()

    db = resolve_db(a.data_dir)
    if not db or not os.path.isfile(db):
        print("webui.db ainda nao existe (servidor nao iniciou). "
              "A memoria sera registrada na proxima inicializacao.")
        return  # nao e' erro: o launcher tenta de novo no proximo boot

    cx = sqlite3.connect(db, timeout=15)
    try:
        if not table_exists(cx, "function"):
            print("Tabela 'function' ainda nao criada pelo servidor. Tentarei no proximo boot.")
            return

        now = int(time.time())
        meta = json.dumps({"description": DESC, "manifest": {}})
        creator = pick_creator(cx)

        row = cx.execute(
            "SELECT user_id FROM function WHERE id=?", (FUNC_ID,)
        ).fetchone()

        if row:
            # Mantem o criador existente, a menos que fosse placeholder e agora haja admin.
            user_id = row[0]
            if (user_id in (None, "", "nous-system")) and creator != "nous-system":
                user_id = creator
            cx.execute(
                """UPDATE function
                   SET name=?, type='filter', content=?, meta=?,
                       is_active=1, is_global=1, user_id=?, updated_at=?
                   WHERE id=?""",
                (FUNC_NAME, content, meta, user_id, now, FUNC_ID),
            )
            action = "atualizada"
        else:
            cx.execute(
                """INSERT INTO function
                   (id, user_id, name, type, content, meta, valves,
                    is_active, is_global, updated_at, created_at)
                   VALUES (?,?,?,?,?,?,?,?,?,?,?)""",
                (FUNC_ID, creator, FUNC_NAME, "filter", content, meta, None,
                 1, 1, now, now),
            )
            action = "instalada"

        cx.commit()
        print(f"Memoria do Nous {action}: Filter global e ativo (id='{FUNC_ID}').")
    finally:
        cx.close()


if __name__ == "__main__":
    main()
