export interface ShopCategory {
  name: string;
  type: string;
  icon: string;
}

export interface ShopItem {
  name: string;
  label: string;
  category: string;
  price: number;
}

export interface CartItem extends ShopItem {
  quantity: number;
}

export interface ShopLocales {
  cartTitle: string;
  cartDescription: string;
  addCart: string;
  paymentTitle: string;
  payBank: string;
  payCash: string;
  emptyCart: string;
  total: string;
  quantity: string;
  removeItem: string;
}

export interface RepairWeapon {
  name: string;
  label: string;
  durability: number;
  ammoType: string;
  repairPrice: number;
}

export interface RepairInProgress {
  name: string;
  label: string;
  pourcent: number;
  finish: boolean;
}

export interface RepairData {
  weapons: RepairWeapon[];
  repairs: RepairInProgress[];
  prices: Record<string, number>;
  timeToRepair: number;
  timeToRepairVIP: number;
  isVip: boolean;
}

export interface ShopBrand {
  id: string;
  name: string;
  logo: string;       // path relative to nui://null-ui/web/images/ (e.g. "shopui/brands/ltd.png")
  bgColor: string;    // background color of the brand header (#232959 etc.)
  accentColor?: string;
  tagline?: string;
}

export interface ShopData {
  label: string;
  tag: string;
  description: string;
  categories: ShopCategory[];
  items: ShopItem[];
  imagePath: string;
  locales: ShopLocales;
  hasRepair?: boolean;
  brand?: ShopBrand;
}

export interface PlayerMoney {
  cash: number;
  bank: number;
}

export interface ShopUIProps {
  visible: boolean;
  onClose: () => void;
  primaryColor: string;
}
