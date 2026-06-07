<#
  Nous - Inicia o "Nous Monitor" (painel de VRAM + modelos) em segundo plano.
  Roda no venv do Open WebUI (ja tem aiohttp). Porta 127.0.0.1:8990.
#>
$ErrorActionPreference = "SilentlyContinue"

$py     = Join-Path $env:USERPROFILE "open-webui\Scripts\python.exe"
$script = Join-Path $PSScriptRoot "nous_monitor.py"

if (-not (Test-Path $py))     { Write-Host "Python do Open WebUI nao encontrado." -ForegroundColor Red; return }
if (-not (Test-Path $script)) { Write-Host "nous_monitor.py nao encontrado."      -ForegroundColor Red; return }

# Ja esta no ar?
try { Invoke-RestMethod "http://127.0.0.1:8990/health" -TimeoutSec 2 | Out-Null
      Write-Host "Nous Monitor ja esta rodando: http://127.0.0.1:8990"; return } catch {}

Start-Process -FilePath $py -ArgumentList "`"$script`"" -WindowStyle Hidden
Write-Host "Nous Monitor iniciando (segundo plano) em http://127.0.0.1:8990 ..."
