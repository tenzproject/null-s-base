import React, { useMemo, useCallback } from 'react';
import { Search, Sword, Shirt, Box, Weight, Boxes, Grid3X3 } from 'lucide-react';
import { InventoryItem, FilterType, BagInfoMap, BackpackPreview } from '../types';
import { nuiCallback } from './utils';
import ItemGrid from './ItemGrid';

interface LeftPanelProps {
  inventory: InventoryItem[];
  title: string;
  weight: number;
  maxWeight: number;
  searchTerm: string;
  activeFilter: FilterType;
  playerSex: 'male' | 'female';
  failedImages: React.MutableRefObject<Set<string>>;
  isDragging: boolean;
  dragItem: InventoryItem | null;
  dragSource: string | null;
  dropTarget: string | null;
  bagInfo: BagInfoMap;
  bagPreviews: Record<string, BackpackPreview>;
  equippedBagId: string | number | null;
  onSearchChange: (v: string) => void;
  onFilterChange: (f: FilterType) => void;
  onMouseDown: (e: React.MouseEvent, item: InventoryItem, source: string) => void;
  onContextMenu: (e: React.MouseEvent, item: InventoryItem) => void;
  onDropTargetChange: (t: string | null) => void;
  onOpenBag: (item: InventoryItem) => void;
  onFetchBagPreview: (item: InventoryItem) => void;
  hideWeight?: boolean;
  serverIcon?: string;
  serverName?: string;
}

const LeftPanel: React.FC<LeftPanelProps> = ({
  inventory, title, weight, maxWeight,
  searchTerm, activeFilter, playerSex, failedImages,
  isDragging, dragItem, dragSource, dropTarget,
  bagInfo, bagPreviews, equippedBagId,
  onSearchChange, onFilterChange,
  onMouseDown, onContextMenu, onDropTargetChange,
  onOpenBag, onFetchBagPreview, hideWeight = false,
  serverIcon, serverName,
}) => {
  const filtered = useMemo(() => {
    return inventory.filter(item => {
      const matchesSearch = !searchTerm ||
        String(item.label || '').toLowerCase().includes(searchTerm.toLowerCase()) ||
        String(item.name || '').toLowerCase().includes(searchTerm.toLowerCase());
      let matchesFilter = true;
      if (activeFilter === 'weapon') matchesFilter = item.type === 'weapon';
      else if (activeFilter === 'clothes') matchesFilter = item.type === 'accessory';
      else if (activeFilter === 'food') matchesFilter = item.type === 'item';
      return matchesSearch && matchesFilter;
    });
  }, [inventory, searchTerm, activeFilter]);

  const handleSearchFocus = useCallback(() => { nuiCallback('newInventory:searchFocus'); }, []);
  const handleSearchBlur = useCallback(() => { nuiCallback('newInventory:searchBlur'); }, []);

  return (
    <div className="ni-panel ni-left">
      <div className="ni-panel-header">
        <div className="ni-panel-title">
          <div className={`ni-panel-title-icon ${serverIcon ? 'ni-panel-title-logo' : ''}`}>
            {serverIcon
              ? <img src={serverIcon} alt={serverName || ''} draggable={false} onError={(e) => { (e.currentTarget as HTMLImageElement).style.display = 'none'; }} />
              : <Boxes size={16} />
            }
          </div>
          <h2>{title}</h2>
        </div>
        <div className="ni-weight-info">
          <Weight size={14} />
          <span>{weight.toFixed(1)}/{maxWeight.toFixed(1)} kg</span>
        </div>
      </div>

      <div className="ni-search-row">
        <div className="ni-search-input">
          <Search size={14} />
          <input
            type="text"
            placeholder="Rechercher un item..."
            value={searchTerm}
            onChange={(e) => onSearchChange(e.target.value)}
            onFocus={handleSearchFocus}
            onBlur={handleSearchBlur}
          />
        </div>
        <div className="ni-filters">
          {([
            { key: 'all' as FilterType, icon: <Grid3X3 size={14} />, tip: 'Tout' },
            { key: 'weapon' as FilterType, icon: <Sword size={14} />, tip: 'Armes' },
            { key: 'clothes' as FilterType, icon: <Shirt size={14} />, tip: 'Vetements' },
            { key: 'food' as FilterType, icon: <Box size={14} />, tip: 'Items' },
          ]).map(f => (
            <button
              key={f.key}
              className={`ni-filter-btn ${activeFilter === f.key ? 'active' : ''}`}
              onClick={() => onFilterChange(f.key)}
              title={f.tip}
            >
              {f.icon}
            </button>
          ))}
        </div>
      </div>

      <ItemGrid
        id="left"
        items={filtered}
        playerSex={playerSex}
        failedImages={failedImages}
        isDragging={isDragging}
        dragItem={dragItem}
        dragSource={dragSource}
        dropTarget={dropTarget}
        onMouseDown={onMouseDown}
        onContextMenu={onContextMenu}
        onDropTargetChange={onDropTargetChange}
        showBagFeatures
        bagInfo={bagInfo}
        bagPreviews={bagPreviews}
        equippedBagId={equippedBagId}
        onOpenBag={onOpenBag}
        onFetchBagPreview={onFetchBagPreview}
        hideWeight={hideWeight}
      />
    </div>
  );
};

export default React.memo(LeftPanel);
