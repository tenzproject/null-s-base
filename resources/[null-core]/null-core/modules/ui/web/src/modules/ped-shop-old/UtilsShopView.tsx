import React, { useState, useEffect, useCallback, useRef } from 'react';
import {
  X, ChevronLeft, ChevronRight, Check, Banknote,
  ShoppingCart, Scissors, Brush, PenTool,
} from 'lucide-react';
import { ShopProps } from './types';
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

type UtilsMode = 'barber' | 'makeup' | 'tattoo';
interface UtilsCategory { id: string; label: string; }
interface TattooEntry { collection: string; nameHash: string; zone: string; price: number; }
interface UtilsData {
  mode: UtilsMode;
  playerSex: 'male' | 'female';
  categories: UtilsCategory[];
  price: number;
  tattoosList: TattooEntry[];
}

const MODE_META: Record<UtilsMode, { title: string; icon: React.ReactNode }> = {
  barber: { title: 'Coiffeur',   icon: <Scissors size={18} /> },
  makeup: { title: 'Maquillage', icon: <Brush size={18} /> },
  tattoo: { title: 'Tatoueur',   icon: <PenTool size={18} /> },
};

const phStyle: React.CSSProperties = {
  display: 'flex', alignItems: 'center', justifyContent: 'center',
  width: '100%', aspectRatio: '1 / 1', minHeight: '64px',
  color: 'var(--shop-accent)', opacity: 0.85,
};

const prettyName = (nameHash: string) => nameHash.replace(/^.*_(?=[^_]+$)/, '').replace(/_/g, ' ');

