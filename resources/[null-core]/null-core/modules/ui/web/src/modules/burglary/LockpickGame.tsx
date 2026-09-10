import React, { useEffect, useMemo, useRef, useState, useCallback } from 'react';
import { KeyRound, AlertTriangle, Check, X } from 'lucide-react';
import { Difficulty } from './Burglary';

/**
 * Lockpick minigame :
 * - A rotating needle goes around a circle.
 * - The player must press SPACE when the needle is inside the GREEN zone
 *   to "crack" the current pin.
 * - Difficulty controls : number of pins to crack (in order),
 *   green-zone width (degrees), needle rotation period, allowed misses.
 * - Each pin's green zone is randomly placed at start.
 * - Visual feedback : pin lights up green when cracked, red flash on miss.
 * - On all pins cracked → success ; on too many misses → fail.
 * - On total time exhaustion (12s × pins) → fail.
 */

const PER_PIN_TIMEOUT_MS = 12_000;

type PinState = 'pending' | 'active' | 'cracked' | 'failed';

type Pin = {
  windowStart: number; // deg, [0,360)
  windowEnd: number;   // deg, [0,360) (may wrap)
  state: PinState;
};

const norm = (deg: number) => ((deg % 360) + 360) % 360;

const inWindow = (angle: number, start: number, end: number) => {
  const a = norm(angle);
  if (start <= end) return a >= start && a <= end;
  return a >= start || a <= end; // wrapping window
};

interface Props {
  difficulty: Difficulty;
  interior: string;
  onDone: (success: boolean) => void;
}

