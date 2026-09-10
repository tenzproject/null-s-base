import React, { useState, useEffect, useCallback, useRef, useMemo } from 'react';
import { generateAccentVars } from '@/utils/accentColors';
import {
  PropInteractProps,
  SceneData,
  SceneZone,
  SceneTool,
  SceneItem,
  DragState,
  HoldProgress,
  ActionResult,
  Notification,
} from './types';
import {
  X, MousePointer2, Hand, Scissors, Wrench, Package, Leaf, FlaskConical,
  Hammer, Crosshair, GripVertical, Pipette, Flame, Zap, Star, Circle,
  Box, Target, Sparkles, Check, AlertCircle, Info,
} from 'lucide-react';
import './PropInteract.css';

const GetParentResourceName = () => 'null-core';

const nuiCallback = async (event: string, data: Record<string, any> = {}) => {
  try {
    const resp = await fetch(`https://${GetParentResourceName()}/${event}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data),
    });
    return await resp.json();
  } catch {
    return null;
  }
};

// Icon mapping
const ICON_MAP: Record<string, any> = {
  hand: Hand,
  scissors: Scissors,
  wrench: Wrench,
  package: Package,
  leaf: Leaf,
  flask: FlaskConical,
  hammer: Hammer,
  crosshair: Crosshair,
  grip: GripVertical,
  pipette: Pipette,
  flame: Flame,
  zap: Zap,
  star: Star,
  circle: Circle,
  box: Box,
  target: Target,
  sparkles: Sparkles,
  check: Check,
  pointer: MousePointer2,
};

const getIcon = (name: string): any => {
  return ICON_MAP[name] || Circle;
};

const PropInteract: React.FC<PropInteractProps> = ({ visible, onClose, primaryColor }) => {
  const [hiding, setHiding] = useState(false);
  const [mounted, setMounted] = useState(false);
  const piAccentVars = useMemo(() => generateAccentVars('--pi-accent', primaryColor), [primaryColor]);

  // Scene data
  const [scene, setScene] = useState<SceneData | null>(null);
  const [zones, setZones] = useState<SceneZone[]>([]);
  const [tools, setTools] = useState<SceneTool[]>([]);
  const [items, setItems] = useState<SceneItem[]>([]);
  const [activeTool, setActiveTool] = useState<string | null>(null);

  // Drag state
  const [drag, setDrag] = useState<DragState>({
    active: false, itemId: null, sourceType: 'item', sourceId: null, x: 0, y: 0,
  });

  // Hold progress
  const [holdProgress, setHoldProgress] = useState<HoldProgress | null>(null);
  const holdTimerRef = useRef<ReturnType<typeof setInterval> | null>(null);
  const holdStartRef = useRef<number>(0);

  // Results
  const [results, setResults] = useState<ActionResult[]>([]);
  const [notifications, setNotifications] = useState<Notification[]>([]);

  // Orbit
  const [orbiting, setOrbiting] = useState(false);
  const orbitStartRef = useRef({ x: 0, y: 0 });

  // Drop target zone (for hover highlight)
  const [dropTargetZone, setDropTargetZone] = useState<string | null>(null);

  // ============================================================
  // Visibility
  // ============================================================

  useEffect(() => {
    if (visible) {
      setMounted(true);
      setHiding(false);
    } else if (mounted) {
      setHiding(true);
      const t = setTimeout(() => { setMounted(false); setHiding(false); }, 300);
      return () => clearTimeout(t);
    }
  }, [visible]);

  // Reset on close
  useEffect(() => {
    if (!visible) {
      setScene(null);
      setZones([]);
      setTools([]);
      setItems([]);
      setActiveTool(null);
      setDrag({ active: false, itemId: null, sourceType: 'item', sourceId: null, x: 0, y: 0 });
      setHoldProgress(null);
      setResults([]);
      setNotifications([]);
      setOrbiting(false);
      setDropTargetZone(null);
    }
  }, [visible]);

  // ============================================================
  // NUI Message handler
  // ============================================================

  useEffect(() => {
    const handler = (event: MessageEvent) => {
      const { action, data } = event.data || {};
      if (!action || !action.startsWith('propInteract:')) return;

      switch (action) {
        case 'propInteract:open': {
          const s = data as SceneData;
          setScene(s);
          setZones(s.zones || []);
          setTools(s.tools || []);
          setItems(s.items || []);
          setResults([]);
          setNotifications([]);
          setActiveTool(s.tools?.[0]?.id || null);
          
          break;
        }

        case 'propInteract:updatePositions': {
          // data = { positions: [{ id, screenX, screenY, visible, distance }] }
          if (data?.positions) {
            setZones(prev => prev.map(z => {
              const pos = data.positions.find((p: any) => p.id === z.id);
              if (pos) {
                return { ...z, screenX: pos.screenX, screenY: pos.screenY, visible: pos.visible, distance: pos.distance };
              }
              return z;
            }));
          }
          break;
        }

        case 'propInteract:updateZoneState': {
          // data = { id, state, pulse? }
          if (data?.id) {
            setZones(prev => prev.map(z =>
              z.id === data.id ? { ...z, state: data.state ?? z.state, pulse: data.pulse ?? z.pulse } : z
            ));
          }
          break;
        }

        case 'propInteract:updateItems': {
          // data = { items: SceneItem[] }
          if (data?.items) {
            setItems(data.items);
          }
          break;
        }

        case 'propInteract:updateZoneItems': {
          // data = { id, heldItems: ZoneHeldItem[] }
          if (data?.id) {
            setZones(prev => prev.map(z =>
              z.id === data.id ? { ...z, heldItems: data.heldItems ?? z.heldItems } : z
            ));
          }
          break;
        }

        case 'propInteract:holdProgress': {
          // data = { zoneId, actionId, progress, duration }
          setHoldProgress(data);
          break;
        }

        case 'propInteract:holdComplete': {
          setHoldProgress(null);
          break;
        }

        case 'propInteract:holdCancel': {
          setHoldProgress(null);
          break;
        }

        case 'propInteract:addResult': {
          // data = { id, label, icon, image?, count }
          const result: ActionResult = { ...data, timestamp: Date.now() };
          setResults(prev => {
            const existing = prev.find(r => r.id === result.id);
            if (existing) {
              return prev.map(r => r.id === result.id ? { ...r, count: r.count + result.count, timestamp: Date.now() } : r);
            }
            return [...prev, result];
          });
          break;
        }

        case 'propInteract:removeItem': {
          // data = { id, count }
          if (data?.id) {
            setItems(prev => prev.map(it => {
              if (it.id === data.id) {
                const newCount = it.count - (data.count || 1);
                return { ...it, count: Math.max(0, newCount) };
              }
              return it;
            }).filter(it => it.count > 0));
          }
          break;
        }

        case 'propInteract:notification': {
          // data = { text, type }
          const notif: Notification = {
            id: `${Date.now()}_${Math.random()}`,
            text: data.text,
            type: data.type || 'info',
            timestamp: Date.now(),
          };
          setNotifications(prev => [...prev, notif]);
          setTimeout(() => {
            setNotifications(prev => prev.filter(n => n.id !== notif.id));
          }, 3000);
          break;
        }

        case 'propInteract:removeZone': {
          // data = { id }
          if (data?.id) {
            setZones(prev => prev.filter(z => z.id !== data.id));
          }
          break;
        }

        case 'propInteract:addZone': {
          // data = SceneZone object
          if (data?.id) {
            setZones(prev => {
              // Check if zone already exists
              const exists = prev.find(z => z.id === data.id);
              if (exists) {
                // Update existing zone
                return prev.map(z => z.id === data.id ? { ...z, ...data } : z);
              }
              // Add new zone with default position values
              return [...prev, { ...data, screenX: 0.5, screenY: 0.5, visible: false, distance: 2.0 }];
            });
          }
          break;
        }
      }
    };

    window.addEventListener('message', handler);
    return () => window.removeEventListener('message', handler);
  }, []);

  // ============================================================
  // Close
  // ============================================================

  const handleClose = useCallback(() => {
    nuiCallback('propInteract:close', {});
    onClose();
  }, [onClose]);

  // ESC key
  useEffect(() => {
    if (!visible) return;
    const handler = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        e.preventDefault();
        handleClose();
      }
    };
    window.addEventListener('keydown', handler);
    return () => window.removeEventListener('keydown', handler);
  }, [visible, handleClose]);

  // ============================================================
  // Tool selection
  // ============================================================

  const handleSelectTool = useCallback((toolId: string) => {
    setActiveTool(toolId);
    nuiCallback('propInteract:selectTool', { toolId });
  }, []);

  // ============================================================
  // Zone click / hold
  // ============================================================

  const handleZoneMouseDown = useCallback((zone: SceneZone, e: React.MouseEvent) => {
    e.stopPropagation();
    if (zone.state === 'disabled' || zone.state === 'completed') return;

    // If zone is draggable, start a drag (moves the 3D prop in-game)
    if (zone.draggable) {
      e.preventDefault();
      setDrag({
        active: true,
        itemId: zone.dragItemId || zone.id,
        sourceType: 'zone',
        sourceId: zone.id,
        x: e.clientX,
        y: e.clientY,
      });
      nuiCallback('propInteract:zoneDragStart', { zoneId: zone.id });
      return;
    }

    // Find first available action
    const action = zone.actions.find(a => {
      if (a.enabled === false) return false;
      if (a.requiredTool && a.requiredTool !== activeTool) return false;
      if (a.type === 'drag_receive') return false; // handled by drop
      return true;
    });

    if (!action) return;

    if (action.type === 'click') {
      nuiCallback('propInteract:zoneClick', { zoneId: zone.id, actionId: action.id, toolId: activeTool });
    } else if (action.type === 'hold') {
      // Start hold
      holdStartRef.current = Date.now();
      const duration = action.duration || 2000;
      setHoldProgress({ zoneId: zone.id, actionId: action.id, progress: 0, duration });

      nuiCallback('propInteract:zoneHoldStart', { zoneId: zone.id, actionId: action.id, toolId: activeTool });

      holdTimerRef.current = setInterval(() => {
        const elapsed = Date.now() - holdStartRef.current;
        const pct = Math.min(100, (elapsed / duration) * 100);
        setHoldProgress(prev => prev ? { ...prev, progress: pct } : null);
        if (pct >= 100) {
          if (holdTimerRef.current) clearInterval(holdTimerRef.current);
          holdTimerRef.current = null;
          setHoldProgress(null);
        }
      }, 16);
    }
  }, [activeTool]);

  const handleZoneMouseUp = useCallback(() => {
    if (holdTimerRef.current) {
      clearInterval(holdTimerRef.current);
      holdTimerRef.current = null;
    }
    if (holdProgress) {
      if (holdProgress.progress < 100) {
        nuiCallback('propInteract:zoneHoldEnd', {
          zoneId: holdProgress.zoneId,
          actionId: holdProgress.actionId,
          completed: false,
          progress: holdProgress.progress,
        });
      }
      setHoldProgress(null);
    }
  }, [holdProgress]);

  // Global mouseup for hold release
  useEffect(() => {
    if (!visible) return;
    const handler = () => handleZoneMouseUp();
    window.addEventListener('mouseup', handler);
    return () => window.removeEventListener('mouseup', handler);
  }, [visible, handleZoneMouseUp]);

  // ============================================================
  // Drag & drop (items → zones)
  // ============================================================

  const handleItemDragStart = useCallback((item: SceneItem, e: React.MouseEvent) => {
    e.preventDefault();
    if (!item.draggable || item.count <= 0) return;
    setDrag({
      active: true,
      itemId: item.id,
      sourceType: 'item',
      sourceId: item.id,
      x: e.clientX,
      y: e.clientY,
    });
  }, []);

  const handleMouseMove = useCallback((e: React.MouseEvent | MouseEvent) => {
    if (drag.active) {
      setDrag(prev => ({ ...prev, x: e.clientX, y: e.clientY }));
      // If dragging a zone, send screen coords to Lua for 3D prop movement
      if (drag.sourceType === 'zone') {
        nuiCallback('propInteract:zoneDragMove', {
          screenX: e.clientX / window.innerWidth,
          screenY: e.clientY / window.innerHeight,
        });
      }
    }
    if (orbiting) {
      const dx = e.clientX - orbitStartRef.current.x;
      const dy = e.clientY - orbitStartRef.current.y;
      nuiCallback('propInteract:orbitMove', { dx, dy });
      orbitStartRef.current = { x: e.clientX, y: e.clientY };
    }
  }, [drag.active, drag.sourceType, orbiting]);

  const handleMouseUp = useCallback((e: MouseEvent) => {
    if (drag.active) {
      const dropped = !!dropTargetZone;
      // If zone drag, tell Lua to end the 3D prop drag
      if (drag.sourceType === 'zone') {
        nuiCallback('propInteract:zoneDragEnd', { dropped });
      }
      // Check if over a zone drop target
      if (dropped) {
        nuiCallback('propInteract:zoneDrop', {
          zoneId: dropTargetZone,
          itemId: drag.itemId,
          sourceType: drag.sourceType,
          sourceId: drag.sourceId,
          toolId: activeTool,
        });
      }
      setDrag({ active: false, itemId: null, sourceType: 'item', sourceId: null, x: 0, y: 0 });
      setDropTargetZone(null);
    }
    if (orbiting) {
      setOrbiting(false);
      nuiCallback('propInteract:orbitEnd', {});
    }
  }, [drag, dropTargetZone, activeTool, orbiting]);

  useEffect(() => {
    if (!visible) return;
    window.addEventListener('mousemove', handleMouseMove as any);
    window.addEventListener('mouseup', handleMouseUp);
    return () => {
      window.removeEventListener('mousemove', handleMouseMove as any);
      window.removeEventListener('mouseup', handleMouseUp);
    };
  }, [visible, handleMouseMove, handleMouseUp]);

  // Check if zone accepts current drag
  const zoneAcceptsDrag = useCallback((zone: SceneZone): boolean => {
    if (!drag.active || !drag.itemId) return false;
    if (zone.state === 'disabled' || zone.state === 'completed') return false;
    // Don't drop on yourself
    if (drag.sourceType === 'zone' && drag.sourceId === zone.id) return false;
    return zone.actions.some(a =>
      a.type === 'drag_receive' &&
      a.enabled !== false &&
      (a.acceptItems?.includes(drag.itemId!) ?? true)
    );
  }, [drag]);

  const handleZoneDragEnter = useCallback((zoneId: string) => {
    if (drag.active) {
      setDropTargetZone(zoneId);
      if (drag.sourceType === 'zone') {
        nuiCallback('propInteract:zoneDragSnap', { targetZoneId: zoneId });
      }
    }
  }, [drag.active, drag.sourceType]);

  const handleZoneDragLeave = useCallback(() => {
    setDropTargetZone(null);
    if (drag.active && drag.sourceType === 'zone') {
      nuiCallback('propInteract:zoneDragSnap', { targetZoneId: null });
    }
  }, [drag.active, drag.sourceType]);

  // ============================================================
  // Orbit (drag on background to rotate camera)
  // ============================================================

  const handleOrbitStart = useCallback((e: React.MouseEvent) => {
    if (drag.active) return;
    if (scene?.allowOrbit === false) return;
    setOrbiting(true);
    orbitStartRef.current = { x: e.clientX, y: e.clientY };
    nuiCallback('propInteract:orbitStart', {});
  }, [drag.active, scene?.allowOrbit]);

  const handleWheel = useCallback((e: React.WheelEvent) => {
    if (scene?.allowZoom === false) return;
    const delta = e.deltaY > 0 ? 1 : -1;
    nuiCallback('propInteract:zoom', { delta });
  }, [scene?.allowZoom]);

  // ============================================================
  // Render helpers
  // ============================================================

  const getZoneActionHint = (zone: SceneZone): string | null => {
    const action = zone.actions.find(a => {
      if (a.enabled === false) return false;
      if (a.type === 'drag_receive') return false;
      return true;
    });
    if (!action) return null;
    if (action.requiredTool && action.requiredTool !== activeTool) {
      const tool = tools.find(t => t.id === action.requiredTool);
      return tool ? `Requis: ${tool.label}` : null;
    }
    if (action.type === 'hold') return 'Maintenir clic';
    if (action.type === 'click') return 'Cliquer';
    return null;
  };

  const getDragInfo = (): { label: string; icon: string; image?: string } => {
    if (!drag.itemId) return { label: '', icon: 'circle' };
    // Zone source: get info from the zone
    if (drag.sourceType === 'zone' && drag.sourceId) {
      const zone = zones.find(z => z.id === drag.sourceId);
      if (zone) return { label: zone.label, icon: zone.icon, image: zone.image };
    }
    // Item source: get info from the item
    const item = items.find(i => i.id === drag.itemId);
    if (item) return { label: item.label, icon: item.icon, image: item.image };
    return { label: drag.itemId, icon: 'circle' };
  };

  // Hold progress ring circumference
  const RING_RADIUS = 28;
  const RING_CIRCUMFERENCE = 2 * Math.PI * RING_RADIUS;

  // ============================================================
  // Render
  // ============================================================

  if (!mounted) return null;
  const sceneColor = scene?.color || primaryColor;
  const accentVars = scene?.color
    ? generateAccentVars('--pi-accent', scene.color)
    : piAccentVars;

  return (
    <div
      className={`pi-container ${hiding ? 'pi-closing' : ''}`}
      style={accentVars}
      onMouseMove={handleMouseMove as any}
    >
      {/* Orbit overlay (background drag) */}
      <div
        className={`pi-orbit-overlay ${orbiting ? 'pi-orbiting' : ''}`}
        onMouseDown={handleOrbitStart}
        onWheel={handleWheel}
      />

      {/* Header */}
      {scene && (
        <div className="pi-header">
          <div className="pi-header-title">{scene.title}</div>
          {scene.subtitle && <div className="pi-header-subtitle">{scene.subtitle}</div>}
        </div>
      )}

      {/* Close button */}
      <button className="pi-close-btn" onClick={handleClose}>
        <X size={18} />
      </button>

      {/* Keybind hint */}
      <div className="pi-keybind-hint">
        <span className="pi-keybind-key">ESC</span>
        <span className="pi-keybind-text">Fermer</span>
        {scene?.allowOrbit !== false && (
          <>
            <span style={{ width: 1, height: 16, background: 'rgba(255,255,255,0.1)', margin: '0 4px' }} />
            <span className="pi-keybind-key">Clic</span>
            <span className="pi-keybind-text">Tourner la caméra</span>
          </>
        )}
        {scene?.allowZoom !== false && (
          <>
            <span style={{ width: 1, height: 16, background: 'rgba(255,255,255,0.1)', margin: '0 4px' }} />
            <span className="pi-keybind-key">Scroll</span>
            <span className="pi-keybind-text">Zoomer</span>
          </>
        )}
      </div>

      {/* Notifications */}
      <div className="pi-notifications">
        {notifications.map(n => {
          const NotifIcon = n.type === 'success' ? Check : n.type === 'error' ? AlertCircle : Info;
          return (
            <div key={n.id} className={`pi-notification pi-notif-${n.type}`}>
              <NotifIcon size={14} style={{ marginRight: 6, verticalAlign: 'middle' }} />
              {n.text}
            </div>
          );
        })}
      </div>

      {/* Tools panel (left) */}
      {tools.length > 0 && (
        <div className="pi-tools-panel">
          <div className="pi-tools-label">Outils</div>
          {tools.map(tool => {
            const Icon = getIcon(tool.icon);
            return (
              <button
                key={tool.id}
                className={`pi-tool-btn ${activeTool === tool.id ? 'pi-tool-active' : ''}`}
                onClick={() => handleSelectTool(tool.id)}
              >
                <Icon size={22} />
                <span className="pi-tool-btn-label">{tool.label}</span>
                {tool.description && (
                  <span className="pi-tool-tooltip">{tool.description}</span>
                )}
              </button>
            );
          })}
        </div>
      )}

      {/* Items panel (right) */}
      {items.length > 0 && (
        <div className="pi-items-panel">
          <div className="pi-items-label">Objets</div>
          {items.map(item => {
            const Icon = getIcon(item.icon);
            const isEmpty = item.count <= 0;
            return (
              <div
                key={item.id}
                className={`pi-item-card ${isEmpty ? 'pi-item-empty' : ''}`}
                onMouseDown={(e) => !isEmpty && item.draggable !== false && handleItemDragStart(item, e)}
              >
                {item.image
                  ? <img src={item.image} alt={item.label} className="pi-item-card-img" />
                  : <Icon size={22} />
                }
                <span className="pi-item-card-label">{item.label}</span>
                {item.count > 1 && <span className="pi-item-count">x{item.count}</span>}
                <span className="pi-item-tooltip">{item.label} ({item.count})</span>
              </div>
            );
          })}
        </div>
      )}

      {/* Results tray (bottom right) */}
      {scene?.showResults !== false && results.length > 0 && (
        <div className="pi-results-panel">
          <div className="pi-results-label">Résultats</div>
          {results.map(r => {
            const Icon = getIcon(r.icon);
            return (
              <div key={r.id} className="pi-result-item">
                <Icon size={16} />
                <span className="pi-result-item-text">{r.label}</span>
                <span className="pi-result-item-count">x{r.count}</span>
              </div>
            );
          })}
        </div>
      )}

      {/* Zone markers (positioned at 3D screen coords) */}
      {zones.map(zone => {
        const Icon = getIcon(zone.icon);
        const isDropTarget = dropTargetZone === zone.id && zoneAcceptsDrag(zone);
        const actionHint = getZoneActionHint(zone);
        const isHolding = holdProgress?.zoneId === zone.id;
        const totalHeld = zone.heldItems?.reduce((sum, h) => sum + h.count, 0) ?? 0;
        const scaleByDistance = zone.distance > 0 ? Math.max(0.6, Math.min(1.2, 3 / zone.distance)) : 1;

        return (
          <div
            key={zone.id}
            className={`pi-zone ${!zone.visible || (drag.active && drag.sourceType === 'zone' && drag.sourceId === zone.id) ? 'pi-zone-hidden' : ''}`}
            style={{
              left: `${zone.screenX * 100}%`,
              top: `${zone.screenY * 100}%`,
              transform: `translate(-50%, -50%) scale(${scaleByDistance})`,
            }}
            onMouseEnter={() => drag.active && zoneAcceptsDrag(zone) && handleZoneDragEnter(zone.id)}
            onMouseLeave={() => drag.active && handleZoneDragLeave()}
          >
            <div
              className={`pi-zone-marker pi-zone-${zone.state} ${isDropTarget ? 'pi-zone-drop-target' : ''} ${zone.image ? 'pi-zone-has-image' : ''} ${zone.draggable ? 'pi-zone-draggable' : ''}`}
              onMouseDown={(e) => handleZoneMouseDown(zone, e)}
            >
              {zone.image
                ? <img src={zone.image} alt={zone.label} className="pi-zone-marker-img" />
                : <Icon size={20} />
              }

              {/* Pulse ring */}
              {zone.pulse && zone.state !== 'completed' && zone.state !== 'disabled' && (
                <div className="pi-zone-pulse" />
              )}

              {/* Held items badge */}
              {totalHeld > 0 && (
                <div className="pi-zone-held">{totalHeld}</div>
              )}

              {/* Hold progress ring */}
              {isHolding && holdProgress && (
                <div className="pi-hold-ring">
                  <svg viewBox="0 0 60 60">
                    <circle className="pi-hold-ring-bg" cx="30" cy="30" r={RING_RADIUS} />
                    <circle
                      className="pi-hold-ring-progress"
                      cx="30"
                      cy="30"
                      r={RING_RADIUS}
                      strokeDasharray={RING_CIRCUMFERENCE}
                      strokeDashoffset={RING_CIRCUMFERENCE * (1 - holdProgress.progress / 100)}
                    />
                  </svg>
                </div>
              )}
            </div>

            {/* Label */}
            <div className="pi-zone-label">{zone.tooltip || zone.label}</div>

            {/* Action hint */}
            {actionHint && <div className="pi-zone-action-hint">{actionHint}</div>}
          </div>
        );
      })}

      {/* Drag ghost */}
      {drag.active && (() => {
        const info = getDragInfo();
        const GhostIcon = getIcon(info.icon);
        return (
          <div className="pi-drag-ghost" style={{ left: drag.x, top: drag.y }}>
            {info.image
              ? <img src={info.image} alt={info.label} className="pi-drag-ghost-img" />
              : <GhostIcon size={16} />
            }
            <span className="pi-drag-ghost-label">{info.label}</span>
          </div>
        );
      })()}
    </div>
  );
};

export default PropInteract;
