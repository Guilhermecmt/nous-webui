# Changelog

Todas as mudancas notaveis do Nous. Formato baseado em
[Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/) e
[Versionamento Semantico](https://semver.org/lang/pt-BR/).

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
