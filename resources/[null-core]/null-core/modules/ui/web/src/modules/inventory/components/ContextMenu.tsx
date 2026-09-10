import React, { useRef, useLayoutEffect, useState } from 'react';
import { Hand, Gift, Pen, Trash2, Backpack, ShieldOff, Weight } from 'lucide-react';
import { InventoryItem, isBagItem } from '../types';
import { TYPE_LABELS, getItemImageSrc, handleImgError, isLicenseItem, LICENSE_TYPE_LABELS, LICENSE_CATEGORY_LABELS, isKevlarItem, KEVLAR_TYPE_LABELS, KEVLAR_TYPE_COLORS, getKevlarDurability, getKevlarProtection } from './utils';
import { soundManager } from '@core/SoundManager';

interface ContextMenuProps {
  item: InventoryItem;
  x: number;
  y: number;
  playerSex: 'male' | 'female';
  failedImages: React.MutableRefObject<Set<string>>;
  onUse: (item: InventoryItem) => void;
  onGive: (item: InventoryItem) => void;
  onDrop: (item: InventoryItem) => void;
  onRename: (item: InventoryItem) => void;
  onOpenBag?: (item: InventoryItem) => void;
  kevlarExtraId?: string | number | null;
  onKevlarUnequip?: () => void;
}

