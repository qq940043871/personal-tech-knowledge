@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

set "PORT=3005"
set "SCRIPT_DIR=%~dp0"
cd /d "%SCRIPT_DIR%"

echo ========================================
echo   personal-tech-knowledge - Local Preview
echo   Port: %PORT%
echo ========================================
echo.

rem ===== [1/3] refresh document tree index (best effort) =====
rem library/index.html 的侧边栏导航由 library/tree.json 驱动。每次启动都从磁盘
rem 重新扫描生成，避免新增/删除文档后导航出现死链。
set "PYOK="
python -c "print(1)" 2>nul | findstr /x "1" >nul && set "PYOK=1"
if defined PYOK (
    python "%~dp0library\build_tree.py" >nul 2>&1 && echo [1/3] Document index: tree.json regenerated. || echo [1/3] Document index: generation failed, using existing tree.json.
) else (
    echo [1/3] Document index: python unavailable, using existing tree.json.
)

rem ===== [2/3] pick a static file server =====
rem NOTE 1: every npx call below MUST use `call`. npx is a .cmd file, and invoking a
rem         .cmd from a .bat without `call` transfers control away and abandons this
rem         script (silent exit, no error).
rem NOTE 2: `where python` is NOT a reliable check. A Windows install may expose a
rem         0-byte Microsoft Store stub named python.exe that silently does nothing,
rem         so candidates are verified by actually running them (see PYOK above).
set "SERVER="
call npx --no-install http-server --version >nul 2>&1 && set "SERVER=http-server"
if not defined SERVER (
    if defined PYOK set "SERVER=python"
)
if not defined SERVER (
    call npx --yes http-server --version >nul 2>&1 && set "SERVER=npx-install"
)
if not defined SERVER (
    echo [ERROR] No usable static file server found.
    echo         Tried: cached http-server, python, npx http-server.
    echo         Install Node.js: https://nodejs.org/
    exit /b 1
)
echo [2/3] HTTP server: %SERVER%

rem ===== [3/3] check port =====
echo [3/3] Checking port %PORT% ...
set "PID="
for /f "tokens=5" %%a in ('netstat -ano ^| findstr ":%PORT% " ^| findstr LISTENING') do (
    set "PID=%%a"
    goto :found_pid
)
echo       Port %PORT% is free.
goto :start_server

:found_pid
echo       Port %PORT% is already in use by PID !PID!.
set "PNAME=unknown"
for /f "tokens=1 delims=," %%n in ('tasklist /FI "PID eq !PID!" /FO CSV /NH 2^>nul') do set "PNAME=%%~n"
echo       Process name: !PNAME!
set "ANSWER="
set /p "ANSWER=      Kill it? [y/N] "
if /i not "!ANSWER!"=="y" (
    echo       Cancelled. No process was terminated.
    exit /b 1
)
taskkill /F /PID !PID! >nul 2>&1
if !errorlevel! equ 0 (
    echo       Process !PID! terminated.
) else (
    echo       [WARN] Failed to terminate !PID!, trying to start anyway.
)
timeout /t 1 /nobreak >nul 2>&1

:start_server
echo.
echo   ============================================
echo    URL:  http://127.0.0.1:%PORT%/
echo.
echo    Keep this window OPEN while browsing.
echo    Press Ctrl+C to stop the server.
echo   ============================================
echo.

if /i "%SERVER%"=="python" (
    python -m http.server %PORT% --bind 127.0.0.1
) else (
    call npx http-server -p %PORT% -c-1 -a 127.0.0.1
)

echo.
echo Server stopped.
pause
endlocal
