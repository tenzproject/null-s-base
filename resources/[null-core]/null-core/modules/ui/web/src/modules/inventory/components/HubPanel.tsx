import React, { useState, useCallback, useEffect, useMemo, MutableRefObject } from 'react';
import {
  Home, Settings, Hammer, BookOpen, Monitor, ShoppingBag,
  Smartphone, Drama, ChevronRight, ChevronLeft, ToggleLeft, ToggleRight,
  Clock, Package, Check, X, AlertCircle, Footprints, MapPin,
  Swords, Eye, Car, MoreHorizontal, Search, Shirt, Backpack,
  Sword, Grid3X3, Box, Coins, Building2,
  ArrowRightLeft, Weight, Crown, Loader2, HeartPulse
} from 'lucide-react';
import {
  HubPage, CraftRecipe, SettingDef, OptionsData, OptionsCategory, SocietyInfo,
  OutfitHubData, BackpackData, InventoryItem, MetabolismData,
  OUTFIT_SLOT_LABELS, ACCESSORY_SLOTS,
} from '../types';
import { nuiCallback } from './utils';
import { cacheImg } from '@shared/cacheVersion';
import DragSlot from './DragSlot';
import ItemGrid from './ItemGrid';
import MetabolismTab from './MetabolismTab';

interface HubPanelProps {
  serverIcon?: string;
  serverName?: string;
  playerName: string;
  playerId: string;
  playerUniqueId?: string;
  playerJob: string;
  playerMoney: number;
  playerBank: number;
  playerDirtyMoney: number;
  craftRecipes: CraftRecipe[];
  craftingId: string | null;
  craftProgress: number;
  craftTableId: string | null;
  craftTableBased: boolean;
  settings: SettingDef[];
  onSettingChange: (id: string, value: any) => void;
  optionsData: OptionsData | null;
  societies: SocietyInfo[];
  outfitData: OutfitHubData | null;
  backpackData: BackpackData | null;
  leftInventory: InventoryItem[];
  playerSex: 'male' | 'female';
  failedImages: MutableRefObject<Set<string>>;
  isDragging: boolean;
  dragItem: InventoryItem | null;
  dragSource: string | null;
  dropTarget: string | null;
  onDropTargetChange: (t: string | null) => void;
  onMouseDown: (e: React.MouseEvent, item: InventoryItem, source: string) => void;
  onContextMenu: (e: React.MouseEvent, item: InventoryItem) => void;
  isFounder?: boolean;
  onOutfitSlotDrop: (slotType: string, item: InventoryItem) => void;
  onOutfitResultDrop: (item: InventoryItem) => void;
  outfitAssemblerSlots: Record<string, InventoryItem | null>;
  outfitResultSlot: InventoryItem | null;
  onOutfitSlotClear: (slotType: string) => void;
  onOutfitResultClear: () => void;
  onOutfitAssemble: () => void;
  onOutfitDisassemble: () => void;
  hideWeight?: boolean;
  onHideWeightChange?: (v: boolean) => void;
  /* ---- Chest (right inventory) integration ---- */
  chestVisible: boolean;
  chestInventory: InventoryItem[];
  chestTitle: string;
  chestWeight: number;
  chestMaxWeight: number;
  bagMode: boolean;
  onCloseBag: () => void;
  metabolismData: MetabolismData | null;
}

/* ---- Quick Links config ---- */
const QUICK_LINKS = [
  { id: 'reglement', label: 'Reglement', icon: BookOpen, action: 'hub:openReglement' },
  { id: 'hud', label: 'HUD Editor', icon: Monitor, action: 'hub:openHudEditor' },
  { id: 'boutique', label: 'Boutique', icon: ShoppingBag, action: 'hub:openBoutique' },
  { id: 'tablet', label: 'Tablette', icon: Smartphone, action: 'hub:openTablet' },
  { id: 'animations', label: 'Animations', icon: Drama, action: 'hub:openAnimations' },
];

/* ---- Options categories config ---- */
const OPTIONS_CATEGORIES: { key: OptionsCategory; label: string; icon: React.FC<any> }[] = [
  { key: 'demarche', label: 'Démarche', icon: Footprints },
  { key: 'blips', label: 'Blips', icon: MapPin },
  { key: 'combat', label: 'Combat', icon: Swords },
  { key: 'affichage', label: 'Affichage', icon: Eye },
  { key: 'vehicules', label: 'Véhicules', icon: Car },
  { key: 'autre', label: 'Autre', icon: MoreHorizontal },
];

