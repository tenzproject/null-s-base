import React, { useState, useEffect } from 'react';
import { DoorPromptProps, DoorPromptState } from './types';
import lockIcon from './lock.png';
import unlockIcon from './unlock.png';
import './DoorPrompt.css';

const BASE_W = 1920;
const BASE_H = 1080;

const DEFAULT_STATE: DoorPromptState = {
  id: null,
  screenX: 0,
  screenY: 0,
  distance: 99,
  locked: true,
  label: undefined,
  interactKey: 'E',
  canInteract: false,
  show: false,
};

const DoorPrompt: React.FC<DoorPromptProps> = () => {
  const [state, setState] = useState<DoorPromptState>(DEFAULT_STATE);

  useEffect(() => {
    const handler = (event: MessageEvent) => {
      const msg = event.data || {};
      if (!msg.type || typeof msg.type !== 'string') return;
      if (!msg.type.startsWith('doorPrompt:')) return;

      switch (msg.type) {
        case 'doorPrompt:update':
          setState(prev => ({
            ...prev,
            ...msg,
            show: msg.show !== false,
          }));
          break;
        case 'doorPrompt:hide':
          setState(prev => ({ ...prev, show: false }));
          break;
      }
    };
    window.addEventListener('message', handler);
    return () => window.removeEventListener('message', handler);
  }, []);

  if (!state.show) return null;

  const left = `${(state.screenX / BASE_W) * 100}%`;
  const top = `${(state.screenY / BASE_H) * 100}%`;

  // Échelle légère selon la distance (plus proche = plus grand).
  const scale = Math.max(0.7, Math.min(1.15, 2.2 / Math.max(0.5, state.distance)));

  return (
    <div
      className={`dl-prompt ${state.locked ? 'dl-locked' : 'dl-unlocked'} ${state.canInteract ? 'dl-active' : 'dl-passive'}`}
      style={{
        left,
        top,
        transform: `translate(-50%, -50%) scale(${scale})`,
      }}
    >
      <div className="dl-icon-shell">
        <img className="dl-state-icon dl-lock-icon" src={lockIcon} alt="" />
        <img className="dl-state-icon dl-unlock-icon" src={unlockIcon} alt="" />
      </div>
    </div>
  );
};

export default DoorPrompt;
