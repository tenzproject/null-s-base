import React, { useState, useEffect, useCallback, useRef, useMemo } from 'react';
import { generateAccentVars } from '@/utils/accentColors';
import {
  X, Store, Search, Package, Banknote, CreditCard, ChevronRight,
  Plus, Minus, Tag, ShoppingBag, ListOrdered, DollarSign,
  Check, AlertCircle, Trash2, Send, User, Clock
} from 'lucide-react';
import { PawnShopProps, PawnShopData, PawnShopListing, PawnShopInventoryItem, PawnShopPendingSale } from './types';
import './PawnShop.css';
import { cacheImg } from '@shared/cacheVersion';

const GetParentResourceName = () => 'null-core';

const ItemImage: React.FC<{ name: string; label?: string; size?: number }> = ({ name, label, size }) => (
  <div className="pawnshop-item-image" style={size ? { width: size, height: size } : undefined}>
    <img
      src={cacheImg(`items/${name}.webp`)}
      alt={label || name}
      draggable={false}
      onLoad={(e) => {
        const fallback = (e.target as HTMLImageElement).nextElementSibling;
        if (fallback) (fallback as HTMLElement).style.display = 'none';
      }}
      onError={(e) => {
        const el = e.target as HTMLImageElement;
        if (!el.dataset.fallback) {
          el.dataset.fallback = '1';
          el.src = cacheImg('items/box.png');
        }
      }}
    />
    <div className="pawnshop-item-image-fallback"><Package size={size ? Math.floor(size * 0.5) : 28} /></div>
  </div>
);

type TabType = 'browse' | 'sell' | 'mylistings' | 'revenue';

