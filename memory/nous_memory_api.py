# -*- coding: utf-8 -*-
"""
Nous Memory API — micro-servico REST para gerenciar memorias e personas.

Porta 8993 (CORS liberado p/ o navegador em localhost:8080).

Memorias:
  GET  /memories?user_id=...&persona=...  lista memorias do usuario
  POST /memories                          { user_id, text, persona? } -> adiciona
  PUT  /memories/{id}                     { user_id, text }           -> edita texto
  DELETE /memories/{id}?user_id=...       deleta memoria

Personas:
  GET  /personas                          dicionario de todas as personas
  GET  /persona?user_id=...               persona ativa do usuario
  POST /persona                           { user_id, name } -> muda persona ativa
  POST /persona/config                    { name, folder?, description? } -> cria/edita
  DELETE /persona/{name}                  deleta persona (nunca 'default')

GET /health
"""
import os
import re
import json
import time
import sqlite3
from aiohttp import web

PORT        = 8993
DB_NAME     = "nous_memory.sqlite3"
ACTIVE_FILE = "nous_active_persona.json"
CONFIG_FILE = "nous_personas.json"
FILES_CFG   = "nous_files.json"


def _data_dir():
    for v in (os.environ.get("DATA_DIR"), os.environ.get("NOUS_DATA_DIR")):
        if v:
            return v
    return os.path.join(os.path.expanduser("~"), "NousData")


def _db():
    return os.path.join(_data_dir(), DB_NAME)


def _normalize(s):
    s = (s or "").lower().strip()
    s = re.sub(r"\s+", " ", s)
    s = re.sub(r"[.;:!?]+$", "", s)
    return s


def _read_json(path, default=None):
    try:
        with open(path, encoding="utf-8-sig") as f:
            return json.load(f) or (default if default is not None else {})
    except Exception:
        return default if default is not None else {}


def _write_json(path, data):
    os.makedirs(os.path.dirname(path) or ".", exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)


# ---- personas ---------------------------------------------------------------

def _active_path():  return os.path.join(_data_dir(), ACTIVE_FILE)
def _config_path():  return os.path.join(_data_dir(), CONFIG_FILE)
def _files_path():   return os.path.join(_data_dir(), FILES_CFG)


def get_active_persona(user_id):
    return _read_json(_active_path(), {}).get(user_id, "default")


def set_active_persona(user_id, persona):
    data = _read_json(_active_path(), {})
    data[user_id] = persona
    _write_json(_active_path(), data)
    _sync_files_folder(persona)


def _sync_files_folder(persona):
    """Atualiza nous_files.json com a pasta da persona ativa (sem sobrescrever se vazio)."""
    folder = get_personas().get(persona, {}).get("folder", "")
    if not folder:
        return
    cfg = _read_json(_files_path(), {})
    if cfg.get("folder") != folder:
        cfg["folder"] = folder
        _write_json(_files_path(), cfg)


def get_personas():
    data = _read_json(_config_path(), {})
    if "default" not in data:
        data["default"] = {"description": "Modo padrao", "folder": ""}
    return data


def upsert_persona(name, description, folder):
    data = get_personas()
    data[name] = {"description": description, "folder": folder}
    _write_json(_config_path(), data)


def remove_persona(name):
    if name == "default":
        return False
    data = get_personas()
    data.pop(name, None)
    _write_json(_config_path(), data)
    return True


# ---- memorias ---------------------------------------------------------------

def _conn():
    db = _db()
    if not os.path.isfile(db):
        return None
    cx = sqlite3.connect(db, timeout=10)
    return cx


def list_memories(user_id, persona=None):
    cx = _conn()
    if cx is None:
        return []
    try:
        cols = {r[1] for r in cx.execute("PRAGMA table_info(memories)").fetchall()}
        if "persona" in cols:
            if persona and persona != "all":
                rows = cx.execute(
                    "SELECT id, text, persona, created_at FROM memories "
                    "WHERE user_id=? AND (persona=? OR persona IS NULL) "
                    "ORDER BY created_at DESC",
                    (user_id, persona),
                ).fetchall()
            else:
                rows = cx.execute(
                    "SELECT id, text, persona, created_at FROM memories "
                    "WHERE user_id=? ORDER BY created_at DESC",
                    (user_id,),
                ).fetchall()
        else:
            rows = cx.execute(
                "SELECT id, text, 'default', created_at FROM memories "
                "WHERE user_id=? ORDER BY created_at DESC",
                (user_id,),
            ).fetchall()
        return [{"id": r[0], "text": r[1], "persona": r[2] or "default", "created_at": r[3]}
                for r in rows]
    finally:
        cx.close()


