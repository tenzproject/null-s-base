# 📸 null ImageMaker

Système complet de génération automatique d'icônes transparentes pour inventaire FiveM.

## 🎯 Fonctionnalités

- **Automatisation complète** : Génère automatiquement des centaines d'icônes en une seule commande
- **Détourage automatique** : Suppression du fond avec IA via `@imgly/background-removal-node`
- **Organisation intelligente** : Classement automatique par catégorie et genre
- **Surveillance en temps réel** : Traitement automatique dès qu'une nouvelle image est détectée
- **Gestion des erreurs** : Suppression automatique des fichiers corrompus

## 📋 Catégories supportées

- **Cheveux** (male/female) - 74/77 variations
- **Barbes** - 29 variations
- **Sourcils** - 34 variations
- **Poils du torse** - 17 variations
- **Rouge à lèvres** - 10 variations
- **Tatouages** - 101 variations

## 🚀 Installation

### 1. Installation de la ressource FiveM

```bash
cd resources/[addon]/
# La ressource est déjà présente dans null-imagemaker/
```

Ajoutez dans votre `server.cfg` :
```cfg
ensure screenshot-basic
ensure null-imagemaker
```

### 2. Prérequis Node.js

**Important** : Le processeur Node.js nécessite Node.js ≥18.0.0. Votre serveur FiveM utilise probablement une version plus ancienne, c'est pourquoi le processeur doit tourner **séparément**.

Si vous n'avez pas Node.js 18+ installé sur votre système :
```bash
# Installer Node.js 18+ via nvm (recommandé)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
source ~/.bashrc
nvm install 18
nvm use 18
```

## 📖 Utilisation

### Étape 1 : Démarrer le processeur Node.js

Dans un terminal séparé (avec Node.js 18+) :

```bash
cd resources/[addon]/null-imagemaker/processor/
./start-processor.sh
```

**Note** : Le processeur est dans un dossier séparé pour éviter que FiveM détecte le `package.json` et essaie de l'installer avec sa propre version de Node.js.

Vous devriez voir :
```
╔════════════════════════════════════════════════════════╗
║     null IMAGE MAKER - Processeur d'images          ║
╚════════════════════════════════════════════════════════╝

✓ Dossiers initialisés
👀 Surveillance active du dossier raw_images/
```

### Étape 2 : Lancer la génération in-game

Connectez-vous à votre serveur FiveM et utilisez :

```
/generateicons male
```

ou

```
/generateicons female
```

### Étape 3 : Surveiller la progression

**In-game** :
- Le HUD sera automatiquement désactivé
- Vous verrez la progression dans la console F8
- Un message de confirmation apparaîtra à la fin

**Terminal Node.js** :
- Chaque image sera traitée automatiquement
- Affichage en temps réel de la progression
- Statistiques finales à la fin du traitement

### Commandes disponibles

| Commande | Description |
|----------|-------------|
| `/generateicons male` | Génère toutes les icônes pour personnage masculin |
| `/generateicons female` | Génère toutes les icônes pour personnage féminin |
| `/stopgeneration` | Arrête la génération en cours |

## 📁 Structure des dossiers

```
null-imagemaker/
├── raw_images/              # Images brutes (temporaire)
├── images/                  # Images finales détourées
│   ├── hair/
│   │   ├── male/           # 0.png → 73.png
│   │   └── female/         # 0.png → 76.png
│   ├── beard/              # 0.png → 28.png
│   ├── eyebrows/           # 0.png → 33.png
│   ├── chest_hair/         # 0.png → 16.png
│   ├── lipstick/           # 0.png → 9.png
│   └── tattoos/            # 0.png → 100.png
├── processor/              # Processeur Node.js (séparé de FiveM)
│   ├── processor.js        # Script de traitement
│   ├── package.json        # Dépendances Node.js
│   └── start-processor.sh  # Script de démarrage
├── config.lua              # Configuration des caméras
├── client.lua              # Script client FiveM
├── server.lua              # Script serveur FiveM
└── fxmanifest.lua          # Manifest FiveM
```

