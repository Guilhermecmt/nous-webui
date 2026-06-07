@echo off
REM ============================================================
REM  Nous - Desinstalador (clique duplo). Por padrao remove so'
REM  o app Nous e preserva seus dados, o Ollama e o Python.
REM  Para remover TUDO: rode  desinstalar.bat -All
REM ============================================================
title Desinstalador do Nous
cd /d "%~dp0"

echo ============================================
echo            Desinstalador do Nous
echo ============================================
echo.
echo Por padrao remove SO' o app Nous (ambiente isolado,
echo atalho e launchers) e PRESERVA:
echo   - seus dados (conversas, memoria) em NousData
echo   - Ollama e Python (podem ser usados por outros apps)
echo   - suas notas em Documentos\Nous
echo.
echo Para remover TUDO (inclusive dados, Ollama e Python),
echo feche esta janela e rode novamente assim:
echo   desinstalar.bat -All
echo.
pause

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0installer\uninstall-nous.ps1" %*

echo.
pause