def add_memory(user_id, text, persona="default"):
    db = _db()
    if not os.path.isfile(db):
        return None
    cx = sqlite3.connect(db, timeout=10)
    try:
        cols = {r[1] for r in cx.execute("PRAGMA table_info(memories)").fetchall()}
        norm = _normalize(text)
        if "persona" in cols:
            if cx.execute(
                "SELECT id FROM memories WHERE user_id=? AND norm=? AND (persona=? OR persona IS NULL)",
                (user_id, norm, persona),
            ).fetchone():
                return None
            cur = cx.execute(
                "INSERT INTO memories(user_id, text, norm, created_at, persona) VALUES(?,?,?,?,?)",
                (user_id, text, norm, int(time.time()), persona),
            )
        else:
            if cx.execute(
                "SELECT id FROM memories WHERE user_id=? AND norm=?", (user_id, norm)
            ).fetchone():
                return None
            cur = cx.execute(
                "INSERT INTO memories(user_id, text, norm, created_at) VALUES(?,?,?,?)",
                (user_id, text, norm, int(time.time())),
            )
        cx.commit()
        return cur.lastrowid
    finally:
        cx.close()


def edit_memory(mem_id, user_id, text):
    cx = _conn()
    if cx is None:
        return False
    try:
        norm = _normalize(text)
        cx.execute(
            "UPDATE memories SET text=?, norm=? WHERE id=? AND user_id=?",
            (text, norm, mem_id, user_id),
        )
        cx.commit()
        changed = cx.execute("SELECT changes()").fetchone()[0]
        return changed > 0
    finally:
        cx.close()


def delete_memory(mem_id, user_id):
    cx = _conn()
    if cx is None:
        return False
    try:
        cx.execute("DELETE FROM memories WHERE id=? AND user_id=?", (mem_id, user_id))
        cx.commit()
        changed = cx.execute("SELECT changes()").fetchone()[0]
        return changed > 0
    finally:
        cx.close()


# ---- handlers ---------------------------------------------------------------

async def h_health(request):
    return web.json_response({"ok": True})


async def h_list(request):
    uid = request.rel_url.query.get("user_id")
    if not uid:
        return web.json_response({"error": "user_id required"}, status=400)
    persona = request.rel_url.query.get("persona")
    return web.json_response(list_memories(uid, persona))


async def h_add(request):
    body = await request.json()
    uid  = body.get("user_id")
    text = (body.get("text") or "").strip()
    if not uid or not text:
        return web.json_response({"error": "user_id and text required"}, status=400)
    mid = add_memory(uid, text, body.get("persona", "default"))
    if mid is None:
        return web.json_response({"ok": False, "reason": "duplicate"})
    return web.json_response({"ok": True, "id": mid})


async def h_edit(request):
    try:
        mid = int(request.match_info["id"])
    except Exception:
        return web.json_response({"error": "invalid id"}, status=400)
    body = await request.json()
    uid  = body.get("user_id")
    text = (body.get("text") or "").strip()
    if not uid or not text:
        return web.json_response({"error": "user_id and text required"}, status=400)
    return web.json_response({"ok": edit_memory(mid, uid, text)})


async def h_delete(request):
    try:
        mid = int(request.match_info["id"])
    except Exception:
        return web.json_response({"error": "invalid id"}, status=400)
    uid = request.rel_url.query.get("user_id")
    if not uid:
        return web.json_response({"error": "user_id required"}, status=400)
    return web.json_response({"ok": delete_memory(mid, uid)})


async def h_personas(request):
    return web.json_response(get_personas())


async def h_get_active(request):
    uid = request.rel_url.query.get("user_id", "default")
    return web.json_response({"persona": get_active_persona(uid)})


async def h_set_active(request):
    body = await request.json()
    uid  = body.get("user_id", "default")
    name = (body.get("name") or body.get("persona") or "default").strip()
    set_active_persona(uid, name)
    return web.json_response({"ok": True, "persona": name})


async def h_save_persona(request):
    body = await request.json()
    name = (body.get("name") or "").strip()
    if not name:
        return web.json_response({"error": "name required"}, status=400)
    upsert_persona(name, body.get("description", ""), body.get("folder", ""))
    return web.json_response({"ok": True})


async def h_del_persona(request):
    name = request.match_info["name"]
    if name == "default":
        return web.json_response({"error": "cannot delete default"}, status=400)
    return web.json_response({"ok": remove_persona(name)})


# ---- CORS / app -------------------------------------------------------------

_CORS = {
    "Access-Control-Allow-Origin":  "*",
    "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type",
}


@web.middleware
async def cors_mw(request, handler):
    if request.method == "OPTIONS":
        return web.Response(status=204, headers=_CORS)
    resp = await handler(request)
    resp.headers.update(_CORS)
    return resp


def build_app():
    app = web.Application(middlewares=[cors_mw])
    app.add_routes([
        web.get("/health",          h_health),
        web.get("/memories",        h_list),
        web.post("/memories",       h_add),
        web.put("/memories/{id}",   h_edit),
        web.delete("/memories/{id}", h_delete),
        web.get("/personas",        h_personas),
        web.get("/persona",         h_get_active),
        web.post("/persona",        h_set_active),
        web.post("/persona/config", h_save_persona),
        web.delete("/persona/{name}", h_del_persona),
    ])
    return app


if __name__ == "__main__":
    web.run_app(build_app(), host="127.0.0.1", port=PORT, print=None)
