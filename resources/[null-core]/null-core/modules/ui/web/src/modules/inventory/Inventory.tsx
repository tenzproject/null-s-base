import React, { useState, useEffect, useCallback, useRef, useMemo } from 'react';
import { generateAccentVars } from '@/utils/accentColors';
import { soundManager } from '@core/SoundManager';
import { Check } from 'lucide-react';
import {
  InventoryItem, FilterType, CraftRecipe, SettingDef, OptionsData, SocietyInfo,
  OutfitHubData, BackpackData, BackpackPreview, BagInfoMap, MetabolismData,
  isBagItem,
  getAccessoryDataKey, getAccessorySlotKey, normalizeToDataKey,
} from './types';
import { nuiCallback, getItemImageSrc, handleImgError, KEVLAR_ITEM_NAMES } from './components/utils';
import LeftPanel from './components/LeftPanel';
import CenterPanel from './components/CenterPanel';
import HubPanel from './components/HubPanel';
import ContextMenu from './components/ContextMenu';
import './Inventory.css';

interface InventoryProps {
  visible: boolean;
  onClose: () => void;
  primaryColor: string;
  serverIcon?: string;
  serverName?: string;
}

const parseInventorySlotRef = (value: string | null | undefined) => {
  const match = value?.match(/^(left|right|backpack):slot:(\d+)$/);
  if (!match) return null;
  return {
    container: match[1],
    slot: Number(match[2]),
  };
};

const getInventoryItemSlotKey = (item: InventoryItem) => {
  const flexibleItem = item as InventoryItem & { uid?: string | number; uniqueId?: string | number; identifier?: string | number };
  const uniqueId =
    flexibleItem.uid ??
    flexibleItem.uniqueId ??
    flexibleItem.identifier ??
    item.id ??
    item.extra?.identifier ??
    item.extra?.id ??
    item.metadata?.identifier ??
    item.metadata?.id ??
    item.serialnumber;

  const itemType = String(item.type);
  if (itemType === 'cash' || itemType === 'dirtycash') return `${itemType}:${item.name}`;
  return `${item.type}:${item.name}:${uniqueId ?? item.slot ?? ''}`;
};

