export interface VehicleData {
  plate: string;
  model: string;
  modelLabel: string;
  label: string | null;
  type: 'car' | 'boat' | 'aircraft';
  owner: string;
  ownerCategory: 'personal' | 'job' | 'org';
  state: boolean; // true = in garage, false = impound
  boutique: boolean;
  spawned: boolean; // currently spawned on map
  distance: number | null; // distance from player if spawned
  vehicle: any; // full vehicle props for spawning
}

export interface GarageData {
  mode: 'garage' | 'impound' | 'store';
  garageType: 'car' | 'boat' | 'aircraft';
  garageId: string;
  garageName: string;
  vehicles: VehicleData[];
  hasJob: boolean;
  hasOrg: boolean;
  jobLabel: string;
  orgLabel: string;
  impoundPrice: number;
  repairPrice: number;
  vehicleDamaged?: boolean;
  currentVehiclePlate?: string;
}

export type TabType = 'personal' | 'job' | 'org';
export type SortType = 'name' | 'type' | 'status';
