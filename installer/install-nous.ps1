<#
.SYNOPSIS
  Nous WebUI - Instalador idempotente (1 comando faz tudo).
.DESCRIPTION
  1) Analisa a capacidade da maquina (aborta se INCAPAZ)
  2) Instala o Ollama (silencioso)         - pula se ja existir
  3) Baixa o modelo (gemma4:12b)           - pula se ja existir
  4) Instala o Python 3.11                 - pula se ja existir
  5) Cria o ambiente + Open WebUI          - pula se ja existir
  6) Aplica a identidade Nous
  7) Cria pasta de dados + atalho + .exe oculto
  8) Verificacao final de saude

  Idempotente: rodar de novo nao quebra nada. Use -Force para reinstalar.
.PARAMETER Force
  Reinstala/atualiza componentes mesmo que ja existam.
.PARAMETER Model
  Modelo do Ollama (padrao gemma4:12b).
#>
param(
    [switch]$Force,
    [switch]$WithModel,                # baixar o modelo durante a instalacao (por padrao NAO)
    [switch]$WithImages,               # instalar tambem o motor de imagem (ComfyUI + Flux)
    [string]$Model = "gemma4:12b",
    [string]$AdminEmail,               # se a conta ja existir, registra o Pipe de imagem
    [string]$AdminPassword
)
$ErrorActionPreference = "Stop"

$REPO      = Split-Path $PSScriptRoot -Parent
$venv      = Join-Path $env:USERPROFILE "open-webui"
$dataDir   = Join-Path $env:USERPROFILE "NousData"
$ollamaExe = Join-Path $env:LOCALAPPDATA "Programs\Ollama\ollama.exe"
$ollamaApp = Join-Path $env:LOCALAPPDATA "Programs\Ollama\ollama app.exe"

function Step($n, $t) { Write-Host "`n[$n] $t" -ForegroundColor Cyan }
function Ok($t)       { Write-Host "    [ok] $t" -ForegroundColor Green }
function Info($t)     { Write-Host "    $t" -ForegroundColor DarkGray }

# --- Deteccao robusta: NAO rebaixar o que ja existe, mesmo instalado por
#     outro metodo/local (PATH, locais comuns, serviço no ar). ---
function Find-Ollama {
    $c = Get-Command ollama -ErrorAction SilentlyContinue
    if ($c) { return $c.Source }
    foreach ($p in @(
        (Join-Path $env:LOCALAPPDATA "Programs\Ollama\ollama.exe"),
        (Join-Path $env:ProgramFiles  "Ollama\ollama.exe"),
        (Join-Path ${env:ProgramFiles(x86)} "Ollama\ollama.exe"))) {
        if ($p -and (Test-Path $p)) { return $p }
    }
    return $null
}
function Test-OllamaUp {
    try { Invoke-RestMethod "http://127.0.0.1:11434/api/version" -TimeoutSec 3 | Out-Null; return $true }
    catch { return $false }
}
function Find-Py311 {
    # Open WebUI exige Python 3.11 (nao 3.12+). Procura qualquer 3.11 ja' presente.
    try {
        $v = & py -3.11 -c "import sys; sys.stdout.write(sys.executable)" 2>$null
        if ($LASTEXITCODE -eq 0 -and $v) { return $v.Trim() }
    } catch {}
    foreach ($p in @(
        (Join-Path $env:LOCALAPPDATA "Programs\Python\Python311\python.exe"),
        "C:\Python311\python.exe",
        (Join-Path $env:ProgramFiles "Python311\python.exe"))) {
        if (Test-Path $p) { return $p }
    }
    return $null
}

Write-Host "================ Instalador do Nous ================" -ForegroundColor Yellow

# 0) Porteiro de capacidade -------------------------------------------------
Step 0 "Analisando a capacidade da maquina"
& (Join-Path $REPO "tools\check-system.ps1")
switch ($LASTEXITCODE) {
    1 { Write-Host "`nMaquina INCAPAZ de rodar o Nous. Instalacao abortada." -ForegroundColor Red; exit 1 }
    2 { Info "Sem GPU adequada: vai funcionar na CPU (mais lento)." }
}

# 0.5) Pre-requisito: winget (App Installer) --------------------------------
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host "`nO 'winget' (App Installer) nao foi encontrado nesta maquina." -ForegroundColor Red
    Write-Host "Ele ja vem no Windows 10/11 atualizado. Instale o 'App Installer'" -ForegroundColor Yellow
    Write-Host "pela Microsoft Store e rode o instalador de novo:" -ForegroundColor Yellow
    Write-Host "  https://apps.microsoft.com/detail/9NBLGGH4NNS1" -ForegroundColor Cyan
    exit 1
}

