# Changelog

Todas as mudancas notaveis do Nous. Formato baseado em
[Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/) e
[Versionamento Semantico](https://semver.org/lang/pt-BR/).

## [1.8.0] - 2026-06-08
### Adicionado
- **Painel "O que o Nous sabe" — Fase 3** (`memory/nous_memory_api.py`): micro-servico
  REST local (porta 8993, CORS aberto para localhost) que expoe as memorias para o
  novo painel flutuante da UI. Endpoints: listar, adicionar, editar e deletar memorias;
  criar/trocar/deletar personas; sincronizar pasta de arquivos ao trocar persona.
- **Personas — Fase 5** (`memory/`): suporte a multiplos modos de uso com contexto
  de memoria independente. Cada persona tem seu proprio conjunto de memorias e,
  opcionalmente, uma pasta de arquivos diferente.
  - Migracao automatica da tabela `memories`: adiciona coluna `persona TEXT DEFAULT
    'default'` (compativel com dados existentes).
  - `nous_memory.py` atualizado: le a persona ativa de `nous_active_persona.json`
    (escrito pela API) no `inlet` e `outlet`; filtra memorias por persona; salva
    novas memorias com a tag da persona ativa.
  - `branding/nous-loader.js` atualizado: botao flutuante (icone cerebro, canto
    inferior direito) abre painel "O que o Nous sabe" com seletor de persona,
    lista de memorias editaveis/deletaveis, formulario para criar novas personas
    (com pasta de arquivos opcional) e campo para adicionar memorias manualmente.
- `launchers/start-nous.ps1`: adiciona `Start-MemoryAPI` nos dois pontos de boot.

## [1.7.0] - 2026-06-08
### Adicionado
- **Historico de conversas — Fase 4** (`history/`): o Nous agora recupera contexto
  de dialogos anteriores do usuario e o injeta automaticamente em cada resposta.
  - `history/index_history.py` — indexador incremental em modo watch (60 s): le
    `webui.db` do Open WebUI em modo somente-leitura, agrupa mensagens em pares
    dialogo (pergunta + resposta seguinte), gera embeddings via Ollama
    (`nomic-embed-text`, prefixo `search_document:`), tabela FTS5 de duas colunas
    (`user_msg`, `asst_msg`). Deduplicacao por `msg_id`. Singleton por porta (8992).
    Marca d'agua de tempo com 1 h de sobreposicao para capturar respostas tardias.
  - `history/nous_history.py` — Filter global do Open WebUI com busca **hibrida**
    (semantica + FTS5/BM25, RRF). Filtra pelo `user_id` (cada usuario ve so' o
    proprio historico). Exclui a conversa atual (evita auto-referencia circular).
    Limiar `MIN_SIM=0.60`. Status: *"Nous encontrou contexto em N conversa(s)
    anterior(es)."* Complementa Memoria Pessoal (fatos) e Arquivos (notas).
  - `history/register_history.py` — auto-registra o filter em `webui.db` (sem
    login, idempotente). Chamado pelo launcher a cada boot.
- `launchers/start-nous.ps1`: adicionadas funcoes `Start-HistoryIndexer`,
  `Register-History` e `Setup-History`; chamadas nos dois pontos de boot.

## [1.6.0] - 2026-06-07
### Adicionado
- **Acesso aos seus arquivos locais — Fase 2** (`files/`): o Nous agora consulta
  automaticamente sua pasta de notas (Obsidian, `.md`, `.txt`) e injeta os trechos
  mais relevantes no contexto de cada conversa.
  - `files/index_files.py` — indexador incremental: chunking por parágrafos/headings,
    embeddings via Ollama (`nomic-embed-text` com prefixo `search_document:`), tabela
    FTS5, mtime+hash para so' reindexa o que mudou. Modo watch (a cada 20 s).
    Singleton por porta (8991) para nao duplicar processo.
  - `files/nous_files.py` — Filter global do Open WebUI com busca **hibrida**:
    semântica (cosine similarity via matriz de embeddings) + palavra-chave (FTS5/BM25),
    fundidas por Reciprocal Rank Fusion. Limiar `MIN_SIM=0.65` bloqueia ruido
    (`search_query:` no embedding da consulta). Status: *"Nous consultou seus
    arquivos: arquivo.md"*. Stopwords PT/EN para eliminar tokens triviais do FTS.
  - `files/register_files.py` — auto-registra o filter direto no `webui.db` (sem
    login, idempotente). Chamado pelo launcher a cada boot.
- **Arena Model desativado** (`ENABLE_EVALUATION_ARENA_MODELS=False`): nao aparece
  mais no dropdown, evitando confusao.
- **Modelo pre-selecionado** (`DEFAULT_MODELS=gemma4:12b`): novo chat ja abre com
  o gemma4 selecionado; usuario nao precisa escolher nada.
### Mudado
- `instalar.bat` agora passa `-WithModel` por padrao: instala o gemma4:12b (~5 GB)
  durante o setup, sem precisar navegar ate Admin > Settings > Models.

## [1.5.1] - 2026-06-07
### Corrigido
- **Wordmark alinhado com a coruja na tela inicial**: o `body::after` fixo ficava
  longe da logo (topo vs centro). Agora o CSS o suprime quando a coruja esta'
  visivel e o `loader.js` injeta `.nous-home-wordmark` diretamente abaixo dela.
### Adicionado
- **Auto-registro do Pipe de imagem** (`images/register_pipe_auto.py`): o launcher
  registra o Gerador de Imagem Local **direto no banco** a cada boot, sem email
  nem senha. Instale o ComfyUI, reinicie o Nous e o Pipe ja' aparece no dropdown
  de modelos, sem nenhum comando extra.

## [1.5.0] - 2026-06-07
### Adicionado
- **Memoria pessoal persistente e 100% local** (`memory/nous_memory.py`): o Nous
  **lembra de voce entre conversas**. E' um Filter global do Open WebUI -
  `inlet` injeta no contexto o que ele ja sabe; `outlet` extrai novos fatos com o
  Ollama local e salva em `nous_memory.sqlite3` (dentro do `NousData`, gitignored).
  Captura fatos duraveis (nome, cidade, trabalho, gostos) e acontecimentos do dia
  a dia (com data). Mostra status na tela: *"Nous lembrou de N detalhe(s)..."*.
- **Auto-instalacao da memoria** (`memory/register_memory.py`): grava a funcao
  direto no banco como Filter **global e ativo** - sem login, sem painel, sem
  importar nada. O launcher roda isso a cada inicio (idempotente; re-sincroniza o
  codigo). E' o primeiro passo do diferencial do Nous: *uma IA na nuvem pode ser
  inteligente; so' uma IA local pode ser realmente sua.*
### Corrigido
- A memoria agora e' **mesclada no system message existente** em vez de criar um
  segundo (que o Ollama descartava) - sem isto, o recall nao chegava ao modelo.

## [1.4.0] - 2026-06-06
### Adicionado
- **Geracao de imagem local** (ComfyUI + Flux.1 Schnell): peca *"crie uma imagem
  de ..."* no chat e a imagem aparece **inline**. Pipe **assincrono** (nao trava o
  servidor) que salva a imagem como **arquivo nativo** do Open WebUI (persistente).
  - `images/install-comfyui.ps1`: instala o ComfyUI + o PyTorch certo p/ a GPU
    (NVIDIA CUDA, AMD RDNA4 ROCm nativo, ou CPU) + custom node GGUF + modelos Flux.
  - `images/register_pipe.py`: registra o Pipe "Gerador de Imagem Local" (idempotente).
