import React, { useEffect, useRef, useState, useCallback } from 'react';
import { hudPositionManager } from '../../utils/hudPositionManager';
import { getAnchorTransform } from '../../utils/anchorPositioning';
import { HUD_MODULES } from '../hud-editor/HUDModulesConfig';
import { cacheImg } from '@shared/cacheVersion';
import './InventoryNotifications.css';

interface InventoryNotificationsProps {
  hudEditorOpen?: boolean;
  previewMode?: boolean;
}

interface InvNotif {
  key: string;
  add: boolean;
  name: string;  // technical name (for image lookup)
  label: string; // display label
  count: number;
  bumpToken: number; // increment to trigger bump animation
}

const DISPLAY_MS = 2500;
const FADE_MS = 220;
const FALLBACK_IMG = cacheImg('items/box.png');

const resolveImg = (name: string): string => {
  if (!name) return FALLBACK_IMG;
  // Money accounts use the same images as the inventory
  if (name === 'cash') return cacheImg('items/cash.webp');
  if (name === 'dirtycash') return cacheImg('items/dirtycash.webp');
  if (name === 'bank') return cacheImg('items/bank.webp');
  return cacheImg(`items/${name}.webp`);
};

const InventoryNotifications: React.FC<InventoryNotificationsProps> = ({
  hudEditorOpen = false,
  previewMode = false,
}) => {
  const [actualPosition, setActualPosition] = useState<{ x: number; y: number; anchor: string } | null>(null);
  const [items, setItems] = useState<InvNotif[]>(previewMode ? [
    { key: 'add_pomme', add: true, name: 'pomme', label: 'Pomme', count: 3, bumpToken: 0 },
    { key: 'remove_bread', add: false, name: 'bread', label: 'Pain', count: 1, bumpToken: 0 },
  ] : []);
  const timeoutsRef = useRef<Map<string, number>>(new Map());

  /* ---- Position ---- */
  useEffect(() => {
    if (previewMode) return;
    const update = () => {
      const pos = hudPositionManager.getPosition('inventory_notifications');
      if (pos) setActualPosition(pos);
    };
    hudPositionManager.onReady(update);
    window.addEventListener('hudLayoutChanged', update);
    return () => window.removeEventListener('hudLayoutChanged', update);
  }, [previewMode]);

  /* ---- Schedule removal ---- */
  const scheduleRemoval = useCallback((key: string) => {
    const existing = timeoutsRef.current.get(key);
    if (existing) window.clearTimeout(existing);
    const t = window.setTimeout(() => {
      // Trigger fade-out; actual removal happens in a follow-up timer
      setItems(prev => prev.map(it => it.key === key ? { ...it, count: it.count } : it));
      const el = document.querySelector<HTMLDivElement>(`[data-invn-key="${CSS.escape(key)}"]`);
      if (el) el.classList.add('invn-leaving');
      const t2 = window.setTimeout(() => {
        setItems(prev => prev.filter(it => it.key !== key));
        timeoutsRef.current.delete(key);
      }, FADE_MS);
      timeoutsRef.current.set(key, t2);
    }, DISPLAY_MS);
    timeoutsRef.current.set(key, t);
  }, []);

  /* ---- NUI handler ---- */
  useEffect(() => {
    if (previewMode) return;
    const handler = (event: MessageEvent) => {
      const d = event.data;
      if ((d?.action || d?.type) !== 'inventoryNotification') return;

      const add = !!d.add;
      const label: string = String(d.label ?? '');
      const name: string = String(d.name ?? d.itemName ?? label ?? '').toLowerCase().replace(/\s+/g, '_');
      const count: number = Number(d.count) || 1;
      if (!label && !name) return;

      const key = `${add ? 'add' : 'rm'}_${name || label}`;

      setItems(prev => {
        const idx = prev.findIndex(it => it.key === key);
        if (idx >= 0) {
          const updated = [...prev];
          updated[idx] = {
            ...updated[idx],
            count: updated[idx].count + count,
            bumpToken: updated[idx].bumpToken + 1,
          };
          return updated;
        }
        return [...prev, { key, add, name, label: label || name, count, bumpToken: 0 }];
      });
      scheduleRemoval(key);
    };
    window.addEventListener('message', handler);
    return () => window.removeEventListener('message', handler);
  }, [previewMode, scheduleRemoval]);

  /* ---- Cleanup on unmount ---- */
  useEffect(() => {
    return () => {
      timeoutsRef.current.forEach(t => window.clearTimeout(t));
      timeoutsRef.current.clear();
    };
  }, []);

  if (hudEditorOpen && !previewMode) return null;
  if (!previewMode && items.length === 0) return null;

  const defaultConfig = HUD_MODULES.find(m => m.id === 'inventory_notifications');
  const positionStyle: React.CSSProperties = previewMode
    ? { position: 'relative', left: 0, top: 0, transform: 'none' }
    : actualPosition
      ? {
          position: 'fixed',
          left: `${actualPosition.x}%`,
          top: `${actualPosition.y}%`,
          transform: getAnchorTransform(actualPosition.anchor as any),
        }
      : defaultConfig
        ? {
            position: 'fixed',
            left: `${defaultConfig.defaultPosition.x}%`,
            top: `${defaultConfig.defaultPosition.y}%`,
            transform: getAnchorTransform(defaultConfig.anchor as any),
          }
        : { position: 'fixed', left: '50%', top: '82%', transform: 'translate(-50%, -100%)' };

  return (
    <div className="invn-wrapper" style={{ ...positionStyle, zIndex: 99 }}>
      {items.map(it => (
        <div
          key={it.key}
          data-invn-key={it.key}
          className={`invn-item ${it.add ? 'invn-add' : 'invn-remove'}`}
        >
          <div className="invn-content">
            <img
              src={resolveImg(it.name)}
              alt={it.label}
              className="invn-img"
              draggable={false}
              onError={(e) => { (e.target as HTMLImageElement).src = FALLBACK_IMG; }}
            />
          </div>
          <span key={it.bumpToken} className={`invn-count ${it.add ? 'invn-count-add' : 'invn-count-remove'} invn-bump`}>
            {it.add ? '+' : '-'}{it.count}
          </span>
          <span className="invn-label">{it.label}</span>
        </div>
      ))}
    </div>
  );
};

export default InventoryNotifications;
