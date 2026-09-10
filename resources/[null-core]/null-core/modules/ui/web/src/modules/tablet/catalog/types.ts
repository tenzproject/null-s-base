export interface CatalogOption {
  value: string;
  label: string;
}

export interface CatalogItem {
  id: string;
  label: string;
  description?: string;
  price: number;
  image?: string;
  options?: CatalogOption[];
  metadata?: Record<string, any>;
}

export interface CatalogData {
  title: string;
  subtitle?: string;
  description?: string;
  items: CatalogItem[];
  imagePath?: string;
  currency?: string;
  callbackEvent: string;
}

export interface CatalogTabletProps {
  visible: boolean;
  onClose: () => void;
  primaryColor: string;
}
