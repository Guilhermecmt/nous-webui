# ============================================================================
#  Nous - Download dos modelos do Flux.1 Schnell para o ComfyUI
#  Baixa: UNET (GGUF Q4) + T5 + CLIP-L + VAE  (cabem nos 16 GB da RX 9070 XT)
#
#  USO:
#    .\download-models.ps1 -ComfyUI "C:\caminho\para\ComfyUI"
#
#  Observacao honesta: estes sao ~12 GB no total e as URLs do HuggingFace podem
#  mudar com o tempo. Se alguma falhar, baixe manualmente do repo indicado.
#  Flux Schnell e' Apache-2.0 (uso comercial liberado).
# ============================================================================
param(
    [Parameter(Mandatory = $true)]
    [string]$ComfyUI
)

if (-not (Test-Path $ComfyUI)) {
    Write-Host "Pasta do ComfyUI nao encontrada: $ComfyUI" -ForegroundColor Red
    exit 1
}

# destino_relativo  =>  url
$models = @(
    @{ dir = "models\unet"; file = "flux1-schnell-Q4_K_S.gguf";
       url = "https://huggingface.co/city96/FLUX.1-schnell-gguf/resolve/main/flux1-schnell-Q4_K_S.gguf" },
    @{ dir = "models\clip"; file = "t5xxl_fp8_e4m3fn.safetensors";
       url = "https://huggingface.co/comfyanonymous/flux_text_encoders/resolve/main/t5xxl_fp8_e4m3fn.safetensors" },
    @{ dir = "models\clip"; file = "clip_l.safetensors";
       url = "https://huggingface.co/comfyanonymous/flux_text_encoders/resolve/main/clip_l.safetensors" },
    @{ dir = "models\vae"; file = "ae.safetensors";
       # O repo oficial (black-forest-labs) exige login (HTTP 401). Usamos um
       # espelho ABERTO do mesmo autoencoder (~320 MB, identico ao do Flux).
       url = "https://huggingface.co/ffxvs/vae-flux/resolve/main/ae.safetensors" }
)

foreach ($m in $models) {
    $destDir = Join-Path $ComfyUI $m.dir
    if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Force -Path $destDir | Out-Null }
    $dest = Join-Path $destDir $m.file

    if (Test-Path $dest) {
        Write-Host "[ja existe] $($m.file)" -ForegroundColor DarkGray
        continue
    }
    Write-Host "[baixando ] $($m.file) ..." -ForegroundColor Cyan
    try {
        Invoke-WebRequest -Uri $m.url -OutFile $dest -UseBasicParsing
        Write-Host "[ok       ] $($m.file)" -ForegroundColor Green
    } catch {
        Write-Host "[FALHOU   ] $($m.file)  -> baixe manualmente de:" -ForegroundColor Yellow
        Write-Host "             $($m.url)" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "Pronto. Lembre de instalar o custom node 'ComfyUI-GGUF' (para o UnetLoaderGGUF)." -ForegroundColor White
Write-Host "  cd `"$ComfyUI\custom_nodes`"; git clone https://github.com/city96/ComfyUI-GGUF" -ForegroundColor White
