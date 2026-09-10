import React, { useEffect, useRef, useState } from 'react';
import { hudPositionManager } from '../../utils/hudPositionManager';
import { getAnchorTransform } from '../../utils/anchorPositioning';
import './AmmoHud.css';

interface AmmoHudProps {
  hudEditorOpen?: boolean;
  primaryColor?: string;
  previewMode?: boolean;
  previewPosition?: { x: number; y: number };
}

interface AmmoData {
  visible: boolean;
  clip: number;
  mag: number;
  mags: number;
  label: string;
}

function hexToRgb(hex?: string): string {
  if (!hex) return '255, 255, 255';
  const m = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex.trim());
  if (!m) return '255, 255, 255';
  return `${parseInt(m[1], 16)}, ${parseInt(m[2], 16)}, ${parseInt(m[3], 16)}`;
}

/**
 * 2D ammo HUD rendered next to the minimap. Opt-in via HUD Editor
 * (ammo module → variant "2d"). Data is pushed by Lua
 * `modules/_core/ui/client/ammo-hud.lua` via NUI message { type: "ammoStatus" }.
 */
const AmmoHud: React.FC<AmmoHudProps> = ({
  hudEditorOpen = false,
  primaryColor,
  previewMode = false,
  previewPosition,
}) => {
  const [data, setData] = useState<AmmoData>({
    visible: previewMode,
    clip: previewMode ? 17 : 0,
    mag: previewMode ? 17 : 0,
    mags: previewMode ? 3 : 0,
    label: previewMode ? 'PISTOL' : '',
  });
  const [position, setPosition] = useState<{ x: number; y: number; anchor: string } | null>(null);
  const [show, setShow] = useState(previewMode);
  const [animState, setAnimState] = useState<'entering' | 'leaving' | 'idle'>('idle');
  const prevVisibleRef = useRef<boolean>(previewMode);

  // Listen for layout + ammo status messages
  useEffect(() => {
    if (previewMode) return;

    hudPositionManager.onReady(() => {
      const pos = hudPositionManager.getPosition('ammo');
      if (pos) setPosition(pos);
    });

    const handler = (event: MessageEvent) => {
      const payload = event.data;
      if ((payload.type || payload.action) !== 'ammoStatus') return;
      setData({
        visible: !!payload.visible,
        clip:    Number(payload.clip  ?? 0),
        mag:     Number(payload.mag   ?? 0),
        mags:    Number(payload.mags  ?? 0),
        label:   String(payload.label ?? ''),
      });
    };
    window.addEventListener('message', handler);
    return () => window.removeEventListener('message', handler);
  }, [previewMode]);

  // Pop-in / pop-out animation synced with visibility (mirrors StatusBar)
  useEffect(() => {
    if (previewMode) return;
    if (prevVisibleRef.current === data.visible) return;
    prevVisibleRef.current = data.visible;

    if (data.visible) {
      setShow(true);
      setAnimState('entering');
      const t = setTimeout(() => setAnimState('idle'), 300);
      return () => clearTimeout(t);
    }
    setAnimState('leaving');
    const t = setTimeout(() => { setShow(false); setAnimState('idle'); }, 250);
    return () => clearTimeout(t);
  }, [data.visible, previewMode]);

  if (hudEditorOpen && !previewMode) return null;
  if (!show && !previewMode) return null;

  // In preview mode DraggableModule wraps us already, so keep the card at 0/0.
  void previewPosition;
  const positionStyle: React.CSSProperties = previewMode
    ? { left: '0', top: '0', transform: 'none' }
    : position
      ? {
          left: `${position.x}%`,
          top: `${position.y}%`,
          transform: getAnchorTransform(position.anchor as any),
        }
      : { left: '22%', top: '99.3%', transform: 'translate(0, -100%)' };

  const lowClip = data.mag > 0 && data.clip / data.mag < 0.25;
  const noMags = data.mags === 0;

  const cardClass = [
    'ammo-card',
    animState === 'entering' ? 'ammo-entering' : '',
    animState === 'leaving'  ? 'ammo-leaving'  : '',
    lowClip && animState === 'idle' ? 'ammo-low' : '',
    noMags ? 'ammo-empty' : '',
  ].filter(Boolean).join(' ');

  const accent = primaryColor || '#ffffff';

  return (
    <div
      className={`ammo-wrapper ${previewMode ? '' : 'fixed'}`}
      style={{ ...positionStyle, zIndex: 100 }}
    >
      <div
        className={cardClass}
        style={{
          // CSS custom properties consumed by AmmoHud.css
          ['--ammo-color' as any]: accent,
          ['--ammo-color-rgb' as any]: hexToRgb(accent),
        }}
      >
        {/* Bullet icon */}
        <svg className="ammo-icon" viewBox="0 0 512 512">
          <path d="M96 32L64 96V288H224V96L192 32H96zM64 320V416c0 17.7 14.3 32 32 32H192c17.7 0 32-14.3 32-32V320H64zm192 96H384V320H256v96zM256 288H384V96H256V288z" />
        </svg>

        {/* Clip / Max */}
        <div className="ammo-clip">
          <span className="ammo-clip-value">{data.clip}</span>
          <span className="ammo-clip-max">/{data.mag}</span>
        </div>

        <div className="ammo-divider" />

        {/* Magazines */}
        <div className="ammo-mags" title="Chargeurs en réserve">
          <svg className="ammo-mags-icon" viewBox="0 0 512 512">
            <path d="M144 32C117.5 32 96 53.5 96 80V432c0 26.5 21.5 48 48 48H368c26.5 0 48-21.5 48-48V80c0-26.5-21.5-48-48-48H144zm32 80H336v32H176V112z" />
          </svg>
          <span className="ammo-mags-count">x{data.mags}</span>
        </div>
      </div>
    </div>
  );
};

export default AmmoHud;
