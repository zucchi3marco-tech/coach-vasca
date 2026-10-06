@echo off
rem Ricompila la versione web dopo una modifica al codice; poi ricarica la pagina 127.0.0.1:8801.
cd /d "%~dp0"
call C:\Users\emanu\flutter\bin\flutter.bat build web --release --no-wasm-dry-run --no-web-resources-cdn
pause
