<#
  Nous WebUI - Compila os launchers para .exe SEM console (sem janela feia).
  Requer o modulo ps2exe:  Install-Module ps2exe -Scope CurrentUser
  Gera:  Nous.exe (iniciar)  e  "Parar Nous.exe" (parar)
#>
$ErrorActionPreference = "Stop"
$here   = $PSScriptRoot
$assets = Join-Path (Split-Path $here -Parent) "branding\assets"
$ico    = Join-Path $assets "nous.ico"
$master = Join-Path $assets "nous_logo.png"
$vpy    = Join-Path $env:USERPROFILE "open-webui\Scripts\python.exe"

# Gera o icone (.ico) a partir da logo-mestre, se possivel
if ((Test-Path $vpy) -and (Test-Path $master)) {
    & $vpy -c "from PIL import Image; Image.open(r'$master').save(r'$ico', sizes=[(256,256),(128,128),(64,64),(48,48),(32,32),(16,16)])"
}

# Garante o ps2exe (melhor esforco). Se nao der, lanca erro e o instalador
# cai no fallback de atalho via .vbs (que funciona sem este modulo).
if (-not (Get-Module -ListAvailable -Name ps2exe)) {
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser -ErrorAction SilentlyContinue | Out-Null
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted -ErrorAction SilentlyContinue
    Install-Module ps2exe -Scope CurrentUser -Force -ErrorAction Stop
}
Import-Module ps2exe
$icoArg = @{}
if (Test-Path $ico) { $icoArg = @{ iconFile = $ico } }

Invoke-ps2exe -inputFile "$here\start-nous.ps1" -outputFile "$here\Nous.exe" `
    -noConsole -title "Nous" -description "Nous - IA local" -product "Nous" -company "Nous" -noConfigFile @icoArg
Invoke-ps2exe -inputFile "$here\stop-nous.ps1" -outputFile "$here\Parar Nous.exe" `
    -noConsole -title "Parar Nous" -description "Encerra o Nous" -product "Nous" -company "Nous" -noConfigFile @icoArg

Write-Host "Gerados: Nous.exe e 'Parar Nous.exe' em $here" -ForegroundColor Green
