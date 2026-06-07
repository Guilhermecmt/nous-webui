# -*- coding: utf-8 -*-
"""Esboco do agente de pesquisa com LangGraph (PROXIMO PASSO).

Evolui o RAG linear (search -> context -> answer) para um grafo com estado,
capaz de planejar sub-perguntas, decidir se precisa buscar mais e sintetizar
com citacoes:

    plan -> search -> (precisa de mais?) --sim--> search
                              |
                             nao
                              v
                         synthesize -> END

Requer:  pip install langgraph
O langgraph e importado SOB DEMANDA (dentro de build_agent), entao o resto do
pacote nous_search funciona sem ele instalado.
"""
from typing import TypedDict, List, Dict
from .search import search_web
from .rag import answer as _rag_answer


class ResearchState(TypedDict, total=False):
    question: str
    subqueries: List[str]
    results: List[Dict]
    iterations: int
    max_iterations: int
    final: str


def _plan(state: ResearchState) -> ResearchState:
    # TODO: usar o LLM para decompor em varias sub-perguntas.
    state.setdefault("max_iterations", 2)
    state["iterations"] = 0
    state["subqueries"] = [state["question"]]
    state["results"] = []
    return state


def _search(state: ResearchState) -> ResearchState:
    found = []
    for q in state["subqueries"]:
        found.extend(search_web(q, k=5))
    # dedup por URL, preservando ordem
    seen, uniq = set(), []
    for r in state["results"] + found:
        if r["url"] in seen:
            continue
        seen.add(r["url"])
        uniq.append(r)
    state["results"] = uniq
    state["iterations"] = state.get("iterations", 0) + 1
    return state


def _need_more(state: ResearchState) -> str:
    # TODO: pedir ao LLM para avaliar se o contexto ja basta.
    if state["iterations"] < state.get("max_iterations", 2) and len(state["results"]) < 5:
        return "search"
    return "synthesize"


def _synthesize(state: ResearchState) -> ResearchState:
    res = _rag_answer(state["question"], k=5)
    state["final"] = res["answer"]
    state["results"] = res["sources"]
    return state


def build_agent():
    """Compila o grafo LangGraph. Levanta ImportError se o langgraph faltar."""
    from langgraph.graph import StateGraph, END

    g = StateGraph(ResearchState)
    g.add_node("plan", _plan)
    g.add_node("search", _search)
    g.add_node("synthesize", _synthesize)
    g.set_entry_point("plan")
    g.add_edge("plan", "search")
    g.add_conditional_edges(
        "search", _need_more, {"search": "search", "synthesize": "synthesize"}
    )
    g.add_edge("synthesize", END)
    return g.compile()


if __name__ == "__main__":
    import sys

    q = " ".join(sys.argv[1:]) or "estado dos LLMs locais em 2026"
    agent = build_agent()
    out = agent.invoke({"question": q})
    print(out.get("final", ""))
