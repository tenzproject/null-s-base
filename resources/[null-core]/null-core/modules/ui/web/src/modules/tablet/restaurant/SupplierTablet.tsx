import React, { useState, useEffect, useCallback, useMemo } from 'react';
import { cacheImg } from '@/shared/cacheVersion';
import { generateAccentVars } from '@/utils/accentColors';
import {
  X, Truck, ShoppingCart, Plus, Minus, Package, Clock,
  CheckCircle2, AlertCircle, CreditCard, Loader2, ClipboardList,
  ChevronRight, Search, Trash2, Check
} from 'lucide-react';
import { SupplierTabletProps, SupplierTabletData, SupplierItem, SupplierOrder } from './types';
import './SupplierTablet.css';

const GetParentResourceName = () => 'null-core';

const nuiCallback = async (event: string, body: any = {}) => {
  try {
    const resp = await fetch(`https://${GetParentResourceName()}/${event}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
    });
    return await resp.json();
  } catch { return null; }
};

const formatMoney = (n: number) => '$' + n.toLocaleString('fr-FR');

const formatTime = (seconds: number) => {
  const m = Math.floor(seconds / 60);
  const s = seconds % 60;
  return m > 0 ? `${m}m ${s}s` : `${s}s`;
};

const STATUS_LABELS: Record<string, { label: string; color: string }> = {
  pending: { label: 'En attente', color: '#f59e0b' },
  preparing: { label: 'Préparation', color: '#3b82f6' },
  delivering: { label: 'En livraison', color: '#8b5cf6' },
  ready: { label: 'Livré', color: '#22c55e' },
  collected: { label: 'Récupéré', color: 'var(--text-tertiary)' },
};

type ViewMode = 'items' | 'cart' | 'tracking';

const SupplierTablet: React.FC<SupplierTabletProps> = ({ visible, onClose, primaryColor }) => {
  const [data, setData] = useState<SupplierTabletData | null>(null);
  const [hiding, setHiding] = useState(false);
  const [view, setView] = useState<ViewMode>('items');
  const [cart, setCart] = useState<Record<string, number>>({});
  const [ordering, setOrdering] = useState(false);
  const [notification, setNotification] = useState<{ message: string; type: 'success' | 'error' } | null>(null);
  const [searchQuery, setSearchQuery] = useState('');

  const accent = primaryColor || '#22c55e';
  const accentVars = useMemo(() => generateAccentVars('--sp-accent', accent), [accent]);

  useEffect(() => {
    const handler = (event: MessageEvent) => {
      const { action, data: payload } = event.data;
      if (action === 'supplierTablet:open' && payload) {
        setData(payload);
        setCart({});
        setOrdering(false);
        setView('items');
        setSearchQuery('');
      } else if (action === 'supplierTablet:setData') {
        setData(payload);
        setCart({});
        setOrdering(false);
        setView('items');
        setSearchQuery('');
      } else if (action === 'supplierTablet:updateOrders') {
        setData(prev => prev ? { ...prev, orders: payload } : prev);
      } else if (action === 'supplierTablet:orderResult') {
        setOrdering(false);
        if (payload?.success) {
          showNotif(payload.message || 'Commande passée !', 'success');
          setCart({});
          setView('tracking');
        } else {
          showNotif(payload?.message || 'Erreur de commande', 'error');
        }
      } else if (action === 'supplierTablet:updateMoney') {
        setData(prev => prev ? { ...prev, societyMoney: payload.societyMoney ?? prev.societyMoney, playerMoney: payload.playerMoney ?? prev.playerMoney } : prev);
      }
    };
    window.addEventListener('message', handler);
    return () => window.removeEventListener('message', handler);
  }, []);

  useEffect(() => {
    if (!visible || hiding) return;
    const h = (e: KeyboardEvent) => { if (e.key === 'Escape') handleClose(); };
    window.addEventListener('keydown', h);
    return () => window.removeEventListener('keydown', h);
  }, [visible, hiding]);

  // Timer tick for countdown
  useEffect(() => {
    if (!data || !visible) return;
    const interval = setInterval(() => {
      setData(prev => {
        if (!prev) return prev;
        const now = Math.floor(Date.now() / 1000);
        return {
          ...prev,
          orders: prev.orders.map(o => ({
            ...o,
            remainingSeconds: Math.max(0, o.deliveryTime - (now - o.orderTime)),
          })),
        };
      });
    }, 1000);
    return () => clearInterval(interval);
  }, [data, visible]);

  const showNotif = (message: string, type: 'success' | 'error') => {
    setNotification({ message, type });
    setTimeout(() => setNotification(null), 3000);
  };

  const handleClose = useCallback(() => {
    if (hiding) return;
    setHiding(true);
    setTimeout(() => {
      setHiding(false);
      setData(null);
      setCart({});
      onClose();
      nuiCallback('supplierTablet:close');
    }, 300);
  }, [onClose, hiding]);

  const addToCart = (item: SupplierItem) => {
    setCart(prev => ({ ...prev, [item.name]: (prev[item.name] || 0) + 1 }));
    showNotif(`${item.label} ajouté au panier`, 'success');
  };

  const removeFromCart = (itemName: string) => {
    setCart(prev => {
      const { [itemName]: _, ...rest } = prev;
      return rest;
    });
  };

  const updateCartQty = (itemName: string, delta: number) => {
    setCart(prev => {
      const current = prev[itemName] || 0;
      const next = Math.max(1, current + delta);
      return { ...prev, [itemName]: next };
    });
  };

  const cartTotal = useMemo(() => {
    if (!data) return 0;
    return Object.entries(cart).reduce((sum, [name, qty]) => {
      const item = data.items.find(i => i.name === name);
      return sum + (item ? item.price * qty : 0);
    }, 0);
  }, [cart, data]);

  const cartCount = useMemo(() => {
    return Object.values(cart).reduce((sum, qty) => sum + qty, 0);
  }, [cart]);

  const cartItems = useMemo(() => {
    if (!data) return [];
    return Object.entries(cart)
      .filter(([, qty]) => qty > 0)
      .map(([name, qty]) => {
        const item = data.items.find(i => i.name === name)!;
        return { ...item, quantity: qty, total: item.price * qty };
      });
  }, [cart, data]);

  const handleOrder = async () => {
    if (ordering || cartItems.length === 0) return;
    setOrdering(true);
    const items = cartItems.map(i => ({ name: i.name, count: i.quantity }));
    await nuiCallback('supplierTablet:order', { items });
  };

  const filteredItems = useMemo(() => {
    if (!data) return [];
    if (!searchQuery) return data.items;
    const q = searchQuery.toLowerCase();
    return data.items.filter(i => i.label.toLowerCase().includes(q));
  }, [data, searchQuery]);

  const activeOrders = useMemo(() => {
    if (!data) return 0;
    return data.orders.filter(o => o.status !== 'collected').length;
  }, [data]);

  if (!visible && !hiding) return null;

  const overlayClass = hiding ? 'sp-hiding' : 'sp-visible';

  return (
    <div className={`sp-overlay ${overlayClass}`}>
      <div className="sp-container" style={accentVars as React.CSSProperties}>

        {!data ? (
          <div className="sp-loading-state">
            <Loader2 size={32} className="sp-spin" />
            <span>Chargement...</span>
          </div>
        ) : (
          <>
            {/* Sidebar */}
            <div className="sp-sidebar">
              <div className="sp-sidebar-header">
                <div className="sp-sidebar-icon" style={{ background: `linear-gradient(135deg, ${accent}, ${accent}88)` }}>
                  <Truck size={20} />
                </div>
                <div className="sp-sidebar-title">
                  <h1>Fournisseur</h1>
                  <p>{data.restaurantLabel}</p>
                </div>
              </div>

              {/* Money display */}
              <div className="sp-money-section">
                <div className="sp-money-item">
                  <CreditCard size={14} />
                  <span>{formatMoney(data.societyMoney)}</span>
                </div>
              </div>

              {/* Navigation */}
              <nav className="sp-sidebar-nav">
                <button
                  className={`sp-sidebar-item ${view === 'items' ? 'active' : ''}`}
                  onClick={() => setView('items')}
                >
                  {view === 'items' && <div className="sp-sidebar-indicator" style={{ background: accent }} />}
                  <Package size={16} />
                  <span>Articles</span>
                  <ChevronRight size={14} className="sp-sidebar-arrow" />
                </button>
                <button
                  className={`sp-sidebar-item ${view === 'tracking' ? 'active' : ''}`}
                  onClick={() => setView('tracking')}
                >
                  {view === 'tracking' && <div className="sp-sidebar-indicator" style={{ background: accent }} />}
                  <ClipboardList size={16} />
                  <span>Suivi</span>
                  {activeOrders > 0 && (
                    <span className="sp-sidebar-badge" style={{ backgroundColor: accent }}>{activeOrders}</span>
                  )}
                  <ChevronRight size={14} className="sp-sidebar-arrow" />
                </button>
              </nav>

              {/* Cart + Close */}
              <div className="sp-sidebar-footer">
                <button
                  className={`sp-cart-btn ${view === 'cart' ? 'active' : ''}`}
                  onClick={() => setView('cart')}
                >
                  <ShoppingCart size={16} />
                  <span>Panier</span>
                  {cartCount > 0 && (
                    <span className="sp-cart-badge" style={{ backgroundColor: accent }}>{cartCount}</span>
                  )}
                </button>
                <button className="sp-close-btn" onClick={handleClose}>
                  <X size={16} />
                  <span>Fermer</span>
                </button>
              </div>
            </div>

            {/* Main content */}
            <div className="sp-content">

              {/* Items view */}
              {view === 'items' && (
                <>
                  <div className="sp-content-header">
                    <div className="sp-content-header-info">
                      <h2>Catalogue Fournisseur</h2>
                      <p>Sélectionnez les articles à commander pour votre restaurant</p>
                    </div>
                    <div className="sp-search">
                      <Search size={16} />
                      <input
                        type="text"
                        placeholder="Rechercher un article..."
                        value={searchQuery}
                        onChange={e => setSearchQuery(e.target.value)}
                      />
                    </div>
                  </div>

                  <div className="sp-items-grid">
                    {filteredItems.map((item) => {
                      const inCart = cart[item.name] || 0;
                      return (
                        <div key={item.name} className="sp-item-card">
                          <div className="sp-item-image">
                            <img
                              src={cacheImg(`items/${item.name}.webp`)}
                              alt={item.label}
                              onLoad={(e) => {
                                const fallback = (e.target as HTMLImageElement).nextElementSibling;
                                if (fallback) (fallback as HTMLElement).style.display = 'none';
                              }}
                              onError={(e) => { (e.target as HTMLImageElement).style.display = 'none'; }}
                            />
                            <div className="sp-item-image-fallback"><Package size={32} /></div>
                          </div>
                          <div className="sp-item-info">
                            <span className="sp-item-label">{item.label}</span>
                            <span className="sp-item-price" style={{ color: accent }}>{formatMoney(item.price)}</span>
                          </div>
                          <button
                            className={`sp-item-add-btn ${inCart > 0 ? 'in-cart' : ''}`}
                            onClick={() => addToCart(item)}
                            style={inCart > 0 ? { backgroundColor: accent, borderColor: accent } : { borderColor: accent, color: accent }}
                          >
                            {inCart > 0 ? (
                              <><Check size={14} /> {inCart}x</>
                            ) : (
                              <><Plus size={14} /> Ajouter</>
                            )}
                          </button>
                        </div>
                      );
                    })}
                    {filteredItems.length === 0 && (
                      <div className="sp-empty">
                        <Search size={48} />
                        <p>Aucun article trouvé</p>
                      </div>
                    )}
                  </div>
                </>
              )}

              {/* Cart view */}
              {view === 'cart' && (
                <div className="sp-cart-view">
                  <div className="sp-cart-header">
                    <div className="sp-section-header">
                      <div className="sp-section-header-icon" style={{ backgroundColor: `${accent}15`, color: accent }}>
                        <ShoppingCart size={20} />
                      </div>
                      <div>
                        <h2>Panier</h2>
                        <p>Vérifiez votre commande avant de la passer</p>
                      </div>
                    </div>
                  </div>

                  {cartItems.length === 0 ? (
                    <div className="sp-empty">
                      <ShoppingCart size={48} />
                      <p>Votre panier est vide</p>
                    </div>
                  ) : (
                    <>
                      <div className="sp-cart-items">
                        {cartItems.map(item => (
                          <div key={item.name} className="sp-cart-item">
                            <div className="sp-cart-item-image">
                              <img
                                src={cacheImg(`items/${item.name}.webp`)}
                                alt={item.label}
                                onError={(e) => { (e.target as HTMLImageElement).style.display = 'none'; }}
                              />
                              <div className="sp-cart-item-image-fallback"><Package size={20} /></div>
                            </div>
                            <div className="sp-cart-item-info">
                              <span className="sp-cart-item-label">{item.label}</span>
                              <span className="sp-cart-item-price">{formatMoney(item.price)} / unité</span>
                            </div>
                            <div className="sp-cart-item-quantity">
                              <button onClick={() => updateCartQty(item.name, -1)} disabled={item.quantity <= 1}><Minus size={14} /></button>
                              <span>{item.quantity}</span>
                              <button onClick={() => updateCartQty(item.name, 1)}><Plus size={14} /></button>
                            </div>
                            <span className="sp-cart-item-total" style={{ color: accent }}>{formatMoney(item.total)}</span>
                            <button className="sp-cart-item-remove" onClick={() => removeFromCart(item.name)}><Trash2 size={14} /></button>
                          </div>
                        ))}
                      </div>

                      {/* Cart footer */}
                      <div className="sp-cart-footer">
                        <div className="sp-cart-total">
                          <span>Total</span>
                          <span className="sp-cart-total-amount" style={{ color: accent }}>{formatMoney(cartTotal)}</span>
                        </div>
                        <div className="sp-cart-payment">
                          <span className="sp-cart-payment-title">Paiement via caisse société</span>
                          <button
                            className={`sp-pay-btn ${ordering ? 'sp-pay-loading' : ''}`}
                            onClick={handleOrder}
                            disabled={ordering || cartTotal > data.societyMoney}
                            style={!ordering && cartTotal <= data.societyMoney ? { backgroundColor: accent } : {}}
                          >
                            {ordering ? (
                              <><Loader2 size={16} className="sp-spin" /> Commande en cours...</>
                            ) : cartTotal > data.societyMoney ? (
                              <><AlertCircle size={16} /> Fonds insuffisants ({formatMoney(data.societyMoney)} disponibles)</>
                            ) : (
                              <><CreditCard size={16} /> Passer la commande · {formatMoney(cartTotal)}</>
                            )}
                          </button>
                        </div>
                      </div>
                    </>
                  )}
                </div>
              )}

              {/* Tracking view */}
              {view === 'tracking' && (
                <div className="sp-tracking-view">
                  <div className="sp-content-header">
                    <div className="sp-content-header-info">
                      <h2>Suivi des commandes</h2>
                      <p>{data.orders.length} commande{data.orders.length > 1 ? 's' : ''} au total</p>
                    </div>
                  </div>

                  {data.orders.length === 0 ? (
                    <div className="sp-empty">
                      <Package size={48} />
                      <p>Aucune commande en cours</p>
                    </div>
                  ) : (
                    <div className="sp-order-list">
                      {data.orders.map(order => {
                        const statusInfo = STATUS_LABELS[order.status] || STATUS_LABELS.pending;
                        const remaining = order.remainingSeconds ?? 0;
                        return (
                          <div key={order.orderId} className="sp-order-card">
                            <div className="sp-order-header">
                              <div className="sp-order-id">
                                <Package size={14} />
                                <span>#{order.orderId}</span>
                              </div>
                              <div className="sp-order-status" style={{ color: statusInfo.color, borderColor: statusInfo.color + '40', background: statusInfo.color + '15' }}>
                                {statusInfo.label}
                              </div>
                            </div>
                            <div className="sp-order-items">
                              {order.items.map((item, i) => (
                                <span key={i} className="sp-order-item-tag">{item.count}x {item.label}</span>
                              ))}
                            </div>
                            <div className="sp-order-footer">
                              <span className="sp-order-total" style={{ color: accent }}>{formatMoney(order.totalPrice)}</span>
                              {(order.status === 'pending' || order.status === 'preparing' || order.status === 'delivering') && remaining > 0 && (
                                <span className="sp-order-timer"><Clock size={12} /> {formatTime(remaining)}</span>
                              )}
                              {order.status === 'ready' && (
                                <span className="sp-order-ready"><CheckCircle2 size={12} /> Palette disponible</span>
                              )}
                            </div>
                          </div>
                        );
                      })}
                    </div>
                  )}
                </div>
              )}

            </div>
          </>
        )}

        {/* Notification */}
        {notification && (
          <div className={`sp-notification ${notification.type}`}>
            {notification.type === 'success' ? <Check size={16} /> : <AlertCircle size={16} />}
            <span>{notification.message}</span>
          </div>
        )}
      </div>
    </div>
  );
};

export default SupplierTablet;
