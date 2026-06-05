# Changelog

Todas as mudancas notaveis do Nous. Formato baseado em
[Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/) e
[Versionamento Semantico](https://semver.org/lang/pt-BR/).

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
