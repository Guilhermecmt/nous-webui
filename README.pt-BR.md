<div align="center">

<img src="branding/assets/nous_logo.png" width="120" alt="Logo do Nous">

# Nous

**Sua IA particular — bonita, local e sua.**

Chat · Visão · Geração de imagem local · Busca na web — 100% no seu PC.  
Sem nuvem. Sem chaves de API. Nada sai da sua máquina.

[![version](https://img.shields.io/badge/version-2.1.0-c8962e)](CHANGELOG.md)
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
- **Lê seus arquivos** — aponte para o seu vault do Obsidian (ou qualquer pasta de notas) e o Nous busca automaticamente nos seus `.md`/`.txt` e injeta os trechos relevantes em cada conversa.
- **Bonito por padrão** — tema, logo, alternância claro/escuro, UI com identidade.
- **Gera imagens localmente** — peça *"crie uma imagem de…"* e ela aparece inline no chat, via ComfyUI + Flux. Sem assinatura.
- **Visão** — solte um print ou foto e pergunte; o modelo realmente vê a imagem.
- **Busca na web** — opcional, via DuckDuckGo. Sem chave de API.
- **Painel de recursos** — VRAM / memória compartilhada em tempo real, modelos carregados e um botão para liberar a placa na hora.
- **Roda em segundo plano** — sem janelas de terminal; abre por um atalho.

---

<div align="center">
<img src="docs/screenshots/philosophy-banner.png" width="860" alt="Nous — The Intelligence Engine">
</div>

---

## Requisitos

| Recurso | Mínimo | Recomendado |
|---------|--------|-------------|
| SO      | Windows 10 / 11 | Windows 11 |
| RAM     | 8 GB | 16 GB+ |
| GPU / VRAM | nenhuma — roda na CPU (lento) | 8 GB+ VRAM para aceleração por GPU |
| Disco   | 20 GB livres | 30 GB+ |

> **Sem GPU dedicada?** O Nous funciona em CPUs também — só um pouco mais lento (1–2 min por resposta). O instalador detecta isso automaticamente e escolhe um modelo mais leve para você.

---

## Começo rápido — clique duplo para instalar

> **Isso é tudo que você precisa fazer.** Sem terminal, sem configuração.

1. Clique no botão verde **Code → Download ZIP** no topo desta página.
2. Descompacte em qualquer lugar (ex.: `Downloads\Nous WebUI`).
3. Abra a pasta e **dê clique duplo em `instalar.bat`**.
4. Se o Windows mostrar um aviso, escolha **"Mais informações → Executar assim mesmo"** ou **"Sim"**.

O instalador vai:
- Verificar seu hardware e escolher o modelo de IA ideal para sua máquina
- Instalar o Ollama, o Python e o Open WebUI automaticamente
- Baixar o modelo de IA (~3–5 GB — leva alguns minutos)
- Criar um atalho **Nous** na sua Área de Trabalho

Quando terminar, **abra o Nous pelo atalho na Área de Trabalho**.

> Se o atalho não aparecer, dê clique duplo em **`iniciar.bat`** na pasta do Nous.

---

## Primeiro uso — 3 passos

**Passo 1 — Crie sua conta**

A primeira tela pede para você se cadastrar. Digite qualquer nome, qualquer e-mail, qualquer senha — essa conta fica só na sua máquina. **A primeira conta criada vira automaticamente a administradora.**

**Passo 2 — Selecione seu modelo**

O instalador baixou o modelo que você escolheu. O nome dele aparece no seletor de modelos no topo do chat. Clique nele e comece a conversar.

> Quer um modelo diferente? Clique no nome do modelo no topo → Search → digite qualquer nome do [ollama.com/library](https://ollama.com/library) → Download.

**Passo 3 — Comece a usar**

Digite qualquer coisa. O Nous está pronto.

---

## Qual modelo de IA devo usar?

**O Nous funciona com qualquer modelo disponível em [ollama.com/library](https://ollama.com/library)** — são centenas. O instalador mostra as especificações da sua máquina e pergunta qual modelo você quer; basta digitar qualquer nome do catálogo do Ollama.

Para trocar de modelo depois: abra o chat, clique no nome do modelo no topo, pesquise o que quiser e clique em Download. Você pode ter vários modelos instalados ao mesmo tempo e trocar livremente entre eles.

A tabela abaixo traz alguns exemplos populares — são sugestões, não obrigações.

### Com GPU dedicada (NVIDIA ou AMD)

| Sua VRAM | Exemplo de modelo | Tamanho | Como é |
|----------|------------------|---------|--------|
| 8–10 GB | `gemma4:12b` | ~5 GB | Ótimo para chat, escrita e perguntas do dia a dia |
| 12–16 GB | `qwen3:14b` | ~9 GB | Raciocínio melhor, contexto mais longo |
| 20 GB+ | `qwen3:32b` | ~20 GB | Qualidade próxima ao GPT-4 |

> Não sabe sua VRAM? O instalador (`instalar.bat`) mostra o hardware antes de perguntar.

### Sem GPU dedicada (só CPU)

| Sua RAM | Exemplo de modelo | Tamanho | Como é |
|---------|------------------|---------|--------|
| 8–16 GB | `gemma4:e4b` | ~3 GB | Leve e rápido na CPU, bom para o dia a dia |
| 16–32 GB | `qwen3:8b` | ~5 GB | Melhor qualidade, um pouco mais lento |
| 32 GB+ | `gemma4:12b` | ~5 GB | Qualidade completa, mas lento (1–2 min/resposta) |

> Veja o catálogo completo em **[ollama.com/library](https://ollama.com/library)**. Qualquer modelo listado lá funciona com o Nous.

### Modelos de nuvem (opcional) — GPT-4, Claude, Gemini

O Nous é **local por padrão**, mas se um dia você quiser mais potência pode *opcionalmente* plugar um modelo pago de nuvem. Nada muda enquanto você não adicionar uma chave — sem ela, o Nous continua 100% local.

1. Abra o chat → **Admin Panel → Settings → Connections → OpenAI → +**.
2. Cole a URL base e a sua chave de API e clique em **Save**. Os modelos aparecem no seletor no topo.
   - **GPT-4 / GPT-4o** — URL `https://api.openai.com/v1` + sua chave da OpenAI.
   - **Claude + Gemini + GPT, uma só chave** — URL `https://openrouter.ai/api/v1` + sua chave do [OpenRouter](https://openrouter.ai). (É a forma recomendada de usar o Claude, que não é diretamente compatível com OpenAI.)

> **Seus dados continuam seus, mesmo com um modelo de nuvem.** Memória, arquivos e histórico rodam sempre no seu Ollama local — só o texto da conversa atual é enviado ao provedor que você escolheu. Um modelo de nuvem nunca vê suas notas indexadas nem suas memórias guardadas.

---

## Problemas comuns

### "O Windows protegeu seu computador" / "Editor desconhecido"

Isso é normal para software local sem assinatura digital. Clique em **"Mais informações"** → **"Executar assim mesmo"**.

### O atalho não apareceu na Área de Trabalho

Dê clique duplo em **`iniciar.bat`** na pasta do Nous. Abre do mesmo jeito.

### O Nous abre mas não tem modelo para conversar

Clique no nome do modelo no topo do chat → **Search** → digite `gemma4:12b` → clique no ícone de download. Aguarde terminar e selecione o modelo.

### Diz "Ollama não está rodando" ou o chat não responde

Abra o Nous pelo atalho da Área de Trabalho (não abra o site diretamente). O atalho já sobe o Ollama sozinho. Se já estiver aberto, clique em **Parar modelos** no painel de recursos e reabra.

### A instalação falhou / quero recomeçar

Dê clique duplo em **`desinstalar.bat`** → escolha **[1] Remoção segura** e depois dê clique duplo em **`instalar.bat`** de novo.

### Esqueci minha senha

Abra o PowerShell dentro da pasta do Nous e rode:
```powershell
python tools\reset-password.py --email seuemail@exemplo.com
```

---

## Geração de imagem local (opcional)

```powershell
powershell -ExecutionPolicy Bypass -File images\install-comfyui.ps1
```

Instala o ComfyUI + o PyTorch certo para a sua GPU + modelos do Flux.1 Schnell (~12 GB). Reinicie o Nous, selecione **Gerador de Imagem Local** no dropdown de modelos e peça: *"crie uma logo dourada de uma coruja"* — a imagem aparece **na conversa**.

---

## Memória — o Nous lembra de você

Conforme você conversa, o Nous aprende fatos duráveis sobre você — nome, cidade, trabalho, gostos — e os recupera nas conversas seguintes. Um status *"Nous lembrou de N detalhe(s) sobre você"* aparece quando isso acontece. Tudo fica armazenado localmente em `NousData`, nunca sincronizado.

---

## Arquivos — o Nous lê suas anotações

Aponte o Nous para uma pasta (seu vault do Obsidian, `Documentos\Nous`, qualquer coisa com `.md`/`.txt`) e ele buscará nas suas notas antes de cada resposta, injetando os trechos relevantes na conversa.

No primeiro boot, o Nous cria `Documentos\Nous` automaticamente. Coloque notas lá e o Nous vai usá-las. Para apontar para o seu vault do Obsidian, abra as configurações do filtro **Nous Files** no painel de admin e altere o valve `FOLDER`.

---

## Nous Nuvem — modelos de fronteira opcionais (NVIDIA NIM)

O Nous é privado por padrão. Mas se você quiser acesso a modelos de ponta (DeepSeek R1, Llama 3.3 70B, Qwen3 Coder, MiniMax M1, Kimi K2…), pode conectar opcionalmente à API de inferência gratuita da NVIDIA — **sem GPU, sem cartão de crédito, sem assinatura**.

> ⚠️ **Aviso de privacidade:** conversas com modelos de nuvem são enviadas para os servidores da NVIDIA para processamento. Sua **memória pessoal nunca é enviada** — o Nous a protege automaticamente nas requisições de nuvem.

### Como ativar

1. Obtenha uma chave de API gratuita em [build.nvidia.com/models](https://build.nvidia.com/models) — cadastre-se no NVIDIA Developer Program (gratuito).
2. Dê clique duplo em **`ativar-nuvem.bat`** na pasta do Nous, cole sua chave e clique em OK.
3. Reinicie o Nous — os modelos de nuvem curados aparecem no dropdown de modelos.

Para desativar: clique duplo em **`desativar-nuvem.bat`** e reinicie o Nous. Nenhum rastro permanece.

**Free tier:** ~1.000 créditos de inferência no cadastro (até 5.000 com e-mail corporativo), 40 requisições/minuto. Projetado para uso pessoal — exatamente o caso de uso do Nous.

---

## Painel de recursos

Um pequeno card **Recursos** (canto inferior esquerdo) mostra o uso de VRAM em tempo real, quais modelos estão carregados e um botão **"Parar modelos"** que libera a GPU na hora.

---

## Desinstalar

Dê clique duplo em **`desinstalar.bat`** e escolha uma opção:

- **[1] Remoção segura** *(recomendado)* — remove só o app Nous e o ambiente Python. Preserva suas conversas, notas, o Ollama e o Python.
- **[2] Remover tudo** — também apaga suas conversas e desinstala Ollama/Python (somente os que o Nous instalou — um Ollama/Python que já existia nunca é tocado).

---

## Estrutura

```
Nous WebUI/
├─ branding/    identidade: logo, tema Branco & Ouro, toggle claro/escuro, apply_branding.py
├─ files/       RAG local: indexador, filtro de busca híbrida, script de auto-registro
├─ images/      geração de imagem: instalador do ComfyUI, modelos Flux, o Pipe do chat
├─ memory/      filtro de memória pessoal + script de auto-registro
├─ monitor/     o serviço do painel de recursos (GPU + modelos carregados)
├─ launchers/   iniciar/parar em segundo plano + build do .exe sem console
├─ installer/   instalador de 1 comando + o script do Inno Setup (.exe)
├─ search/      busca na web + RAG opcionais (DuckDuckGo)
├─ tools/       verificação de capacidade, backup, reset de senha, health check
└─ docs/        roadmap, screenshots
```

## Uso avançado

<details>
<summary>Opções para desenvolvedores / usuários avançados</summary>

### Verificação de hardware manual

```powershell
powershell -ExecutionPolicy Bypass -File tools\check-system.ps1
```

Mostra **CAPAZ (GPU)**, **CAPAZ (CPU)** ou **INCAPAZ** com detalhes do hardware e recomendações de modelos.

### Instalar pela linha de comando

```powershell
powershell -ExecutionPolicy Bypass -File installer\install-nous.ps1 -WithModel -Model qwen3:14b
```

Idempotente. Verifica capacidade, instala Ollama + Python + Open WebUI só se faltarem, aplica a identidade, cria atalho. Use `-WithImages` para instalar também o ComfyUI, ou `-Force` para reinstalar.

### Instalação manual

```powershell
# 1) Ollama  →  https://ollama.com
# 2) Python 3.11 + Open WebUI
py -3.11 -m venv $env:USERPROFILE\open-webui
& $env:USERPROFILE\open-webui\Scripts\python.exe -m pip install open-webui
# 3) Aplicar a identidade Nous
& $env:USERPROFILE\open-webui\Scripts\python.exe branding\apply_branding.py
# 4) Iniciar
powershell -ExecutionPolicy Bypass -File launchers\start-nous.ps1
```

### Ferramentas

```powershell
tools\backup-data.ps1                                    # zip dos dados, mantém 10
tools\health-check.ps1                                   # verificação pós-instalação
python tools\reset-password.py --email voce@exemplo.com  # esqueci a senha
```

### Instalador .exe (Inno Setup)

`installer\nous-setup.iss` gera `dist\Nous-Setup.exe` com `ISCC.exe installer\nous-setup.iss`. Instalador online pequeno, cria atalhos e desinstalador. Não assinado — o Windows pode pedir "Mais informações → Executar assim mesmo".

</details>

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
