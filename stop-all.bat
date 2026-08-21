@echo off
chcp 65001 >nul 2>&1
title Sleep Well - Stop All
setlocal
echo ============================================
echo   Sleep Well - Stop backend + MySQL
echo   (DSH / port 3080 will NOT be touched)
echo ============================================
echo.

rem ---------- 1) Stop backend on port 3000 ----------
echo [1/2] Stopping backend [port 3000] ...
set "FOUND3000=0"
for /f "tokens=5" %%P in ('netstat -ano ^| findstr ":3000 " ^| findstr "LISTENING"') do (
    tasklist /fi "PID eq %%P" | findstr /i "node.exe" >nul 2>&1
    if not errorlevel 1 (
        taskkill /F /PID %%P >nul 2>&1
        set "FOUND3000=1"
        echo   - backend node PID %%P stopped
    )
)
if "%FOUND3000%"=="0" echo   no backend node on :3000 - nothing to stop
echo.

rem ---------- 2) Stop MySQL on port 3306 ----------
echo [2/2] Stopping MySQL [port 3306] ...
set "FOUND3306=0"
for /f "tokens=5" %%P in ('netstat -ano ^| findstr ":3306 " ^| findstr "LISTENING"') do (
    tasklist /fi "PID eq %%P" | findstr /i "mysqld.exe" >nul 2>&1
    if not errorlevel 1 (
        taskkill /F /PID %%P >nul 2>&1
        set "FOUND3306=1"
        echo   - MySQL mysqld PID %%P stopped
    )
)
if "%FOUND3306%"=="0" echo   no mysqld on :3306 - nothing to stop

echo.
echo Done. Backend and MySQL stopped. DSH on port 3080 untouched.
echo Start everything again with start-server.bat
echo.
pause
endlocal
