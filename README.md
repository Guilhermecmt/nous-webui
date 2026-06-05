<div align="center">

<img src="branding/assets/nous_logo.png" width="140" alt="Nous">

# Nous

**IA local, privada e elegante — uma interface "Branco & Ouro" sobre Ollama + Open WebUI.**

[![version](https://img.shields.io/badge/version-1.0.0-c8962e)](CHANGELOG.md)
[![license](https://img.shields.io/badge/license-MIT-black)](LICENSE)
[![platform](https://img.shields.io/badge/Windows-11-0078D6)](#requisitos)

</div>

---

## O que e o Nous

O **Nous** (do grego *νοῦς*, "mente/intelecto") e um pacote de identidade + ferramentas
que transforma o **Open WebUI** rodando localmente sobre o **Ollama** em um produto
proprio, bonito e privado:

- 🦉 **Marca propria** — coruja imperial dourada, nome "Nous", tema claro Branco & Ouro
- 🔒 **100% local** — modelo (Gemma 4 12B) e conversas nunca saem da sua maquina
- 🌐 **Busca na web** opcional via DuckDuckGo (sem chave de API)
- 🧠 **Analise de capacidade** — verifica se a maquina aguenta rodar antes de instalar
- 💾 **Backup inteligente** dos seus dados (conversas/conta) com poda automatica
- 🚀 **Execucao em segundo plano** — sem janelas de terminal

> Este repositorio contem as **ferramentas e a identidade** (scripts, tema, launchers).
> O motor (Ollama, Python/Open WebUI, o modelo) e instalado a parte — veja abaixo.

## Requisitos

| Recurso | Minimo | Recomendado |
|--------|--------|-------------|
| SO     | Windows 10/11 | Windows 11 |
| RAM    | 16 GB | 32 GB |
| GPU/VRAM | — (roda na CPU) | 8 GB+ (ideal 12 GB+) |
| Disco  | 20 GB livres | 30 GB+ |

Rode a analise automatica:

```powershell
powershell -ExecutionPolicy Bypass -File tools\check-system.ps1
```

Ela retorna **CAPAZ (GPU)**, **CAPAZ (CPU)** ou **INCAPAZ** (com o motivo) e um codigo de saida.

## Instalacao (resumo)

1. **Ollama** — https://ollama.com  → `ollama pull gemma4:12b`
2. **Python 3.11** + ambiente:
   ```powershell
   py -3.11 -m venv $env:USERPROFILE\open-webui
   & $env:USERPROFILE\open-webui\Scripts\python.exe -m pip install open-webui
   ```
3. **Aplicar a identidade Nous**:
   ```powershell
   & $env:USERPROFILE\open-webui\Scripts\python.exe branding\apply_branding.py
   ```
4. **Iniciar** (segundo plano, abre o navegador sozinho):
   ```powershell
   powershell -ExecutionPolicy Bypass -File launchers\start-nous.ps1
   ```
   ou compile para `.exe` sem janela: `launchers\build-exe.ps1`.

> Um **instalador de 1 clique** com assistente de primeira execucao esta no [roadmap](docs/ROADMAP.md).

## Estrutura

```
Nous WebUI/
├─ branding/        identidade visual
│  ├─ apply_branding.py   aplica logo + favicons + tema + nome
│  ├─ prepare_logo.py     gera a logo-mestre a partir de uma imagem-fonte
│  ├─ nous-gold.css       tema "Branco & Ouro"
│  └─ assets/             logos / icones
├─ launchers/       iniciar/parar (segundo plano) + build do .exe
├─ tools/           check-system, backup-data, reset-password
├─ bkp/             backups locais dos dados (ignorados pelo git)
└─ docs/            roadmap e notas
```

## Backup dos dados

```powershell
powershell -ExecutionPolicy Bypass -File tools\backup-data.ps1
```
Gera um `.zip` com carimbo de data em `bkp/` e mantem os 10 mais recentes.

## Esqueci a senha

```powershell
& $env:USERPROFILE\open-webui\Scripts\python.exe tools\reset-password.py --email voce@exemplo.com
```

## Roadmap

Veja [docs/ROADMAP.md](docs/ROADMAP.md) — instalador de 1 clique, assistente de
primeira execucao, verificacao pos-instalacao e bandeja do sistema.

## Licenca

[MIT](LICENSE). "Open WebUI" e "Ollama" pertencem aos seus respectivos projetos.
