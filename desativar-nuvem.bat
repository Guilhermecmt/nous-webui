@echo off
REM ============================================================
REM  Nous - Desativar Nuvem NVIDIA (clique duplo).
REM  Remove os modelos de nuvem e a conexao com a NVIDIA.
REM ============================================================
cd /d "%~dp0"
powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File "%~dp0cloud\desativar-nuvem.ps1"