- **Visao**: o Gemma agora **le imagens** que voce envia (prints, fotos). O Pipe
  passa as imagens em base64 ao Ollama; antes elas eram descartadas (ele "chutava").
- **Painel de Recursos** (canto inferior esquerdo): VRAM / memoria compartilhada da
  GPU em tempo real, modelos carregados (com contagem regressiva de descarga) e
  botao **"Parar modelos"**. Servico local `monitor/nous_monitor.py` (porta 8990).
- Botao flutuante de tema **claro/escuro** na tela inicial (`branding/nous-loader.js`).
### Mudado
- `OLLAMA_KEEP_ALIVE=30s` (era 5 min): o modelo **sai da VRAM rapido**. O Pipe
  tambem envia `keep_alive` por requisicao.
- `WEBUI_SECRET_KEY` agora e' **fixada** (chave local em `NousData`): fim dos
  logouts a cada reinicio do servidor.
- Busca na web: `BYPASS_WEB_SEARCH_EMBEDDING_AND_RETRIEVAL=True` corrige o
  "nao tenho acesso a informacoes em tempo real".
- `download-models.ps1`: VAE do Flux agora de um **espelho aberto** (sem login).
### Corrigido
- **Logo/favicons que sumiam (404)**: `apply_branding.py` agora **cria** os PNGs
  que faltavam em `/static` (favicon.png, splash.png, logo.png, ...).

