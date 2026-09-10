export interface Transaction {
  id: string;
  amount: number;
  title: string;
  description: string;
  category: string;
  date: string;
  timestamp: number;
}

export interface Credit {
  id: string;
  originalAmount: number;
  interest: number;
  totalDue: number;
  installments: number;
  perInstallment: number;
  paid: number;
  paidInstallments: number;
  paidOff: boolean;
  createdAt: number;
  createdDate: string;
}

export interface PendingTransfer {
  id: string;
  amount: number;
  description: string;
  fromIban: string;
  date: string;
  timestamp: number;
}

export interface CreditConfig {
  maxAmount: number;
  minAmount: number;
  interestRate: number;
  installments: number[];
  maxActiveLoans: number;
}

export interface CategoryDef {
  label: string;
  icon: string;
}

export interface BankBrand {
  id: string;
  name: string;
  tagline?: string;
  logo: string;       // path relative to nui://null-ui/web/images/  (e.g. "bank/brands/fleeca.png")
  bgColor: string;    // hero background color (#0c1f17)
  accent?: string;    // overrides primaryColor when defined
}

export interface CardConfig {
  price: number;
  itemName: string;
}

export interface BankData {
  iban: string;
  cardNumber: string;
  playerName: string;
  cash: number;
  bank: number;
  history: Transaction[];
  credits: Credit[];
  pendingTransfers: PendingTransfer[];
  creditConfig: CreditConfig | null;
  categories: Record<string, CategoryDef>;
  brand?: BankBrand;
  hasCard: boolean;
  hasPin: boolean;
  cardConfig: CardConfig;
}

export type TabType = 'dashboard' | 'transfers' | 'history' | 'credits' | 'card';

export interface BankProps {
  visible: boolean;
  onClose: () => void;
  primaryColor: string;
}
