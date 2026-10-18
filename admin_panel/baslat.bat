@echo off
title Ozel Adimlar - Yonetim Paneli
echo ===================================================
echo   OZEL ADIMLAR - YONETIM VE OGRETMEN PORTALI
echo ===================================================
echo Panel tarayicida aciliyor...

cd /d "C:\ozel_app\admin_panel"

:: Tarayiciyi ekrana getir
start explorer.exe "http://localhost:8085"

:: Eger sunucu calismiyorsa baslat
netstat -ano | findstr ":8085" | findstr "LISTENING" >nul
if %errorlevel% neq 0 (
    echo Sunucu baslatiliyor...
    python server.py
) else (
    echo Sunucu zaten arka planda aktif ve canli!
    timeout /t 3 >nul
)
