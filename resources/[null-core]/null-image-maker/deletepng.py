from pathlib import Path
import os

def supprimer_fichiers_png(chemin_dossier):
    dossier = Path(chemin_dossier)
    
    # Vérifier si le dossier existe
    if not dossier.is_dir():
        print(f"❌ Le dossier spécifié n'existe pas : {chemin_dossier}")
        return

    # Lister tous les fichiers .png
    fichiers_png = list(dossier.glob("*.png"))
    nombre_fichiers = len(fichiers_png)
    
    if nombre_fichiers == 0:
        print("ℹ️ Aucun fichier .png n'a été trouvé dans ce dossier.")
        return

    # Avertissement de sécurité
    print(f"⚠️ ATTENTION : Vous êtes sur le point de supprimer {nombre_fichiers} fichier(s) .png")
    print(f"Dossier cible : {dossier.absolute()}")
    
    # Demander confirmation
    confirmation = input("Voulez-vous vraiment continuer ? (tapez 'o' pour oui, 'n' pour non) : ")
    
    if confirmation.lower() == 'o':
        compteur = 0
        for fichier in fichiers_png:
            try:
                # La fonction unlink() supprime le fichier
                fichier.unlink()
                print(f"🗑️ Supprimé : {fichier.name}")
                compteur += 1
            except Exception as e:
                print(f"❌ Impossible de supprimer {fichier.name} : {e}")
                
        print(f"\n✅ Terminé ! {compteur}/{nombre_fichiers} fichier(s) supprimé(s).")
    else:
        print("\n🛑 Opération annulée. Aucun fichier n'a été supprimé.")

# --- EXÉCUTION ---
# Indiquez le dossier où se trouvent les images à supprimer
dossier_cible = "/home/null/fivem-server/resources/[others-not-started]/imagemaker/images/vehicles" # "./" correspond au dossier dans lequel se trouve le script

supprimer_fichiers_png(dossier_cible)