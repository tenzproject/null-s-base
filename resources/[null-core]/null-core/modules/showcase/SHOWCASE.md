# Mode Showcase (base de test / vitrine)

Active une variante "vitrine" de la base, **sans toucher aux serveurs normaux**
(tout est inerte si le convar est absent).

## Activation — `server.cfg` de CE serveur uniquement

```cfg
# Active le mode showcase
setr Null_showcase "true"
```

`setr` = replicated → lisible côté client ET serveur.

## Base de données séparée

Pour ne pas lier ce serveur à tes autres serveurs, utilise une DB dédiée.

```bash
# 1. Dumper le SCHÉMA de ta base actuelle (structure seule)
mysqldump -u USER -p --no-data --routines NOM_DB_ACTUELLE > showcase_schema.sql

# 2. Créer la nouvelle base
mysql -u USER -p -e "CREATE DATABASE Null_showcase CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;"

# 3. Importer le schéma dans la nouvelle base
mysql -u USER -p Null_showcase < showcase_schema.sql
```

Puis, dans le `server.cfg` de CE serveur **uniquement** :

```cfg
set mysql_connection_string "mysql://USER:PASSWORD@127.0.0.1/Null_showcase?charset=utf8mb4"
setr Null_showcase "true"
```

> Astuce : si tu veux quelques données de base (jobs, sociétés, configs en DB),
> remplace `--no-data` par un dump complet des tables voulues.

## Ce que le mode showcase fait

- **Écran de bienvenue** à chaque connexion (overlay plein écran, vignette
  radiale noire, thème + logo/nom serveur) : prévient base de test, aucun
  mapping/pack vêtements/pack véhicules, perms + menu dédié, demande de
  prudence, version + date de MAJ.
- **Tablette showcaser** via `/showcase` : se setgroup, se wipe, se register
  (uniquement sur soi-même).
- **Auto-setup** : groupe `autoGroup` attribué à la 1re connexion.
- **Watermark** permanent « BASE DE TEST · vX.Y ».
- **Restrictions** : `/wipe` et `/register` forcés sur soi ; `/ban`, `/jail`,
  `/bring`, `/back` bloqués sur autrui ; impossible de tuer les autres joueurs ;
  menu « Wipe Avancé » masqué.

## Config

`configs/modules/showcase/shared/main.lua` : version, date de MAJ, commande,
liste de groupes, groupe auto, anti-kill.