const HubPanel: React.FC<HubPanelProps> = ({
  serverIcon, serverName,
  playerName, playerId, playerUniqueId, playerJob, playerMoney, playerBank, playerDirtyMoney,
  craftRecipes, craftingId, craftProgress, craftTableId, craftTableBased,
  settings, onSettingChange, optionsData, societies,
  outfitData, backpackData, leftInventory, playerSex, failedImages,
  isDragging, dragItem, dragSource, dropTarget, onDropTargetChange, onMouseDown, onContextMenu,
  isFounder,
  onOutfitSlotDrop, onOutfitResultDrop,
  outfitAssemblerSlots, outfitResultSlot,
  onOutfitSlotClear, onOutfitResultClear,
  onOutfitAssemble, onOutfitDisassemble,
  hideWeight = false, onHideWeightChange,
  chestVisible, chestInventory, chestTitle, chestWeight, chestMaxWeight, bagMode, onCloseBag,
  metabolismData,
}) => {
  const [page, setPage] = useState<HubPage>('home');
  const [selectedRecipe, setSelectedRecipe] = useState<CraftRecipe | null>(null);
  const [craftTooltip, setCraftTooltip] = useState<{ recipe: CraftRecipe; x: number; y: number } | null>(null);
  const [optionsCategory, setOptionsCategory] = useState<OptionsCategory | null>(null);
  const [walkSearch, setWalkSearch] = useState('');
  const [societySearch, setSocietySearch] = useState('');

  /* ---- Society card renderer (shared by home preview & entreprises tab) ---- */
  const HOME_SOCIETY_PREVIEW = 4;
  const renderSocietyCard = useCallback((s: SocietyInfo) => {
    const accent = s.brandColor || '#3498db';
    const logoUrl = s.logo ? cacheImg(s.logo) : null;
    return (
      <button
        key={s.name}
        className={`ni-hub-society-card ${s.state ? 'ni-open' : 'ni-closed'}`}
        style={{ ['--society-accent' as any]: accent }}
        onClick={() => {
          if (s.hasPosition) nuiCallback('newInventory:societyWaypoint', { name: s.name });
        }}
        disabled={!s.hasPosition}
        title={s.hasPosition ? 'Définir un GPS vers cette entreprise' : ''}
      >
        <div className="ni-hub-society-logo">
          {logoUrl ? (
            <img
              src={logoUrl}
              alt={s.label}
              draggable={false}
              onError={(e) => { (e.currentTarget as HTMLImageElement).style.display = 'none'; }}
            />
          ) : (
            <span className="ni-hub-society-logo-fallback">
              {(s.label || s.name).slice(0, 2).toUpperCase()}
            </span>
          )}
        </div>
        <div className="ni-hub-society-info">
          <div className="ni-hub-society-name">{s.label}</div>
          {s.description ? (
            <div className="ni-hub-society-desc">{s.description}</div>
          ) : (
            <div className="ni-hub-society-desc ni-hub-society-desc-empty">{s.type || 'Entreprise'}</div>
          )}
        </div>
        <div className={`ni-hub-society-status ${s.state ? 'open' : 'closed'}`}>
          <span className="ni-hub-society-dot" />
          {s.state ? 'Ouvert' : 'Fermé'}
        </div>
      </button>
    );
  }, []);

  /* Minimalist home preview: prioritize open entreprises, capped, with "Voir plus" */
  const homeSocietiesPreview = useMemo(() => {
    const open = societies.filter(s => s.state);
    const closed = societies.filter(s => !s.state);
    return [...open, ...closed].slice(0, HOME_SOCIETY_PREVIEW);
  }, [societies]);

  /* Full list for the entreprises tab, with optional search filter */
  const filteredSocieties = useMemo(() => {
    const q = societySearch.trim().toLowerCase();
    if (!q) return societies;
    return societies.filter(s =>
      (s.label || '').toLowerCase().includes(q) ||
      (s.name || '').toLowerCase().includes(q) ||
      (s.type || '').toLowerCase().includes(q) ||
      (s.description || '').toLowerCase().includes(q)
    );
  }, [societies, societySearch]);

  useEffect(() => {
    if (craftTableBased && craftRecipes.length > 0) {
      setPage('craft');
    }
  }, [craftTableBased, craftRecipes]);

  /* ---- Admin tabs state ---- */
  const [allItems, setAllItems] = useState<InventoryItem[]>([]);
  const [allItemsLoading, setAllItemsLoading] = useState(false);
  const [allItemsSearch, setAllItemsSearch] = useState('');
  const [allItemsFilter, setAllItemsFilter] = useState<'all' | 'weapon' | 'item' | 'account'>('all');
  const [allItemsPage, setAllItemsPage] = useState(1);
  const ALL_ITEMS_PER_PAGE = 50;

  /* ---- Chest search/filter state ---- */
  const [chestSearch, setChestSearch] = useState('');
  const [chestFilter, setChestFilter] = useState<'all' | 'weapon' | 'clothes' | 'food'>('all');

  /* ---- Auto-switch to chest tab when opening / away when closing ---- */
  const prevChestVisibleRef = React.useRef(false);
  useEffect(() => {
    if (chestVisible && !prevChestVisibleRef.current) {
      setPage('chest');
    } else if (!chestVisible && prevChestVisibleRef.current && page === 'chest') {
      setPage('home');
    }
    prevChestVisibleRef.current = chestVisible;
  }, [chestVisible]);


  const handleQuickLink = useCallback((action: string) => {
    nuiCallback('newInventory:hubAction', { action });
  }, []);

  const handleCraft = useCallback((recipe: CraftRecipe) => {
    nuiCallback('newInventory:advancedCraft', {
      recipeId: recipe.id,
      tableId: recipe.tableId || craftTableId,
      isLegacyWeaponCraft: recipe.isLegacyWeaponCraft || false,
      time: recipe.time,
    });
  }, [craftTableId]);

  const canCraft = (recipe: CraftRecipe): boolean => {
    return recipe.requirements.every(r => (r.have ?? 0) >= r.amount);
  };

  /* ---- Backpack handlers ---- */
  const handleBackpackAction = useCallback((action: string, data?: any) => {
    nuiCallback(`newInventory:${action}`, data || {});
  }, []);

  const handleTogglePreference = useCallback((id: string, currentEnabled: boolean) => {
    nuiCallback('newInventory:togglePreference', { id, enabled: !currentEnabled });
  }, []);

  const handleToggleBlip = useCallback((kvpName: string, currentEnabled: boolean) => {
    nuiCallback('newInventory:toggleBlip', { kvpName, enabled: !currentEnabled });
  }, []);

  const handleSetWalkStyle = useCallback((name: string) => {
    nuiCallback('newInventory:setWalkStyle', { name });
  }, []);

  /* ---- Outfit assembler slots config ---- */
  const ASSEMBLER_SLOTS = Object.keys(OUTFIT_SLOT_LABELS).filter(k => k !== 'bag' && k !== 'ear' && k !== 'bracelet' && k !== 'watch');
  const filledSlotCount = ASSEMBLER_SLOTS.filter(t => outfitAssemblerSlots[t] != null).length;
  const canAssemble = filledSlotCount >= 2;
  const canDisassemble = outfitResultSlot != null && outfitResultSlot.type === 'accessory' && outfitResultSlot.type2 === 'outfit';
  const [assemblerTooltip, setAssemblerTooltip] = useState(false);

  /* ---- Admin: fetch all items ---- */
  const fetchAllItems = useCallback(() => {
    if (allItemsLoading) return;
    setAllItemsLoading(true);
    nuiCallback('newInventory:fetchAllItems', {}).then((res: any) => {
      if (res?.success && Array.isArray(res.items)) {
        setAllItems(res.items);
      } else {
        console.warn('[Inventory] All Items unavailable:', res?.reason || res);
        setAllItems([]);
      }
      setAllItemsLoading(false);
    }).catch(() => setAllItemsLoading(false));
  }, [allItemsLoading]);

  // Auto-fetch when switching to admin tabs
  useEffect(() => {
    if (page === 'allitems' && allItems.length === 0 && !allItemsLoading) fetchAllItems();
  }, [page]);

  /* ---- Admin: All Items Page ---- */
  const allItemsFiltered = useMemo(() => {
    const term = allItemsSearch.toLowerCase();
    let filtered = term
      ? allItems.filter(i => (i.label || i.name).toLowerCase().includes(term) || i.name.toLowerCase().includes(term))
      : allItems;
    if (allItemsFilter !== 'all') {
      filtered = filtered.filter(i => i.type === allItemsFilter);
    }
    filtered = [...filtered].sort((a, b) => {
      const typeOrder: Record<string, number> = { account: 0, item: 1, weapon: 2 };
      const aOrder = typeOrder[a.type] ?? 3;
      const bOrder = typeOrder[b.type] ?? 3;
      if (aOrder !== bOrder) return aOrder - bOrder;
      return (a.label || a.name).localeCompare(b.label || b.name);
    });
    return filtered;
  }, [allItems, allItemsSearch, allItemsFilter]);

  const allItemsPaginated = useMemo(() => {
    return allItemsFiltered.slice(0, allItemsPage * ALL_ITEMS_PER_PAGE);
  }, [allItemsFiltered, allItemsPage]);

  const renderAllItems = () => {
    const hasMore = allItemsPaginated.length < allItemsFiltered.length;
    return (
      <div className="ni-hub-backpack-inventory">
        <div className="ni-panel-header">
          <div className="ni-panel-title">
            <h2>Tous les items</h2>
          </div>
          <div className="ni-panel-header-right">
            <div className="ni-weight-info">
              <Package size={14} />
              <span>{allItemsFiltered.length}/{allItems.length}</span>
            </div>
            <button className="ni-bag-close-btn" onClick={fetchAllItems} disabled={allItemsLoading} title="Rafraîchir">
              {allItemsLoading ? <Loader2 size={14} className="ni-spin" /> : <ArrowRightLeft size={14} />}
            </button>
          </div>
        </div>

        <div className="ni-search-row">
          <div className="ni-search-input">
            <Search size={14} />
            <input
              type="text"
              placeholder="Rechercher un item..."
              value={allItemsSearch}
              onChange={e => { setAllItemsSearch(e.target.value); setAllItemsPage(1); }}
            />
          </div>
          <div className="ni-filters">
            {([
              { key: 'all' as const, icon: <Grid3X3 size={14} />, tip: 'Tout' },
              { key: 'weapon' as const, icon: <Sword size={14} />, tip: 'Armes' },
              { key: 'item' as const, icon: <Box size={14} />, tip: 'Items' },
              { key: 'account' as const, icon: <Coins size={14} />, tip: 'Argent' },
            ]).map(f => (
              <button
                key={f.key}
                className={`ni-filter-btn ${allItemsFilter === f.key ? 'active' : ''}`}
                onClick={() => { setAllItemsFilter(f.key); setAllItemsPage(1); }}
                title={f.tip}
              >
                {f.icon}
              </button>
            ))}
          </div>
        </div>

        {allItemsLoading && allItems.length === 0 ? (
          <div className="ni-hub-admin-loading">
            <Loader2 size={24} className="ni-spin" />
            <span>Chargement...</span>
          </div>
        ) : (
          <>
            <ItemGrid
              id="allitems"
              items={allItemsPaginated}
              emptyText="Aucun item"
              playerSex={playerSex}
              failedImages={failedImages}
              isDragging={isDragging}
              dragItem={dragItem}
              dragSource={dragSource}
              dropTarget={dropTarget}
              onMouseDown={onMouseDown}
              onContextMenu={onContextMenu}
              onDropTargetChange={onDropTargetChange}
            />
            {hasMore && (
              <button
                className="ni-hub-craft-btn"
                style={{ marginTop: 8, fontSize: 11 }}
                onClick={() => setAllItemsPage(p => p + 1)}
              >
                Charger plus ({allItemsPaginated.length}/{allItemsFiltered.length})
              </button>
            )}
          </>
        )}
      </div>
    );
  };

  /* ---- Chest Tab (right inventory integrated into hub) ---- */
  const renderChest = () => {
    const term = chestSearch.toLowerCase();
    let filtered = chestInventory.filter(item => {
      const matchesSearch = !term ||
        String(item.label || '').toLowerCase().includes(term) ||
        String(item.name || '').toLowerCase().includes(term);
      let matchesFilter = true;
      if (chestFilter === 'weapon') matchesFilter = item.type === 'weapon';
      else if (chestFilter === 'clothes') matchesFilter = item.type === 'accessory';
      else if (chestFilter === 'food') matchesFilter = item.type === 'item';
      return matchesSearch && matchesFilter;
    });

    return (
      <div className="ni-hub-backpack-inventory">
        <div className="ni-panel-header">
          <div className="ni-panel-title">
            <h2>{chestTitle || 'Coffre'}</h2>
          </div>
          <div className="ni-panel-header-right">
            <div className="ni-weight-info">
              <Weight size={14} />
              <span>{chestWeight.toFixed(1)}/{chestMaxWeight.toFixed(1)} kg</span>
            </div>
            {bagMode && (
              <button className="ni-bag-close-btn" onClick={onCloseBag} title="Fermer le sac">
                <X size={14} />
              </button>
            )}
          </div>
        </div>

        <div className="ni-search-row">
          <div className="ni-search-input">
            <Search size={14} />
            <input
              type="text"
              placeholder="Rechercher un item..."
              value={chestSearch}
              onChange={(e) => setChestSearch(e.target.value)}
            />
          </div>
          <div className="ni-filters">
            {([
              { key: 'all' as const, icon: <Grid3X3 size={14} />, tip: 'Tout' },
              { key: 'weapon' as const, icon: <Sword size={14} />, tip: 'Armes' },
              { key: 'clothes' as const, icon: <Shirt size={14} />, tip: 'Vetements' },
              { key: 'food' as const, icon: <Box size={14} />, tip: 'Items' },
            ]).map(f => (
              <button
                key={f.key}
                className={`ni-filter-btn ${chestFilter === f.key ? 'active' : ''}`}
                onClick={() => setChestFilter(f.key)}
                title={f.tip}
              >
                {f.icon}
              </button>
            ))}
          </div>
        </div>

        <ItemGrid
          id="right"
          items={filtered}
          emptyText="Vide"
          playerSex={playerSex}
          failedImages={failedImages}
          isDragging={isDragging}
          dragItem={dragItem}
          dragSource={dragSource}
          dropTarget={dropTarget}
          onMouseDown={onMouseDown}
          onContextMenu={onContextMenu}
          onDropTargetChange={onDropTargetChange}
          hideWeight={hideWeight}
        />
      </div>
    );
  };

  /* ---- Home Page ---- */
  const renderHome = () => (
    <div className="ni-hub-home">
      {/* --- Player hero card --- */}
      <div className="ni-hub-hero">
        <div className="ni-hub-hero-head">
          <div className="ni-hub-hero-avatar">
            {serverIcon
              ? <img src={serverIcon} alt={serverName || ''} draggable={false} onError={(e) => { (e.currentTarget as HTMLImageElement).style.display = 'none'; }} />
              : <span>{(playerName || 'J').slice(0, 1).toUpperCase()}</span>
            }
          </div>
          <div className="ni-hub-hero-identity">
            <div className="ni-hub-hero-name">{playerName || 'Joueur'}</div>
            <div className="ni-hub-hero-job">{playerJob || 'Sans emploi'}</div>
            <div className="ni-hub-hero-meta">
              {playerId && <span className="ni-hub-hero-meta-id">#{playerId}</span>}
              {playerId && playerUniqueId && <span className="ni-hub-hero-meta-sep">·</span>}
              {playerUniqueId && <span className="ni-hub-hero-meta-uid" title={playerUniqueId}>{playerUniqueId}</span>}
            </div>
          </div>
        </div>

        <div className="ni-hub-hero-balances">
          <div className="ni-hub-hero-balance">
            <span className="ni-hub-hero-balance-label">Liquide</span>
            <span className="ni-hub-hero-balance-amount">${(playerMoney || 0).toLocaleString()}</span>
          </div>
          <div className="ni-hub-hero-balance-sep" />
          <div className="ni-hub-hero-balance">
            <span className="ni-hub-hero-balance-label">Sale</span>
            <span className="ni-hub-hero-balance-amount ni-hub-hero-balance-dirty">${(playerDirtyMoney || 0).toLocaleString()}</span>
          </div>
          <div className="ni-hub-hero-balance-sep" />
          <div className="ni-hub-hero-balance">
            <span className="ni-hub-hero-balance-label">Banque</span>
            <span className="ni-hub-hero-balance-amount">${(playerBank || 0).toLocaleString()}</span>
          </div>
        </div>
      </div>

      <div className="ni-hub-section-title">Acces rapide</div>
      <div className="ni-hub-grid">
        {QUICK_LINKS.map(link => {
          const Icon = link.icon;
          return (
            <button
              key={link.id}
              className="ni-hub-grid-slot"
              onClick={() => handleQuickLink(link.action)}
            >
              <div className="ni-hub-grid-icon">
                <Icon size={20} />
              </div>
              <span className="ni-hub-grid-label">{link.label}</span>
            </button>
          );
        })}
      </div>

      {/* ---- Societies status (compact preview) ---- */}
      {societies && societies.length > 0 && (
        <>
          <div className="ni-hub-section-title">
            Entreprises
            {societies.length > homeSocietiesPreview.length ? (
              <button
                className="ni-hub-section-link"
                onClick={() => { setSocietySearch(''); setPage('entreprises'); }}
              >
                Voir toutes <ChevronRight size={11} />
              </button>
            ) : (
              <span className="ni-hub-section-count">
                {societies.filter(s => s.state).length}/{societies.length} ouvertes
              </span>
            )}
          </div>
          <div className="ni-hub-society-compact">
            {homeSocietiesPreview.map(renderSocietyCard)}
          </div>
        </>
      )}

      {/* ---- Outfit Assembler ---- */}
      <div className="ni-hub-section-title">Assembleur de tenues</div>
      <div className="ni-outfit-assembler">
        {/* LEFT — clothing/accessory input slots */}
        <div className="ni-oa-slots">
          {ASSEMBLER_SLOTS.map(type => {
            const filled = outfitAssemblerSlots[type] || null;
            const slotDef = ACCESSORY_SLOTS.find(s => s.key === type);
            return (
              <DragSlot
                key={type}
                slotId={`outfit-slot-${type}`}
                item={filled}
                playerSex={playerSex}
                failedImages={failedImages}
                isDragging={isDragging}
                dropTarget={dropTarget}
                onDropTargetChange={onDropTargetChange}
                onMouseDown={onMouseDown}
                onDoubleClick={filled ? () => onOutfitSlotClear(type) : undefined}
                className={`ni-oa-slot ${filled ? 'ni-oa-filled' : ''}`}
                title={filled ? `${OUTFIT_SLOT_LABELS[type]}: ${filled.label || filled.name}` : OUTFIT_SLOT_LABELS[type]}
                placeholder={
                  <>
                    {slotDef && (
                      <img
                        className="ni-oa-placeholder-img"
                        src={cacheImg(slotDef.placeholderImg)}
                        alt={slotDef.label}
                        draggable={false}
                      />
                    )}
                    <span className="ni-oa-slot-label">{OUTFIT_SLOT_LABELS[type]}</span>
                  </>
                }
              />
            );
          })}
        </div>

        {/* CENTER — arrow button */}
        <div className="ni-oa-arrow-wrap">
          <button
            className={`ni-oa-arrow-btn ${canAssemble || canDisassemble ? 'ni-oa-active' : ''}`}
            disabled={!canAssemble && !canDisassemble}
            onClick={() => {
              if (canDisassemble) onOutfitDisassemble();
              else if (canAssemble) onOutfitAssemble();
            }}
            onMouseEnter={() => setAssemblerTooltip(true)}
            onMouseLeave={() => setAssemblerTooltip(false)}
          >
            <ArrowRightLeft size={16} />
          </button>
          {assemblerTooltip && (
            <div className="ni-oa-tooltip">
              {canDisassemble
                ? 'Désassembler la tenue'
                : canAssemble
                  ? `Assembler ${filledSlotCount} pièces`
                  : 'Glissez des vêtements ou une tenue'
              }
            </div>
          )}
        </div>

        {/* RIGHT — outfit result slot */}
        <DragSlot
          slotId="outfit-result"
          item={outfitResultSlot}
          playerSex={playerSex}
          failedImages={failedImages}
          isDragging={isDragging}
          dropTarget={dropTarget}
          onDropTargetChange={onDropTargetChange}
          onMouseDown={onMouseDown}
          onDoubleClick={outfitResultSlot ? () => onOutfitResultClear() : undefined}
          className={`ni-oa-result ${outfitResultSlot ? 'ni-oa-filled' : ''}`}
          title={outfitResultSlot ? `${outfitResultSlot.label || 'Tenue'}` : 'Tenue assemblée'}
          placeholder={
            <>
              <Shirt size={16} style={{ opacity: 0.3 }} />
              <span className="ni-oa-slot-label">Tenue</span>
            </>
          }
        />
      </div>
    </div>
  );

  /* ---- Options Page ---- */
  const renderOptions = () => {
    if (!optionsData) {
      return (
        <div className="ni-hub-empty">
          <Settings size={24} />
          <span>Chargement des options...</span>
        </div>
      );
    }

    // Category list view
    if (!optionsCategory) {
      return (
        <div className="ni-hub-options">
          <div className="ni-hub-section-title">Options</div>
          <div className="ni-opt-cat-list">
            {OPTIONS_CATEGORIES.map(cat => {
              const Icon = cat.icon;
              return (
                <button
                  key={cat.key}
                  className="ni-opt-cat-btn"
                  onClick={() => { setOptionsCategory(cat.key); setWalkSearch(''); }}
                >
                  <div className="ni-opt-cat-icon">
                    <Icon size={16} />
                  </div>
                  <span className="ni-opt-cat-label">{cat.label}</span>
                  <ChevronRight size={14} className="ni-opt-cat-arrow" />
                </button>
              );
            })}
          </div>
        </div>
      );
    }

    // Back button + category content
    const catDef = OPTIONS_CATEGORIES.find(c => c.key === optionsCategory)!;

    return (
      <div className="ni-hub-options">
        <button className="ni-hub-back-btn" onClick={() => setOptionsCategory(null)}>
          <ChevronLeft size={16} /> Retour
        </button>
        <div className="ni-hub-section-title">
          {catDef.label}
        </div>

        {optionsCategory === 'demarche' && renderDemarche()}
        {optionsCategory === 'blips' && renderBlips()}
        {optionsCategory === 'combat' && renderPreferenceCategory('fight')}
        {optionsCategory === 'affichage' && renderAffichage()}
        {optionsCategory === 'vehicules' && renderPreferenceCategory('vehicle')}
        {optionsCategory === 'autre' && renderAutre()}
      </div>
    );
  };

  /* ---- Démarche sub-page ---- */
  const renderDemarche = () => {
    if (!optionsData) return null;
    const walks = optionsData.walkStyles || [];
    const filtered = walkSearch
      ? walks.filter(w => w.name.toLowerCase().includes(walkSearch.toLowerCase()))
      : walks;

    return (
      <div className="ni-opt-demarche">
        <div className="ni-opt-current-walk">
          <Footprints size={14} />
          <span>Démarche actuelle :</span>
          <strong>{optionsData.currentWalk || 'Par défaut'}</strong>
        </div>
        <div className="ni-opt-search">
          <Search size={14} />
          <input
            type="text"
            placeholder="Rechercher une démarche..."
            value={walkSearch}
            onChange={e => setWalkSearch(e.target.value)}
          />
        </div>
        <div className="ni-opt-walk-list">
          {filtered.map(walk => (
            <button
              key={walk.name}
              className={`ni-opt-walk-item ${optionsData.currentWalk === walk.name ? 'active' : ''}`}
              onClick={() => handleSetWalkStyle(walk.name)}
            >
              <span className="ni-opt-walk-name">{walk.name}</span>
              {optionsData.currentWalk === walk.name && <Check size={14} />}
            </button>
          ))}
          {filtered.length === 0 && (
            <div className="ni-hub-empty" style={{ padding: '20px 0' }}>Aucune démarche trouvée</div>
          )}
        </div>
      </div>
    );
  };

  /* ---- Blips sub-page ---- */
  const renderBlips = () => {
    if (!optionsData) return null;
    return (
      <div className="ni-opt-toggles">
        {optionsData.blips.map(blip => (
          <div key={blip.kvpName} className="ni-opt-toggle-item">
            <div className="ni-opt-toggle-info">
              <div className="ni-opt-toggle-label">{blip.label}</div>
            </div>
            <button
              className={`ni-hub-toggle ${blip.enabled ? 'active' : ''}`}
              onClick={() => handleToggleBlip(blip.kvpName, blip.enabled)}
            >
              {blip.enabled ? <ToggleRight size={24} /> : <ToggleLeft size={24} />}
            </button>
          </div>
        ))}
      </div>
    );
  };

  /* ---- Preference category (combat, vehicules) ---- */
  const renderPreferenceCategory = (category: string) => {
    if (!optionsData) return null;
    const prefs = optionsData.preferences.filter(p => p.category === category);
    if (prefs.length === 0) {
      return <div className="ni-hub-empty" style={{ padding: '20px 0' }}>Aucune option disponible</div>;
    }
    return (
      <div className="ni-opt-toggles">
        {prefs.map(pref => (
          <div key={pref.id} className="ni-opt-toggle-item">
            <div className="ni-opt-toggle-info">
              <div className="ni-opt-toggle-label">{pref.label}</div>
              {pref.description && <div className="ni-opt-toggle-desc">{pref.description}</div>}
            </div>
            <button
              className={`ni-hub-toggle ${pref.enabled ? 'active' : ''}`}
              onClick={() => handleTogglePreference(pref.id, pref.enabled)}
            >
              {pref.enabled ? <ToggleRight size={24} /> : <ToggleLeft size={24} />}
            </button>
          </div>
        ))}
      </div>
    );
  };

  /* ---- Affichage sub-page (ui prefs + special toggles) ---- */
  const renderAffichage = () => {
    if (!optionsData) return null;
    // 'ui' category prefs + the special affichage toggles (radar, hud, cinema)
    const uiPrefs = optionsData.preferences.filter(p => p.category === 'ui');
    return (
      <div className="ni-opt-toggles">
        {uiPrefs.map(pref => (
          <div key={pref.id} className="ni-opt-toggle-item">
            <div className="ni-opt-toggle-info">
              <div className="ni-opt-toggle-label">{pref.label}</div>
              {pref.description && <div className="ni-opt-toggle-desc">{pref.description}</div>}
            </div>
            <button
              className={`ni-hub-toggle ${pref.enabled ? 'active' : ''}`}
              onClick={() => handleTogglePreference(pref.id, pref.enabled)}
            >
              {pref.enabled ? <ToggleRight size={24} /> : <ToggleLeft size={24} />}
            </button>
          </div>
        ))}
        {/* Local UI toggle: hide item weights */}
        <div className="ni-opt-toggle-item">
          <div className="ni-opt-toggle-info">
            <div className="ni-opt-toggle-label">Masquer le poids</div>
            <div className="ni-opt-toggle-desc">Cacher le poids des objets dans l'inventaire</div>
          </div>
          <button
            className={`ni-hub-toggle ${hideWeight ? 'active' : ''}`}
            onClick={() => onHideWeightChange?.(!hideWeight)}
          >
            {hideWeight ? <ToggleRight size={24} /> : <ToggleLeft size={24} />}
          </button>
        </div>
      </div>
    );
  };

  /* ---- Autre sub-page (root prefs: interfaces, cloneped, informations objets) ---- */
  const renderAutre = () => {
    if (!optionsData) return null;
    const rootPrefs = optionsData.preferences.filter(p => !p.category || p.category === 'root');
    return (
      <div className="ni-opt-toggles">
        {rootPrefs.map(pref => (
          <div key={pref.id} className="ni-opt-toggle-item">
            <div className="ni-opt-toggle-info">
              <div className="ni-opt-toggle-label">{pref.label}</div>
              {pref.description && <div className="ni-opt-toggle-desc">{pref.description}</div>}
            </div>
            <button
              className={`ni-hub-toggle ${pref.enabled ? 'active' : ''}`}
              onClick={() => handleTogglePreference(pref.id, pref.enabled)}
            >
              {pref.enabled ? <ToggleRight size={24} /> : <ToggleLeft size={24} />}
            </button>
          </div>
        ))}
      </div>
    );
  };

  /* ---- Craft search & filter ---- */
  const [craftSearch, setCraftSearch] = useState('');
  const [craftFilter, setCraftFilter] = useState<'all' | 'weapon' | 'item' | 'ready'>('all');

  const filteredRecipes = useMemo(() => {
    const term = craftSearch.trim().toLowerCase();
    return craftRecipes.filter(r => {
      const matchesSearch = !term
        || (r.label || '').toLowerCase().includes(term)
        || (r.item || '').toLowerCase().includes(term)
        || (r.description || '').toLowerCase().includes(term);
      if (!matchesSearch) return false;
      if (craftFilter === 'weapon') return r.type === 'weapon';
      if (craftFilter === 'item') return !r.type || r.type === 'item';
      if (craftFilter === 'ready') return canCraft(r);
      return true;
    });
  }, [craftRecipes, craftSearch, craftFilter]);

  /* ---- Backpack Page ---- */
  const [backpackSearch, setBackpackSearch] = useState('');
  const [backpackFilter, setBackpackFilter] = useState<'all' | 'weapon' | 'clothes' | 'food'>('all');

  const renderBackpack = () => {
    if (!backpackData || !backpackData.hasBag) {
      return (
        <div className="ni-hub-backpack">
          <div className="ni-hub-empty">
            <Backpack size={24} />
            <span>Aucun sac équipé</span>
            <span className="ni-hub-empty-sub">Équipez un sac pour accéder à son inventaire</span>
          </div>
        </div>
      );
    }

    const items = backpackData.items || [];
    const weight = backpackData.weight || 0;
    const maxWeight = backpackData.maxWeight || 15;

    const filteredItems = items.filter(item => {
      const matchesSearch = !backpackSearch ||
        String(item.label || '').toLowerCase().includes(backpackSearch.toLowerCase()) ||
        String(item.name || '').toLowerCase().includes(backpackSearch.toLowerCase());
      let matchesFilter = true;
      if (backpackFilter === 'weapon') matchesFilter = item.type === 'weapon';
      else if (backpackFilter === 'clothes') matchesFilter = item.type === 'accessory';
      else if (backpackFilter === 'food') matchesFilter = item.type === 'item';
      return matchesSearch && matchesFilter;
    });

    return (
      <div className="ni-hub-backpack-inventory">
        <div className="ni-hub-backpack-header">
          <div className="ni-hub-backpack-title">
            <Backpack size={16} />
            <span>{backpackData.bagName || 'Sac à dos'}</span>
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
              value={backpackSearch}
              onChange={(e) => setBackpackSearch(e.target.value)}
            />
          </div>
          <div className="ni-filters">
            {([
              { key: 'all' as const, icon: <Grid3X3 size={14} />, tip: 'Tout' },
              { key: 'weapon' as const, icon: <Sword size={14} />, tip: 'Armes' },
              { key: 'clothes' as const, icon: <Shirt size={14} />, tip: 'Vetements' },
              { key: 'food' as const, icon: <Box size={14} />, tip: 'Items' },
            ]).map(f => (
              <button
                key={f.key}
                className={`ni-filter-btn ${backpackFilter === f.key ? 'active' : ''}`}
                onClick={() => setBackpackFilter(f.key)}
                title={f.tip}
              >
                {f.icon}
              </button>
            ))}
          </div>
        </div>

        <ItemGrid
          id="backpack"
          items={filteredItems}
          playerSex={playerSex}
          failedImages={failedImages}
          isDragging={isDragging}
          dragItem={dragItem}
          dragSource={dragSource}
          dropTarget={dropTarget}
          onMouseDown={onMouseDown}
          onContextMenu={onContextMenu}
          onDropTargetChange={onDropTargetChange}
        />
      </div>
    );
  };

  /* ---- Entreprises Page (full list with search, GPS on click) ---- */
  const renderEntreprises = () => (
    <div className="ni-hub-societies">
      <div className="ni-panel-header">
        <div className="ni-panel-title">
          <h2>Status des entreprises</h2>
        </div>
        <div className="ni-weight-info">
          <Building2 size={14} />
          <span>
            {societies.filter(s => s.state).length}/{societies.length}
          </span>
        </div>
      </div>

      {societies.length > 0 && (
        <div className="ni-search-row">
          <div className="ni-search-input">
            <Search size={14} />
            <input
              type="text"
              placeholder="Rechercher une entreprise..."
              value={societySearch}
              onChange={(e) => setSocietySearch(e.target.value)}
            />
          </div>
        </div>
      )}

      {societies.length === 0 ? (
        <div className="ni-hub-empty">
          <Building2 size={24} />
          <span>Aucune entreprise disponible</span>
        </div>
      ) : filteredSocieties.length === 0 ? (
        <div className="ni-hub-empty">
          <Search size={24} />
          <span>Aucun résultat</span>
        </div>
      ) : (
        <div className="ni-hub-society-grid">
          {filteredSocieties.map(renderSocietyCard)}
        </div>
      )}
    </div>
  );

  /* ---- Craft Page ---- */
  const renderCraft = () => (
    <div className="ni-hub-craft">
      {selectedRecipe ? (
        <div className="ni-hub-craft-detail">
          <button className="ni-hub-back-btn" onClick={() => setSelectedRecipe(null)}>
            <ChevronLeft size={16} /> Retour
          </button>
          <div className="ni-hub-craft-header">
            <div className="ni-hub-craft-icon">
              {selectedRecipe.icon ? (
                <img src={selectedRecipe.icon} alt="" draggable={false} />
              ) : (
                <Package size={28} />
              )}
            </div>
            <div>
              <div className="ni-hub-craft-name">{selectedRecipe.label}</div>
              {selectedRecipe.description && (
                <div className="ni-hub-craft-desc">{selectedRecipe.description}</div>
              )}
              <div className="ni-hub-craft-time">
                <Clock size={12} /> {selectedRecipe.time}s
              </div>
            </div>
          </div>

          <div className="ni-hub-section-title">Ingredients requis</div>
          <div className="ni-hub-craft-reqs">
            {selectedRecipe.requirements.map((req, i) => {
              const hasEnough = (req.have ?? 0) >= req.amount;
              return (
                <div key={i} className={`ni-hub-craft-req ${hasEnough ? 'ni-has' : 'ni-missing'}`}>
                  {req.icon ? (
                    <img className="ni-hub-craft-req-icon" src={req.icon} alt="" draggable={false} />
                  ) : (
                    <div className="ni-hub-craft-req-icon ni-hub-craft-req-placeholder">
                      <Package size={16} />
                    </div>
                  )}
                  <div className="ni-hub-craft-req-info">
                    <span className="ni-hub-craft-req-name">{req.label}</span>
                    <span className="ni-hub-craft-req-count">
                      {req.have ?? 0}/{req.amount}
                    </span>
                  </div>
                  {hasEnough ? <Check size={14} className="ni-hub-craft-req-check" /> : <X size={14} className="ni-hub-craft-req-x" />}
                </div>
              );
            })}
          </div>

          {craftingId === selectedRecipe.id ? (
            <div className="ni-hub-craft-progress">
              <div className="ni-hub-craft-progress-bar">
                <div
                  className="ni-hub-craft-progress-fill"
                  style={{ width: `${craftProgress}%` }}
                />
              </div>
              <span>{Math.round(craftProgress)}%</span>
            </div>
          ) : (
            <button
              className={`ni-hub-craft-btn ${canCraft(selectedRecipe) ? '' : 'disabled'}`}
              onClick={() => canCraft(selectedRecipe) && handleCraft(selectedRecipe)}
              disabled={!canCraft(selectedRecipe)}
            >
              {canCraft(selectedRecipe) ? (
                <><Hammer size={15} /> Fabriquer</>
              ) : (
                <><AlertCircle size={15} /> Ingredients manquants</>
              )}
            </button>
          )}
        </div>
      ) : (
        <div className="ni-hub-craft-inventory">
          <div className="ni-panel-header">
            <div className="ni-panel-title">
              <h2>Fabrication</h2>
            </div>
            <div className="ni-weight-info">
              <Package size={14} />
              <span>{filteredRecipes.length}/{craftRecipes.length}</span>
            </div>
          </div>

          {craftRecipes.length > 0 && (
            <div className="ni-search-row">
              <div className="ni-search-input">
                <Search size={14} />
                <input
                  type="text"
                  placeholder="Rechercher une recette..."
                  value={craftSearch}
                  onChange={(e) => setCraftSearch(e.target.value)}
                />
              </div>
              <div className="ni-filters">
                {([
                  { key: 'all' as const, icon: <Grid3X3 size={14} />, tip: 'Tout' },
                  { key: 'weapon' as const, icon: <Sword size={14} />, tip: 'Armes' },
                  { key: 'item' as const, icon: <Box size={14} />, tip: 'Items' },
                  { key: 'ready' as const, icon: <Check size={14} />, tip: 'Disponibles' },
                ]).map(f => (
                  <button
                    key={f.key}
                    className={`ni-filter-btn ${craftFilter === f.key ? 'active' : ''}`}
                    onClick={() => setCraftFilter(f.key)}
                    title={f.tip}
                  >
                    {f.icon}
                  </button>
                ))}
              </div>
            </div>
          )}

          {craftRecipes.length === 0 ? (
            <div className="ni-hub-empty">
              <Hammer size={24} />
              <span>Aucune recette disponible</span>
              <span className="ni-hub-empty-sub">Approchez-vous d'un atelier de craft</span>
            </div>
          ) : filteredRecipes.length === 0 ? (
            <div className="ni-hub-empty">
              <Search size={24} />
              <span>Aucun résultat</span>
            </div>
          ) : (
            <div className="ni-item-grid-wrapper">
              <div className="ni-grid" style={{ ['--ni-grid-columns' as any]: 5 }}>
                {filteredRecipes.map(recipe => {
                  const ready = canCraft(recipe);
                  const isCrafting = craftingId === recipe.id;
                  return (
                    <div
                      key={recipe.id}
                      className={`ni-item-slot ni-craft-item-slot ${ready ? 'ni-craft-ready' : 'ni-craft-missing'} ${isCrafting ? 'ni-craft-active' : ''}`}
                      onClick={() => setSelectedRecipe(recipe)}
                      onMouseEnter={(e) => setCraftTooltip({ recipe, x: e.clientX, y: e.clientY })}
                      onMouseLeave={() => setCraftTooltip(null)}
                      onMouseMove={(e) => craftTooltip?.recipe.id === recipe.id && setCraftTooltip({ recipe, x: e.clientX, y: e.clientY })}
                    >
                      <div className="ni-item-content">
                        {recipe.icon ? (
                          <img src={recipe.icon} alt={recipe.label} draggable={false} />
                        ) : (
                          <Package size={32} style={{ opacity: 0.35 }} />
                        )}
                        <div className={`ni-bag-badge ni-craft-badge ${ready ? 'ni-craft-badge-ready' : 'ni-craft-badge-missing'}`}>
                          {ready ? <Check size={10} /> : <AlertCircle size={10} />}
                        </div>
                        <span className="ni-item-label">{recipe.label}</span>
                        <span className="ni-item-weight">
                          <Clock size={9} style={{ marginRight: 3, verticalAlign: '-1px' }} />
                          {recipe.time}s
                        </span>
                      </div>
                      {isCrafting && (
                        <div className="ni-craft-slot-progress">
                          <div className="ni-craft-slot-progress-fill" style={{ width: `${craftProgress}%` }} />
                        </div>
                      )}
                    </div>
                  );
                })}
              </div>
            </div>
          )}
        </div>
      )}
    </div>
  );

  return (
    <div className="ni-panel ni-hub">
      {/* Tab Navigation */}
      <div className="ni-hub-tabs">
        {([
          ...(chestVisible ? [{ key: 'chest' as HubPage, icon: bagMode ? Backpack : Package, label: bagMode ? 'Sac' : 'Coffre', highlight: true }] : []),
          { key: 'home' as HubPage, icon: Home, label: 'Accueil' },
          { key: 'backpack' as HubPage, icon: Backpack, label: 'Sac' },
          { key: 'entreprises' as HubPage, icon: Building2, label: 'Entreprises' },
          { key: 'craft' as HubPage, icon: Hammer, label: 'Craft' },
          ...(metabolismData !== null ? [{ key: 'metabolism' as HubPage, icon: HeartPulse, label: 'Métabolisme' }] : []),
          { key: 'settings' as HubPage, icon: Settings, label: 'Options' },
          ...(isFounder ? [{ key: 'allitems' as HubPage, icon: Crown, label: 'All Items' }] : []),
        ]).map(tab => {
          const Icon = tab.icon;
          return (
            <button
              key={tab.key}
              className={`ni-hub-tab ${page === tab.key ? 'active' : ''} ${(tab as any).highlight ? 'ni-hub-tab-chest' : ''}`}
              onClick={() => {
                setPage(tab.key);
                setSelectedRecipe(null);
                setOptionsCategory(null);
              }}
            >
              <Icon size={16} />
              <span>{tab.label}</span>
            </button>
          );
        })}
      </div>

      {/* Page Content */}
      <div className="ni-hub-content">
        {page === 'home' && renderHome()}
        {page === 'backpack' && renderBackpack()}
        {page === 'settings' && renderOptions()}
        {page === 'entreprises' && renderEntreprises()}
        {page === 'craft' && renderCraft()}
        {page === 'metabolism' && <MetabolismTab data={metabolismData} />}
        {page === 'allitems' && isFounder && renderAllItems()}
        {page === 'chest' && chestVisible && renderChest()}
      </div>

      {/* Craft Recipe Tooltip - follows mouse */}
      {craftTooltip && (
        <div
          className="ni-craft-tooltip"
          style={{
            position: 'fixed',
            left: craftTooltip.x + 15,
            top: craftTooltip.y + 15,
            zIndex: 99999,
            pointerEvents: 'none',
          }}
        >
          <div className="ni-craft-tooltip-header">
            <span className="ni-craft-tooltip-name">{craftTooltip.recipe.label}</span>
            <span className="ni-craft-tooltip-time">
              <Clock size={10} /> {craftTooltip.recipe.time}s
            </span>
          </div>
          <div className="ni-craft-tooltip-ingredients">
            {craftTooltip.recipe.requirements.map((req, i) => {
              const hasEnough = (req.have ?? 0) >= req.amount;
              return (
                <div key={i} className={`ni-craft-tooltip-ingredient ${hasEnough ? 'ni-has' : 'ni-missing'}`}>
                  {req.icon ? (
                    <img src={req.icon} alt="" className="ni-craft-tooltip-icon" />
                  ) : (
                    <div className="ni-craft-tooltip-icon ni-craft-tooltip-icon-fallback">
                      <Package size={14} />
                    </div>
                  )}
                  <span className="ni-craft-tooltip-ingredient-name">{req.label}</span>
                  <span className="ni-craft-tooltip-ingredient-count">
                    {req.have ?? 0}/{req.amount}
                  </span>
                  {hasEnough ? <Check size={12} className="ni-craft-tooltip-check" /> : <X size={12} className="ni-craft-tooltip-x" />}
                </div>
              );
            })}
          </div>
        </div>
      )}
    </div>
  );
};

export default HubPanel;
