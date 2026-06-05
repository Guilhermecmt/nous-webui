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
    [string]$Model = "gemma4:12b"
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

Write-Host "================ Instalador do Nous ================" -ForegroundColor Yellow

# 0) Porteiro de capacidade -------------------------------------------------
Step 0 "Analisando a capacidade da maquina"
& (Join-Path $REPO "tools\check-system.ps1")
switch ($LASTEXITCODE) {
    1 { Write-Host "`nMaquina INCAPAZ de rodar o Nous. Instalacao abortada." -ForegroundColor Red; exit 1 }
    2 { Info "Sem GPU adequada: vai funcionar na CPU (mais lento)." }
}

# 1) Ollama -----------------------------------------------------------------
Step 1 "Ollama"
if ((Test-Path $ollamaExe) -and -not $Force) { Ok "ja instalado" }
else {
    Info "instalando via winget (silencioso)..."
    winget install --id Ollama.Ollama -e --accept-package-agreements --accept-source-agreements --silent | Out-Null
    Ok "instalado"
}
try { Invoke-RestMethod "http://127.0.0.1:11434/api/version" -TimeoutSec 3 | Out-Null; Ok "servico no ar" }
catch {
    if (Test-Path $ollamaApp) { Start-Process $ollamaApp -WindowStyle Hidden }
    Start-Sleep -Seconds 5; Ok "servico iniciado"
}

# 2) Modelo (baixado DENTRO do app, com progresso na tela) ------------------
Step 2 "Modelo"
$hasModel = [bool]((& $ollamaExe list 2>$null) -match [regex]::Escape($Model))
if ($WithModel) {
    if ($hasModel -and -not $Force) { Ok "$Model ja baixado" }
    else { Info "baixando $Model (pode levar varios minutos)..."; & $ollamaExe pull $Model; Ok "baixado" }
}
elseif ($hasModel) { Ok "$Model ja presente" }
else {
    Info "pulado de proposito: o modelo e baixado DENTRO do Nous, com barra de"
    Info "progresso na tela (Admin > Settings > Models). Recomendado: $Model."
}

# 3) Python 3.11 ------------------------------------------------------------
Step 3 "Python 3.11"
$py311 = Join-Path $env:LOCALAPPDATA "Programs\Python\Python311\python.exe"
if (Test-Path $py311) { Ok "ja instalado" }
else {
    Info "instalando via winget..."
    winget install --id Python.Python.3.11 -e --accept-package-agreements --accept-source-agreements --silent | Out-Null
    Ok "instalado"
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
try { & (Join-Path $REPO "launchers\build-exe.ps1") | Out-Null; Ok "launchers .exe gerados" }
catch { Info "build do .exe pulado (instale o modulo ps2exe para gerar)" }

$nousExe = Join-Path $REPO "launchers\Nous.exe"
if (Test-Path $nousExe) {
    $desktop = [Environment]::GetFolderPath("Desktop")
    $ws  = New-Object -ComObject WScript.Shell
    $lnk = $ws.CreateShortcut((Join-Path $desktop "Nous.lnk"))
    $lnk.TargetPath = $nousExe
    $lnk.WorkingDirectory = (Split-Path $nousExe)
    $ico = Join-Path $REPO "branding\assets\nous.ico"
    if (Test-Path $ico) { $lnk.IconLocation = "$ico,0" }
    $lnk.Save()
    Ok "atalho 'Nous' criado na area de trabalho"
}

# 7) Verificacao ------------------------------------------------------------
Step 7 "Verificacao final de saude"
& (Join-Path $REPO "tools\health-check.ps1") -Model $Model

Write-Host "`n=========== Nous pronto! Abra pelo atalho 'Nous'. ===========" -ForegroundColor Green
