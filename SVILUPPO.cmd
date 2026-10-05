@echo off
rem Anteprima di sviluppo (debug) su http://localhost:8802, con riavvio automatico a ogni modifica.
cd /d "%~dp0"
python -u tool\sviluppo.py
