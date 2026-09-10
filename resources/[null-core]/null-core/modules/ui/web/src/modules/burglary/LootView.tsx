import React, { useEffect, useMemo, useRef, useState } from 'react';
import { Package, Clock, X, AlertTriangle, Banknote, Gem, Watch, Cpu, Smartphone, Briefcase, Wallet as WalletIcon, ImageIcon, Pill, FlaskRound } from 'lucide-react';

export type LootItem = {
  key:   string;
  item:  string;
  count: number;
  label: string;
};

const ITEM_ICONS: Record<string, JSX.Element> = {
  cash:                  <Banknote size={28} />,
  phone:                 <Smartphone size={28} />,
  laptop:                <Cpu size={28} />,
  tablet:                <Cpu size={28} />,
  watch:                 <Watch size={28} />,
  rolex:                 <Watch size={28} />,
  jewelry:               <Gem size={28} />,
  gold:                  <Gem size={28} />,
  diamond:               <Gem size={28} />,
  painting:              <ImageIcon size={28} />,
  wallet:                <WalletIcon size={28} />,
  weed_pooch:            <FlaskRound size={28} />,
  coke_pooch:            <FlaskRound size={28} />,
  meth_pooch:            <Pill size={28} />,
  electronic_components: <Cpu size={28} />,
};

interface Props {
  items: LootItem[];
  taken: number;
  max: number;
  initialTime: number;
  interior: string;
  onPick: (lootKey: string, quantity?: number, label?: string) => void;
  onClose: () => void;
  endReason: string | null;
  pickedToast: { label: string; count: number } | null;
  isRealChest?: boolean;
  inWorld?: boolean;
}

const LootView: React.FC<Props> = ({
  items, taken, max, initialTime, interior, onPick, onClose, endReason, pickedToast,
  isRealChest = false, inWorld = false,
}) => {
  const [selectedQuantity, setSelectedQuantity] = useState<Record<string, number>>({});
  const [remaining, setRemaining] = useState(initialTime);
  const startedAt = useRef<number>(performance.now());
  const lastInitial = useRef<number>(initialTime);

  // Reset timer if a new session arrives
  useEffect(() => {
    if (initialTime !== lastInitial.current) {
      lastInitial.current = initialTime;
      startedAt.current = performance.now();
      setRemaining(initialTime);
    }
  }, [initialTime]);

  useEffect(() => {
    const id = setInterval(() => {
      const elapsed = (performance.now() - startedAt.current) / 1000;
      setRemaining(Math.max(0, initialTime - elapsed));
    }, 200);
    return () => clearInterval(id);
  }, [initialTime]);

  // ESC closes
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => { if (e.key === 'Escape') onClose(); };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [onClose]);

  const interiorLabel = useMemo(() => (
    interior?.startsWith('Entrepot') ? 'Entrepôt' :
    interior === 'High'   ? 'Penthouse' :
    interior === 'Middle' ? 'Maison standing' :
    interior === 'Low'    ? 'Petite maison' : interior || ''
  ), [interior]);

  // Initialize quantities when items change (for real chest mode)
  useEffect(() => {
    if (isRealChest) {
      const newQuantities: Record<string, number> = {};
      items.forEach(it => {
        newQuantities[it.key] = 1;
      });
      setSelectedQuantity(newQuantities);
    }
  }, [items, isRealChest]);

  const adjustQuantity = (key: string, delta: number, maxCount: number) => {
    setSelectedQuantity(prev => ({
      ...prev,
      [key]: Math.max(1, Math.min(maxCount, (prev[key] || 1) + delta)),
    }));
  };

  const minutes = Math.floor(remaining / 60);
  const seconds = Math.floor(remaining % 60);
  const danger  = remaining <= 10;

  return (
    <div className={`burg-loot-wrap${inWorld ? ' burg-loot-inworld' : ''}`}>
      <div className="burg-loot-card">
        <div className="burg-loot-head">
          <div className="burg-loot-title">
            <div className="burg-loot-icon"><Package size={22} /></div>
            <div>
              <h2>Pillage en cours</h2>
              <p>{interiorLabel} • Faites vite, la police arrive…</p>
            </div>
          </div>
          <div className="burg-loot-meters">
            <div className={`burg-loot-meter time ${danger ? 'danger' : ''}`}>
              <Clock size={14} />
              <span>{minutes > 0 ? `${minutes}:${String(seconds).padStart(2, '0')}` : `${seconds}s`}</span>
            </div>
            <div className="burg-loot-meter bag">
              <Package size={14} />
              <span>{taken} / {max}</span>
            </div>
            <button className="burg-loot-close" onClick={onClose} title="Fuir (ESC)">
              <X size={16} />
            </button>
          </div>
        </div>

        <div className="burg-loot-progress">
          <div
            className={`burg-loot-progress-fill ${danger ? 'danger' : ''}`}
            style={{ width: `${(remaining / Math.max(1, initialTime)) * 100}%` }}
          />
        </div>

        <div className="burg-loot-grid">
          {items.length === 0 && (
            <div className="burg-loot-empty">
              <AlertTriangle size={32} />
              <p>Plus rien à voler ici.</p>
            </div>
          )}
          {items.map(it => (
            <div key={it.key} className={`burg-loot-item-wrapper ${isRealChest ? 'real-chest' : ''}`}>
              <button
                className="burg-loot-item"
                onClick={() => onPick(it.key, isRealChest ? (selectedQuantity[it.key] || 1) : it.count, it.label)}
                disabled={taken >= max}
                title={`Voler ${it.label} ×${isRealChest ? (selectedQuantity[it.key] || 1) : it.count}`}
              >
                <span className="bli-icon">{ITEM_ICONS[it.item] || <Briefcase size={28} />}</span>
                <span className="bli-label">{it.label}</span>
                <span className="bli-count">
                  {isRealChest ? (
                    <>
                      <span className="bli-current-qty">{selectedQuantity[it.key] || 1}</span>
                      <span className="bli-total">/{it.count}</span>
                    </>
                  ) : (
                    `×${it.count}`
                  )}
                </span>
              </button>
              {isRealChest && (
                <div className="burg-loot-qty-controls">
                  <button
                    className="burg-qty-btn"
                    onClick={(e) => { e.stopPropagation(); adjustQuantity(it.key, -1, it.count); }}
                    disabled={(selectedQuantity[it.key] || 1) <= 1}
                  >-</button>
                  <span className="burg-qty-value">{selectedQuantity[it.key] || 1}</span>
                  <button
                    className="burg-qty-btn"
                    onClick={(e) => { e.stopPropagation(); adjustQuantity(it.key, 1, it.count); }}
                    disabled={(selectedQuantity[it.key] || 1) >= it.count}
                  >+</button>
                </div>
              )}
            </div>
          ))}
        </div>

        <div className="burg-loot-foot">
          <span>
            {isRealChest ? 'Sélectionnez une quantité et volez. ' : 'Cliquez pour voler. '}
            Limite : <strong>{max}</strong> types d'objets différents. <kbd>ESC</kbd> pour fuir.
          </span>
        </div>
      </div>

      {pickedToast && (
        <div className="burg-loot-toast">
          + {pickedToast.label} ×{pickedToast.count}
        </div>
      )}

      {endReason && (
        <div className="burg-loot-end">
          <strong>
            {endReason === 'timeout' ? "Temps écoulé !" :
             endReason === 'max'     ? "Sac plein !"     :
             "Session terminée"}
          </strong>
          <span>Fuyez !</span>
        </div>
      )}
    </div>
  );
};

export default LootView;
