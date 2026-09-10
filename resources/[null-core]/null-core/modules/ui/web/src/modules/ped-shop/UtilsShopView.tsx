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

import React, { useState, useEffect, useCallback, useMemo } from 'react';
import { generateAccentVars, hexToRgba } from '@/utils/accentColors';
import {
  X, Search, ShoppingCart, CreditCard, Trash2, Check, Scissors,
} from 'lucide-react';
import { cacheImg, useCacheVersion } from '@shared/cacheVersion';
import { soundManager } from '@core/SoundManager';
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
}

// Limite d'index par utilsType pour la grille (basé sur les counts GTA V).
// onError sur l'image cache les indexes inexistants automatiquement.
const MAX_PER_TYPE: Record<string, number> = {
  hair: 80,
  beard: 30,
  eyebrows: 75,
  makeup: 75,
  lipstick: 12,
  blush: 12,
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
  primaryColor?: string;
}

const UtilsShopView: React.FC<Props> = ({ visible, onClose, primaryColor }) => {
  const [data, setData] = useState<UtilsShopData | null>(null);
  const [activeCategory, setActiveCategory] = useState<string>('');
  // barber/makeup : { hair: 12, beard: 5, ... }
  const [selected, setSelected] = useState<Record<string, number>>({});
  // tattoo : panier
  const [cart, setCart] = useState<TattooEntry[]>([]);
  const [search, setSearch] = useState('');
  const [hiding, setHiding] = useState(false);
  const [mounted, setMounted] = useState(false);
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
        setSelected({});
        setCart([]);
        setSearch('');
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

  // ---- Brand styling ------------------------------------------------------
  const brand = data?.brand;
  const brandBg = brand?.bgColor || '#1a1a1a';
  const accent = brand?.accentColor || primaryColor || '#f5a623';

  const accentVars = useMemo(
    () => generateAccentVars('--utilshop-accent', accent),
    [accent]
  );
  const brandVars = useMemo(() => {
    const vars: Record<string, string> = {
      '--utilshop-brand-bg': brandBg,
      '--utilshop-brand-accent': accent,
    };
    const isHex = brandBg.startsWith('#') && brandBg.length >= 7;
    [10, 15, 20, 25, 30, 40, 50, 60, 80].forEach(o => {
      vars[`--utilshop-brand-${o}`] = isHex ? hexToRgba(brandBg, o) : brandBg;
    });
    return vars as React.CSSProperties;
  }, [brandBg, accent]);

  const containerStyle = useMemo(() => ({
    ...(accentVars as React.CSSProperties),
    ...brandVars,
  }), [accentVars, brandVars]);

  // ---- Items computed -----------------------------------------------------
  // tattoo : filtré par zone active + search.
  // barber/makeup : 0..MAX_PER_TYPE (broken images filtrées via onError).
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
    const max = MAX_PER_TYPE[activeCategory] || 50;
    const arr: number[] = [];
    for (let i = 0; i < max; i++) arr.push(i);
    return arr;
  }, [data, activeCategory]);

  // ---- Apply (barber/makeup) ----------------------------------------------
  const handleApplyOverlay = useCallback((index: number) => {
    if (!data || data.mode === 'tattoo') return;
    setSelected(prev => ({ ...prev, [activeCategory]: index }));
    nuiCall('shop:utils:apply', { utilsType: activeCategory, variationId: index });
    soundManager.play('click');
  }, [data, activeCategory]);

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
    setMounted(false);
    setHiding(true);
    setTimeout(() => {
      nuiCall('shop:utils:exit');
      onClose();
    }, 250);
  }, [onClose]);

  const handlePay = useCallback(async () => {
    if (!data) return;
    const resp = await nuiCall('shop:utils:pay', { mode: data.mode });
    if (resp?.success) {
      soundManager.play('success');
    }
  }, [data]);

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

  return (
    <div className={`utilshop-overlay ${overlayClass}`} style={containerStyle}>
      <div className="utilshop-container">
        {/* Header brand */}
        <header className="utilshop-header">
          <div className="utilshop-brand">
            {brand?.logo
              ? <img src={cacheImg(brand.logo)} alt={brand.name} className="utilshop-brand-logo" />
              : <div className="utilshop-brand-fallback"><Scissors size={18} /></div>}
            <div className="utilshop-brand-text">
              <div className="utilshop-brand-name">{brand?.name || TITLES[data.mode]}</div>
              {brand?.tagline && <div className="utilshop-brand-tagline">{brand.tagline}</div>}
            </div>
          </div>
          <div className="utilshop-mode-pill">{TITLES[data.mode]}</div>
          <button className="utilshop-close" onClick={handleClose} aria-label="Fermer">
            <X size={18} />
          </button>
        </header>

        <div className="utilshop-body">
          {/* Sidebar catégories */}
          <aside className="utilshop-sidebar">
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
                        label={`#${i}`}
                        selected={isSelected}
                        onClick={() => handleApplyOverlay(i)}
                      />
                    );
                  })}
            </div>
          </main>

          {/* Cart aside */}
          <aside className="utilshop-cart">
            <div className="utilshop-cart-header">
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
          </aside>
        </div>
      </div>
    </div>
  );
};

// ----------------------------------------------------------------------------
// ItemCard — gère le fallback onError pour les images inexistantes.
// ----------------------------------------------------------------------------

interface ItemCardProps {
  src: string;
  label: string;
  price?: number;
  selected: boolean;
  onClick: () => void;
}

const ItemCard: React.FC<ItemCardProps> = ({ src, label, price, selected, onClick }) => {
  const [broken, setBroken] = useState(false);
  if (broken) return null;
  return (
    <button
      className={`utilshop-item ${selected ? 'selected' : ''}`}
      onClick={onClick}
      type="button"
    >
      <div className="utilshop-item-img">
        <img src={src} alt={label} loading="lazy" onError={() => setBroken(true)} />
      </div>
      <div className="utilshop-item-meta">
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
