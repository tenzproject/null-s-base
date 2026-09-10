/**
 * Configuration centrale des modules HUD éditables
 * Chaque module représente un élément UI qui peut être déplacé et configuré
 */

export interface Position {
  x: number; // Pourcentage (0-100)
  y: number; // Pourcentage (0-100)
}

export interface Size {
  width: number; // Pourcentage (0-100)
  height: number; // Pourcentage (0-100)
}

export type AnchorPoint = 'top-left' | 'top-center' | 'top-right' | 'center-left' | 'center' | 'center-right' | 'bottom-left' | 'bottom-center' | 'bottom-right';

export interface HUDModule {
  id: string;
  name: string;
  description: string;
  category: 'Info' | 'Interaction' | 'Menu' | 'Notification' | 'Status' | 'HUD';
  defaultPosition: Position;
  defaultSize: Size;
  anchor: AnchorPoint; // Point d'ancrage pour le positionnement
  isResizable: boolean;
  defaultEnabled: boolean;
  isDraggable: boolean; // Si false, le module est config-only (pas de preview déplaçable)
  colors?: any; // Configuration colors (for runtime state passing)
  parentId?: string; // ID du module parent (pour les sous-modules)
  isSubModule?: boolean; // Si true, c'est un sous-module
  disableAutoAnchor?: boolean; // Si true, désactive le calcul automatique de l'anchor
  alwaysEnabled?: boolean; // Si true, le module ne peut pas être désactivé par l'utilisateur
}