const LockpickGame: React.FC<Props> = ({ difficulty, interior, onDone }) => {
  const { pins: pinCount, window: windowDeg, rotation: rotationMs, tries: maxMisses } = difficulty;

  // Build pins (windows are randomly placed; ensure no overlap)
  const buildPins = useCallback((): Pin[] => {
    const out: Pin[] = [];
    const minGap = Math.max(20, windowDeg / 2);
    let attempts = 0;
    while (out.length < pinCount && attempts < 200) {
      attempts++;
      const start = Math.random() * 360;
      const end   = norm(start + windowDeg);
      // check overlap with any existing window (allowing wrap)
      const overlap = out.some(p => {
        const probe = (a: number) => inWindow(a, p.windowStart, p.windowEnd);
        return probe(start) || probe(end) || probe(norm(start + windowDeg / 2));
      });
      // also enforce a min gap between window-centers
      const centerNew = norm(start + windowDeg / 2);
      const tooClose  = out.some(p => {
        const c = norm(p.windowStart + windowDeg / 2);
        const dd = Math.min(norm(centerNew - c), norm(c - centerNew));
        return dd < minGap;
      });
      if (!overlap && !tooClose) {
        out.push({ windowStart: norm(start), windowEnd: end, state: 'pending' });
      }
    }
    if (out.length === 0) return [];
    out[0].state = 'active';
    return out;
  }, [pinCount, windowDeg]);

  const [pins, setPins] = useState<Pin[]>(() => buildPins());
  const [activeIdx, setActiveIdx] = useState(0);
  const [misses, setMisses] = useState(0);
  const [angle, setAngle] = useState(0); // Continuous angle, grows without bound
  const normalizedAngle = useMemo(() => norm(angle), [angle]); // 0-360 for hit detection
  const [flash, setFlash] = useState<'good' | 'bad' | null>(null);
  const [outcome, setOutcome] = useState<'success' | 'fail' | null>(null);
  const [pinTimeLeft, setPinTimeLeft] = useState(PER_PIN_TIMEOUT_MS);

  const startTimeRef = useRef<number>(performance.now());
  const pinStartTimeRef = useRef<number>(performance.now());
  const rafRef = useRef<number | null>(null);

  // RAF loop : update needle angle + per-pin timer
  useEffect(() => {
    if (outcome) return;
    const tick = (now: number) => {
      // Calculate total elapsed time for continuous rotation
      const elapsed = now - startTimeRef.current;
      // Keep angle continuous (no norm) so needle spins without resetting
      setAngle((elapsed / rotationMs) * 360);

      // Calculate timer with proper clamping
      const timeRemaining = Math.max(0, Math.min(PER_PIN_TIMEOUT_MS, PER_PIN_TIMEOUT_MS - (now - pinStartTimeRef.current)));
      setPinTimeLeft(timeRemaining);

      rafRef.current = requestAnimationFrame(tick);
    };
    rafRef.current = requestAnimationFrame(tick);
    return () => { if (rafRef.current) cancelAnimationFrame(rafRef.current); };
  }, [rotationMs, outcome]);

  // Per-pin timeout → counts as miss
  useEffect(() => {
    if (outcome) return;
    if (pinTimeLeft > 0) return;
    handleAttempt(true);
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [pinTimeLeft]);

  // ESC → fail
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (outcome) return;
      if (e.key === 'Escape') {
        setOutcome('fail');
        setTimeout(() => onDone(false), 600);
      } else if (e.key === ' ' || e.code === 'Space' || e.key === 'Enter') {
        e.preventDefault();
        handleAttempt(false);
      }
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [outcome, angle, activeIdx, pins]);

  const finishWith = useCallback((result: 'success' | 'fail') => {
    setOutcome(result);
    setTimeout(() => onDone(result === 'success'), 700);
  }, [onDone]);

  const handleAttempt = useCallback((isTimeout: boolean) => {
    if (outcome) return;
    const current = pins[activeIdx];
    if (!current) return;
    const hit = !isTimeout && inWindow(normalizedAngle, current.windowStart, current.windowEnd);

    if (hit) {
      setFlash('good');
      setTimeout(() => setFlash(null), 200);
      setPins(prev => {
        const next = prev.slice();
        next[activeIdx] = { ...next[activeIdx], state: 'cracked' };
        const ni = activeIdx + 1;
        if (ni < next.length) next[ni] = { ...next[ni], state: 'active' };
        return next;
      });
      const ni = activeIdx + 1;
      if (ni >= pins.length) {
        finishWith('success');
      } else {
        setActiveIdx(ni);
        pinStartTimeRef.current = performance.now();
        setPinTimeLeft(PER_PIN_TIMEOUT_MS);
      }
    } else {
      setFlash('bad');
      setTimeout(() => setFlash(null), 250);
      const newMisses = misses + 1;
      setMisses(newMisses);
      if (newMisses > maxMisses) {
        setPins(prev => {
          const next = prev.slice();
          if (next[activeIdx]) next[activeIdx] = { ...next[activeIdx], state: 'failed' };
          return next;
        });
        finishWith('fail');
      } else {
        // small needle "kick" animation: bump phase by ~45 degrees (backwards)
        // Move startTimeRef forward so the needle jumps back
        const kickMs = (45 / 360) * rotationMs;
        startTimeRef.current = startTimeRef.current + kickMs;
      }
    }
  }, [outcome, pins, activeIdx, normalizedAngle, misses, maxMisses, finishWith]);

  // Compute SVG arc paths once per pin
  const arcs = useMemo(() => {
    const cx = 150, cy = 150, r = 120;
    const polarToXY = (deg: number) => {
      const rad = ((deg - 90) * Math.PI) / 180;
      return [cx + r * Math.cos(rad), cy + r * Math.sin(rad)];
    };
    return pins.map(p => {
      const [x1, y1] = polarToXY(p.windowStart);
      const [x2, y2] = polarToXY(p.windowEnd);
      const sweepDeg = p.windowEnd >= p.windowStart
        ? p.windowEnd - p.windowStart
        : 360 - (p.windowStart - p.windowEnd);
      const largeArc = sweepDeg > 180 ? 1 : 0;
      return `M ${x1} ${y1} A ${r} ${r} 0 ${largeArc} 1 ${x2} ${y2}`;
    });
  }, [pins]);

  const interiorLabel = (
    interior?.startsWith('Entrepot') ? 'Entrepôt' :
    interior === 'High'   ? 'Penthouse' :
    interior === 'Middle' ? 'Maison standing' :
    interior === 'Low'    ? 'Petite maison' : interior || ''
  );

  return (
    <div className={`burg-mg-wrap ${flash ? `flash-${flash}` : ''} ${outcome || ''}`}>
      <div className="burg-mg-card">
        <div className="burg-mg-head">
          <div className="burg-mg-icon"><KeyRound size={22} /></div>
          <div className="burg-mg-text">
            <h2>Crochetage</h2>
            <p>{interiorLabel} • {pinCount} pins • {Math.max(0, maxMisses - misses)} essais restants</p>
          </div>
          <div className="burg-mg-badge" data-tone={outcome ?? 'live'}>
            {outcome === 'success' ? <Check size={16} /> :
             outcome === 'fail'    ? <X size={16} /> :
                                      <AlertTriangle size={16} />}
            <span>
              {outcome === 'success' ? 'Réussi'
                : outcome === 'fail' ? 'Échec'
                : 'En cours'}
            </span>
          </div>
        </div>

        <div className="burg-mg-stage">
          <svg viewBox="0 0 300 300" className="burg-mg-svg">
            {/* Outer track */}
            <circle cx="150" cy="150" r="120" stroke="var(--bg-tertiary)" strokeWidth="22" fill="none" />
            {/* Pin windows */}
            {arcs.map((d, i) => {
              const p = pins[i];
              const color =
                p.state === 'cracked' ? '#2ecc71' :
                p.state === 'active'  ? '#f1c40f' :
                p.state === 'failed'  ? '#e74c3c' :
                                        'rgba(255,255,255,0.18)';
              return (
                <path
                  key={i}
                  d={d}
                  stroke={color}
                  strokeWidth="22"
                  fill="none"
                  strokeLinecap="butt"
                  className={`burg-arc state-${p.state}`}
                />
              );
            })}
            {/* Tick marks every 30° */}
            {Array.from({ length: 12 }).map((_, i) => {
              const a = (i * 30 * Math.PI) / 180;
              const x1 = 150 + Math.cos(a - Math.PI / 2) * 100;
              const y1 = 150 + Math.sin(a - Math.PI / 2) * 100;
              const x2 = 150 + Math.cos(a - Math.PI / 2) * 108;
              const y2 = 150 + Math.sin(a - Math.PI / 2) * 108;
              return <line key={i} x1={x1} y1={y1} x2={x2} y2={y2}
                           stroke="var(--border-strong)" strokeWidth="1.5" />;
            })}
            {/* Needle */}
            <g transform={`rotate(${angle} 150 150)`} className="burg-needle">
              <line x1="150" y1="150" x2="150" y2="42"
                    stroke="#fff" strokeWidth="3" strokeLinecap="round" />
              <circle cx="150" cy="42" r="6" fill="#fff" />
              <circle cx="150" cy="150" r="9" fill="#1a1a1a" stroke="#fff" strokeWidth="2" />
            </g>
            {/* Center pin counter */}
            <text x="150" y="170" textAnchor="middle"
                  fill="#fff" fontSize="38" fontWeight="800"
                  fontFamily="Outfit, sans-serif">
              {Math.min(activeIdx + 1, pins.length)}/{pins.length}
            </text>
          </svg>

          {/* Per-pin timer ring */}
          <div className="burg-mg-timer">
            <div
              className="burg-mg-timer-fill"
              style={{ width: `${Math.max(0, Math.min(100, (pinTimeLeft / PER_PIN_TIMEOUT_MS) * 100))}%` }}
            />
          </div>
        </div>

        <div className="burg-mg-foot">
          <div className="burg-mg-pinrow">
            {pins.map((p, i) => (
              <span
                key={i}
                className={`burg-mg-pin pin-${p.state}`}
              />
            ))}
          </div>
          <div className="burg-mg-keys">
            <kbd>SPACE</kbd> ou <kbd>ENTER</kbd> pour crocheter • <kbd>ESC</kbd> pour annuler
          </div>
        </div>
      </div>
    </div>
  );
};

export default LockpickGame;