## [1.3.0] - 2026-06-05
### Adicionado
- `installer/nous-setup.iss` -> **`dist/Nous-Setup.exe`** (~8 MB): instalador online
  (Inno Setup) que baixa e configura tudo (Ollama, Python, Open WebUI, identidade),
  cria atalhos e desinstalador. Assistente em portugues.
- Marca **"Nous"** (wordmark) na interface, em fonte serifada classica (Cinzel).
- `branding/make_marble.py`: gerador opcional de textura de marmore.
### Mudado
- Tema: removido o fundo de marmore (ficou poluido); mantidos os acentos dourados.
- Sugestoes da tela inicial: on-brand em portugues por padrao.

## [1.2.0] - 2026-06-05
### Mudado
- A instalacao **nao baixa mais o modelo** por padrao (setup leve, ~5-6 GB). O
  modelo e baixado **dentro do app** (Open WebUI: Admin > Settings > Models), com
  barra de progresso nativa. Use `install-nous.ps1 -WithModel` para baixar no setup.
### Adicionado
- `check-system.ps1` agora **recomenda o modelo** conforme o hardware
  (gemma4:12b com GPU; gemma4:e4b em CPU).
- `health-check.ps1`: ausencia de modelo passou a ser informativa (nao falha mais).

## [1.1.0] - 2026-06-05
### Adicionado
- `installer/install-nous.ps1` — instalador idempotente de **1 comando**: porteiro de
  capacidade (aborta se INCAPAZ) -> Ollama -> modelo -> Python 3.11 -> Open WebUI ->
  identidade Nous -> atalho + launcher oculto -> verificacao. Pula o que ja existe;
  `-Force` reinstala.
- `tools/health-check.ps1` — verificacao pos-instalacao (Ollama no ar, modelo presente,
  ambiente, identidade aplicada, servidor respondendo) com codigo de saida.

## [1.0.0] - 2026-06-04
### Adicionado
- Identidade visual **Nous**: logo da coruja imperial dourada, favicons (png/svg/ico)
  e tema claro **Branco & Ouro** (`branding/`).
- `apply_branding.py` — aplica logo + favicons + tema + nome "Nous" (remove o
  sufixo "(Open WebUI)"), de forma portatil (`import open_webui`).
- `prepare_logo.py` — gera a logo-mestre transparente a partir de uma imagem-fonte.
- `tools/check-system.ps1` — analise inteligente de capacidade da maquina
  (RAM, VRAM real via registro, disco) com veredito e codigo de saida.
- `tools/backup-data.ps1` — backup compactado dos dados com poda automatica.
- `tools/reset-password.py` — redefinicao de senha local (sem segredos no codigo).
- `launchers/` — iniciar/parar em **segundo plano** (sem janela de terminal) e
  `build-exe.ps1` para gerar `.exe` sem console.
- Persistencia dos dados em `DATA_DIR` fora do `site-packages` (sobrevive a updates).
- Documentacao: README, este changelog e o [roadmap](docs/ROADMAP.md).

[1.0.0]: https://github.com/Guilhermecmt/nous-webui/releases/tag/v1.0.0
