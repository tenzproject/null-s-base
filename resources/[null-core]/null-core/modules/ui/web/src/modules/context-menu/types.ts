export type ContextMenuItemType = 'button' | 'checkbox' | 'submenu' | 'separator' | 'text';

export interface ContextMenuItem {
  type: ContextMenuItemType;
  label: string;
  description?: string;
  icon?: string;
  checked?: boolean;
  disabled?: boolean;
  closeOnClick?: boolean;
  keepNuiFocus?: boolean;
  action?: string;
  items?: ContextMenuItem[];
}

export interface ContextMenuData {
  title?: string;
  items: ContextMenuItem[];
  position: { x: number; y: number };
  entityType?: 'player' | 'vehicle' | 'ped' | 'object' | 'ground' | 'sky';
}

export interface ContextMenuProps {
  visible: boolean;
  data: ContextMenuData | null;
  primaryColor?: string;
  onClose: (keepNuiFocus?: boolean) => void;
}