const PawnShop: React.FC<PawnShopProps> = ({ visible, onClose, primaryColor }) => {
  const [data, setData] = useState<PawnShopData | null>(null);
  const [activeTab, setActiveTab] = useState<TabType>('browse');
  const [hiding, setHiding] = useState(false);
  const [notification, setNotification] = useState<{ message: string; type: 'success' | 'error' } | null>(null);
  const [searchQuery, setSearchQuery] = useState('');
  const [buyQuantity, setBuyQuantity] = useState<Record<number, number>>({});
  const [sellItem, setSellItem] = useState<PawnShopInventoryItem | null>(null);
  const [sellPrice, setSellPrice] = useState('');
  const [sellCount, setSellCount] = useState('1');
  const [processing, setProcessing] = useState(false);
  const searchRef = useRef<HTMLInputElement>(null);

  const accentColor = primaryColor || '#e67e22';
  const pawnshopAccentVars = useMemo(() => generateAccentVars('--pawnshop-accent', accentColor), [accentColor]);

  useEffect(() => {
    const handleMessage = (event: MessageEvent) => {
      const { action, data: d } = event.data;
      switch (action) {
        case 'pawnshop:open':
          if (d) { setData(d); setActiveTab('browse'); setSearchQuery(''); setSellItem(null); setSellPrice(''); setSellCount('1'); setBuyQuantity({}); setProcessing(false); }
          break;
        case 'pawnshop:close':
          setData(null);
          break;
        case 'pawnshop:update':
          if (d) setData(d);
          break;
        case 'pawnshop:buyResult':
          setProcessing(false);
          if (d?.success) { showNotification(d.message || 'Achat effectue !', 'success'); setBuyQuantity({}); }
          else { showNotification(d?.message || 'Erreur lors de l\'achat', 'error'); }
          break;
        case 'pawnshop:sellResult':
          setProcessing(false);
          if (d?.success) { showNotification(d.message || 'Annonce creee !', 'success'); setSellItem(null); setSellPrice(''); setSellCount('1'); }
          else { showNotification(d?.message || 'Erreur lors de la mise en vente', 'error'); }
          break;
        case 'pawnshop:cancelResult':
          setProcessing(false);
          if (d?.success) showNotification(d.message || 'Annonce supprimee', 'success');
          else showNotification(d?.message || 'Erreur', 'error');
          break;
        case 'pawnshop:collectResult':
          setProcessing(false);
          if (d?.success) showNotification(d.message || 'Gains encaisses !', 'success');
          else showNotification(d?.message || 'Erreur', 'error');
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
      fetch(`https://${GetParentResourceName()}/pawnshop:close`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({}) });
    }, 300);
  }, [onClose]);

  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => { if (e.key === 'Escape' && visible) handleClose(); };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [visible, handleClose]);

  const handleBuy = async (listing: PawnShopListing, paymentType: 'cash' | 'bank') => {
    if (processing) return;
    const qty = buyQuantity[listing.id] || 1;
    setProcessing(true);
    try { await fetch(`https://${GetParentResourceName()}/pawnshop:buy`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ listingId: listing.id, quantity: qty, paymentType, isNpc: listing.isNpc }) }); } catch { setProcessing(false); }
  };

  const handleSell = async () => {
    if (processing || !sellItem) return;
    const price = parseInt(sellPrice);
    const count = parseInt(sellCount);
    if (!price || price <= 0 || !count || count <= 0) { showNotification('Prix et quantite invalides', 'error'); return; }
    if (count > sellItem.count) { showNotification('Vous n\'avez pas assez de cet item', 'error'); return; }
    setProcessing(true);
    try { await fetch(`https://${GetParentResourceName()}/pawnshop:sell`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ itemName: sellItem.name, itemLabel: sellItem.label, count, pricePerUnit: price }) }); } catch { setProcessing(false); }
  };

  const handleCancel = async (listingId: number) => {
    if (processing) return;
    setProcessing(true);
    try { await fetch(`https://${GetParentResourceName()}/pawnshop:cancel`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ listingId }) }); } catch { setProcessing(false); }
  };

  const handleCollectAll = async () => {
    if (processing || !data || data.pendingSales.length === 0) return;
    setProcessing(true);
    try { await fetch(`https://${GetParentResourceName()}/pawnshop:collectAll`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({}) }); } catch { setProcessing(false); }
  };

  const updateBuyQty = (listingId: number, delta: number, max: number) => {
    setBuyQuantity(prev => {
      const current = prev[listingId] || 1;
      const next = Math.max(1, Math.min(max, current + delta));
      return { ...prev, [listingId]: next };
    });
  };

  const filteredListings = data?.listings.filter(l => !searchQuery || l.itemLabel.toLowerCase().includes(searchQuery.toLowerCase())) || [];
  const npcListings = filteredListings.filter(l => l.isNpc);
  const playerListings = filteredListings.filter(l => !l.isNpc);
  const sellableItems = data?.playerInventory.filter(item => item.count > 0) || [];

  if (!visible || !data) return null;

  const TABS: { key: TabType; label: string; icon: React.ReactNode; badge?: number }[] = [
    { key: 'browse', label: 'Marche', icon: <Store size={16} /> },
    { key: 'sell', label: 'Vendre', icon: <Tag size={16} /> },
    { key: 'mylistings', label: 'Mes Annonces', icon: <ListOrdered size={16} />, badge: data.myListings.length },
    { key: 'revenue', label: 'Revenus', icon: <DollarSign size={16} />, badge: data.pendingSales.length },
  ];

  return (
    <div className={`pawnshop-overlay ${hiding ? 'pawnshop-hiding' : ''}`}>
      <div className="pawnshop-container" style={pawnshopAccentVars as React.CSSProperties}>

        <div className="pawnshop-sidebar">
          <div className="pawnshop-sidebar-header">
            <div className="pawnshop-sidebar-icon" style={{ background: `linear-gradient(135deg, ${accentColor}, ${accentColor}88)` }}>
              <ShoppingBag size={20} />
            </div>
            <div className="pawnshop-sidebar-title">
              <h1>Marche aux Puces</h1>
              <p>Achetez & Vendez</p>
            </div>
          </div>

          <div className="pawnshop-money-section">
            <div className="pawnshop-money-item"><Banknote size={14} /><span>${data.money.cash.toLocaleString()}</span></div>
            <div className="pawnshop-money-item"><CreditCard size={14} /><span>${data.money.bank.toLocaleString()}</span></div>
          </div>

          <nav className="pawnshop-sidebar-nav">
            {TABS.map(tab => (
              <button key={tab.key} className={`pawnshop-sidebar-item ${activeTab === tab.key ? 'active' : ''}`} onClick={() => setActiveTab(tab.key)} style={activeTab === tab.key ? { backgroundColor: accentColor } : {}}>
                {tab.icon}
                <span>{tab.label}</span>
                {tab.badge !== undefined && tab.badge > 0 && <span className="pawnshop-tab-badge" style={{ backgroundColor: accentColor }}>{tab.badge}</span>}
                <ChevronRight size={14} className="pawnshop-sidebar-arrow" />
              </button>
            ))}
          </nav>

          <div className="pawnshop-sidebar-footer">
            <div className="pawnshop-tax-info">
              <AlertCircle size={12} />
              <span>Taxe de vente: {data.saleTax}%</span>
            </div>
            <button className="pawnshop-close-btn" onClick={handleClose}><X size={16} /><span>Fermer</span></button>
          </div>
        </div>

        <div className="pawnshop-content">
          {activeTab === 'browse' && (
            <>
              <div className="pawnshop-content-header">
                <div className="pawnshop-content-header-info">
                  <h2>Parcourir le marche</h2>
                  <p>Items NPC et annonces de joueurs</p>
                </div>
                <div className="pawnshop-search">
                  <Search size={16} />
                  <input ref={searchRef} type="text" placeholder="Rechercher un article..." value={searchQuery} onChange={e => setSearchQuery(e.target.value)} />
                </div>
              </div>

              <div className="pawnshop-browse-content">
                {npcListings.length > 0 && (
                  <div className="pawnshop-section">
                    <h3 className="pawnshop-section-title"><Store size={16} /> Boutique</h3>
                    <div className="pawnshop-items-grid">
                      {npcListings.map(listing => {
                        const qty = buyQuantity[listing.id] || 1;
                        const total = listing.pricePerUnit * qty;
                        return (
                          <div key={listing.id} className="pawnshop-item-card">
                            <ItemImage name={listing.itemName} label={listing.itemLabel} />
                            <div className="pawnshop-item-info">
                              <span className="pawnshop-item-label">{listing.itemLabel}</span>
                              <span className="pawnshop-item-price" style={{ color: accentColor }}>${listing.pricePerUnit.toLocaleString()}</span>
                            </div>
                            <div className="pawnshop-item-bottom">
                              <div className="pawnshop-qty-control">
                                <button onClick={() => updateBuyQty(listing.id, -1, listing.count > 0 ? listing.count : 99)}><Minus size={12} /></button>
                                <span>{qty}</span>
                                <button onClick={() => updateBuyQty(listing.id, 1, listing.count > 0 ? listing.count : 99)}><Plus size={12} /></button>
                              </div>
                              <div className="pawnshop-buy-buttons">
                                <button className="pawnshop-buy-btn" onClick={() => handleBuy(listing, 'cash')} disabled={processing || data.money.cash < total} title="Especes" style={{ borderColor: accentColor, color: accentColor }}><Banknote size={13} /></button>
                                <button className="pawnshop-buy-btn" onClick={() => handleBuy(listing, 'bank')} disabled={processing || data.money.bank < total} title="Carte" style={{ borderColor: accentColor, color: accentColor }}><CreditCard size={13} /></button>
                              </div>
                            </div>
                          </div>
                        );
                      })}
                    </div>
                  </div>
                )}

                {playerListings.length > 0 && (
                  <div className="pawnshop-section">
                    <h3 className="pawnshop-section-title"><User size={16} /> Annonces Joueurs</h3>
                    <div className="pawnshop-items-grid">
                      {playerListings.map(listing => {
                        const qty = buyQuantity[listing.id] || 1;
                        const total = listing.pricePerUnit * qty;
                        return (
                          <div key={listing.id} className="pawnshop-item-card player-listing">
                            <ItemImage name={listing.itemName} label={listing.itemLabel} />
                            <div className="pawnshop-item-info">
                              <span className="pawnshop-item-label">{listing.itemLabel}</span>
                              <span className="pawnshop-item-price" style={{ color: accentColor }}>${listing.pricePerUnit.toLocaleString()}</span>
                              <span className="pawnshop-item-seller"><User size={10} /> {listing.sellerName} &middot; x{listing.count}</span>
                            </div>
                            <div className="pawnshop-item-bottom">
                              <div className="pawnshop-qty-control">
                                <button onClick={() => updateBuyQty(listing.id, -1, listing.count)}><Minus size={12} /></button>
                                <span>{qty}</span>
                                <button onClick={() => updateBuyQty(listing.id, 1, listing.count)}><Plus size={12} /></button>
                              </div>
                              <div className="pawnshop-buy-buttons">
                                <button className="pawnshop-buy-btn" onClick={() => handleBuy(listing, 'cash')} disabled={processing || data.money.cash < total} title="Especes" style={{ borderColor: accentColor, color: accentColor }}><Banknote size={13} /></button>
                                <button className="pawnshop-buy-btn" onClick={() => handleBuy(listing, 'bank')} disabled={processing || data.money.bank < total} title="Carte" style={{ borderColor: accentColor, color: accentColor }}><CreditCard size={13} /></button>
                              </div>
                            </div>
                          </div>
                        );
                      })}
                    </div>
                  </div>
                )}

                {filteredListings.length === 0 && (
                  <div className="pawnshop-empty"><Search size={48} /><p>Aucun article trouve</p></div>
                )}
              </div>
            </>
          )}

          {activeTab === 'sell' && (
            <>
              <div className="pawnshop-content-header">
                <div className="pawnshop-content-header-info">
                  <h2>Mettre en vente</h2>
                  <p>Annonces: {data.myListings.length}/{data.maxListings}</p>
                </div>
              </div>

              <div className="pawnshop-sell-content">
                {!sellItem ? (
                  <>
                    <h3 className="pawnshop-section-title"><Package size={16} /> Choisir un item</h3>
                    {sellableItems.length > 0 ? (
                      <div className="pawnshop-inventory-grid">
                        {sellableItems.map(item => (
                          <button key={item.name} className="pawnshop-inv-item" onClick={() => { setSellItem(item); setSellCount('1'); setSellPrice(''); }}>
                            <ItemImage name={item.name} label={item.label} size={48} />
                            <span className="pawnshop-inv-item-label">{item.label}</span>
                            <span className="pawnshop-inv-item-count">x{item.count}</span>
                          </button>
                        ))}
                      </div>
                    ) : (
                      <div className="pawnshop-empty"><Package size={48} /><p>Aucun item vendable</p></div>
                    )}
                  </>
                ) : (
                  <div className="pawnshop-sell-form">
                    <button className="pawnshop-back-btn" onClick={() => setSellItem(null)}><ChevronRight size={14} style={{ transform: 'rotate(180deg)' }} /> Retour</button>

                    <div className="pawnshop-sell-item-preview">
                      <ItemImage name={sellItem.name} label={sellItem.label} size={52} />
                      <div>
                        <h3>{sellItem.label}</h3>
                        <p>Vous en possedez: x{sellItem.count}</p>
                      </div>
                    </div>

                    <div className="pawnshop-sell-fields">
                      <div className="pawnshop-field">
                        <label>Quantite a vendre</label>
                        <input type="number" min="1" max={sellItem.count} value={sellCount} onChange={e => setSellCount(e.target.value)} placeholder="1" />
                      </div>
                      <div className="pawnshop-field">
                        <label>Prix par unite ($)</label>
                        <input type="number" min="1" value={sellPrice} onChange={e => setSellPrice(e.target.value)} placeholder="100" />
                      </div>
                    </div>

                    {sellPrice && sellCount && parseInt(sellPrice) > 0 && parseInt(sellCount) > 0 && (
                      <div className="pawnshop-sell-summary">
                        <div className="pawnshop-sell-summary-row"><span>Total brut:</span><span>${(parseInt(sellPrice) * parseInt(sellCount)).toLocaleString()}</span></div>
                        <div className="pawnshop-sell-summary-row tax"><span>Taxe ({data.saleTax}%):</span><span>-${Math.floor(parseInt(sellPrice) * parseInt(sellCount) * data.saleTax / 100).toLocaleString()}</span></div>
                        <div className="pawnshop-sell-summary-row total"><span>Vous recevrez:</span><span style={{ color: accentColor }}>${Math.floor(parseInt(sellPrice) * parseInt(sellCount) * (100 - data.saleTax) / 100).toLocaleString()}</span></div>
                      </div>
                    )}

                    <button className="pawnshop-sell-submit" onClick={handleSell} disabled={processing || data.myListings.length >= data.maxListings} style={{ backgroundColor: accentColor }}>
                      <Send size={16} /> Mettre en vente
                    </button>
                    {data.myListings.length >= data.maxListings && (
                      <p className="pawnshop-sell-warning"><AlertCircle size={14} /> Nombre max d'annonces atteint</p>
                    )}
                  </div>
                )}
              </div>
            </>
          )}

          {activeTab === 'mylistings' && (
            <>
              <div className="pawnshop-content-header">
                <div className="pawnshop-content-header-info">
                  <h2>Mes Annonces</h2>
                  <p>{data.myListings.length}/{data.maxListings} annonces actives</p>
                </div>
              </div>

              <div className="pawnshop-mylistings-content">
                {data.myListings.length > 0 ? (
                  <div className="pawnshop-listing-list">
                    {data.myListings.map(listing => (
                      <div key={listing.id} className="pawnshop-listing-row">
                        <ItemImage name={listing.itemName} label={listing.itemLabel} size={36} />
                        <div className="pawnshop-listing-info">
                          <span className="pawnshop-listing-label">{listing.itemLabel}</span>
                          <span className="pawnshop-listing-detail">x{listing.count} @ ${listing.pricePerUnit.toLocaleString()}/u</span>
                        </div>
                        <span className="pawnshop-listing-total" style={{ color: accentColor }}>${(listing.pricePerUnit * listing.count).toLocaleString()}</span>
                        <button className="pawnshop-listing-cancel" onClick={() => handleCancel(listing.id)} disabled={processing}><Trash2 size={14} /> Annuler</button>
                      </div>
                    ))}
                  </div>
                ) : (
                  <div className="pawnshop-empty"><ListOrdered size={48} /><p>Aucune annonce active</p></div>
                )}
              </div>
            </>
          )}

          {activeTab === 'revenue' && (
            <>
              <div className="pawnshop-content-header">
                <div className="pawnshop-content-header-info">
                  <h2>Revenus</h2>
                  <p>Recuperez vos gains de ventes</p>
                </div>
              </div>

              <div className="pawnshop-revenue-content">
                {data.pendingSales.length > 0 ? (
                  <>
                    <div className="pawnshop-revenue-total-card" style={{ borderColor: accentColor }}>
                      <DollarSign size={24} style={{ color: accentColor }} />
                      <div>
                        <span className="pawnshop-revenue-total-label">Total a encaisser</span>
                        <span className="pawnshop-revenue-total-amount" style={{ color: accentColor }}>${data.pendingSalesTotal.toLocaleString()}</span>
                      </div>
                      <button className="pawnshop-collect-all-btn" onClick={handleCollectAll} disabled={processing} style={{ backgroundColor: accentColor }}>
                        <DollarSign size={14} /> Tout encaisser
                      </button>
                    </div>
                    <div className="pawnshop-revenue-list">
                      {data.pendingSales.map(sale => (
                        <div key={sale.id} className="pawnshop-revenue-row">
                          <DollarSign size={16} style={{ color: accentColor }} />
                          <span className="pawnshop-revenue-amount">${sale.amount.toLocaleString()}</span>
                        </div>
                      ))}
                    </div>
                  </>
                ) : (
                  <div className="pawnshop-empty"><DollarSign size={48} /><p>Aucun revenu en attente</p></div>
                )}
              </div>
            </>
          )}
        </div>

        {notification && (
          <div className={`pawnshop-notification ${notification.type}`}>
            {notification.type === 'success' ? <Check size={16} /> : <AlertCircle size={16} />}
            <span>{notification.message}</span>
          </div>
        )}
      </div>
    </div>
  );
};

export default PawnShop;
