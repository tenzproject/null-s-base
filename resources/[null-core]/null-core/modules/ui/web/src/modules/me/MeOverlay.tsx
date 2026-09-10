import React, { useCallback, useEffect, useState } from 'react';
import './MeOverlay.css';

type MeEntry = {
  id: string | number;
  text: string;
  x: number;
  y: number;
  color?: { r?: number; g?: number; b?: number; a?: number };
  kind?: 'me' | 'admin';
};

type RenderedMeEntry = MeEntry & {
  exiting?: boolean;
};

const clamp = (value: number, min: number, max: number) => Math.min(max, Math.max(min, value));

const MeBubble: React.FC<{ entry: RenderedMeEntry; onExitDone: (id: MeEntry['id']) => void }> = ({ entry, onExitDone }) => {
  const [displayText, setDisplayText] = useState('');
  const [shinePhase, setShinePhase] = useState<'none' | 'in' | 'out'>('none');

  useEffect(() => {
    const text = String(entry.text || '');
    setDisplayText('');
    setShinePhase('none');

    if (!text) {
      setShinePhase('in');
      return;
    }

    let index = 0;
    const timer = window.setInterval(() => {
      index += 1;
      setDisplayText(text.slice(0, index));

      if (index >= text.length) {
        window.clearInterval(timer);
        setShinePhase('in');
      }
    }, 22);

    return () => window.clearInterval(timer);
  }, [entry.id, entry.text]);

  useEffect(() => {
    if (shinePhase === 'none') return;

    const timer = window.setTimeout(() => setShinePhase('none'), 900);
    return () => window.clearTimeout(timer);
  }, [shinePhase]);

  useEffect(() => {
    if (!entry.exiting) return;

    const text = String(entry.text || '');
    let index = text.length;

    setDisplayText(text);
    setShinePhase('out');

    const timer = window.setInterval(() => {
      index -= 1;
      setDisplayText(text.slice(0, Math.max(index, 0)));

      if (index <= 0) {
        window.clearInterval(timer);
        window.setTimeout(() => onExitDone(entry.id), 120);
      }
    }, 18);

    return () => window.clearInterval(timer);
  }, [entry.exiting, entry.id, entry.text, onExitDone]);

  return (
    <div
      className={`me-bubble ${shinePhase === 'in' ? 'me-bubble-shine-in' : ''} ${shinePhase === 'out' ? 'me-bubble-shine-out me-bubble-exiting' : ''} ${entry.kind === 'admin' ? 'me-bubble-admin' : ''}`}
      style={{
        left: `${clamp(entry.x, 0, 1) * 100}%`,
        top: `${clamp(entry.y, 0, 1) * 100}%`,
      }}
    >
      <span>{displayText}</span>
    </div>
  );
};

const MeOverlay: React.FC = () => {
  const [entries, setEntries] = useState<RenderedMeEntry[]>([]);

  useEffect(() => {
    const handler = (event: MessageEvent) => {
      const payload = event.data;
      if ((payload.action || payload.type) !== 'me:update') return;

      const nextEntries = Array.isArray(payload.entries) ? payload.entries : [];
      setEntries((currentEntries) => {
        const nextIds = new Set(nextEntries.map((entry: MeEntry) => String(entry.id)));
        const exitingEntries = currentEntries
          .filter((entry) => !nextIds.has(String(entry.id)) && !entry.exiting)
          .map((entry) => ({ ...entry, exiting: true }));

        return [
          ...nextEntries.map((entry: MeEntry) => ({ ...entry, exiting: false })),
          ...exitingEntries,
          ...currentEntries.filter((entry) => entry.exiting && !nextIds.has(String(entry.id))),
        ];
      });
    };

    window.addEventListener('message', handler);
    return () => window.removeEventListener('message', handler);
  }, []);

  const removeEntry = useCallback((id: MeEntry['id']) => {
    setEntries((currentEntries) => currentEntries.filter((entry) => String(entry.id) !== String(id)));
  }, []);

  if (entries.length === 0) return null;

  return (
    <div className="me-overlay" aria-hidden>
      {entries.map((entry) => <MeBubble key={entry.id} entry={entry} onExitDone={removeEntry} />)}
    </div>
  );
};

export default MeOverlay;
