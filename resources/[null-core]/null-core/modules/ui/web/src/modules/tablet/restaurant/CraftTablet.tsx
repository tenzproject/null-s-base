import React, { useState, useEffect, useCallback, useMemo } from 'react';
import { cacheImg } from '@/shared/cacheVersion';
import { generateAccentVars } from '@/utils/accentColors';
import {
  X, ChefHat, Search, Clock, Package, ChevronRight,
  Play, CheckCircle2, AlertCircle, Loader2,
  Bell, User, DollarSign, Truck, Ban, Hand
} from 'lucide-react';
import { CraftTabletProps, CraftTabletData, CraftRecipe, RestaurantOrder } from './types';
import './CraftTablet.css';

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

const CraftTablet: React.FC<CraftTabletProps> = ({ visible, onClose, primaryColor }) => {
  const [data, setData] = useState<CraftTabletData | null>(null);
  const [hiding, setHiding] = useState(false);
  const [activeTab, setActiveTab] = useState<'kitchen' | 'orders'>('kitchen');
  const [selectedCategory, setSelectedCategory] = useState('all');
  const [selectedRecipe, setSelectedRecipe] = useState<CraftRecipe | null>(null);
  const [searchQuery, setSearchQuery] = useState('');
  const [crafting, setCrafting] = useState(false);
  const [craftProgress, setCraftProgress] = useState(0);
  const [notification, setNotification] = useState<{ message: string; type: 'success' | 'error' } | null>(null);

  // Brand: prefer restaurant brand color over global primary
  const brandColor = data?.brand?.color;
  const accent = brandColor || primaryColor || '#f97316';
  const accentVars = useMemo(() => generateAccentVars('--ct-accent', accent), [accent]);
  const orders: RestaurantOrder[] = data?.orders || [];
  const pendingCount = orders.filter(o => o.status === 'pending').length;

  useEffect(() => {
    const handler = (event: MessageEvent) => {
      const { action, data: payload } = event.data;
      if (action === 'craftTablet:setData') {
        setData(payload);
        setSelectedCategory('all');
        setSelectedRecipe(null);
        setSearchQuery('');
        setCrafting(false);
        setCraftProgress(0);
      } else if (action === 'craftTablet:craftResult') {
        setCrafting(false);
        setCraftProgress(0);
        if (payload?.success) {
          showNotif(payload.message || 'Craft réussi !', 'success');
          // Refresh data
          nuiCallback('craftTablet:refreshData');
        } else {
          showNotif(payload?.message || 'Craft échoué', 'error');
        }
      } else if (action === 'craftTablet:updateData') {
        setData(payload);
      } else if (action === 'craftTablet:craftProgress') {
        setCraftProgress(payload?.progress || 0);
      } else if (action === 'craftTablet:ordersUpdate') {
        setData(prev => prev ? { ...prev, orders: payload || [] } : prev);
      }
    };
    window.addEventListener('message', handler);
    return () => window.removeEventListener('message', handler);
  }, []);

  // Poll orders while tab is open (every 5s) when Commandes tab is active
  useEffect(() => {
    if (!visible || activeTab !== 'orders') return;
    nuiCallback('craftTablet:getOrders');
    const interval = setInterval(() => nuiCallback('craftTablet:getOrders'), 5000);
    return () => clearInterval(interval);
  }, [visible, activeTab]);

  useEffect(() => {
    if (!visible || hiding) return;
    const h = (e: KeyboardEvent) => { if (e.key === 'Escape') handleClose(); };
    window.addEventListener('keydown', h);
    return () => window.removeEventListener('keydown', h);
  }, [visible, hiding]);

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
      setSelectedRecipe(null);
      onClose();
      nuiCallback('craftTablet:close');
    }, 300);
  }, [onClose, hiding]);

  const handleCraft = useCallback(async (recipe: CraftRecipe) => {
    if (crafting) return;
    setCrafting(true);
    setCraftProgress(0);
    const result = await nuiCallback('craftTablet:craft', { recipeId: recipe.id });
    if (!result?.started) {
      setCrafting(false);
      showNotif(result?.message || 'Impossible de lancer le craft', 'error');
    }
  }, [crafting]);

  const categories = useMemo(() => {
    if (!data) return [];
    const cats = new Set(data.recipes.map(r => r.category));
    return Array.from(cats);
  }, [data]);

  const filteredRecipes = useMemo(() => {
    if (!data) return [];
    return data.recipes.filter(r => {
      if (selectedCategory !== 'all' && r.category !== selectedCategory) return false;
      if (searchQuery) {
        const q = searchQuery.toLowerCase();
        return r.label.toLowerCase().includes(q) || r.description.toLowerCase().includes(q);
      }
      return true;
    });
  }, [data, selectedCategory, searchQuery]);

  if (!visible && !hiding) return null;
  if (!data) return null;

  const overlayClass = hiding ? 'ct-hiding' : 'ct-visible';

  const canCraft = (recipe: CraftRecipe): boolean => {
    return recipe.requirements.every(req => (req.playerHas ?? 0) >= req.amount);
  };

  const handleClaimOrder = async (orderId: string) => {
    await nuiCallback('craftTablet:claimOrder', { orderId });
  };
  const handleMarkReady = async (orderId: string) => {
    await nuiCallback('craftTablet:markReady', { orderId });
  };
  const handleHandOver = async (orderId: string) => {
    await nuiCallback('craftTablet:handOverOrder', { orderId });
  };
  const handleCancelOrder = async (orderId: string) => {
    await nuiCallback('craftTablet:cancelOrder', { orderId });
  };

  const brand = data.brand;
  const brandLogo = brand?.logo ? brand.logo : null;

  return (
    <div className={`ct-overlay ${overlayClass}`} style={accentVars as React.CSSProperties}>
      <div className="ct-container">
        {/* Brand Header */}
        <div className="ct-header ct-header-branded">
          <div className="ct-header-left">
            {brandLogo ? (
              <div className="ct-brand-logo">
                <img src={brandLogo} alt={data.restaurantLabel}
                  onError={e => { (e.target as HTMLImageElement).style.display = 'none'; }} />
              </div>
            ) : (
              <div className="ct-header-icon"><ChefHat size={20} /></div>
            )}
            <div>
              <h2 className="ct-title">{data.restaurantLabel}</h2>
              <span className="ct-subtitle">
                {brand?.description ? brand.description : 'Gestion cuisine & commandes'}
              </span>
            </div>
          </div>
          <div className="ct-header-tabs">
            <button
              className={`ct-tab-btn ${activeTab === 'kitchen' ? 'ct-tab-active' : ''}`}
              onClick={() => setActiveTab('kitchen')}
            >
              <ChefHat size={14} /> Cuisine
            </button>
            <button
              className={`ct-tab-btn ${activeTab === 'orders' ? 'ct-tab-active' : ''}`}
              onClick={() => setActiveTab('orders')}
            >
              <Bell size={14} /> Commandes
              {pendingCount > 0 && <span className="ct-tab-badge">{pendingCount}</span>}
            </button>
          </div>
          <button className="ct-close-btn" onClick={handleClose}><X size={18} /></button>
        </div>

        {activeTab === 'orders' ? (
          <div className="ct-orders-panel">
            {orders.length === 0 ? (
              <div className="ct-empty ct-orders-empty">
                <Bell size={28} />
                <span>Aucune commande en attente</span>
              </div>
            ) : (
              <div className="ct-orders-list">
                {orders.map(order => (
                  <div key={order.id} className={`ct-order-card ct-order-${order.status}`}>
                    <div className="ct-order-header">
                      <div className="ct-order-customer">
                        <User size={14} />
                        <span>{order.customerName}</span>
                      </div>
                      <div className="ct-order-total">
                        <DollarSign size={12} />
                        <span>{order.total}</span>
                      </div>
                    </div>
                    <div className="ct-order-items">
                      {order.items.map((it, i) => (
                        <div key={i} className="ct-order-item">
                          <div className="ct-order-item-img">
                            <img src={cacheImg(`items/${it.name}.webp`)} alt={it.label}
                              onError={e => { (e.target as HTMLImageElement).src = cacheImg('items/box.png'); }} />
                          </div>
                          <span className="ct-order-item-label">{it.label}</span>
                          <span className="ct-order-item-qty">x{it.quantity}</span>
                        </div>
                      ))}
                    </div>
                    <div className="ct-order-actions">
                      {order.status === 'pending' && (
                        <>
                          <button className="ct-order-btn ct-order-btn-primary" onClick={() => handleClaimOrder(order.id)}>
                            <Hand size={13} /> Prendre en charge
                          </button>
                          <button className="ct-order-btn ct-order-btn-danger" onClick={() => handleCancelOrder(order.id)}>
                            <Ban size={13} /> Annuler
                          </button>
                        </>
                      )}
                      {order.status === 'preparing' && (
                        <>
                          <span className="ct-order-status-tag"><Loader2 size={12} className="ct-spin" /> En préparation</span>
                          <button className="ct-order-btn ct-order-btn-primary" onClick={() => handleMarkReady(order.id)}>
                            <Bell size={13} /> Marquer prête
                          </button>
                        </>
                      )}
                      {order.status === 'ready' && (
                        <>
                          <span className="ct-order-status-tag ct-order-status-ready">
                            <Bell size={12} /> Prête — au comptoir
                          </span>
                          <button className="ct-order-btn ct-order-btn-primary" onClick={() => handleHandOver(order.id)}>
                            <Truck size={13} /> Remettre au client
                          </button>
                        </>
                      )}
                      {order.status === 'delivered' && (
                        <span className="ct-order-status-tag ct-order-status-done">
                          <CheckCircle2 size={12} /> Livrée
                        </span>
                      )}
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        ) : (
        <>
        {/* Search + Categories */}
        <div className="ct-toolbar">
          <div className="ct-search">
            <Search size={14} />
            <input
              type="text"
              placeholder="Rechercher une recette..."
              value={searchQuery}
              onChange={e => setSearchQuery(e.target.value)}
              onFocus={() => nuiCallback('craftTablet:inputFocus')}
              onBlur={() => nuiCallback('craftTablet:inputBlur')}
            />
          </div>
          <div className="ct-categories">
            <button
              className={`ct-cat-btn ${selectedCategory === 'all' ? 'ct-cat-active' : ''}`}
              onClick={() => setSelectedCategory('all')}
            >Tout</button>
            {categories.map(cat => (
              <button
                key={cat}
                className={`ct-cat-btn ${selectedCategory === cat ? 'ct-cat-active' : ''}`}
                onClick={() => setSelectedCategory(cat)}
              >{cat}</button>
            ))}
          </div>
        </div>

        {/* Content */}
        <div className="ct-content">
          {/* Recipe list */}
          <div className="ct-recipe-list">
            {filteredRecipes.length === 0 ? (
              <div className="ct-empty">Aucune recette trouvée</div>
            ) : (
              filteredRecipes.map(recipe => (
                <div
                  key={recipe.id}
                  className={`ct-recipe-row ${selectedRecipe?.id === recipe.id ? 'ct-recipe-selected' : ''} ${canCraft(recipe) ? 'ct-recipe-craftable' : 'ct-recipe-missing'}`}
                  onClick={() => setSelectedRecipe(recipe)}
                >
                  <div className="ct-recipe-img">
                    <img src={cacheImg(`items/${recipe.item}.webp`)} alt={recipe.label} onError={e => { (e.target as HTMLImageElement).src = cacheImg('items/box.png'); }} />
                  </div>
                  <div className="ct-recipe-info">
                    <span className="ct-recipe-name">{recipe.label}</span>
                    <span className="ct-recipe-meta">
                      <Clock size={10} /> {recipe.time}s · x{recipe.count}
                    </span>
                  </div>
                  <div className={`ct-recipe-status ${canCraft(recipe) ? 'ct-status-ok' : 'ct-status-miss'}`}>
                    {canCraft(recipe) ? <CheckCircle2 size={14} /> : <AlertCircle size={14} />}
                  </div>
                  <ChevronRight size={14} className="ct-chevron" />
                </div>
              ))
            )}
          </div>

          {/* Recipe detail */}
          <div className="ct-detail">
            {selectedRecipe ? (
              <>
                <div className="ct-detail-header">
                  <div className="ct-detail-img">
                    <img src={cacheImg(`items/${selectedRecipe.item}.webp`)} alt={selectedRecipe.label} onError={e => { (e.target as HTMLImageElement).src = cacheImg('items/box.png'); }} />
                  </div>
                  <div>
                    <h3>{selectedRecipe.label}</h3>
                    <span className="ct-detail-meta">
                      <Clock size={12} /> {selectedRecipe.time}s · Produit x{selectedRecipe.count}
                    </span>
                    {selectedRecipe.description && (
                      <p className="ct-detail-desc">{selectedRecipe.description}</p>
                    )}
                  </div>
                </div>

                <div className="ct-ingredients">
                  <h4><Package size={14} /> Ingrédients requis</h4>
                  {selectedRecipe.requirements.map((req, i) => {
                    const has = req.playerHas ?? 0;
                    const enough = has >= req.amount;
                    return (
                      <div key={i} className={`ct-ingredient ${enough ? 'ct-ing-ok' : 'ct-ing-miss'}`}>
                        <div className="ct-ing-img">
                          <img src={cacheImg(`items/${req.itemName}.webp`)} alt={req.label} onError={e => { (e.target as HTMLImageElement).src = cacheImg('items/box.png'); }} />
                        </div>
                        <span className="ct-ing-label">{req.label}</span>
                        <span className="ct-ing-count">{has}/{req.amount}</span>
                      </div>
                    );
                  })}
                </div>

                {crafting ? (
                  <div className="ct-crafting-bar">
                    <Loader2 size={16} className="ct-spin" />
                    <div className="ct-progress-track">
                      <div className="ct-progress-fill" style={{ width: `${craftProgress}%` }} />
                    </div>
                    <span>{Math.round(craftProgress)}%</span>
                  </div>
                ) : (
                  <button
                    className={`ct-craft-btn ${canCraft(selectedRecipe) ? '' : 'ct-craft-disabled'}`}
                    onClick={() => canCraft(selectedRecipe) && handleCraft(selectedRecipe)}
                    disabled={!canCraft(selectedRecipe)}
                  >
                    <Play size={16} />
                    {canCraft(selectedRecipe) ? 'Lancer le craft' : 'Ingrédients manquants'}
                  </button>
                )}
              </>
            ) : (
              <div className="ct-detail-empty">
                <ChefHat size={40} />
                <span>Sélectionnez une recette</span>
              </div>
            )}
          </div>
        </div>
        </>
        )}
      </div>

      {notification && (
        <div className={`ct-notif ct-notif-${notification.type}`}>
          {notification.type === 'success' ? <CheckCircle2 size={16} /> : <AlertCircle size={16} />}
          {notification.message}
        </div>
      )}
    </div>
  );
};

export default CraftTablet;
