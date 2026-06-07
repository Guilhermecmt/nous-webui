@echo off
REM ============================================================
REM  Nous - Desinstalador (clique duplo, com menu).
REM  Avancado: tambem aceita argumentos, ex.:  desinstalar.bat -All
REM ============================================================
title Desinstalador do Nous
cd /d "%~dp0"

REM Se vier argumento (uso avancado), repassa direto e sai.
if not "%~1"=="" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0installer\uninstall-nous.ps1" %*
    echo.
    pause
    goto :eof
)

:menu
cls
echo ============================================
echo            Desinstalador do Nous
echo ============================================
echo.
echo  [1] Remocao segura (recomendado)
echo      Remove so' o app Nous. PRESERVA seus dados,
echo      suas notas, o Ollama e o Python.
echo.
echo  [2] Remover TUDO
echo      Tambem APAGA seus dados (conversas, memoria) e
echo      desinstala Ollama e Python (se o Nous instalou).
echo.
echo  [3] Cancelar
echo.
choice /C 123 /N /M "Escolha uma opcao (1, 2 ou 3): "
if errorlevel 3 goto cancel
if errorlevel 2 goto all
if errorlevel 1 goto safe

:all
echo.
echo ATENCAO: isto vai APAGAR suas conversas e memoria.
choice /C SN /N /M "Tem certeza? (S = sim, N = voltar): "
if errorlevel 2 goto menu
set "ARGS=-All"
goto run

:safe
set "ARGS="
goto run

:run
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0installer\uninstall-nous.ps1" %ARGS%
echo.
pause
goto :eof

:cancel
echo.
echo Cancelado. Nada foi removido.
pause
goto :eof
