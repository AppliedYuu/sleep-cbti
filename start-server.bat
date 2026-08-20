@echo off
chcp 65001 >nul 2>&1
title Sleep Well - One-click Start
echo ============================================
echo   Sleep Well (sleep-cbti) One-click Start
echo ============================================
echo.

rem PROJECT dir = this script's directory (works with any path/encoding)
set "PROJECT=%~dp0"
set "MYSQL_BIN=C:\xampp\mysql\bin"

rem ---------- check ports to avoid duplicate start ----------
set "BACKEND_RUNNING=0"
set "MYSQL_RUNNING=0"

netstat -ano | findstr ":3000 " | findstr "LISTENING" >nul 2>&1
if %errorlevel%==0 set "BACKEND_RUNNING=1"

netstat -ano | findstr ":3306 " | findstr "LISTENING" >nul 2>&1
if %errorlevel%==0 set "MYSQL_RUNNING=1"

if "%BACKEND_RUNNING%"=="1" echo [skip] backend already running (port 3000)
if "%MYSQL_RUNNING%"=="1"  echo [skip] mysql already running (port 3306)
echo.

rem ---------- start MySQL if not running ----------
if "%MYSQL_RUNNING%"=="0" (
    echo [1/2] starting MySQL ...
    start "MySQL" /min "%MYSQL_BIN%\mysqld.exe" --defaults-file="%MYSQL_BIN%\my.ini"

    echo       waiting for MySQL (max 25s) ...
    set /a TRIES=0
:wait_mysql
    set /a TRIES+=1
    if %TRIES% gtr 50 goto mysql_timeout
    netstat -ano | findstr ":3306 " | findstr "LISTENING" >nul 2>&1
    if errorlevel 1 (
        timeout /t 1 /nobreak >nul
        goto wait_mysql
    )
    echo [OK] MySQL ready (port 3306)
    goto mysql_ready
:mysql_timeout
    echo [WARN] MySQL start timeout. Please start it manually.
:mysql_ready
) else (
    echo [OK] MySQL already running
)

rem ---------- start backend if not running ----------
if "%BACKEND_RUNNING%"=="0" (
    echo.
    echo [2/2] starting backend ...
    echo       frontend  : http://localhost:3000
    echo       health    : http://localhost:3000/api/health
    echo       press Ctrl+C to stop.
    echo --------------------------------------------
    cd /d "%PROJECT%server"
    call npm start
) else (
    echo.
    echo [OK] backend already running. Open http://localhost:3000
    echo.
    echo Done. Press any key to close.
    pause >nul
)

endlocal
