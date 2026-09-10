import React, { useEffect, useRef, useState } from 'react';
import { Clock, Package, AlertTriangle, Shield, ChevronRight, LogOut, Minus, Plus } from 'lucide-react';
import { cacheImg } from '@shared/cacheVersion';
import type { MinigameConfig } from './Burglary';

// ─── Types ────────────────────────────────────────────────────────────────────
export interface BurglaryItem {
  key: string;
  item: string;
  count: number;
  label: string;
}

interface Props {
  items: BurglaryItem[];
  taken: number;
  max: number;
  maxQtyPerItem: number;
  initialTime: number;
  interior: string;
  onPick: (lootKey: string, quantity: number, label: string) => void;
  onClose: () => void;
  endReason: string | null;
  pickedToast: { label: string; count: number } | null;
  minigameConfig: MinigameConfig | null;
  cooldownUntil: number;
  itemStealCooldown: number;
}

// ─── Image helpers (mirrors inventory utils) ──────────────────────────────────
const FALLBACK = () => cacheImg('items/box.png');

function getItemImg(itemName: string, failed: Set<string>): string {
  if (failed.has(itemName)) return FALLBACK();
  return cacheImg(`items/${itemName}.webp`);
}

function handleImgErr(
  e: React.SyntheticEvent<HTMLImageElement>,
  itemName: string,
  failed: Set<string>
) {
  const el = e.target as HTMLImageElement;
  if (!failed.has(itemName)) {
    failed.add(itemName);
    el.src = FALLBACK();
  }
}

// ─── Interior label ───────────────────────────────────────────────────────────
function interiorLabel(interior: string): string {
  if (interior?.startsWith('Entrepot')) return 'Entrepôt';
  if (interior === 'High')   return 'Penthouse';
  if (interior === 'Middle') return 'Appartement';
  if (interior === 'Low')    return 'Petit appartement';
  return interior || 'Propriété';
}

