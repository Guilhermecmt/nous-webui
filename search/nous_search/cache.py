# -*- coding: utf-8 -*-
"""Cache local (SQLite) para evitar repetir buscas identicas.

Chave = hash dos parametros da busca. TTL padrao de 6h. Usa so a stdlib.
"""
import os
import json
import time
import hashlib
import sqlite3

DEFAULT_DB = os.environ.get(
    "NOUS_CACHE_DB",
    os.path.join(os.path.dirname(os.path.dirname(__file__)), "search_cache.sqlite"),
)
DEFAULT_TTL = int(os.environ.get("NOUS_CACHE_TTL", 6 * 3600))


class Cache:
    """Cache chave->valor com expiracao, persistido em SQLite."""

    def __init__(self, path=DEFAULT_DB, ttl=DEFAULT_TTL):
        self.path = path
        self.ttl = ttl
        self._db = sqlite3.connect(self.path, check_same_thread=False)
        self._db.execute(
            "CREATE TABLE IF NOT EXISTS cache (key TEXT PRIMARY KEY, ts REAL, value TEXT)"
        )
        self._db.commit()

    @staticmethod
    def _key(*parts):
        raw = "|".join(str(p) for p in parts)
        return hashlib.sha256(raw.encode("utf-8")).hexdigest()

    def get(self, *parts):
        key = self._key(*parts)
        row = self._db.execute(
            "SELECT ts, value FROM cache WHERE key = ?", (key,)
        ).fetchone()
        if not row:
            return None
        ts, value = row
        if self.ttl and (time.time() - ts) > self.ttl:
            self._db.execute("DELETE FROM cache WHERE key = ?", (key,))
            self._db.commit()
            return None
        try:
            return json.loads(value)
        except json.JSONDecodeError:
            return None

    def set(self, value, *parts):
        key = self._key(*parts)
        self._db.execute(
            "INSERT OR REPLACE INTO cache (key, ts, value) VALUES (?, ?, ?)",
            (key, time.time(), json.dumps(value, ensure_ascii=False)),
        )
        self._db.commit()

    def clear(self):
        self._db.execute("DELETE FROM cache")
        self._db.commit()


# instancia compartilhada (conveniencia)
cache = Cache()
