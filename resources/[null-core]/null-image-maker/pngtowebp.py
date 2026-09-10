from pathlib import Path
from PIL import Image
import os

def convertir_png_vers_webp(chemin_dossier):
    # Transformer le chemin en objet Path
    dossier = Path(chemin_dossier)
    
    # Vérifier si le dossier existe
    if not dossier.is_dir():
        print(f"Le dossier spécifié n'existe pas : {chemin_dossier}")
        return

    # Compteur pour le suivi
    compteur = 0

    # Parcourir tous les fichiers .png dans le dossier
    for fichier_png in dossier.glob("*.png"):
        # Créer le nouveau chemin avec l'extension .webp
        fichier_webp = fichier_png.with_suffix('.webp')
        
        try:
            # Ouvrir l'image et la sauvegarder en webp
            with Image.open(fichier_png) as img:
                # On utilise RGB si l'image a une transparence (RGBA) pour éviter certains bugs, 
                # mais WebP supporte nativement le RGBA (transparence) !
                img.save(fichier_webp, "webp")
                
            print(f"✅ Converti : {fichier_png.name} -> {fichier_webp.name}")
            compteur += 1
            
        except Exception as e:
            print(f"❌ Erreur avec {fichier_png.name} : {e}")

    print(f"\nTerminé ! {compteur} image(s) convertie(s).")

# --- EXÉCUTION ---
# Remplacez le chemin ci-dessous par le chemin de votre dossier
# Exemple sous Windows : r"C:\Users\VotreNom\Images\Dossier"
# Exemple sous Mac/Linux : "/Users/VotreNom/Images/Dossier"
dossier_cible = "/home/null/fivem-server/resources/[others-not-started]/imagemaker/images/vehicles" # "./" correspond au dossier dans lequel se trouve le script

convertir_png_vers_webp(dossier_cible)