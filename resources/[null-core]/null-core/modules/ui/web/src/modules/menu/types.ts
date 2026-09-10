export interface PanelItem {
  label: string
  key?: string
  value?: string | number | boolean
}

export interface CollapsibleItem {
  label: string
  description?: string
  rightLabel?: string
  enabled?: boolean
  onSelected?: () => void
}

export interface MenuItem {
  type: 'button' | 'list' | 'checkbox' | 'slider' | 'separator' | 'info' | 'infopanel' | 'colorpanel' | 'imagepanel' | 'gridpanel' | 'imageselector' | 'collapsible' | 'percentagepanel'
  label: string
  description?: string
  rightLabel?: string
  enabled?: boolean
  value?: number | string | boolean
  items?: string[]
  checked?: boolean
  min?: number
  max?: number
  leftBadge?: string
  rightBadge?: string
  leftItems?: string[]
  rightItems?: string[]
  panelItems?: PanelItem[]
  currentColor?: { r: number; g: number; b: number }
  imageUrl?: string
  width?: number
  height?: number
  clickable?: boolean
  callback?: any
  currentX?: number
  currentY?: number
  labelX?: string
  labelY?: string
  images?: Array<{ url: string; label: string }>
  columns?: number
  selectedIndex?: number
  collapsed?: boolean
  collapsibleItems?: CollapsibleItem[]
  minText?: string
  maxText?: string
}

export interface MenuState {
  visible: boolean
  title: string
  subtitle: string
  items: MenuItem[]
  selectedIndex: number
  position: { x: number; y: number }
  previewImage?: string
  maxVisibleItems: number
  transition?: 'forward' | 'back' | null
}

export interface MenuProps {
  title: string
  subtitle: string
  items: MenuItem[]
  selectedIndex: number
  position: { x: number; y: number }
  previewImage?: string
  maxVisibleItems: number
  primaryColor?: string
  serverLuaColor?: string
  transition?: 'forward' | 'back' | null
}
