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
echo   - o modelo de IA recomendado para sua maquina
echo.
echo Pode levar varios minutos e baixar alguns GB.
echo Se aparecer um aviso do Windows, escolha "Sim".
echo.
pause

REM Com argumentos (uso avancado) = repassa direto sem analise.
if not "%~1"=="" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0installer\install-nous.ps1" %*
    goto fim
)

REM ---- Detecta o hardware e escolhe o modelo certo ----
echo.
echo Analisando sua maquina para escolher o modelo ideal...
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\check-system.ps1"
set CHECK_EXIT=%errorlevel%

REM EXIT 1 = INCAPAZ (pouca RAM ou disco)
if %CHECK_EXIT%==1 (
    echo.
    echo ATENCAO: sua maquina nao atende os requisitos minimos.
    echo Veja os detalhes acima. Instalacao cancelada.
    echo.
    pause
    exit /b 1
)

REM EXIT 0 = GPU capaz -> gemma4:12b (modelo padrao, bom para todos os dias)
REM EXIT 2 = so CPU   -> gemma4:e4b  (modelo leve, mais rapido sem GPU)
if %CHECK_EXIT%==0 (
    set "NOUS_MODEL=gemma4:12b"
) else (
    set "NOUS_MODEL=gemma4:e4b"
)

echo.
echo Modelo selecionado automaticamente: %NOUS_MODEL%
echo (voce pode trocar por outro depois, dentro do Nous)
echo.
pause

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0installer\install-nous.ps1" -WithModel -Model "%NOUS_MODEL%"

:fim
echo.
echo ============================================
echo  Terminou. Abra o Nous pelo atalho "Nous"
echo  criado na area de trabalho.
echo ============================================
echo.
pause
