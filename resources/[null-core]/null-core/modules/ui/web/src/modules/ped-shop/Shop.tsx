import React, { useState, useEffect, useCallback, useRef, useMemo } from 'react';
import { generateAccentVars, hexToRgba } from '@/utils/accentColors';
import {
  X, ShoppingCart, Search, ChevronLeft, ChevronRight, ChevronRight as ArrowRight,
  Shirt, CreditCard, Banknote, Trash2, RotateCw, Check,
  ShieldCheck, Eye, Glasses, Watch, Link, CircleDot,
  Crown, Backpack, Footprints, Layers, Image as ImageIcon, Hand,
  Download, Upload, Copy, ClipboardPaste, Weight, Swords,
  Plus, AlertCircle
} from 'lucide-react';
import { ShopProps, ShopData, CartItem, CategoryDef, BagInfo, ShopBrand } from './types';
import { cacheImg, useCacheVersion } from '@shared/cacheVersion';
import './Shop.css';
import { soundManager } from '@core/SoundManager';

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

/* ---- Category definitions ---- */
const CLOTHES_CATEGORIES: CategoryDef[] = [
  { key: 'tshirt_1', label: 'T-Shirt', icon: 'shirt', group: 'Haut' },
  { key: 'torso_1', label: 'Torse', icon: 'layers', group: 'Haut' },
  { key: 'decals_1', label: 'Calques', icon: 'image', group: 'Haut' },
  { key: 'arms', label: 'Bras', icon: 'hand', group: 'Haut' },
  { key: 'pants_1', label: 'Pantalon', icon: 'footprints', group: 'Bas' },
  { key: 'shoes_1', label: 'Chaussures', icon: 'footprints', group: 'Bas' },
];

const ACCESSORIES_CATEGORIES: CategoryDef[] = [
  { key: 'helmet_1', label: 'Chapeau', icon: 'crown', group: 'Tête' },
  { key: 'mask_1', label: 'Masque', icon: 'eye', group: 'Tête' },
  { key: 'glasses_1', label: 'Lunettes', icon: 'glasses', group: 'Tête' },
  { key: 'ears_1', label: "Boucles d'oreilles", icon: 'circle', group: 'Tête' },
  { key: 'chain_1', label: 'Chaîne', icon: 'link', group: 'Corps' },
  { key: 'bproof_1', label: 'Gilet', icon: 'shield', group: 'Corps' },
  { key: 'bags_1', label: 'Sac', icon: 'backpack', group: 'Corps' },
  { key: 'watches_1', label: 'Montre', icon: 'watch', group: 'Mains' },
  { key: 'bracelets_1', label: 'Bracelet', icon: 'circle', group: 'Mains' },
];

/* Catégories mises en avant (cards bento plus grandes) par mode */
const FEATURED_CATEGORIES: Record<string, string[]> = {
  clothes: ['torso_1', 'pants_1'],
  accessories: ['mask_1', 'bags_1'],
};

const VARIATION_MAP: Record<string, string> = {
  tshirt_1: 'tshirt_2', torso_1: 'torso_2', arms: 'arms',
  pants_1: 'pants_2', shoes_1: 'shoes_2', decals_1: 'decals_2',
  mask_1: 'mask_2', bproof_1: 'bproof_2', chain_1: 'chain_2',
  helmet_1: 'helmet_2', ears_1: 'ears_2', glasses_1: 'glasses_2',
  watches_1: 'watches_2', bracelets_1: 'bracelets_2', bags_1: 'bags_2',
};

const NAKED_VALUES: Record<string, number> = {
  tshirt_1: 15, torso_1: 15, decals_1: 0, arms: 15, pants_1: 21, shoes_1: 34,
};

