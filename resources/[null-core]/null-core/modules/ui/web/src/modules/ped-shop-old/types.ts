export interface ShopProps {
  visible: boolean;
  onClose: () => void;
  primaryColor: string;
}

export interface ShopData {
  mode: 'clothes' | 'accessories';
  playerSex: 'male' | 'female';
  skins: Record<string, number>;
  prices: PriceConfig;
  blackList: Record<string, Record<string, Record<number, boolean>>>;
  bagInfo?: Record<string, Record<number, BagInfo>>;
}

export interface PriceConfig {
  mainPrice: number;
  categoryPrices: Record<string, Record<string, number>>;
  customPrices: Record<string, Record<string, Record<number, number>>>;
}

export interface BagInfo {
  weight: number;
  weapon: boolean;
}

export interface CategoryDef {
  key: string;
  label: string;
  icon: string;
  group: string;
  span?: number;
  rowSpan?: number;
}

export interface CartItem {
  category: string;
  item: number;
  variation: number;
}

export interface OutfitCode {
  mode: 'clothes' | 'accessories';
  sex: 'male' | 'female';
  items: Record<string, { item: number; variation: number }>;
}
