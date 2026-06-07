# -*- coding: utf-8 -*-
"""search_web(): busca na web via SearXNG (API JSON) com cache local."""
import os
import requests
from .cache import cache as _cache

SEARXNG_URL = os.environ.get("SEARXNG_URL", "http://localhost:8888").rstrip("/")
DEFAULT_LANG = os.environ.get("NOUS_SEARCH_LANG", "pt-BR")


def search_web(query, k=5, *, lang=DEFAULT_LANG, categories="general",
               use_cache=True, timeout=15):
    """Busca `query` no SearXNG e retorna os `k` melhores resultados.

    Cada resultado e um dict: {title, url, content, engine, score}.
    Resultados ficam em cache local (TTL 6h) para nao repetir a busca.
    """
    query = (query or "").strip()
    if not query:
        return []

    if use_cache:
        hit = _cache.get("search", query, k, lang, categories)
        if hit is not None:
            return hit

    params = {
        "q": query,
        "format": "json",
        "language": lang,
        "categories": categories,
        "safesearch": 0,
    }
    resp = requests.get(
        f"{SEARXNG_URL}/search",
        params=params,
        timeout=timeout,
        headers={"User-Agent": "Nous/1.0 (+local)"},
    )
    resp.raise_for_status()
    data = resp.json()

    results = []
    for item in data.get("results", [])[:k]:
        results.append({
            "title": (item.get("title") or "").strip(),
            "url": item.get("url", ""),
            "content": (item.get("content") or "").strip(),
            "engine": item.get("engine", ""),
            "score": item.get("score", 0),
        })

    if use_cache:
        _cache.set(results, "search", query, k, lang, categories)
    return results