const UtilsShopView: React.FC<ShopProps> = ({ visible, onClose, primaryColor }) => {
  const [data, setData] = useState<UtilsData | null>(null);
  const [view, setView] = useState<'categories' | 'items'>('categories');
  const [activeCat, setActiveCat] = useState<string>('');
  const [selected, setSelected] = useState<number | null>(null);
  const [maxVariation, setMaxVariation] = useState(0);
  const [tattooCart, setTattooCart] = useState<TattooEntry[]>([]);
  const [mounted, setMounted] = useState(false);
  const [notification, setNotification] = useState<string | null>(null);
  const notifTimer = useRef<ReturnType<typeof setTimeout>>();

  const accent = primaryColor || '#3498db';
  const meta = data ? MODE_META[data.mode] : null;
  const isTattoo = data?.mode === 'tattoo';

  const showNotif = useCallback((msg: string) => {
    setNotification(msg);
    if (notifTimer.current) clearTimeout(notifTimer.current);
    notifTimer.current = setTimeout(() => setNotification(null), 2500);
  }, []);

  /* ---- NUI open/close ---- */
  useEffect(() => {
    const handle = (e: MessageEvent) => {
      const { action, data: d } = e.data;
      if (action === 'shop:open' && d && (d.mode === 'barber' || d.mode === 'makeup' || d.mode === 'tattoo')) {
        setData({
          mode: d.mode,
          playerSex: d.playerSex || 'male',
          categories: d.categories || [],
          price: d.price || 100,
          tattoosList: d.tattoosList || [],
        });
        setView('categories'); setActiveCat(''); setSelected(null);
        setMaxVariation(0); setTattooCart([]);
      } else if (action === 'shop:close') {
        setData(null);
      }
    };
    window.addEventListener('message', handle);
    return () => window.removeEventListener('message', handle);
  }, []);

  useEffect(() => { setMounted(visible); }, [visible]);

  const handleClose = useCallback(() => {
    nuiCall('shop:utils:exit');
    setData(null);
    onClose();
  }, [onClose]);

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => { if (e.key === 'Escape' && data) handleClose(); };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [data, handleClose]);

  /* ---- Navigation ---- */
  const openCategory = useCallback(async (catId: string) => {
    setActiveCat(catId); setView('items'); setSelected(null);
    if (data && data.mode !== 'tattoo') {
      const res = await nuiCall('shop:utils:getMaxVariations', { utilsType: catId });
      setMaxVariation(res?.max || 0);
    }
  }, [data]);

  const backToCategories = useCallback(() => {
    setView('categories'); setActiveCat(''); setSelected(null); setMaxVariation(0);
  }, []);

  /* ---- Barber / Makeup : apply a variation (live preview) ---- */
  const applyVariation = useCallback((id: number) => {
    setSelected(id);
    nuiCall('shop:utils:apply', { utilsType: activeCat, variationId: id });
  }, [activeCat]);

  /* ---- Tattoo : add / remove ---- */
  const addTattoo = useCallback(async (t: TattooEntry) => {
    if (tattooCart.some(x => x.nameHash === t.nameHash)) { showNotif('Déjà sélectionné'); return; }
    const res = await nuiCall('shop:utils:tattoo:add', {
      collection: t.collection, nameHash: t.nameHash, zone: t.zone, price: t.price,
    });
    if (res?.ok) { setTattooCart(prev => [...prev, t]); showNotif('Tatouage ajouté'); }
  }, [tattooCart, showNotif]);

  const removeTattoo = useCallback(async (nameHash: string) => {
    await nuiCall('shop:utils:tattoo:remove', { nameHash });
    setTattooCart(prev => prev.filter(x => x.nameHash !== nameHash));
  }, []);

  /* ---- Pay ---- */
  const pay = useCallback(async () => {
    if (!data) return;
    if (isTattoo && tattooCart.length === 0) { showNotif('Aucun tatouage sélectionné'); return; }
    soundManager.play('success');
    const res = await nuiCall('shop:utils:pay', { mode: data.mode });
    if (res?.success) { setData(null); onClose(); }
    else { showNotif('Paiement refusé'); }
  }, [data, isTattoo, tattooCart, onClose, showNotif]);

  if (!visible || !data || !meta) return null;

  const tattoosForCat = isTattoo ? data.tattoosList.filter(t => t.zone === activeCat) : [];
  const activeCatLabel = data.categories.find(c => c.id === activeCat)?.label || '';
  const overlayClass = mounted ? 'shop-showing shop-visible' : '';
  const cartTotal = tattooCart.reduce((s, t) => s + t.price, 0);

  return (
    <div className={`shop-overlay ${overlayClass}`} style={{ '--shop-accent': accent } as React.CSSProperties}>
      {/* Left panel */}
      <div className="shop-panel">
        {view === 'categories' ? (
          <>
            <div className="shop-panel-header">
              <div className="shop-title">{meta.icon}<span>{meta.title}</span></div>
              <button className="shop-close-btn" onClick={handleClose}><X size={16} /></button>
            </div>
            <div className="shop-cat-bento-scroll">
              <div className="shop-cat-bento is-clothes">
                {data.categories.map(cat => (
                  <button
                    key={cat.id}
                    className="shop-cat-card"
                    style={{ gridColumn: 'span 6' }}
                    onClick={() => openCategory(cat.id)}
                    onMouseEnter={() => soundManager.play('hover')}
                  >
                    <div className="shop-cat-card-shade" />
                    <div className="shop-cat-card-icon">{meta.icon}</div>
                    <div className="shop-cat-card-body">
                      <span className="shop-cat-card-group">{meta.title}</span>
                      <span className="shop-cat-card-label">{cat.label}</span>
                    </div>
                    <ChevronRight className="shop-cat-card-arrow" size={16} />
                  </button>
                ))}
              </div>
            </div>
          </>
        ) : (
          <>
            <div className="shop-panel-header">
              <button className="shop-back-btn" onClick={backToCategories}><ChevronLeft size={16} /></button>
              <div className="shop-title">{meta.icon}<span>{activeCatLabel}</span></div>
              <button className="shop-close-btn" onClick={handleClose}><X size={16} /></button>
            </div>
            <div className="shop-items-scroll">
              <div className="shop-items-grid">
                {isTattoo ? (
                  tattoosForCat.length === 0 ? (
                    <div className="shop-empty"><PenTool size={28} /><span>Aucun tatouage pour cette zone</span></div>
                  ) : tattoosForCat.map(t => {
                    const inCart = tattooCart.some(x => x.nameHash === t.nameHash);
                    return (
                      <div
                        key={t.nameHash}
                        className={`shop-item ${inCart ? 'in-cart' : ''}`}
                        onClick={() => addTattoo(t)}
                        onMouseEnter={() => soundManager.play('hover')}
                      >
                        <div style={phStyle}><PenTool size={26} /></div>
                        <div className="shop-item-footer">
                          <span className="shop-item-id">{prettyName(t.nameHash)}</span>
                          <span className="shop-item-price">{t.price}$</span>
                        </div>
                        {inCart && <div className="shop-item-cart-badge"><ShoppingCart size={9} /></div>}
                      </div>
                    );
                  })
                ) : (
                  maxVariation <= 0 ? (
                    <div className="shop-empty">{meta.icon}<span>Aucune variation</span></div>
                  ) : Array.from({ length: maxVariation }, (_, id) => {
                    const isActive = selected === id;
                    return (
                      <div
                        key={id}
                        className={`shop-item ${isActive ? 'active' : ''}`}
                        onClick={() => applyVariation(id)}
                        onMouseEnter={() => soundManager.play('hover')}
                      >
                        <div style={{ ...phStyle, fontSize: 22, fontWeight: 700 }}>{id}</div>
                        <div className="shop-item-footer">
                          <span className="shop-item-id">#{id}</span>
                        </div>
                        {isActive && <div className="shop-item-check"><Check size={10} /></div>}
                      </div>
                    );
                  })
                )}
              </div>
            </div>
          </>
        )}
      </div>

      {/* Right panel : tattoo cart OR barber/makeup summary */}
      <div className="shop-cart-panel">
        <div className="shop-cart-header">
          <div className="shop-cart-title">
            {isTattoo ? <ShoppingCart size={16} /> : meta.icon}
            <span>{isTattoo ? 'Panier' : 'Résumé'}</span>
            {isTattoo && tattooCart.length > 0 && <span className="shop-cart-count">{tattooCart.length}</span>}
          </div>
        </div>

        <div className="shop-cart-items">
          {isTattoo ? (
            tattooCart.length === 0 ? (
              <div className="shop-cart-empty"><ShoppingCart size={28} /><span>Panier vide</span><p>Sélectionnez des tatouages</p></div>
            ) : tattooCart.map(t => (
              <div key={t.nameHash} className="shop-cart-item">
                <div className="shop-cart-item-img" style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--shop-accent)' }}>
                  <PenTool size={20} />
                </div>
                <div className="shop-cart-item-info">
                  <span className="shop-cart-item-name">{prettyName(t.nameHash)}</span>
                  <span className="shop-cart-item-meta">{t.zone}</span>
                </div>
                <span className="shop-cart-item-price">{t.price}$</span>
                <button className="shop-cart-item-remove" onClick={() => removeTattoo(t.nameHash)}><X size={12} /></button>
              </div>
            ))
          ) : (
            <div className="shop-cart-empty">
              {meta.icon}
              <span>{meta.title}</span>
              <p>Modifiez votre apparence puis validez</p>
            </div>
          )}
        </div>

        <div className="shop-cart-footer">
          <div className="shop-cart-total">
            <span>Total</span>
            <span className="shop-cart-total-price">{isTattoo ? cartTotal : data.price}$</span>
          </div>
          <div className="shop-cart-pay">
            <button className="shop-pay-btn shop-pay-cash" onClick={pay}>
              <Banknote size={14} /> Valider
            </button>
          </div>
        </div>
      </div>

      {notification && (
        <div className="shop-notification"><Check size={14} /><span>{notification}</span></div>
      )}
    </div>
  );
};

export default UtilsShopView;
