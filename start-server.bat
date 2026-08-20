@echo off
chcp 65001 >nul 2>&1
title Sleep Well - One-click Start
setlocal enabledelayedexpansion
echo ============================================
echo   Sleep Well (sleep-cbti) One-click Start
echo ============================================
echo.

rem PROJECT dir = this script's directory (any path works)
set "PROJECT=%~dp0"
set "MYSQL_BIN=C:\xampp\mysql\bin"
set "MYSQL_DATA=C:\xampp\mysql\data"

rem ---------- check if ports already in use ----------
set "BACKEND_RUNNING=0"
set "MYSQL_RUNNING=0"
netstat -ano | findstr ":3000 " | findstr "LISTENING" >nul 2>&1
if %errorlevel%==0 set "BACKEND_RUNNING=1"
netstat -ano | findstr ":3306 " | findstr "LISTENING" >nul 2>&1
if %errorlevel%==0 set "MYSQL_RUNNING=1"

if "%MYSQL_RUNNING%"=="1"   echo [skip] MySQL already running   (port 3306)
if "%BACKEND_RUNNING%"=="1" echo [skip] backend already running (port 3000)

rem ---------- start MySQL if it is NOT running ----------
if "%MYSQL_RUNNING%"=="0" goto start_mysql
echo.
echo MySQL already running - skipping.
goto start_backend

:start_mysql
echo.
echo [1/2] Starting MySQL ...
rem remove stale pid files that can block startup
del /q "%MYSQL_DATA%\*.pid" 2>nul
rem launch mysqld in the background (same window), then poll the port
start "" /b "%MYSQL_BIN%\mysqld.exe" --defaults-file="%MYSQL_BIN%\my.ini" 2>nul
echo        Waiting for MySQL (max 30s) ...
set /a TRIES=0
:wait_mysql_loop
set /a TRIES+=1
if %TRIES% gtr 60 (
    echo [WARN] Timeout waiting for MySQL. Check errors below.
    goto start_backend
)
netstat -ano | findstr ":3306 " | findstr "LISTENING" >nul 2>&1
if errorlevel 1 (
    timeout /t 1 /nobreak >nul
    goto wait_mysql_loop
)
echo [OK] MySQL ready (port 3306)
goto start_backend

:start_backend
rem ---------- start backend if it is NOT running ----------
if "%BACKEND_RUNNING%"=="1" goto backend_exists
echo.
echo [2/2] Starting backend ...
echo        frontend : http://localhost:3000
echo        health   : http://localhost:3000/api/health
echo        Press Ctrl+C to stop.
echo --------------------------------------------
cd /d "%PROJECT%server"
call npm start
goto end

:backend_exists
echo.
echo [OK] backend already running. Open http://localhost:3000
pause >nul
goto end

:end
echo.
echo Done.
endlocal
