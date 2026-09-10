import React, { useState, useEffect, useCallback, useMemo, useRef, memo } from 'react';
import { generateAccentVars } from '@/utils/accentColors';
import {
  Camera, Car, Shirt, Crosshair, Users, Box, Settings, Play, Square,
  RefreshCw, CheckCircle, XCircle, Clock, Search, Image, RotateCcw,
  Eye, Loader2, CheckSquare, ChevronRight, X, Sliders, Move, Trash2, Scissors
} from 'lucide-react';
import {
  TabType, CaptureType, ImageMakerConfig, ExistingImages, GameScanData,
  CaptureQueueItem, CaptureSettings, ItemEntry, CaptureProgress
} from './types';
import './ImageMaker.css';
import { cacheImg, useCacheVersion } from '@shared/cacheVersion';

const GetParentResourceName = () => 'null-core';

const TABS: { key: TabType; label: string; icon: React.ReactNode }[] = [
  { key: 'vehicles', label: 'Véhicules', icon: <Car size={16} /> },
  { key: 'clothing', label: 'Vêtements', icon: <Shirt size={16} /> },
  { key: 'weapons', label: 'Armes', icon: <Crosshair size={16} /> },
  { key: 'peds', label: 'Peds', icon: <Users size={16} /> },
  { key: 'props', label: 'Props', icon: <Box size={16} /> },
  { key: 'utils', label: 'Utils', icon: <Scissors size={16} /> },
  { key: 'custom', label: 'Personnalisé', icon: <Move size={16} /> },
];

const ITEMS_PER_CHUNK = 60;

interface GridCardProps {
  item: ItemEntry;
  isSelected: boolean;
  justCaptured: boolean;
  imgUrl: string | null;
  onToggle: (id: string) => void;
  onPreview: (url: string | null) => void;
  onRetake: (id: string) => void;
}

const GridCard = memo<GridCardProps>(({ item, isSelected, justCaptured, imgUrl, onToggle, onPreview, onRetake }) => (
  <div
    className={`imgm-card ${isSelected ? 'selected' : ''} ${item.hasImage ? 'has-image' : 'no-image'} ${justCaptured ? 'just-captured' : ''}`}
    onClick={() => onToggle(item.id)}
  >
    <div className="imgm-card-img">
      {imgUrl ? (
        <img src={imgUrl} alt={item.label} loading="lazy" onError={(e) => { (e.target as HTMLImageElement).style.display = 'none'; }} />
      ) : (
        <div className="imgm-card-placeholder"><Camera size={20} /></div>
      )}
      <div className={`imgm-card-badge ${item.hasImage ? 'imgm-badge-ok' : 'imgm-badge-miss'}`}>
        {item.hasImage ? <CheckCircle size={10} /> : <XCircle size={10} />}
      </div>
      {isSelected && (
        <div className="imgm-card-check"><CheckSquare size={16} /></div>
      )}
    </div>
    <div className="imgm-card-label" title={item.id}>{item.label}</div>
    {item.hasImage && (
      <div className="imgm-card-actions">
        <button className="imgm-card-action" title="Voir" onClick={(e) => { e.stopPropagation(); onPreview(imgUrl); }}>
          <Eye size={11} />
        </button>
        <button className="imgm-card-action imgm-action-retake" title="Reprendre" onClick={(e) => { e.stopPropagation(); onRetake(item.id); }}>
          <RotateCcw size={11} />
        </button>
      </div>
    )}
  </div>
));

interface ImageMakerProps {
  visible: boolean;
  serverColor?: string;
}

