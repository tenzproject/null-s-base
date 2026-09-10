# Debug Menu — Mode Développement

## Activation

Le Debug Menu est **automatiquement activé** quand vous lancez le projet en mode développement avec `npm run dev`.

Détection : `window.location.hostname === 'localhost'` ou `'127.0.0.1'`

## Utilisation

### Ouvrir/Fermer
- **Touche F8** — Toggle le menu debug

### Fonctionnalités

Le menu permet d'ouvrir n'importe quel module UI avec des données mockées :

#### UI Modules
- **Banque** — Compte avec transactions, crédits, virements en attente
- **Garage** — Liste de véhicules (Adder, T20)
- **Magasin** — Mode vêtements avec catégories
- **Inventaire** — Items de base (pain, eau, téléphone)
- **Créateur** — Création de personnage
- **Auto-école** — Permis disponibles

#### Tablettes
- **Boutique** — Shop quotidien avec véhicules/armes
- **Tablette Illégale** — Gang "Les Ballas" niveau 15
- **Règlement** — Règles du serveur

### Données Mock

Chaque module reçoit des données réalistes générées automatiquement :
- Transactions bancaires avec catégories
- Véhicules avec plaques, modèles, états
- Inventaire avec poids et items utilisables
- Gang avec XP, niveau, couleur personnalisée

### Onglets

- **Tout** — Tous les modules
- **UI Modules** — Interfaces principales (bank, garage, shop, etc.)
- **Tablettes** — Interfaces tablette (boutique, illégale, règlement)

## Développement

Pour ajouter un nouveau module au debug menu :

1. Ouvrir `src/modules/debug/DebugMenu.tsx`
2. Ajouter le module dans `uiModules` ou `tabletModules`
3. Créer la fonction mock data dans `generateMockData()`

```typescript
{
  id: 'monmodule',
  label: 'Mon Module',
  icon: <MonIcon size={18} />,
  color: '#3b82f6',
  action: () => openModule('monmodule'),
}
```

## Production

En production (build), le Debug Menu **n'est pas inclus** dans le bundle final grâce à la condition `{isDev && <DebugMenu />}`.
