// ============================================================
// PropInteract — TypeScript Types
// Realistic 3D prop interaction system with cursor, drag & drop
// ============================================================

export interface PropInteractProps {
  visible: boolean;
  onClose: () => void;
  primaryColor: string;
}

// --- Scene definition (sent from Lua) ---

export interface SceneData {
  id: string;
  title: string;
  subtitle?: string;
  color?: string;
  tools: SceneTool[];
  zones: SceneZone[];
  items: SceneItem[];
  /** Whether camera orbit (mouse drag on background) is enabled */
  allowOrbit?: boolean;
  allowZoom?: boolean;
  /** Whether to show the results tray */
  showResults?: boolean;
}

export interface SceneTool {
  id: string;
  label: string;
  icon: string;
  description?: string;
}

export interface SceneZone {
  id: string;
  label: string;
  icon: string;
  /** Image URL for zone marker (replaces icon when set) */
  image?: string;
  /** Screen position (0-1) updated every frame from Lua */
  screenX: number;
  screenY: number;
  /** Whether zone is visible on screen */
  visible: boolean;
  /** Distance from camera — used for scale */
  distance: number;
  /** Current state */
  state: 'idle' | 'active' | 'completed' | 'disabled' | 'highlight';
  actions: ZoneAction[];
  /** Items currently held in this zone (for container zones) */
  heldItems?: ZoneHeldItem[];
  /** Max items this zone can hold */
  maxItems?: number;
  /** Tooltip text override */
  tooltip?: string;
  /** Glow pulse animation */
  pulse?: boolean;
  /** Whether this zone can be dragged to another zone */
  draggable?: boolean;
  /** Item ID this zone represents when dragged */
  dragItemId?: string;
}

export interface ZoneAction {
  id: string;
  label: string;
  /** click = single click, hold = hold for duration, drag_receive = accepts dragged items */
  type: 'click' | 'hold' | 'drag_receive';
  /** Duration in ms for hold type */
  duration?: number;
  /** Required tool ID to be selected */
  requiredTool?: string;
  /** Item IDs this zone accepts for drag_receive */
  acceptItems?: string[];
  /** Whether this action is currently available */
  enabled?: boolean;
  /** Icon override for the action */
  icon?: string;
}

export interface ZoneHeldItem {
  itemId: string;
  count: number;
}

export interface SceneItem {
  id: string;
  label: string;
  icon: string;
  image?: string;
  count: number;
  maxStack?: number;
  /** Whether this item can be dragged to zones */
  draggable?: boolean;
}

// --- UI State ---

export interface DragState {
  active: boolean;
  itemId: string | null;
  sourceType: 'tool' | 'item' | 'zone';
  sourceId: string | null;
  x: number;
  y: number;
}

export interface HoldProgress {
  zoneId: string;
  actionId: string;
  progress: number; // 0-100
  duration: number;
}

export interface ActionResult {
  id: string;
  label: string;
  icon: string;
  image?: string;
  count: number;
  timestamp: number;
}

export interface Notification {
  id: string;
  text: string;
  type: 'success' | 'error' | 'info';
  timestamp: number;
}

// --- NUI Messages (Lua → React) ---

export type NUIAction =
  | 'propInteract:open'
  | 'propInteract:close'
  | 'propInteract:updatePositions'
  | 'propInteract:updateZoneState'
  | 'propInteract:updateItems'
  | 'propInteract:holdProgress'
  | 'propInteract:holdComplete'
  | 'propInteract:holdCancel'
  | 'propInteract:addResult'
  | 'propInteract:removeItem'
  | 'propInteract:notification'
  | 'propInteract:updateZoneItems'
  | 'propInteract:removeZone';

// --- NUI Callbacks (React → Lua) ---

export type NUICallback =
  | 'propInteract:close'
  | 'propInteract:selectTool'
  | 'propInteract:zoneClick'
  | 'propInteract:zoneHoldStart'
  | 'propInteract:zoneHoldEnd'
  | 'propInteract:zoneDrop'
  | 'propInteract:orbitStart'
  | 'propInteract:orbitMove'
  | 'propInteract:orbitEnd'
  | 'propInteract:zoom';
