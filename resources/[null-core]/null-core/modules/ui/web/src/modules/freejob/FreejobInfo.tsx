import React, { useState, useEffect, useCallback } from 'react';
import { X, Keyboard, Info, ArrowUp, ArrowDown, Hand } from 'lucide-react';
import { FreejobInfoProps, FreejobInfoData } from './types';
import './Freejob.css';

const GetParentResourceName = () => 'null-core';

const ICON_MAP: Record<string, React.ReactNode> = {
  up: <ArrowUp size={14} />,
  down: <ArrowDown size={14} />,
  hand: <Hand size={14} />,
  info: <Info size={14} />,
  keyboard: <Keyboard size={14} />,
};

const FreejobInfo: React.FC<FreejobInfoProps> = ({ visible, onClose }) => {
  const [data, setData] = useState<FreejobInfoData | null>(null);
  const [hiding, setHiding] = useState(false);

  useEffect(() => {
    const handler = (event: MessageEvent) => {
      const msg = event.data || {};
      if (msg.action === 'freejobInfo:open' && msg.data) {
        setData(msg.data);
      } else if (msg.action === 'freejobInfo:close') {
        handleClose();
      }
    };
    window.addEventListener('message', handler);
    return () => window.removeEventListener('message', handler);
  }, []);

  const handleClose = useCallback(() => {
    setHiding(true);
    setTimeout(() => {
      setHiding(false);
      setData(null);
      onClose();
      fetch(`https://${GetParentResourceName()}/freejobInfo:close`, { method: 'POST' }).catch(() => {});
    }, 250);
  }, [onClose]);

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape' && visible && data) handleClose();
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [visible, data, handleClose]);

  if (!visible && !hiding) return null;
  if (!data && !hiding) return null;
  if (!data) return null;

  return (
    <div className={`fjinfo-overlay ${hiding ? 'fj-hiding' : ''}`}>
      <div className="fjinfo">
        <div className="fjinfo-header">
          <h2>{data.title || 'Informations'}</h2>
          <button className="fjinfo-close" onClick={handleClose}>
            <X size={16} />
          </button>
        </div>

        <div className="fjinfo-lines">
          {data.lines && data.lines.map((line, i) => (
            <div key={i} className="fjinfo-line">
              <div className="fjinfo-line-key">{line.key || ''}</div>
              <div className="fjinfo-line-text">{line.text || ''}</div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};

export default FreejobInfo;
