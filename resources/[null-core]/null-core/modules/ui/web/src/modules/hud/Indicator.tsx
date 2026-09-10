import React, { useEffect, useState, useMemo } from 'react';
import { HUD_MODULES } from '../hud-editor/HUDModulesConfig';
import { hudPositionManager } from '../../utils/hudPositionManager';
import { getAnchorTransform, AnchorPoint } from '../../utils/anchorPositioning';
import './Indicator.css';

interface IndicatorEntry {
  id: string;
  icon: string;
  label?: string;
  visible: boolean;
}

const DEFAULT_REGISTRY: Record<string, { icon: string; label: string }> = {
  safezone: {
    icon: 'nui://null-cache/images/indicators/protected.webp',
    label: 'Zone protégée',
  },
  'dangerous-zone': {
    icon: 'nui://null-cache/images/indicators/dangerous.png',
    label: 'Zone hostile',
  },
};

interface IndicatorProps {
  previewMode?: boolean;
  previewPosition?: { x: number; y: number } | null;
  previewAnchor?: AnchorPoint;
  primaryColor?: string;
}

const Indicator: React.FC<IndicatorProps> = ({
  previewMode = false,
  previewPosition,
  previewAnchor,
}) => {
  const [entries, setEntries] = useState<Record<string, IndicatorEntry>>(
    previewMode
      ? {
        safezone: {
          id: 'safezone',
          icon: DEFAULT_REGISTRY.safezone.icon,
          label: DEFAULT_REGISTRY.safezone.label,
          visible: true,
        },
      }
      : {}
  );
  const [actualPosition, setActualPosition] = useState<{ x: number; y: number; anchor: string } | null>(null);
  const [positionReady, setPositionReady] = useState(previewMode);

  useEffect(() => {
    if (previewMode) return;
    hudPositionManager.onReady(() => {
      const saved = hudPositionManager.getPosition('indicator');
      if (saved) setActualPosition(saved);
      setPositionReady(true);
    });
  }, [previewMode]);

  useEffect(() => {
    if (previewMode) return;
    const onMessage = (event: MessageEvent) => {
      const msg = event.data || {};
      if (msg.action !== 'indicator:update') return;
      const { id, visible, icon, label } = msg.data || {};
      if (!id) return;
      setEntries(prev => {
        const next = { ...prev };
        const fallback = DEFAULT_REGISTRY[id];
        next[id] = {
          id,
          visible: !!visible,
          icon: icon || fallback?.icon || '',
          label: label || fallback?.label || '',
        };
        return next;
      });
    };
    window.addEventListener('message', onMessage);
    return () => window.removeEventListener('message', onMessage);
  }, [previewMode]);

  const visibleEntries = useMemo(
    () => Object.values(entries).filter(e => e.visible && e.icon),
    [entries]
  );

  if (!positionReady) return null;
  if (!previewMode && visibleEntries.length === 0) return null;

  const defaultConfig = HUD_MODULES.find(m => m.id === 'indicator');

  let positionStyle: React.CSSProperties = {};
  if (previewMode && previewPosition) {
    positionStyle = { left: '0px', top: '0px', transform: 'none' };
  } else if (actualPosition) {
    positionStyle = {
      left: `${actualPosition.x}%`,
      top: `${actualPosition.y}%`,
      transform: getAnchorTransform(actualPosition.anchor as AnchorPoint),
    };
  } else if (defaultConfig) {
    positionStyle = {
      left: `${defaultConfig.defaultPosition.x}%`,
      top: `${defaultConfig.defaultPosition.y}%`,
      transform: getAnchorTransform((previewAnchor || defaultConfig.anchor) as AnchorPoint),
    };
  }

  return (
    <div className="vol-indicator-stack" style={positionStyle}>
      {visibleEntries.map(e => (
        <div key={e.id} className={`vol-indicator vol-indicator-${e.id}`} title={e.label}>
          <img
            src={e.icon}
            alt={e.label || e.id}
            onError={(ev) => { (ev.target as HTMLImageElement).style.display = 'none'; }}
          />
        </div>
      ))}
    </div>
  );
};

export default Indicator;
