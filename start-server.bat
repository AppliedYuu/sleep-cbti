@echo off
chcp 65001 >nul 2>&1
title Sleep Well - One-click Start
setlocal enabledelayedexpansion
echo ============================================
echo   Sleep Well (sleep-cbti) One-click Start
echo ============================================
echo.

set "PROJECT=%~dp0"
set "MYSQL_BIN=C:\xampp\mysql\bin"
set "MYSQL_DATA=C:\xampp\mysql\data"

rem ---------- check MySQL on 3306 ----------
set "MYSQL_RUNNING=0"
netstat -ano | findstr ":3306 " | findstr "LISTENING" >nul 2>&1
if %errorlevel%==0 set "MYSQL_RUNNING=1"

rem ---------- check backend health on 3000 ----------
rem A port listener is NOT enough - must also pass /api/health check.
rem If the port is occupied but health fails, it is a stale/broken backend
rem (e.g. database disconnected) -> we kill it and restart.
set "BACKEND_RUNNING=0"
netstat -ano | findstr ":3000 " | findstr "LISTENING" >nul 2>&1
if %errorlevel%==0 (
    set "PORT_IN_USE=1"
    call :is_backend_healthy
    if "!HEALTHY!"=="1" set "BACKEND_RUNNING=1"
) else (
    set "PORT_IN_USE=0"
)

if "%MYSQL_RUNNING%"=="1"  echo [skip] MySQL  running   (port 3306)
if "%BACKEND_RUNNING%"=="1" echo [ok]   backend healthy (port 3000)
if "%PORT_IN_USE%"=="1" if not "%BACKEND_RUNNING%"=="1" (
    echo [warn] port 3000 occupied by a stale backend - will restart it
)

rem ---------- start MySQL if not running ----------
if "%MYSQL_RUNNING%"=="0" goto start_mysql
goto start_backend

:start_mysql
echo.
echo [1/2] Starting MySQL ...
del /q "%MYSQL_DATA%\*.pid" 2>nul
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
if "%BACKEND_RUNNING%"=="1" goto backend_exists

rem if a stale process holds port 3000, kill it before starting fresh
if "%PORT_IN_USE%"=="1" (
    echo [cleanup] killing stale process on port 3000 ...
    for /f "tokens=5" %%P in ('netstat -ano ^| findstr ":3000 " ^| findstr "LISTENING"') do (
        taskkill /F /PID %%P >nul 2>&1
    )
    timeout /t 2 /nobreak >nul
)

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
echo [OK] backend already healthy. Open http://localhost:3000
pause >nul
goto end

:end
echo.
echo Done.
endlocal
goto :eof

rem ============================================
rem sub: is_backend_healthy  -> sets HEALTHY=1/0
rem ============================================
:is_backend_healthy
set "HEALTHY=0"
where curl >nul 2>&1
if errorlevel 1 (
    rem no curl - fall back: treat a live port as healthy
    set "HEALTHY=1"
    goto :eof
)
curl -s -o nul -w "%%{http_code}" http://localhost:3000/api/health > "%TEMP%\sbti_hc.txt" 2>nul
set "HC="
set /p HC=<"%TEMP%\sbti_hc.txt"
if "%HC%"=="200" set "HEALTHY=1"
del /q "%TEMP%\sbti_hc.txt" 2>nul
goto :eof
