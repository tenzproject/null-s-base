export type CaptureType = 'vehicle' | 'clothing' | 'weapon' | 'ped' | 'prop' | 'utils';

export type TabType = 'vehicles' | 'clothing' | 'weapons' | 'peds' | 'props' | 'utils' | 'custom';

export interface ClothingCategory {
  id: string;
  component: number;
  type: 'CLOTHING' | 'PROPS';
  label: string;
}

export type UtilsType = 'hair' | 'eyebrows' | 'beard' | 'chesthair' | 'lipstick' | 'makeup' | 'blush' | 'tattoos';

export interface TattooEntry {
  collection: string;
  nameHash: string;
  zone?: string;
}

export interface UtilsCategory {
  id: UtilsType;
  label: string;
  componentId: number;
  textureId?: number;
  opacityId?: number;
  colorId?: number;
  highlightId?: number;
}

export interface CameraSettings {
  CLOTHING: Record<number, { fov: number; zPos: number; rotation: { x: number; y: number; z: number } }>;
  PROPS: Record<number, { fov: number; zPos: number; rotation: { x: number; y: number; z: number } }>;
}

export interface GreenScreen {
  position: { x: number; y: number; z: number };
  rotation: { x: number; y: number; z: number };
  vehiclePosition: { x: number; y: number; z: number };
  vehicleRotation: { x: number; y: number; z: number };
  hiddenSpot: { x: number; y: number; z: number };
}

export interface ImageMakerConfig {
  weaponList: string[];
  pedList: string[];
  clothingCategories: ClothingCategory[];
  utilsCategories: UtilsCategory[];
  cameraSettings: CameraSettings;
  greenScreen: GreenScreen;
}

export interface ExistingImages {
  vehicles: string[];
  weapons: string[];
  peds: string[];
  props: string[];
  clothing: {
    male: Record<string, string[]>;
    female: Record<string, string[]>;
  };
  utils: {
    male: Record<string, string[]>;
    female: Record<string, string[]>;
  };
}

export interface GameScanData {
  clothing: Record<string, number>; // categoryId -> drawable count
  utils: Record<string, number>; // utilsType -> variation count
  tattoosList?: TattooEntry[]; // liste des tattoos pour ce genre (cas spécial utils)
  vehicleCount: number;
  vehicles: string[];
}

export interface CaptureQueueItem {
  type: CaptureType;
  id: string;
  label: string;
  // clothing specific
  gender?: string;
  categoryId?: string;
  componentType?: 'CLOTHING' | 'PROPS';
  componentId?: number;
  drawableId?: number;
  // utils specific
  utilsType?: UtilsType;
  variationId?: number;
  // tattoos specific (when utilsType === 'tattoos')
  nameHash?: string;
  collection?: string;
  zone?: string;
  // vehicle/weapon/ped/prop
  model?: string;
  weaponName?: string;
}

export interface CaptureSettings {
  delay: number;      // ms between each capture
  greenRemoval: boolean;
}

export interface ItemEntry {
  id: string;
  label: string;
  hasImage: boolean;
  type: CaptureType;
  // For building queue item
  meta?: Record<string, any>;
}

export interface CaptureProgress {
  current: number;
  total: number;
  itemLabel?: string;
  capturing?: boolean;
  success?: boolean;
  filename?: string;
  captureType?: string;
}
