export type SocietyPage = 'home' | 'employees' | 'grades' | 'finances' | 'settings' | 'government' | 'cityinfo' | 'properties';

export interface SocietyEmployee {
  idunique: string;
  identifier: string;
  firstname: string;
  lastname: string;
  name: string;
  job: string;
  job_grade: number;
  job2: string;
  job2_grade: number;
  gradeLabel: string;
  online: boolean;
}

export interface SocietyGrade {
  grade: number;
  name: string;
  label: string;
  salary: number;
  mensuelpay: number;
  job_name?: string;
}

export interface PropertyData {
  id: number;
  name: string;
  label: string;
  price: number;
  isBuy: boolean;
  owner: string | null;
  immeuble: string;
}

export interface SocietyHistoryEntry {
  id: number;
  label: string;
  info: string;
  count: number;
  time: string;
  society: string;
}

export interface SocietyAccounts {
  cash: number;
  dirtycash: number;
}

export interface SalaryLimits {
  min: number;
  max: number;
}

export interface SalaryData {
  Mensuel: SalaryLimits;
  'Pour 30 Min': SalaryLimits;
  Primes: SalaryLimits;
}

export interface TaxesData {
  retrait: number;
  gains: number;
  salaire: number;
  tva: number;
}

export interface PolitiqueConfig {
  [key: string]: {
    type: string | string[];
    default: boolean;
    description: string;
  };
}

export interface SocietyEnterprise {
  name: string;
  label: string;
  state: boolean;
  employeeCount: number;
  politique?: Record<string, boolean>;
}

export interface BlanchimentConfig {
  pourcentage: number;
  delai: number;
}

export interface DrinkItem {
  name: string;
  value: string;
  price: number;
}

export interface HealItem {
  name: string;
  value: string;
  price: number;
}

export interface SocietyData {
  societyName: string;
  societyLabel: string;
  societyType: string;
  isBoss: boolean;
  isGovernment: boolean;
  isJob2: boolean;
  accounts: SocietyAccounts;
  employees: SocietyEmployee[];
  grades: SocietyGrade[];
  history: SocietyHistoryEntry[];
  salaryData?: SalaryData;
  taxesData?: TaxesData;
  politique: Record<string, boolean>;
  politiqueConfig: PolitiqueConfig;
  enterprises: SocietyEnterprise[];
  canLaunder: boolean;
  blanchimentConfig: BlanchimentConfig;
  canBuyDrinks: boolean;
  drinks: DrinkItem[];
  canBuyHeals: boolean;
  heals: HealItem[];
  playerGrade: number;
  playerGradeLabel: string;
  employeeCount: number;
  state: boolean;
  isMecano: boolean;
  isRealEstate: boolean;
  customHistory: SocietyHistoryEntry[];
  properties: PropertyData[];
  maxGrades: number;
  brandLogo?: string;
  brandTagline?: string;
  brandBg?: string;
}

export interface SocietyTabletProps {
  visible: boolean;
  onClose: () => void;
  primaryColor: string;
}
