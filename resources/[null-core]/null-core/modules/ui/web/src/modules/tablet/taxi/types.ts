export interface TaxiRank {
  key: string;
  label: string;
  minXp: number;
  payMul: number;
  vehicles: string[];
}

export interface TaxiProfile {
  xp: number;
  rank: TaxiRank;
  nextRank?: TaxiRank;
  todayRides: number;
  todayEarnings: number;
  dailyGoal: number;
  identifier: string;
  playerName: string;
}

export interface TaxiMissionUI {
  key: string;
  label: string;
  description: string;
  icon?: string;
  stops?: number;
  requireRank?: string;
  unlocked: boolean;
}

export interface TaxiBrand {
  id: string;
  name: string;
  logo: string;            // path relative to nui://null-cache/images/  (e.g. "shopui/brands/taxi.png")
  bgColor: string;         // brand hero background
  accentColor?: string;    // overrides primaryColor
  tagline?: string;
}

export interface TaxiBoardData {
  profile: TaxiProfile;
  missions: TaxiMissionUI[];
  ranks: TaxiRank[];
  brand?: TaxiBrand;
}

export interface TaxiRequest {
  id: string;
  citizenName: string;
  citizenId?: string;
  coords: { x: number; y: number; z: number };
  address?: string;
  note?: string;
  createdAt: number; // ms epoch
}

export interface TaxiHUDData {
  visible: boolean;
  missionKey?: string;
  missionLabel?: string;
  step: 'idle' | 'toPickup' | 'atPickup' | 'inRide' | 'atDestination';
  stopIndex: number;
  stopCount: number;
  stopLabel?: string;
  distanceMeters: number;
  moodPercent: number;
  fareEstimate: number;
  elapsedSec: number;
}

export interface TaxiSummaryData {
  total: number;
  fare: number;
  tip: number;
  xpGain: number;
  rankUp: boolean;
  rank: TaxiRank;
  dailyBonus: number;
  todayRides: number;
  mood: number;
}

export interface TaxiHUDProps {
  primaryColor?: string;
}

export interface TaxiBoardProps {
  visible: boolean;
  onClose: () => void;
  primaryColor?: string;
}