const ICON_MAP: Record<string, React.ReactNode> = {
  shirt: <Shirt size={16} />, layers: <Layers size={16} />, image: <ImageIcon size={16} />,
  hand: <Hand size={16} />, footprints: <Footprints size={16} />,
  shield: <ShieldCheck size={16} />, eye: <Eye size={16} />, glasses: <Glasses size={16} />,
  watch: <Watch size={16} />, link: <Link size={16} />, circle: <CircleDot size={16} />,
  crown: <Crown size={16} />, backpack: <Backpack size={16} />,
};

/* ---- Component ---- */
const Shop: React.FC<ShopProps> = ({ visible, onClose, primaryColor }) => {
  const [shopData, setShopData] = useState<ShopData | null>(null);
  const [view, setView] = useState<'home' | 'category'>('home');
  const [activeCategory, setActiveCategory] = useState<string>('');
  const [cart, setCart] = useState<Record<string, CartItem>>({});
  const [variation, setVariation] = useState(0);
  const [maxVariation, setMaxVariation] = useState(0);
  const [searchQuery, setSearchQuery] = useState('');
  const [hiding, setHiding] = useState(false);
  const [mounted, setMounted] = useState(false);
  const [loadedImages, setLoadedImages] = useState<Record<string, number[]>>({});
  const cacheVersion = useCacheVersion();
  const [loadingCategory, setLoadingCategory] = useState(false);
  const [isDragging, setIsDragging] = useState(false);
  const [selectedItem, setSelectedItem] = useState<number | null>(null);
  const [importCode, setImportCode] = useState('');
  const [showImportModal, setShowImportModal] = useState(false);
  const [notification, setNotification] = useState<{ message: string; type: 'success' | 'error' } | null>(null);
  const lastMouseXRef = useRef(0);
  const gridRef = useRef<HTMLDivElement>(null);
  const notifTimerRef = useRef<ReturnType<typeof setTimeout>>();

  const brand: ShopBrand | undefined = shopData?.brand;
  // Le menu reprend la couleur du serveur (config Global). La marque ne
  // sert plus qu'à afficher une bannière + un nom + une courte description.
  const accent = primaryColor || '#f5a623';
  const brandBanner = brand?.banner ? cacheImg(brand.banner) : null;

  const shopAccentVars = useMemo(() => generateAccentVars('--shop-accent', accent), [accent]);
  // Génère manuellement toutes les déclinaisons d'opacité de l'accent serveur
  // (10/15/.../90) en rgba, pour pouvoir remplacer tous les `color-mix()`
  // côté CSS — la version de CEF embarquée dans FiveM ne supporte pas la
  // fonction `color-mix()`.
  const shopBrandVars = useMemo(() => {
    const vars: Record<string, string> = {
      '--shop-brand-bg': accent,
      '--shop-brand-accent': accent,
    };
    const isHex = accent.startsWith('#') && accent.length >= 7;
    const opacities = [10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60, 65, 70, 90];
    for (const o of opacities) {
      vars[`--shop-brand-${o}`] = isHex ? hexToRgba(accent, o) : accent;
    }
    return vars as React.CSSProperties;
  }, [accent]);

  const categories = useMemo(() =>
    shopData?.mode === 'accessories' ? ACCESSORIES_CATEGORIES : CLOTHES_CATEGORIES
    , [shopData?.mode]);

  const prefix = shopData?.mode === 'accessories' ? 'shop:acc:' : 'shop:clothes:';

  /* ---- Notifications ---- */
  const showNotif = useCallback((message: string, type: 'success' | 'error' = 'success') => {
    setNotification({ message, type });
    if (notifTimerRef.current) clearTimeout(notifTimerRef.current);
    notifTimerRef.current = setTimeout(() => setNotification(null), 3000);
  }, []);

  /* ---- NUI messages ---- */
  useEffect(() => {
    const handle = (event: MessageEvent) => {
      const { action, data } = event.data;
      if (action === 'shop:open' && data) {
        const mode = data.mode || 'clothes';
        // Modes utils gérés par <UtilsShopView /> — on ignore ici.
        if (mode === 'barber' || mode === 'makeup' || mode === 'tattoo') return;
        const skins = typeof data.skins === 'string' ? JSON.parse(data.skins) : data.skins;
        setShopData({
          mode,
          playerSex: data.playerSex || 'male',
          skins,
          prices: {
            mainPrice: parseInt(data.prices?.MainPrice) || 10,
            categoryPrices: data.prices?.CategoryMainPrice || {},
            customPrices: data.prices?.CustomPrice || {},
          },
          blackList: data.blackList || {},
          bagInfo: data.bagInfo || {},
          brand: data.brand || undefined,
        });
        setCart({});
        setView('home');
        const cats = mode === 'accessories' ? ACCESSORIES_CATEGORIES : CLOTHES_CATEGORIES;
        setActiveCategory(cats[0]?.key || '');
        setVariation(0);
        setMaxVariation(0);
        setSearchQuery('');
        setLoadedImages({});
        setSelectedItem(null);
        setShowImportModal(false);
        setImportCode('');
      } else if (action === 'shop:close') {
        setShopData(null);
      }
    };
    window.addEventListener('message', handle);
    return () => window.removeEventListener('message', handle);
  }, []);

  /* ---- Mount animation ---- */
  useEffect(() => {
    if (visible) setMounted(true);
    if (!visible) setMounted(false);
  }, [visible]);

  /* ---- Load images for category ---- */
  const loadImagesForCategory = useCallback(async (category: string, sex: string) => {
    setLoadingCategory(true);
    const ids: number[] = [];
    let consecutiveFails = 0;

    for (let i = 0; consecutiveFails < 1; i++) {
      const url = cacheImg(`clothes/${sex}/${category}/${i}.webp`);
      try {
        const exists = await new Promise<boolean>((resolve) => {
          const img = new window.Image();
          img.onload = () => resolve(true);
          img.onerror = () => resolve(false);
          img.src = url;
        });
        if (exists) { ids.push(i); consecutiveFails = 0; }
        else { consecutiveFails++; }
      } catch { consecutiveFails++; }
    }

    setLoadedImages(prev => ({ ...prev, [category]: ids }));
    setLoadingCategory(false);
  }, [cacheVersion]);

  useEffect(() => {
    setLoadedImages({});
  }, [cacheVersion]);

  useEffect(() => {
    if (shopData && activeCategory) {
      loadImagesForCategory(activeCategory, shopData.playerSex);
    }
  }, [activeCategory, shopData, loadImagesForCategory]);

  /* ---- Fetch max variations ---- */
  const fetchMaxVariations = useCallback(async (category: string) => {
    const result = await nuiCall(`${prefix}getMaxVariations`, { category });
    setMaxVariation(result?.max || 0);
  }, [prefix]);

  /* ---- Price ---- */
  const getPrice = useCallback((category: string, itemId: number): number => {
    if (!shopData) return 0;
    const { prices, playerSex } = shopData;
    if (prices.customPrices[playerSex]?.[category]?.[itemId] !== undefined)
      return prices.customPrices[playerSex][category][itemId];
    if (prices.categoryPrices[playerSex]?.[category] !== undefined)
      return prices.categoryPrices[playerSex][category] as unknown as number;
    return prices.mainPrice || 0;
  }, [shopData]);

  const isBlacklisted = useCallback((category: string, itemId: number): boolean => {
    if (!shopData?.blackList) return false;
    return shopData.blackList[shopData.playerSex]?.[category]?.[itemId] === true;
  }, [shopData]);

  /* ---- Bag info ---- */
  const getBagInfo = useCallback((itemId: number): BagInfo | null => {
    if (!shopData?.bagInfo) return null;
    const sex = shopData.playerSex;
    return shopData.bagInfo[sex]?.[itemId] || null;
  }, [shopData]);

  /* ---- Select item (preview) ---- */
  const selectItem = useCallback((category: string, itemId: number) => {
    setSelectedItem(itemId);
    setVariation(0);
    nuiCall(`${prefix}updateSkin`, { type: category, number: itemId });
    fetchMaxVariations(category);
  }, [prefix, fetchMaxVariations]);

  /* ---- Variation change ---- */
  const changeVariation = useCallback(async (direction: number) => {
    if (selectedItem === null) return;
    if (maxVariation <= 0) return;

    let newVal = variation + direction;
    if (newVal < 0) newVal = maxVariation - 1;
    if (newVal >= maxVariation) newVal = 0;

    setVariation(newVal);
    const variationType = VARIATION_MAP[activeCategory];
    if (variationType) {
      nuiCall(`${prefix}updateVariation`, { type: variationType, number: newVal });
    }
  }, [activeCategory, variation, maxVariation, selectedItem, prefix]);

  /* ---- Category change ---- */
  const handleCategoryChange = useCallback((category: string) => {
    setActiveCategory(category);
    setView('category');
    setSearchQuery('');
    setSelectedItem(null);
    setVariation(0);
    setMaxVariation(0);
    nuiCall(`${prefix}changeCategory`, { category });
  }, [prefix]);

  /* ---- Retour à l'accueil (bento des catégories) ---- */
  const goHome = useCallback(() => {
    setView('home');
    setSelectedItem(null);
    setSearchQuery('');
  }, []);

  /* ---- Cart ---- */
  const addToCart = useCallback(() => {
    if (selectedItem === null) return;
    setCart(prev => ({
      ...prev,
      [activeCategory]: { category: activeCategory, item: selectedItem, variation }
    }));
    showNotif('Article ajouté au panier');
  }, [activeCategory, selectedItem, variation, showNotif]);

  const removeFromCart = useCallback((category: string) => {
    setCart(prev => {
      const n = { ...prev };
      delete n[category];
      return n;
    });
  }, []);

  const clearCart = useCallback(() => setCart({}), []);

  const cartTotal = useMemo(() => {
    return Object.entries(cart).reduce((total, [cat, item]) => total + getPrice(cat, item.item), 0);
  }, [cart, getPrice]);

  const cartCount = Object.keys(cart).length;

  /* ---- Import current outfit into cart ---- */
  const importCurrentOutfit = useCallback(() => {
    if (!shopData) return;
    const newCart: Record<string, CartItem> = {};
    categories.forEach(cat => {
      const val = shopData.skins[cat.key];
      if (val !== undefined && val !== null) {
        const varKey = VARIATION_MAP[cat.key];
        const varVal = varKey ? (shopData.skins[varKey] ?? 0) : 0;
        if (shopData.mode === 'clothes') {
          const nakedVal = NAKED_VALUES[cat.key];
          if (nakedVal !== undefined && val === nakedVal) return;
        }
        newCart[cat.key] = { category: cat.key, item: val, variation: varVal };
      }
    });
    setCart(newCart);
    showNotif('Tenue actuelle importée dans le panier');
  }, [shopData, categories, showNotif]);

  /* ---- Export/Import codes ---- */
  const exportCart = useCallback(() => {
    if (cartCount === 0) { showNotif('Le panier est vide', 'error'); return; }
    if (!shopData) return;
    const outfitData = {
      m: shopData.mode === 'accessories' ? 'a' : 'c',
      s: shopData.playerSex === 'male' ? 'm' : 'f',
      i: Object.fromEntries(
        Object.entries(cart).map(([cat, item]) => [cat, [item.item, item.variation]])
      ),
    };
    const code = btoa(JSON.stringify(outfitData));
    showNotif('Code copié dans le presse-papier !');
    nuiCall('copyToClipboard', { text: code });
  }, [cart, cartCount, shopData, showNotif]);

  const importCart = useCallback(() => {
    if (!importCode.trim()) return;
    try {
      const decoded = JSON.parse(atob(importCode.trim()));
      if (!decoded.i || typeof decoded.i !== 'object') throw new Error('Invalid');
      const newCart: Record<string, CartItem> = {};
      Object.entries(decoded.i).forEach(([cat, val]: [string, any]) => {
        if (Array.isArray(val) && val.length >= 2) {
          newCart[cat] = { category: cat, item: val[0], variation: val[1] };
        }
      });
      setCart(prev => ({ ...prev, ...newCart }));
      setShowImportModal(false);
      setImportCode('');
      showNotif(`${Object.keys(newCart).length} articles importés !`);
    } catch {
      showNotif('Code invalide', 'error');
    }
  }, [importCode, showNotif]);

  /* ---- Payment ---- */
  const handlePay = useCallback((method: 'cash' | 'bank') => {
    if (cartCount === 0) return;
    if (shopData?.mode === 'clothes') {
      nuiCall(`${prefix}pay`, { items: cart, paymentMethod: method });
    } else {
      nuiCall(`${prefix}buyAccessories`, { items: cart, method });
    }
  }, [cart, cartCount, prefix, shopData?.mode]);

  /* ---- Close ---- */
  const handleClose = useCallback(() => {
    if (hiding) return;
    setHiding(true);
    setTimeout(() => {
      setHiding(false);
      onClose();
      nuiCall(`${prefix}exit`, { changeSkin: false });
    }, 350);
  }, [onClose, hiding, prefix]);

  /* ---- Rotation (drag on overlay area) ---- */
  const handleRotStart = useCallback((e: React.MouseEvent) => {
    if ((e.target as HTMLElement).closest('.shop-container, .shop-modal-overlay, .shop-notification')) return;
    setIsDragging(true);
    lastMouseXRef.current = e.clientX;
    nuiCall(`${prefix}startRotation`, { mouseX: e.clientX });
  }, [prefix]);

  useEffect(() => {
    const move = (e: MouseEvent) => {
      if (isDragging) {
        nuiCall(`${prefix}updateRotation`, { mouseX: e.clientX });
        lastMouseXRef.current = e.clientX;
      }
    };
    const up = () => {
      if (isDragging) {
        setIsDragging(false);
        nuiCall(`${prefix}stopRotation`, {});
      }
    };
    window.addEventListener('mousemove', move);
    window.addEventListener('mouseup', up);
    return () => { window.removeEventListener('mousemove', move); window.removeEventListener('mouseup', up); };
  }, [isDragging, prefix]);

  /* ---- Escape ---- */
  useEffect(() => {
    const handleKey = (e: KeyboardEvent) => {
      if (showImportModal && e.key === 'Escape') { setShowImportModal(false); return; }
      if (e.key === 'Escape' && visible && !hiding) {
        if (view === 'category') { goHome(); return; }
        handleClose();
      }
    };
    window.addEventListener('keydown', handleKey);
    return () => window.removeEventListener('keydown', handleKey);
  }, [visible, hiding, handleClose, showImportModal, view, goHome]);

  /* ---- Filter images ---- */
  const filteredImages = useMemo(() => {
    return (loadedImages[activeCategory] || []).filter(id => {
      if (isBlacklisted(activeCategory, id)) return false;
      if (searchQuery) return String(id).includes(searchQuery);
      return true;
    });
  }, [loadedImages, activeCategory, searchQuery, isBlacklisted]);

  if (!visible || !shopData) return null;

  const isAccessories = shopData.mode === 'accessories';
  const overlayClass = hiding ? 'shop-hiding' : mounted ? 'shop-showing shop-visible' : '';
  const activeCatLabel = categories.find(c => c.key === activeCategory)?.label || '';

  /* ---- Bannière (style bento boutique : image + nom + courte description) ---- */
  const headerName = brand?.name || (isAccessories ? 'Accessoires' : 'Vêtements');
  const headerDesc = brand?.tagline || (isAccessories ? 'Personnalisez vos accessoires' : 'Composez votre tenue');

  const renderBrandHeader = () => (
    <div className="shop-banner">
      {brandBanner && (
        <img
          className="shop-banner-img"
          src={brandBanner}
          alt=""
          onError={(e) => { (e.target as HTMLImageElement).style.display = 'none'; }}
        />
      )}
      <div className="shop-banner-shade" />
      <button className="shop-banner-close" onClick={handleClose} title="Fermer">
        <X size={16} />
      </button>
      <div className="shop-banner-text">
        <span className="shop-banner-eyebrow">{isAccessories ? 'Accessoires' : 'Vêtements'}</span>
        <h1 className="shop-banner-title">{headerName}</h1>
        <p className="shop-banner-desc">{headerDesc}</p>
      </div>
    </div>
  );

  /* ---- Accueil : catégories en bento (style boutique) ---- */
  const featuredKeys = FEATURED_CATEGORIES[shopData.mode] || [];
  const orderedCats = [...categories].sort((a, b) => {
    const af = featuredKeys.includes(a.key) ? 0 : 1;
    const bf = featuredKeys.includes(b.key) ? 0 : 1;
    return af - bf;
  });

  const renderHome = () => (
    <div className="shop-items-scroll shop-home-scroll">
      <div className={`shop-bento-grid shop-bento-grid--${shopData.mode}`}>
        {orderedCats.map(cat => {
          const featured = featuredKeys.includes(cat.key);
          const inCart = !!cart[cat.key];
          return (
            <button
              key={cat.key}
              className={`shop-bento-card ${featured ? 'featured' : ''} ${inCart ? 'in-cart' : ''}`}
              onClick={() => { soundManager.play('hover'); handleCategoryChange(cat.key); }}
              onMouseEnter={() => soundManager.play('hover')}
            >
              <img
                className="shop-bento-img"
                src={cacheImg(`shopui/categories/${cat.key}.webp`)}
                alt=""
                draggable={false}
                onError={(e) => { (e.target as HTMLImageElement).style.display = 'none'; }}
              />
              {/* <div className="shop-bento-icon">{ICON_MAP[cat.icon]}</div> */}
              <div className="shop-bento-shade" />
              <div className="shop-bento-body">
                <span className="shop-bento-eyebrow">{cat.group}</span>
                <div className="shop-bento-foot">
                  <h3 className="shop-bento-title">{cat.label}</h3>
                  <span className="shop-bento-cta"><ArrowRight size={featured ? 16 : 14} /></span>
                </div>
              </div>
              {inCart && <div className="shop-bento-badge"><Check size={11} /></div>}
            </button>
          );
        })}
      </div>
    </div>
  );

  return (
    <div
      className={`shop-overlay ${overlayClass}`}
      style={{ ...shopAccentVars, ...shopBrandVars } as React.CSSProperties}
      onMouseDown={handleRotStart}
    >
      {/* === Main container === */}
      <div className="shop-container">
        {renderBrandHeader()}
        <div className="shop-brand-sep" aria-hidden />

        {view === 'home' ? (
          <>
            <div className="shop-content-header">
              <div className="shop-content-header-info">
                <h2>Catégories</h2>
                <p>Choisissez une catégorie à personnaliser</p>
              </div>
            </div>
            {renderHome()}
          </>
        ) : (
          <>
            <div className="shop-content-header">
              <div className="shop-content-header-left">
                <button className="shop-back-btn" onClick={goHome} title="Retour">
                  <ChevronLeft size={16} />
                  <span>Retour</span>
                </button>
                <div className="shop-content-header-info">
                  <h2>{activeCatLabel}</h2>
                  <p>Sélectionnez un article puis ajoutez-le au panier</p>
                </div>
              </div>
              <div className="shop-toolbar">
                <div className="shop-search">
                  <Search size={14} />
                  <input
                    type="number"
                    placeholder="N°..."
                    value={searchQuery}
                    onChange={e => setSearchQuery(e.target.value)}
                  />
                </div>
                <div className="shop-variation">
                  <button onClick={() => changeVariation(-1)} disabled={selectedItem === null || maxVariation <= 0}>
                    <ChevronLeft size={14} />
                  </button>
                  <span>Var. {variation}</span>
                  <button onClick={() => changeVariation(1)} disabled={selectedItem === null || maxVariation <= 0}>
                    <ChevronRight size={14} />
                  </button>
                </div>
              </div>
            </div>

            <div className="shop-items-scroll" ref={gridRef}>
              {loadingCategory && !loadedImages[activeCategory] ? (
                <div className="shop-loading">
                  <RotateCw size={22} className="shop-spin" />
                  <span>Chargement...</span>
                </div>
              ) : (
                <div className="shop-items-grid">
                  {filteredImages.map(id => {
                    const isActive = selectedItem === id;
                    const price = getPrice(activeCategory, id);
                    const inCart = cart[activeCategory]?.item === id;
                    const bagInfoData = activeCategory === 'bags_1' ? getBagInfo(id) : null;

                    return (
                      <div
                        key={id}
                        className={`shop-item-card ${isActive ? 'active' : ''} ${inCart ? 'in-cart' : ''}`}
                        onClick={() => selectItem(activeCategory, id)}
                        onMouseEnter={() => soundManager.play('hover')}
                      >
                        <div className="shop-item-image">
                          <img
                            src={cacheImg(`clothes/${shopData.playerSex}/${activeCategory}/${id}.webp`)}
                            alt={`#${id}`}
                            loading="lazy"
                            draggable={false}
                            onError={(e) => { (e.target as HTMLImageElement).style.opacity = '0'; }}
                          />
                          {bagInfoData && (
                            <div className="shop-item-bag-info">
                              <span><Weight size={10} /> {bagInfoData.weight}kg</span>
                              {bagInfoData.weapon && <span className="shop-bag-weapon"><Swords size={10} /></span>}
                            </div>
                          )}
                        </div>
                        <div className="shop-item-info">
                          <span className="shop-item-label">#{id}</span>
                          <span className="shop-item-price" style={{ color: accent }}>${price.toLocaleString()}</span>
                        </div>
                        {isActive && <div className="shop-item-check" style={{ background: accent }}><Check size={10} /></div>}
                        {inCart && <div className="shop-item-cart-badge" style={{ background: accent }}><ShoppingCart size={9} /></div>}
                      </div>
                    );
                  })}
                  {filteredImages.length === 0 && !loadingCategory && (
                    <div className="shop-empty">
                      <Search size={48} />
                      <p>Aucun article trouvé</p>
                    </div>
                  )}
                </div>
              )}
            </div>

            <div className="shop-add-bar">
              <button
                className="shop-add-btn"
                onClick={() => { soundManager.play('success'); addToCart(); }}
                disabled={selectedItem === null}
                style={selectedItem !== null ? {
                  background: "var(--shop-brand-70)",
                  borderColor: "var(--shop-brand-10)",
                  color: "#fff"
                } : undefined}
              >
                <Plus size={14} /> Ajouter au panier
              </button>
            </div>
          </>
        )}
      </div>

      {/* === Right Cart Panel === */}
      <div className="shop-cart-panel">
        {/* <div
          className="shop-brand-ambient"
          style={{ background: `radial-gradient(circle at 100% 0%, var(--shop-brand-40) 0%, transparent 55%)` }}
          aria-hidden
        /> */}

        {/* Pas de header / pas d'icône — uniquement la barre d'actions en
            haut à droite (import, export, vider). */}
        <div className="shop-cart-panel-header">
          <div className="shop-cart-actions-top">
            <button className="shop-icon-btn" onClick={importCurrentOutfit} title="Importer tenue actuelle">
              <Download size={14} />
            </button>
            <button className="shop-icon-btn" onClick={() => setShowImportModal(true)} title="Importer un code">
              <ClipboardPaste size={14} />
            </button>
            <button className="shop-icon-btn" onClick={exportCart} title="Exporter le panier">
              <Copy size={14} />
            </button>
            {cartCount > 0 && (
              <button className="shop-icon-btn shop-icon-danger" onClick={clearCart} title="Vider le panier">
                <Trash2 size={14} />
              </button>
            )}
          </div>
        </div>

        {cartCount === 0 ? (
          <div className="shop-empty shop-cart-empty">
            <ShoppingCart size={42} />
            <p>Panier vide</p>
            <small>Sélectionnez des articles puis ajoutez-les</small>
          </div>
        ) : (
          <>
            <div className="shop-cart-items">
              {Object.entries(cart).map(([category, item]) => {
                const cat = categories.find(c => c.key === category);
                const itemPrice = getPrice(category, item.item);
                const bagInfoData = category === 'bags_1' ? getBagInfo(item.item) : null;
                return (
                  <div key={category} className="shop-cart-item">
                    <div className="shop-cart-item-image">
                      <img
                        src={cacheImg(`clothes/${shopData.playerSex}/${category}/${item.item}.webp`)}
                        alt={cat?.label}
                        draggable={false}
                        onError={(e) => { (e.target as HTMLImageElement).style.opacity = '0'; }}
                      />
                    </div>
                    <div className="shop-cart-item-info">
                      <span className="shop-cart-item-label">{cat?.label} #{item.item}</span>
                      <span className="shop-cart-item-price">Variation {item.variation}</span>
                      {bagInfoData && (
                        <span className="shop-cart-item-bag">
                          <Weight size={10} /> {bagInfoData.weight}kg
                          {bagInfoData.weapon && <> · <Swords size={10} /> Arme</>}
                        </span>
                      )}
                    </div>
                    <span className="shop-cart-item-total" style={{ color: accent }}>${itemPrice.toLocaleString()}</span>
                    <button className="shop-cart-item-remove" onClick={() => removeFromCart(category)}>
                      <Trash2 size={14} />
                    </button>
                  </div>
                );
              })}
            </div>

            <div className="shop-cart-footer">
              <div className="shop-cart-total">
                <span>Total</span>
                <span className="shop-cart-total-amount" style={{ color: accent }}>${cartTotal.toLocaleString()}</span>
              </div>
              <div className="shop-cart-payment">
                <span className="shop-cart-payment-title">Méthode de paiement</span>
                <div className="shop-cart-payment-buttons">
                  <button className="shop-pay-btn cash" onClick={() => { soundManager.play('success'); handlePay('cash'); }}>
                    <Banknote size={16} />
                    <div>
                      <span>Liquide</span>
                      <small>Cash en main</small>
                    </div>
                  </button>
                  <button className="shop-pay-btn bank" onClick={() => { soundManager.play('success'); handlePay('bank'); }}>
                    <CreditCard size={16} />
                    <div>
                      <span>Carte</span>
                      <small>Compte bancaire</small>
                    </div>
                  </button>
                </div>
              </div>
            </div>
          </>
        )}

        {notification && (
          <div className={`shop-notification ${notification.type}`}>
            {notification.type === 'success' ? <Check size={16} /> : <AlertCircle size={16} />}
            <span>{notification.message}</span>
          </div>
        )}
      </div>

      {/* Rotation hint */}
      <div className="shop-rotation-hint">
        <RotateCw size={12} />
        <span>Glisser pour tourner</span>
      </div>

      {/* Import modal */}
      {showImportModal && (
        <div className="shop-modal-overlay" onClick={() => setShowImportModal(false)}>
          <div className="shop-modal" onClick={e => e.stopPropagation()}>
            <div className="shop-modal-header">
              <Upload size={16} />
              <span>Importer un code</span>
              <button onClick={() => setShowImportModal(false)}><X size={14} /></button>
            </div>
            <div className="shop-modal-body">
              <textarea
                placeholder="Collez votre code de tenue ici..."
                value={importCode}
                onChange={e => setImportCode(e.target.value)}
                rows={4}
              />
              <button className="shop-import-btn" onClick={importCart} disabled={!importCode.trim()}>
                <Download size={14} /> Importer
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default Shop;
