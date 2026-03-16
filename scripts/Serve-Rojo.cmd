
@echo off
powershell -ExecutionPolicy Bypass -File "%~dp0Serve-Rojo.ps1"
rokit add rojo-rbx/rojo
rokit install
rojo plugin install

