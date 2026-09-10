@echo off
setlocal enabledelayedexpansion

echo [INFO] Script de renommage démarré
echo [INFO] Date et heure actuelles: %date% %time%

:: Définir le répertoire courant
cd /d "%~dp0"
echo [INFO] Répertoire courant: %CD%

:: Trouver l'ID le plus élevé existant
set "HIGHEST_ID=-1"
for %%F in (father-*.png) do (
    set "FILENAME=%%~nF"
    set "ID=!FILENAME:~7!"
    if !ID! GTR !HIGHEST_ID! set "HIGHEST_ID=!ID!"
)

:: Si aucun fichier father-ID n'existe, commencer à 0
if !HIGHEST_ID! EQU -1 (
    set "NEXT_ID=0"
    echo [INFO] Aucun fichier father-*.png existant, on commence à l'ID 0
) else (
    set /a "NEXT_ID=!HIGHEST_ID!+1"
    echo [INFO] ID le plus élevé trouvé: !HIGHEST_ID!, prochain ID: !NEXT_ID!
)

:: Utiliser PowerShell pour gérer les caractères spéciaux
echo [INFO] Utilisation de PowerShell pour le traitement des fichiers...

:: Créer un script PowerShell temporaire
set "PS_SCRIPT=%TEMP%\rename_script.ps1"
echo $ErrorActionPreference = 'Stop' > "%PS_SCRIPT%"
echo $nextId = %NEXT_ID% >> "%PS_SCRIPT%"
echo Write-Host "[INFO] Recherche des fichiers PNG..." >> "%PS_SCRIPT%"
echo $files = Get-ChildItem -Path . -Filter "*.png" ^| Where-Object { $_.Name -notlike "father-*.png" } >> "%PS_SCRIPT%"

:: Extraire le numéro à la fin du nom de fichier pour le tri
echo Write-Host "[INFO] Extraction des numéros à partir des noms de fichiers..." >> "%PS_SCRIPT%"
echo $filesWithNumbers = @() >> "%PS_SCRIPT%"
echo foreach ($file in $files) { >> "%PS_SCRIPT%"
echo   $match = $file.Name -match "(\d+)\.png$" >> "%PS_SCRIPT%"
echo   if ($match) { >> "%PS_SCRIPT%"
echo     $number = [int]$matches[1] >> "%PS_SCRIPT%"
echo     $filesWithNumbers += [PSCustomObject]@{ >> "%PS_SCRIPT%"
echo       File = $file >> "%PS_SCRIPT%"
echo       Number = $number >> "%PS_SCRIPT%"
echo     } >> "%PS_SCRIPT%"
echo     Write-Host "[INFO] Fichier: $($file.Name) - Numéro extrait: $number" >> "%PS_SCRIPT%"
echo   } else { >> "%PS_SCRIPT%"
echo     Write-Host "[AVERTISSEMENT] Impossible d'extraire le numéro du fichier: $($file.Name)" >> "%PS_SCRIPT%"
echo     $filesWithNumbers += [PSCustomObject]@{ >> "%PS_SCRIPT%"
echo       File = $file >> "%PS_SCRIPT%"
echo       Number = 999999 >> "%PS_SCRIPT%"
echo     } >> "%PS_SCRIPT%"
echo   } >> "%PS_SCRIPT%"
echo } >> "%PS_SCRIPT%"

:: Trier par numéro extrait (ordre croissant)
echo Write-Host "[INFO] Tri des fichiers par numéro..." >> "%PS_SCRIPT%"
echo $sortedFiles = $filesWithNumbers ^| Sort-Object Number >> "%PS_SCRIPT%"
echo Write-Host "[INFO] Liste des fichiers triés:" >> "%PS_SCRIPT%"
echo $sortedFiles ^| ForEach-Object { Write-Host "  $($_.Number) - $($_.File.Name)" } >> "%PS_SCRIPT%"

:: Renommer les fichiers
echo Write-Host "[INFO] Renommage des fichiers..." >> "%PS_SCRIPT%"
echo foreach ($fileInfo in $sortedFiles) { >> "%PS_SCRIPT%"
echo   $file = $fileInfo.File >> "%PS_SCRIPT%"
echo   $newName = "father-" + $nextId + ".png" >> "%PS_SCRIPT%"
echo   Write-Host "[INFO] Renommage de '$($file.Name)' en '$newName'" >> "%PS_SCRIPT%"
echo   try { >> "%PS_SCRIPT%"
echo     Rename-Item -Path $file.FullName -NewName $newName -Force >> "%PS_SCRIPT%"
echo     Write-Host "[SUCCÈS] Fichier renommé avec succès" >> "%PS_SCRIPT%"
echo     $nextId++ >> "%PS_SCRIPT%"
echo   } catch { >> "%PS_SCRIPT%"
echo     Write-Host "[ERREUR] Échec du renommage: $_" >> "%PS_SCRIPT%"
echo     try { >> "%PS_SCRIPT%"
echo       Copy-Item -Path $file.FullName -Destination $newName -Force >> "%PS_SCRIPT%"
echo       Remove-Item -Path $file.FullName -Force >> "%PS_SCRIPT%"
echo       Write-Host "[SUCCÈS] Fichier copié et supprimé avec succès" >> "%PS_SCRIPT%"
echo       $nextId++ >> "%PS_SCRIPT%"
echo     } catch { >> "%PS_SCRIPT%"
echo       Write-Host "[ERREUR] Échec de la copie: $_" >> "%PS_SCRIPT%"
echo     } >> "%PS_SCRIPT%"
echo   } >> "%PS_SCRIPT%"
echo } >> "%PS_SCRIPT%"
echo Write-Host "" >> "%PS_SCRIPT%"
echo Write-Host "[INFO] Renommage terminé. Prochain ID disponible: $nextId" >> "%PS_SCRIPT%"

:: Exécuter le script PowerShell
echo [INFO] Exécution du script PowerShell...
powershell -ExecutionPolicy Bypass -File "%PS_SCRIPT%"

:: Nettoyage
del "%PS_SCRIPT%" > nul 2>&1

echo.
echo [INFO] Traitement terminé.
echo.
pause