// ─── Component ────────────────────────────────────────────────────────────────
const BurglaryLootPanel: React.FC<Props> = ({
  items, taken, max, maxQtyPerItem, initialTime, interior,
  onPick, onClose, endReason, pickedToast, minigameConfig,
  cooldownUntil, itemStealCooldown,
}) => {
  const failedImages = useRef<Set<string>>(new Set());
  const startedAt    = useRef(performance.now());
  const lastInitial  = useRef(initialTime);
  const [remaining, setRemaining] = useState(initialTime);
  const [quantities, setQuantities] = useState<Record<string, number>>({});
  const [hoveredKey, setHoveredKey] = useState<string | null>(null);
  const [now, setNow] = useState(Date.now());

  // Tick for cooldown display
  useEffect(() => {
    if (itemStealCooldown <= 0) return;
    const id = setInterval(() => setNow(Date.now()), 200);
    return () => clearInterval(id);
  }, [itemStealCooldown]);

  // Reset timer on new session
  useEffect(() => {
    if (initialTime !== lastInitial.current) {
      lastInitial.current = initialTime;
      startedAt.current   = performance.now();
      setRemaining(initialTime);
    }
  }, [initialTime]);

  // Countdown
  useEffect(() => {
    const id = setInterval(() => {
      setRemaining(Math.max(0, initialTime - (performance.now() - startedAt.current) / 1000));
    }, 200);
    return () => clearInterval(id);
  }, [initialTime]);

  // Init quantities: default = min(maxQtyPerItem, item.count)
  useEffect(() => {
    const q: Record<string, number> = {};
    items.forEach(it => { q[it.key] = Math.min(maxQtyPerItem, it.count); });
    setQuantities(q);
  }, [items, maxQtyPerItem]);

  // ESC closes
  useEffect(() => {
    const h = (e: KeyboardEvent) => { if (e.key === 'Escape') onClose(); };
    window.addEventListener('keydown', h);
    return () => window.removeEventListener('keydown', h);
  }, [onClose]);

  const danger  = remaining <= 10;
  const minutes = Math.floor(remaining / 60);
  const seconds = Math.floor(remaining % 60);
  const label   = interiorLabel(interior);

  const adjustQty = (key: string, delta: number, itemMax: number) =>
    setQuantities(prev => ({
      ...prev,
      [key]: Math.max(1, Math.min(Math.min(itemMax, maxQtyPerItem), (prev[key] || 1) + delta)),
    }));

  const timeFmt = minutes > 0
    ? `${minutes}:${String(seconds).padStart(2, '0')}`
    : `${seconds}s`;
  const progressPct = (remaining / Math.max(1, initialTime)) * 100;
  const limitReached = taken >= max;
  const onCooldown = itemStealCooldown > 0 && now < cooldownUntil;
  const cooldownPct = onCooldown ? Math.max(0, (cooldownUntil - now) / itemStealCooldown * 100) : 0;

  return (
    <div className="blp-overlay">
      <div className="blp-container">

        {/* ══ SIDEBAR ══ */}
        <div className="tablet-sidebar">
          <div className="tablet-sidebar-header">
            <div className="tablet-sidebar-icon" style={{ background: 'linear-gradient(135deg,#c0392b,#8e44ad)' }}>
              <Shield size={18} />
            </div>
            <div className="tablet-sidebar-title">
              <h1>Cambriolage</h1>
              <p>{label}</p>
            </div>
          </div>

          {/* Timer */}
          <div className="blp-side-timer-wrap">
            <div className={`blp-side-timer${danger ? ' danger' : ''}`}>
              <Clock size={28} />
              <span className="blp-side-timer-val">{timeFmt}</span>
              <span className="blp-side-timer-label">Temps restant</span>
            </div>
            <div className="blp-side-progress">
              <div
                className={`blp-side-progress-fill${danger ? ' danger' : ''}`}
                style={{ width: `${progressPct}%` }}
              />
            </div>
          </div>

          {/* Stats */}
          <div className="tablet-sidebar-nav">
            <div className="blp-stat-card">
              <Package size={16} />
              <div>
                <span className="blp-stat-val">{taken} <span className="blp-stat-max">/ {max}</span></span>
                <span className="blp-stat-label">Types volés</span>
              </div>
            </div>
            <div className="blp-stat-card">
              <AlertTriangle size={16} style={{ color: danger ? '#e74c3c' : 'rgba(255,255,255,0.4)' }} />
              <div>
                <span className="blp-stat-val" style={{ color: danger ? '#e74c3c' : undefined }}>
                  {danger ? 'ALERTE' : 'Normal'}
                </span>
                <span className="blp-stat-label">Statut police</span>
              </div>
            </div>

            {pickedToast && (
              <div className="blp-toast-side">
                <ChevronRight size={13} />
                +{pickedToast.count} {pickedToast.label}
              </div>
            )}

            {endReason && (
              <div className="blp-end-side">
                <AlertTriangle size={14} />
                <strong>
                  {endReason === 'timeout' ? 'Temps écoulé !' :
                   endReason === 'max'     ? 'Limite atteinte !' : 'Session terminée'}
                </strong>
                <span>Fuyez !</span>
              </div>
            )}
          </div>

          {/* Close */}
          <div className="tablet-sidebar-footer">
            <button className="tablet-close-btn" onClick={onClose}>
              <LogOut size={14} />
              Fuir la propriété
              <kbd>ESC</kbd>
            </button>
          </div>
        </div>

        {/* ══ CONTENT ══ */}
        <div className="tablet-content blp-content">
          {/* Section header */}
          <div className="tablet-section-header">
            <div className="tablet-section-header-icon" style={{ background: 'rgba(192,57,43,0.15)', color: '#c0392b' }}>
              <Package size={22} />
            </div>
            <div>
              <h2>Contenu du coffre</h2>
              <p>Cliquez sur un objet pour le voler · {items.length} objet{items.length !== 1 ? 's' : ''} disponible{items.length !== 1 ? 's' : ''}</p>
            </div>
          </div>

          {/* Cooldown bar */}
          {onCooldown && (
            <div className="blp-cooldown-bar-wrap">
              <div className="blp-cooldown-bar-fill" style={{ width: `${cooldownPct}%` }} />
              <span className="blp-cooldown-label">Prochaine action dans {Math.ceil((cooldownUntil - now) / 1000)}s…</span>
            </div>
          )}

          {/* Grid */}
          {items.length === 0 ? (
            <div className="blp-empty">
              <AlertTriangle size={36} />
              <span>Le coffre est vide</span>
            </div>
          ) : (
            <div className="blp-grid">
              {items.map(it => {
                const qty = quantities[it.key] || 1;
                return (
                  <div
                    key={it.key}
                    className={`blp-item-slot${limitReached ? ' blp-disabled' : ''}${hoveredKey === it.key ? ' blp-hovered' : ''}`}
                    onMouseEnter={() => !limitReached && setHoveredKey(it.key)}
                    onMouseLeave={() => setHoveredKey(null)}
                  >
                    <div className="blp-item-content">
                      <img
                        src={getItemImg(it.item, failedImages.current)}
                        alt={it.label}
                        onError={e => handleImgErr(e, it.item, failedImages.current)}
                        draggable={false}
                      />
                      {it.count > 1 && <span className="blp-item-count">×{it.count}</span>}
                      <span className="blp-item-label">{it.label}</span>
                    </div>

                    {hoveredKey === it.key && !limitReached && (
                      <div className="blp-item-overlay">
                        <div className="blp-qty-row">
                          <button className="blp-qty-btn" onClick={e => { e.stopPropagation(); adjustQty(it.key, -1, it.count); }} disabled={qty <= 1}>
                            <Minus size={10} />
                          </button>
                          <span className="blp-qty-val">{qty}<span className="blp-qty-max">/{Math.min(maxQtyPerItem, it.count)}</span></span>
                          <button className="blp-qty-btn" onClick={e => { e.stopPropagation(); adjustQty(it.key, 1, it.count); }} disabled={qty >= Math.min(maxQtyPerItem, it.count)}>
                            <Plus size={10} />
                          </button>
                        </div>
                        <button className="blp-steal-btn" onClick={() => onPick(it.key, qty, it.label)}>
                          <LogOut size={12} />
                          Voler ×{qty}
                        </button>
                      </div>
                    )}
                  </div>
                );
              })}
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default BurglaryLootPanel;
