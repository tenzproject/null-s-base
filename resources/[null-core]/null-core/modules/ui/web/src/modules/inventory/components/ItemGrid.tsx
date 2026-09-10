import React, { useState, useCallback } from 'react';
import { Backpack, Weight, ArrowDownToLine } from 'lucide-react';
import { InventoryItem, BagInfoMap, BackpackPreview, isBagItem, getBagMaxWeight } from '../types';
import { getItemImageSrc, handleImgError, isLicenseItem, LICENSE_TYPE_LABELS, LICENSE_CATEGORY_LABELS, isKevlarItem, KEVLAR_TYPE_LABELS, KEVLAR_TYPE_COLORS, getKevlarDurability, getKevlarProtection } from './utils';
import SmartTooltip from './SmartTooltip';
import { soundManager } from '@core/SoundManager';

export interface ItemGridProps {
  /** Unique identifier for this grid as a drag source/drop target (e.g. 'left', 'right', 'backpack') */
  id: string;
  /** Items to display */
  items: InventoryItem[];
  /** Number of grid columns (default 5) */
  columns?: number;
  /** Text shown when no items */
  emptyText?: string;
  /** Player sex for image resolution */
  playerSex: 'male' | 'female';
  /** Failed images ref */
  failedImages: React.MutableRefObject<Set<string>>;
  /** Global drag state */
  isDragging: boolean;
  /** Currently dragged item */
  dragItem: InventoryItem | null;
  /** Source of the drag */
  dragSource: string | null;
  /** Current drop target id */
  dropTarget: string | null;
  /** Callback when user starts dragging an item */
  onMouseDown: (e: React.MouseEvent, item: InventoryItem, source: string) => void;
  /** Callback on right-click */
  onContextMenu?: (e: React.MouseEvent, item: InventoryItem) => void;
  /** Callback to set the current drop target */
  onDropTargetChange: (t: string | null) => void;

  /* ---- Bag features (optional) ---- */
  /** Enable bag item features (badge, weight bar, preview tooltip) */
  showBagFeatures?: boolean;
  /** Bag config map */
  bagInfo?: BagInfoMap;
  /** Cached bag previews */
  bagPreviews?: Record<string, BackpackPreview>;
  /** Currently equipped bag id */
  equippedBagId?: string | number | null;
  /** Handler to open a bag */
  onOpenBag?: (item: InventoryItem) => void;
  /** Handler to fetch bag preview on hover */
  onFetchBagPreview?: (item: InventoryItem) => void;

  /* ---- Display options ---- */
  /** Additional CSS class on the grid container */
  className?: string;
  /** Override the grid wrapper style */
  style?: React.CSSProperties;
  /** Hide item weight indicators */
  hideWeight?: boolean;
}

