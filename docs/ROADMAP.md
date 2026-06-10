# Roadmap — Nous

Objetivo maior: transformar o Nous em um **programa que qualquer pessoa baixa e usa**,
sem conhecimento tecnico, com tudo acontecendo em segundo plano.

## v1.0 — Fundacao (feito)
- Identidade visual (logo, favicons, tema Branco & Ouro), nome "Nous".
- Persistencia dos dados fora do `site-packages` (`DATA_DIR`).
- Execucao em segundo plano (sem janela de terminal).
- Ferramentas: analise de capacidade, backup, reset de senha.
- Repositorio versionado (Git + SemVer + CHANGELOG).

## v1.1 — Instalador de 1 clique
- **Bootstrapper unico** (`install-nous`) que faz tudo sem interacao tecnica:
  1. **Porteiro de capacidade** — roda `check-system.ps1`; se **INCAPAZ**, mostra
     um erro claro (RAM/VRAM/disco) e aborta antes de baixar qualquer coisa.
  2. Instala o **Ollama** silenciosamente (winget/instalador, sem janelas).
  3. O **modelo** NAO e baixado na instalacao — fica para **dentro do app**
     (Open WebUI: Admin > Settings > Models), com progresso nativo na tela.
     Mantem o setup leve (~5-6 GB) e deixa o usuario escolher o modelo.
  4. Cria o ambiente **Python 3.11** + instala o **Open WebUI**.
  5. Aplica a **identidade Nous** (`apply_branding.py`).
  6. Cria atalhos (Iniciar/Parar Nous) e configura inicio automatico opcional.
- Tudo **oculto/segundo plano**; UI de progresso propria (nada de prompt cru).

## v1.2 — Assistente de primeira execucao (First-Run Wizard)
- Tela de boas-vindas nativa no primeiro uso da maquina:
  - passo a passo visual (instalar / baixar modelo / pronto);
  - deteccao automatica do que ja existe (idempotente);
  - criacao da conta admin local.

## v1.3 — Verificacao inteligente pos-instalacao (Health Check)
- Servico que confirma que **tudo** subiu certo: Ollama no ar, modelo presente,
  servidor respondendo, GPU em uso. Em caso de falha, mensagem acionavel
  (ex.: "GPU nao detectada — rodando na CPU", "modelo nao baixado", etc.).

## v1.6 — Nous Nuvem (feito)
- Acesso *opt-in* a modelos de fronteira via NVIDIA NIM API (gratuito, sem GPU).
- `cloud/register_nvidia.py` — registro idempotente no banco a cada boot.
- `ativar-nuvem.bat` / `desativar-nuvem.bat` — ativacao por clique duplo, sem terminal.
- Memoria pessoal protegida: nao injetada em modelos de nuvem por padrao.

## v1.4 — Bandeja do sistema (System Tray)
- Icone na bandeja: Iniciar/Parar, abrir, status (rodando/parado, GPU/CPU),
  uso de memoria — substitui qualquer necessidade de terminal.

## v2.0 — Distribuicao
- Instalador assinado (.exe/MSI) para reduzir alerta do SmartScreen.
- Auto-update do Nous e do modelo.

---
### Principios
- **Nunca** mostrar janela de terminal ao usuario final.
- **Sempre** checar capacidade antes de baixar (falhar cedo, com mensagem clara).
- **Idempotente**: rodar de novo nao quebra nada; detecta o que ja existe.
- **Privado por padrao**: dados locais; nada sai da maquina sem acao explicita.
