export interface InventoryItem {
  id?: number;
  name: string;
  label: string;
  count: number;
  type: 'item' | 'weapon' | 'accessory' | 'account';
  type2?: string;
  weight?: number;
  rare?: boolean;
  canUse?: boolean;
  canRemove?: boolean;
  usable?: boolean;
  unique?: boolean;
  slot?: number;
  metadata?: Record<string, any>;
  extra?: Record<string, any>;
  data?: Record<string, any>;
  durability?: number;
  permanent?: boolean;
  serialnumber?: string;
  ammo?: number;
  description?: string;
}

export interface InventoryData {
  playerSex: 'male' | 'female';
  leftInventory: InventoryItem[];
  rightInventory: InventoryItem[];
  leftTitle: string;
  rightTitle: string;
  leftWeight: number;
  leftMaxWeight: number;
  rightWeight: number;
  rightMaxWeight: number;
  rightDisabled: boolean;
  rightVisible: boolean;
  shortcuts: (InventoryItem | null)[];
  accessories: Record<string, InventoryItem | null>;
  stats: PlayerStats;
}

/* ---- Hub types (right panel default) ---- */
export type HubPage = 'home' | 'settings' | 'craft' | 'outfits' | 'backpack' | 'allitems' | 'chest' | 'entreprises' | 'metabolism';

/* ---- Metabolism (nutrition) types ---- */
export interface MetabolismData {
  score: number;        // 0-100, moyenne pondérée hydration+fitness
  hydration: number;   // 0-100
  fitness: number;     // 0-100
  bodyweight: number;  // kg, caché (jamais affiché)
  neutralBW: number;   // kg de référence
  effects: {
    sprint:  { min: number; max: number };
    stamina: { min: number; max: number };
    regen:   { min: number; max: number };
  };
}

export interface SocietyInfo {
  name: string;
  label: string;
  type: string;
  state: boolean;
  logo?: string;
  description?: string;
  brandColor?: string;
  hasPosition?: boolean;
}

export interface HubLink {
  id: string;
  label: string;
  icon: string;
  action: string;
  color?: string;
}

export interface CraftRecipe {
  id: string;
  item: string;
  label: string;
  description?: string;
  icon?: string;
  time: number;
  type?: 'item' | 'weapon';
  category?: string;
  requirements: CraftRequirement[];
  isLegacyWeaponCraft?: boolean;
  tableId?: string;
  tableBased?: boolean;
}

export interface CraftRequirement {
  label: string;
  itemName: string;
  icon?: string;
  amount: number;
  have?: number;
}

export interface SettingDef {
  id: string;
  label: string;
  description?: string;
  type: 'toggle' | 'slider' | 'select';
  value: any;
  options?: { label: string; value: any }[];
  min?: number;
  max?: number;
  step?: number;
}

/* ---- Options menu types (from F5 personal menu) ---- */
export interface WalkStyle {
  name: string;
  clipSet: string;
}

export interface BlipOption {
  label: string;
  kvpName: string;
  category: string;
  enabled: boolean;
}

export interface PreferenceOption {
  id: string;
  label: string;
  description?: string;
  enabled: boolean;
  category?: string; // fight, vehicle, ui, or undefined (root)
}

export interface OptionsData {
  walkStyles: WalkStyle[];
  currentWalk: string;
  blips: BlipOption[];
  preferences: PreferenceOption[];
}

export type OptionsCategory = 'demarche' | 'blips' | 'combat' | 'affichage' | 'vehicules' | 'autre';

export interface PlayerStats {
  health?: number;
  hunger?: number;
  thirst?: number;
  oxygen?: number;
  stamina?: number;
  stress?: number;
  alcohol?: number;
  drug?: number;
}

export type FilterType = 'all' | 'weapon' | 'clothes' | 'food';

/* ---- Outfit System types ---- */
export interface OutfitPiece {
  id: number;
  name: string;
  label: string;
  type: string;
  data?: Record<string, any>;
}

export interface OutfitHubData {
  clothesByType: Record<string, OutfitPiece[]>;
}

/* ---- Backpack System types ---- */
export interface BackpackData {
  hasBag: boolean;
  bagId?: number | string;
  bagName?: string;
  items?: InventoryItem[];
  weight?: number;
  maxWeight?: number;
}

export interface BackpackPreview {
  itemCount: number;
  weaponCount: number;
  cash: number;
  dirtycash: number;
  weight: number;
  maxWeight: number;
}

export interface BagConfig {
  weight: number;
  weapon: boolean;
}

// bagInfo is keyed by bags_1 value (number) → BagConfig
export type BagInfoMap = Record<string, BagConfig>;

export function isBagItem(item: InventoryItem): boolean {
  return item.type === 'accessory' && item.type2 === 'bag';
}