# 1) Ollama -----------------------------------------------------------------
Step 1 "Ollama"
$instOllama = $false   # o Nous instalou? (para o desinstalador saber)
$ollamaExe = Find-Ollama
if (($ollamaExe -or (Test-OllamaUp)) -and -not $Force) {
    Ok "ja instalado - nao vou baixar de novo$(if ($ollamaExe) { " ($ollamaExe)" })"
} else {
    Info "instalando via winget (silencioso)..."
    winget install --id Ollama.Ollama -e --accept-package-agreements --accept-source-agreements --silent | Out-Null
    $ollamaExe = Find-Ollama
    $instOllama = $true
    Ok "instalado"
}
if (-not (Test-OllamaUp)) {
    if (Test-Path $ollamaApp)   { Start-Process $ollamaApp -WindowStyle Hidden }
    elseif ($ollamaExe)         { Start-Process $ollamaExe -ArgumentList "serve" -WindowStyle Hidden }
    Start-Sleep -Seconds 5
}
if (Test-OllamaUp) { Ok "servico no ar" } else { Info "servico nao respondeu ainda (confira o Ollama)" }

# 2) Modelo (baixado DENTRO do app, com progresso na tela) ------------------
Step 2 "Modelo"
$ollamaCmd = if ($ollamaExe) { $ollamaExe } else { "ollama" }
$instModel = $false
$hasModel = [bool]((& $ollamaCmd list 2>$null) -match [regex]::Escape($Model))
if ($WithModel) {
    if ($hasModel -and -not $Force) { Ok "$Model ja baixado" }
    else { Info "baixando $Model (pode levar varios minutos)..."; & $ollamaCmd pull $Model; $instModel = $true; Ok "baixado" }
}
elseif ($hasModel) { Ok "$Model ja presente" }
else {
    Info "pulado de proposito: o modelo e baixado DENTRO do Nous, com barra de"
    Info "progresso na tela (Admin > Settings > Models). Recomendado: $Model."
}

# 3) Python 3.11 ------------------------------------------------------------
Step 3 "Python 3.11"
$instPython = $false
$py311 = Find-Py311
if ($py311 -and -not $Force) { Ok "ja instalado - nao vou baixar de novo ($py311)" }
else {
    Info "instalando via winget..."
    winget install --id Python.Python.3.11 -e --accept-package-agreements --accept-source-agreements --silent | Out-Null
    $py311 = Find-Py311
    $instPython = $true
    if ($py311) { Ok "instalado" }
    else { Write-Host "    [erro] Python 3.11 nao encontrado apos a instalacao." -ForegroundColor Red; exit 1 }
}

# 4) Ambiente + Open WebUI --------------------------------------------------
Step 4 "Ambiente Python + Open WebUI"
$vpy = Join-Path $venv "Scripts\python.exe"
if (-not (Test-Path $vpy)) { Info "criando ambiente isolado..."; & $py311 -m venv $venv }
if ((Test-Path (Join-Path $venv "Scripts\open-webui.exe")) -and -not $Force) { Ok "Open WebUI ja instalado" }
else {
    Info "instalando o Open WebUI (varios minutos, baixa varios GB)..."
    & $vpy -m pip install --upgrade pip --quiet
    & $vpy -m pip install open-webui
    Ok "instalado"
}

# 5) Identidade Nous --------------------------------------------------------
Step 5 "Aplicando a identidade Nous"
& $vpy (Join-Path $REPO "branding\apply_branding.py")

# 6) Dados + atalho + launcher oculto --------------------------------------
Step 6 "Dados, atalho e launcher"
New-Item -ItemType Directory -Force -Path $dataDir | Out-Null
Ok "pasta de dados: $dataDir"
# (opcional) gera os .exe bonitos via ps2exe; se faltar o modulo, seguimos
# com o atalho via .vbs (funciona igual, sem janela de console).
$nousExe = Join-Path $REPO "launchers\Nous.exe"
try { & (Join-Path $REPO "launchers\build-exe.ps1") | Out-Null; Ok "launchers .exe gerados" }
catch { Info "sem ps2exe: vou usar o atalho via .vbs (abre igual, sem janela)" }