const ImageMaker: React.FC<ImageMakerProps> = ({ visible, serverColor }) => {
  const [hiding, setHiding] = useState(false);
  const [activeTab, setActiveTab] = useState<TabType>('vehicles');
  const [config, setConfig] = useState<ImageMakerConfig | null>(null);
  const [existingImages, setExistingImages] = useState<ExistingImages | null>(null);
  const [gameScanData, setGameScanData] = useState<{ male: GameScanData | null; female: GameScanData | null }>({ male: null, female: null });
  const [loading, setLoading] = useState(true);
  const [scanning, setScanning] = useState(false);

  // Clothing sub-state
  const [clothingGender, setClothingGender] = useState<'male' | 'female'>('male');
  const [clothingCategory, setClothingCategory] = useState<string>('torso_1');

  // Utils sub-state
  const [utilsGender, setUtilsGender] = useState<'male' | 'female'>('male');
  const [utilsType, setUtilsType] = useState<string>('hair');

  // Selection
  const [selected, setSelected] = useState<Set<string>>(new Set());
  const [searchQuery, setSearchQuery] = useState('');
  const [filterMode, setFilterMode] = useState<'all' | 'missing' | 'existing'>('all');

  // Capture state
  const [isCapturing, setIsCapturing] = useState(false);
  const [progress, setProgress] = useState<CaptureProgress | null>(null);
  const [capturedThisSession, setCapturedThisSession] = useState<Set<string>>(new Set());

  // Settings
  const [showSettings, setShowSettings] = useState(false);
  const [settings, setSettings] = useState<CaptureSettings>({
    delay: 500,
    greenRemoval: true,
  });

  // Preview
  const [previewImage, setPreviewImage] = useState<string | null>(null);

  // Props input
  const [propInput, setPropInput] = useState('');
  const [propList, setPropList] = useState<string[]>([]);

  // Custom capture state
  const [customEntityType, setCustomEntityType] = useState<string>('vehicle');
  const [customModel, setCustomModel] = useState('');
  const [customGender, setCustomGender] = useState<'male' | 'female'>('male');
  const [customClothingCat, setCustomClothingCat] = useState<string>('torso_1');
  const [customDrawableId, setCustomDrawableId] = useState(0);
  const [customSpawned, setCustomSpawned] = useState(false);
  const [customSpawning, setCustomSpawning] = useState(false);
  const [customCapturing, setCustomCapturing] = useState(false);
  const [customStatus, setCustomStatus] = useState<{ text: string; success?: boolean } | null>(null);
  const [customSaveName, setCustomSaveName] = useState('');
  const [customSaveType, setCustomSaveType] = useState<string>('vehicle');
  const [camDist, setCamDist] = useState(5.0);
  const [camAngleH, setCamAngleH] = useState(30.0);
  const [camAngleV, setCamAngleV] = useState(10.0);
  const [camFov, setCamFov] = useState(40.0);
  const [camOffsetZ, setCamOffsetZ] = useState(0.0);
  const [entityRotZ, setEntityRotZ] = useState(0.0);

  const accentColor = serverColor || '#8b5cf6';
  const imgmAccentVars = useMemo(() => generateAccentVars('--imgm-accent', accentColor), [accentColor]);

  const cacheVer = useCacheVersion();

  // Progressive loading
  const [visibleCount, setVisibleCount] = useState(ITEMS_PER_CHUNK);
  const gridContainerRef = useRef<HTMLDivElement>(null);

  // ========================================================================
  // INIT & NUI MESSAGE HANDLER
  // ========================================================================

  useEffect(() => {
    const handler = (e: MessageEvent) => {
      const { action, data } = e.data || {};
      if (action === 'imagemaker:scanResult' && data) {
        setExistingImages(data);
        setScanning(false);
      }
      if (action === 'imagemaker:captureProgress') {
        setProgress(e.data as CaptureProgress);
        if (e.data.success && e.data.filename) {
          setCapturedThisSession(prev => new Set(prev).add(e.data.filename));
          
          // Update existingImages immediately for clothing to show image in real-time
          if (e.data.captureType === 'clothing' && e.data.filename) {
            const parts = e.data.filename.split('/');
            if (parts.length === 3) {
              const [gender, category, idWithExt] = parts;
              const id = idWithExt.replace('.webp', '');
              setExistingImages(prev => {
                if (!prev) return prev;
                const newClothing = { ...prev.clothing };
                if (!newClothing[gender]) newClothing[gender] = {};
                if (!newClothing[gender][category]) newClothing[gender][category] = [];
                if (!newClothing[gender][category].includes(id)) {
                  newClothing[gender][category] = [...newClothing[gender][category], id];
                }
                return { ...prev, clothing: newClothing };
              });
            }
          }
        }
      }
      if (action === 'imagemaker:captureComplete') {
        setIsCapturing(false);
        setProgress(null);
        triggerScanImages();
      }
      if (action === 'imagemaker:deleteResult') {
        if (e.data.success) {
          triggerScanImages();
        }
      }
    };
    window.addEventListener('message', handler);
    return () => window.removeEventListener('message', handler);
  }, []);

  useEffect(() => {
    if (visible && !config) {
      fetchConfig();
    }
    if (visible) {
      triggerScanImages();
      setSelected(new Set());
      setCapturedThisSession(new Set());
    }
  }, [visible]);

  const fetchConfig = () => {
    setLoading(true);
    fetch(`https://${GetParentResourceName()}/imagemaker:getConfig`, { method: 'POST' })
      .then(r => r.json())
      .then(cfg => {
        setConfig(cfg);
        setLoading(false);
      })
      .catch(() => setLoading(false));
  };

  const triggerScanImages = () => {
    fetch(`https://${GetParentResourceName()}/imagemaker:scanImages`, { method: 'POST' }).catch(() => {});
  };

  const scanGameData = (gender: 'male' | 'female') => {
    if (gameScanData[gender]) return;
    setScanning(true);
    fetch(`https://${GetParentResourceName()}/imagemaker:scanGameData`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ gender }),
    })
      .then(r => r.json())
      .then(data => {
        setGameScanData(prev => ({ ...prev, [gender]: data }));
        setScanning(false);
      })
      .catch(() => setScanning(false));
  };

  useEffect(() => {
    if (visible && config && activeTab === 'clothing') {
      scanGameData(clothingGender);
    }
    if (visible && config && activeTab === 'utils') {
      scanGameData(utilsGender);
    }
    if (visible && config && activeTab === 'vehicles' && !gameScanData.male) {
      scanGameData('male');
    }
  }, [visible, config, activeTab, clothingGender, utilsGender]);

  // ========================================================================
  // BUILD ITEM LISTS
  // ========================================================================

  const vehicleItems = useMemo((): ItemEntry[] => {
    const scan = gameScanData.male;
    if (!scan) return [];
    return scan.vehicles.map(model => ({
      id: model,
      label: model,
      hasImage: existingImages?.vehicles?.includes(model) || false,
      type: 'vehicle' as CaptureType,
      meta: { model },
    }));
  }, [gameScanData.male, existingImages]);

  const clothingItems = useMemo((): ItemEntry[] => {
    const scan = gameScanData[clothingGender];
    if (!scan || !scan.clothing) return [];
    const count = scan.clothing[clothingCategory] || 0;
    const existingCat = existingImages?.clothing?.[clothingGender]?.[clothingCategory] || [];
    const items: ItemEntry[] = [];

    const cat = config?.clothingCategories?.find(c => c.id === clothingCategory);
    if (!cat) return [];

    for (let i = 0; i < count; i++) {
      items.push({
        id: `${clothingGender}/${clothingCategory}/${i}`,
        label: `${cat.label} #${i}`,
        hasImage: existingCat.includes(String(i)),
        type: 'clothing' as CaptureType,
        meta: {
          gender: clothingGender,
          categoryId: clothingCategory,
          componentType: cat.type,
          componentId: cat.component,
          drawableId: i,
        },
      });
    }
    return items;
  }, [gameScanData, clothingGender, clothingCategory, existingImages, config]);

  const weaponItems = useMemo((): ItemEntry[] => {
    if (!config) return [];
    return config.weaponList.map(name => ({
      id: name,
      label: name.replace('WEAPON_', ''),
      hasImage: existingImages?.weapons?.includes(name) || existingImages?.weapons?.includes(name.toLowerCase()) || false,
      type: 'weapon' as CaptureType,
      meta: { weaponName: name },
    }));
  }, [config, existingImages]);

  const pedItems = useMemo((): ItemEntry[] => {
    if (!config) return [];
    return config.pedList.map(name => ({
      id: name,
      label: name,
      hasImage: existingImages?.peds?.includes(name) || false,
      type: 'ped' as CaptureType,
      meta: { model: name },
    }));
  }, [config, existingImages]);

  const propItems = useMemo((): ItemEntry[] => {
    return propList.map(name => ({
      id: name,
      label: name,
      hasImage: existingImages?.props?.includes(name) || false,
      type: 'prop' as CaptureType,
      meta: { model: name },
    }));
  }, [propList, existingImages]);

  const utilsItems = useMemo((): ItemEntry[] => {
    const scan = gameScanData[utilsGender];
    if (!scan || !scan.utils) return [];
    const existingCat = existingImages?.utils?.[utilsGender]?.[utilsType] || [];
    const items: ItemEntry[] = [];

    const cat = config?.utilsCategories?.find(c => c.id === utilsType);
    if (!cat) return [];

    // Cas spécial : tatouages — la liste vient de scan.tattoosList et l'id
    // de chaque item est le nameHash (utilisé comme nom de fichier .png).
    if (utilsType === 'tattoos') {
      const list = scan.tattoosList || [];
      for (const t of list) {
        items.push({
          id: `${utilsGender}/tattoos/${t.nameHash}`,
          label: t.nameHash,
          hasImage: existingCat.includes(t.nameHash),
          type: 'utils' as CaptureType,
          meta: {
            gender: utilsGender,
            utilsType: 'tattoos',
            nameHash: t.nameHash,
            collection: t.collection,
            zone: t.zone,
          },
        });
      }
      return items;
    }

    const count = scan.utils[utilsType] || 0;
    for (let i = 0; i < count; i++) {
      items.push({
        id: `${utilsGender}/${utilsType}/${i}`,
        label: `${cat.label} #${i}`,
        hasImage: existingCat.includes(String(i)),
        type: 'utils' as CaptureType,
        meta: {
          gender: utilsGender,
          utilsType: utilsType,
          variationId: i,
        },
      });
    }
    return items;
  }, [gameScanData, utilsGender, utilsType, existingImages, config]);

  const currentItems = useMemo(() => {
    let items: ItemEntry[] = [];
    switch (activeTab) {
      case 'vehicles': items = vehicleItems; break;
      case 'clothing': items = clothingItems; break;
      case 'weapons': items = weaponItems; break;
      case 'peds': items = pedItems; break;
      case 'props': items = propItems; break;
      case 'utils': items = utilsItems; break;
    }

    if (filterMode === 'missing') items = items.filter(i => !i.hasImage);
    if (filterMode === 'existing') items = items.filter(i => i.hasImage);

    if (searchQuery.trim()) {
      const q = searchQuery.toLowerCase();
      items = items.filter(i => i.label.toLowerCase().includes(q) || i.id.toLowerCase().includes(q));
    }

    return items;
  }, [activeTab, vehicleItems, clothingItems, weaponItems, pedItems, propItems, filterMode, searchQuery]);

  // ========================================================================
  // SELECTION
  // ========================================================================

  const toggleSelect = useCallback((id: string) => {
    setSelected(prev => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });
  }, []);

  const selectAll = () => {
    setSelected(new Set(currentItems.map(i => i.id)));
  };

  const selectMissing = () => {
    setSelected(new Set(currentItems.filter(i => !i.hasImage).map(i => i.id)));
  };

  const deselectAll = () => {
    setSelected(new Set());
  };

  // ========================================================================
  // CAPTURE
  // ========================================================================

  const buildQueue = (): CaptureQueueItem[] => {
    const queue: CaptureQueueItem[] = [];
    const allItems = activeTab === 'vehicles' ? vehicleItems :
                     activeTab === 'clothing' ? clothingItems :
                     activeTab === 'weapons' ? weaponItems :
                     activeTab === 'peds' ? pedItems :
                     activeTab === 'utils' ? utilsItems : propItems;

    for (const item of allItems) {
      if (!selected.has(item.id)) continue;
      const q: CaptureQueueItem = {
        type: item.type,
        id: item.id,
        label: item.label,
        ...item.meta,
      };
      queue.push(q);
    }
    return queue;
  };

  const startCapture = () => {
    const queue = buildQueue();
    if (queue.length === 0) return;

    setIsCapturing(true);
    setCapturedThisSession(new Set());
    setProgress({ current: 0, total: queue.length });

    fetch(`https://${GetParentResourceName()}/imagemaker:startCapture`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ queue, settings }),
    }).catch(() => setIsCapturing(false));
  };

  const stopCapture = () => {
    fetch(`https://${GetParentResourceName()}/imagemaker:stopCapture`, { method: 'POST' }).catch(() => {});
    setIsCapturing(false);
  };

  // ========================================================================
  // STATS
  // ========================================================================

  const stats = useMemo(() => {
    const total = currentItems.length;
    const existing = currentItems.filter(i => i.hasImage).length;
    const missing = total - existing;
    const selectedCount = selected.size;
    const estimatedTime = selectedCount * (settings.delay + 1500);
    return { total, existing, missing, selectedCount, estimatedTime };
  }, [currentItems, selected, settings]);

  // ========================================================================
  // CUSTOM CAPTURE HANDLERS
  // ========================================================================

  const customSpawn = async () => {
    setCustomSpawning(true);
    setCustomStatus(null);

    const cat = config?.clothingCategories?.find(c => c.id === customClothingCat);
    const payload: Record<string, any> = {
      entityType: customEntityType,
      model: customModel,
    };
    if (customEntityType === 'clothing') {
      payload.gender = customGender;
      payload.componentType = cat?.type || 'CLOTHING';
      payload.componentId = cat?.component ?? 11;
      payload.drawableId = customDrawableId;
    }

    try {
      const resp = await fetch(`https://${GetParentResourceName()}/imagemaker:customSpawn`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
      });
      const result = await resp.json();
      if (result.error) {
        setCustomStatus({ text: `Erreur: ${result.error}` });
        setCustomSpawning(false);
        return;
      }
      setCamDist(result.dist ?? 5);
      setCamAngleH(result.angleH ?? 30);
      setCamAngleV(result.angleV ?? 10);
      setCamFov(result.fov ?? 40);
      setCamOffsetZ(result.offsetZ ?? 0);
      setEntityRotZ(0.0);
      setCustomSpawned(true);
      setCustomSaveType(customEntityType === 'clothing' ? 'clothing' : customEntityType);
      setCustomSaveName(customEntityType === 'clothing'
        ? `${customGender}/${customClothingCat}/${customDrawableId}`
        : customModel.toLowerCase());
    } catch {
      setCustomStatus({ text: 'Erreur de communication' });
    }
    setCustomSpawning(false);
  };

  const customAdjust = (key: string, value: number) => {
    fetch(`https://${GetParentResourceName()}/imagemaker:customAdjust`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ [key]: value }),
    }).catch(() => {});
  };

  const customCapture = async () => {
    if (!customSaveName.trim()) {
      setCustomStatus({ text: 'Nom de fichier requis' });
      return;
    }
    setCustomCapturing(true);
    setCustomStatus({ text: 'Capture en cours...' });
    try {
      await fetch(`https://${GetParentResourceName()}/imagemaker:customCapture`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ saveName: customSaveName, saveType: customSaveType }),
      });
      setCustomStatus({ text: 'Capture réussie !', success: true });
    } catch {
      setCustomStatus({ text: 'Erreur de capture' });
    }
    setCustomCapturing(false);
  };

  const customClear = async () => {
    try {
      await fetch(`https://${GetParentResourceName()}/imagemaker:customClear`, { method: 'POST' });
    } catch {}
    setCustomSpawned(false);
    setCustomStatus(null);
  };

  const formatTime = (ms: number) => {
    const s = Math.ceil(ms / 1000);
    if (s < 60) return `${s}s`;
    const m = Math.floor(s / 60);
    const rem = s % 60;
    if (m < 60) return `${m}m ${rem}s`;
    const h = Math.floor(m / 60);
    return `${h}h ${m % 60}m`;
  };

  // ========================================================================
  // CLOSE
  // ========================================================================

  const handleClose = useCallback(() => {
    if (customSpawned) {
      fetch(`https://${GetParentResourceName()}/imagemaker:customClear`, { method: 'POST' }).catch(() => {});
      setCustomSpawned(false);
    }
    setHiding(true);
    setTimeout(() => {
      setHiding(false);
      fetch(`https://${GetParentResourceName()}/imagemaker:close`, { method: 'POST' }).catch(() => {});
    }, 280);
  }, [customSpawned]);

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape' && visible) {
        if (previewImage) setPreviewImage(null);
        else if (showSettings) setShowSettings(false);
        else handleClose();
      }
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [visible, previewImage, showSettings, handleClose]);

  // ========================================================================
  // IMAGE HELPERS
  // ========================================================================

  const getImageUrl = (item: ItemEntry): string | null => {
    if (!item.hasImage) return null;
    switch (item.type) {
      case 'vehicle': return cacheImg(`vehicles/${item.id}.webp`);
      case 'weapon': return cacheImg(`weapons/${item.id}.webp`);
      case 'ped': return cacheImg(`peds/${item.id}.webp`);
      case 'prop': return cacheImg(`props/${item.id}.webp`);
      case 'clothing': return cacheImg(`clothes/${item.id}.png`);
      case 'utils': return cacheImg(`clothes/utils/${item.id}.png`);
      default: return null;
    }
  };

  const changeTab = (tab: TabType) => {
    if (tab === activeTab) return;
    if (activeTab === 'custom' && customSpawned) {
      customClear();
    }
    setActiveTab(tab);
    setSelected(new Set());
    setSearchQuery('');
    setFilterMode('all');
    setVisibleCount(ITEMS_PER_CHUNK);
  };

  // Reset visible count when filter/search/category changes
  useEffect(() => {
    setVisibleCount(ITEMS_PER_CHUNK);
    if (gridContainerRef.current) gridContainerRef.current.scrollTop = 0;
  }, [clothingGender, clothingCategory, filterMode, searchQuery]);

  const visibleItems = useMemo(() => currentItems.slice(0, visibleCount), [currentItems, visibleCount]);

  const handleGridScroll = useCallback((e: React.UIEvent<HTMLDivElement>) => {
    const el = e.currentTarget;
    if (el.scrollTop + el.clientHeight >= el.scrollHeight - 300) {
      setVisibleCount(prev => Math.min(prev + ITEMS_PER_CHUNK, currentItems.length));
    }
  }, [currentItems.length]);

  // ========================================================================
  // RENDER
  // ========================================================================

  if (!visible && !hiding) return null;

  // Custom tab: slim floating side panel
  if (activeTab === 'custom') {
    return (
      <div className={`imgm-custom-overlay-wrap ${hiding ? 'imgm-hiding' : ''}`} style={imgmAccentVars as React.CSSProperties}>
        <div className="imgm-custom-float">
          {/* Header */}
          <div className="imgm-custom-float-header">
            <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
              <Move size={16} style={{ color: accentColor }} />
              <span className="imgm-custom-float-title">Capture personnalisée</span>
            </div>
            <div style={{ display: 'flex', gap: 4 }}>
              <button className="imgm-icon-btn" onClick={() => changeTab('vehicles')} title="Retour">
                <ChevronRight size={14} style={{ transform: 'rotate(180deg)' }} />
              </button>
              <button className="imgm-icon-btn" onClick={handleClose} title="Fermer">
                <X size={14} />
              </button>
            </div>
          </div>

          {/* Spawn section */}
          <div className="imgm-custom-float-section">
            <div className="imgm-custom-float-label">Type</div>
            <select className="imgm-custom-float-select" value={customEntityType} onChange={e => { setCustomEntityType(e.target.value); setCustomModel(''); }}>
              <option value="vehicle">Véhicule</option>
              <option value="weapon">Arme</option>
              <option value="ped">Ped</option>
              <option value="prop">Prop</option>
              <option value="clothing">Vêtement</option>
            </select>

            {customEntityType !== 'clothing' && (
              <>
                <div className="imgm-custom-float-label">Modèle</div>
                <input
                  className="imgm-custom-float-input"
                  type="text"
                  placeholder={
                    customEntityType === 'vehicle' ? 'sultan, adder...' :
                    customEntityType === 'weapon' ? 'WEAPON_PISTOL...' :
                    customEntityType === 'ped' ? 'a_m_y_hipster_01...' :
                    'prop_bench_01a...'
                  }
                  value={customModel}
                  onChange={e => setCustomModel(e.target.value)}
                  onKeyDown={e => { if (e.key === 'Enter' && customModel.trim()) customSpawn(); }}
                />
              </>
            )}

            {customEntityType === 'clothing' && (
              <>
                <div className="imgm-custom-float-label">Genre</div>
                <div className="imgm-toggle-group" style={{ width: '100%' }}>
                  <button style={{ flex: 1 }} className={customGender === 'male' ? 'active' : ''} onClick={() => setCustomGender('male')}>Homme</button>
                  <button style={{ flex: 1 }} className={customGender === 'female' ? 'active' : ''} onClick={() => setCustomGender('female')}>Femme</button>
                </div>
                <div className="imgm-custom-float-label">Catégorie</div>
                <select className="imgm-custom-float-select" value={customClothingCat} onChange={e => setCustomClothingCat(e.target.value)}>
                  {config?.clothingCategories?.map(cat => (
                    <option key={cat.id} value={cat.id}>{cat.label}</option>
                  ))}
                </select>
                <div className="imgm-custom-float-label">Drawable ID</div>
                <input
                  className="imgm-custom-float-input"
                  type="number"
                  min={0}
                  value={customDrawableId}
                  onChange={e => setCustomDrawableId(parseInt(e.target.value) || 0)}
                />
              </>
            )}

            <button
              className="imgm-custom-spawn-btn"
              style={{ background: `linear-gradient(135deg, ${accentColor}, #7c3aed)`, width: '100%', marginTop: 6 }}
              disabled={customSpawning || (customEntityType !== 'clothing' && !customModel.trim())}
              onClick={customSpawn}
            >
              {customSpawning ? <><Loader2 size={14} className="imgm-spin" /> Chargement...</> : <><Eye size={14} /> Prévisualiser</>}
            </button>
          </div>

          {/* Camera controls */}
          {customSpawned && (
            <>
              <div className="imgm-custom-float-divider" />
              <div className="imgm-custom-float-section">
                <div className="imgm-custom-float-label">Caméra</div>
                {[
                  { label: 'Distance', value: camDist, set: setCamDist, key: 'dist', min: 0.5, max: 30, step: 0.1 },
                  { label: 'Angle H', value: camAngleH, set: setCamAngleH, key: 'angleH', min: 0, max: 360, step: 1 },
                  { label: 'Angle V', value: camAngleV, set: setCamAngleV, key: 'angleV', min: -89, max: 89, step: 1 },
                  { label: 'FOV', value: camFov, set: setCamFov, key: 'fov', min: 5, max: 120, step: 1 },
                  { label: 'Hauteur', value: camOffsetZ, set: setCamOffsetZ, key: 'offsetZ', min: -5, max: 5, step: 0.05 },
                  { label: 'Rotation', value: entityRotZ, set: setEntityRotZ, key: 'entityRotZ', min: 0.0, max: 360.0, step: 1 },
                ].map(s => (
                  <div key={s.key} className="imgm-custom-slider-row">
                    <span className="imgm-custom-slider-label">{s.label}</span>
                    <input
                      type="range"
                      min={s.min}
                      max={s.max}
                      step={s.step}
                      value={s.value}
                      onChange={e => {
                        const v = parseFloat(e.target.value);
                        s.set(v);
                        customAdjust(s.key, v);
                      }}
                    />
                    <span className="imgm-custom-slider-value">{s.value.toFixed(s.step < 1 ? 1 : 0)}</span>
                  </div>
                ))}
              </div>

              <div className="imgm-custom-float-divider" />
              <div className="imgm-custom-float-section">
                <div className="imgm-custom-float-label">Sauvegarder</div>
                <select className="imgm-custom-float-select" value={customSaveType} onChange={e => setCustomSaveType(e.target.value)}>
                  <option value="vehicle">Véhicule</option>
                  <option value="weapon">Arme</option>
                  <option value="ped">Ped</option>
                  <option value="prop">Prop</option>
                  <option value="clothing">Vêtement</option>
                </select>
                <input
                  className="imgm-custom-float-input"
                  type="text"
                  placeholder="Nom du fichier"
                  value={customSaveName}
                  onChange={e => setCustomSaveName(e.target.value)}
                />
                <div className="imgm-custom-btn-row">
                  <button
                    className="imgm-custom-capture-btn"
                    style={{ background: `linear-gradient(135deg, ${accentColor}, #7c3aed)` }}
                    disabled={customCapturing || !customSaveName.trim()}
                    onClick={customCapture}
                  >
                    {customCapturing ? <><Loader2 size={14} className="imgm-spin" /> Capture...</> : <><Camera size={14} /> Capturer</>}
                  </button>
                  <button className="imgm-custom-clear-btn" onClick={customClear}>
                    <Trash2 size={14} />
                  </button>
                </div>
                {customStatus && (
                  <div className={`imgm-custom-status ${customStatus.success ? 'success' : ''}`}>
                    {customStatus.text}
                  </div>
                )}
              </div>
            </>
          )}
        </div>
      </div>
    );
  }

  // Standard tabs: full centered container
  return (
    <div className={`imgm-overlay ${hiding ? 'imgm-hiding' : ''}`}>
      <div className="imgm-container" style={imgmAccentVars as React.CSSProperties}>
        {/* ============ SIDEBAR ============ */}
        <div className="imgm-sidebar">
          <div className="imgm-sidebar-header">
            <div className="imgm-sidebar-icon" style={{ background: `${accentColor}20`, color: accentColor }}>
              <Camera size={18} />
            </div>
            <div className="imgm-sidebar-title">
              <h1>Image Maker</h1>
              <p>Capture d'images</p>
            </div>
          </div>

          <nav className="imgm-sidebar-nav">
            {TABS.map(tab => (
              <button
                key={tab.key}
                className={`imgm-sidebar-item ${activeTab === tab.key ? 'active' : ''}`}
                onClick={() => changeTab(tab.key)}
                style={activeTab === tab.key ? {
                  background: `${accentColor}12`,
                  borderColor: `${accentColor}30`,
                  color: accentColor
                } : {}}
              >
                {tab.icon}
                {tab.label}
                <ChevronRight size={14} className="imgm-sidebar-arrow" />
              </button>
            ))}
          </nav>

          {/* Stats */}
          <div className="imgm-sidebar-stats">
            <div className="imgm-sidebar-stat">
              <Image size={12} />
              <span>{stats.total} items</span>
            </div>
            <div className="imgm-sidebar-stat" style={{ color: '#22c55e' }}>
              <CheckCircle size={12} />
              <span>{stats.existing} capturés</span>
            </div>
            <div className="imgm-sidebar-stat" style={{ color: '#ef4444' }}>
              <XCircle size={12} />
              <span>{stats.missing} manquants</span>
            </div>
            {stats.selectedCount > 0 && (
              <>
                <div className="imgm-sidebar-stat" style={{ color: accentColor }}>
                  <CheckSquare size={12} />
                  <span>{stats.selectedCount} sélectionnés</span>
                </div>
                <div className="imgm-sidebar-stat" style={{ color: '#f59e0b' }}>
                  <Clock size={12} />
                  <span>~{formatTime(stats.estimatedTime)}</span>
                </div>
              </>
            )}
          </div>

          <div className="imgm-sidebar-footer">
            <button className="imgm-sidebar-close" onClick={handleClose}>
              <X size={16} />
              Fermer (ESC)
            </button>
          </div>
        </div>

        {/* ============ CONTENT ============ */}
        <div className="imgm-content">
          {/* Content header */}
          <div className="imgm-content-header">
            <div className="imgm-content-header-info">
              <div className="imgm-content-header-icon" style={{ background: `${accentColor}15`, color: accentColor }}>
                {TABS.find(t => t.key === activeTab)?.icon}
              </div>
              <div>
                <h2>{TABS.find(t => t.key === activeTab)?.label}</h2>
                <p>{stats.total} éléments disponibles</p>
              </div>
            </div>
            <div className="imgm-content-header-actions">
              <button className="imgm-icon-btn" onClick={() => triggerScanImages()} title="Actualiser">
                <RefreshCw size={14} />
              </button>
              <button className={`imgm-icon-btn ${showSettings ? 'active' : ''}`} onClick={() => setShowSettings(!showSettings)} title="Paramètres">
                <Sliders size={14} />
              </button>
            </div>
          </div>

          {/* Settings panel */}
          {showSettings && (
            <div className="imgm-settings-panel">
              <div className="imgm-setting-row">
                <label>Délai entre captures (ms)</label>
                <input
                  type="number"
                  min={100}
                  max={5000}
                  step={100}
                  value={settings.delay}
                  onChange={e => setSettings(prev => ({ ...prev, delay: parseInt(e.target.value) || 500 }))}
                />
              </div>
              <div className="imgm-setting-row">
                <label>Suppression fond vert</label>
                <button
                  className={`imgm-toggle ${settings.greenRemoval ? 'on' : ''}`}
                  onClick={() => setSettings(prev => ({ ...prev, greenRemoval: !prev.greenRemoval }))}
                >
                  {settings.greenRemoval ? 'ON' : 'OFF'}
                </button>
              </div>
            </div>
          )}

          {/* Capture progress */}
          {isCapturing && progress && (
            <div className="imgm-progress-bar">
              <div className="imgm-progress-info">
                <Loader2 size={14} className="imgm-spin" />
                <span>Capture en cours... {progress.current}/{progress.total}</span>
                {progress.itemLabel && <span className="imgm-progress-item">{progress.itemLabel}</span>}
              </div>
              <div className="imgm-progress-track">
                <div
                  className="imgm-progress-fill"
                  style={{ width: `${(progress.current / progress.total) * 100}%` }}
                />
              </div>
              <button className="imgm-stop-btn" onClick={stopCapture}>
                <Square size={12} /> Arrêter
              </button>
            </div>
          )}

          {/* Toolbar */}
          <div className="imgm-toolbar">
            <div className="imgm-toolbar-left">
              {activeTab === 'clothing' && (
                <>
                  <div className="imgm-toggle-group">
                    <button className={clothingGender === 'male' ? 'active' : ''} onClick={() => { setClothingGender('male'); scanGameData('male'); setSelected(new Set()); }}>
                      Homme
                    </button>
                    <button className={clothingGender === 'female' ? 'active' : ''} onClick={() => { setClothingGender('female'); scanGameData('female'); setSelected(new Set()); }}>
                      Femme
                    </button>
                  </div>
                  <select
                    className="imgm-select"
                    value={clothingCategory}
                    onChange={e => { setClothingCategory(e.target.value); setSelected(new Set()); }}
                  >
                    {config?.clothingCategories?.map(cat => (
                      <option key={cat.id} value={cat.id}>{cat.label} ({cat.id})</option>
                    ))}
                  </select>
                </>
              )}

              {activeTab === 'utils' && (
                <>
                  <div className="imgm-toggle-group">
                    <button className={utilsGender === 'male' ? 'active' : ''} onClick={() => { setUtilsGender('male'); scanGameData('male'); setSelected(new Set()); }}>
                      Homme
                    </button>
                    <button className={utilsGender === 'female' ? 'active' : ''} onClick={() => { setUtilsGender('female'); scanGameData('female'); setSelected(new Set()); }}>
                      Femme
                    </button>
                  </div>
                  <select
                    className="imgm-select"
                    value={utilsType}
                    onChange={e => { setUtilsType(e.target.value); setSelected(new Set()); }}
                  >
                    {config?.utilsCategories?.map(cat => (
                      <option key={cat.id} value={cat.id}>{cat.label}</option>
                    ))}
                  </select>
                </>
              )}

              {activeTab === 'props' && (
                <div className="imgm-prop-input">
                  <input
                    type="text"
                    placeholder="Nom du prop (ex: prop_bench_01a)"
                    value={propInput}
                    onChange={e => setPropInput(e.target.value)}
                    onKeyDown={e => {
                      if (e.key === 'Enter' && propInput.trim()) {
                        setPropList(prev => [...new Set([...prev, propInput.trim()])]);
                        setPropInput('');
                      }
                    }}
                  />
                  <button onClick={() => {
                    if (propInput.trim()) {
                      setPropList(prev => [...new Set([...prev, propInput.trim()])]);
                      setPropInput('');
                    }
                  }}>+</button>
                </div>
              )}

              <div className="imgm-search-box">
                <Search size={13} />
                <input
                  type="text"
                  placeholder="Rechercher..."
                  value={searchQuery}
                  onChange={e => setSearchQuery(e.target.value)}
                />
              </div>
            </div>

            <div className="imgm-toolbar-right">
              <div className="imgm-toggle-group">
                <button className={filterMode === 'all' ? 'active' : ''} onClick={() => setFilterMode('all')}>Tout</button>
                <button className={filterMode === 'missing' ? 'active' : ''} onClick={() => setFilterMode('missing')}>Manquant</button>
                <button className={filterMode === 'existing' ? 'active' : ''} onClick={() => setFilterMode('existing')}>Existant</button>
              </div>
            </div>
          </div>

          {/* Selection bar */}
          <div className="imgm-selection-bar">
            <button className="imgm-sel-btn" onClick={selectAll}>Tout sélectionner</button>
            <button className="imgm-sel-btn" onClick={selectMissing}>Sélectionner manquants</button>
            <button className="imgm-sel-btn" onClick={deselectAll}>Désélectionner</button>
            <div className="imgm-sel-spacer" />
            {stats.selectedCount > 0 && !isCapturing && (
              <button className="imgm-capture-btn" onClick={startCapture} style={{ background: `linear-gradient(135deg, ${accentColor}, #7c3aed)` }}>
                <Play size={14} />
                Capturer {stats.selectedCount} image{stats.selectedCount > 1 ? 's' : ''}
              </button>
            )}
          </div>

          {/* Item grid */}
          <div className="imgm-grid-container" ref={gridContainerRef} onScroll={handleGridScroll}>
            {loading || scanning ? (
              <div className="imgm-loading">
                <Loader2 size={24} className="imgm-spin" />
                <span>{loading ? 'Chargement...' : 'Scan en cours...'}</span>
              </div>
            ) : currentItems.length === 0 ? (
              <div className="imgm-empty">
                {activeTab === 'props' ? (
                  <>
                    <Box size={32} />
                    <span>Ajoutez des noms de props ci-dessus</span>
                  </>
                ) : (
                  <>
                    <Image size={32} />
                    <span>Aucun item trouvé</span>
                  </>
                )}
              </div>
            ) : (
              <div className="imgm-grid">
                {visibleItems.map(item => (
                  <GridCard
                    key={item.id}
                    item={item}
                    isSelected={selected.has(item.id)}
                    justCaptured={capturedThisSession.has(item.meta?.gender ? `${item.meta.gender}/${item.meta.categoryId}/${item.meta.drawableId}` : item.id)}
                    imgUrl={getImageUrl(item)}
                    onToggle={toggleSelect}
                    onPreview={setPreviewImage}
                    onRetake={(id) => setSelected(new Set([id]))}
                  />
                ))}
                {visibleCount < currentItems.length && (
                  <div className="imgm-load-more">
                    <Loader2 size={16} className="imgm-spin" />
                    <span>{currentItems.length - visibleCount} restants</span>
                  </div>
                )}
              </div>
            )}
          </div>
        </div>
      </div>

      {/* IMAGE PREVIEW MODAL */}
      {previewImage && (
        <div className="imgm-preview-overlay" onClick={() => setPreviewImage(null)}>
          <div className="imgm-preview-content" onClick={e => e.stopPropagation()}>
            <img src={previewImage} alt="Preview" />
            <button className="imgm-preview-close" onClick={() => setPreviewImage(null)}>
              <X size={14} />
            </button>
          </div>
        </div>
      )}
    </div>
  );
};

export default ImageMaker;
