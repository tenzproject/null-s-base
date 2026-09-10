export interface Position {
  x: number;
  y: number;
}

export interface Size {
  width: number;
  height: number;
}

export interface Rect {
  x: number;
  y: number;
  width: number;
  height: number;
}

export interface DragState {
  isDragging: boolean;
  moduleId: string | null;
  startPos: Position;
  offset: Position;
}

export interface HUDEditorState {
  isOpen: boolean;
  isSelectorExpanded: boolean;
  selectedModules: string[];
  moduleStates: Map<string, { position: Position; size: Size; enabled: boolean }>;
  dragState: DragState;
}
