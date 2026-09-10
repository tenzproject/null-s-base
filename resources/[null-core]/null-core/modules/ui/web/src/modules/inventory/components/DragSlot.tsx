import React from 'react';
import { InventoryItem } from '../types';
import { getItemImageSrc, handleImgError } from './utils';

interface DragSlotProps {
  /** Unique identifier for this slot as a drop target (e.g. "equip-top", "shortcut-1", "outfit-slot-top") */
  slotId: string;
  /** The item currently in this slot, or null */
  item: InventoryItem | null;
  /** Player sex for image resolution */
  playerSex: 'male' | 'female';
  /** Failed images ref */
  failedImages: React.MutableRefObject<Set<string>>;
  /** Global drag state */
  isDragging: boolean;
  /** Current drop target id */
  dropTarget: string | null;
  /** Callback to set the current drop target */
  onDropTargetChange: (t: string | null) => void;
  /** Callback when user starts dragging an item OUT of this slot */
  onMouseDown: (e: React.MouseEvent, item: InventoryItem, source: string) => void;
  /** Callback on double-click when slot is filled */
  onDoubleClick?: () => void;
  /** CSS class name for the outer wrapper — lets parent control the visual style */
  className?: string;
  /** Tooltip / title */
  title?: string;
  /** Placeholder content when empty */
  placeholder?: React.ReactNode;
  /** Override content when filled (if not provided, renders item image) */
  filledContent?: React.ReactNode;
  /** data-slot attribute for CSS positioning (e.g. "top", "pants") */
  dataSlot?: string;
}

const DragSlot: React.FC<DragSlotProps> = ({
  slotId, item, playerSex, failedImages,
  isDragging, dropTarget, onDropTargetChange, onMouseDown,
  onDoubleClick, className, title, placeholder, filledContent, dataSlot,
}) => {
  const isDropHover = isDragging && dropTarget === slotId;

  return (
    <div
      className={`ni-drag-slot ${item ? 'ni-ds-filled' : ''} ${isDropHover ? 'ni-drop-hover' : ''} ${className || ''}`}
      data-slot={dataSlot}
      onMouseEnter={() => isDragging && onDropTargetChange(slotId)}
      onMouseLeave={() => isDragging && onDropTargetChange(null)}
      onMouseDown={item ? (e) => onMouseDown(e, item, slotId) : undefined}
      onDoubleClick={item && onDoubleClick ? onDoubleClick : undefined}
      title={title}
    >
      {item ? (
        filledContent || (
          <img
            className="ni-ds-item-img"
            src={getItemImageSrc(item, playerSex, failedImages.current)}
            alt={item.label}
            onError={(e) => handleImgError(e, item, failedImages.current)}
            draggable={false}
          />
        )
      ) : (
        placeholder || null
      )}
    </div>
  );
};

export default React.memo(DragSlot);
