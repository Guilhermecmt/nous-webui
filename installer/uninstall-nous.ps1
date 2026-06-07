<#
.SYNOPSIS
  Nous - Desinstalador. Remove o que o instalador colocou, com seguranca.
.DESCRIPTION
  Por padrao remove SO' o app Nous isolado (o ambiente em %USERPROFILE%\open-webui,
  o atalho e os launchers) e para os processos. PRESERVA:
    - seus dados (NousData: conversas, conta, memoria, indice de arquivos)
    - Ollama e Python (ferramentas que podem ser usadas por outros programas)
    - suas notas em Documentos\Nous

  Para remover mais, use as flags. O desinstalador le o manifesto gravado pelo
  instalador (NousData\install-manifest.json) e so' remove Ollama/Python se o
  proprio Nous os tiver instalado.
.PARAMETER RemoveData
  Apaga a pasta NousData (conversas, conta, memoria, indice de arquivos).
.PARAMETER RemoveOllama
  Desinstala o Ollama - apenas se o manifesto indicar que o Nous o instalou.
.PARAMETER RemovePython
  Desinstala o Python 3.11 - mesma regra do Ollama.
.PARAMETER All
  Equivale a -RemoveData -RemoveOllama -RemovePython.
.PARAMETER Force
  Remove Ollama/Python mesmo sem manifesto que confirme (cuidado: podem ter
  existido antes do Nous).
#>
param(
    [switch]$RemoveData,
    [switch]$RemoveOllama,
    [switch]$RemovePython,
    [switch]$All,
    [switch]$Force
)
$ErrorActionPreference = "SilentlyContinue"
if ($All) { $RemoveData = $true; $RemoveOllama = $true; $RemovePython = $true }

$venv    = Join-Path $env:USERPROFILE "open-webui"
$dataDir = Join-Path $env:USERPROFILE "NousData"
$REPO    = Split-Path $PSScriptRoot -Parent

function Ok($t)   { Write-Host "    [ok] $t" -ForegroundColor Green }
function Info($t) { Write-Host "    $t" -ForegroundColor DarkGray }
function Warn($t) { Write-Host "    [!] $t" -ForegroundColor Yellow }

Write-Host "================ Desinstalador do Nous ================" -ForegroundColor Yellow

# manifesto: o que o Nous realmente instalou
$man = $null
$manPath = Join-Path $dataDir "install-manifest.json"
if (Test-Path $manPath) { try { $man = Get-Content $manPath -Raw | ConvertFrom-Json } catch {} }

# 1) parar processos (servidor 8080, monitor 8990, indexador 8991) ----------
Write-Host "`n[1] Parando o Nous" -ForegroundColor Cyan
foreach ($p in 8080, 8990, 8991) {
    $c = Get-NetTCPConnection -LocalPort $p -State Listen -ErrorAction SilentlyContinue
    if ($c) {
        $c.OwningProcess | Select-Object -Unique | ForEach-Object { Stop-Process -Id $_ -Force -ErrorAction SilentlyContinue }
    }
}
Ok "processos encerrados"

# 2) remover o app isolado (sempre - e' 100% do Nous) -----------------------
Write-Host "`n[2] Removendo o app Nous (ambiente isolado)" -ForegroundColor Cyan
if (Test-Path $venv) { Remove-Item $venv -Recurse -Force; Ok "ambiente removido: $venv" }
else { Info "ambiente nao encontrado (ja' removido?)" }
$desktop = [Environment]::GetFolderPath("Desktop")
foreach ($lnk in "Nous.lnk", "Parar Nous.lnk") {
    $lp = Join-Path $desktop $lnk
    if (Test-Path $lp) { Remove-Item $lp -Force; Ok "atalho removido: $lnk" }
}
foreach ($exe in "Nous.exe", "Parar Nous.exe") {
    $ep = Join-Path $REPO "launchers\$exe"
    if (Test-Path $ep) { Remove-Item $ep -Force; Ok "launcher removido: $exe" }
}

# 3) dados pessoais (opcional) ----------------------------------------------
Write-Host "`n[3] Dados pessoais (NousData)" -ForegroundColor Cyan
if ($RemoveData) {
    if (Test-Path $dataDir) { Remove-Item $dataDir -Recurse -Force; Ok "NousData removido (conversas, memoria, indice)" }
    else { Info "NousData nao encontrado" }
} else {
    Info "PRESERVADO: $dataDir"
    Info "(conversas, conta, memoria e indice - use -RemoveData para apagar)"
}

# 4) Ollama (opcional) ------------------------------------------------------
Write-Host "`n[4] Ollama" -ForegroundColor Cyan
if ($RemoveOllama) {
    $byNous = if ($man) { [bool]$man.ollama_by_nous } else { $null }
    if ($byNous -eq $false -and -not $Force) {
        Warn "o manifesto diz que o Ollama ja' existia antes do Nous - NAO vou remover (use -Force)."
    } elseif ($byNous -eq $true -or $Force) {
        winget uninstall --id Ollama.Ollama -e --silent | Out-Null
        Ok "Ollama desinstalado"
        Info "modelos baixados continuam em $env:USERPROFILE\.ollama (apague a mao se quiser)"
    } else {
        Warn "sem manifesto p/ confirmar que o Nous instalou o Ollama - use -Force se tiver certeza."
    }
} else { Info "PRESERVADO (pode ser usado por outros apps - use -RemoveOllama)" }

# 5) Python 3.11 (opcional) -------------------------------------------------
Write-Host "`n[5] Python 3.11" -ForegroundColor Cyan
if ($RemovePython) {
    $byNous = if ($man) { [bool]$man.python_by_nous } else { $null }
    if ($byNous -eq $false -and -not $Force) {
        Warn "o manifesto diz que o Python ja' existia antes do Nous - NAO vou remover (use -Force)."
    } elseif ($byNous -eq $true -or $Force) {
        winget uninstall --id Python.Python.3.11 -e --silent | Out-Null
        Ok "Python 3.11 desinstalado"
    } else {
        Warn "sem manifesto p/ confirmar - use -Force se tiver certeza."
    }
} else { Info "PRESERVADO (pode ser usado por outros apps - use -RemovePython)" }

Write-Host "`n=========== Nous removido. ===========" -ForegroundColor Green
Info "Suas notas em Documentos\Nous NAO foram tocadas."
Info "Para apagar tudo de uma vez: uninstall-nous.ps1 -All"
Info "Por fim, apague a pasta do repositorio se nao for usar mais."
