<#
.SYNOPSIS
  Nous WebUI - Verificacao inteligente pos-instalacao.
.DESCRIPTION
  Confere se a instalacao esta integra: Ollama instalado e no ar, modelo
  presente, ambiente Open WebUI, identidade Nous aplicada e (se rodando)
  o servidor respondendo. Retorna 0 se tudo certo, 1 se houver falhas.
#>
param([string]$Model = "gemma4:12b")
$ErrorActionPreference = "SilentlyContinue"

$venv    = Join-Path $env:USERPROFILE "open-webui"
$owDir   = Join-Path $venv "Lib\site-packages\open_webui"
$dataDir = if ($env:DATA_DIR) { $env:DATA_DIR } else { Join-Path $env:USERPROFILE "NousData" }
$script:fail = 0

# Mesma logica de Find-Ollama do instalador: PATH > locais comuns.
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
$ollamaExe = Find-Ollama

function Check($name, $ok, $detail) {
    if ($ok) { Write-Host ("  [OK]    {0}" -f $name) -ForegroundColor Green }
    else     { Write-Host ("  [FALHA] {0} -> {1}" -f $name, $detail) -ForegroundColor Red; $script:fail++ }
}
function Note($name, $msg) { Write-Host ("  [i]     {0} -> {1}" -f $name, $msg) -ForegroundColor DarkGray }

Write-Host "=== Nous - Verificacao de Saude ===`n" -ForegroundColor Cyan

Check "Ollama instalado" ($ollamaExe -ne $null) "ollama nao encontrado (PATH nem locais comuns)"

$apiUp = $false
try { Invoke-RestMethod "http://127.0.0.1:11434/api/version" -TimeoutSec 3 | Out-Null; $apiUp = $true } catch {}
Check "Servico Ollama no ar" $apiUp "API 11434 nao responde"

$hasModel = $false
if (Test-Path $ollamaExe) { $hasModel = [bool]((& $ollamaExe list 2>$null) -match [regex]::Escape($Model)) }
if ($hasModel) { Check "Modelo $Model presente" $true "" }
else { Note "Modelo" "nenhum baixado ainda - baixe dentro do Nous (Settings > Models)" }

Check "Open WebUI instalado" (Test-Path (Join-Path $venv "Scripts\open-webui.exe")) "ambiente/open-webui ausente"
Check "Identidade Nous aplicada" (Test-Path (Join-Path $owDir "static\custom.css")) "rode branding\apply_branding.py"

if (Test-Path (Join-Path $dataDir "webui.db")) {
    Check "Dados em local seguro (DATA_DIR)" $true ""
} else {
    Note "Dados (DATA_DIR)" "webui.db sera criado no primeiro uso ($dataDir)"
}

$srv = $false
try { $srv = (Invoke-WebRequest "http://localhost:8080/health" -TimeoutSec 3 -UseBasicParsing).StatusCode -eq 200 } catch {}
if ($srv) { Write-Host "  [OK]    Servidor Nous respondendo (8080)" -ForegroundColor Green }
else      { Note "Servidor Nous" "parado (normal se voce ainda nao iniciou)" }

Write-Host ""
if ($script:fail -eq 0) { Write-Host "TUDO CERTO - instalacao integra." -ForegroundColor Green; exit 0 }
else { Write-Host "$($script:fail) problema(s) encontrado(s)." -ForegroundColor Red; exit 1 }
