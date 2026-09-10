export interface BoutiqueItem {
  id: string;
  label: string;
  description?: string;
  price: number;
  image?: string;
  category: 'vehicle' | 'weapon' | 'pack' | 'boost' | 'crate';
  tags?: string[];
  buyable?: boolean;
  // Vehicle specific
  model?: string;
  stats?: Record<string, number>;
  // Weapon specific
  name?: string;
  // Pack specific
  info?: any;
  info2?: Record<string, string>;
  // Boost specific
  time?: number;
  activeBoost?: Record<string, number>;
  // Crate specific
  inside?: CrateItem[];
  five?: number;
  teen?: number;
  preview?: boolean;
}

export interface CrateItem {
  model: string;
  typeLot: string;
  label: string;
  rarity: number; // 1=common, 2=rare, 3=legendary, 4=ultimate
  amount?: number;
}

export type RarityLevel = 'common' | 'rare' | 'epic' | 'legendary' | 'ultimate';

export interface DailyShopItem {
  id: string;
  label: string;
  description?: string;
  price: number;
  originalPrice?: number;
  image?: string;
  type: 'vehicle' | 'weapon';
  model?: string;
  name?: string;
  stats?: Record<string, number>;
  rarity: RarityLevel;
  discount?: number;
}

export interface UserInfo {
  coins: number;
  history?: PurchaseHistory[];
  fidelity?: number;
  fidelityTotal?: number;
}

export interface PurchaseHistory {
  id: string;
  label: string;
  price: number;
  date: string;
  category: string;
  isCredit?: boolean;
}

export type BoutiquePage = 'home' | 'daily' | 'vehicles' | 'weapons' | 'packs' | 'boosts' | 'crates' | 'customization' | 'nightmarket' | 'history' | 'vip' | 'battlepass';

// ============================================================================
// VIP TYPES
// ============================================================================
export interface VIPAdvantageInfo {
  key: string;
  label: string;
  desc: string;
  icon: string;
  basic: boolean | string;
  premium: boolean | string;
  default?: string;
}

export interface VIPTierConfig {
  level: number;
  label: string;
  color: string;
  icon: string;
  price: number;
  durationDays: number;
}

export interface VIPData {
  isVip: boolean;
  type?: string;
  time?: { days: number; hours: number; minutes: number; remaining: number };
  advantages: VIPAdvantageInfo[];
}

// ============================================================================
// BATTLE PASS TYPES
// ============================================================================
export interface BPReward {
  type: 'money' | 'item' | 'weapon' | 'vehicle' | 'coins' | 'crate';
  label: string;
  amount?: number;
  name?: string;
  model?: string;
  ammo?: number;
  permanent?: boolean;
}

export interface BPRewardLevel {
  level: number;
  free: BPReward | null;
  premium: BPReward | null;
}

export interface BPSeasonInfo {
  id: string;
  name: string;
  startDate: number;
  endDate: number;
  active: boolean;
  timeLeft: number;
}

export interface BattlePassData {
  level: number;
  xp: number;
  requiredXP: number;
  maxLevel: number;
  claimedFree: number[];
  claimedPremium: number[];
  hasPremium: boolean;
  season: BPSeasonInfo | null;
  rewards: BPRewardLevel[];
}

export interface NightMarketCard {
  id: string;
  label: string;
  description?: string;
  price: number;
  originalPrice: number;
  discount: number;
  type: 'vehicle' | 'weapon';
  model?: string;
  name?: string;
  rarity: RarityLevel;
  revealed: boolean;
}

export interface PlayerWeaponSummary {
  name: string;
  label: string;
  componentCount: number;
  installedCount: number;
}

export interface BoutiqueProps {
  visible: boolean;
  onClose: () => void;
  primaryColor: string;
  serverConfig: {
    serverName: string;
    serverColor: string;
    serverIcon: string;
    serverDiscord: string;
  };
}
