export type TabletPage = 'home' | 'members' | 'ranks' | 'missions' | 'ranking' | 'territories' | 'actions' | 'blackmarket' | 'createGroup';

export interface GangTier {
  name: string;
  description: string;
  specialization: string;
  color: string;
}

export interface CreateGroupData {
  mode: 'createGroup';
  gangTiers: Record<number, GangTier>;
  groupCreation: {
    enabled: boolean;
    price: number;
    minNameLength: number;
    maxNameLength: number;
    minLabelLength: number;
    maxLabelLength: number;
  };
}

export interface TabletMission {
  id: string;
  label: string;
  description: string;
  category: string;
  xp: number;
  objective: number;
  progress: number;
  completed: boolean;
  claimed: boolean;
  acceptedBy: string | null;
}

export interface TabletMember {
  idunique: string;
  firstname: string;
  lastname: string;
  grade: number;
  gradeLabel: string;
  online: boolean;
}

export interface TabletGrade {
  grade: number;
  name: string;
  label: string;
}

export interface TabletPermissions {
  perms_coffre: Record<string, boolean>;
  perms_recruter: Record<string, boolean>;
  perms_promouvoir: Record<string, boolean>;
  perms_gestionmembre: Record<string, boolean>;
  perms_vente: Record<string, boolean>;
  perms_fabrication: Record<string, boolean>;
}

export interface TabletRankingEntry {
  name: string;
  label: string;
  level: number;
  xp: number;
  tier: number;
  totalTerritoriesWon: number;
  memberCount: number;
}

export interface TabletTerritory {
  id: number;
  name: string;
  owner: string;
  ownerLabel: string;
  ownerCount: number;
  active: boolean;
  data: Record<string, { count: number }>;
}

export interface TabletUnlock {
  level: number;
  type: string;
  value: number | boolean;
  description: string;
}

export interface GroupStats {
  criminalité: number;
  confiance: number;
  honneur: number;
  morale: number;
}

export interface DirtyMoneyStats {
  today: number;
  week: number;
  month: number;
  total: number;
}

export interface BlackmarketItem {
  id: string;
  name: string;
  label: string;
  basePrice: number;
  price: number;
}

export interface BlackmarketData {
  unlocked: boolean;
  discount?: number;
  weapons?: BlackmarketItem[];
  items?: BlackmarketItem[];
}

export interface TabletData {
  gangname: string;
  ganglabel: string;
  gangcolor: string;
  tier: number;
  gangTiers: Record<number, GangTier>;
  level: number;
  xp: number;
  requiredXP: number;
  maxLevel: number;
  memberCount: number;
  maxMembers: number;
  maxRanks: number;
  blackmarketDiscount: number;
  hasWeaponSell: boolean;
  hasWeaponCraft: boolean;
  members: TabletMember[];
  grades: TabletGrade[];
  permissions: TabletPermissions;
  missions: {
    daily: TabletMission[];
    weekly: TabletMission[];
  };
  ranking: TabletRankingEntry[];
  territories: Record<string, TabletTerritory>;
  ownedTerritories: number;
  totalTerritoriesWon: number;
  nextUnlocks: TabletUnlock[];
  unlocks: Record<string, number | boolean>;
  playerGrade: number;
  playerGradeName: string;
  isBoss: boolean;
  kitArme: number | boolean;
  fabArme: number | boolean;
  groupStats: GroupStats;
  dirtyMoney: DirtyMoneyStats;
  blackmarket: BlackmarketData | null;
}
