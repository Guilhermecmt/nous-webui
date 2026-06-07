# -*- coding: utf-8 -*-
"""CLI de demonstracao do nous_search.

Uso:
    python cli.py "sua pergunta"               # busca + RAG (resposta do LLM)
    python cli.py "sua pergunta" --search-only # so lista as fontes (testa o SearXNG)
    python cli.py "sua pergunta" --deep        # baixa as paginas (RAG mais rico)
    python cli.py --clear-cache                # limpa o cache local
"""
import sys
from nous_search import search_web, answer, cache


def main():
    argv = sys.argv[1:]
    if not argv or "--help" in argv or "-h" in argv:
        print(__doc__)
        return
    if "--clear-cache" in argv:
        cache.clear()
        print("Cache limpo.")
        return

    flags = {a for a in argv if a.startswith("--")}
    query = " ".join(a for a in argv if not a.startswith("--")).strip()
    if not query:
        print("Informe uma pergunta. Use --help.")
        return

    if "--search-only" in flags:
        results = search_web(query)
        if not results:
            print("Nenhum resultado. O SearXNG esta no ar em http://localhost:8888 ?")
            return
        for i, r in enumerate(results, 1):
            print(f"[{i}] {r['title']}")
            print(f"    {r['url']}")
            if r["content"]:
                print(f"    {r['content'][:160]}")
            print()
        return

    out = answer(query, deep="--deep" in flags)
    print(out["answer"])
    print("\nFontes:")
    for i, s in enumerate(out["sources"], 1):
        print(f"  [{i}] {s['url']}")


if __name__ == "__main__":
    main()
