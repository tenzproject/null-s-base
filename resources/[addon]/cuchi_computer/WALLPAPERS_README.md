# 🖼️ Guide d'Ajout de Fond d'Écran

## Comment ajouter vos propres fonds d'écran

### Étape 1 : Ajouter votre image

Placez vos images dans le dossier :
```
nui/assets/wallpapers/
```

**Formats recommandés :** JPG, PNG, WEBP  
**Résolution recommandée :** 1920x1080 ou supérieur  
**Taille de fichier :** Moins de 2MB pour de meilleures performances

### Étape 2 : Configurer le wallpaper

Ouvrez le fichier `app_config.lua` et ajoutez votre wallpaper dans la section `Wallpapers` :

```lua
Wallpapers = {
    { name = "None", image = "none" },
    { name = "Weed Lab", image = "assets/images/weed_labo3.png" },
    { name = "Weed Lab 2", image = "assets/images/weed_labo2.png" },
    { name = "Abstract", image = "assets/images/1802979.png" },
    
    -- Ajoutez vos wallpapers ici :
    { name = "Mon Wallpaper", image = "assets/wallpapers/mon-image.jpg" },
    { name = "Cyberpunk", image = "assets/wallpapers/cyberpunk.png" },
},
```

### Étape 3 : Redémarrer la ressource

```
/restart cuchi_computer
```

## Exemples de configuration

### Utiliser une image du dossier wallpapers
```lua
{ name = "Nature", image = "assets/wallpapers/nature.jpg" }
```

### Utiliser une image existante du script
```lua
{ name = "Laboratory", image = "assets/images/labo.png" }
```

### Aucun fond d'écran (transparent)
```lua
{ name = "None", image = "none" }
```

## Conseils

- **Noms descriptifs** : Utilisez des noms clairs pour vos wallpapers
- **Optimisation** : Compressez vos images avant de les ajouter
- **Cohérence** : Gardez une résolution similaire pour tous vos wallpapers
- **Test** : Testez chaque wallpaper après l'ajout pour vérifier le rendu

## Structure des fichiers

```
cuchi_computer/
├── app_config.lua          ← Configuration des wallpapers
└── nui/
    └── assets/
        ├── wallpapers/     ← Placez vos images ici
        │   ├── wallpaper1.jpg
        │   ├── wallpaper2.png
        │   └── ...
        └── images/         ← Images existantes du script
```

## Dépannage

**Le wallpaper ne s'affiche pas ?**
- Vérifiez le chemin de l'image dans `app_config.lua`
- Assurez-vous que l'image existe dans le bon dossier
- Redémarrez la ressource avec `/restart cuchi_computer`

**L'image est floue ?**
- Utilisez une résolution plus élevée (1920x1080 minimum)
- Vérifiez que l'image n'est pas trop compressée

**L'image ralentit le jeu ?**
- Réduisez la taille du fichier (< 2MB recommandé)
- Utilisez le format WEBP pour une meilleure compression
