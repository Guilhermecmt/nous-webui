@echo off
REM ============================================================
REM  Nous - Instalador (clique duplo). Funciona de qualquer pasta.
REM ============================================================
title Instalador do Nous
cd /d "%~dp0"

echo ============================================
echo             Instalador do Nous
echo ============================================
echo.
echo Isto instala tudo que o Nous precisa:
echo   - Ollama (motor dos modelos de IA)
echo   - Python + Open WebUI (a interface)
echo   - a identidade Nous (tema, logo, memoria)
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

REM ---- Analisa o hardware ----
echo.
echo Analisando sua maquina...
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

echo.
echo ============================================
echo  Qual modelo voce quer instalar?
echo ============================================
echo.
echo  Veja as recomendacoes acima de acordo com sua maquina.
echo  Voce pode usar QUALQUER modelo disponivel no Ollama
echo  (https://ollama.com/library) - nao so' os listados acima.
echo.
echo  Exemplos populares:
echo    gemma4:12b   llama3.2    mistral    phi4    deepseek-r1
echo.
set /p NOUS_MODEL="Digite o nome do modelo (ou pressione ENTER para gemma4:12b): "
if "%NOUS_MODEL%"=="" set "NOUS_MODEL=gemma4:12b"

echo.
echo Modelo escolhido: %NOUS_MODEL%
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
