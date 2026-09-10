import React, { useState, useCallback, useEffect } from 'react';
import { HUD_MODULES, getDefaultModuleStates, HUDModuleState, AnchorPoint } from './HUDModulesConfig';
import ModuleSelector from './components/ModuleSelector';
import Workspace from './components/Workspace';
import { GlobalConfig } from './components/GlobalConfigPanel';
import HUDTutorial, { TutorialPrompt } from './components/HUDTutorial';
import { Position } from './types';
import { resolveAllCollisionsOnDrop } from './utils/collisionOptimized';

function GetParentResourceName(): string {
  return 'null-core';
}

interface HUDEditorProps {
  visible: boolean;
  onClose: () => void;
  primaryColor: string;
  serverColor: string;
  statusColors?: any;
  speedometerColors?: any;
  serverConfig?: {
    serverName: string;
    serverColor: string;
    serverLuaColor: string;
    serverIcon: string;
    serverDiscord: string;
  };
}

const HUDEditor: React.FC<HUDEditorProps> = ({ visible, onClose, primaryColor, serverColor, statusColors, speedometerColors, serverConfig }) => {
  const [moduleStates, setModuleStates] = useState<Map<string, HUDModuleState>>(new Map());
  const [enabledModules, setEnabledModules] = useState<Set<string>>(new Set());
  const [draggingModuleId, setDraggingModuleId] = useState<string | null>(null);
  const [configuringModuleId, setConfiguringModuleId] = useState<string | null>(null);
  const [hasUnsavedChanges, setHasUnsavedChanges] = useState(false);
  const [globalConfigOpen, setGlobalConfigOpen] = useState(false);
  const [isPanelCollapsed, setIsPanelCollapsed] = useState(false);
  const [tutorialOpen, setTutorialOpen] = useState(false);
  const [tutorialPromptOpen, setTutorialPromptOpen] = useState(false);
  const [tutorialDone, setTutorialDone] = useState(true);
  const [devMode, setDevMode] = useState(false);
  const [globalConfig, setGlobalConfig] = useState<GlobalConfig>({
    primaryColor: primaryColor,
    theme: 'dark',
    style: 'modern'
  });

  // Update globalConfig when primaryColor prop changes
  useEffect(() => {
    setGlobalConfig(prev => ({
      ...prev,
      primaryColor: primaryColor
    }));
  }, [primaryColor]);

  // Listen for openHUDEditor to get tutorial status from KVP
  useEffect(() => {
    const handleTutorialStatus = (event: MessageEvent) => {
      const data = event.data;
      if (data.action === 'openHUDEditor') {
        const done = data.tutorialDone === true;
        setTutorialDone(done);
        setDevMode(data.devMode === true);
        if (!done) {
          setTutorialPromptOpen(true);
        }
      }
    };
    window.addEventListener('message', handleTutorialStatus);
    return () => window.removeEventListener('message', handleTutorialStatus);
  }, []);

  // Initialize module states
  useEffect(() => {
    const initialStates = getDefaultModuleStates();
    const statesMap = new Map<string, HUDModuleState>();
    const enabledSet = new Set<string>();

    initialStates.forEach((state) => {
      statesMap.set(state.id, state);
      if (state.enabled) {
        enabledSet.add(state.id);
      }
    });

    setModuleStates(statesMap);
    setEnabledModules(enabledSet);

    // Load global config from localStorage
    const savedGlobalConfig = localStorage.getItem('hudGlobalConfig');
    if (savedGlobalConfig) {
      try {
        const parsed = JSON.parse(savedGlobalConfig);
        setGlobalConfig(prev => ({
          theme: parsed.theme || prev.theme,
          style: parsed.style || prev.style,
          // primaryColor vient déjà des props (qui a été chargé dans App.tsx)
          primaryColor: prev.primaryColor
        }));
      } catch (e) {
        console.error('Failed to parse global config:', e);
      }
    }
  }, []);

  // Listen for saved layout from Lua
  useEffect(() => {
    const handleMessage = (event: MessageEvent) => {
      const data = event.data;

      if (data.action === 'loadDefaultLayout') {
        // Load default layout when no saved layout exists (first connection)
        const defaultStates = getDefaultModuleStates();
        const statesMap = new Map<string, HUDModuleState>();
        const enabledSet = new Set<string>();

        defaultStates.forEach((state) => {
          statesMap.set(state.id, state);
          if (state.enabled) {
            enabledSet.add(state.id);
          }
        });

        setModuleStates(statesMap);
        setEnabledModules(enabledSet);

        // Save default layout to localStorage so UI components can read it
        const layoutArray = Array.from(statesMap.values());
        localStorage.setItem('hudLayout', JSON.stringify(layoutArray));
        
        // Dispatch event so UI components update
        window.dispatchEvent(new Event('hudLayoutChanged'));
      } else if (data.action === 'loadHUDLayout' && data.layout) {
        try {
          const layout = typeof data.layout === 'string' ? JSON.parse(data.layout) : data.layout;
          const defaultStates = getDefaultModuleStates();
          const statesMap = new Map<string, HUDModuleState>();
          const enabledSet = new Set<string>();

          // Merge saved positions with default enabled states
          defaultStates.forEach((defaultState, id) => {
            const savedState = layout.find((s: any) => s.id === id);
            const mergedState = {
              id,
              enabled: defaultState.enabled, // Always use default enabled state
              position: savedState?.position || defaultState.position,
              size: savedState?.size || defaultState.size,
              anchor: savedState?.anchor || defaultState.anchor,
              colors: savedState?.colors,
              manualAnchor: savedState?.manualAnchor || false
            };
            statesMap.set(id, mergedState);
            if (mergedState.enabled) {
              enabledSet.add(id);
            }
          });

          setModuleStates(statesMap);
          setEnabledModules(enabledSet);
        } catch (error) {
          console.error('[HUDEditor] Error loading layout:', error);
        }
      }

      if (data.action === 'loadGlobalConfig' && data.config) {
        try {
          setGlobalConfig(prev => ({
            ...data.config,
            primaryColor: prev.primaryColor // Always preserve primaryColor from props
          }));
          localStorage.setItem('hudGlobalConfig', JSON.stringify({
            ...data.config,
            primaryColor: globalConfig.primaryColor
          }));
        } catch (error) {
          console.error('[HUDEditor] Error loading global config:', error);
        }
      }
    };

    window.addEventListener('message', handleMessage);
    return () => window.removeEventListener('message', handleMessage);
  }, []);

  const handleToggleModule = useCallback((moduleId: string, enabled: boolean) => {
    setEnabledModules((prev) => {
      const newSet = new Set(prev);
      if (enabled) {
        newSet.add(moduleId);
      } else {
        newSet.delete(moduleId);
      }
      return newSet;
    });

    setModuleStates((prev) => {
      const newMap = new Map(prev);
      const state = newMap.get(moduleId);
      if (state) {
        newMap.set(moduleId, { ...state, enabled });
      }
      return newMap;
    });
  }, []);

  const handleResetModule = useCallback((moduleId: string) => {
    setModuleStates((prev) => {
      const newMap = new Map(prev);
      const defaultStates = getDefaultModuleStates();
      const defaultState = defaultStates.get(moduleId);
      const currentState = newMap.get(moduleId);

      if (defaultState && currentState) {
        // Reset only position/size/anchor, preserve colors and other config
        newMap.set(moduleId, {
          ...defaultState,
          enabled: true,
          position: { ...defaultState.position },
          size: { ...defaultState.size },
          anchor: defaultState.anchor,
          manualAnchor: false, // Reset manual anchor flag
          colors: currentState.colors, // Preserve colors config (includes 2D/3D variant)
        });
      }

      return newMap;
    });
  }, []);

  const handleConfigure = useCallback((moduleId: string) => {
    setConfiguringModuleId(moduleId);
  }, []);

  const handleBackToList = useCallback(() => {
    setConfiguringModuleId(null);
    setGlobalConfigOpen(false);
  }, []);

  // Live changes pour la config globale (couleur, thème, style) → applique immédiatement
  const handleGlobalConfigChange = useCallback((partial: Partial<GlobalConfig>) => {
    setGlobalConfig((prev) => {
      const next = { ...prev, ...partial };
      localStorage.setItem('hudGlobalConfig', JSON.stringify(next));
      window.postMessage({ action: 'updateGlobalConfig', data: next }, '*');
      return next;
    });
    setHasUnsavedChanges(true);
  }, []);

  // Live preview: applique tout changement immédiatement à moduleStates ET push les configs NUI concernées.
  const handleConfigChange = useCallback((moduleId: string, partial: { anchor?: AnchorPoint; enabled?: boolean; colors?: any }) => {
    const module = HUD_MODULES.find((m) => m.id === moduleId);
    if (!module) return;

    setHasUnsavedChanges(true);

    // enabled
    if (typeof partial.enabled === 'boolean') {
      setEnabledModules((prev) => {
        const next = new Set(prev);
        if (partial.enabled) next.add(moduleId);
        else next.delete(moduleId);
        return next;
      });
    }

    // moduleStates patch (anchor, enabled, colors)
    setModuleStates((prev) => {
      const next = new Map(prev);
      const state = next.get(moduleId);
      if (!state) return next;
      const anchorChanged = partial.anchor !== undefined && partial.anchor !== state.anchor;
      next.set(moduleId, {
        ...state,
        enabled: partial.enabled !== undefined ? partial.enabled : state.enabled,
        anchor: partial.anchor !== undefined ? partial.anchor : state.anchor,
        colors: partial.colors !== undefined ? partial.colors : state.colors,
        manualAnchor: anchorChanged ? true : state.manualAnchor,
      });

      // Sync sous-module → parent status_bars : on merge pour que TOUTES les barres restent cohérentes
      const isStatusBarSub = module.parentId === 'status_bars';
      if (isStatusBarSub && partial.colors !== undefined) {
        const parent = next.get('status_bars');
        if (parent) {
          const merged = { ...(parent.colors || {}), ...partial.colors };
          next.set('status_bars', { ...parent, colors: merged });
        }
      }
      return next;
    });

    // Mirror anchor change into module config (used by Workspace defaults)
    if (partial.anchor !== undefined) {
      module.anchor = partial.anchor;
    }

    // Push live previews vers le NUI selon le module
    if (partial.colors !== undefined) {
      const isStatusBarSub = module.parentId === 'status_bars';
      const colors = partial.colors;

      if (moduleId === 'status_bars' || isStatusBarSub) {
        const parent = moduleStates.get('status_bars');
        const merged = isStatusBarSub
          ? { ...(parent?.colors || {}), ...colors }
          : colors;
        fetch(`https://${GetParentResourceName()}/setStatusBarColors`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ colors: merged }),
        }).catch((e) => console.error('[HUDEditor] setStatusBarColors:', e));
      }
      if (moduleId === 'speedometer') {
        fetch(`https://${GetParentResourceName()}/setSpeedometerColors`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ colors }),
        }).catch((e) => console.error('[HUDEditor] setSpeedometerColors:', e));
      }
      if (moduleId === 'minimap') {
        const state = moduleStates.get(moduleId);
        fetch(`https://${GetParentResourceName()}/setMinimapConfig`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            config: colors,
            anchor: partial.anchor || state?.anchor || module.anchor,
            position: state?.position || { x: 1, y: 83 },
          }),
        }).catch((e) => console.error('[HUDEditor] setMinimapConfig:', e));
      }
      if (moduleId === 'ui_3d') {
        fetch(`https://${GetParentResourceName()}/set3dUIConfig`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            config: {
              packMode: colors.packMode || 'basic',
              quality: colors.quality || 'medium',
            },
          }),
        }).catch((e) => console.error('[HUDEditor] set3dUIConfig:', e));
      }
      if ((moduleId === 'speedometer' || moduleId === 'ammo') && colors.variant) {
        const variant = colors.variant === '2d' ? '2d' : 'hologram';
        const payload = moduleId === 'speedometer'
          ? { speedVariant: variant }
          : { ammoVariant: variant };
        fetch(`https://${GetParentResourceName()}/set3dUIConfig`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ config: payload }),
        }).catch((e) => console.error('[HUDEditor] set3dUIConfig variant:', e));
      }
    }
  }, [moduleStates]);

  const handleDragStart = useCallback((moduleId: string, startPos: Position) => {
    setDraggingModuleId(moduleId);
  }, []);
 
  const handleDrag = useCallback(
    (moduleId: string, newPos: Position) => {
      setModuleStates((prev) => {
        const newStates = new Map(prev);
        const moduleState = newStates.get(moduleId);

        if (moduleState) {
          newStates.set(moduleId, {
            ...moduleState,
            position: newPos,
          });
        }

        return newStates;
      });
    },
    []
  );

  const handleDragEnd = useCallback((moduleId: string) => {
    setDraggingModuleId(null);
    
    // Résoudre les collisions uniquement au drop
    setModuleStates((prev) => {
      const newStates = new Map(prev);
      const collisionResolutions = resolveAllCollisionsOnDrop(newStates, moduleId);
      
      collisionResolutions.forEach((newPosition, movedModuleId) => {
        const movedState = newStates.get(movedModuleId);
        if (movedState) {
          newStates.set(movedModuleId, {
            ...movedState,
            position: newPosition,
          });
        }
      });
      
      return newStates;
    });
  }, []);

  const handleAnchorChange = useCallback((moduleId: string, newAnchor: string) => {
    // Update anchor directly (auto-calculated on drag)
    setModuleStates((prev) => {
      const newMap = new Map(prev);
      const state = newMap.get(moduleId);
      if (state) {
        // Don't mark as manual since this is auto-calculated
        newMap.set(moduleId, { ...state, anchor: newAnchor as any });
      }
      return newMap;
    });
  }, []);

  const handleSave = useCallback(() => {
    // Save positions, sizes, anchors, and colors (not enabled/disabled state)
    const layout = Array.from(moduleStates.values()).map(state => ({
      id: state.id,
      position: state.position,
      size: state.size,
      anchor: state.anchor,
      colors: state.colors
    }));
    
    // Send to Lua for KVP save
    fetch(`https://${GetParentResourceName()}/saveHUDLayout`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ layout }),
    }).catch((error) => {
      console.error('[HUDEditor] Error saving layout:', error);
    });

    // Persist global config (color, theme, style) to backend
    fetch(`https://${GetParentResourceName()}/saveGlobalConfig`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(globalConfig),
    }).catch((error) => {
      console.error('[HUDEditor] Error saving global config:', error);
    });

    setHasUnsavedChanges(false);

    // Save to localStorage immediately so App.tsx can read it
    localStorage.setItem('hudLayout', JSON.stringify(layout));

    // Dispatch event to notify components of layout change
    window.dispatchEvent(new CustomEvent('hudLayoutChanged'));
    
    // Update minimap position if it exists
    const minimapState = moduleStates.get('minimap');
    if (minimapState) {
      fetch(`https://${GetParentResourceName()}/setMinimapConfig`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ 
          config: minimapState.colors || {},
          anchor: minimapState.anchor,
          position: minimapState.position
        }),
      }).catch((error) => {
        console.error('[HUDEditor] Error updating minimap position:', error);
      });
    }
  }, [moduleStates, globalConfig]);


  const handleClose = useCallback(() => {
    setConfiguringModuleId(null);

    // Notifie la window parente (où vit interactions-bridge) que le HUD
    // Editor se ferme. Indispensable car le fetch ci-dessous part en HTTP
    // côté Lua et ne passe pas par window.postMessage — sans cela le bridge
    // garderait `hud-editor` dans activeComponents et les autres UIs (ex.
    // notifications) resteraient bloquées en mode "interface ouverte".
    try {
      window.parent?.postMessage({ action: 'closeHUDEditor' }, '*');
    } catch (_) { /* parent inaccessible — sans gravité */ }

    fetch(`https://${GetParentResourceName()}/closeHUDEditor`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' }
    }); 

    onClose();
  }, [onClose]);

  // Handle escape key
  useEffect(() => {
    const handleKeyDown = (event: KeyboardEvent) => {
      if (event.key === 'Escape' && visible) {
        if (tutorialOpen) {
          setTutorialOpen(false);
        } else if (tutorialPromptOpen) {
          setTutorialPromptOpen(false);
        } else if (configuringModuleId) {
          setConfiguringModuleId(null);
        } else if (globalConfigOpen) {
          setGlobalConfigOpen(false);
        } else {
          handleClose();
        }
      }
    };

    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [visible, configuringModuleId, globalConfigOpen, tutorialOpen, tutorialPromptOpen, handleClose]);

  if (!visible) return null;

  const modulePositions = new Map<string, Position>();
  const moduleSizes = new Map<string, { width: number; height: number }>();

  moduleStates.forEach((state, id) => {
    modulePositions.set(id, state.position);
    moduleSizes.set(id, state.size);
  });

  return (
    <div data-theme={globalConfig.theme} data-style={globalConfig.style}>
      <ModuleSelector
        enabledModules={enabledModules}
        moduleStates={moduleStates}
        configuringModuleId={configuringModuleId}
        globalConfigOpen={globalConfigOpen}
        globalConfig={globalConfig}
        defaultPrimaryColor={serverColor}
        devMode={devMode}
        onToggleModule={handleToggleModule}
        onResetModule={handleResetModule}
        onConfigureModule={handleConfigure}
        onBackToList={handleBackToList}
        onConfigChange={handleConfigChange}
        onGlobalConfigChange={handleGlobalConfigChange}
        onSave={handleSave}
        onClose={handleClose}
        onOpenGlobalConfig={() => setGlobalConfigOpen(true)}
        onOpenTutorial={() => setTutorialOpen(true)}
        primaryColor={globalConfig.primaryColor}
        statusColors={statusColors}
        speedometerColors={speedometerColors}
        hasUnsavedChanges={hasUnsavedChanges}
        isCollapsed={isPanelCollapsed}
        onToggleCollapse={() => setIsPanelCollapsed((v) => !v)}
      />

      <Workspace
        enabledModules={enabledModules}
        modulePositions={modulePositions}
        moduleSizes={moduleSizes}
        moduleStates={moduleStates}
        draggingModuleId={draggingModuleId}
        onDragStart={handleDragStart}
        onDrag={handleDrag}
        onDragEnd={handleDragEnd}
        onReset={handleResetModule}
        onConfigure={handleConfigure}
        onAnchorChange={handleAnchorChange}
        primaryColor={globalConfig.primaryColor}
        statusColors={statusColors || moduleStates.get('status_bars')?.colors}
        speedometerColors={speedometerColors || moduleStates.get('speedometer')?.colors}
        serverConfig={serverConfig}
      />

      <TutorialPrompt
        isOpen={tutorialPromptOpen}
        onStartTutorial={() => {
          setTutorialPromptOpen(false);
          setTutorialOpen(true);
        }}
        onSkip={() => {
          setTutorialPromptOpen(false);
          setTutorialDone(true);
          fetch(`https://${GetParentResourceName()}/completeTutorial`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({}),
          }).catch(() => {});
        }}
        primaryColor={globalConfig.primaryColor}
      />

      <HUDTutorial
        isOpen={tutorialOpen}
        onClose={() => setTutorialOpen(false)}
        primaryColor={globalConfig.primaryColor}
        controls={{
          expandPanel: () => setIsPanelCollapsed(false),
          collapsePanel: () => setIsPanelCollapsed(true),
          openModuleConfig: (id) => { setGlobalConfigOpen(false); setConfiguringModuleId(id); },
          closeModuleConfig: () => setConfiguringModuleId(null),
          openGlobalConfig: () => { setConfiguringModuleId(null); setGlobalConfigOpen(true); },
          closeGlobalConfig: () => setGlobalConfigOpen(false),
        }}
      />
    </div>
  );
};

export default HUDEditor;