export function getBagValue(item: InventoryItem): number | null {
  if (!isBagItem(item) || !item.data) return null;
  const v = item.data['bags_1'];
  return typeof v === 'number' ? v : null;
}

export function getBagMaxWeight(item: InventoryItem, bagInfo: BagInfoMap, defaultWeight = 15): number {
  const v = getBagValue(item);
  if (v === null) return defaultWeight;
  const cfg = bagInfo[String(v)];
  return cfg?.weight ?? defaultWeight;
}

/* ---- Outfit slot labels ---- */
export const OUTFIT_SLOT_LABELS: Record<string, string> = {
  top: 'Haut',
  pants: 'Pantalon',
  shoes: 'Chaussures',
  mask: 'Masque',
  glasses: 'Lunettes',
  hat: 'Chapeau',
  bag: 'Sac',
  gillet: 'Gilet',
  bracelet: 'Bracelet',
  ear: 'Boucles',
  watch: 'Montre',
  neck: 'Collier',
};

export interface AccessorySlotDef {
  key: string;
  label: string;
  icon: string;
  dataKey: string;
  placeholderImg: string;
  side: 'left' | 'right';
}

export const ACCESSORY_SLOTS: AccessorySlotDef[] = [
  { key: 'hat', label: 'Chapeau', icon: '🎩', dataKey: 'helmet_1', placeholderImg: 'casquette.webp', side: 'left' },
  { key: 'neck', label: 'Collier', icon: '�', dataKey: 'chain_1', placeholderImg: 'collier-medaille.webp', side: 'left' },
  { key: 'top', label: 'Haut', icon: '�', dataKey: 'torso_1', placeholderImg: 't-shirt.webp', side: 'left' },
  { key: 'pants', label: 'Pantalon', icon: '�', dataKey: 'pants_1', placeholderImg: 'trousers.webp', side: 'left' },
  { key: 'shoes', label: 'Chaussures', icon: '�', dataKey: 'shoes_1', placeholderImg: 'sport-shoe.webp', side: 'left' },
  { key: 'bag', label: 'Sac', icon: '🎒', dataKey: 'bags_1', placeholderImg: 'bagpack.webp', side: 'left' },
  { key: 'mask', label: 'Masque', icon: '🎭', dataKey: 'mask_1', placeholderImg: 'masque.webp', side: 'right' },
  { key: 'glasses', label: 'Lunettes', icon: '�️', dataKey: 'glasses_1', placeholderImg: 'lunettes.webp', side: 'right' },
  { key: 'ear', label: 'Boucles', icon: '💎', dataKey: 'ears_1', placeholderImg: 'boucles-doreilles.webp', side: 'right' },
  { key: 'bracelet', label: 'Bracelet', icon: '⌚', dataKey: 'bracelets_1', placeholderImg: 'bracelet.webp', side: 'right' },
  { key: 'watch', label: 'Montre', icon: '⏱️', dataKey: 'watches_1', placeholderImg: 'montre.webp', side: 'right' },
  { key: 'gillet', label: 'Gilet', icon: '🦺', dataKey: 'bproof_1', placeholderImg: 'gilet.webp', side: 'right' },
];

export function getAccessoryDataKey(type2: string): string {
  // First try direct match with key
  let slot = ACCESSORY_SLOTS.find(s => s.key === type2);
  
  // If not found, try matching with dataKey (in case type2 is already a dataKey like "pants_1")
  if (!slot) {
    slot = ACCESSORY_SLOTS.find(s => s.dataKey === type2);
  }
  
  // If still not found, try removing _1 suffix and matching with key
  if (!slot && type2.endsWith('_1')) {
    const baseKey = type2.slice(0, -2); // Remove "_1"
    slot = ACCESSORY_SLOTS.find(s => s.key === baseKey);
  }
  
  return slot?.dataKey || 'torso_1';
}

// Map dataKey (bproof_1, helmet_1, etc.) to slot key (gillet, hat, etc.)
export function getAccessorySlotKey(dataKey: string): string {
  const slot = ACCESSORY_SLOTS.find(s => s.dataKey === dataKey);
  return slot?.key || dataKey;
}

// Map any type2 value (key, dataKey, or label) to dataKey
export function normalizeToDataKey(type2: string): string {
  if (!type2) return 'torso_1';
  
  // Already a dataKey (contains '_')
  if (type2.includes('_')) {
    return type2;
  }
  
  // Try to find by key first
  let slot = ACCESSORY_SLOTS.find(s => s.key === type2);
  if (slot) return slot.dataKey;
  
  // Try to find by label (case-insensitive)
  slot = ACCESSORY_SLOTS.find(s => s.label.toLowerCase() === type2.toLowerCase());
  if (slot) return slot.dataKey;
  
  // Default fallback
  return 'torso_1';
}
