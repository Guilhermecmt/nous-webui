# Nous · Geração de imagens (ComfyUI + Flux) — RX 9070 XT, 100% local

Geração de imagens **local**, integrada ao chat do Nous (Open WebUI), com
**detecção automática de intenção**: *"crie uma logo dourada de uma coruja"* gera
a imagem no **Flux** via **ComfyUI** e mostra **dentro da conversa**; qualquer
outra pergunta vai normalmente para o **Gemma**.

```
Chat (modelo "Nous") ─▶ Pipe ─▶ intenção de imagem? ─▶ ComfyUI ─▶ Flux ─▶ imagem inline
                              \▶ senão ───────────────▶ Ollama (gemma4:12b) ─▶ texto
```

## ✅ Status nesta máquina (testado e funcionando)
- **GPU:** AMD Radeon RX 9070 XT (RDNA4) — detectada como `cuda:0 ... : native`
- **Caminho que funcionou: ROCm NATIVO no Windows (sem ZLUDA!)** — graças às wheels
  `torch …+rocm7.13 (gfx120X)` + HIP SDK 7.1 (com libs gfx1201).
- **1ª geração:** ~32 s (carrega ~11 GB + compila); seguintes bem mais rápidas.
- ComfyUI em `C:\Users\<voce>\ComfyUI-Zluda`, em `http://localhost:8188`.
- Pipe **"Nous"** registrado e ativo no Open WebUI → aparece no seletor de modelos.

> Observação honesta sobre qualidade: o **Flux Schnell** (4 passos, Apache-2.0) é
> rápido mas tem **aderência limitada** a prompts específicos e **erra texto**.
> Para resultados mais fiéis use prompts em inglês, ou troque para **Flux Dev**
> (mais passos/qualidade, porém licença **não-comercial**).

## Como usar (no dia a dia)
1. **Suba o ComfyUI** (precisa estar no ar para gerar imagem):
   ```powershell
   powershell -ExecutionPolicy Bypass -File images\start-comfyui.ps1
   ```
   (Sobe em segundo plano, com `PYTHONUTF8=1`.)
2. No Nous, selecione o modelo **"Nous"** no topo do chat.
3. Peça uma imagem: *"crie uma logo dourada de uma coruja"*, *"gere uma paisagem
   futurista"*. Para texto, é só perguntar normalmente.

> ⚠️ Se o ComfyUI **não** estiver no ar, o Pipe responde com um aviso de erro em
> vez da imagem. Rode o `start-comfyui.ps1` antes.

## Como foi instalado (reproduzível em outra máquina RX 9000)
Pré-requisitos: **AMD HIP SDK** (testado com 7.1, traz libs gfx1201), **git**,
**Python 3.11**.

```powershell
# 1) ComfyUI (base)
git clone https://github.com/patientx/ComfyUI-Zluda "$env:USERPROFILE\ComfyUI-Zluda"
cd "$env:USERPROFILE\ComfyUI-Zluda"

# 2) venv + PyTorch ROCm NATIVO para RDNA4 (gfx120X) - este e' o pulo do gato
py -3.11 -m venv venv
venv\Scripts\python -m pip install --upgrade pip
venv\Scripts\pip install --pre torch torchvision torchaudio `
  --index-url https://rocm.nightlies.amd.com/v2/gfx120X-all/
venv\Scripts\pip install -r requirements.txt   # nao sobrescreve o torch ROCm

# 3) no GGUF (Flux quantizado) e suas deps
git clone https://github.com/city96/ComfyUI-GGUF custom_nodes\ComfyUI-GGUF
venv\Scripts\pip install -r custom_nodes\ComfyUI-GGUF\requirements.txt

# 4) modelos do Flux Schnell (~12 GB)
powershell -ExecutionPolicy Bypass -File "<repo>\images\download-models.ps1" -ComfyUI "$env:USERPROFILE\ComfyUI-Zluda"
```
> O `download-models.ps1` ja usa um espelho ABERTO para o VAE (o repo oficial da
> Black Forest Labs exige login). Modelos: `flux1-schnell-Q4_K_S.gguf` (unet),
> `t5xxl_fp8_e4m3fn.safetensors` + `clip_l.safetensors` (clip), `ae.safetensors` (vae).

Iniciar: `images\start-comfyui.ps1`  → http://localhost:8188

## O Pipe (integração com o chat)
`nous_image_pipe.py` é um **Pipe** do Open WebUI (já registrado aqui como função
"Nous"). Ele detecta intenção de imagem (PT/EN), gera no ComfyUI e devolve a
imagem inline; o resto encaminha ao `gemma4:12b`.

Para (re)instalar manualmente: Open WebUI → **Admin → Settings → Functions → "+"**
→ cole `nous_image_pipe.py` → salve e habilite. Valves úteis: `COMFYUI_URL`
(padrão `http://localhost:8188`), `STEPS`, `WIDTH/HEIGHT`, `STORAGE_DIR`,
`USE_LLM_CLASSIFIER`.

## Modularidade (adicionar modelos sem mexer no chat)
Troque/adicione um workflow do ComfyUI (formato API) e aponte a valve
`WORKFLOW_PATH`, ou adicione ao dicionário do Pipe. **SDXL, Flux Dev, ControlNet,
img2img, inpainting** entram assim — o frontend (o chat) nunca muda.

## Arquivos
```
images/
├─ README.md                este guia
├─ nous_image_pipe.py       Pipe do Open WebUI (detecção + roteamento)
├─ start-comfyui.ps1        sobe o ComfyUI (PYTHONUTF8) em segundo plano
├─ download-models.ps1      baixa o Flux Schnell (com espelho aberto p/ o VAE)
└─ workflows/
   └─ flux_schnell.json     workflow ComfyUI (Flux Schnell, formato API)
```
