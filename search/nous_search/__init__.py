# -*- coding: utf-8 -*-
"""nous_search - busca na web (SearXNG) + RAG local (Ollama) para o Nous."""
from .cache import Cache, cache
from .search import search_web
from .rag import build_context, fetch_page, answer

__all__ = ["search_web", "build_context", "fetch_page", "answer", "Cache", "cache"]
__version__ = "0.1.0"
