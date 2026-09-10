@echo off
setlocal enabledelayedexpansion

REM Parcourt le dossier courant et tous les sous-dossiers
for /r %%i in (*.png) do (
    echo Conversion de : "%%i"
    magick "%%i" -quality 80 "%%~dpni.webp"

    REM Si la conversion a réussi, supprime l’ancien PNG
    if exist "%%~dpni.webp" (
        del "%%i"
        echo Supprime : "%%i"
    )
)

echo.
echo Conversion terminee !
pause