export const HUD_MODULES: HUDModule[] = [
  {
    id: 'info_dialog',
    name: 'Informations',
    description: 'Affiche les informations importantes (argent, niveau, etc.)',
    category: 'Info',
    defaultPosition: { x: 99, y: 50 },
    defaultSize: { width: 0, height: 0 },
    anchor: 'center-right',
    isResizable: false,
    defaultEnabled: false,
    isDraggable: true,
  },
  {
    id: 'info_dialog_staff',
    name: 'Informations Staff',
    description: 'Affiche les informations staff (joueurs, reports, etc.)',
    category: 'Info',
    defaultPosition: { x: 50, y: 1 },
    defaultSize: { width: 0, height: 0 },
    anchor: 'top-center',
    isResizable: false,
    defaultEnabled: false,
    isDraggable: true,
  },
  {
    id: 'menu',
    name: 'Menu',
    description: 'Menu principal d\'interaction',
    category: 'Menu',
    defaultPosition: { x: 1, y: 8 },
    defaultSize: { width: 0, height: 0 },
    anchor: 'top-left',
    isResizable: false,
    defaultEnabled: true,
    isDraggable: true,
    disableAutoAnchor: true,
  },
  {
    id: 'announcement',
    name: 'Annonces',
    description: 'Annonces serveur et notifications importantes',
    category: 'Notification',
    defaultPosition: { x: 50, y: 10 },
    defaultSize: { width: 0, height: 0 },
    anchor: 'top-center',
    isResizable: false,
    defaultEnabled: false,
    isDraggable: true,
  },
  {
    id: 'status_bars',
    name: 'Barres de Statut',
    description: 'Configuration globale des barres de statut',
    category: 'HUD',
    defaultPosition: { x: 0, y: 100 },
    defaultSize: { width: 0, height: 0 },
    anchor: 'top-left',
    isResizable: false,
    defaultEnabled: true,
    isDraggable: false,
  },
  {
    id: 'status_bar_mic',
    name: 'Micro',
    description: 'Indicateur de micro',
    category: 'Status',
    defaultPosition: { x: 0.95, y: 99.3 },
    defaultSize: { width: 0, height: 0 },
    anchor: 'bottom-left',
    isResizable: false,
    defaultEnabled: true,
    isDraggable: true,
    parentId: 'status_bars',
    isSubModule: true,
  },
  {
    id: 'status_bar_health',
    name: 'Santé',
    description: 'Barre de santé',
    category: 'Status',
    defaultPosition: { x: 3.75, y: 99.3 },
    defaultSize: { width: 0, height: 0 },
    anchor: 'bottom-left',
    isResizable: false,
    defaultEnabled: true,
    isDraggable: true,
    parentId: 'status_bars',
    isSubModule: true,
  },
  {
    id: 'status_bar_armor',
    name: 'Armure',
    description: 'Barre d\'armure',
    category: 'Status',
    defaultPosition: { x: 6.55, y: 99.3 },
    defaultSize: { width: 0, height: 0 },
    anchor: 'bottom-left',
    isResizable: false,
    defaultEnabled: true,
    isDraggable: true,
    parentId: 'status_bars',
    isSubModule: true,
  },
  {
    id: 'status_bar_hunger',
    name: 'Faim',
    description: 'Barre de faim',
    category: 'Status',
    defaultPosition: { x: 9.34, y: 99.3 },
    defaultSize: { width: 0, height: 0 },
    anchor: 'bottom-left',
    isResizable: false,
    defaultEnabled: true,
    isDraggable: true,
    parentId: 'status_bars',
    isSubModule: true,
  },
  {
    id: 'status_bar_thirst',
    name: 'Soif',
    description: 'Barre de soif',
    category: 'Status',
    defaultPosition: { x: 12.15, y: 99.3 },
    defaultSize: { width: 0, height: 0 },
    anchor: 'bottom-left',
    isResizable: false,
    defaultEnabled: true,
    isDraggable: true,
    parentId: 'status_bars',
    isSubModule: true,
  },
  {
    id: 'status_bar_stamina',
    name: 'Stamina',
    description: 'Barre de stamina',
    category: 'Status',
    defaultPosition: { x: 14.95, y: 99.3 },
    defaultSize: { width: 0, height: 0 },
    anchor: 'bottom-left',
    isResizable: false,
    defaultEnabled: true,
    isDraggable: true,
    parentId: 'status_bars',
    isSubModule: true,
  },
  {
    id: 'status_bar_oxygen',
    name: 'Oxygène',
    description: 'Barre d\'oxygène (sous l\'eau)',
    category: 'Status',
    defaultPosition: { x: 17.75, y: 99.3 },
    defaultSize: { width: 0, height: 0 },
    anchor: 'bottom-left',
    isResizable: false,
    defaultEnabled: true,
    isDraggable: true,
    parentId: 'status_bars',
    isSubModule: true,
  },
  {
    id: 'speedometer',
    name: 'Compteur de Vitesse',
    description: 'Affiche la vitesse, RPM, carburant et indicateurs véhicule (hologramme 3D ou 2D classique)',
    category: 'HUD',
    defaultPosition: { x: 100, y: 100 },
    defaultSize: { width: 0, height: 0 },
    anchor: 'bottom-right',
    isResizable: false,
    defaultEnabled: true,
    isDraggable: true,
  },
  {
    id: 'ammo',
    name: 'Munitions',
    description: 'Affiche les munitions de l\'arme équipée (hologramme 3D ou 2D à côté de la minimap)',
    category: 'HUD',
    defaultPosition: { x: 50, y: 99 },
    defaultSize: { width: 0, height: 0 },
    anchor: 'bottom-center',
    isResizable: false,
    defaultEnabled: true,
    isDraggable: true,
  },
  {
    id: 'input_dialog',
    name: 'Saisie',
    description: 'Dialogue de saisie utilisateur',
    category: 'Interaction',
    defaultPosition: { x: 50, y: 50 },
    defaultSize: { width: 0, height: 0 },
    anchor: 'center',
    isResizable: false,
    defaultEnabled: false,
    isDraggable: false, // Config-only, pas de preview déplaçable
  },
  {
    id: 'confirm_dialog',
    name: 'Confirmation',
    description: 'Dialogue de confirmation',
    category: 'Interaction',
    defaultPosition: { x: 50, y: 50 },
    defaultSize: { width: 0, height: 0 },
    anchor: 'center',
    isResizable: false,
    defaultEnabled: false,
    isDraggable: false, // Config-only, pas de preview déplaçable
  },
  {
    id: 'minimap',
    name: 'Carte',
    description: 'Minimap avec choix du style (ronde/carrée) et visibilité',
    category: 'HUD',
    defaultPosition: { x: 1, y: 95 },
    defaultSize: { width: 0, height: 0 },
    anchor: 'bottom-left',
    isResizable: false,
    defaultEnabled: true,
    isDraggable: true,
  },
  {
    id: 'notifications',
    name: 'Notifications',
    description: 'Système de notifications (standard, advanced, accept)',
    category: 'Notification',
    defaultPosition: { x: 1, y: 75 },
    defaultSize: { width: 0, height: 0 },
    anchor: 'bottom-left',
    isResizable: false,
    defaultEnabled: true,
    isDraggable: true,
  },
  {
    id: 'inventory_notifications',
    name: 'Notifications Inventaire',
    description: 'Affiche les items reçus ou perdus (icône + quantité animée)',
    category: 'Notification',
    defaultPosition: { x: 50, y: 94 },
    defaultSize: { width: 0, height: 0 },
    anchor: 'bottom-center',
    isResizable: false,
    defaultEnabled: true,
    isDraggable: true,
  },
  {
    id: 'chat',
    name: 'Chat',
    description: 'Système de chat avec commandes et suggestions',
    category: 'Interaction',
    defaultPosition: { x: 99, y: 15 },
    defaultSize: { width: 0, height: 0 },
    anchor: 'top-right',
    isResizable: false,
    defaultEnabled: true,
    isDraggable: true,
  },
  {
    id: 'progress_bar',
    name: 'Barre de Progression',
    description: 'Barre de progression pour les actions',
    category: 'HUD',
    defaultPosition: { x: 50, y: 75 },
    defaultSize: { width: 0, height: 0 },
    anchor: 'bottom-center',
    isResizable: false,
    defaultEnabled: true,
    isDraggable: true,
  },
  {
    id: 'context_menu',
    name: 'Menu Contextuel',
    description: 'Menu contextuel pour les interactions (config uniquement)',
    category: 'Menu',
    defaultPosition: { x: 50, y: 50 },
    defaultSize: { width: 0, height: 0 },
    anchor: 'center',
    isResizable: false,
    defaultEnabled: true,
    isDraggable: false, // Config only, no draggable preview
  },
  {
    id: 'player_info',
    name: 'Infos Joueur',
    description: 'Affiche le logo serveur, nom du serveur, argent propre/sale, identité et IDs',
    category: 'HUD',
    defaultPosition: { x: 99, y: 1 },
    defaultSize: { width: 0, height: 0 },
    anchor: 'top-right',
    isResizable: false,
    defaultEnabled: true,
    isDraggable: true,
  },
  {
    id: 'help_notification',
    name: 'Aide contextuelle',
    description: 'Remplace l\'aide native (ESX.ShowHelpNotification) par un bandeau stylisé avec badge de touche',
    category: 'Notification',
    defaultPosition: { x: 1, y: 1 },
    defaultSize: { width: 0, height: 0 },
    anchor: 'top-left',
    isResizable: false,
    defaultEnabled: true,
    isDraggable: true,
  },
  {
    id: 'indicator',
    name: 'Indicateurs',
    description: 'Pictogrammes d\'état (zone protégée, zone hostile, etc.)',
    category: 'Status',
    defaultPosition: { x: 99, y: 2 },
    defaultSize: { width: 0, height: 0 },
    anchor: 'top-right',
    isResizable: false,
    defaultEnabled: true,
    isDraggable: true,
  },
  {
    id: 'ui_3d',
    name: '3D UI (Hologrammes)',
    description: 'Configuration globale des interfaces 3D holographiques (munitions, compteur de vitesse)',
    category: 'HUD',
    defaultPosition: { x: 50, y: 50 },
    defaultSize: { width: 0, height: 0 },
    anchor: 'center',
    isResizable: false,
    defaultEnabled: true,
    isDraggable: false, // Config-only
  },
];

export interface HUDModuleState {
  id: string;
  position: Position;
  size: Size;
  enabled: boolean;
  anchor: AnchorPoint;
  colors?: any;
  manualAnchor?: boolean; // Si true, l'anchor a été défini manuellement (ne pas recalculer)
}

export function getDefaultModuleStates(): Map<string, HUDModuleState> {
  const states = new Map<string, HUDModuleState>();

  HUD_MODULES.forEach((module) => {
    states.set(module.id, {
      id: module.id,
      enabled: module.defaultEnabled,
      position: { ...module.defaultPosition },
      size: { ...module.defaultSize },
      anchor: module.anchor,
    });
  });

  return states;
}
