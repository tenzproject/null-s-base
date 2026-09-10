// ================================================================
// REALTOR — types partagés Lua ↔ React
// ================================================================

export type RealtorMode = 'boss' | 'employee';
export type ListingMode = 'sell' | 'rent';

export interface Door {
  x: number;
  y: number;
  z: number;
  w: number;
}

export interface InteriorMeta {
  label: string;
  basePrice: number;
  baseRent: number;
  photos: number;
  warehouse?: boolean;
}

export interface NeighborhoodMeta {
  label: string;
  priceMul: number;
}

export interface Listing {
  id: string;
  spawnKey: string;
  door: Door;
  interior: string;
  interiorLabel: string;
  photos: number;
  warehouse: boolean;
  neighborhood: string;
  neighborhoodLabel: string;
  price: number;
  suggestedSale: number;
  suggestedRent: number;
  generatedAt: number;
}

export interface OwnedRental {
  tenantName: string;
  expiresAt: number;
  dailyPrice: number;
  startedAt: number;
}

export interface OwnedProperty {
  name: string;
  label: string;
  price: number;
  positions: { EXIT: { x: number; y: number; z: number } };
  interior: string;
  interiorLabel: string;
  neighborhood: string;
  neighborhoodLabel: string;
  listingMode: ListingMode;
  salePrice: number;
  rentPrice: number;
  boughtAt: number;
  boughtFor: number;
  originSpawn: string;
  photos: number;
  warehouse: boolean;
  rental?: OwnedRental;
}

export interface SaleHistoryRow {
  id: number;
  property_name: string;
  property_label: string;
  interior: string;
  neighborhood: string;
  mode: ListingMode;
  seller_identifier: string;
  seller_name: string;
  buyer_identifier: string;
  buyer_name: string;
  price: number;
  days: number;
  created_at: string;
}

export interface DashboardData {
  mode: RealtorMode;
  societyMoney: number;
  listings: Listing[];
  owned: OwnedProperty[];
  history: SaleHistoryRow[];
  neighborhoods: Record<string, NeighborhoodMeta>;
  interiors: Record<string, InteriorMeta>;
  config: {
    buyMargin: number;
    publicSaleMargin: number;
    minRentalDays: number;
    maxRentalDays: number;
  };
  nextRefreshAt: number;
  playerName: string;
}

export interface RealtorProps {
  visible: boolean;
  onClose: () => void;
  primaryColor?: string;
}
