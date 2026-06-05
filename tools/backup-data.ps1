<#
.SYNOPSIS
  Nous WebUI - Backup inteligente dos dados (conversas, conta, configuracoes).
.DESCRIPTION
  Compacta o DATA_DIR (padrao: %USERPROFILE%\NousData) em um .zip com carimbo
  de data/hora dentro de  bkp/ , e mantem apenas os N backups mais recentes.
  Use o Agendador de Tarefas do Windows para rodar diariamente, se quiser.
.PARAMETER DataDir
  Pasta de dados do Nous. Padrao: $env:NOUS_DATA_DIR ou %USERPROFILE%\NousData
.PARAMETER Keep
  Quantos backups manter (padrao 10).
#>
param(
    [string]$DataDir = $(if ($env:NOUS_DATA_DIR) { $env:NOUS_DATA_DIR } else { Join-Path $env:USERPROFILE "NousData" }),
    [int]$Keep = 10
)

$ErrorActionPreference = "Stop"
$bkpDir = Join-Path (Split-Path $PSScriptRoot -Parent) "bkp"
New-Item -ItemType Directory -Force -Path $bkpDir | Out-Null

if (-not (Test-Path $DataDir)) {
    Write-Host "Pasta de dados nao encontrada: $DataDir" -ForegroundColor Red
    exit 1
}

$stamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$zip = Join-Path $bkpDir "nous-data_$stamp.zip"

Write-Host "Compactando $DataDir ..." -ForegroundColor Cyan
Compress-Archive -Path (Join-Path $DataDir "*") -DestinationPath $zip -CompressionLevel Optimal -Force
$sizeMB = [math]::Round((Get-Item $zip).Length / 1MB, 1)
Write-Host "Backup criado: $zip ($sizeMB MB)" -ForegroundColor Green

# Mantem apenas os N mais recentes (poda inteligente)
$todos = Get-ChildItem $bkpDir -Filter "nous-data_*.zip" | Sort-Object LastWriteTime -Descending
if ($todos.Count -gt $Keep) {
    $todos | Select-Object -Skip $Keep | ForEach-Object {
        Remove-Item $_.FullName -Force
        Write-Host "  removido backup antigo: $($_.Name)" -ForegroundColor DarkGray
    }
}
Write-Host "Backups mantidos: $([math]::Min($todos.Count, $Keep))"
