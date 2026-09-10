import React, { useState, useEffect, useCallback, useRef, useMemo } from 'react';
import {
  X, ShoppingCart, Search, ChevronLeft, ChevronRight,
  Shirt, CreditCard, Banknote, Trash2, RotateCw, Check,
  ShieldCheck, Eye, Glasses, Watch, Link, CircleDot,
  Crown, Backpack, Footprints, Layers, Image, Hand,
  Download, Upload, Copy, ClipboardPaste, Weight, Swords,
  Plus, Minus
} from 'lucide-react';
import { ShopProps, ShopData, CartItem, CategoryDef, BagInfo } from './types';
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

/* ---- Category definitions ----
   Bento layouts target a 12-col grid; rows are sized to fill the panel.
   Clothes  → 4 rows | Accessories → 4 rows
*/
const CLOTHES_CATEGORIES: CategoryDef[] = [
  // Row 1-2 : T-Shirt en hero carré (8×2)  +  Torse / Calques à droite
  { key: 'tshirt_1', label: 'T-Shirt', icon: 'shirt', group: 'Haut', span: 8, rowSpan: 2 },
  { key: 'torso_1', label: 'Torse', icon: 'layers', group: 'Haut', span: 4 },
  { key: 'decals_1', label: 'Calques', icon: 'image', group: 'Haut', span: 4 },
  // Row 3 : Pantalon en banderole pleine largeur
  { key: 'pants_1', label: 'Pantalon', icon: 'footprints', group: 'Bas', span: 12 },
  // Row 4 : Bras + Chaussures côte à côte
  { key: 'arms', label: 'Bras', icon: 'hand', group: 'Haut', span: 6 },
  { key: 'shoes_1', label: 'Chaussures', icon: 'footprints', group: 'Bas', span: 6 },
];

const ACCESSORIES_CATEGORIES: CategoryDef[] = [
  // Row 1-2 : Chapeau en hero (6×2)  +  Masque / Lunettes paysage à droite
  { key: 'helmet_1', label: 'Chapeau', icon: 'crown', group: 'Tête', span: 6, rowSpan: 2 },
  { key: 'mask_1', label: 'Masque', icon: 'eye', group: 'Tête', span: 6 },
  { key: 'glasses_1', label: 'Lunettes', icon: 'glasses', group: 'Tête', span: 6 },
  // Row 3 : trio carré (Boucles / Chaîne / Gilet)
  { key: 'ears_1', label: "Boucles d'oreilles", icon: 'circle', group: 'Tête', span: 4 },
  { key: 'chain_1', label: 'Chaîne', icon: 'link', group: 'Corps', span: 4 },
  { key: 'bproof_1', label: 'Gilet', icon: 'shield', group: 'Corps', span: 4 },
  // Row 4 : trio carré (Montre / Bracelet / Sac)
  { key: 'watches_1', label: 'Montre', icon: 'watch', group: 'Mains', span: 4 },
  { key: 'bracelets_1', label: 'Bracelet', icon: 'circle', group: 'Mains', span: 4 },
  { key: 'bags_1', label: 'Sac', icon: 'backpack', group: 'Corps', span: 4 },
];

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
  shirt: <Shirt size={16} />, layers: <Layers size={16} />, image: <Image size={16} />,
  hand: <Hand size={16} />, footprints: <Footprints size={16} />,
  shield: <ShieldCheck size={16} />, eye: <Eye size={16} />, glasses: <Glasses size={16} />,
  watch: <Watch size={16} />, link: <Link size={16} />, circle: <CircleDot size={16} />,
  crown: <Crown size={16} />, backpack: <Backpack size={16} />,
};

