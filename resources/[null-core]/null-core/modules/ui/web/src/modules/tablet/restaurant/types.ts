export interface CraftRequirement {
  itemName: string;
  label: string;
  amount: number;
  playerHas?: number;
}

export interface CraftRecipe {
  id: string;
  label: string;
  item: string;
  count: number;
  time: number;
  category: string;
  description: string;
  requirements: CraftRequirement[];
}

export interface RestaurantBrand {
  color: string;
  logo: string;
  description: string;
}

export interface OrderItem {
  name: string;
  label: string;
  quantity: number;
  price: number;
}

export interface RestaurantOrder {
  id: string;
  items: OrderItem[];
  customerName: string;
  total: number;
  status: 'pending' | 'preparing' | 'ready' | 'delivered';
  createdAt: number;
  claimedBy?: number | null;
}

export interface CraftTabletData {
  restaurantName: string;
  restaurantLabel: string;
  recipes: CraftRecipe[];
  categories: string[];
  brand?: RestaurantBrand | null;
  orders?: RestaurantOrder[];
}

export interface CraftTabletProps {
  visible: boolean;
  onClose: () => void;
  primaryColor: string;
}

// ── Supplier types ──

export interface SupplierItem {
  name: string;
  label: string;
  price: number;
  image?: string;
}

export interface SupplierOrder {
  orderId: string;
  items: { name: string; label: string; count: number; price: number }[];
  totalPrice: number;
  status: 'pending' | 'preparing' | 'delivering' | 'ready' | 'collected';
  orderTime: number;
  deliveryTime: number;
  remainingSeconds?: number;
}

export interface SupplierTabletData {
  restaurantName: string;
  restaurantLabel: string;
  items: SupplierItem[];
  orders: SupplierOrder[];
  playerMoney: number;
  societyMoney: number;
}

export interface SupplierTabletProps {
  visible: boolean;
  onClose: () => void;
  primaryColor: string;
}
