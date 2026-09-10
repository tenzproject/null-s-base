/**
 * Utility to manage HUD positions from localStorage
 * Used by UI components to read saved positions from the HUD editor
 */

export interface HUDPosition {
  x: number;
  y: number;
}

export interface HUDModuleLayout {
  id: string;
  position: HUDPosition;
  size: { width: number; height: number };
}

/**
 * Get saved HUD layout from localStorage
 */
export function getSavedHUDLayout(): HUDModuleLayout[] | null {
  try {
    const saved = localStorage.getItem('hudLayout');
    if (!saved) {
      return null;
    }
    const parsed = JSON.parse(saved);
    return parsed;
  } catch (error) {
    return null;
  }
}

/**
 * Get position for a specific module
 */
export function getModulePosition(moduleId: string): HUDPosition | null {
  const layout = getSavedHUDLayout();
  if (!layout) {
    return null;
  }
  
  const module = layout.find(m => m.id === moduleId);
  return module?.position || null;
}

/**
 * Save HUD layout to localStorage (called from Lua via NUI message)
 */
export function saveHUDLayout(layout: HUDModuleLayout[]): void {
  try {
    localStorage.setItem('hudLayout', JSON.stringify(layout));
  } catch (error) {
    console.error('[HUD] Error saving layout:', error);
  }
}