const CARD_ICON_MAP: Record<string, React.ReactNode> = {
  shirt: <Shirt size={26} />, layers: <Layers size={26} />, image: <Image size={26} />,
  hand: <Hand size={26} />, footprints: <Footprints size={26} />,
  shield: <ShieldCheck size={26} />, eye: <Eye size={26} />, glasses: <Glasses size={26} />,
  watch: <Watch size={26} />, link: <Link size={26} />, circle: <CircleDot size={26} />,
  crown: <Crown size={26} />, backpack: <Backpack size={26} />,
};

/* ---- Component ---- */
const Shop: React.FC<ShopProps> = ({ visible, onClose, primaryColor }) => {
  const [shopData, setShopData] = useState<ShopData | null>(null);
  const [view, setView] = useState<'categories' | 'items'>('categories');
  const [activeCategory, setActiveCategory] = useState<string>('');
  const [cart, setCart] = useState<Record<string, CartItem>>({});
  const [variation, setVariation] = useState(0);
  const [maxVariation, setMaxVariation] = useState(0);
  const [searchQuery, setSearchQuery] = useState('');
  const [hiding, setHiding] = useState(false);
  const [mounted, setMounted] = useState(false);
  const [loadedImages, setLoadedImages] = useState<Record<string, number[]>>({});
  const [loadingCategory, setLoadingCategory] = useState(false);
  const [isDragging, setIsDragging] = useState(false);
  const [selectedItem, setSelectedItem] = useState<number | null>(null);
  const [importCode, setImportCode] = useState('');
  const [showImportModal, setShowImportModal] = useState(false);
  const [notification, setNotification] = useState<string | null>(null);
  const lastMouseXRef = useRef(0);
  const gridRef = useRef<HTMLDivElement>(null);
  const notifTimerRef = useRef<ReturnType<typeof setTimeout>>();

  const accent = primaryColor || '#3498db';

  const categories = useMemo(() =>
    shopData?.mode === 'accessories' ? ACCESSORIES_CATEGORIES : CLOTHES_CATEGORIES
    , [shopData?.mode]);

  const groups = useMemo(() => {
    const map = new Map<string, CategoryDef[]>();
    categories.forEach(cat => {
      if (!map.has(cat.group)) map.set(cat.group, []);
      map.get(cat.group)!.push(cat);
    });
    return Array.from(map.entries());
  }, [categories]);

  const activeCatDef = useMemo(
    () => categories.find(c => c.key === activeCategory),
    [categories, activeCategory]
  );

  const prefix = shopData?.mode === 'accessories' ? 'shop:acc:' : 'shop:clothes:';

  /* ---- Notifications ---- */
  const showNotif = useCallback((msg: string) => {
    setNotification(msg);
    if (notifTimerRef.current) clearTimeout(notifTimerRef.current);
    notifTimerRef.current = setTimeout(() => setNotification(null), 3000);
  }, []);

  /* ---- NUI messages ---- */
  useEffect(() => {
    const handle = (event: MessageEvent) => {
      const { action, data } = event.data;
      if (action === 'shop:open' && data) {
        const skins = typeof data.skins === 'string' ? JSON.parse(data.skins) : data.skins;
        const mode = data.mode || 'clothes';
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
        });
        setCart({});
        setView('categories');
        setActiveCategory('');
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
    if (loadedImages[category]) return;
    setLoadingCategory(true);
    const ids: number[] = [];
    let consecutiveFails = 0;

    for (let i = 0; consecutiveFails < 1; i++) {
      const url = `nui://null-ui/web/images/clothes/${sex}/${category}/${i}.webp`;
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
  }, [loadedImages]);

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
    setView('items');
    setSearchQuery('');
    setSelectedItem(null);
    setVariation(0);
    setMaxVariation(0);
    nuiCall(`${prefix}changeCategory`, { category });
  }, [prefix]);

  const handleBackToCategories = useCallback(() => {
    setView('categories');
    setSearchQuery('');
    setSelectedItem(null);
    setVariation(0);
    setMaxVariation(0);
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
        // Skip "naked" values for clothes
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
    if (cartCount === 0) { showNotif('Le panier est vide'); return; }
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
      showNotif('Code invalide');
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

  /* ---- Rotation ---- */
  const handleRotStart = useCallback((e: React.MouseEvent) => {
    if ((e.target as HTMLElement).closest('.shop-panel, .shop-cart-panel')) return;
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
      if (e.key === 'Escape' && visible && !hiding) handleClose();
    };
    window.addEventListener('keydown', handleKey);
    return () => window.removeEventListener('keydown', handleKey);
  }, [visible, hiding, handleClose, showImportModal]);

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

  return (
    <div
      className={`shop-overlay ${overlayClass}`}
      style={{ '--shop-accent': accent } as React.CSSProperties}
      onMouseDown={handleRotStart}
    >
      {/* Left Panel - Categories grid OR Items */}
      <div className="shop-panel">
        {view === 'categories' ? (
          <>
            <div className="shop-panel-header">
              <div className="shop-title">
                {isAccessories ? <Glasses size={18} /> : <Shirt size={18} />}
                <span>{isAccessories ? 'Accessoires' : 'Vêtements'}</span>
              </div>
              <button className="shop-close-btn" onClick={handleClose}><X size={16} /></button>
            </div>

            {/* Category bento grid */}
            <div className="shop-cat-bento-scroll">
              <div className={`shop-cat-bento ${isAccessories ? 'is-accessories' : 'is-clothes'}`}>
                {categories.map(cat => (
                  <button
                    key={cat.key}
                    className={`shop-cat-card ${cart[cat.key] ? 'in-cart' : ''}`}
                    style={{
                      gridColumn: `span ${cat.span || 4}`,
                      gridRow: cat.rowSpan ? `span ${cat.rowSpan}` : undefined,
                    }}
                    onClick={() => handleCategoryChange(cat.key)}
                    onMouseEnter={() => soundManager.play('hover')}
                  >
                    {/* TODO: image de fond par catégorie — <img className="shop-cat-card-img" src={...} /> */}
                    <div className="shop-cat-card-shade" />
                    <div className="shop-cat-card-body">
                      <span className="shop-cat-card-group">{cat.group}</span>
                      <span className="shop-cat-card-label">{cat.label}</span>
                    </div>
                    {cart[cat.key] && (
                      <div className="shop-cat-card-badge"><ShoppingCart size={10} /></div>
                    )}
                    <ChevronRight className="shop-cat-card-arrow" size={16} />
                  </button>
                ))}
              </div>
            </div>
          </>
        ) : (
          <>
            <div className="shop-panel-header">
              <button className="shop-back-btn" onClick={handleBackToCategories}>
                <ChevronLeft size={16} />
              </button>
              <div className="shop-title">
                {ICON_MAP[activeCatDef?.icon || 'shirt']}
                <span>{activeCatDef?.label || ''}</span>
              </div>
              <button className="shop-close-btn" onClick={handleClose}><X size={16} /></button>
            </div>

            {/* Toolbar: search + variation */}
            <div className="shop-toolbar">
              <div className="shop-search">
                <Search size={14} />
                <input
                  type="number"
                  placeholder="Rechercher N°..."
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

            {/* Items Grid */}
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
                        className={`shop-item ${isActive ? 'active' : ''} ${inCart ? 'in-cart' : ''}`}
                        onClick={() => selectItem(activeCategory, id)}
                        onMouseEnter={() => soundManager.play('hover')}
                      >
                        <img
                          src={`nui://null-ui/web/images/clothes/${shopData.playerSex}/${activeCategory}/${id}.webp`}
                          alt={`#${id}`}
                          loading="lazy"
                          draggable={false}
                          onError={(e) => { (e.target as HTMLImageElement).style.opacity = '0'; }}
                        />
                        <div className="shop-item-footer">
                          <span className="shop-item-id">#{id}</span>
                          <span className="shop-item-price">{price}$</span>
                        </div>
                        {isActive && <div className="shop-item-check"><Check size={10} /></div>}
                        {inCart && <div className="shop-item-cart-badge"><ShoppingCart size={9} /></div>}
                        {bagInfoData && (
                          <div className="shop-item-bag-info">
                            <span><Weight size={10} /> {bagInfoData.weight}kg</span>
                            {bagInfoData.weapon && <span className="shop-bag-weapon"><Swords size={10} /></span>}
                          </div>
                        )}
                      </div>
                    );
                  })}
                  {filteredImages.length === 0 && !loadingCategory && (
                    <div className="shop-empty">
                      <Search size={28} />
                      <span>Aucun article trouvé</span>
                    </div>
                  )}
                </div>
              )}
            </div>

            {/* Add to cart bar */}
            <div className="shop-add-bar">
              <button
                className="shop-add-btn"
                onClick={addToCart}
                disabled={selectedItem === null}
              >
                <Plus size={14} /> Ajouter au panier
              </button>
            </div>
          </>
        )}
      </div>

      {/* Right Panel - Cart */}
      <div className="shop-cart-panel">
        <div className="shop-cart-header">
          <div className="shop-cart-title">
            <ShoppingCart size={16} />
            <span>Panier</span>
            {cartCount > 0 && <span className="shop-cart-count">{cartCount}</span>}
          </div>
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

        <div className="shop-cart-items">
          {cartCount === 0 ? (
            <div className="shop-cart-empty">
              <ShoppingCart size={28} />
              <span>Panier vide</span>
              <p>Sélectionnez des articles et ajoutez-les</p>
            </div>
          ) : (
            Object.entries(cart).map(([category, item]) => {
              const cat = categories.find(c => c.key === category);
              const itemPrice = getPrice(category, item.item);
              const bagInfoData = category === 'bags_1' ? getBagInfo(item.item) : null;
              return (
                <div key={category} className="shop-cart-item">
                  <div className="shop-cart-item-img">
                    <img
                      src={`nui://null-ui/web/images/clothes/${shopData.playerSex}/${category}/${item.item}.webp`}
                      alt={cat?.label}
                      draggable={false}
                      onError={(e) => { (e.target as HTMLImageElement).style.opacity = '0'; }}
                    />
                  </div>
                  <div className="shop-cart-item-info">
                    <span className="shop-cart-item-name">{cat?.label} #{item.item}</span>
                    <span className="shop-cart-item-meta">Variation {item.variation}</span>
                    {bagInfoData && (
                      <span className="shop-cart-item-bag">
                        <Weight size={10} /> {bagInfoData.weight}kg
                        {bagInfoData.weapon && <> · <Swords size={10} /> Arme</>}
                      </span>
                    )}
                  </div>
                  <span className="shop-cart-item-price">{itemPrice}$</span>
                  <button className="shop-cart-item-remove" onClick={() => removeFromCart(category)}>
                    <X size={12} />
                  </button>
                </div>
              );
            })
          )}
        </div>

        {cartCount > 0 && (
          <div className="shop-cart-footer">
            <div className="shop-cart-total">
              <span>Total</span>
              <span className="shop-cart-total-price">{cartTotal}$</span>
            </div>
            <div className="shop-cart-pay">
              <button className="shop-pay-btn shop-pay-cash" onClick={() => { soundManager.play('success'); handlePay('cash'); }}>
                <Banknote size={14} /> Liquide
              </button>
              <button className="shop-pay-btn shop-pay-bank" onClick={() => { soundManager.play('success'); handlePay('bank'); }}>
                <CreditCard size={14} /> Carte
              </button>
            </div>
          </div>
        )}
      </div>

      {/* Rotation hint */}
      <div className="shop-rotation-hint">
        <RotateCw size={12} />
        <span>Glisser pour tourner</span>
      </div>

      {/* Notification */}
      {notification && (
        <div className="shop-notification">
          <Check size={14} />
          <span>{notification}</span>
        </div>
      )}

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
