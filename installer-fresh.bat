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

set "targetDir=C:\ProgramData\Cleaner"
set "cleanerName=system_cleanup.bat"
set "vbsName=start_service.vbs"
set "logFile=%targetDir%\cleanup.log"

:: 1. Crear el directorio estrategico
echo [*] Paso 1: Verificando existencia de la carpeta...
if not exist "%targetDir%" (
    mkdir "%targetDir%" 2>nul
    echo [+] Carpeta creada exitosamente.
) else (
    echo [i] La carpeta ya existe.
)

:: Forzar toma de posesion y permisos totales
echo [*] Paso 2: Forzando permisos...
takeown /f "%targetDir%" /a /r /d s >nul 2>&1
icacls "%targetDir%" /grant administrators:F /t >nul 2>&1

:: 2. Crear el script de limpieza (Bucle Infinito)
echo [*] Paso 3: Creando archivos de servicio...
echo @echo off > "%targetDir%\%cleanerName%"
echo set "logFile=%logFile%" >> "%targetDir%\%cleanerName%"
echo echo [%%date%% %%time%%] === NUEVO SERVICIO INICIADO === ^>^> "%%logFile%%" >> "%targetDir%\%cleanerName%"
echo :loop >> "%targetDir%\%cleanerName%"
echo :: Control de tamano de log (10MB) >> "%targetDir%\%cleanerName%"
echo if exist "%%logFile%%" (for %%%%I in ("%%logFile%%") do if %%%%~zI gtr 10485760 type nul ^> "%%logFile%%") >> "%targetDir%\%cleanerName%"

echo echo [%%date%% %%time%%] --- Buscando Roblox --- ^>^> "%%logFile%%" >> "%targetDir%\%cleanerName%"

echo :: Matar procesos >> "%targetDir%\%cleanerName%"
echo tasklist /FI "IMAGENAME eq RobloxPlayerBeta.exe" 2^>NUL ^| find /I /N "RobloxPlayerBeta.exe"^>NUL >> "%targetDir%\%cleanerName%"
echo if "%%ERRORLEVEL%%"=="0" (echo [%%date%% %%time%%] Matando juego... ^>^> "%%logFile%%" ^& taskkill /F /IM RobloxPlayerBeta.exe /T ^>^> "%%logFile%%" 2^>^&1) >> "%targetDir%\%cleanerName%"

echo tasklist /FI "IMAGENAME eq RobloxPlayerLauncher.exe" 2^>NUL ^| find /I /N "RobloxPlayerLauncher.exe"^>NUL >> "%targetDir%\%cleanerName%"
echo if "%%ERRORLEVEL%%"=="0" (echo [%%date%% %%time%%] Matando launcher... ^>^> "%%logFile%%" ^& taskkill /F /IM RobloxPlayerLauncher.exe /T ^>^> "%%logFile%%" 2^>^&1) >> "%targetDir%\%cleanerName%"

echo :: Borrar carpetas de instalacion >> "%targetDir%\%cleanerName%"
echo if exist "%%LocalAppData%%\Roblox" (echo [%%date%% %%time%%] Eliminando LocalAppData... ^>^> "%%logFile%%" ^& rd /s /q "%%LocalAppData%%\Roblox" ^>^> "%%logFile%%" 2^>^&1) >> "%targetDir%\%cleanerName%"
echo if exist "%%ProgramFiles(x86)%%\Roblox" (echo [%%date%% %%time%%] Eliminando ProgramFiles... ^>^> "%%logFile%%" ^& rd /s /q "%%ProgramFiles(x86)%%\Roblox" ^>^> "%%logFile%%" 2^>^&1) >> "%targetDir%\%cleanerName%"

echo :: Borrar ACCESOS DIRECTOS del escritorio >> "%targetDir%\%cleanerName%"
echo if exist "%%UserProfile%%\Desktop\Roblox*.lnk" (echo [%%date%% %%time%%] Eliminando iconos del usuario... ^>^> "%%logFile%%" ^& del /q "%%UserProfile%%\Desktop\Roblox*.lnk" 2^>nul) >> "%targetDir%\%cleanerName%"
echo if exist "C:\Users\Public\Desktop\Roblox*.lnk" (echo [%%date%% %%time%%] Eliminando iconos publicos... ^>^> "%%logFile%%" ^& del /q "C:\Users\Public\Desktop\Roblox*.lnk" 2^>nul) >> "%targetDir%\%cleanerName%"

echo :: Borrar llaves de registro >> "%targetDir%\%cleanerName%"
echo reg query "HKEY_CURRENT_USER\Software\Roblox" ^>nul 2^>^&1 >> "%targetDir%\%cleanerName%"
echo if "%%ERRORLEVEL%%"=="0" (echo [%%date%% %%time%%] Eliminando registro... ^>^> "%%logFile%%" ^& reg delete "HKEY_CURRENT_USER\Software\Roblox" /f ^>^> "%%logFile%%" 2^>^&1) >> "%targetDir%\%cleanerName%"

echo :: Esperar 15 segundos >> "%targetDir%\%cleanerName%"
echo timeout /t 15 /nobreak ^>nul >> "%targetDir%\%cleanerName%"
echo goto loop >> "%targetDir%\%cleanerName%"

:: 3. Crear el script VBS
echo Set WshShell = CreateObject("WScript.Shell") > "%targetDir%\%vbsName%"
echo WshShell.Run chr(34) ^& "%targetDir%\%cleanerName%" ^& Chr(34), 0 >> "%targetDir%\%vbsName%"
echo Set WshShell = Nothing >> "%targetDir%\%vbsName%"

:: Ocultar carpeta
attrib +h +s "%targetDir%" /d /s >nul 2>&1

:: 4. Persistencia
echo [*] Paso 4: Creando persistencia...
reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run" /v "CleanerService" /t REG_SZ /d "wscript.exe \"%targetDir%\%vbsName%\"" /f >nul 2>&1

:: 5. Ejecutar
echo [*] Paso 5: Iniciando servicio en segundo plano...
start wscript.exe "%targetDir%\%vbsName%"

:: 6. Verificacion
timeout /t 3 /nobreak >nul
if exist "%logFile%" (
    echo [LISTO] El script esta corriendo exitosamente.
) else (
    echo [ERROR] No se pudo generar el archivo de log.
)
pause