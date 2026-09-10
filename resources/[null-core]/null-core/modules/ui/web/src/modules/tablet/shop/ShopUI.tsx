import React, { useState, useEffect, useCallback, useRef, useMemo } from 'react';
import { cacheImg } from '@/shared/cacheVersion';
import { generateAccentVars } from '@/utils/accentColors';
import {
  X, ShoppingCart, Plus, Minus, Trash2, CreditCard, Banknote,
  ChevronRight, Package, Search, LayoutGrid, UtensilsCrossed,
  GlassWater, Smartphone, Wrench, Heart, Swords, Flame,
  Settings, Shield, Check, AlertCircle, Store, Clock, Hammer
} from 'lucide-react';
import { ShopUIProps, ShopData, ShopItem, CartItem, PlayerMoney, ShopCategory, RepairData, RepairWeapon, ShopBrand } from './types';
import WaveBackground from '@/components/WaveBackground';
import './ShopUI.css';

const GetParentResourceName = () => 'null-core';

// Tronque un montant trop long ($ + chiffres) pour qu'il ne deborde pas d'un
// bouton/label : coupe a maxLen caracteres et ajoute « … » (montre qu'il y a plus).
const fmtMoney = (n: number, maxLen = 13): string => {
  const s = '$' + (n || 0).toLocaleString();
  if (s.length <= maxLen) return s;
  return s.slice(0, maxLen).replace(/[,.\s]$/, '') + '…';
};

const ICON_MAP: Record<string, React.ReactNode> = {
  // Lucide names
  LayoutGrid: <LayoutGrid size={16} />,
  UtensilsCrossed: <UtensilsCrossed size={16} />,
  GlassWater: <GlassWater size={16} />,
  Smartphone: <Smartphone size={16} />,
  Wrench: <Wrench size={16} />,
  Heart: <Heart size={16} />,
  Swords: <Swords size={16} />,
  Flame: <Flame size={16} />,
  Settings: <Settings size={16} />,
  Shield: <Shield size={16} />,
  Package: <Package size={16} />,
  Store: <Store size={16} />,
  // Iconify names (from existing configs)
  'ic:round-clear-all': <LayoutGrid size={16} />,
  'mdi:food-drumstick': <UtensilsCrossed size={16} />,
  'ion:water-sharp': <GlassWater size={16} />,
  'ic:round-phone-iphone': <Smartphone size={16} />,
  'material-symbols:healing': <Heart size={16} />,
  'material-symbols:soap': <Package size={16} />,
  'mdi:pistol': <Swords size={16} />,
  'mdi:ammunition': <Flame size={16} />,
  'game-icons:machine-gun-magazine': <Settings size={16} />,
  'game-icons:kevlar-vest': <Shield size={16} />,
  'mdi:wrench': <Wrench size={16} />,
};

