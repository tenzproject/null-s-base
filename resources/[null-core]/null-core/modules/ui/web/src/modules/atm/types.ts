export interface ATMTransaction {
  id: string;
  amount: number;
  title: string;
  date: string;
  category: string;
}

export interface ATMSpending {
  label: string;
  total: number;
}

export interface ATMBrand {
  id: string;
  name: string;
  tagline?: string;
  bgColor?: string;
  accent?: string;
}

export interface ATMData {
  iban: string;
  cardNumber: string;
  playerName: string;
  cash: number;
  bank: number;
  recent: ATMTransaction[];
  spending: ATMSpending[];
  brand?: ATMBrand;
  atmId: string;
  hasPin: boolean;
}

export interface ATMProps {
  visible: boolean;
  onClose: () => void;
  primaryColor: string;
}
