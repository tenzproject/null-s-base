/**
 * Centralized HUD Position Manager
 * Ensures positions are loaded before UI components try to read them
 */

import { AnchorPoint, HUD_MODULES } from '../modules/hud-editor/HUDModulesConfig';

export interface HUDPosition {
  x: number;
  y: number;
}

export interface HUDModuleLayout {
  id: string;
  position: HUDPosition;
  size: { width: number; height: number };
}

export interface HUDPositionWithAnchor extends HUDPosition {
  anchor: AnchorPoint;
}

class HUDPositionManager {
  private layout: HUDModuleLayout[] | null = null;
  private isReady: boolean = false;
  private readyCallbacks: Array<() => void> = [];
  private updateCallbacks: Array<() => void> = []; // Callbacks that should be called on every layout update

  constructor() {
    // Listen for layout updates from Lua
    window.addEventListener('message', (event) => {
      const data = event.data;
      
      if (data.action === 'saveHUDLayoutToStorage') {
        if (data.layout) {
          this.setLayout(data.layout);
        }
      }
    });

    // Try to load from localStorage on init
    this.loadFromStorage();
  }

  private loadFromStorage(): void {
    try {
      const saved = localStorage.getItem('hudLayout');
      if (saved) {
        const parsed = JSON.parse(saved);
        this.setLayout(parsed);
      } else {
        // Don't mark as ready - wait for Lua to send the layout
        // Set a timeout to mark ready anyway after 5 seconds to prevent infinite waiting
        setTimeout(() => {
          if (!this.isReady) {
            this.isReady = true;
            this.notifyReady();
          }
        }, 5000);
      }
    } catch (error) {
      console.error('[HUDPositionManager] Error loading from localStorage:', error);
      this.isReady = true;
      this.notifyReady();
    }
  }

  private setLayout(layout: HUDModuleLayout[]): void {
    this.layout = layout;
    const wasReady = this.isReady;
    this.isReady = true;
    
    // Save to localStorage
    try {
      localStorage.setItem('hudLayout', JSON.stringify(layout));
    } catch (error) {
      console.error('[HUDPositionManager] Error saving to localStorage:', error);
    }
    
    // Notify all waiting callbacks (first time ready)
    if (!wasReady) {
      this.notifyReady();
    }
    this.updateCallbacks.forEach(callback => callback());
  }

  private notifyReady(): void {
    this.readyCallbacks.forEach(callback => callback());
    this.readyCallbacks = [];
  }

  /**
   * Wait for layout to be ready before executing callback
   * Also register for updates when layout changes
   */
  public onReady(callback: () => void): void {
    // Register for future updates
    this.updateCallbacks.push(callback);
    
    if (this.isReady) {
      callback();
    } else {
      this.readyCallbacks.push(callback);
    }
  }

  /**
   * Get position for a specific module with anchor information
   */
  public getPosition(moduleId: string): HUDPositionWithAnchor | null {
    if (!this.layout) return null;
    
    const module = this.layout.find(m => m.id === moduleId);
    if (!module) return null;
    
    // Get anchor from saved layout first, fallback to module config
    const savedAnchor = (module as any).anchor;
    const moduleConfig = HUD_MODULES.find(m => m.id === moduleId);
    const anchor = savedAnchor || moduleConfig?.anchor || 'top-left';
    
    return {
      ...module.position,
      anchor
    };
  }

  /**
   * Check if manager is ready
   */
  public ready(): boolean {
    return this.isReady;
  }
}

// Singleton instance
export const hudPositionManager = new HUDPositionManager();
