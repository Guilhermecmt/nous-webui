<#
.SYNOPSIS
  Nous WebUI - Analise de capacidade da maquina.
.DESCRIPTION
  Verifica se a maquina tem capacidade para rodar o Nous (Gemma 4 12B via Ollama):
  RAM, VRAM (real, via registro), espaco em disco e SO. Retorna um veredito e
  um codigo de saida:
     0 = CAPAZ (GPU)      apta, com aceleracao de GPU
     2 = CAPAZ (CPU)      roda, porem so na CPU (mais lento)
     1 = INCAPAZ          nao atende aos requisitos minimos
.NOTES
  Requisitos do modelo gemma4:12b (Q4 ~ 8 GB):
     RAM   minimo 16 GB   | recomendado 32 GB
     VRAM  >= 8 GB para aceleracao por GPU (ideal 12 GB+)
     Disco >= 20 GB livres
#>

$ErrorActionPreference = "SilentlyContinue"
$MIN_RAM_GB  = 16
$MIN_DISK_GB = 20
$GPU_VRAM_GB = 8

function Get-RealVramGB {
    # AdapterRAM (WMI) estoura em 4 GB; o valor real esta no registro (qwMemorySize)
    $best = 0
    $base = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}"
    Get-ChildItem $base -ErrorAction SilentlyContinue | ForEach-Object {
        $q = (Get-ItemProperty $_.PSPath -Name "HardwareInformation.qwMemorySize" -ErrorAction SilentlyContinue)."HardwareInformation.qwMemorySize"
        if ($q -and $q -gt $best) { $best = $q }
    }
    if ($best -gt 0) { return [math]::Round($best / 1GB, 1) }
    # fallback WMI (impreciso)
    $a = (Get-CimInstance Win32_VideoController | Sort-Object AdapterRAM -Descending | Select-Object -First 1).AdapterRAM
    if ($a) { return [math]::Round($a / 1GB, 1) }
    return 0
}

Write-Host "=== Nous WebUI - Analise de Capacidade ===`n" -ForegroundColor Cyan

$os   = (Get-CimInstance Win32_OperatingSystem).Caption
$ramGB = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 1)
$gpu  = (Get-CimInstance Win32_VideoController | Sort-Object AdapterRAM -Descending | Select-Object -First 1).Name
$vramGB = Get-RealVramGB
$sys  = $env:SystemDrive
$freeGB = [math]::Round((Get-PSDrive ($sys.TrimEnd(':'))).Free / 1GB, 1)

Write-Host ("SO       : {0}" -f $os)
Write-Host ("RAM      : {0} GB   (min {1})" -f $ramGB, $MIN_RAM_GB)
Write-Host ("GPU      : {0}" -f $gpu)
Write-Host ("VRAM     : {0} GB   (>= {1} para GPU)" -f $vramGB, $GPU_VRAM_GB)
Write-Host ("Disco {0} : {1} GB livres   (min {2})" -f $sys, $freeGB, $MIN_DISK_GB)
Write-Host ""

$problemas = @()
if ($ramGB  -lt $MIN_RAM_GB)  { $problemas += "RAM insuficiente ($ramGB GB < $MIN_RAM_GB GB)" }
if ($freeGB -lt $MIN_DISK_GB) { $problemas += "Disco insuficiente ($freeGB GB < $MIN_DISK_GB GB)" }

if ($problemas.Count -gt 0) {
    Write-Host "VEREDITO: INCAPAZ" -ForegroundColor Red
    $problemas | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    exit 1
}
elseif ($vramGB -ge $GPU_VRAM_GB) {
    Write-Host "VEREDITO: CAPAZ (GPU) - apta com aceleracao de GPU" -ForegroundColor Green
    exit 0
}
else {
    Write-Host "VEREDITO: CAPAZ (CPU) - roda, porem sem GPU sera mais lento" -ForegroundColor Yellow
    exit 2
}
