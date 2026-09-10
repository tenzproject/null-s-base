import React, { useState, useEffect, useCallback, useMemo } from 'react';
import { Delete, Hash, X, Check } from 'lucide-react';
import { generateAccentVars } from '@/utils/accentColors';
import './DoorCodePad.css';

const GetParentResourceName = () => 'null-core';

const nui = async (event: string, data: Record<string, any> = {}) => {
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

interface Props {
  primaryColor?: string;
}

const MAX_LEN = 8;

const DoorCodePad: React.FC<Props> = ({ primaryColor = '#4A90E2' }) => {
  const [open, setOpen] = useState(false);
  const [doorId, setDoorId] = useState<number | null>(null);
  const [label, setLabel] = useState<string>('');
  const [code, setCode] = useState('');

  const accentVars = useMemo(
    () => generateAccentVars('--dcp-accent', primaryColor),
    [primaryColor]
  );

  useEffect(() => {
    const handler = (e: MessageEvent) => {
      const msg = e.data || {};
      if (!msg.type || typeof msg.type !== 'string' || !msg.type.startsWith('doorCode:')) return;
      if (msg.type === 'doorCode:open') {
        setDoorId(msg.id ?? null);
        setLabel(msg.label || '');
        setCode('');
        setOpen(true);
      } else if (msg.type === 'doorCode:close') {
        setOpen(false);
      }
    };
    window.addEventListener('message', handler);
    return () => window.removeEventListener('message', handler);
  }, []);

  const close = useCallback(() => {
    nui('doorlock:closeCode');
    setOpen(false);
  }, []);

  const submit = useCallback(() => {
    if (!code) return;
    nui('doorlock:submitCode', { id: doorId, code });
    setOpen(false);
  }, [code, doorId]);

  const press = useCallback((d: string) => {
    setCode(prev => (prev.length >= MAX_LEN ? prev : prev + d));
  }, []);

  const backspace = useCallback(() => setCode(prev => prev.slice(0, -1)), []);

  // Clavier physique
  useEffect(() => {
    if (!open) return;
    const onKey = (e: KeyboardEvent) => {
      if (e.key >= '0' && e.key <= '9') { e.preventDefault(); press(e.key); }
      else if (e.key === 'Backspace') { e.preventDefault(); backspace(); }
      else if (e.key === 'Enter') { e.preventDefault(); submit(); }
      else if (e.key === 'Escape') { e.preventDefault(); close(); }
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [open, press, backspace, submit, close]);

  if (!open) return null;

  const keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9'];

  return (
    <div className="dcp-overlay" style={accentVars}>
      <div className="dcp-pad">
        <div className="dcp-header">
          <div className="dcp-header-icon"><Hash size={18} /></div>
          <div>
            <div className="dcp-title">Code de la porte</div>
            {label && <div className="dcp-sub">{label}</div>}
          </div>
          <button className="dcp-close" onClick={close}><X size={16} /></button>
        </div>

        <div className="dcp-display">
          {Array.from({ length: MAX_LEN }).map((_, i) => (
            <span key={i} className={`dcp-dot ${i < code.length ? 'filled' : ''}`} />
          ))}
        </div>

        <div className="dcp-keys">
          {keys.map(k => (
            <button key={k} className="dcp-key" onClick={() => press(k)}>{k}</button>
          ))}
          <button className="dcp-key dcp-key-action" onClick={backspace}><Delete size={18} /></button>
          <button className="dcp-key" onClick={() => press('0')}>0</button>
          <button className="dcp-key dcp-key-confirm" onClick={submit}><Check size={18} /></button>
        </div>
      </div>
    </div>
  );
};

export default DoorCodePad;
