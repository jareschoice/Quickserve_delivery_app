@echo off
cd /d "%~dp0backend"
echo.
echo ╔════════════════════════════════════════════════════════════════╗
echo ║         Starting QuickServe Backend Server on Port 5555        ║
echo ╚════════════════════════════════════════════════════════════════╝
echo.
node server.js
pause
