import React, { useEffect, useRef, useState } from 'react';
import { hudPositionManager } from '../../utils/hudPositionManager';
import { getAnchorTransform } from '../../utils/anchorPositioning';
import { HUD_MODULES } from '../hud-editor/HUDModulesConfig';
import './HelpNotification.css';

interface HelpNotificationProps {
  hudEditorOpen?: boolean;
  primaryColor?: string;
  previewMode?: boolean;
  previewPosition?: { x: number; y: number };
}

interface HelpData {
  visible: boolean;
  message: string;
  key?: string;
}

/**
 * Splits a GTA-style message string (containing ~r~, ~g~, ~b~, ~y~, ~p~, ~o~,
 * ~w~, ~s~, ~h~, ~n~ tokens) into styled segments.
 */
function renderStyledMessage(msg: string): React.ReactNode {
  if (!msg) return null;
  // Remove ~INPUT_*~ tokens (already extracted into the key badge by Lua).
  const cleaned = msg.replace(/~INPUT_[A-Z0-9_]+~/g, '');

  const colorMap: Record<string, string> = {
    r: 'hn-msg-r',
    g: 'hn-msg-g',
    b: 'hn-msg-b',
    y: 'hn-msg-y',
    p: 'hn-msg-p',
    o: 'hn-msg-o',
  };

  const segments: { text: string; cls?: string }[] = [];
  let current: { text: string; cls?: string } = { text: '', cls: undefined };
  let i = 0;
  while (i < cleaned.length) {
    const ch = cleaned[i];
    if (ch === '~') {
      // Find closing tilde
      const end = cleaned.indexOf('~', i + 1);
      if (end > i) {
        const token = cleaned.substring(i + 1, end);
        // Flush current segment
        if (current.text) segments.push(current);
        if (token === 's' || token === 'w' || token === 'n' || token === 'h') {
          current = { text: '', cls: undefined };
        } else if (colorMap[token]) {
          current = { text: '', cls: colorMap[token] };
        } else {
          // Unknown token — drop it, keep current style
          current = { text: '', cls: current.cls };
        }
        i = end + 1;
        continue;
      }
    }
    current.text += ch;
    i++;
  }
  if (current.text) segments.push(current);

  return segments.map((seg, idx) => (
    <span key={idx} className={seg.cls}>{seg.text}</span>
  ));
}

const HelpNotification: React.FC<HelpNotificationProps> = ({
  hudEditorOpen = false,
  primaryColor,
  previewMode = false,
  previewPosition,
}) => {
  const [data, setData] = useState<HelpData>({
    visible: previewMode,
    message: previewMode ? 'Appuie pour interagir' : '',
    key: previewMode ? 'E' : undefined,
  });
  const [actualPosition, setActualPosition] = useState<{ x: number; y: number; anchor: string } | null>(null);
  const [show, setShow] = useState(previewMode);
  const [animState, setAnimState] = useState<'entering' | 'leaving' | 'idle'>('idle');
  const prevVisibleRef = useRef<boolean>(previewMode);

  // Position
  useEffect(() => {
    if (previewMode) return;
    hudPositionManager.onReady(() => {
      const pos = hudPositionManager.getPosition('help_notification');
      if (pos) setActualPosition(pos);
    });
  }, [previewMode]);

  // NUI messages
  useEffect(() => {
    if (previewMode) return;
    const handler = (event: MessageEvent) => {
      const payload = event.data;
      if ((payload.type || payload.action) !== 'helpNotification') return;
      setData({
        visible: !!payload.visible,
        message: String(payload.message ?? ''),
        key: payload.key ? String(payload.key) : undefined,
      });
    };
    window.addEventListener('message', handler);
    return () => window.removeEventListener('message', handler);
  }, [previewMode]);

  // Pop-in / pop-out animation
  useEffect(() => {
    if (previewMode) return;
    if (prevVisibleRef.current === data.visible) return;
    prevVisibleRef.current = data.visible;

    if (data.visible) {
      setShow(true);
      setAnimState('entering');
      const t = setTimeout(() => setAnimState('idle'), 250);
      return () => clearTimeout(t);
    }
    setAnimState('leaving');
    const t = setTimeout(() => { setShow(false); setAnimState('idle'); }, 200);
    return () => clearTimeout(t);
  }, [data.visible, previewMode]);

  if (hudEditorOpen && !previewMode) return null;
  if (!show && !previewMode) return null;
  if (!data.message && !previewMode) return null;

  void previewPosition;
  const defaultConfig = HUD_MODULES.find(m => m.id === 'help_notification');
  const positionStyle: React.CSSProperties = previewMode
    ? { left: '0', top: '0', transform: 'none' }
    : actualPosition
      ? {
          left: `${actualPosition.x}%`,
          top: `${actualPosition.y}%`,
          transform: getAnchorTransform(actualPosition.anchor as any),
        }
      : defaultConfig
        ? {
            left: `${defaultConfig.defaultPosition.x}%`,
            top: `${defaultConfig.defaultPosition.y}%`,
            transform: getAnchorTransform(defaultConfig.anchor as any),
          }
        : { left: '1.5%', top: '25%' };

  const cardClass = [
    'hn-card',
    animState === 'entering' ? 'hn-entering' : '',
    animState === 'leaving' ? 'hn-leaving' : '',
  ].filter(Boolean).join(' ');

  const accent = primaryColor || '#c8c8c8';

  return (
    <div
      className={`hn-wrapper ${previewMode ? '' : 'fixed'}`}
      style={{ ...positionStyle, zIndex: 100 }}
    >
      <div
        className={cardClass}
        style={{ ['--hn-accent' as any]: accent }}
      >
        {data.key && <span className="hn-key">{data.key}</span>}
        <span className="hn-message">{renderStyledMessage(data.message)}</span>
      </div>
    </div>
  );
};

export default HelpNotification;
