// ============================================================================
// UtilsShopView — UI pour les modes utils du ped-shop (barber / makeup / tattoo)
//
//   Lit les images générées par image-maker (`clothes/utils/{gender}/{type}/`)
//   pour afficher la grille. Pour barber/makeup : single-select par
//   catégorie + apply en preview live. Pour tattoo : panier multi.
//
//   Layout : header brand + sidebar catégories + grille images + aside cart.
//   Pas de 3 peds preview (le joueur voit le résultat sur son propre ped).
// ============================================================================

import React, { useState, useEffect, useCallback, useMemo, useRef } from 'react';
import { generateAccentVars, hexToRgba } from '@/utils/accentColors';
import {
  X, Search, ShoppingCart, CreditCard, Trash2, Check, Scissors, AlertCircle,
  RotateCw, ZoomIn, Palette,
} from 'lucide-react';
import { cacheImg, useCacheVersion } from '@shared/cacheVersion';
import { soundManager } from '@core/SoundManager';
import { GTA_HAIR_COLORS } from '../character-creator/types';
import './UtilsShopView.css';

const GetParentResourceName = () => 'null-core';
const nuiCall = async (event: string, data: Record<string, any> = {}) => {
  try {
    const resp = await fetch(`https://${GetParentResourceName()}/${event}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data),
    });
    return await resp.json();
  } catch { return null; }
};

// ----------------------------------------------------------------------------
// Types
// ----------------------------------------------------------------------------

type UtilsMode = 'barber' | 'makeup' | 'tattoo';

interface ShopBrand {
  id: string;
  name: string;
  logo?: string;
  banner?: string;
  bgColor?: string;
  accentColor?: string;
  tagline?: string;
}

interface UtilsCategory {
  id: string;
  label: string;
}

interface TattooEntry {
  collection: string;
  nameHash: string;
  zone?: string;
  price?: number;
}

interface UtilsShopData {
  mode: UtilsMode;
  playerSex: 'male' | 'female';
  brand?: ShopBrand;
  categories: UtilsCategory[];
  price: number;
  tattoosList?: TattooEntry[];
  skin?: Record<string, number>;
  maxValues?: UtilsMaxValues;
}

interface UtilsMaxValues {
  hair: number;
  beard: number;
  eyebrows: number;
  colors: number;
  opacity: number;
}

const EMPTY_MAX_VALUES: UtilsMaxValues = {
  hair: 0,
  beard: 0,
  eyebrows: 0,
  colors: 0,
  opacity: 0,
};

const TITLES: Record<UtilsMode, string> = {
  barber: 'Salon de coiffure',
  makeup: 'Salon de maquillage',
  tattoo: 'Salon de tatouage',
};

// ----------------------------------------------------------------------------
// Component
// ----------------------------------------------------------------------------

interface Props {
  visible: boolean;
  onClose: () => void;
  primaryColor: string;
  serverIcon?: string;
  serverName?: string;
}

const UtilsShopView: React.FC<Props> = ({ visible, onClose, primaryColor, serverIcon, serverName }) => {
  const [data, setData] = useState<UtilsShopData | null>(null);
  const [activeCategory, setActiveCategory] = useState<string>('');
  // barber/makeup : { hair: 12, beard: 5, ... }
  const [selected, setSelected] = useState<Record<string, number>>({});
  // tattoo : panier
  const [cart, setCart] = useState<TattooEntry[]>([]);
  const [search, setSearch] = useState('');
  const [hiding, setHiding] = useState(false);
  const [mounted, setMounted] = useState(false);
  const [variationCounts, setVariationCounts] = useState<Record<string, number>>({});
  const [maxValues, setMaxValues] = useState<UtilsMaxValues>(EMPTY_MAX_VALUES);
  const [skinValues, setSkinValues] = useState<Record<string, number>>({});
  const [previewDragging, setPreviewDragging] = useState(false);
  const previewPointer = useRef({ x: 0, y: 0 });
  const [notification, setNotification] = useState<{ message: string; type: 'success' | 'error' } | null>(null);
  const notificationTimer = useRef<ReturnType<typeof setTimeout>>();
  useCacheVersion();

  // ---- NUI listeners ------------------------------------------------------
  useEffect(() => {
    const handle = (event: MessageEvent) => {
      const { action, data: payload } = event.data || {};
      if (action === 'shop:open' && payload &&
          (payload.mode === 'barber' || payload.mode === 'makeup' || payload.mode === 'tattoo')) {
        setData({
          mode: payload.mode,
          playerSex: payload.playerSex || 'male',
          brand: payload.brand,
          categories: payload.categories || [],
          price: payload.price || 100,
          tattoosList: payload.tattoosList,
        });
        setActiveCategory(payload.categories?.[0]?.id || '');
        const initialSelected: Record<string, number> = {};
        (payload.categories || []).forEach((category: UtilsCategory) => {
          const initialValue = payload.skin?.[`${category.id}_1`];
          if (typeof initialValue === 'number') initialSelected[category.id] = initialValue;
        });
        setSelected(initialSelected);
        setCart([]);
        setSearch('');
        setVariationCounts(payload.maxValues || {});
        setMaxValues({ ...EMPTY_MAX_VALUES, ...(payload.maxValues || {}) });
        setSkinValues(payload.skin || {});
        setHiding(false);
        // animation in
        requestAnimationFrame(() => setMounted(true));
      } else if (action === 'shop:close') {
        setMounted(false);
        setHiding(true);
        setTimeout(() => { setData(null); setHiding(false); }, 250);
      }
    };
    window.addEventListener('message', handle);
    return () => window.removeEventListener('message', handle);
  }, []);

  // Always consume the game callback for the active category. This prevents
  // the UI from truncating valid hair/beard/eyebrow variations.
  useEffect(() => {
    if (!data || data.mode === 'tattoo' || !activeCategory) return;
    let cancelled = false;
    nuiCall('shop:utils:getMaxVariations', { utilsType: activeCategory }).then(resp => {
      if (cancelled || typeof resp?.max !== 'number') return;
      setVariationCounts(prev => ({ ...prev, [activeCategory]: resp.max }));
    });
    return () => { cancelled = true; };
  }, [activeCategory, data?.mode]);

  // ---- Brand styling ------------------------------------------------------
  const brand = data?.brand;
  const brandBg = primaryColor;
  // Keep utils shops aligned with the same dynamic accent used by Inventory.
  // Shop brands may provide an accent for clothing, but barber/makeup/tattoo
  // must follow the server HUD theme instead.
  const accent = primaryColor;

  const accentVars = useMemo(
    () => generateAccentVars('--utilshop-accent', accent),
    [accent]
  );
  const brandVars = useMemo(() => {
    const vars: Record<string, string> = {
      '--utilshop-brand-bg': accent,
      '--utilshop-brand-accent': accent,
      '--utilshop-brand-surface': brandBg,
    };
    const isHex = accent.startsWith('#') && accent.length >= 7;
    [10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60, 65, 70, 80, 90].forEach(o => {
      vars[`--utilshop-brand-${o}`] = isHex ? hexToRgba(accent, o) : accent;
    });
    return vars as React.CSSProperties;
  }, [brandBg, accent]);

  const containerStyle = useMemo(() => ({
    ...(accentVars as React.CSSProperties),
    ...brandVars,
  }), [accentVars, brandVars]);

  // ---- Items computed -----------------------------------------------------
  // tattoo : filtré par zone active + search.
  // barber/makeup : all valid indexes returned by the game callback.
  const tattooItems = useMemo<TattooEntry[]>(() => {
    if (!data || data.mode !== 'tattoo') return [];
    const list = data.tattoosList || [];
    const q = search.trim().toLowerCase();
    return list.filter(t => {
      const matchZone = (t.zone || 'torso') === activeCategory;
      const matchQ = !q || t.nameHash.toLowerCase().includes(q);
      return matchZone && matchQ;
    });
  }, [data, activeCategory, search]);

  const overlayItems = useMemo<number[]>(() => {
    if (!data || data.mode === 'tattoo') return [];
    const max = variationCounts[activeCategory] ?? 0;
    const arr: number[] = [];
    for (let i = 0; i < max; i++) arr.push(i);
    return arr;
  }, [data, activeCategory, variationCounts]);

  // ---- Apply (barber/makeup) ----------------------------------------------
  const handleApplyOverlay = useCallback((index: number) => {
    if (!data || data.mode === 'tattoo') return;
    setSelected(prev => ({ ...prev, [activeCategory]: index }));
    const skinKey = `${activeCategory}_1`;
    setSkinValues(prev => ({ ...prev, [skinKey]: index }));
    nuiCall('shop:utils:apply', { utilsType: activeCategory, variationId: index });
    soundManager.play('click');
  }, [data, activeCategory]);

  const applySkinValue = useCallback((key: string, value: number) => {
    setSkinValues(prev => ({ ...prev, [key]: value }));
    nuiCall('shop:utils:update', { key, value });
    soundManager.play('click');
  }, []);

  // The transparent area between the two panels is the live character
  // preview. Mouse movement is forwarded globally while dragging so the
  // camera keeps responding even if the pointer crosses a panel edge.
  const handlePreviewMouseDown = useCallback((event: React.MouseEvent) => {
    if (event.button !== 0) return;
    event.preventDefault();
    previewPointer.current = { x: event.clientX, y: event.clientY };
    setPreviewDragging(true);
    nuiCall('shop:utils:startRotation', { mouseX: event.clientX, mouseY: event.clientY });
  }, []);

  const stopPreviewDragging = useCallback(() => {
    setPreviewDragging(false);
    nuiCall('shop:utils:stopRotation');
  }, []);

  useEffect(() => {
    if (!previewDragging) return;
    const handleMouseMove = (event: MouseEvent) => {
      previewPointer.current = { x: event.clientX, y: event.clientY };
      nuiCall('shop:utils:updateRotation', { mouseX: event.clientX, mouseY: event.clientY });
    };
    window.addEventListener('mousemove', handleMouseMove);
    window.addEventListener('mouseup', stopPreviewDragging);
    return () => {
      window.removeEventListener('mousemove', handleMouseMove);
      window.removeEventListener('mouseup', stopPreviewDragging);
    };
  }, [previewDragging, stopPreviewDragging]);

  const handlePreviewWheel = useCallback((event: React.WheelEvent) => {
    event.preventDefault();
    nuiCall('shop:utils:zoom', { delta: event.deltaY });
  }, []);

  // ---- Tattoo cart toggle -------------------------------------------------
  const handleTattooToggle = useCallback((tattoo: TattooEntry) => {
    if (!data || data.mode !== 'tattoo') return;
    const exists = cart.find(t => t.nameHash === tattoo.nameHash);
    if (exists) {
      setCart(prev => prev.filter(t => t.nameHash !== tattoo.nameHash));
      nuiCall('shop:utils:tattoo:remove', { nameHash: tattoo.nameHash });
    } else {
      setCart(prev => [...prev, tattoo]);
      nuiCall('shop:utils:tattoo:add', tattoo);
    }
    soundManager.play('click');
  }, [data, cart]);

  // ---- Close / pay --------------------------------------------------------
  const handleClose = useCallback(() => {
    if (hiding) return;
    setPreviewDragging(false);
    nuiCall('shop:utils:stopRotation');
    setMounted(false);
    setHiding(true);
    setTimeout(() => {
      nuiCall('shop:utils:exit');
      onClose();
    }, 250);
  }, [hiding, onClose]);

  const showNotification = useCallback((message: string, type: 'success' | 'error' = 'success') => {
    setNotification({ message, type });
    if (notificationTimer.current) clearTimeout(notificationTimer.current);
    notificationTimer.current = setTimeout(() => setNotification(null), 3000);
  }, []);

  const handlePay = useCallback(async () => {
    if (!data) return;
    const resp = await nuiCall('shop:utils:pay', { mode: data.mode });
    if (resp?.success) {
      soundManager.play('success');
      showNotification('Paiement confirmé');
    } else {
      showNotification('Paiement refusé', 'error');
    }
  }, [data, showNotification]);

  useEffect(() => () => {
    if (notificationTimer.current) clearTimeout(notificationTimer.current);
  }, []);

  useEffect(() => {
    const handleKey = (event: KeyboardEvent) => {
      if (event.key === 'Escape' && visible && !hiding) handleClose();
    };
    window.addEventListener('keydown', handleKey);
    return () => window.removeEventListener('keydown', handleKey);
  }, [handleClose, hiding, visible]);

  // ---- Total --------------------------------------------------------------
  const total = useMemo(() => {
    if (!data) return 0;
    if (data.mode === 'tattoo') return cart.reduce((s, t) => s + (t.price || 100), 0);
    // barber/makeup : prix global fixe
    return data.price || 100;
  }, [data, cart]);

  // ---- Render -------------------------------------------------------------
  if (!visible || !data) return null;

  const overlayClass = hiding ? 'utilshop-hiding' : mounted ? 'utilshop-visible utilshop-showing' : '';
  const cartCount = data.mode === 'tattoo' ? cart.length : 0;
  const activeCategoryLabel = data.categories.find(cat => cat.id === activeCategory)?.label || 'Sélection';
  const headerName = brand?.name || serverName || TITLES[data.mode];
  const headerDesc = brand?.tagline || (data.mode === 'tattoo'
    ? 'Choisissez vos tatouages et composez votre sélection'
    : 'Personnalisez votre apparence en direct');
  const brandBanner = brand?.banner ? cacheImg(brand.banner) : null;

  const renderColorGrid = (key: string, label: string) => {
    const colorCount = maxValues.colors;
    return (
      <div className="utilshop-control-section">
        <div className="utilshop-control-label"><Palette size={12} /> {label}</div>
        {colorCount > 0 ? (
          <div className="utilshop-color-grid">
            {Array.from({ length: colorCount }, (_, index) => (
              <button
                key={`${key}-${index}`}
                type="button"
                className={`utilshop-color-swatch ${skinValues[key] === index ? 'selected' : ''}`}
                style={GTA_HAIR_COLORS[index] ? { background: GTA_HAIR_COLORS[index] } : undefined}
                onClick={() => applySkinValue(key, index)}
                aria-label={`${label} ${index}`}
                title={`${label} ${index}`}
              >
                {!GTA_HAIR_COLORS[index] && index}
              </button>
            ))}
          </div>
        ) : (
          <span className="utilshop-control-muted">Palette indisponible</span>
        )}
      </div>
    );
  };

  const renderOpacity = (key: 'beard_2' | 'eyebrows_2', label: string) => {
    const value = skinValues[key] ?? 0;
    return (
      <div className="utilshop-control-section utilshop-opacity-control">
        <div className="utilshop-control-heading">
          <span>{label}</span>
          <strong>{Math.round((value / Math.max(maxValues.opacity, 1)) * 100)}%</strong>
        </div>
        <input
          type="range"
          min={0}
          max={maxValues.opacity}
          value={value}
          disabled={maxValues.opacity <= 0}
          onChange={event => applySkinValue(key, Number(event.target.value))}
          style={{ accentColor: 'var(--utilshop-accent)' }}
        />
      </div>
    );
  };

  const renderControls = () => {
    if (data.mode !== 'barber') return null;
    if (activeCategory === 'hair') {
      return (
        <div className="utilshop-controls">
          {renderColorGrid('hair_color_1', 'Couleur des cheveux')}
          {renderColorGrid('hair_color_2', 'Reflets')}
        </div>
      );
    }
    if (activeCategory === 'beard') {
      return (
        <div className="utilshop-controls">
          {renderOpacity('beard_2', 'Épaisseur / opacité')}
          {renderColorGrid('beard_3', 'Couleur de barbe')}
          {renderColorGrid('beard_4', 'Teinte secondaire')}
        </div>
      );
    }
    if (activeCategory === 'eyebrows') {
      return (
        <div className="utilshop-controls">
          {renderOpacity('eyebrows_2', 'Épaisseur / opacité')}
          {renderColorGrid('eyebrows_3', 'Couleur des sourcils')}
          {renderColorGrid('eyebrows_4', 'Teinte secondaire')}
        </div>
      );
    }
    return null;
  };

  return (
    <div className={`utilshop-overlay ${overlayClass}`} style={containerStyle}>
      <div
        className={`utilshop-preview-zone ${previewDragging ? 'dragging' : ''}`}
        onMouseDown={handlePreviewMouseDown}
        onWheel={handlePreviewWheel}
        aria-label="Aperçu du personnage : glisser pour tourner, molette pour zoomer"
      >
        <div className="utilshop-preview-hint">
          <RotateCw size={13} />
          <span>Glisser pour tourner</span>
          <span className="utilshop-preview-hint-divider">·</span>
          <ZoomIn size={13} />
          <span>Molette pour zoomer</span>
        </div>
      </div>
      <div className="utilshop-container">
        <div className="utilshop-banner">
          {brandBanner && (
            <img
              className="utilshop-banner-img"
              src={brandBanner}
              alt=""
              onError={(event) => { (event.target as HTMLImageElement).style.display = 'none'; }}
            />
          )}
          <div className="utilshop-banner-shade" />
          <button className="utilshop-banner-close" onClick={handleClose} title="Fermer" aria-label="Fermer">
            <X size={16} />
          </button>
          <div className="utilshop-banner-text">
            <div className="utilshop-banner-brand">
              {(serverIcon || brand?.logo)
                ? <img src={serverIcon || cacheImg(brand!.logo!)} alt={serverName || headerName} className="utilshop-brand-logo" />
                : <div className="utilshop-brand-fallback"><Scissors size={18} /></div>}
              <div>
                <span className="utilshop-banner-eyebrow">{TITLES[data.mode]}</span>
                <h1 className="utilshop-banner-title">{headerName}</h1>
              </div>
            </div>
            <p className="utilshop-banner-desc">{headerDesc}</p>
          </div>
        </div>
        <div className="utilshop-brand-sep" aria-hidden />

        <div className="utilshop-body">
          <aside className="utilshop-sidebar">
            <div className="utilshop-sidebar-label">Catégories</div>
            {data.categories.map(cat => {
              const isActive = activeCategory === cat.id;
              const isSelected = data.mode !== 'tattoo' && selected[cat.id] !== undefined;
              return (
                <button
                  key={cat.id}
                  className={`utilshop-cat ${isActive ? 'active' : ''} ${isSelected ? 'has-selection' : ''}`}
                  onClick={() => setActiveCategory(cat.id)}
                >
                  <span>{cat.label}</span>
                  {isSelected && <Check size={12} className="utilshop-cat-check" />}
                </button>
              );
            })}
          </aside>

          {/* Main grid */}
          <main className="utilshop-main">
            <div className="utilshop-content-header">
              <div className="utilshop-content-header-info">
                <h2>{activeCategoryLabel}</h2>
                <p>{data.mode === 'tattoo' ? 'Sélectionnez un motif à ajouter au panier' : 'Aperçu en direct sur votre personnage'}</p>
              </div>
              <div className="utilshop-toolbar">
                <div className="utilshop-search">
                  <Search size={14} />
                  <input
                    value={search}
                    onChange={e => setSearch(e.target.value)}
                    placeholder="Rechercher..."
                  />
                </div>
                <div className="utilshop-counter">
                  {data.mode === 'tattoo'
                    ? `${tattooItems.length} tatouage(s)`
                    : `${overlayItems.length} variation(s)`}
                </div>
              </div>
            </div>

            <div className="utilshop-grid">
              {data.mode === 'tattoo'
                ? tattooItems.map(t => {
                    const inCart = cart.some(c => c.nameHash === t.nameHash);
                    return (
                      <ItemCard
                        key={t.nameHash}
                        src={cacheImg(`clothes/utils/${data.playerSex}/tattoos/${t.nameHash}.webp`)}
                        label={t.nameHash}
                        price={t.price || 100}
                        selected={inCart}
                        onClick={() => handleTattooToggle(t)}
                      />
                    );
                  })
                : overlayItems.map(i => {
                    const isSelected = selected[activeCategory] === i;
                    return (
                      <ItemCard
                        key={`${activeCategory}-${i}`}
                        src={cacheImg(`clothes/utils/${data.playerSex}/${activeCategory}/${i}.webp`)}
                        fallbackSrc={cacheImg(`clothes/utils/${data.playerSex}/hair/0.webp`)}
                        label={`#${i}`}
                        selected={isSelected}
                        onClick={() => handleApplyOverlay(i)}
                      />
                    );
                })}
            </div>
            {renderControls()}
          </main>
        </div>
      </div>

      {/* Cart aside */}
      <aside className="utilshop-cart-panel">
            <div className="utilshop-cart-panel-header">
              <ShoppingCart size={16} />
              <span>{data.mode === 'tattoo' ? `Panier (${cartCount})` : 'Récapitulatif'}</span>
            </div>

            {data.mode === 'tattoo' ? (
              <div className="utilshop-cart-items">
                {cart.length === 0 ? (
                  <div className="utilshop-cart-empty">Aucun tatouage ajouté</div>
                ) : (
                  cart.map(t => (
                    <div key={t.nameHash} className="utilshop-cart-row">
                      <div className="utilshop-cart-name" title={t.nameHash}>{t.nameHash}</div>
                      <div className="utilshop-cart-price">{t.price || 100}$</div>
                      <button
                        className="utilshop-cart-remove"
                        onClick={() => handleTattooToggle(t)}
                        aria-label="Retirer"
                      >
                        <Trash2 size={12} />
                      </button>
                    </div>
                  ))
                )}
              </div>
            ) : (
              <div className="utilshop-cart-items">
                {data.categories.map(cat => {
                  const idx = selected[cat.id];
                  return (
                    <div key={cat.id} className="utilshop-cart-row">
                      <div className="utilshop-cart-name">{cat.label}</div>
                      <div className="utilshop-cart-price">
                        {idx === undefined ? '—' : `#${idx}`}
                      </div>
                    </div>
                  );
                })}
              </div>
            )}

            <div className="utilshop-cart-footer">
              <div className="utilshop-cart-total">
                <span>Total</span>
                <strong>{total}$</strong>
              </div>
              <button
                className="utilshop-pay"
                onClick={handlePay}
                disabled={data.mode === 'tattoo' && cart.length === 0}
              >
                <CreditCard size={16} />
                Payer {total}$
              </button>
            </div>
            {notification && (
              <div className={`utilshop-notification ${notification.type}`}>
                {notification.type === 'success' ? <Check size={15} /> : <AlertCircle size={15} />}
                <span>{notification.message}</span>
              </div>
            )}
      </aside>
    </div>
  );
};

