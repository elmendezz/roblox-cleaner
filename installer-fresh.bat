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

:: 1. Crear el directorio estratégico
echo [*] Paso 1: Verificando existencia de la carpeta...
if not exist "%targetDir%" (
    mkdir "%targetDir%" 2>nul
    echo [+] Carpeta creada exitosamente.
) else (
    echo [i] La carpeta ya existe.
)

:: Forzar toma de posesion y permisos totales
echo [*] Paso 2: Forzando toma de posesion y privilegios...
takeown /f "%targetDir%" /a /r /d s >nul 2>&1
icacls "%targetDir%" /grant administrators:F /t >nul 2>&1
echo [OK] Permisos concedidos al grupo Administradores.

:: 2. Crear el script de limpieza (Bucle Infinito con MEJOR LOGGING)
echo [*] Paso 3: Creando archivos de servicio...
echo @echo off > "%targetDir%\%cleanerName%"
echo set "logFile=%logFile%" >> "%targetDir%\%cleanerName%"
echo echo [%%date%% %%time%%] === SERVICIO INICIADO === ^>^> "%%logFile%%" >> "%targetDir%\%cleanerName%"
echo :loop >> "%targetDir%\%cleanerName%"
echo :: Control de tamano de log (10MB) >> "%targetDir%\%cleanerName%"
echo if exist "%%logFile%%" (for %%%%I in ("%%logFile%%") do if %%%%~zI gtr 10485760 type nul ^> "%%logFile%%") >> "%targetDir%\%cleanerName%"

echo echo [%%date%% %%time%%] --- Nuevo ciclo de busqueda y limpieza --- ^>^> "%%logFile%%" >> "%targetDir%\%cleanerName%"

echo :: Matar procesos >> "%targetDir%\%cleanerName%"
echo tasklist /FI "IMAGENAME eq RobloxPlayerBeta.exe" 2^>NUL ^| find /I /N "RobloxPlayerBeta.exe"^>NUL >> "%targetDir%\%cleanerName%"
echo if "%%ERRORLEVEL%%"=="0" (echo [%%date%% %%time%%] Matando RobloxPlayerBeta.exe... ^>^> "%%logFile%%" ^& taskkill /F /IM RobloxPlayerBeta.exe /T ^>^> "%%logFile%%" 2^>^&1) >> "%targetDir%\%cleanerName%"

echo tasklist /FI "IMAGENAME eq RobloxStudioBeta.exe" 2^>NUL ^| find /I /N "RobloxStudioBeta.exe"^>NUL >> "%targetDir%\%cleanerName%"
echo if "%%ERRORLEVEL%%"=="0" (echo [%%date%% %%time%%] Matando RobloxStudioBeta.exe... ^>^> "%%logFile%%" ^& taskkill /F /IM RobloxStudioBeta.exe /T ^>^> "%%logFile%%" 2^>^&1) >> "%targetDir%\%cleanerName%"

echo :: Borrar archivos >> "%targetDir%\%cleanerName%"
echo if exist "%%LocalAppData%%\Roblox" (echo [%%date%% %%time%%] Eliminando archivos en LocalAppData... ^>^> "%%logFile%%" ^& rd /s /q "%%LocalAppData%%\Roblox" ^>^> "%%logFile%%" 2^>^&1) >> "%targetDir%\%cleanerName%"
echo if exist "%%ProgramFiles(x86)%%\Roblox" (echo [%%date%% %%time%%] Eliminando archivos en ProgramFiles... ^>^> "%%logFile%%" ^& rd /s /q "%%ProgramFiles(x86)%%\Roblox" ^>^> "%%logFile%%" 2^>^&1) >> "%targetDir%\%cleanerName%"

echo :: Borrar llaves de registro >> "%targetDir%\%cleanerName%"
echo reg query "HKEY_CURRENT_USER\Software\Roblox" ^>nul 2^>^&1 >> "%targetDir%\%cleanerName%"
echo if "%%ERRORLEVEL%%"=="0" (echo [%%date%% %%time%%] Eliminando registro de Roblox... ^>^> "%%logFile%%" ^& reg delete "HKEY_CURRENT_USER\Software\Roblox" /f ^>^> "%%logFile%%" 2^>^&1) >> "%targetDir%\%cleanerName%"

echo :: Esperar 30 segundos >> "%targetDir%\%cleanerName%"
echo timeout /t 30 /nobreak ^>nul >> "%targetDir%\%cleanerName%"
echo goto loop >> "%targetDir%\%cleanerName%"

:: 3. Crear el script VBS para ejecucion invisible
echo Set WshShell = CreateObject("WScript.Shell") > "%targetDir%\%vbsName%"
echo WshShell.Run chr(34) ^& "%targetDir%\%cleanerName%" ^& Chr(34), 0 >> "%targetDir%\%vbsName%"
echo Set WshShell = Nothing >> "%targetDir%\%vbsName%"

:: Mover la ocultacion AQUI (despues de haber creado los archivos)
attrib +h +s "%targetDir%" /d /s >nul 2>&1

:: 4. Persistencia en el Registro
echo [*] Paso 4: Creando persistencia en el registro...
reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run" /v "CleanerService" /t REG_SZ /d "wscript.exe \"%targetDir%\%vbsName%\"" /f >nul 2>&1

:: 5. Ejecutar ahora mismo de forma invisible
echo [*] Paso 5: Iniciando servicio en segundo plano...
start wscript.exe "%targetDir%\%vbsName%"

:: 6. Verificacion de ejecucion (CORREGIDA)
:: En lugar de buscar wscript, buscamos si el log se creo exitosamente
timeout /t 3 /nobreak >nul
if exist "%logFile%" (
    echo [LISTO] El script esta corriendo exitosamente.
    echo.
    echo --- ULTIMAS LINEAS DEL LOG ---
    type "%logFile%"
    echo ------------------------------
    echo Puedes revisar todo el historial en: %logFile%
) else (
    echo [ERROR] El archivo de log no se genero. 
    echo Posibles causas: Tu antivirus (Windows Defender) bloqueo el VBScript.
)
pause