import React, { useState, useEffect, useRef } from 'react';
import { FreejobMarkerData } from './types';
import './Freejob.css';

const FreejobMarker: React.FC = () => {
  const [markers, setMarkers] = useState<Record<string, FreejobMarkerData>>({});
  const [screenPositions, setScreenPositions] = useState<Record<string, { x: number; y: number; visible: boolean }>>({});

  useEffect(() => {
    const handler = (event: MessageEvent) => {
      const msg = event.data || {};
      if (msg.action === 'freejobMarker:add' && msg.data) {
        setMarkers(prev => ({ ...prev, [msg.data.id]: msg.data }));
      } else if (msg.action === 'freejobMarker:update' && msg.data) {
        setMarkers(prev => {
          if (!prev[msg.data.id]) return prev;
          return { ...prev, [msg.data.id]: { ...prev[msg.data.id], ...msg.data } };
        });
      } else if (msg.action === 'freejobMarker:remove' && msg.data) {
        setMarkers(prev => {
          const copy = { ...prev };
          delete copy[msg.data.id];
          return copy;
        });
      } else if (msg.action === 'freejobMarker:clearAll') {
        setMarkers({});
      } else if (msg.action === 'freejobMarker:screenPos' && msg.data) {
        setScreenPositions(msg.data);
      }
    };
    window.addEventListener('message', handler);
    return () => window.removeEventListener('message', handler);
  }, []);

  const markerEntries = Object.values(markers);
  if (markerEntries.length === 0) return null;

  return (
    <>
      {markerEntries.map(m => {
        const sp = screenPositions[m.id];
        if (!sp || !sp.visible) return null;

        return (
          <div
            key={m.id}
            className="fjmarker"
            style={{
              left: `${sp.x * 100}%`,
              top: `${sp.y * 100}%`,
            }}
          >
            <div className="fjmarker-pulse" />
            <div className="fjmarker-dot" />
            {m.label && <div className="fjmarker-label">{m.label}</div>}
            <div className="fjmarker-key">E</div>
          </div>
        );
      })}
    </>
  );
};

export default FreejobMarker;