// ----------------------------------------------------------------------------
// ItemCard — gère le fallback onError pour les images inexistantes.
// ----------------------------------------------------------------------------

interface ItemCardProps {
  src: string;
  fallbackSrc?: string;
  label: string;
  price?: number;
  selected: boolean;
  onClick: () => void;
}

const ItemCard: React.FC<ItemCardProps> = ({ src, fallbackSrc, label, price, selected, onClick }) => {
  const [broken, setBroken] = useState(false);
  const [fallbackBroken, setFallbackBroken] = useState(false);
  return (
    <button
      className={`utilshop-item ${selected ? 'selected' : ''}`}
      onClick={onClick}
      type="button"
    >
      <div className="utilshop-item-image">
        {broken && fallbackSrc && !fallbackBroken ? (
          <img
            src={fallbackSrc}
            alt="Aperçu de tête générique"
            className="utilshop-item-fallback-image"
            loading="lazy"
            draggable={false}
            onError={() => setFallbackBroken(true)}
          />
        ) : broken ? (
          <div className="utilshop-item-fallback">
            <div className="utilshop-item-fallback-head" aria-hidden="true">
              <span className="utilshop-item-fallback-face" />
              <span className="utilshop-item-fallback-shoulders" />
            </div>
          </div>
        ) : (
          <img src={src} alt={label} loading="lazy" draggable={false} onError={() => setBroken(true)} />
        )}
      </div>
      <div className="utilshop-item-info">
        <span className="utilshop-item-label">{label}</span>
        {price !== undefined && <span className="utilshop-item-price">{price}$</span>}
      </div>
      {selected && (
        <div className="utilshop-item-check"><Check size={14} /></div>
      )}
    </button>
  );
};

export default UtilsShopView;