const ShopUI: React.FC<ShopUIProps> = ({ visible, onClose, primaryColor }) => {
  const [shopData, setShopData] = useState<ShopData | null>(null);
  const [selectedCategory, setSelectedCategory] = useState<string>('all');
  const [cart, setCart] = useState<CartItem[]>([]);
  const [money, setMoney] = useState<PlayerMoney>({ cash: 0, bank: 0 });
  const [hiding, setHiding] = useState(false);
  const [notification, setNotification] = useState<{ message: string; type: 'success' | 'error' } | null>(null);
  const [searchQuery, setSearchQuery] = useState('');
  const [cartOpen, setCartOpen] = useState(false);
  const [purchasing, setPurchasing] = useState(false);
  const [repairData, setRepairData] = useState<RepairData | null>(null);
  const searchRef = useRef<HTMLInputElement>(null);

  const brand: ShopBrand | undefined = shopData?.brand;
  const brandBg = brand?.bgColor || '#1a1a1a';
  const accentColor = primaryColor || brand?.accentColor || '#3498db';
  const brandLogo = brand?.logo ? cacheImg(brand.logo) : null;
  const shopuiAccentVars = useMemo(() => generateAccentVars('--shopui-accent', accentColor), [accentColor]);
  const shopuiBrandVars = useMemo(() => ({
    '--shopui-brand-bg': brandBg,
    '--shopui-brand-accent': accentColor,
  } as React.CSSProperties), [brandBg, accentColor]);

  // Listen for NUI messages
  useEffect(() => {
    const handleMessage = (event: MessageEvent) => {
      const { action, data } = event.data;

      switch (action) {
        case 'shopui:open':
          if (data) {
            setShopData(data);
            setSelectedCategory('all');
            setCart([]);
            setSearchQuery('');
            setCartOpen(false);
            setPurchasing(false);
            setRepairData(null);
          }
          break;

        case 'shopui:close':
          setShopData(null);
          setCart([]);
          setRepairData(null);
          break;

        case 'shopui:setMoney':
          if (data) setMoney(data);
          break;

        case 'shopui:purchaseResult':
          setPurchasing(false);
          if (data?.success) {
            showNotification('Achat effectué avec succès !', 'success');
            setCart([]);
            setCartOpen(false);
          } else {
            showNotification('Erreur lors de l\'achat', 'error');
          }
          break;

        case 'shopui:repairData':
          if (data) setRepairData(data);
          break;

        case 'shopui:repairResult':
          if (data?.success) {
            showNotification(data.message || 'Arme envoyée en réparation !', 'success');
            // Refresh repair data
            fetch(`https://${GetParentResourceName()}/shopui:getRepairData`, {
              method: 'POST',
              headers: { 'Content-Type': 'application/json' },
              body: JSON.stringify({}),
            });
          } else {
            showNotification(data?.message || 'Erreur', 'error');
          }
          break;

        case 'shopui:repairPickupResult':
          if (data?.success) {
            showNotification(data.message || 'Arme récupérée !', 'success');
            fetch(`https://${GetParentResourceName()}/shopui:getRepairData`, {
              method: 'POST',
              headers: { 'Content-Type': 'application/json' },
              body: JSON.stringify({}),
            });
          } else {
            showNotification(data?.message || 'Erreur', 'error');
          }
          break;
      }
    };
    window.addEventListener('message', handleMessage);
    return () => window.removeEventListener('message', handleMessage);
  }, []);

  const showNotification = useCallback((message: string, type: 'success' | 'error') => {
    setNotification({ message, type });
    setTimeout(() => setNotification(null), 3000);
  }, []);

  const handleClose = useCallback(() => {
    setHiding(true);
    setTimeout(() => {
      setHiding(false);
      onClose();
      fetch(`https://${GetParentResourceName()}/shopui:close`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({}),
      });
    }, 300);
  }, [onClose]);

  // Auto-refresh repair data when repair category is active
  useEffect(() => {
    if (selectedCategory !== 'repair' || !shopData?.hasRepair || !visible) return;
    const interval = setInterval(() => {
      fetch(`https://${GetParentResourceName()}/shopui:getRepairData`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({}),
      });
    }, 3000);
    return () => clearInterval(interval);
  }, [selectedCategory, shopData?.hasRepair, visible]);

  // Escape to close
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape' && visible) {
        handleClose();
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [visible, handleClose]);

  // Cart helpers
  const addToCart = useCallback((item: ShopItem) => {
    setCart(prev => {
      const existing = prev.find(c => c.name === item.name);
      if (existing) {
        return prev.map(c => c.name === item.name ? { ...c, quantity: c.quantity + 1 } : c);
      }
      return [...prev, { ...item, quantity: 1 }];
    });
    showNotification(`${item.label} ajouté au panier`, 'success');
  }, [showNotification]);

  const removeFromCart = useCallback((itemName: string) => {
    setCart(prev => prev.filter(c => c.name !== itemName));
  }, []);

  const updateQuantity = useCallback((itemName: string, delta: number) => {
    setCart(prev => prev.map(c => {
      if (c.name === itemName) {
        const newQty = Math.max(1, c.quantity + delta);
        return { ...c, quantity: newQty };
      }
      return c;
    }));
  }, []);

  const cartTotal = useMemo(() => cart.reduce((sum, c) => sum + c.price * c.quantity, 0), [cart]);
  const cartCount = useMemo(() => cart.reduce((sum, c) => sum + c.quantity, 0), [cart]);

  const handlePurchase = useCallback(async (paymentType: 'cash' | 'bank') => {
    if (cart.length === 0 || purchasing) return;
    setPurchasing(true);

    const cartData = cart.map(c => ({
      name: c.name,
      label: c.label,
      price: c.price,
      quantity: c.quantity,
    }));

    try {
      await fetch(`https://${GetParentResourceName()}/shopui:buy`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ paymentType, cart: cartData }),
      });
    } catch (e) {
      setPurchasing(false);
    }
  }, [cart, purchasing]);

  const handleRepairWeapon = useCallback(async (weapon: RepairWeapon) => {
    try {
      await fetch(`https://${GetParentResourceName()}/shopui:repairWeapon`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ weaponName: weapon.name, ammoType: weapon.ammoType }),
      });
    } catch (e) { }
  }, []);

  const handleRepairPickup = useCallback(async (weaponName: string) => {
    try {
      await fetch(`https://${GetParentResourceName()}/shopui:repairPickup`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ weaponName }),
      });
    } catch (e) { }
  }, []);

  const handleCategoryClick = useCallback((catType: string) => {
    setSelectedCategory(catType);
    setCartOpen(false);
    if (catType === 'repair' && shopData?.hasRepair) {
      fetch(`https://${GetParentResourceName()}/shopui:getRepairData`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({}),
      });
    }
  }, [shopData]);

  // Filter items (memoise : ne recalcule que si items/categorie/recherche changent)
  const filteredItems = useMemo(() => shopData?.items.filter(item => {
    const matchesCategory = selectedCategory === 'all' || item.category === selectedCategory;
    const matchesSearch = !searchQuery || item.label.toLowerCase().includes(searchQuery.toLowerCase());
    return matchesCategory && matchesSearch;
  }) || [], [shopData?.items, selectedCategory, searchQuery]);

  if (!visible || !shopData) return null;

  return (
    <div className={`shopui-overlay ${hiding ? 'shopui-hiding' : ''}`}>
      <div
        className={`shopui-container ${brand ? `shopui-brand-${brand.id}` : ''}`}
        style={{ ...shopuiAccentVars, ...shopuiBrandVars } as React.CSSProperties}
      >
        <WaveBackground accentColor={brand?.accentColor || accentColor} opacity={0.5} />

        {/* Sidebar */}
        <div className="shopui-sidebar">
          {brand ? (
            <div
              className="shopui-brand-hero"
              style={{ background: `linear-gradient(160deg, ${brandBg} 0%, ${brandBg}dd 60%, rgba(0,0,0,0.4) 100%)` }}
            >
              <div className="shopui-brand-hero-shine" />
              <div className="shopui-brand-hero-inner">
                {brandLogo ? (
                  <img
                    className="shopui-brand-logo"
                    src={brandLogo}
                    alt={brand.name}
                    onError={(e) => { (e.target as HTMLImageElement).style.display = 'none'; }}
                  />
                ) : (
                  <div className="shopui-brand-logo-fallback"><Store size={28} /></div>
                )}
                <div className="shopui-brand-hero-text">
                  <h1>{brand.name}</h1>
                  {(brand.tagline || shopData.tag) && (
                    <p>{brand.tagline || shopData.tag}</p>
                  )}
                </div>
              </div>
            </div>
          ) : (
            <div className="shopui-sidebar-header">
              <div className="shopui-sidebar-icon" style={{ background: `linear-gradient(135deg, ${accentColor}, ${accentColor}88)` }}>
                <Store size={20} />
              </div>
              <div className="shopui-sidebar-title">
                <h1>{shopData.label}</h1>
                <p>{shopData.tag}</p>
              </div>
            </div>
          )}

          {/* Money display */}
          <div className="shopui-money-section">
            <div className="shopui-money-item">
              <Banknote size={14} />
              <span>{fmtMoney(money.cash)}</span>
            </div>
            <div className="shopui-money-item">
              <CreditCard size={14} />
              <span>{fmtMoney(money.bank)}</span>
            </div>
          </div>

          {/* Categories */}
          <nav className="shopui-sidebar-nav">
            {shopData.categories.map((cat: ShopCategory) => (
              <button
                key={cat.type}
                className={`shopui-sidebar-item ${selectedCategory === cat.type ? 'active' : ''}`}
                onClick={() => handleCategoryClick(cat.type)}
              >
                {selectedCategory === cat.type && <div className="shopui-sidebar-indicator" style={{ background: accentColor }} />}
                {ICON_MAP[cat.icon] || <Package size={16} />}
                <span>{cat.name}</span>
                <ChevronRight size={14} className="shopui-sidebar-arrow" />
              </button>
            ))}
          </nav>

          {/* Cart button */}
          <div className="shopui-sidebar-footer">
            <button
              className={`shopui-cart-btn ${cartOpen ? 'active' : ''}`}
              onClick={() => setCartOpen(!cartOpen)}
            >
              <ShoppingCart size={16} />
              <span>Panier</span>
              {cartCount > 0 && (
                <span className="shopui-cart-badge" style={{ backgroundColor: accentColor }}>{cartCount}</span>
              )}
            </button>
            <button className="shopui-close-btn" onClick={handleClose}>
              <X size={16} />
              <span>Fermer</span>
            </button>
          </div>
        </div>

        {/* Main content */}
        <div className="shopui-content">
          {/* {brand && (
            <div
              className="shopui-brand-ambient"
              style={{
                background: `radial-gradient(circle at 0% 0%, ${brandBg}55 0%, transparent 55%)`,
              }}
              aria-hidden
            />
          )} */}
          {selectedCategory === 'repair' && shopData.hasRepair ? (
            /* Repair view */
            <div className="shopui-repair-view">
              <div className="shopui-content-header">
                <div className="shopui-content-header-info">
                  <h2>Réparation d'armes</h2>
                  <p>Faites réparer vos armes endommagées. Temps de réparation : {repairData ? (repairData.isVip ? `${repairData.timeToRepairVIP} min (VIP)` : `${repairData.timeToRepair} min`) : '...'}</p>
                </div>
              </div>

              {!repairData ? (
                <div className="shopui-empty">
                  <Clock size={48} />
                  <p>Chargement...</p>
                </div>
              ) : (
                <div className="shopui-repair-content">
                  {/* Weapons to repair */}
                  {repairData.weapons.length > 0 && (
                    <div className="shopui-repair-section">
                      <h3 className="shopui-repair-section-title">
                        Vos armes
                      </h3>
                      <div className="shopui-repair-list">
                        {repairData.weapons.map((weapon) => (
                          <div key={weapon.name} className="shopui-repair-card">
                            <div className="shopui-repair-card-image">
                              <img
                                src={cacheImg(`items/${weapon.name}.webp`)}
                                alt={weapon.label}
                                onLoad={(e) => {
                                  const fallback = (e.target as HTMLImageElement).nextElementSibling;
                                  if (fallback) (fallback as HTMLElement).style.display = 'none';
                                }}
                                onError={(e) => { (e.target as HTMLImageElement).style.display = 'none'; }}
                              />
                              <div className="shopui-item-image-fallback"><Swords size={24} /></div>
                            </div>
                            <div className="shopui-repair-card-info">
                              <span className="shopui-repair-card-label">{weapon.label}</span>
                              <div className="shopui-repair-durability">
                                <div className="shopui-repair-durability-bar">
                                  <div
                                    className="shopui-repair-durability-fill"
                                    style={{
                                      width: `${weapon.durability}%`,
                                      backgroundColor: weapon.durability > 50 ? '#2ecc71' : weapon.durability > 25 ? '#f39c12' : '#e74c3c'
                                    }}
                                  />
                                </div>
                                <span className="shopui-repair-durability-text">{Math.round(weapon.durability)}%</span>
                              </div>
                            </div>
                            <div className="shopui-repair-card-action">
                              <span className="shopui-repair-card-price" style={{ color: accentColor }}>
                                ${weapon.repairPrice.toLocaleString()}
                              </span>
                              <button
                                className="shopui-repair-btn"
                                onClick={() => handleRepairWeapon(weapon)}
                                style={{ borderColor: accentColor, color: accentColor }}
                              >
                                Réparer
                              </button>
                            </div>
                          </div>
                        ))}
                      </div>
                    </div>
                  )}

                  {/* Repairs in progress */}
                  {repairData.repairs.filter(r => !r.finish).length > 0 && (
                    <div className="shopui-repair-section">
                      <h3 className="shopui-repair-section-title">
                        En réparation
                      </h3>
                      <div className="shopui-repair-list">
                        {repairData.repairs.filter(r => !r.finish).map((repair) => (
                          <div key={repair.name} className="shopui-repair-card repair-progress">
                            <div className="shopui-repair-card-image">
                              <img
                                src={cacheImg(`items/${repair.name}.webp`)}
                                alt={repair.label}
                                onLoad={(e) => {
                                  const fallback = (e.target as HTMLImageElement).nextElementSibling;
                                  if (fallback) (fallback as HTMLElement).style.display = 'none';
                                }}
                                onError={(e) => { (e.target as HTMLImageElement).style.display = 'none'; }}
                              />
                              <div className="shopui-item-image-fallback"><Wrench size={24} /></div>
                            </div>
                            <div className="shopui-repair-card-info" style={{ flex: 1 }}>
                              <span className="shopui-repair-card-label">{repair.label}</span>
                              <div className="shopui-repair-progress-bar">
                                <div
                                  className="shopui-repair-progress-fill"
                                  style={{ width: `${repair.pourcent}%`, backgroundColor: accentColor }}
                                />
                              </div>
                              <span className="shopui-repair-progress-text">{Math.round(repair.pourcent)}%</span>
                            </div>
                          </div>
                        ))}
                      </div>
                    </div>
                  )}

                  {/* Ready to pick up */}
                  {repairData.repairs.filter(r => r.finish).length > 0 && (
                    <div className="shopui-repair-section">
                      <h3 className="shopui-repair-section-title" style={{ color: '#2ecc71' }}>
                        Prêtes à récupérer
                      </h3>
                      <div className="shopui-repair-list">
                        {repairData.repairs.filter(r => r.finish).map((repair) => (
                          <div key={repair.name} className="shopui-repair-card repair-ready">
                            <div className="shopui-repair-card-image">
                              <img
                                src={cacheImg(`items/${repair.name}.webp`)}
                                alt={repair.label}
                                onLoad={(e) => {
                                  const fallback = (e.target as HTMLImageElement).nextElementSibling;
                                  if (fallback) (fallback as HTMLElement).style.display = 'none';
                                }}
                                onError={(e) => { (e.target as HTMLImageElement).style.display = 'none'; }}
                              />
                              <div className="shopui-item-image-fallback"><Check size={24} /></div>
                            </div>
                            <div className="shopui-repair-card-info">
                              <span className="shopui-repair-card-label">{repair.label}</span>
                              <span className="shopui-repair-ready-text">Réparation terminée !</span>
                            </div>
                            <button
                              className="shopui-repair-pickup-btn"
                              onClick={() => handleRepairPickup(repair.name)}
                              style={{ backgroundColor: accentColor }}
                            >
                              <Check size={14} /> Récupérer
                            </button>
                          </div>
                        ))}
                      </div>
                    </div>
                  )}

                  {repairData.weapons.length === 0 && repairData.repairs.length === 0 && (
                    <div className="shopui-empty">
                      <Wrench size={48} />
                      <p>Aucune arme à réparer</p>
                    </div>
                  )}
                </div>
              )}
            </div>
          ) : !cartOpen ? (
            <>
              {/* Header with search */}
              <div className="shopui-content-header">
                <div className="shopui-content-header-info">
                  <h2>{selectedCategory === 'all' ? shopData.label : shopData.categories.find(c => c.type === selectedCategory)?.name || shopData.label}</h2>
                  <p>{shopData.description.split('\n')[0]}</p>
                </div>
                <div className="shopui-search">
                  <Search size={16} />
                  <input
                    ref={searchRef}
                    type="text"
                    placeholder="Rechercher un article..."
                    value={searchQuery}
                    onChange={e => setSearchQuery(e.target.value)}
                  />
                </div>
              </div>

              {/* Items grid — keyed by category so items re-stagger on change */}
              <div className="shopui-items-grid" key={selectedCategory}>
                {filteredItems.map((item, index) => {
                  const inCart = cart.find(c => c.name === item.name);
                  return (
                    <div
                      key={`${item.name}-${index}`}
                      className="shopui-item-card"
                      style={{ animationDelay: `${Math.min(index, 18) * 0.035}s` }}
                    >
                      <div className="shopui-item-image">
                        <img
                          src={cacheImg(`items/${item.name}.webp`)}
                          alt={item.label}
                          onLoad={(e) => {
                            const fallback = (e.target as HTMLImageElement).nextElementSibling;
                            if (fallback) (fallback as HTMLElement).style.display = 'none';
                          }}
                          onError={(e) => {
                            (e.target as HTMLImageElement).style.display = 'none';
                          }}
                        />
                        <div className="shopui-item-image-fallback">
                          <Package size={32} />
                        </div>
                      </div>
                      <div className="shopui-item-info">
                        <span className="shopui-item-label">{item.label}</span>
                        <span className="shopui-item-price" style={{ color: accentColor }}>
                          ${item.price.toLocaleString()}
                        </span>
                      </div>
                      <button
                        className={`shopui-item-add-btn ${inCart ? 'in-cart' : ''}`}
                        onClick={() => addToCart(item)}
                        style={inCart ? { backgroundColor: accentColor, borderColor: accentColor } : { borderColor: accentColor, color: accentColor }}
                      >
                        {inCart ? (
                          <><Check size={14} /> {inCart.quantity}x</>
                        ) : (
                          <><Plus size={14} /> Ajouter</>
                        )}
                      </button>
                    </div>
                  );
                })}
                {filteredItems.length === 0 && (
                  <div className="shopui-empty">
                    <Search size={48} />
                    <p>Aucun article trouvé</p>
                  </div>
                )}
              </div>
            </>
          ) : (
            /* Cart view */
            <div className="shopui-cart-view">
              <div className="shopui-cart-header">
                <div className="shopui-section-header">
                  <div>
                    <h2>{shopData.locales.cartTitle}</h2>
                    <p>{shopData.locales.cartDescription}</p>
                  </div>
                </div>
              </div>

              {cart.length === 0 ? (
                <div className="shopui-empty">
                  <ShoppingCart size={48} />
                  <p>{shopData.locales.emptyCart}</p>
                </div>
              ) : (
                <>
                  <div className="shopui-cart-items">
                    {cart.map(item => (
                      <div key={item.name} className="shopui-cart-item">
                        <div className="shopui-cart-item-image">
                          <img
                            src={cacheImg(`items/${item.name}.webp`)}
                            alt={item.label}
                            onError={(e) => {
                              (e.target as HTMLImageElement).style.display = 'none';
                            }}
                          />
                          <div className="shopui-cart-item-image-fallback">
                            <Package size={20} />
                          </div>
                        </div>
                        <div className="shopui-cart-item-info">
                          <span className="shopui-cart-item-label">{item.label}</span>
                          <span className="shopui-cart-item-price">${item.price.toLocaleString()} / unité</span>
                        </div>
                        <div className="shopui-cart-item-quantity">
                          <button onClick={() => updateQuantity(item.name, -1)} disabled={item.quantity <= 1}>
                            <Minus size={14} />
                          </button>
                          <span>{item.quantity}</span>
                          <button onClick={() => updateQuantity(item.name, 1)}>
                            <Plus size={14} />
                          </button>
                        </div>
                        <span className="shopui-cart-item-total" style={{ color: accentColor }}>
                          ${(item.price * item.quantity).toLocaleString()}
                        </span>
                        <button className="shopui-cart-item-remove" onClick={() => removeFromCart(item.name)}>
                          <Trash2 size={14} />
                        </button>
                      </div>
                    ))}
                  </div>

                  {/* Cart footer with total + payment */}
                  <div className="shopui-cart-footer">
                    <div className="shopui-cart-total">
                      <span>{shopData.locales.total}</span>
                      <span className="shopui-cart-total-amount" style={{ color: accentColor }}>
                        ${cartTotal.toLocaleString()}
                      </span>
                    </div>
                    <div className="shopui-cart-payment">
                      <span className="shopui-cart-payment-title">{shopData.locales.paymentTitle}</span>
                      <div className="shopui-cart-payment-buttons">
                        <button
                          className="shopui-pay-btn cash"
                          onClick={() => handlePurchase('cash')}
                          disabled={purchasing || money.cash < cartTotal}
                        >
                          <Banknote size={16} />
                          <div>
                            <span>{shopData.locales.payCash}</span>
                            <small>{fmtMoney(money.cash, 11)}</small>
                          </div>
                          {money.cash < cartTotal && <AlertCircle size={14} className="shopui-pay-warning" />}
                        </button>
                        <button
                          className="shopui-pay-btn bank"
                          onClick={() => handlePurchase('bank')}
                          disabled={purchasing || money.bank < cartTotal}
                        >
                          <CreditCard size={16} />
                          <div>
                            <span>{shopData.locales.payBank}</span>
                            <small>{fmtMoney(money.bank, 11)}</small>
                          </div>
                          {money.bank < cartTotal && <AlertCircle size={14} className="shopui-pay-warning" />}
                        </button>
                      </div>
                    </div>
                  </div>
                </>
              )}
            </div>
          )}
        </div>

        {/* Notification */}
        {notification && (
          <div className={`shopui-notification ${notification.type}`}>
            {notification.type === 'success' ? <Check size={16} /> : <AlertCircle size={16} />}
            <span>{notification.message}</span>
          </div>
        )}
      </div>
    </div>
  );
};

export default ShopUI;
