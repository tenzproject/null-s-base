// ── Prompt 3D (cadenas in-world) ───────────────────────────────────────────
export interface DoorPromptState {
  id: number | null;
  screenX: number;   // base 1920
  screenY: number;   // base 1080
  distance: number;
  locked: boolean;
  label?: string;
  interactKey: string;
  canInteract: boolean;
  hasCode?: boolean;
  show: boolean;
}

export interface DoorPromptProps {
  primaryColor?: string;
}

// ── Menu de gestion (éditeur) ──────────────────────────────────────────────
export interface DoorPhysical {
  model: number;
  x: number;
  y: number;
  z: number;
  heading?: number;
}

export interface EditorDoor {
  id: number;
  label?: string;
  locked: boolean;
  doors: DoorPhysical[];
  groups?: Record<string, number>;
  items?: string[];
  code?: string | null;
  adminRank?: string | null;
  lockpick?: boolean;
  autolock?: number | null;
}

export interface JobPermissionRow {
  name: string;
  grade: number;
}

export interface DoorlockManagerProps {
  primaryColor?: string;
}
