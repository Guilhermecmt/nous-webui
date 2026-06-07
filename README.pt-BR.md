<div align="center">

<img src="branding/assets/nous_logo.png" width="120" alt="Logo do Nous">

# Nous

**Sua IA particular — bonita, local e sua.**

Chat · Visão · Geração de imagem local · Busca na web — 100% no seu PC.  
Sem nuvem. Sem chaves de API. Nada sai da sua máquina.

[![version](https://img.shields.io/badge/version-1.5.1-c8962e)](CHANGELOG.md)
[![license](https://img.shields.io/badge/license-MIT-black)](LICENSE)
[![platform](https://img.shields.io/badge/Windows-10%20%7C%2011-0078D6)](#requisitos)
[![local](https://img.shields.io/badge/100%25-local%20%26%20privado-2ea44f)](#por-que-o-nous)

[English](README.md) · **Português**

<img src="docs/screenshots/hero-github.png" width="860" alt="Interface do Nous">

</div>

---

## Por que o Nous

**Nous** (do grego *νοῦς*, "mente / intelecto") transforma o conjunto local **Ollama + Open WebUI** num produto próprio, bonito e privado — tema sereno **Branco & Ouro**, a marca da coruja e algumas coisas que o conjunto cru não entrega:

- **Realmente privado** — o modelo e todas as conversas ficam no seu computador.
- **Lembra de você** — aprende fatos duráveis sobre você ao longo das conversas e os recupera sozinho, no seu PC. O que a nuvem não pode fazer com segurança.
- **Bonito por padrão** — tema, logo, alternância claro/escuro, UI com identidade.
- **Gera imagens localmente** — peça *"crie uma imagem de…"* e ela aparece inline no chat, via ComfyUI + Flux. Sem assinatura.
- **Visão** — solte um print ou foto e pergunte; o modelo realmente vê a imagem.
- **Busca na web** — opcional, via DuckDuckGo. Sem chave de API.
- **Painel de recursos** — VRAM / memória compartilhada em tempo real, modelos carregados e um botão para liberar a placa na hora.
- **Roda em segundo plano** — sem janelas de terminal; abre por um atalho.

> Este repositório traz a **identidade + ferramentas** (tema, launchers, instaladores, o pipeline de imagem, o monitor). O motor (Ollama, Python/Open WebUI, o modelo) é instalado pelos scripts abaixo.

---

<div align="center">
<img src="docs/screenshots/philosophy-banner.png" width="860" alt="Nous — The Intelligence Engine">
</div>

---

## Em um relance

<div align="center">

<img src="docs/screenshots/dashboard-showcase.png" width="860" alt="Nous workspace">

<br><br>

<img src="docs/screenshots/performance.png" width="860" alt="Rode IA na sua máquina">

</div>

---

## Requisitos

| Recurso | Mínimo | Recomendado |
|---------|--------|-------------|
| SO      | Windows 10 / 11 | Windows 11 |
| RAM     | 16 GB | 32 GB |
| GPU / VRAM | nenhuma — roda na CPU | 8 GB+ (ideal 12 GB+) |
| Disco   | 20 GB livres | 30 GB+ |

> A geração de imagem é pesada na GPU. Funciona em **NVIDIA** (CUDA) e **AMD RDNA4 (RX 9070 / 9060)** via ROCm nativo; outras GPUs caem para CPU (lento).

Analise sua máquina primeiro:

```powershell
powershell -ExecutionPolicy Bypass -File tools\check-system.ps1
```

Retorna **CAPAZ (GPU)**, **CAPAZ (CPU)** ou **INCAPAZ** com o motivo.

---

## Começo rápido

### Mais fácil — baixar e dar clique duplo (recomendado)

1. Use o botão verde **Code → Download ZIP** no topo desta página (ou `git clone`).
2. Descompacte em qualquer lugar.
3. Abra a pasta e **dê clique duplo em `instalar.bat`**.

Pronto. Ele analisa a máquina, instala Ollama + Python + Open WebUI, aplica a identidade Nous e cria um atalho na área de trabalho — sem precisar abrir o PowerShell nem mudar nenhuma configuração. Se o Windows mostrar um aviso, escolha **Sim / Executar assim mesmo**.

Abra o Nous pelo atalho **Nous** na área de trabalho — ou, se ele não estiver lá, dê clique duplo em **`iniciar.bat`** na pasta.

> Os comandos de PowerShell abaixo são para usuários avançados e precisam ser rodados **de dentro da pasta do Nous** (caminhos relativos como `tools\check-system.ps1` só funcionam ali).

### Opção A — Instalador (`.exe`) · para usuários finais

`installer\nous-setup.iss` gera o **`Nous-Setup.exe`** (Inno Setup): um instalador online pequeno que baixa e configura tudo, cria atalhos e um desinstalador. Compile com `ISCC.exe installer\nous-setup.iss` → `dist\Nous-Setup.exe`.  
*(Não assinado — o Windows pode pedir "Mais informações → Executar assim mesmo".)*

### Opção B — Um comando · para desenvolvedores

```powershell
powershell -ExecutionPolicy Bypass -File installer\install-nous.ps1
```

Idempotente. Verifica a capacidade da máquina, instala **Ollama + Python + Open WebUI** só se faltarem, aplica a identidade Nous, conserta a logo, cria o atalho e roda uma verificação de saúde. Use **`-WithImages`** para instalar também o motor de imagem (ComfyUI + Flux), ou **`-Force`** para reinstalar.

### Opção C — Manual

```powershell
# 1) Ollama  →  https://ollama.com  (o modelo é baixado depois, dentro do app)
# 2) Python 3.11 + Open WebUI
py -3.11 -m venv $env:USERPROFILE\open-webui
& $env:USERPROFILE\open-webui\Scripts\python.exe -m pip install open-webui
# 3) Aplicar a identidade Nous (logo, tema, alternância claro/escuro)
& $env:USERPROFILE\open-webui\Scripts\python.exe branding\apply_branding.py
# 4) Iniciar (segundo plano, abre o navegador)
powershell -ExecutionPolicy Bypass -File launchers\start-nous.ps1
```

### Primeiro uso — escolher um modelo

Abra o Nous, crie sua conta (a **primeira conta é a admin**), vá em  
**Admin Panel → Settings → Models**, digite `gemma4:12b` em *"Pull a model from Ollama.com"* e baixe — o progresso aparece na tela. Selecione o modelo no topo do chat e converse.

---

## Geração de imagem local (opcional)

```powershell
# Instala o ComfyUI + o PyTorch certo p/ a sua GPU + modelos do Flux.1 Schnell (~12 GB)
powershell -ExecutionPolicy Bypass -File images\install-comfyui.ps1
```

Reinicie o Nous (`launchers\start-nous.ps1`) — o Pipe de imagem se registra sozinho, sem credenciais. Inicie o motor (`images\start-comfyui.ps1`), selecione **Gerador de Imagem Local** no dropdown de modelos e peça: *"crie uma logo dourada de uma coruja"* — a imagem aparece **na conversa**. O Flux Schnell é Apache-2.0 (uso comercial liberado).

---

## O painel de recursos

Um pequeno card **Recursos** (canto inferior esquerdo) consulta um micro-serviço local (`monitor/nous_monitor.py`, porta 8990) e mostra, ao vivo:

- **VRAM** e **memória compartilhada** da GPU (totais estilo Gerenciador de Tarefas),
- quais modelos estão **carregados** e quanto cada um usa, com contagem para descarga,
- um botão **"Parar modelos"** que libera a VRAM na hora.

O launcher sobe o serviço automaticamente; os modelos saem da VRAM **30 s** após a última mensagem (configurável).

---

## Memória — o Nous lembra de você

O Nous mantém uma memória pessoal que vive **só na sua máquina** (`memory/nous_memory.py`, um filter global do Open WebUI). Conforme você conversa, ele aprende fatos duráveis sobre você — nome, cidade, trabalho, gostos — e os recupera nas conversas seguintes. Um status *"Nous lembrou de N detalhe(s) sobre você"* aparece quando isso acontece.

Ela se instala sozinha ao abrir (sem importar nada, sem painel) e guarda tudo em `nous_memory.sqlite3` dentro da sua pasta de dados, que é gitignored. É o primeiro passo do que torna o Nous diferente: *uma IA na nuvem pode ser inteligente; só uma IA local pode ser realmente sua.*

---

## Como funciona

```
            ┌──────────────── Nous (Open WebUI com tema) ──────────────┐
  Você ───▶ │  Chat · Visão · Busca na web · Painel de recursos        │
            └───────────────┬────────────────────────┬─────────────────┘
                texto/visão │            "crie uma imagem…"
                            ▼                         ▼
                  Ollama (gemma4:12b)        ComfyUI + Flux.1 Schnell
                     100% local                  100% local
                            └──────────► imagem salva como arquivo nativo
                                          → mostrada inline no chat
```

---

## Ferramentas

```powershell
tools\backup-data.ps1                 # zip dos seus dados (conversas/conta), mantém 10
tools\check-system.ps1                # veredito de capacidade (RAM, VRAM real, disco)
tools\health-check.ps1                # verificação pós-instalação
python tools\reset-password.py --email voce@exemplo.com   # esqueci a senha
```

## Desinstalar

Dê clique duplo em **`desinstalar.bat`** e escolha uma opção:

- **[1] Remoção segura** — remove só o app Nous isolado (o ambiente Python, o atalho e os launchers) e **preserva** seus dados (`NousData`), suas notas em `Documentos\Nous` e as ferramentas compartilhadas (Ollama, Python).
- **[2] Remover tudo** — também apaga seus dados e desinstala Ollama/Python.

Ele lê o manifesto de instalação, então Ollama/Python só são removidos **se foi o Nous que os instalou** — um Ollama/Python que já existia nunca é tocado. (Avançado, de dentro da pasta: `installer\uninstall-nous.ps1 -All` ou `-Force`.)

## Estrutura

```
Nous WebUI/
├─ branding/    identidade: logo, tema Branco & Ouro, toggle claro/escuro, apply_branding.py
├─ images/      geração de imagem: instalador do ComfyUI, modelos Flux, o Pipe do chat
├─ monitor/     o serviço do painel de recursos (GPU + modelos carregados)
├─ launchers/   iniciar/parar em segundo plano + build do .exe sem console
├─ installer/   instalador de 1 comando + o script do Inno Setup (.exe)
├─ search/      busca na web + RAG opcionais (DuckDuckGo)
├─ tools/       verificação de capacidade, backup, reset de senha, health check
└─ docs/        roadmap, screenshots
```

## Roadmap

Veja [docs/ROADMAP.md](docs/ROADMAP.md) — instalador de 1 clique de verdade, assistente de primeira execução e um **app de bandeja** que inicia/para o Nous + ComfyUI juntos.

---

<div align="center">
<img src="docs/screenshots/wallpaper.png" width="860" alt="Nous — Your Personal AI Sovereign">
</div>

---

## Construído sobre

[Open WebUI](https://github.com/open-webui/open-webui) ·
[Ollama](https://ollama.com) ·
[ComfyUI](https://github.com/comfyanonymous/ComfyUI) ·
[Flux.1 Schnell](https://huggingface.co/black-forest-labs/FLUX.1-schnell) (Apache-2.0).  
Marcas pertencem aos seus respectivos projetos.

## Licença

[MIT](LICENSE) © Nous. Contribuições são bem-vindas — abra uma issue ou um PR.
