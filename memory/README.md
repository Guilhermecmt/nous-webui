# Nous Memory

Memória pessoal persistente e **100% local** para o Nous. Faz o Nous lembrar de
você entre conversas — sem você curar nada, sem nuvem.

É a Fase 1 do diferencial do Nous: *uma IA na nuvem pode ser inteligente; só uma
IA local pode ser realmente sua, porque só nela você confia acesso à sua vida.*

## Como funciona

É um **Filter** do Open WebUI (mesma arquitetura do pipe de imagem):

- **`inlet`** — antes de cada resposta, injeta no contexto "o que o Nous já sabe
  sobre você".
- **`outlet`** — depois da resposta, usa o Ollama local para extrair fatos
  duráveis (preferências, trabalho, projetos, restrições) e salva.

Os dados ficam em `nous_memory.sqlite3`, dentro do `DATA_DIR` (`NousData`), que é
**gitignored**. Nada de pessoal sai da máquina nem entra no repositório.

## Instalação: automática

Você **não precisa fazer nada**. O launcher (`start-nous.ps1`) roda
`register_memory.py` a cada inicialização, que grava a função direto no banco do
Open WebUI como **Filter global e ativo** — sem login, sem painel, sem importar
nada. É idempotente e re-sincroniza o código de `nous_memory.py` todo boot (o
arquivo em disco é a fonte da verdade).

Para registrar manualmente uma vez (ex.: servidor já rodando, sem reiniciar):

```powershell
& $env:USERPROFILE\open-webui\Scripts\python.exe `
    memory\register_memory.py --data-dir $env:USERPROFILE\NousData
```

(Opcional) Em **Admin Panel → Functions → Nous Memory → Valves** dá para trocar o
`EXTRACT_MODEL` por um modelo menor/rápido e gastar menos GPU na extração.

## Testar (o "momento mágico")

1. Conte algo: *"meu nome é Guilherme e eu programo em Python"*.
2. Abra um **chat novo** e pergunte: *"o que você sabe sobre mim?"*.
3. Ele deve responder com o que memorizou.

## Valves

| Valve | Padrão | O que faz |
|-------|--------|-----------|
| `ENABLED` | `true` | Liga/desliga tudo |
| `EXTRACT` | `true` | Extrair fatos automaticamente |
| `EXTRACT_MODEL` | `gemma4:12b` | Modelo que extrai (pode ser menor) |
| `MAX_MEMORIES` | `200` | Quantas memórias injetar por conversa |
| `MIN_USER_CHARS` | `12` | Ignora mensagens curtas demais |
| `MAX_FACTS_PER_TURN` | `5` | Limite de fatos novos por mensagem |

## Próximas fases

- **Fase 2** — apontar o Nous para uma pasta (Documentos, Obsidian) e indexá-la
  automaticamente (RAG local sobre os seus arquivos reais).
- **Fase 3** — painel "O que o Nous sabe" no `nous-loader.js` para ver, editar e
  apagar memórias.
