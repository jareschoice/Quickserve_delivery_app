@echo off
title QuickServe Local Test Runner
echo ===================================================
echo     🚀 QuickServe Local Server - Auto Starter
echo ===================================================

:: Detect local IP address
for /f "tokens=2 delims=:" %%A in ('ipconfig ^| findstr /R /C:"IPv4 Address"') do (
    set IP=%%A
)
set IP=%IP: =%

echo.
echo 🌍 Detected Local IP: http://%IP%:5555
echo ---------------------------------------------------
echo Make sure your phone is connected to this same Wi-Fi
echo Then open the above link in your phone browser
echo ---------------------------------------------------

:: Check port 5555 availability
netstat -ano | find "5555" >nul
if %errorlevel%==0 (
    echo ✅ Port 5555 is already in use (Server may be running)
) else (
    echo ⚙ Starting backend server on port 5555...
    echo.
    npm run dev
)

echo.
echo ✅ Ready! Visit http://%IP%:5555 from your phone
pausenode