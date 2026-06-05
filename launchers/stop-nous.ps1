<#
  Nous WebUI - Parar o servidor (libera a porta e a memoria).
#>
$ErrorActionPreference = "SilentlyContinue"
$port = 8080
$conn = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue
if ($conn) {
    $conn.OwningProcess | Select-Object -Unique | ForEach-Object {
        Stop-Process -Id $_ -Force -ErrorAction SilentlyContinue
    }
    Write-Host "Nous encerrado." -ForegroundColor Green
} else {
    Write-Host "O Nous nao estava em execucao." -ForegroundColor Yellow
}
