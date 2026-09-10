import React, { useEffect, useRef, useState } from 'react';
import { Target, X, Package, CheckCircle, XCircle } from 'lucide-react';

interface Props {
  duration: number;
  sweetSpotSize: number;
  maxAttempts: number;
  quantity: number;
  currentAttempt: number;
  totalAttempts: number;
  itemLabel: string;
  onSuccess: () => void;
  onFail: () => void;
  onCancel: () => void;
}

const StealMinigame: React.FC<Props> = ({
  duration, sweetSpotSize, maxAttempts, quantity, currentAttempt, totalAttempts,
  itemLabel, onSuccess, onFail, onCancel,
}) => {
  const [cursorPos, setCursorPos] = useState(0);
  const [sweetSpotStart, setSweetSpotStart] = useState(30);
  const [isRunning, setIsRunning] = useState(true);
  const [attemptsLeft, setAttemptsLeft] = useState(maxAttempts);
  const [result, setResult] = useState<'idle' | 'hit' | 'miss' | 'success' | 'fail'>('idle');

  const directionRef  = useRef(1);
  const speedRef      = useRef(100 / duration);
  const rafRef        = useRef<number | null>(null);
  const lastTimeRef   = useRef<number>(performance.now());
  const sweetSpotEnd  = sweetSpotStart + sweetSpotSize * 100;

  useEffect(() => {
    if (!isRunning || result === 'success' || result === 'fail') return;
    const tick = (now: number) => {
      const dt = (now - lastTimeRef.current) / 1000;
      lastTimeRef.current = now;
      setCursorPos(prev => {
        let next = prev + directionRef.current * speedRef.current * dt;
        if (next >= 100) { next = 100; directionRef.current = -1; }
        else if (next <= 0) { next = 0; directionRef.current = 1; }
        return next;
      });
      rafRef.current = requestAnimationFrame(tick);
    };
    lastTimeRef.current = performance.now();
    rafRef.current = requestAnimationFrame(tick);
    return () => { if (rafRef.current) cancelAnimationFrame(rafRef.current); };
  }, [isRunning, result, duration]);

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') { onCancel(); }
      else if ((e.key === ' ' || e.code === 'Space') && isRunning && result === 'idle') {
        e.preventDefault();
        attemptSteal();
      }
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [isRunning, result, cursorPos, sweetSpotStart, sweetSpotEnd]);

  const attemptSteal = () => {
    const inZone = cursorPos >= sweetSpotStart && cursorPos <= sweetSpotEnd;
    if (inZone) {
      setResult('hit');
      setTimeout(() => { setResult('success'); setTimeout(onSuccess, 500); }, 250);
    } else {
      const remaining = attemptsLeft - 1;
      setAttemptsLeft(remaining);
      setResult('miss');
      if (remaining <= 0) {
        setTimeout(() => { setResult('fail'); setTimeout(onFail, 500); }, 250);
      } else {
        setSweetSpotStart(Math.random() * (100 - sweetSpotSize * 100));
        setTimeout(() => setResult('idle'), 350);
      }
    }
  };

  const isDone = result === 'success' || result === 'fail';

  return (
    <div className="smg-overlay">
      <div className={`smg-card ${result}`}>

        {/* Header */}
        <div className="smg-header">
          <div className="smg-header-icon">
            <Target size={20} />
          </div>
          <div className="smg-header-text">
            <h2>Vol en cours</h2>
            <p>Synchronisez le curseur avec la zone verte</p>
          </div>
          <button className="smg-cancel-btn" onClick={onCancel} title="Annuler (ESC)">
            <X size={16} />
          </button>
        </div>

        {/* Item label + series progress */}
        <div className="smg-item-row">
          <Package size={15} />
          <span>{itemLabel}</span>
          {quantity > 1 && <span className="smg-qty-badge">×{quantity}</span>}
          <span className="smg-difficulty-badge" style={{
            color: sweetSpotSize >= 0.2 ? '#2ecc71' : sweetSpotSize >= 0.12 ? '#f39c12' : '#e74c3c',
          }}>
            {sweetSpotSize >= 0.2 ? 'Facile' : sweetSpotSize >= 0.12 ? 'Difficile' : 'Extrême'}
          </span>
        </div>
        {totalAttempts > 1 && (
          <div className="smg-series-row">
            <span className="smg-series-label">Série</span>
            <div className="smg-series-dots">
              {[...Array(totalAttempts)].map((_, i) => (
                <div key={i} className={`smg-series-dot ${i < currentAttempt ? 'done' : i === currentAttempt ? 'active' : ''}`} />
              ))}
            </div>
            <span className="smg-series-count">{currentAttempt + 1}/{totalAttempts}</span>
          </div>
        )}

        {/* Timing bar */}
        <div className="smg-bar-wrap">
          <div className="smg-bar">
            {/* Sweet spot */}
            <div
              className="smg-sweet"
              style={{ left: `${sweetSpotStart}%`, width: `${sweetSpotSize * 100}%` }}
            />
            {/* Cursor */}
            <div
              className={`smg-cursor ${result !== 'idle' ? 'frozen' : ''}`}
              style={{ left: `${cursorPos}%` }}
            />
            {/* Ticks */}
            {[...Array(11)].map((_, i) => (
              <div key={i} className="smg-tick" style={{ left: `${i * 10}%` }} />
            ))}
          </div>
          <div className="smg-bar-labels">
            <span>0%</span>
            <span>50%</span>
            <span>100%</span>
          </div>
        </div>

        {/* Attempts */}
        <div className="smg-attempts-row">
          <span className="smg-attempts-label">Essais</span>
          <div className="smg-dots">
            {[...Array(maxAttempts)].map((_, i) => (
              <div key={i} className={`smg-dot ${i < attemptsLeft ? 'active' : 'used'}`} />
            ))}
          </div>
          <span className="smg-attempts-count">{attemptsLeft}/{maxAttempts}</span>
        </div>

        {/* Status */}
        <div className="smg-status">
          {result === 'idle' && (
            <div className="smg-status-idle">
              <kbd>ESPACE</kbd>
              <span>pour attraper dans la zone verte</span>
            </div>
          )}
          {(result === 'hit' || result === 'success') && (
            <div className="smg-status-success">
              <CheckCircle size={20} />
              <span>{result === 'success' ? 'Objet volé !' : 'Réussi !'}</span>
            </div>
          )}
          {(result === 'miss') && (
            <div className="smg-status-miss">
              <XCircle size={20} />
              <span>Raté — réessayez !</span>
            </div>
          )}
          {result === 'fail' && (
            <div className="smg-status-fail">
              <XCircle size={20} />
              <span>Échec du vol</span>
            </div>
          )}
        </div>

        {!isDone && (
          <button className="smg-footer-cancel" onClick={onCancel}>
            <X size={13} /> Annuler  <kbd>ESC</kbd>
          </button>
        )}
      </div>
    </div>
  );
};

export default StealMinigame;
