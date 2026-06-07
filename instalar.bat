@echo off
REM ============================================================
REM  Nous - Instalador (clique duplo). Funciona de qualquer pasta:
REM  resolve o proprio caminho e roda o instalador do PowerShell
REM  com a politica liberada so' para esta execucao.
REM ============================================================
title Instalador do Nous
cd /d "%~dp0"

echo ============================================
echo             Instalador do Nous
echo ============================================
echo.
echo Isto instala tudo que o Nous precisa:
echo   - Ollama (motor do modelo)
echo   - Python + Open WebUI (a interface)
echo   - a identidade Nous (tema, logo, memoria)
echo.
echo Pode levar varios minutos e baixar alguns GB.
echo Se aparecer um aviso do Windows, escolha "Sim".
echo.
pause

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0installer\install-nous.ps1" %*

echo.
echo ============================================
echo  Terminou. Abra o Nous pelo atalho "Nous"
echo  criado na area de trabalho.
echo ============================================
echo.
pause
