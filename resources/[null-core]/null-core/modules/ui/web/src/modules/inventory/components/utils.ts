import { InventoryItem, getAccessoryDataKey } from '../types';
import { cacheImg } from '@shared/cacheVersion';

export const GetParentResourceName = () => 'null-core';
export const getFallbackImg = () => cacheImg('items/box.png');

export const nuiCallback = async (event: string, data: Record<string, any> = {}) => {
  try {
    const resp = await fetch(`https://${GetParentResourceName()}/${event}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data),
    });
    return await resp.json();
  } catch (e) {
    return null;
  }
};

export const TYPE_LABELS: Record<string, string> = {
  item: 'Objet',
  weapon: 'Arme',
  accessory: 'Vêtement',
  account: 'Compte',
  cash: 'Argent',
  dirtycash: 'Argent Sale',
};

export const getItemImageSrc = (
  item: InventoryItem,
  playerSex: 'male' | 'female',
  failedImages: Set<string>
): string => {
  const key = `${item.type}-${item.name}-${item.type2 || ''}`;
  if (failedImages.has(key)) return getFallbackImg();
  if (item.type === 'accessory' && item.type2 === 'outfit') {
    return cacheImg('items/outfit.webp');
  }
  if (item.type === 'accessory' && item.data) {
    const dataKey = getAccessoryDataKey(item.type2 || '');
    const value = item.data[dataKey] !== undefined ? item.data[dataKey] : 0;
    return cacheImg(`clothes/${playerSex}/${dataKey}/${value}.webp`);
  }
  // if (item.type === 'item' && KEVLAR_BPROOF[item.name]) {
  //   const bpVal = playerSex === 'male' ? KEVLAR_BPROOF[item.name].male : KEVLAR_BPROOF[item.name].female;
  //   return cacheImg(`clothes/${playerSex}/bproof_1/${bpVal}.webp`);
  // }
  return cacheImg(`items/${item.name}.webp`);
};

export const LICENSE_ITEM_NAMES = new Set(['identity_card', 'drive', 'weapon']);

export const isLicenseItem = (item: InventoryItem): boolean =>
  item.type === 'item' && LICENSE_ITEM_NAMES.has(item.name) && !!item.metadata?.firstname;

export const LICENSE_TYPE_LABELS: Record<string, string> = {
  identity_card: "Carte d'identité",
  drive: 'Permis de conduire',
  weapon: "Port d'arme",
};

export const LICENSE_CATEGORY_LABELS: Record<string, string> = {
  drive: 'Voiture',
  drive_bike: 'Moto',
  drive_truck: 'Camion',
  weapon: 'Arme légère',
  weapon2: 'Arme lourde',
};

/* ---- Kevlar helpers ---- */
export const KEVLAR_ITEM_NAMES = new Set(['kevlar_light', 'kevlar_medium', 'kevlar_heavy']);

// Bproof clothing values per kevlar type per sex (matches Config.Kevlar.Items in Lua)
export const KEVLAR_BPROOF: Record<string, { male: number; female: number }> = {
  kevlar_light: { male: 16, female: 16 },
  kevlar_medium: { male: 2, female: 2 },
  kevlar_heavy: { male: 14, female: 14 },
};

export const isKevlarItem = (item: InventoryItem): boolean =>
  item.type === 'item' && KEVLAR_ITEM_NAMES.has(item.name);

export const KEVLAR_TYPE_LABELS: Record<string, string> = {
  kevlar_light: 'Kevlar Léger',
  kevlar_medium: 'Kevlar Standard',
  kevlar_heavy: 'Kevlar Lourd',
};

export const KEVLAR_TYPE_COLORS: Record<string, string> = {
  kevlar_light: '#3b82f6',
  kevlar_medium: '#f59e0b',
  kevlar_heavy: '#ef4444',
};

export const getKevlarDurability = (item: InventoryItem): { current: number; max: number; pct: number } => {
  const dur = item.metadata?.durability ?? 0;
  const maxDur = item.metadata?.maxDurability ?? 100;
  const pct = maxDur > 0 ? Math.round((dur / maxDur) * 100) : 0;
  return { current: dur, max: maxDur, pct };
};

export const getKevlarProtection = (item: InventoryItem): number =>
  item.metadata?.maxArmor ?? 0;

export const handleImgError = (
  e: React.SyntheticEvent<HTMLImageElement>,
  item: InventoryItem,
  failedImages: Set<string>
) => {
  const el = e.target as HTMLImageElement;
  const key = `${item.type}-${item.name}-${item.type2 || ''}`;
  if (!failedImages.has(key)) {
    failedImages.add(key);
    el.src = getFallbackImg();
  }
};
