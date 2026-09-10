export interface PoliceBrand {
  id: string;
  name: string;
  logo?: string | null;
  accentColor: string;
  bgColor: string;
}

export interface PoliceAgent {
  identifier: string;
  idunique: string;
  firstname: string;
  lastname: string;
  name: string;
}

export interface DispatchCard {
  identifier: string;
  idunique: string;
  firstname: string;
  lastname: string;
  matricule: string;
  color: string;
  x: number;
  y: number;
  groupId: string | null;
}

export interface DispatchGroup {
  id: string;
  name: string;
  color: string;
  x: number;
  y: number;
  createdBy: string;
}

export interface DispatchState {
  cards: Record<string, DispatchCard>;
  groups: Record<string, DispatchGroup>;
}

export interface PenalOffense {
  id: number;
  label: string;
  price: number;
  jail: number;
}

export type PenalCode = Record<string, PenalOffense[]>;

export interface RadioCode {
  id: number;
  code: string;
  label: string;
  priority: number;
}

export interface PlayerSummary {
  identifier: string;
  idunique: string;
  firstname: string;
  lastname: string;
  bank: number;
  job: string;
  jobGrade: number;
  sex: string;
  dateofbirth: string;
  phone: string;
}

export interface OwnedVehicle {
  plate: string;
  label: string;
  vehicle: string;
  type: string;
  state: string;
  owner?: string;
  ownerName?: string;
  garage?: string;
}

export interface OwnedProperty {
  name: string;
  label: string;
  price: number;
  owner?: string;
  ownerName?: string;
  coords?: { x: number; y: number; z: number } | null;
  immeuble?: string;
}

export interface CasierEntry {
  id: number;
  agentName: string;
  agentMatricule: string;
  offenses: Array<{ label: string; price: number; jail: number; category?: string }>;
  totalAmount: number;
  totalJail: number;
  notes: string;
  createdAt: string;
  targetName?: string;
}

export interface PlayerDetails {
  summary: PlayerSummary;
  vehicles: OwnedVehicle[];
  vehiclesCount: number;
  properties: OwnedProperty[];
  propertiesCount: number;
  casier: CasierEntry[];
}

export interface PoliceTabletData {
  jobName: string;
  brand: PoliceBrand;
  isBoss: boolean;
  grade: string;
  gradeLabel: string;
  agent: PoliceAgent;
  penalCode: PenalCode;
  radioCodes?: RadioCode[];
  dispatch: DispatchState;
}

export interface PoliceTabletProps {
  visible: boolean;
  onClose: () => void;
  primaryColor?: string;
}