# Cria SEMPRE um atalho funcional na area de trabalho:
#  - se Nous.exe existe, aponta p/ ele;
#  - senao, aponta p/ wscript + nous-hidden.vbs (inicia o .ps1 escondido).
$desktop = [Environment]::GetFolderPath("Desktop")
$ico = Join-Path $REPO "branding\assets\nous.ico"
$ws  = New-Object -ComObject WScript.Shell
$lnk = $ws.CreateShortcut((Join-Path $desktop "Nous.lnk"))
if (Test-Path $nousExe) {
    $lnk.TargetPath = $nousExe
    $lnk.WorkingDirectory = (Split-Path $nousExe)
} else {
    $vbs = Join-Path $REPO "launchers\nous-hidden.vbs"
    $lnk.TargetPath = "wscript.exe"
    $lnk.Arguments  = "`"$vbs`""
    $lnk.WorkingDirectory = (Join-Path $REPO "launchers")
}
if (Test-Path $ico) { $lnk.IconLocation = "$ico,0" }
$lnk.Save()
Ok "atalho 'Nous' criado na area de trabalho"

# 6.5) Manifesto de instalacao ---------------------------------------------
# Registra o que o Nous REALMENTE instalou, para o desinstalador remover so'
# isso e nunca mexer num Ollama/Python que ja' existia antes.
$manifest = [ordered]@{
    installed_at   = (Get-Date).ToString("s")
    venv           = $venv
    ollama_by_nous = [bool]$instOllama
    python_by_nous = [bool]$instPython
    model          = $Model
    model_by_nous  = [bool]$instModel
}
[IO.File]::WriteAllText((Join-Path $dataDir "install-manifest.json"), ($manifest | ConvertTo-Json))
Ok "manifesto de instalacao salvo (ajuda o desinstalador)"

# 7) Verificacao ------------------------------------------------------------
Step 7 "Verificacao final de saude"
& (Join-Path $REPO "tools\health-check.ps1") -Model $Model

# 8) Motor de imagem (opcional) --------------------------------------------
# Nao-fatal: se a parte pesada/GPU-especifica falhar, o nucleo continua OK.
if ($WithImages) {
    Step 8 "Motor de imagem (ComfyUI + Flux) - opcional"
    try {
        & (Join-Path $REPO "images\install-comfyui.ps1")
        if ($AdminEmail -and $AdminPassword) {
            Info "registrando o Pipe 'Gerador de Imagem Local'..."
            & $vpy (Join-Path $REPO "images\register_pipe.py") --email $AdminEmail --password $AdminPassword
        } else {
            Info "Apos criar sua conta no Nous, ative a geracao de imagem no chat com:"
            Info "  `"$vpy`" images\register_pipe.py --email SEU@EMAIL --password SUASENHA"
        }
    } catch {
        Info "[aviso] motor de imagem falhou (segue sem ele): $($_.Exception.Message)"
    }
}

Write-Host "`n==========================================================" -ForegroundColor Green
Write-Host " Nous pronto!" -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green
Write-Host ""
Write-Host " 1. Abra pelo atalho 'Nous' na area de trabalho." -ForegroundColor White
Write-Host "    (ou clique duplo em iniciar.bat se o atalho nao aparecer)" -ForegroundColor DarkGray
Write-Host ""
Write-Host " 2. Crie sua conta - a primeira conta e' a administradora." -ForegroundColor White
Write-Host "    Nao precisa de email real; use qualquer nome e senha." -ForegroundColor DarkGray
Write-Host ""
if ($WithModel) {
    Write-Host " 3. O modelo $Model ja foi baixado. Ele aparece no seletor" -ForegroundColor White
    Write-Host "    de modelos no topo da tela. Clique nele e comece a conversar." -ForegroundColor DarkGray
} else {
    Write-Host " 3. Dentro do Nous: clique em Admin Panel > Settings > Models," -ForegroundColor White
    Write-Host "    digite '$Model' e clique em Download." -ForegroundColor DarkGray
}
Write-Host ""
Write-Host " Dica: chat, visao (envie prints), busca na web e memoria pessoal" -ForegroundColor DarkGray
Write-Host "       ja vem ativos - sem configurar nada." -ForegroundColor DarkGray
if (-not $WithImages) {
    Write-Host ""
    Write-Host " Para gerar imagens localmente depois: install-nous.ps1 -WithImages" -ForegroundColor DarkGray
}