const ContextMenu: React.FC<ContextMenuProps> = ({
  item, x, y, playerSex, failedImages,
  onUse, onGive, onDrop, onRename, onOpenBag, kevlarExtraId, onKevlarUnequip,
}) => {
  const ref = useRef<HTMLDivElement>(null);
  const [pos, setPos] = useState({ left: x, top: y });

  useLayoutEffect(() => {
    if (!ref.current) { setPos({ left: x, top: y }); return; }
    const el = ref.current;
    const rect = el.getBoundingClientRect();
    const vw = window.innerWidth;
    const vh = window.innerHeight;
    const margin = 8;

    let left = x;
    let top = y;

    // Clamp right edge
    if (left + rect.width > vw - margin) {
      left = vw - rect.width - margin;
    }
    // Clamp left edge
    if (left < margin) left = margin;
    // Clamp bottom edge
    if (top + rect.height > vh - margin) {
      top = vh - rect.height - margin;
    }
    // Clamp top edge
    if (top < margin) top = margin;

    setPos({ left, top });
  }, [x, y]);

  return (
  <div
    ref={ref}
    className="ni-context-menu"
    style={{ left: pos.left, top: pos.top }}
    onClick={(e) => e.stopPropagation()}
  >
    <div className="ni-ctx-header">
      <img
        className="ni-ctx-header-img"
        src={getItemImageSrc(item, playerSex, failedImages.current)}
        alt=""
        onError={(e) => handleImgError(e, item, failedImages.current)}
        draggable={false}
      />
      <div className="ni-ctx-header-text">
        <div className="ni-ctx-header-name">
          {item.metadata?.title || item.label || item.name}
        </div>
        <div className="ni-ctx-header-type">
          {TYPE_LABELS[item.type] || item.type}
          {item.count > 1 ? ` × ${item.count}` : ''}
          {item.weight != null && item.weight > 0 && (
            <span className="ni-ctx-weight-badge">
              <Weight size={9} /> {(item.weight * (item.count || 1)).toFixed(1)} kg
            </span>
          )}
        </div>
        {(item.description || item.metadata?.description) && (
          <div className="ni-ctx-desc">
            {item.description || item.metadata?.description}
          </div>
        )}
      </div>
    </div>

    {isKevlarItem(item) && item.metadata && (() => {
      const kDur = getKevlarDurability(item);
      const kColor = KEVLAR_TYPE_COLORS[item.name] || '#3b82f6';
      return (
        <div className="ni-ctx-kevlar" style={{ borderColor: kColor }}>
          <div className="ni-ctx-kevlar-type" style={{ color: kColor }}>
            {KEVLAR_TYPE_LABELS[item.name] || item.label}
          </div>
          <div className="ni-ctx-kevlar-fields">
            <div className="ni-ctx-kevlar-row">
              <span className="ni-ctx-kevlar-label">Protection</span>
              <span className="ni-ctx-kevlar-value">{getKevlarProtection(item)}%</span>
            </div>
            <div className="ni-ctx-kevlar-row">
              <span className="ni-ctx-kevlar-label">Durabilité</span>
              <span className="ni-ctx-kevlar-value">{kDur.current} / {kDur.max}</span>
            </div>
            <div className="ni-ctx-kevlar-bar">
              <div className="ni-ctx-kevlar-bar-fill" style={{ width: `${kDur.pct}%`, backgroundColor: kColor }} />
            </div>
          </div>
        </div>
      );
    })()}

    {isLicenseItem(item) && item.metadata && (
      <div className={`ni-ctx-license ni-ctx-license-${item.name}`}>
        <div className="ni-ctx-license-type">
          {LICENSE_TYPE_LABELS[item.name] || item.label}
        </div>
        <div className="ni-ctx-license-fields">
          <div className="ni-ctx-license-row">
            <span className="ni-ctx-license-label">Nom</span>
            <span className="ni-ctx-license-value">{item.metadata.lastname} {item.metadata.firstname}</span>
          </div>
          {item.metadata.birthday && (
            <div className="ni-ctx-license-row">
              <span className="ni-ctx-license-label">Naissance</span>
              <span className="ni-ctx-license-value">{item.metadata.birthday}</span>
            </div>
          )}
          {item.metadata.sex && (
            <div className="ni-ctx-license-row">
              <span className="ni-ctx-license-label">Sexe</span>
              <span className="ni-ctx-license-value">{item.metadata.sex}</span>
            </div>
          )}
          {item.name !== 'identity_card' && item.metadata.licenses && Object.keys(item.metadata.licenses).length > 0 && (
            <div className="ni-ctx-license-row">
              <span className="ni-ctx-license-label">Catégories</span>
              <div className="ni-ctx-license-cats">
                {Object.keys(item.metadata.licenses).filter(k => item.metadata!.licenses[k] && LICENSE_CATEGORY_LABELS[k]).map(k => (
                  <span key={k} className="ni-ctx-license-cat">{LICENSE_CATEGORY_LABELS[k]}</span>
                ))}
              </div>
            </div>
          )}
        </div>
      </div>
    )}

    {(item.serialnumber || item.permanent) && (
      <div className="ni-ctx-meta">
        {item.serialnumber && (
          <div className="ni-ctx-info">N° {item.serialnumber}</div>
        )}
        {item.permanent && (
          <div className="ni-ctx-badge">Arme permanente</div>
        )}
      </div>
    )}

    {item.durability !== undefined && item.durability > 0 && (
      <div className="ni-ctx-durability">
        <span>Durabilite</span>
        <div className="ni-ctx-dur-bar">
          <div
            className="ni-ctx-dur-fill"
            style={{
              width: `${Math.max(0, 100 - item.durability)}%`,
              backgroundColor: (100 - item.durability) > 60 ? 'var(--ni-accent, #646464)' : (100 - item.durability) > 30 ? '#f39c12' : '#e74c3c',
            }}
          />
        </div>
      </div>
    )}

    <div className="ni-ctx-actions">
      {isBagItem(item) && onOpenBag && (
        <button onClick={() => onOpenBag(item)} onMouseEnter={() => soundManager.play('hover')}>
         Ouvrir le sac
        </button>
      )}
      {isKevlarItem(item) && kevlarExtraId != null && item.extra?.identifier != null && String(kevlarExtraId) === String(item.extra.identifier) && onKevlarUnequip && (
        <button onClick={() => { soundManager.play('click'); onKevlarUnequip(); }} onMouseEnter={() => soundManager.play('hover')}>
         Retirer le gilet
        </button>
      )}
      <button onClick={() => { soundManager.play('click'); onUse(item); }} onMouseEnter={() => soundManager.play('hover')}>
         Utiliser
      </button>
      <button onClick={() => { soundManager.play('click'); onRename(item); }} onMouseEnter={() => soundManager.play('hover')}>
         Renommer
      </button>
      <button onClick={() => { soundManager.play('click'); onGive(item); }} onMouseEnter={() => soundManager.play('hover')}>
         Donner
      </button>
      <button className="ni-ctx-danger" onClick={() => { soundManager.play('click'); onDrop(item); }} onMouseEnter={() => soundManager.play('hover')}>
         Jeter
      </button>
    </div>
  </div>
  );
};

export default React.memo(ContextMenu);
