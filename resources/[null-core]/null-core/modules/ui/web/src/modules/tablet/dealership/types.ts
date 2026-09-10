export interface DealershipVehicle {
  model: string;
  label: string;
  price: number;
  salePrice: number;
  category: string;
  inStock: boolean;
  stockCount: number;
}

export interface StockVehicle {
  model: string;
  label: string;
  plate: string;
  color: number;
  colorLabel: string;
  price: number;
  purchaseDate: string;
  available: boolean;
  index: number;
}

export interface SaleRecord {
  seller: string;
  buyer: string;
  model: string;
  plate: string;
  price: number;
  date: string;
}

export interface ColorOption {
  id: number;
  label: string;
  name: string;
}

export interface EmployeeSale {
  type: 'sale' | 'purchase';
  model: string;
  plate: string;
  buyer: string;
  price: number;
  date: string;
}

export interface DealerEmployee {
  identifier: string;
  firstname: string;
  lastname: string;
  grade: number;
  gradeLabel: string;
  online: boolean;
  sales: EmployeeSale[];
  totalCA: number;
  totalSales: number;
}

export interface ShowroomSlotConfig {
  key: string;
  label: string;
}

export interface ShowroomVehicle {
  model: string;
  plate: string;
  color: number;
  price: number;
}

export interface DealershipData {
  mode: 'public' | 'employee' | 'boss';
  shopName: string;
  shopLabel: string;
  shopType: 'car' | 'bike' | 'boat';
  categories: string[];
  vehicles: DealershipVehicle[];
  stock: StockVehicle[];
  colors: ColorOption[];
  autoSale: boolean;
  salesHistory: SaleRecord[];
  societyMoney: number;
  playerJob: string;
  playerGrade: number;
  employees: DealerEmployee[];
  restockPercent: number;
  taxRates: { salaire: number; retrait: number };
  showroomSlots: ShowroomSlotConfig[];
  showroomTitle: string;
  showroomData: Record<string, ShowroomVehicle>;
}

export type DealerTab = 'catalogue' | 'gestion';
export type GestionSubTab = 'stock' | 'employees' | 'history' | 'society' | 'showroom';
export type PaymentMethod = 'cash' | 'bank';
