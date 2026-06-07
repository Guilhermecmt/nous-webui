@echo off
REM ============================================================
REM  Nous - Iniciar (clique duplo). Abre o Nous sem janela de
REM  terminal. Use isto se o atalho da area de trabalho nao
REM  tiver sido criado. Funciona de qualquer pasta.
REM ============================================================
cd /d "%~dp0"
start "" wscript.exe "%~dp0launchers\nous-hidden.vbs"
