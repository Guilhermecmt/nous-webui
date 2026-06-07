# Nous · Busca na Web (SearXNG) + RAG local

Busca na web **100% local** para o Nous: um metabuscador **SearXNG** em Docker,
a funcao `search_web()`, **cache local** (para nao repetir buscas) e um **RAG
simples** que responde com o seu modelo do Ollama (`gemma4:12b`) citando as fontes.

```
Pergunta ─▶ search_web() ─▶ SearXNG (Docker, :8888) ─▶ top 5 resultados
                 │
                 ▼
          cache local (SQLite, TTL 6h)
                 │
                 ▼
   build_context() ─▶ Ollama (gemma4:12b, :11434) ─▶ resposta com [citacoes]
```

## Por que SearXNG
- **Privado**: você controla o metabuscador; nada de telemetria de terceiros.
- **Sem chave de API**: agrega Google, Bing, DuckDuckGo, etc.
- **API JSON**: fácil de consumir em Python.

## 1. Subir o SearXNG (Docker)
Pré-requisito: **Docker Desktop**.
```powershell
cd search
docker compose up -d
```
Confira em http://localhost:8888. (Porta **8888** de propósito, para não colidir
com o Open WebUI em 8080 nem com o Ollama em 11434.)

> Edite `searxng/settings.yml` e troque `secret_key` por um valor aleatório.

## 2. Instalar as dependências Python
```powershell
pip install -r requirements.txt
```

## 3. Usar
```powershell
# Só as fontes (rápido; testa o SearXNG)
python cli.py "melhores LLMs locais em 2026" --search-only

# Busca + RAG (resposta do gemma4:12b com citações [n])
python cli.py "melhores LLMs locais em 2026"

# RAG "deep": baixa o texto das páginas (contexto mais rico)
python cli.py "o que é quantização Q4_K_M" --deep

# Limpar o cache
python cli.py --clear-cache
```

Em código:
```python
from nous_search import search_web, answer

hits = search_web("ROCm RX 9070 XT", k=5)
res = answer("Resumo do estado dos LLMs locais", k=5)
print(res["answer"])    # texto com [1][2]...
print(res["sources"])   # lista de fontes
```

## Configuração (variáveis de ambiente)
| Var | Padrão | O que faz |
|---|---|---|
| `SEARXNG_URL` | `http://localhost:8888` | endpoint do SearXNG |
| `OLLAMA_URL` | `http://localhost:11434` | endpoint do Ollama |
| `NOUS_MODEL` | `gemma4:12b` | modelo usado no RAG |
| `NOUS_SEARCH_LANG` | `pt-BR` | idioma da busca |
| `NOUS_CACHE_TTL` | `21600` (6h) | validade do cache, em segundos |
| `NOUS_CACHE_DB` | `search/search_cache.sqlite` | arquivo do cache |

## Integrar no Open WebUI (bônus, sem código)
O Open WebUI já usa o SearXNG como provedor de busca nativo:
**Admin Panel → Settings → Web Search** → Engine **searxng** →
Query URL: `http://localhost:8888/search?q=<query>`. Assim o próprio chat passa a
pesquisar via seu SearXNG (melhor que o DuckDuckGo padrão que você tinha ligado).

## Próximo passo: agente com LangGraph
`nous_search/agent.py` traz o **esboço** de um agente que evolui o RAG linear
para um grafo com estado (planejar → buscar → avaliar se precisa de mais →
sintetizar com citações). Para ativar:
```powershell
pip install langgraph
python -m nous_search.agent "sua pergunta de pesquisa"
```

## Arquivos
```
search/
├─ docker-compose.yml      SearXNG em Docker (porta 8888)
├─ searxng/settings.yml    config mínima (habilita JSON, desliga limiter)
├─ requirements.txt
├─ cli.py                  demonstração de linha de comando
└─ nous_search/
   ├─ cache.py             cache local SQLite (TTL)
   ├─ search.py            search_web() -> SearXNG JSON
   ├─ rag.py               build_context() + answer() via Ollama
   └─ agent.py             esboço do agente LangGraph (próximo passo)
```