const ItemGrid: React.FC<ItemGridProps> = ({
  id, items, columns = 5, emptyText = 'Aucun objet',
  playerSex, failedImages,
  isDragging, dragItem, dragSource, dropTarget,
  onMouseDown, onContextMenu, onDropTargetChange,
  showBagFeatures = false, bagInfo = {}, bagPreviews = {}, equippedBagId,
  onOpenBag, onFetchBagPreview,
  className, style, hideWeight = false,
}) => {
  const [hoveredBag, setHoveredBag] = useState<string | null>(null);
  const [hoveredLicense, setHoveredLicense] = useState<string | null>(null);
  const [hoveredKevlar, setHoveredKevlar] = useState<string | null>(null);

  const renderItem = (item: InventoryItem, idx: number, slotNumber: number) => {
    const slotTarget = `${id}:slot:${slotNumber}`;
    const durPct = item.durability !== undefined && item.durability > 0 ? Math.max(0, 100 - item.durability) : -1;
    const bag = showBagFeatures && isBagItem(item);
    const isEquippedBag = bag && equippedBagId != null && String(item.name) === String(equippedBagId);
    const bagMaxW = bag ? getBagMaxWeight(item, bagInfo) : 0;
    const preview = bag ? bagPreviews[String(item.name)] : undefined;
    const bagWeightPct = bag && preview ? Math.min((preview.weight / bagMaxW) * 100, 100) : 0;
    const license = isLicenseItem(item);
    const licenseKey = license ? `${item.name}-${item.metadata?.firstname}-${item.extra?.identifier || ''}` : '';
    const kevlar = isKevlarItem(item);
    const kevlarKey = kevlar ? `${item.name}-${item.metadata?.uniqueId || item.extra?.identifier || ''}` : '';
    const kevlarDur = kevlar ? getKevlarDurability(item) : null;

    return (
      <div
        key={`${id}-${slotNumber}-${item.name}-${item.slot ?? item.type2 ?? idx}`}
        className={`ni-item-slot ${isDragging && dragItem === item ? 'ni-dragging' : ''} ${isDragging && dropTarget === slotTarget ? 'ni-slot-drop-hover' : ''} ${bag ? 'ni-bag-item' : ''} ${isEquippedBag ? 'ni-bag-equipped' : ''} ${license ? 'ni-license-item' : ''} ${kevlar ? 'ni-kevlar-item' : ''}`}
        data-slot={slotNumber}
        onMouseDown={(e) => onMouseDown(e, item, slotTarget)}
        onContextMenu={onContextMenu ? (e) => onContextMenu(e, item) : undefined}
        onDoubleClick={bag && onOpenBag ? () => onOpenBag(item) : undefined}
        onMouseEnter={() => {
          if (isDragging) onDropTargetChange(slotTarget);
          soundManager.play('hover');
          if (bag) {
            setHoveredBag(String(item.name));
            onFetchBagPreview?.(item);
          }
          if (license) setHoveredLicense(licenseKey);
          if (kevlar) setHoveredKevlar(kevlarKey);
        }}
        onMouseLeave={() => {
          if (isDragging && dropTarget === slotTarget) onDropTargetChange(null);
          if (bag) setHoveredBag(null);
          if (license) setHoveredLicense(null);
          if (kevlar) setHoveredKevlar(null);
        }}
      >
        <div className="ni-item-content">
          <img
            src={getItemImageSrc(item, playerSex, failedImages.current)}
            alt={item.label || item.name}
            onError={(e) => handleImgError(e, item, failedImages.current)}
            draggable={false}
          />
          {item.count > 1 && <span className="ni-item-count">{item.count}</span>}
          {bag && (
            <div className="ni-bag-badge">
              <Backpack size={10} />
            </div>
          )}
          {bag && (
            <div className="ni-item-durability ni-bag-weight-bar">
              <div
                className="ni-item-durability-fill"
                style={{
                  width: `${bagWeightPct}%`,
                  backgroundColor: bagWeightPct > 80 ? '#e74c3c' : bagWeightPct > 50 ? '#f39c12' : 'var(--ni-accent, #3b82f6)',
                }}
              />
            </div>
          )}
          {kevlar && kevlarDur && (
            <div className="ni-item-durability ni-kevlar-dur-bar">
              <div
                className="ni-item-durability-fill"
                style={{
                  width: `${kevlarDur.pct}%`,
                  backgroundColor: kevlarDur.pct > 60 ? (KEVLAR_TYPE_COLORS[item.name] || '#3b82f6') : kevlarDur.pct > 30 ? '#f39c12' : '#e74c3c',
                }}
              />
            </div>
          )}
          {!bag && !kevlar && durPct >= 0 && (
            <div className="ni-item-durability">
              <div
                className="ni-item-durability-fill"
                style={{
                  width: `${durPct}%`,
                  backgroundColor: durPct > 60 ? 'var(--ni-accent, #646464)' : durPct > 30 ? '#f39c12' : '#e74c3c',
                }}
              />
            </div>
          )}
          <span className="ni-item-label">{item.metadata?.title || item.label || item.name}</span>
          {!hideWeight && item.weight != null && item.weight > 0 && (
            <span className="ni-item-weight">{(item.weight * (item.count || 1)).toFixed(1)} kg</span>
          )}
        </div>

        {/* Bag preview tooltip */}
        <SmartTooltip visible={!!(bag && hoveredBag === String(item.name) && preview)} className="ni-bag-preview">
          {preview && (
            <>
              <div className="ni-bag-preview-title">
                <Backpack size={12} /> {item.label || 'Sac'}
                {isEquippedBag && <span className="ni-bag-preview-equipped">Équipé</span>}
              </div>
              <div className="ni-bag-preview-weight">
                <Weight size={11} /> {preview.weight.toFixed(1)} / {bagMaxW} kg
              </div>
              <div className="ni-bag-preview-stats">
                {preview.itemCount > 0 && <span>{preview.itemCount} objet{preview.itemCount > 1 ? 's' : ''}</span>}
                {preview.weaponCount > 0 && <span>{preview.weaponCount} arme{preview.weaponCount > 1 ? 's' : ''}</span>}
                {preview.cash > 0 && <span>${preview.cash.toLocaleString()}</span>}
                {preview.dirtycash > 0 && <span>${preview.dirtycash.toLocaleString()} sale</span>}
                {preview.itemCount === 0 && preview.weaponCount === 0 && preview.cash === 0 && preview.dirtycash === 0 && <span>Vide</span>}
              </div>
              <div className="ni-bag-preview-hint">Clic-droit pour ouvrir</div>
            </>
          )}
        </SmartTooltip>

        {/* Kevlar preview tooltip */}
        <SmartTooltip visible={!!(kevlar && hoveredKevlar === kevlarKey && kevlarDur)} className={`ni-kevlar-preview ni-kevlar-preview-${item.name}`}>
          {kevlarDur && (
            <>
              <div className="ni-kevlar-preview-type" style={{ color: KEVLAR_TYPE_COLORS[item.name] || '#3b82f6' }}>
                {KEVLAR_TYPE_LABELS[item.name] || item.label}
              </div>
              <div className="ni-kevlar-preview-fields">
                <div className="ni-kevlar-preview-field">
                  <span className="ni-kevlar-preview-label">Protection</span>
                  <span className="ni-kevlar-preview-value">{getKevlarProtection(item)}%</span>
                </div>
                <div className="ni-kevlar-preview-field">
                  <span className="ni-kevlar-preview-label">Durabilité</span>
                  <span className="ni-kevlar-preview-value">{kevlarDur.current} / {kevlarDur.max}</span>
                </div>
                <div className="ni-kevlar-preview-bar">
                  <div className="ni-kevlar-preview-bar-fill" style={{ width: `${kevlarDur.pct}%`, backgroundColor: KEVLAR_TYPE_COLORS[item.name] || '#3b82f6' }} />
                </div>
              </div>
              <div className="ni-kevlar-preview-hint">Clic-droit pour plus d'options</div>
            </>
          )}
        </SmartTooltip>

        {/* License preview tooltip */}
        <SmartTooltip visible={!!(license && hoveredLicense === licenseKey && item.metadata)} className={`ni-license-preview ni-license-preview-${item.name}`}>
          {item.metadata && (
            <>
              <div className="ni-license-preview-type">
                {LICENSE_TYPE_LABELS[item.name] || item.label}
              </div>
              <div className="ni-license-preview-fields">
                <div className="ni-license-preview-field">
                  <span className="ni-license-preview-label">Nom</span>
                  <span className="ni-license-preview-value">{item.metadata.lastname} {item.metadata.firstname}</span>
                </div>
                {item.metadata.birthday && (
                  <div className="ni-license-preview-field">
                    <span className="ni-license-preview-label">Naissance</span>
                    <span className="ni-license-preview-value">{item.metadata.birthday}</span>
                  </div>
                )}
                {item.metadata.sex && (
                  <div className="ni-license-preview-field">
                    <span className="ni-license-preview-label">Sexe</span>
                    <span className="ni-license-preview-value">{item.metadata.sex}</span>
                  </div>
                )}
                {item.name !== 'identity_card' && item.metadata.licenses && Object.keys(item.metadata.licenses).length > 0 && (
                  <div className="ni-license-preview-field">
                    <span className="ni-license-preview-label">Catégories</span>
                    <div className="ni-license-preview-categories">
                      {Object.keys(item.metadata.licenses).filter(k => item.metadata!.licenses[k] && LICENSE_CATEGORY_LABELS[k]).map(k => (
                        <span key={k} className="ni-license-preview-cat">{LICENSE_CATEGORY_LABELS[k]}</span>
                      ))}
                    </div>
                  </div>
                )}
              </div>
            </>
          )}
        </SmartTooltip>
      </div>
    );
  };

  const gridStyle: React.CSSProperties = {
    ...style,
    '--ni-grid-columns': columns,
  } as React.CSSProperties;

  const isDropTarget = isDragging && dropTarget === id;
  const minSlots = columns * 7;
  const maxSavedSlot = items.reduce((max, item) => Math.max(max, Number(item.slot) || 0), 0);
  const totalSlots = Math.max(minSlots, Math.ceil(Math.max(items.length, maxSavedSlot) / columns) * columns);
  const slottedItems: Array<{ item: InventoryItem; idx: number } | null> = Array(totalSlots).fill(null);
  const overflowItems: Array<{ item: InventoryItem; idx: number }> = [];

  items.forEach((item, idx) => {
    const savedSlot = Number(item.slot) || 0;
    const targetIndex = savedSlot > 0 && savedSlot <= totalSlots ? savedSlot - 1 : -1;

    if (targetIndex >= 0 && !slottedItems[targetIndex]) {
      slottedItems[targetIndex] = { item, idx };
      return;
    }

    overflowItems.push({ item, idx });
  });

  overflowItems.forEach((entry) => {
    const emptyIndex = slottedItems.findIndex(slot => slot === null);
    if (emptyIndex >= 0) slottedItems[emptyIndex] = entry;
  });

  return (
    <div
      className={`ni-item-grid-wrapper ${className || ''}`}
      onMouseEnter={() => isDragging && dragSource !== id && onDropTargetChange(id)}
      onMouseLeave={() => isDragging && dropTarget === id && onDropTargetChange(null)}
    >
      <div className="ni-grid" style={gridStyle}>
        {slottedItems.map((entry, idx) => {
          const slotNumber = idx + 1;
          const slotTarget = `${id}:slot:${slotNumber}`;
          if (entry) return renderItem(entry.item, entry.idx, slotNumber);

          return (
            <div
              key={`${id}-empty-${slotNumber}`}
              className={`ni-empty-slot ${isDragging && dropTarget === slotTarget ? 'ni-slot-drop-hover' : ''}`}
              data-slot={slotNumber}
              onMouseEnter={() => isDragging && onDropTargetChange(slotTarget)}
              onMouseLeave={() => isDragging && dropTarget === slotTarget && onDropTargetChange(null)}
            />
          );
        })}
        {items.length === 0 && <div className="ni-empty">{emptyText}</div>}
      </div>

      {isDropTarget && (
        <div className="ni-drop-indicator">
          <div className="ni-drop-indicator-content">
            <ArrowDownToLine size={24} />
            <span>Déposer ici</span>
          </div>
        </div>
      )}
    </div>
  );
};

export default React.memo(ItemGrid);
