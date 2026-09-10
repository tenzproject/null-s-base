@echo off
setlocal enabledelayedexpansion

REM Vérifier si ImageMagick est installé
where magick >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo ImageMagick n'est pas installe. Veuillez l'installer depuis https://imagemagick.org/
    pause
    exit /b 1
)

echo Recherche des images dans tous les dossiers...

REM Traiter chaque image dans le dossier courant et les sous-dossiers
for /R %%f in (*.jpg *.jpeg *.png) do (
    echo Redimensionnement de %%f...
    magick "%%f" -resize "300x300>" "%%f"
)

echo Terminé ! Toutes les images ont été redimensionnées.
pause
