export interface PawnShopListing {
  id: number;
  sellerIdentifier: string;
  sellerName: string;
  itemName: string;
  itemLabel: string;
  count: number;
  pricePerUnit: number;
  isNpc: boolean;
  createdAt?: string;
}

export interface PawnShopInventoryItem {
  name: string;
  label: string;
  count: number;
}

export interface PawnShopPendingSale {
  id: number;
  amount: number;
}

export interface PawnShopData {
  listings: PawnShopListing[];
  myListings: PawnShopListing[];
  playerInventory: PawnShopInventoryItem[];
  pendingSales: PawnShopPendingSale[];
  pendingSalesTotal: number;
  money: PlayerMoney;
  maxListings: number;
  saleTax: number;
}

export interface PlayerMoney {
  cash: number;
  bank: number;
}

export interface PawnShopProps {
  visible: boolean;
  onClose: () => void;
  primaryColor: string;
}
