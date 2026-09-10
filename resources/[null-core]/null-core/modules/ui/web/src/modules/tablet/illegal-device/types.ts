export interface DeviceDifficulty {
  id: 'easy' | 'medium' | 'expert' | string;
  label: string;
  description: string;
  distance: number;
  payment: [number, number];
}

export interface DeviceConfig {
  difficulties: DeviceDifficulty[];
}

export interface DeviceMission {
  id: string;
  difficulty: string;
  difficultyLabel: string;
  payment: number;
}

export interface DeviceStatus {
  active?: boolean;
  cooldown?: number;
  mission?: DeviceMission;
}

export interface IllegalDeviceProps {
  visible: boolean;
  onClose: () => void;
  primaryColor: string;
}

export interface MarketItem {
  id: string;
  name: string;
  label: string;
  basePrice: number;
  price: number;
}

export interface MarketData {
  unlocked: boolean;
  discount?: number;
  weapons?: MarketItem[];
  items?: MarketItem[];
}

export interface TerritoryPoint { x: number; y: number; }

export interface Territory {
  id: number | string;
  name: string;
  points: TerritoryPoint[];
  territoryPoints?: TerritoryPoint[];
  position?: TerritoryPoint | null;
  owner?: string | null;
  ownerLabel?: string | null;
  ownerCount?: number;
  color?: string;
  isOwned?: boolean;
  myPoints?: number;
}

export interface TerritoriesPayload {
  territories: Territory[];
  gangname?: string;
}
