@echo off
REM ============================================================
REM  Nous - Ativar Nuvem NVIDIA (clique duplo).
REM  Solicita sua chave NVIDIA NIM e ativa os modelos de nuvem.
REM ============================================================
cd /d "%~dp0"
powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File "%~dp0cloud\ativar-nuvem.ps1"