**Important** : Le dossier `processor/` contient les fichiers Node.js et est **isolé** de la ressource FiveM pour éviter les conflits de version Node.js.

## ⚙️ Configuration

### Modifier les positions de caméra

Éditez `config.lua` :

```lua
Config.Categories = {
    {
        name = "hair",
        camera = {
            offset = vector3(0.0, 0.5, 0.65),  -- Position relative au ped
            rotation = vector3(0.0, 0.0, 180.0), -- Rotation de la caméra
            fov = 40.0                           -- Champ de vision
        },
        -- ...
    }
}
```

### Modifier les plages d'ID

```lua
ranges = {
    male = {min = 0, max = 73},
    female = {min = 0, max = 76}
}
```

### Modifier le délai entre screenshots

```lua
Config.ScreenshotDelay = 500  -- En millisecondes
```

## 🔧 Workflow de traitement

1. **Capture** : Le script Lua prend un screenshot via `screenshot-basic`
2. **Sauvegarde temporaire** : L'image est sauvegardée dans `raw_images/`
3. **Détection** : Chokidar détecte le nouveau fichier
4. **Traitement** : Le fond est supprimé avec l'IA
5. **Classement** : L'image est déplacée dans le bon dossier
6. **Nettoyage** : Le fichier original est supprimé de `raw_images/`

## 📊 Performance

- **Génération** : ~500 screenshots en 5-10 minutes (selon Config.ScreenshotDelay)
- **Traitement** : ~2-3 secondes par image (dépend de votre CPU)
- **Total** : Comptez environ 20-30 minutes pour un catalogue complet

## ⚠️ Prérequis

- **FiveM** : screenshot-basic installé
- **Node.js** : Version 18.0.0 ou supérieure
- **RAM** : Au moins 4GB disponibles (pour le modèle IA)
- **Espace disque** : ~500MB pour les images finales

## 🐛 Dépannage

### Erreur "The engine node is incompatible" au démarrage de FiveM

**Cause** : FiveM détecte automatiquement les fichiers `package.json` et essaie d'installer les dépendances avec sa propre version de Node.js (16.x), qui est incompatible.

**Solution** : Le `package.json` est maintenant dans le dossier `processor/` qui est isolé de la ressource FiveM. Assurez-vous qu'il n'y a **aucun** fichier `package.json`, `package-lock.json` ou `node_modules` à la racine de `null-imagemaker/`.

Si vous voyez toujours l'erreur :
```bash
cd resources/[addon]/null-imagemaker/
rm -f package.json package-lock.json
rm -rf node_modules
```

Puis redémarrez votre serveur FiveM.

### Le HUD ne se désactive pas

Vérifiez que `null-core` est bien chargé et que l'export `DisplayHud` existe.

### Les images sont corrompues

- Augmentez `Config.ScreenshotDelay` à 1000ms
- Vérifiez que screenshot-basic fonctionne correctement

### Le processeur Node.js crash

- Vérifiez que vous avez assez de RAM disponible
- Réinstallez les dépendances : `npm install --force`

### Les images ne sont pas détourées

- Vérifiez que le modèle IA s'est bien téléchargé
- Essayez de redémarrer le processeur Node.js

### Erreur "Cannot find module"

```bash
cd resources/[addon]/null-imagemaker/
rm -rf node_modules package-lock.json
npm install
```

## 📝 Notes importantes

- **Ne fermez pas le processeur Node.js** pendant la génération
- Les fichiers dans `raw_images/` sont **automatiquement supprimés** après traitement
- Les images finales sont nommées par leur **ID** (0.png, 1.png, etc.)
- Le script gère automatiquement les **différences male/female** pour les cheveux

## 🎨 Utilisation des icônes

Une fois générées, utilisez les icônes dans votre inventaire :

```lua
-- Exemple pour un item
['hair_item'] = {
    label = 'Coiffure #5',
    weight = 0,
    icon = 'nui://null-imagemaker/images/hair/male/5.png'
}
```

## 📄 Licence

MIT License - null © 2024

## 🤝 Support

Pour toute question ou problème, contactez l'équipe null.

---

**Développé avec ❤️ par null**