const Inventory: React.FC<InventoryProps> = ({ visible, onClose, primaryColor, serverIcon, serverName }) => {
  /* ---- Visibility state ---- */
  const [hiding, setHiding] = useState(false);
  const [mounted, setMounted] = useState(false);
  const niAccentVars = useMemo(() => generateAccentVars('--ni-accent', primaryColor), [primaryColor]);

  /* ---- Inventory data ---- */
  const [playerSex, setPlayerSex] = useState<'male' | 'female'>('male');
  const [leftInventory, setLeftInventory] = useState<InventoryItem[]>([]);
  const [rightInventory, setRightInventory] = useState<InventoryItem[]>([]);
  const [leftTitle, setLeftTitle] = useState('Inventaire');
  const [rightTitle, setRightTitle] = useState('');
  const [leftWeight, setLeftWeight] = useState(0);
  const [leftMaxWeight, setLeftMaxWeight] = useState(0);
  const [rightWeight, setRightWeight] = useState(0);
  const [rightMaxWeight, setRightMaxWeight] = useState(0);
  const [rightVisible, setRightVisible] = useState(false);

  /* ---- UI state ---- */
  const [searchTerm, setSearchTerm] = useState('');
  const [activeFilter, setActiveFilter] = useState<FilterType>('all');
  const [contextMenu, setContextMenu] = useState<{ item: InventoryItem; x: number; y: number } | null>(null);
  const [shortcuts, setShortcuts] = useState<(InventoryItem | null)[]>([null, null, null, null, null]);
  const [accessories, setAccessories] = useState<Record<string, InventoryItem | null>>({});
  const [notification, setNotification] = useState<{ text: string; time: number } | null>(null);
  const [isLoading, setIsLoading] = useState(false);

  /* ---- Drag state ---- */
  const [dragItem, setDragItem] = useState<InventoryItem | null>(null);
  const [dragSource, setDragSource] = useState<string | null>(null);
  const [dragPos, setDragPos] = useState({ x: 0, y: 0 });
  const [isDragging, setIsDragging] = useState(false);
  const [dropTarget, setDropTarget] = useState<string | null>(null);
  const [slotMovePending, setSlotMovePending] = useState(false);

  /* ---- Rename state ---- */
  const [renameItem, setRenameItem] = useState<InventoryItem | null>(null);
  const [renameValue, setRenameValue] = useState('');
  const renameInputRef = useRef<HTMLInputElement>(null);

  /* ---- Quantity dialog state ---- */
  const [quantityDialog, setQuantityDialog] = useState<{
    item: InventoryItem;
    from: string;
    to: string;
    max: number;
    targetFreeKg?: number;
    noSpace?: boolean;
  } | null>(null);
  const [quantityValue, setQuantityValue] = useState('1');
  const quantityInputRef = useRef<HTMLInputElement>(null);

  /* ---- Hub state ---- */
  const [playerName, setPlayerName] = useState('');
  const [playerId, setPlayerId] = useState('');
  const [playerUniqueId, setPlayerUniqueId] = useState('');
  const [playerJob, setPlayerJob] = useState('');
  const [playerMoney, setPlayerMoney] = useState(0);
  const [playerDirtyMoney, setPlayerDirtyMoney] = useState(0);
  const [playerBank, setPlayerBank] = useState(0);
  const [craftRecipes, setCraftRecipes] = useState<CraftRecipe[]>([]);
  const [craftingId, setCraftingId] = useState<string | null>(null);
  const [craftProgress, setCraftProgress] = useState(0);
  const [craftTableId, setCraftTableId] = useState<string | null>(null);
  const [craftTableBased, setCraftTableBased] = useState(false);
  const [settings, setSettings] = useState<SettingDef[]>([]);
  const [optionsData, setOptionsData] = useState<OptionsData | null>(null);
  const [societies, setSocieties] = useState<SocietyInfo[]>([]);
  const [hideWeight, setHideWeight] = useState(false);

  /* ---- Metabolism state ---- */
  const [metabolismData, setMetabolismData] = useState<MetabolismData | null>(null);

  /* ---- Outfit state ---- */
  const [outfitData, setOutfitData] = useState<OutfitHubData | null>(null);
  const [outfitAssemblerSlots, setOutfitAssemblerSlots] = useState<Record<string, InventoryItem | null>>({});
  const [outfitResultSlot, setOutfitResultSlot] = useState<InventoryItem | null>(null);

  /* ---- Admin permissions ---- */
  const [isFounder, setIsFounder] = useState(false);
  const [isStaff, setIsStaff] = useState(false);

  /* ---- Backpack state ---- */
  const [backpackData, setBackpackData] = useState<BackpackData | null>(null);
  const [bagMode, setBagMode] = useState<{ enabled: boolean; clotheId?: number | string }>({ enabled: false });
  const [bagInfo, setBagInfo] = useState<BagInfoMap>({});
  const [equippedBagId, setEquippedBagId] = useState<string | number | null>(null);
  const [bagPreviews, setBagPreviews] = useState<Record<string, BackpackPreview>>({});

  /* ---- Kevlar state ---- */
  const [kevlarEquipped, setKevlarEquipped] = useState(false);
  const [kevlarExtraId, setKevlarExtraId] = useState<string | number | null>(null);

  /* ---- Ped visibility ---- */
  const [pedOccluded, setPedOccluded] = useState(false);

  /* ---- Refs ---- */
  const notifTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const failedImages = useRef<Set<string>>(new Set());
  const fetchedBagKeys = useRef<Set<string>>(new Set());
  const slotMoveTimeoutRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  /* ---- Animation class: showing when visible & not hiding ---- */
  useEffect(() => {
    if (visible && !hiding) {
      setMounted(true);
      // Force document focus so keydown events work immediately without clicking
      // This fixes the issue where players had to click before being able to close
      const focusDoc = (retries = 0) => {
        window.focus();
        document.body.focus();
        if (retries < 5 && document.activeElement !== document.body) {
          setTimeout(() => focusDoc(retries + 1), 50);
        }
      };
      setTimeout(() => focusDoc(), 30);
    }
    if (!visible) {
      setMounted(false);
    }
  }, [visible, hiding]);

  /* ---- NUI message handler ---- */
  useEffect(() => {
    const handleMessage = (event: MessageEvent) => {
      const { action, data, type } = event.data;
      const msgType = action || type;

      switch (msgType) {
        case 'newInventory:open':
          if (data?.playerSex) setPlayerSex(data.playerSex);
          if (data?.bagInfo) setBagInfo(data.bagInfo);
          if (data?.equippedBagId !== undefined) setEquippedBagId(data.equippedBagId);
          // demande un re-sync du métabolisme (sécurise le 1er ouverture)
          nuiCallback('metabolism:requestSync');
          if (data?.isFounder !== undefined) setIsFounder(!!data.isFounder);
          if (data?.isStaff !== undefined) setIsStaff(!!data.isStaff);
          break;

        case 'newInventory:close':
          setRightVisible(false);
          setRightTitle('');
          setLeftWeight(0);
          setLeftMaxWeight(0);
          setRightWeight(0);
          setRightMaxWeight(0);
          setSearchTerm('');
          setActiveFilter('all');
          setContextMenu(null);
          setRenameItem(null);
          setBagMode({ enabled: false });
          setBagPreviews({});
          fetchedBagKeys.current.clear();
          setOutfitAssemblerSlots({});
          setOutfitResultSlot(null);
          setPedOccluded(false);
          setSlotMovePending(false);
          if (slotMoveTimeoutRef.current) {
            clearTimeout(slotMoveTimeoutRef.current);
            slotMoveTimeoutRef.current = null;
          }
          break;

        case 'newInventory:setLeft':
          if (data?.inventory && Array.isArray(data.inventory)) {
            setLeftInventory(data.inventory);
            setSlotMovePending(false);
            if (slotMoveTimeoutRef.current) {
              clearTimeout(slotMoveTimeoutRef.current);
              slotMoveTimeoutRef.current = null;
            }
          }
          break;

        case 'newInventory:setRight':
          if (data && 'inventory' in data) setRightInventory(Array.isArray(data.inventory) ? data.inventory : []);
          break;

        case 'newInventory:setLeftWeight':
          if (data?.weight !== undefined) setLeftWeight(parseFloat(data.weight) || 0);
          break;
        case 'newInventory:setMaxLeftWeight':
          if (data?.weight !== undefined) setLeftMaxWeight(parseFloat(data.weight) || 0);
          break;
        case 'newInventory:setRightWeight':
          if (data?.weight !== undefined) setRightWeight(parseFloat(data.weight) || 0);
          break;
        case 'newInventory:setMaxRightWeight':
          if (data?.weight !== undefined) setRightMaxWeight(parseFloat(data.weight) || 0);
          break;

        case 'newInventory:setLeftTitle':
          if (data?.title !== undefined) setLeftTitle(data.title || 'Inventaire');
          break;
        case 'newInventory:setRightTitle':
          if (data?.title !== undefined) {
            setRightTitle(data.title || '');
            setRightVisible(!!data.title);
          }
          break;

        case 'newInventory:disableRight':
          setRightVisible(false);
          setRightTitle('');
          setRightWeight(0);
          setRightMaxWeight(0);
          break;

        case 'newInventory:setShortcut': {
          const { index, shortcut } = data || {};
          if (index !== undefined) {
            setShortcuts(prev => {
              const next = [...prev];
              next[index - 1] = shortcut?.name !== 'none' ? shortcut : null;
              return next;
            });
          }
          break;
        }

        case 'newInventory:setAccessory': {
          const { type: accType, item } = data || {};
          //console.log('[DEBUG UI setAccessory] accType:', accType, 'item:', item);
          if (accType) {
            const slotKey = getAccessorySlotKey(accType);
            //console.log('[DEBUG UI setAccessory] slotKey:', slotKey, 'item.name:', item?.name);
            setAccessories(prev => {
              const next = { ...prev, [slotKey]: item?.name !== 'none' ? item : null };
              //console.log('[DEBUG UI setAccessory] Updated accessories:', next);
              return next;
            });
          }
          break;
        }

        case 'newInventory:sendMessage':
          if (data?.message?.text) showNotification(data.message.text, data.time || 3000);
          break;

        /* ---- Hub messages ---- */
        case 'newInventory:setPlayerInfo':
          if (data?.name !== undefined) setPlayerName(data.name);
          if (data?.id !== undefined) setPlayerId(data.id);
          if (data?.uniqueId !== undefined) setPlayerUniqueId(data.uniqueId);
          if (data?.job !== undefined) setPlayerJob(data.job);
          if (data?.money !== undefined) setPlayerMoney(data.money);
          if (data?.dirtycash !== undefined) setPlayerDirtyMoney(data.dirtycash);
          if (data?.bank !== undefined) setPlayerBank(data.bank);
          break;

        case 'newInventory:setCraftRecipes':
          if (Array.isArray(data?.recipes)) setCraftRecipes(data.recipes);
          if (data?.tableId !== undefined) setCraftTableId(data.tableId);
          if (data?.tableBased !== undefined) setCraftTableBased(data.tableBased);
          break;

        case 'newInventory:setOutfitData':
          if (data) setOutfitData(data as OutfitHubData);
          break;

        case 'newInventory:outfitAssembleResult': {
          const outfitItem = data?.item as InventoryItem | undefined;
          if (outfitItem) {
            // Remove the outfit from leftInventory and place it in the result slot
            setLeftInventory(inv => inv.filter(i => String(i.name) !== String(outfitItem.name)));
            setOutfitResultSlot(outfitItem);
            setOutfitAssemblerSlots({});
          }
          break;
        }

        case 'newInventory:outfitDisassembleResult': {
          const slots = data?.slots as Record<string, InventoryItem> | undefined;
          if (slots) {
            // Remove the disassembled pieces from leftInventory and place them in assembler slots
            const slotNames = new Set(Object.values(slots).map(s => String(s.name)));
            setLeftInventory(inv => inv.filter(i => !slotNames.has(String(i.name))));
            setOutfitAssemblerSlots(slots);
            setOutfitResultSlot(null);
          }
          break;
        }

        case 'newInventory:setBackpackData':
          if (data) setBackpackData(data as BackpackData);
          break;

        case 'newInventory:setBagMode':
          if (data) {
            setBagMode({ enabled: !!data.enabled, clotheId: data.clotheId });
            if (data.enabled) setRightVisible(true);
          }
          break;

        case 'newInventory:setCraftProgress':
          if (data?.recipeId !== undefined) setCraftingId(data.recipeId);
          if (data?.progress !== undefined) setCraftProgress(data.progress);
          if (data?.done) { setCraftingId(null); setCraftProgress(0); }
          break;

        case 'newInventory:setSettings':
          if (Array.isArray(data?.settings)) setSettings(data.settings);
          break;

        case 'newInventory:setOptionsData':
          if (data) setOptionsData(data);
          break;

        case 'newInventory:setSocieties':
          if (Array.isArray(data?.societies)) setSocieties(data.societies);
          break;

        case 'newInventory:setKevlar':
          if (data?.equipped !== undefined) {
            setKevlarEquipped(!!data.equipped);
            setKevlarExtraId(data.equipped ? (data.extraIdentifier ?? null) : null);
          }
          break;

        case 'newInventory:updateKevlarDurability': {
          const { itemName, extraIdentifier, durability, maxDurability } = data || {};
          if (itemName) {
            setLeftInventory(prev => prev.map(it => {
              if (it.name !== itemName) return it;
              if (extraIdentifier != null && it.extra?.identifier != null && String(it.extra.identifier) !== String(extraIdentifier)) return it;
              return { ...it, metadata: { ...it.metadata, durability, maxDurability } };
            }));
          }
          break;
        }

        case 'newInventory:setLoading':
          if (data?.loading !== undefined) setIsLoading(data.loading);
          break;

        case 'newInventory:updatePreference':
          if (data?.id !== undefined && data?.enabled !== undefined) {
            setOptionsData(prev => {
              if (!prev) return prev;
              return {
                ...prev,
                preferences: prev.preferences.map(p =>
                  p.id === data.id ? { ...p, enabled: data.enabled } : p
                ),
              };
            });
          }
          break;

        case 'newInventory:updateBlip':
          if (data?.kvpName !== undefined && data?.enabled !== undefined) {
            setOptionsData(prev => {
              if (!prev) return prev;
              return {
                ...prev,
                blips: prev.blips.map(b =>
                  b.kvpName === data.kvpName ? { ...b, enabled: data.enabled } : b
                ),
              };
            });
          }
          break;

        case 'newInventory:updateWalkStyle':
          if (data?.name) {
            setOptionsData(prev => prev ? { ...prev, currentWalk: data.name } : prev);
          }
          break;

        case 'newInventory:pedVisibility':
          setPedOccluded(!data?.visible);
          break;

        case 'newInventory:setMetabolism':
          if (data) setMetabolismData(data as MetabolismData);
          break;
      }
    };

    window.addEventListener('message', handleMessage);
    return () => window.removeEventListener('message', handleMessage);
  }, []);

  /* ---- Notification ---- */
  const showNotification = useCallback((text: string, time: number) => {
    if (notifTimerRef.current) clearTimeout(notifTimerRef.current);
    setNotification({ text, time });
    notifTimerRef.current = setTimeout(() => setNotification(null), time);
  }, []);

  /* ---- Close handler ---- */
  const handleClose = useCallback(() => {
    if (hiding) return;

    // Clear outfit assembler - items go to main inventory
    setOutfitAssemblerSlots(prev => {
      const items = Object.values(prev).filter(Boolean) as InventoryItem[];
      if (items.length > 0) setLeftInventory(inv => [...inv, ...items]);
      return {};
    });
    if (outfitResultSlot) {
      setLeftInventory(inv => [...inv, outfitResultSlot]);
      setOutfitResultSlot(null);
    }

    setHiding(true);
    setMounted(false);
    setTimeout(() => nuiCallback('inventory:destroyPreviewPed'), 120);
    setTimeout(() => {
      setHiding(false);
      onClose();
      nuiCallback('newInventory:close');
    }, 350);
  }, [onClose, hiding, outfitResultSlot]);

  /* ---- Key handler ---- */
  useEffect(() => {
    const handleKey = (e: KeyboardEvent) => {
      if (renameItem) {
        if (e.key === 'Escape') { setRenameItem(null); setRenameValue(''); }
        return;
      }
      if (quantityDialog) {
        if (e.key === 'Escape') { setQuantityDialog(null); setQuantityValue('1'); }
        return;
      }
      if (e.key === 'Escape' && visible && !hiding) handleClose();
      if (e.key === 'Tab' && visible && !hiding) handleClose();
      // if (e.key === 'Tab' && visible) e.preventDefault();
    };
    window.addEventListener('keydown', handleKey);
    return () => window.removeEventListener('keydown', handleKey);
  }, [visible, hiding, handleClose, renameItem, quantityDialog]);

  /* ---- Item actions ---- */
  const handleUse = useCallback((item: InventoryItem) => { nuiCallback('newInventory:useItem', { item }); setContextMenu(null); }, []);
  const handleGive = useCallback((item: InventoryItem) => { nuiCallback('newInventory:giveItem', { item }); setContextMenu(null); }, []);
  const handleDrop = useCallback((item: InventoryItem) => {
    setContextMenu(null);
    if ((item.count || 1) > 1 && (item.type === 'item' || item.type === 'account')) {
      const count = item.count || 1;
      setQuantityDialog({ item, from: 'left', to: 'drop', max: count });
      setQuantityValue(count.toString());
      setTimeout(() => quantityInputRef.current?.select(), 50);
    } else {
      nuiCallback('newInventory:dropItem', { item, count: item.count || 1 });
    }
  }, []);
  const handleRename = useCallback((item: InventoryItem) => {
    setContextMenu(null);
    setRenameItem(item);
    setRenameValue(item.metadata?.title || item.label || '');
    setTimeout(() => renameInputRef.current?.focus(), 50);
  }, []);
  const submitRename = useCallback(() => {
    if (!renameItem || !renameValue.trim()) return;
    nuiCallback('newInventory:renameItem', { item: renameItem, newName: renameValue.trim() });
    setRenameItem(null);
    setRenameValue('');
  }, [renameItem, renameValue]);

  /* ---- Smart max computation: caps quantity by available weight in target ---- */
  const computeTransferMax = useCallback((item: InventoryItem, from: string, to: string, defaultQty?: number): { max: number; targetFreeKg?: number } => {
    // Money has no weight cost
    const itemWeight = item.weight ?? 0;
    const itemCount = defaultQty ?? (item.count || 1);
    const moneyLike = item.type === 'account' || item.type === ('cash' as any) || item.type === ('dirtycash' as any);
    if (moneyLike || itemWeight <= 0) {
      return { max: itemCount };
    }

    // Destinations without weight constraint
    if (to === 'drop' || to === 'allitems') {
      return { max: itemCount };
    }

    // Determine target free kg
    let targetFreeKg: number | undefined;
    if (to === 'left') {
      targetFreeKg = Math.max(0, leftMaxWeight - leftWeight);
    } else if (to === 'right') {
      if (rightMaxWeight > 0) targetFreeKg = Math.max(0, rightMaxWeight - rightWeight);
    } else if (to === 'backpack') {
      const bMax = backpackData?.maxWeight ?? 0;
      const bCur = backpackData?.weight ?? 0;
      if (bMax > 0) targetFreeKg = Math.max(0, bMax - bCur);
    }

    if (targetFreeKg === undefined) return { max: itemCount };
    const maxByWeight = Math.floor(targetFreeKg / itemWeight);
    return { max: Math.min(itemCount, Math.max(0, maxByWeight)), targetFreeKg };
  }, [leftWeight, leftMaxWeight, rightWeight, rightMaxWeight, backpackData]);

  /* ---- Quantity dialog handlers ---- */
  const openQuantityDialog = useCallback((item: InventoryItem, from: string, to: string, overrideDefault?: number) => {
    if (isBagItem(item)) {
      setQuantityDialog(null);
      setQuantityValue('1');
      return;
    }
    const itemCount = item.count || 1;
    const { max, targetFreeKg } = computeTransferMax(item, from, to);
    if (max <= 0) {
      // No space: show read-only "pas de place" dialog
      setQuantityDialog({ item, from, to, max: 0, targetFreeKg, noSpace: true });
      setQuantityValue('0');
      return;
    }
    const defaultQty = overrideDefault !== undefined ? overrideDefault : Math.min(itemCount, max);
    setQuantityDialog({ item, from, to, max, targetFreeKg });
    setQuantityValue(String(Math.max(1, Math.min(defaultQty, max))));
    setTimeout(() => quantityInputRef.current?.select(), 50);
  }, [computeTransferMax]);

  const submitQuantityTransfer = useCallback(() => {
    if (!quantityDialog || quantityDialog.noSpace) return;
    const qty = parseInt(quantityValue) || 0;
    const hardMax = Math.min(quantityDialog.item.count || 1, quantityDialog.max || (quantityDialog.item.count || 1));
    if (qty <= 0 || qty > hardMax) return;

    const { item, from, to } = quantityDialog;

    // Execute the transfer based on from/to
    if (from === 'backpack' && to === 'left') {
      if (item.type === 'weapon') {
        nuiCallback('newInventory:backpackRemoveWeapon', { weaponName: item.name });
      } else if (item.type === 'account' && (item.name === 'cash' || item.name === 'dirtycash')) {
        nuiCallback('newInventory:backpackTransferMoney', { moneyType: item.name, amount: qty, toBackpack: false });
      } else if (item.type === 'item' || item.type === 'accessory') {
        nuiCallback('newInventory:backpackRemoveItem', { itemName: item.name, count: qty, extra: item.extra });
      }
    } else if (from === 'left' && to === 'backpack') {
      if (item.type === 'weapon') {
        nuiCallback('newInventory:backpackAddWeapon', { weaponName: item.name });
      } else if (item.type === 'account' && (item.name === 'cash' || item.name === 'dirtycash')) {
        nuiCallback('newInventory:backpackTransferMoney', { moneyType: item.name, amount: qty, toBackpack: true });
      } else if (item.type === 'item' || item.type === 'accessory') {
        nuiCallback('newInventory:backpackAddItem', { itemName: item.name, count: qty, extra: item.extra });
      }
    } else if (bagMode.enabled && from === 'left' && to === 'right') {
      if (item.type === 'weapon') {
        nuiCallback('newInventory:backpackAddWeapon', { weaponName: item.name });
      } else if (item.type === 'account' && (item.name === 'cash' || item.name === 'dirtycash')) {
        nuiCallback('newInventory:backpackTransferMoney', { moneyType: item.name, amount: qty, toBackpack: true });
      } else if (item.type === 'item' || item.type === 'accessory') {
        nuiCallback('newInventory:backpackAddItem', { itemName: item.name, count: qty, extra: item.extra });
      }
    } else if (bagMode.enabled && from === 'right' && to === 'left') {
      if (item.type === 'weapon') {
        nuiCallback('newInventory:backpackRemoveWeapon', { weaponName: item.name });
      } else if (item.type === 'account' && (item.name === 'cash' || item.name === 'dirtycash')) {
        nuiCallback('newInventory:backpackTransferMoney', { moneyType: item.name, amount: qty, toBackpack: false });
      } else if (item.type === 'item' || item.type === 'accessory') {
        nuiCallback('newInventory:backpackRemoveItem', { itemName: item.name, count: qty, extra: item.extra });
      }
    } else if (from === 'allitems' && to === 'left') {
      nuiCallback('newInventory:allItemsTake', {
        itemName: item.name,
        itemType: item.type,
        count: qty,
      });
    } else if (from === 'left' && to === 'allitems') {
      nuiCallback('newInventory:allItemsDeposit', {
        itemName: item.name,
        itemType: item.type,
        count: qty,
      });
    } else if (to === 'drop') {
      nuiCallback('newInventory:dropItem', { item: { ...item, count: qty }, count: qty });
    } else if (to === 'right' || to === 'left') {
      nuiCallback('newInventory:changeSlot', { item: { ...item, count: qty }, target: to === 'right' ? 'inventoryRight' : 'inventoryLeft' });
    }

    setQuantityDialog(null);
    setQuantityValue('1');
  }, [quantityDialog, quantityValue, bagMode]);

  /* ---- Bag handlers ---- */
  const handleOpenBag = useCallback((item: InventoryItem) => {
    if (!isBagItem(item)) return;
    setContextMenu(null);
    nuiCallback('newInventory:openBagAsStorage', { clotheId: item.name, bagName: item.label || 'Sac' });
  }, []);

  const handleCloseBag = useCallback(() => {
    nuiCallback('newInventory:closeBagStorage');
    setBagMode({ enabled: false });
    setRightVisible(false);
  }, []);

  const fetchBagPreview = useCallback(async (item: InventoryItem) => {
    if (!isBagItem(item)) return;
    const key = String(item.name);
    if (fetchedBagKeys.current.has(key)) return;
    fetchedBagKeys.current.add(key);
    const resp = await nuiCallback('newInventory:backpackPreview', { clotheId: item.name });
    if (resp?.success && resp.preview) {
      setBagPreviews(prev => ({ ...prev, [key]: resp.preview }));
    }
  }, []);

  // Auto-fetch bag previews for all bag items when inventory loads
  useEffect(() => {
    leftInventory.filter(isBagItem).forEach(bag => fetchBagPreview(bag));
  }, [leftInventory, fetchBagPreview]);

  /* ---- Outfit assembler handlers ---- */
  const handleOutfitSlotDrop = useCallback((slotType: string, item: InventoryItem) => {
    if (item.type !== 'accessory' || item.type2 === 'outfit') return;
    if (item.type2 !== slotType) return;
    setOutfitAssemblerSlots(prev => {
      const existing = prev[slotType];
      if (existing) {
        setLeftInventory(inv => [...inv, existing]);
      }
      return { ...prev, [slotType]: item };
    });
    setLeftInventory(inv => inv.filter(i => i !== item));
  }, []);

  const handleOutfitResultDrop = useCallback((item: InventoryItem) => {
    if (item.type !== 'accessory' || item.type2 !== 'outfit') return;
    setOutfitResultSlot(prev => {
      if (prev) {
        setLeftInventory(inv => [...inv, prev]);
      }
      return item;
    });
    setLeftInventory(inv => inv.filter(i => i !== item));
  }, []);

  const handleOutfitSlotClear = useCallback((slotType: string) => {
    setOutfitAssemblerSlots(prev => {
      const item = prev[slotType];
      if (item) setLeftInventory(inv => [...inv, item]);
      const next = { ...prev };
      delete next[slotType];
      return next;
    });
  }, []);

  const handleOutfitResultClear = useCallback(() => {
    setOutfitResultSlot(prev => {
      if (prev) setLeftInventory(inv => [...inv, prev]);
      return null;
    });
  }, []);

  const clearOutfitAssembler = useCallback(() => {
    setOutfitAssemblerSlots(prev => {
      const items = Object.values(prev).filter(Boolean) as InventoryItem[];
      if (items.length > 0) setLeftInventory(inv => [...inv, ...items]);
      return {};
    });
    setOutfitResultSlot(prev => {
      if (prev) setLeftInventory(inv => [...inv, prev]);
      return null;
    });
  }, []);

  const handleOutfitAssemble = useCallback(() => {
    const pieces: Record<string, number> = {};
    for (const [type, item] of Object.entries(outfitAssemblerSlots)) {
      if (item) pieces[type] = typeof item.name === 'number' ? item.name : parseInt(item.name) || 0;
    }
    if (Object.keys(pieces).length < 2) return;
    nuiCallback('newInventory:outfitCreate', { pieces });
    setOutfitAssemblerSlots({});
  }, [outfitAssemblerSlots]);

  const handleOutfitDisassemble = useCallback(() => {
    if (!outfitResultSlot) return;
    const outfitId = outfitResultSlot.name;
    nuiCallback('newInventory:outfitDisassemble', { outfitId });
    setOutfitResultSlot(null);
  }, [outfitResultSlot]);

  /* ---- Drag handlers ---- */
  const handleMouseDown = useCallback((e: React.MouseEvent, item: InventoryItem, source: string) => {
    if (slotMovePending) return;
    if (e.button === 2) return;
    e.preventDefault();
    setDragItem(item);
    setDragSource(source);
    setDragPos({ x: e.clientX, y: e.clientY });
    setIsDragging(true);
    setContextMenu(null);
    soundManager.play('pickup');
  }, [slotMovePending]);

  useEffect(() => {
    if (!isDragging) return;
    const handleMouseMove = (e: MouseEvent) => setDragPos({ x: e.clientX, y: e.clientY });
    const handleMouseUp = () => {
      if (dragItem && dropTarget && dropTarget !== dragSource) {
        handleDropAction(dragItem, dragSource!, dropTarget);
        soundManager.play('drop');
      }
      setIsDragging(false);
      setDragItem(null);
      setDragSource(null);
      setDropTarget(null);
    };
    window.addEventListener('mousemove', handleMouseMove);
    window.addEventListener('mouseup', handleMouseUp);
    return () => {
      window.removeEventListener('mousemove', handleMouseMove);
      window.removeEventListener('mouseup', handleMouseUp);
    };
  }, [isDragging, dragItem, dragSource, dropTarget]);

  const handleDropAction = useCallback((item: InventoryItem, from: string, to: string) => {
    if (slotMovePending) return;

    // Action buttons
    if (to.startsWith('action-')) {
      const action = to.replace('action-', '');
      if (action === 'use') {
        handleUse(item);
      } else if (action === 'rename') {
        handleRename(item);
      } else if (action === 'give') {
        handleGive(item);
      } else if (action === 'drop') {
        handleDrop(item);
      }
      return;
    }

    const fromInventorySlot = parseInventorySlotRef(from);
    const toInventorySlot = parseInventorySlotRef(to);

    if (
      fromInventorySlot &&
      toInventorySlot &&
      fromInventorySlot.container === toInventorySlot.container &&
      fromInventorySlot.slot !== toInventorySlot.slot
    ) {
      if (fromInventorySlot.container === 'left') {
        const oldSlot = Number(item.slot) || fromInventorySlot.slot;
        const movedSlotKey = getInventoryItemSlotKey(item);
        setSlotMovePending(true);
        if (slotMoveTimeoutRef.current) clearTimeout(slotMoveTimeoutRef.current);
        slotMoveTimeoutRef.current = setTimeout(() => {
          setSlotMovePending(false);
          slotMoveTimeoutRef.current = null;
        }, 2500);

        setLeftInventory(prev => prev.map(invItem => {
          const isDraggedItem =
            invItem === item ||
            getInventoryItemSlotKey(invItem) === movedSlotKey ||
            (invItem.id != null && item.id != null && invItem.id === item.id && invItem.type === item.type && invItem.name === item.name);

          if (isDraggedItem) return { ...invItem, slot: toInventorySlot.slot };
          if ((Number(invItem.slot) || 0) === toInventorySlot.slot) return { ...invItem, slot: oldSlot };
          return invItem;
        }));
        nuiCallback('newInventory:moveSlot', {
          item,
          slotKey: movedSlotKey,
          inventory: 'left',
          fromSlot: fromInventorySlot.slot,
          toSlot: toInventorySlot.slot,
        });
      }
      return;
    }

    if (fromInventorySlot) from = fromInventorySlot.container;
    if (toInventorySlot) to = toInventorySlot.container;

    // Drag FROM outfit-slot → left: return clothing to inventory
    if (from.startsWith('outfit-slot-') && to === 'left') {
      const slotType = from.replace('outfit-slot-', '');
      handleOutfitSlotClear(slotType);
      return;
    }
    // Drag FROM outfit-result → left: return outfit to inventory
    if (from === 'outfit-result' && to === 'left') {
      handleOutfitResultClear();
      return;
    }

    // Outfit assembler slots: drop INTO slot
    if (to.startsWith('outfit-slot-')) {
      const slotType = to.replace('outfit-slot-', '');
      // If dragging from another outfit slot, move between slots
      if (from.startsWith('outfit-slot-')) {
        const fromSlot = from.replace('outfit-slot-', '');
        if (fromSlot === slotType) return;
        // Can only move if the item type matches the target slot
        if (item.type2 !== slotType) return;
        setOutfitAssemblerSlots(prev => {
          const next = { ...prev };
          delete next[fromSlot];
          const existing = next[slotType];
          if (existing) setLeftInventory(inv => [...inv, existing]);
          next[slotType] = item;
          return next;
        });
      } else {
        handleOutfitSlotDrop(slotType, item);
      }
      return;
    }
    // Drop INTO outfit-result
    if (to === 'outfit-result') {
      handleOutfitResultDrop(item);
      return;
    }

    if (to.startsWith('shortcut-') && item.type === 'weapon') {
      nuiCallback('newInventory:shortcutSet', { item, slot: parseInt(to.split('-')[1]) });
      return;
    }
    if (to === 'equip-gillet' && item.type === 'item' && KEVLAR_ITEM_NAMES.has(item.name)) {
      nuiCallback('newInventory:useItem', { item, count: 1 });
      return;
    }
    if (to.startsWith('equip-') && item.type === 'accessory') {
      const slotKey = to.replace('equip-', '');
      const slotDataKey = getAccessoryDataKey(slotKey);
      const itemDataKey = normalizeToDataKey(item.type2 || '');
      const itemSlotKey = getAccessorySlotKey(itemDataKey);
      if (itemSlotKey === slotKey || itemDataKey === slotDataKey) {
        nuiCallback('newInventory:equipAccessory', { item, type: item.type2 || itemSlotKey });
      }
      return;
    }
    if (to === 'character') {
      if (item.type === 'accessory') {
        if (item.type2 === 'outfit') {
          nuiCallback('newInventory:useItem', { item, count: 1 });
        } else {
          nuiCallback('newInventory:equipAccessory', { item, type: item.type2 || '' });
        }
      } else {
        nuiCallback('newInventory:changeSlot', { item });
      }
      return;
    }
    // Drag FROM equip → left/right: remove accessory (or kevlar unequip for gillet slot)
    if (from.startsWith('equip-') && (to === 'left' || to === 'right') && item.type === 'accessory') {
      if (from === 'equip-gillet' && kevlarEquipped) {
        nuiCallback('newInventory:kevlarUnequip');
      } else {
        nuiCallback('newInventory:removeAccessory', { type: item.type2 || '', item: null });
      }
    }
    // Drag FROM shortcut → left: remove shortcut
    if (from.startsWith('shortcut-') && to === 'left') {
      const slot = parseInt(from.split('-')[1]);
      nuiCallback('newInventory:shortcutRemove', { slot });
      return;
    }

    // Admin: drag from allitems → left = spawn item to player inventory
    if (from === 'allitems' && to === 'left') {
      if (item.type === 'weapon') {
        nuiCallback('newInventory:allItemsTake', { itemName: item.name, itemType: 'weapon', count: 1 });
      } else {
        // Use smart max so we never exceed player weight capacity
        openQuantityDialog(item, from, to, item.type === 'account' ? 1000 : 1);
      }
      return;
    }
    // Admin: drag from left → allitems = destroy item
    if (from === 'left' && to === 'allitems') {
      if (item.type === 'weapon') {
        nuiCallback('newInventory:allItemsDeposit', { itemName: item.name, itemType: 'weapon', count: 1 });
      } else if ((item.count || 1) > 1) {
        openQuantityDialog(item, from, to);
      } else {
        nuiCallback('newInventory:allItemsDeposit', { itemName: item.name, itemType: item.type, count: item.count || 1 });
      }
      return;
    }

    // HubPanel Backpack tab: drag from backpack → left = remove from bag
    if (from === 'backpack' && to === 'left') {
      if (item.type === 'weapon') {
        nuiCallback('newInventory:backpackRemoveWeapon', { weaponName: item.name });
      } else if ((item.count || 1) > 1) {
        // Open quantity dialog for stackable items
        openQuantityDialog(item, from, to);
      } else {
        // Direct transfer for single items
        if (item.type === 'account' && (item.name === 'cash' || item.name === 'dirtycash')) {
          nuiCallback('newInventory:backpackTransferMoney', { moneyType: item.name, amount: item.count, toBackpack: false });
        } else if (item.type === 'item' || item.type === 'accessory') {
          nuiCallback('newInventory:backpackRemoveItem', { itemName: item.name, count: item.count, extra: item.extra });
        }
      }
      return;
    }

    // HubPanel Backpack tab: drag from left → backpack = add to bag
    if (from === 'left' && to === 'backpack') {
      // Block bag in bag
      if (isBagItem(item)) return;

      if (item.type === 'weapon') {
        nuiCallback('newInventory:backpackAddWeapon', { weaponName: item.name });
      } else if ((item.count || 1) > 1) {
        // Open quantity dialog for stackable items
        openQuantityDialog(item, from, to);
      } else {
        // Direct transfer for single items
        if (item.type === 'account' && (item.name === 'cash' || item.name === 'dirtycash')) {
          nuiCallback('newInventory:backpackTransferMoney', { moneyType: item.name, amount: item.count, toBackpack: true });
        } else if (item.type === 'item' || item.type === 'accessory') {
          nuiCallback('newInventory:backpackAddItem', { itemName: item.name, count: item.count, extra: item.extra });
        }
      }
      return;
    }

    // Bag mode: drop from left → right = add to bag, right → left = remove from bag
    if (bagMode.enabled && bagMode.clotheId) {
      // Block bag in bag
      if (isBagItem(item) && to === 'right') return;

      if (from === 'left' && to === 'right') {
        if (item.type === 'weapon') {
          nuiCallback('newInventory:backpackAddWeapon', { weaponName: item.name });
        } else if ((item.count || 1) > 1) {
          openQuantityDialog(item, from, to);
        } else {
          if (item.type === 'account' && (item.name === 'cash' || item.name === 'dirtycash')) {
            nuiCallback('newInventory:backpackTransferMoney', { moneyType: item.name, amount: item.count, toBackpack: true });
          } else if (item.type === 'item' || item.type === 'accessory') {
            nuiCallback('newInventory:backpackAddItem', { itemName: item.name, count: item.count, extra: item.extra });
          }
        }
        return;
      }
      if (from === 'right' && to === 'left') {
        if (item.type === 'weapon') {
          nuiCallback('newInventory:backpackRemoveWeapon', { weaponName: item.name });
        } else if ((item.count || 1) > 1) {
          openQuantityDialog(item, from, to);
        } else {
          if (item.type === 'account' && (item.name === 'cash' || item.name === 'dirtycash')) {
            nuiCallback('newInventory:backpackTransferMoney', { moneyType: item.name, amount: item.count, toBackpack: false });
          } else if (item.type === 'item' || item.type === 'accessory') {
            nuiCallback('newInventory:backpackRemoveItem', { itemName: item.name, count: item.count, extra: item.extra });
          }
        }
        return;
      }
    }

    if (to === 'right' || to === 'left') {
      if ((item.count || 1) > 1 && (item.type === 'item' || item.type === 'account')) {
        openQuantityDialog(item, from, to);
      } else {
        nuiCallback('newInventory:changeSlot', { item, target: to === 'right' ? 'inventoryRight' : 'inventoryLeft' });
      }
    }
  }, [bagMode, openQuantityDialog]);

  /* ---- Context menu ---- */
  const handleContextMenu = useCallback((e: React.MouseEvent, item: InventoryItem) => {
    e.preventDefault();
    e.stopPropagation();
    setContextMenu({ item, x: e.clientX, y: e.clientY });
  }, []);

  useEffect(() => {
    if (!contextMenu) return;
    const handler = () => setContextMenu(null);
    window.addEventListener('click', handler);
    return () => window.removeEventListener('click', handler);
  }, [contextMenu]);

  /* ---- Settings handler ---- */
  const handleSettingChange = useCallback((id: string, value: any) => {
    setSettings(prev => prev.map(s => s.id === id ? { ...s, value } : s));
    nuiCallback('newInventory:settingChange', { id, value });
  }, []);

  /* ---- Render guard ---- */
  if (!visible && !hiding) return null;

  /* ---- Compute overlay class ---- */
  const overlayClass = hiding
    ? 'ni-hiding'
    : mounted
      ? 'ni-showing ni-visible'
      : '';

  return (
    <div
      className={`ni-overlay ${overlayClass} ni-has-hub ${rightVisible ? 'ni-chest-open' : ''}`}
      style={niAccentVars as React.CSSProperties}
    >
      {/* Left Panel — Player inventory */}
      <LeftPanel
        inventory={leftInventory}
        title={leftTitle}
        weight={leftWeight}
        maxWeight={leftMaxWeight}
        searchTerm={searchTerm}
        activeFilter={activeFilter}
        playerSex={playerSex}
        failedImages={failedImages}
        isDragging={isDragging}
        dragItem={dragItem}
        dragSource={dragSource}
        dropTarget={dropTarget}
        bagInfo={bagInfo}
        bagPreviews={bagPreviews}
        equippedBagId={equippedBagId}
        onSearchChange={setSearchTerm}
        onFilterChange={setActiveFilter}
        onMouseDown={handleMouseDown}
        onContextMenu={handleContextMenu}
        onDropTargetChange={setDropTarget}
        onOpenBag={handleOpenBag}
        onFetchBagPreview={fetchBagPreview}
        hideWeight={hideWeight}
        serverIcon={serverIcon}
        serverName={serverName}
      />

      {/* Center Panel — Equipment + shortcuts */}
      <CenterPanel
        accessories={accessories}
        shortcuts={shortcuts}
        playerSex={playerSex}
        failedImages={failedImages}
        isDragging={isDragging}
        dragItem={dragItem}
        dropTarget={dropTarget}
        pedOccluded={pedOccluded}
        onMouseDown={handleMouseDown}
        onDropTargetChange={setDropTarget}
      />

      {/* Right-side Panel — always HubPanel; chest opens as a tab */}
      <HubPanel
        serverIcon={serverIcon}
        serverName={serverName}
        playerName={playerName}
        playerId={playerId}
        playerUniqueId={playerUniqueId}
        playerJob={playerJob}
        playerMoney={playerMoney}
        playerDirtyMoney={playerDirtyMoney}
        playerBank={playerBank}
        craftRecipes={craftRecipes}
        craftingId={craftingId}
        craftProgress={craftProgress}
        craftTableId={craftTableId}
        craftTableBased={craftTableBased}
        settings={settings}
        onSettingChange={handleSettingChange}
        optionsData={optionsData}
        societies={societies}
        outfitData={outfitData}
        backpackData={backpackData}
        leftInventory={leftInventory}
        playerSex={playerSex}
        failedImages={failedImages}
        isDragging={isDragging}
        dragItem={dragItem}
        dragSource={dragSource}
        dropTarget={dropTarget}
        onDropTargetChange={setDropTarget}
        onMouseDown={handleMouseDown}
        onContextMenu={handleContextMenu}
        isFounder={isFounder}
        onOutfitSlotDrop={handleOutfitSlotDrop}
        onOutfitResultDrop={handleOutfitResultDrop}
        outfitAssemblerSlots={outfitAssemblerSlots}
        outfitResultSlot={outfitResultSlot}
        onOutfitSlotClear={handleOutfitSlotClear}
        onOutfitResultClear={handleOutfitResultClear}
        onOutfitAssemble={handleOutfitAssemble}
        onOutfitDisassemble={handleOutfitDisassemble}
        hideWeight={hideWeight}
        onHideWeightChange={setHideWeight}
        chestVisible={rightVisible}
        chestInventory={rightInventory}
        chestTitle={rightTitle}
        chestWeight={rightWeight}
        chestMaxWeight={rightMaxWeight}
        bagMode={bagMode.enabled}
        onCloseBag={handleCloseBag}
        metabolismData={metabolismData}
      />

      {/* Drag Ghost */}
      {isDragging && dragItem && (
        <div className="ni-drag-ghost" style={{ left: dragPos.x, top: dragPos.y }}>
          <img
            src={getItemImageSrc(dragItem, playerSex, failedImages.current)}
            alt={dragItem.label}
            onError={(e) => handleImgError(e, dragItem, failedImages.current)}
            draggable={false}
          />
        </div>
      )}

      {/* Context Menu */}
      {contextMenu && (
        <ContextMenu
          item={contextMenu.item}
          x={contextMenu.x}
          y={contextMenu.y}
          playerSex={playerSex}
          failedImages={failedImages}
          onUse={handleUse}
          onGive={handleGive}
          onDrop={handleDrop}
          onRename={handleRename}
          onOpenBag={handleOpenBag}
          kevlarExtraId={kevlarExtraId}
          onKevlarUnequip={() => { nuiCallback('newInventory:kevlarUnequip'); setContextMenu(null); }}
        />
      )}

      {/* Rename Modal */}
      {renameItem && (
        <div className="ni-rename-overlay" onClick={() => { setRenameItem(null); setRenameValue(''); }}>
          <div className="ni-rename-modal" onClick={(e) => e.stopPropagation()}>
            <div className="ni-rename-title">Renommer</div>
            <div className="ni-rename-subtitle">{renameItem.label || renameItem.name}</div>
            <input
              ref={renameInputRef}
              className="ni-rename-input"
              type="text"
              value={renameValue}
              onChange={(e) => setRenameValue(e.target.value)}
              onKeyDown={(e) => { if (e.key === 'Enter') submitRename(); }}
              placeholder="Nouveau nom..."
              maxLength={40}
            />
            <div className="ni-rename-actions">
              <button className="ni-rename-cancel" onClick={() => { setRenameItem(null); setRenameValue(''); }}>Annuler</button>
              <button className="ni-rename-confirm" onClick={submitRename}><Check size={13} /> Confirmer</button>
            </div>
          </div>
        </div>
      )}

      {/* Quantity Dialog */}
      {quantityDialog && (() => {
        const q = quantityDialog;
        const itemWeight = q.item.weight ?? 0;
        const hardMax = Math.min(q.item.count || 1, q.max || (q.item.count || 1));
        const qty = parseInt(quantityValue) || 0;
        const qtyKg = itemWeight > 0 ? qty * itemWeight : 0;
        const close = () => { setQuantityDialog(null); setQuantityValue('1'); };
        return (
          <div className="ni-rename-overlay" onClick={close}>
            <div className="ni-rename-modal" onClick={(e) => e.stopPropagation()}>
              <div className="ni-rename-title">{q.noSpace ? 'Pas de place disponible' : 'Quantité'}</div>
              <div className="ni-rename-subtitle">{q.item.label || q.item.name}</div>

              {q.noSpace ? (
                <>
                  <div className="ni-quantity-nospace">
                    <div>Poids de l'item : <b>{itemWeight.toFixed(1)} kg</b></div>
                    <div>Place libre : <b>{(q.targetFreeKg ?? 0).toFixed(1)} kg</b></div>
                    <div className="ni-quantity-nospace-msg">Impossible de transférer cet item : destination pleine.</div>
                  </div>
                  <div className="ni-rename-actions">
                    <button className="ni-rename-cancel" onClick={close}>Fermer</button>
                  </div>
                </>
              ) : (
                <>
                  <input
                    ref={quantityInputRef}
                    className="ni-rename-input"
                    type="number"
                    min="1"
                    max={hardMax}
                    value={quantityValue}
                    onChange={(e) => setQuantityValue(e.target.value)}
                    onKeyDown={(e) => { if (e.key === 'Enter') submitQuantityTransfer(); }}
                    placeholder="Quantité..."
                  />
                  <div className="ni-quantity-info">
                    <div className="ni-quantity-info-row">
                      <span>Max</span>
                      <b>{hardMax}{q.max < (q.item.count || 1) && q.targetFreeKg !== undefined ? ` (place: ${q.targetFreeKg.toFixed(1)} kg)` : ''}</b>
                    </div>
                    {itemWeight > 0 && (
                      <div className="ni-quantity-info-row">
                        <span>Poids</span>
                        <b>{qtyKg.toFixed(1)} kg <span style={{ opacity: 0.5 }}>({itemWeight.toFixed(1)} kg / u.)</span></b>
                      </div>
                    )}
                  </div>
                  <div className="ni-rename-actions">
                    <button className="ni-rename-cancel" onClick={close}>Annuler</button>
                    <button className="ni-rename-confirm" onClick={submitQuantityTransfer} disabled={qty <= 0 || qty > hardMax}>
                      <Check size={13} /> Confirmer
                    </button>
                  </div>
                </>
              )}
            </div>
          </div>
        );
      })()}

      {/* Notification */}
      {notification && (
        <div className="ni-notification">{notification.text}</div>
      )}

      {/* Loading Overlay */}
      {isLoading && (
        <div className="ni-loading-overlay">
          <div className="ni-loading-spinner"></div>
        </div>
      )}
    </div>
  );
};

export default Inventory;
