import React from 'react';
import { Shirt, Undo2, MousePointerClick, Edit3, UserPlus, Trash2 } from 'lucide-react';
import { InventoryItem, ACCESSORY_SLOTS } from '../types';
import { nuiCallback } from './utils';
import { cacheImg } from '@shared/cacheVersion';
import DragSlot from './DragSlot';

interface CenterPanelProps {
  accessories: Record<string, InventoryItem | null>;
  shortcuts: (InventoryItem | null)[];
  playerSex: 'male' | 'female';
  failedImages: React.MutableRefObject<Set<string>>;
  isDragging: boolean;
  dragItem: InventoryItem | null;
  dropTarget: string | null;
  pedOccluded: boolean;
  onMouseDown: (e: React.MouseEvent, item: InventoryItem, source: string) => void;
  onDropTargetChange: (t: string | null) => void;
}

const CenterPanel: React.FC<CenterPanelProps> = ({
  accessories, shortcuts, playerSex, failedImages,
  isDragging, dropTarget, pedOccluded,
  onMouseDown, onDropTargetChange,
}) => {
  const hasAnyAccessory = Object.values(accessories).some(a => a !== null && a !== undefined);

  const actionButtons = [
    { id: 'use', label: 'Utiliser', icon: MousePointerClick, color: '#10b981' },
    { id: 'rename', label: 'Renommer', icon: Edit3, color: '#3b82f6' },
    { id: 'give', label: 'Donner', icon: UserPlus, color: '#f59e0b' },
    { id: 'drop', label: 'Jeter', icon: Trash2, color: '#ef4444' },
  ];

  return (
    <div className="ni-center">
      {/* Action Buttons */}
      <div className="ni-action-buttons">
        {actionButtons.map(btn => (
          <div
            key={btn.id}
            className={`ni-action-btn ${isDragging && dropTarget === `action-${btn.id}` ? 'ni-action-drop-hover' : ''}`}
            style={{ '--action-color': btn.color } as React.CSSProperties}
            onMouseEnter={() => isDragging && onDropTargetChange(`action-${btn.id}`)}
            onMouseLeave={() => isDragging && onDropTargetChange(null)}
            title={btn.label}
          >
            <btn.icon size={16} />
            <span className="ni-action-btn-label">{btn.label}</span>
          </div>
        ))}
      </div>

      <div className="ni-equipment">
        <div className="ni-equip-slots">
          {ACCESSORY_SLOTS.map(slot => {
            const equipped = accessories[slot.key];
            return (
              <DragSlot
                key={slot.key}
                slotId={`equip-${slot.key}`}
                item={equipped}
                playerSex={playerSex}
                failedImages={failedImages}
                isDragging={isDragging}
                dropTarget={dropTarget}
                onDropTargetChange={onDropTargetChange}
                onMouseDown={onMouseDown}
                onDoubleClick={equipped ? () => nuiCallback('newInventory:removeAccessory', { type: equipped.type2 || slot.key, item: null }) : undefined}
                className={`ni-equip-slot ${equipped ? 'ni-equipped' : ''}`}
                dataSlot={slot.key}
                title={equipped ? `${slot.label}: ${equipped.label}` : slot.label}
                placeholder={
                  <>
                    <img
                      className="ni-equip-placeholder-img"
                      src={cacheImg(slot.placeholderImg)}
                      alt={slot.label}
                      draggable={false}
                    />
                    <span className="ni-equip-slot-label">{slot.label}</span>
                  </>
                }
              />
            );
          })}
        </div>

        {isDragging && (
          <div
            className={`ni-character ${dropTarget === 'character' ? 'ni-drop-hover' : ''}`}
            onMouseEnter={() => onDropTargetChange('character')}
            onMouseLeave={() => dropTarget === 'character' && onDropTargetChange(null)}
          >
            <div className="ni-character-hint">
              <MousePointerClick size={20} />
              <span>Utiliser</span>
            </div>
          </div>
        )}

        {/* Ped occluded fallback — solid bg when ped is behind a wall */}
        <div className={`ni-ped-occluded-bg ${pedOccluded ? 'ni-ped-occluded-active' : ''}`} />

        {/* Gradient overlays for ped visibility */}
        <div className="ni-center-gradient ni-center-gradient-top" />
        <div className="ni-center-gradient ni-center-gradient-bottom" />
        <div className="ni-center-gradient ni-center-gradient-left" />
        <div className="ni-center-gradient ni-center-gradient-right" />
      </div>

      {/* Quick Actions */}
      <div className="ni-quick-actions">
        <button
          className="ni-quick-action-btn"
          onClick={() => nuiCallback('newInventory:removeAllClothes')}
          title="Enlever tous les vetements"
          disabled={!hasAnyAccessory}
        >
          <Shirt size={15} />
          <span>Tout enlever</span>
        </button>
        <button
          className="ni-quick-action-btn"
          onClick={() => nuiCallback('newInventory:restoreLastOutfit')}
          title="Remettre la derniere tenue"
        >
          <Undo2 size={15} />
          <span>Remettre</span>
        </button>
      </div>

      {/* Weapon Shortcuts */}
      <div className="ni-shortcuts">
        {shortcuts.map((shortcut, i) => (
          <DragSlot
            key={i}
            slotId={`shortcut-${i + 1}`}
            item={shortcut}
            playerSex={playerSex}
            failedImages={failedImages}
            isDragging={isDragging}
            dropTarget={dropTarget}
            onDropTargetChange={onDropTargetChange}
            onMouseDown={onMouseDown}
            onDoubleClick={shortcut ? () => nuiCallback('newInventory:shortcutRemove', { slot: i + 1 }) : undefined}
            className="ni-shortcut-slot"
            placeholder={<span className="ni-shortcut-number">{i + 1}</span>}
          />
        ))}
      </div>
    </div>
  );
};

export default React.memo(CenterPanel);
