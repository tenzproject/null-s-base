import React, { useState, useEffect, useCallback, useMemo, useRef } from 'react';
import {
  X, Home, Map as MapIcon, Building2, History, Search, MapPin,
  ShoppingBag, ChevronLeft, ChevronRight, Image as ImageIcon, Warehouse,
  Wallet, Plus, Minus, ZoomIn, ZoomOut, Locate,
  ArrowDownToLine, ArrowUpFromLine, Check, AlertCircle, Banknote,
  HardHat, Timer,
} from 'lucide-react';
import { generateAccentVars } from '@/utils/accentColors';
import { cacheImg } from '@/shared/cacheVersion';
import {
  RealtorProps, DashboardData, Listing, OwnedProperty, ListingMode,
} from './types';
// Reuse the entire shop tablet styling so the look is identical.
import '../shop/ShopUI.css';
// Realtor-specific extras (map / modals / wallet)
import './Realtor.css';

const GetParentResourceName = () => 'null-core';

// ----------------------------------------------------------------
// Map calibration : world (GTA V) → image pixels (0..1 normalized)
// ----------------------------------------------------------------
// GTA V world bounds covered by the map image
//   Gauche (X min) : -5662   Droite (X max) :  6695
//   Bas    (Y min) : -4040   Haut   (Y max) :  8447
const MAP_BOUNDS = {
  worldMinX: -5662, worldMaxX: 6695,
  worldMinY: -4040, worldMaxY: 8447,
};
const worldToMap = (x: number, y: number) => {
  const u = (x - MAP_BOUNDS.worldMinX) / (MAP_BOUNDS.worldMaxX - MAP_BOUNDS.worldMinX);
  const v = (MAP_BOUNDS.worldMaxY - y) / (MAP_BOUNDS.worldMaxY - MAP_BOUNDS.worldMinY);
  return { u: Math.max(0, Math.min(1, u)), v: Math.max(0, Math.min(1, v)) };
};
const MAP_IMAGE_URL = 'nui://null-cache/images/statellite-named.jpg';

// Sidebar brand (Dynasty 8 style)
const REALTOR_BRAND_BG = '#40e05f';
const REALTOR_BRAND_LOGO = 'https://api.null.fr/media/Dynasty8-GTAV-Logo_1777205175518.webp?v=1777205174255';

const fmt = (n: number) => Math.round(n).toLocaleString('fr-FR');

// ----------------------------------------------------------------
type Tab = 'map' | 'owned' | 'history' | 'construct';

interface ConstructionType {
  label: string;
  basePrice?: number;
}
interface ConstructionCfg {
  Enabled: boolean;
  BuildTime: number;
  Prices: Record<string, number>;
  CommissionPct: number;
}
interface ConstructionEntry {
  name: string;
  label: string;
  interior: string;
  finishesAt: number;
  ownerName: string;
}

const Realtor: React.FC<RealtorProps> = ({ visible, onClose, primaryColor }) => {
  const [data, setData] = useState<DashboardData | null>(null);
  const [hiding, setHiding] = useState(false);
  const [tab, setTab] = useState<Tab>('map');
  const [search, setSearch] = useState('');
  const [selListing, setSelListing] = useState<Listing | null>(null);
  const [selOwned, setSelOwned] = useState<OwnedProperty | null>(null);
  const [photoIdx, setPhotoIdx] = useState(0);

  const [editMode, setEditMode] = useState<ListingMode>('sell');
  const [editSale, setEditSale] = useState<string>('0');
  const [editRent, setEditRent] = useState<string>('0');
  const [rentDays, setRentDays] = useState<number>(7);
  const [notif, setNotif] = useState<{ message: string; type: 'success' | 'error' } | null>(null);

  const [walletOpen, setWalletOpen] = useState(false);
  const [walletMode, setWalletMode] = useState<'deposit' | 'withdraw'>('deposit');
  const [walletAmount, setWalletAmount] = useState<string>('');

  const [constructModal, setConstructModal] = useState(false);
  const [constructType, setConstructType] = useState<string>('');
  const [constructTick, setConstructTick] = useState(0);

  // Tab transition: bump key to remount content with fade-in animation
  const [tabKey, setTabKey] = useState(0);
  const switchTab = (next: Tab) => {
    if (next === tab) return;
    setTab(next);
    setTabKey(k => k + 1);
  };

  const accentColor = primaryColor || '#3498db';
  const accentVars = useMemo(
    () => generateAccentVars('--shopui-accent', accentColor),
    [accentColor]
  );

  // ----------------------------------------------------------------
  // Tick for construction timers
  useEffect(() => {
    if (tab !== 'construct') return;
    const id = setInterval(() => setConstructTick(t => t + 1), 1000);
    return () => clearInterval(id);
  }, [tab]);

  useEffect(() => {
    const onMessage = (event: MessageEvent) => {
      const { action, data: payload } = event.data || {};
      switch (action) {
        case 'realtor:open':
          setData(payload?.dashboard || null);
          setSearch(''); setSelListing(null); setSelOwned(null);
          setPhotoIdx(0); setTab('map'); setTabKey(k => k + 1);
          setWalletOpen(false); setConstructModal(false);
          break;
        case 'realtor:close':
          setData(null); setSelListing(null); setSelOwned(null); setWalletOpen(false);
          break;
        case 'realtor:dataUpdate':
          if (payload) setData(payload);
          break;
        case 'realtor:feedback':
          setNotif({ message: payload?.message || '', type: payload?.type || 'error' });
          setTimeout(() => setNotif(null), 3000);
          break;
      }
    };
    window.addEventListener('message', onMessage);
    return () => window.removeEventListener('message', onMessage);
  }, []);

  const handleClose = useCallback(() => {
    setHiding(true);
    setTimeout(() => {
      setHiding(false); onClose();
      fetch(`https://${GetParentResourceName()}/realtor:close`, {
        method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({}),
      });
    }, 300);
  }, [onClose]);

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key !== 'Escape' || !visible) return;
      if (walletOpen) { setWalletOpen(false); return; }
      if (selListing) { setSelListing(null); return; }
      if (selOwned) { setSelOwned(null); return; }
      handleClose();
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [visible, handleClose, selListing, selOwned, walletOpen]);

  const callNui = useCallback(async (route: string, body: any = {}) => {
    try {
      await fetch(`https://${GetParentResourceName()}/${route}`, {
        method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body),
      });
    } catch { /* ignore */ }
  }, []);

  const handleBuy = (l: Listing) => { callNui('realtor:buy', { listingId: l.id }); setSelListing(null); };
  const handleWaypoint = (x: number, y: number) => callNui('realtor:setWaypoint', { x, y });

  const openOwnedSettings = (p: OwnedProperty) => {
    setSelOwned(p); setEditMode(p.listingMode);
    setEditSale(String(p.salePrice || 0));
    setEditRent(String(p.rentPrice || 0));
    setPhotoIdx(0);
  };

  const saveOwnedSettings = () => {
    if (!selOwned) return;
    callNui('realtor:updateSettings', {
      propName: selOwned.name, mode: editMode,
      salePrice: Number(editSale) || 0, rentPrice: Number(editRent) || 0,
    });
    setSelOwned(null);
  };

  const submitWallet = () => {
    const amt = Number(walletAmount);
    if (!Number.isFinite(amt) || amt <= 0) {
      setNotif({ message: 'Montant invalide', type: 'error' });
      setTimeout(() => setNotif(null), 2500);
      return;
    }
    callNui(walletMode === 'deposit' ? 'realtor:deposit' : 'realtor:withdraw', { amount: amt });
    setWalletAmount(''); setWalletOpen(false);
  };

  // ----------------------------------------------------------------
  const filteredListings = useMemo(() => {
    if (!data) return [];
    const q = search.toLowerCase();
    return data.listings.filter(l =>
      !q ||
      l.neighborhoodLabel.toLowerCase().includes(q) ||
      l.interiorLabel.toLowerCase().includes(q));
  }, [data, search]);

  const filteredOwned = useMemo(() => {
    if (!data) return [];
    const q = search.toLowerCase();
    return data.owned.filter(p =>
      !q ||
      p.neighborhoodLabel.toLowerCase().includes(q) ||
      p.interiorLabel.toLowerCase().includes(q) ||
      p.label.toLowerCase().includes(q));
  }, [data, search]);

  const employeeMapPins = useMemo(
    () => (data ? data.owned.filter(p => !p.rental) : []),
    [data]
  );

  if (!visible || !data) return null;

  const isBoss = data.mode === 'boss';
  const constructions: ConstructionEntry[] = (data as any).constructions || [];
  const constructionCfg: ConstructionCfg | null = (data as any).config?.construction || null;
  const interiorTypes: Record<string, ConstructionType> = (data as any).interiors || {};
  const constructableTypes = constructionCfg
    ? Object.entries(constructionCfg.Prices).map(([key, price]) => ({
      key,
      label: (interiorTypes[key] && interiorTypes[key].label) || key,
      price: price as number,
    }))
    : [];

  return (
    <div className={`shopui-overlay ${hiding ? 'shopui-hiding' : ''}`}>
      <div className="shopui-container" style={accentVars as React.CSSProperties}>

        {/* ============= Sidebar (shop layout) ============= */}
        <div className="shopui-sidebar">
          <div
            className="shopui-brand-hero"
            style={{ background: `linear-gradient(160deg, ${REALTOR_BRAND_BG} 0%, ${REALTOR_BRAND_BG}dd 60%, rgba(0,0,0,0.4) 100%)` }}
          >
            <div className="shopui-brand-hero-shine" />
            <div className="shopui-brand-hero-inner">
              <img
                className="shopui-brand-logo"
                src={REALTOR_BRAND_LOGO}
                alt="Null Immo"
                onError={(e) => { (e.target as HTMLImageElement).style.display = 'none'; }}
              />
              <div className="shopui-brand-hero-text">
                <p>{isBoss ? 'Direction' : 'Employé'}</p>
              </div>
            </div>
          </div>

          {/* Money / wallet — reuses shopui-money-section */}
          <div className="shopui-money-section">
            <button
              className="shopui-money-item realtor-money-btn"
              onClick={() => { setWalletOpen(true); setWalletMode('deposit'); setWalletAmount(''); }}
              title="Gérer la trésorerie de l'agence"
            >
              <Banknote size={14} />
              <span>${fmt(data.societyMoney)}</span>
              <ChevronRight size={12} className="realtor-money-chevron" />
            </button>
          </div>

          {/* Categories (tabs) */}
          <nav className="shopui-sidebar-nav">
            <button
              className={`shopui-sidebar-item ${tab === 'map' ? 'active' : ''}`}
              onClick={() => switchTab('map')}
            >
              {tab === 'map' && <div className="shopui-sidebar-indicator" style={{ background: accentColor }} />}
              <MapIcon size={16} />
              <span>{isBoss ? 'Marché' : 'Carte des biens'}</span>
              <ChevronRight size={14} className="shopui-sidebar-arrow" />
            </button>
            <button
              className={`shopui-sidebar-item ${tab === 'owned' ? 'active' : ''}`}
              onClick={() => switchTab('owned')}
            >
              {tab === 'owned' && <div className="shopui-sidebar-indicator" style={{ background: accentColor }} />}
              <Building2 size={16} />
              <span>Mes biens ({data.owned.length})</span>
              <ChevronRight size={14} className="shopui-sidebar-arrow" />
            </button>
            {isBoss && (
              <button
                className={`shopui-sidebar-item ${tab === 'history' ? 'active' : ''}`}
                onClick={() => switchTab('history')}
              >
                {tab === 'history' && <div className="shopui-sidebar-indicator" style={{ background: accentColor }} />}
                <History size={16} />
                <span>Historique</span>
                <ChevronRight size={14} className="shopui-sidebar-arrow" />
              </button>
            )}
            {constructionCfg?.Enabled && (
              <button
                className={`shopui-sidebar-item ${tab === 'construct' ? 'active' : ''}`}
                onClick={() => switchTab('construct')}
              >
                {tab === 'construct' && <div className="shopui-sidebar-indicator" style={{ background: '#e67e22' }} />}
                <HardHat size={16} />
                <span>Construction{constructions.length > 0 ? ` (${constructions.length})` : ''}</span>
                <ChevronRight size={14} className="shopui-sidebar-arrow" />
              </button>
            )}
          </nav>

          {/* Footer */}
          <div className="shopui-sidebar-footer">
            <button className="shopui-close-btn" onClick={handleClose}>
              <X size={16} /> Fermer
            </button>
          </div>
        </div>

        {/* ============= Content ============= */}
        <div className="shopui-content" key={tabKey}>
          {/* Header */}
          <div className="shopui-content-header">
            <div className="shopui-content-header-info">
              <h2>
                {tab === 'map' && (isBoss ? 'Marché immobilier' : 'Biens à vendre / louer')}
                {tab === 'owned' && 'Mes biens'}
                {tab === 'history' && 'Historique des transactions'}
              </h2>
              <p>
                {tab === 'map' && (isBoss
                  ? `${filteredListings.length} bien(s) actuellement disponibles sur le marché`
                  : `${employeeMapPins.length} bien(s) disponibles à placer`)}
                {tab === 'owned' && `${filteredOwned.length} bien(s) détenu(s) par l'agence`}
                {tab === 'history' && `${data.history.length} transaction(s) enregistrée(s)`}
              </p>
            </div>
            {tab !== 'history' && tab !== 'map' && (
              <div className="shopui-search">
                <Search size={14} />
                <input
                  placeholder="Rechercher..."
                  value={search}
                  onChange={e => setSearch(e.target.value)}
                />
              </div>
            )}
          </div>

          {/* Body */}
          {tab === 'construct' && constructionCfg && (
            <ConstructionTab
              constructions={constructions}
              types={constructableTypes}
              cfg={constructionCfg}
              accentColor={accentColor}
              tick={constructTick}
              onLaunch={() => { setConstructType(constructableTypes[0]?.key || ''); setConstructModal(true); }}
            />
          )}

          {tab === 'map' && isBoss && (
            <PannableMap
              accentColor={accentColor}
              items={filteredListings.map(l => ({
                key: l.id, x: l.door.x, y: l.door.y,
                warehouse: l.warehouse,
                topLabel: `${fmt(l.price)} $`,
                hover: { title: l.interiorLabel, sub: l.neighborhoodLabel, line: `${fmt(l.price)} $` },
                onPick: () => { setSelListing(l); setPhotoIdx(0); },
              }))}
            />
          )}
          {tab === 'map' && !isBoss && (
            <PannableMap
              accentColor={accentColor}
              items={employeeMapPins.map(p => ({
                key: p.name, x: p.positions.EXIT.x, y: p.positions.EXIT.y,
                warehouse: p.warehouse,
                topLabel: p.listingMode === 'rent' ? `${fmt(p.rentPrice)} $/j` : `${fmt(p.salePrice)} $`,
                hover: {
                  title: p.interiorLabel, sub: p.neighborhoodLabel,
                  line: p.listingMode === 'rent' ? `${fmt(p.rentPrice)} $/j` : `${fmt(p.salePrice)} $`,
                },
                onPick: () => openOwnedSettings(p),
              }))}
              emptyMsg="Aucun bien à placer pour le moment."
            />
          )}

          {tab === 'owned' && (
            <OwnedTab
              owned={filteredOwned} accentColor={accentColor}
              onPick={openOwnedSettings} onWaypoint={handleWaypoint}
            />
          )}

          {tab === 'history' && isBoss && (
            <HistoryTab history={data.history} accentColor={accentColor} />
          )}

          {/* Notification */}
          {notif && (
            <div className={`shopui-notification ${notif.type}`}>
              {notif.type === 'success' ? <Check size={14} /> : <AlertCircle size={14} />}
              <span>{notif.message}</span>
            </div>
          )}
        </div>

        {/* ============= Modal: listing detail ============= */}
        {selListing && (
          <div className="realtor-modal-overlay" onClick={() => setSelListing(null)}>
            <div className="realtor-modal" onClick={e => e.stopPropagation()}>
              <button className="realtor-modal-close" onClick={() => setSelListing(null)}>
                <X size={16} />
              </button>
              <PhotoCarousel
                interior={selListing.interior} count={selListing.photos}
                idx={photoIdx} onIdx={setPhotoIdx} warehouse={selListing.warehouse}
              />
              <div className="realtor-modal-body">
                <div className="rmb-head">
                  <span className="rmb-tag">{selListing.neighborhoodLabel}</span>
                  <h3>{selListing.interiorLabel}</h3>
                </div>
                <div className="rmb-grid">
                  <Stat label="Prix d'achat" value={`${fmt(selListing.price)} $`} accent={accentColor} />
                  <Stat label="Vente conseillée" value={`${fmt(selListing.suggestedSale)} $`} />
                  {!selListing.warehouse && (
                    <Stat label="Loyer suggéré" value={`${fmt(selListing.suggestedRent)} $/j`} />
                  )}
                  <Stat label="Type" value={selListing.warehouse ? 'Entrepôt' : 'Habitation'} />
                </div>
                <div className="rmb-actions">
                  <button className="rmb-secondary" onClick={() => handleWaypoint(selListing.door.x, selListing.door.y)}>
                    <MapPin size={14} /> GPS
                  </button>
                  {isBoss && (
                    <button className="rmb-primary" style={{ background: accentColor }} onClick={() => handleBuy(selListing)}>
                      <ShoppingBag size={14} /> Acheter pour {fmt(selListing.price)} $
                    </button>
                  )}
                </div>
              </div>
            </div>
          </div>
        )}

        {/* ============= Modal: owned settings ============= */}
        {selOwned && (
          <div className="realtor-modal-overlay" onClick={() => setSelOwned(null)}>
            <div className="realtor-modal" onClick={e => e.stopPropagation()}>
              <button className="realtor-modal-close" onClick={() => setSelOwned(null)}>
                <X size={16} />
              </button>
              <PhotoCarousel
                interior={selOwned.interior} count={selOwned.photos}
                idx={photoIdx} onIdx={setPhotoIdx} warehouse={selOwned.warehouse}
              />
              <div className="realtor-modal-body">
                <div className="rmb-head">
                  <span className="rmb-tag">{selOwned.neighborhoodLabel}</span>
                  <h3>{selOwned.interiorLabel}</h3>
                </div>
                <div className="rmb-grid">
                  <Stat label="Acheté pour" value={`${fmt(selOwned.boughtFor)} $`} />
                  <Stat label="Statut" value={selOwned.rental ? 'Loué' : 'Disponible'}
                    accent={selOwned.rental ? '#e74c3c' : accentColor} />
                  {selOwned.rental && (
                    <>
                      <Stat label="Locataire" value={selOwned.rental.tenantName} />
                      <Stat label="Fin du bail" value={new Date(selOwned.rental.expiresAt * 1000).toLocaleDateString('fr-FR')} />
                    </>
                  )}
                </div>

                {isBoss && !selOwned.rental && (
                  <div className="rmb-form">
                    <div className="rmb-form-row">
                      <label>Mode de mise sur le marché</label>
                      <div className="rmb-segmented">
                        <button className={editMode === 'sell' ? 'active' : ''} onClick={() => setEditMode('sell')}>
                          Vente
                        </button>
                        <button className={editMode === 'rent' ? 'active' : ''} onClick={() => setEditMode('rent')} disabled={selOwned.warehouse}>
                          Location
                        </button>
                      </div>
                    </div>
                    {editMode === 'sell' && (
                      <div className="rmb-form-row">
                        <label>Prix de vente public ($)</label>
                        <input type="number" min={1} value={editSale} onChange={e => setEditSale(e.target.value)} />
                      </div>
                    )}
                    {editMode === 'rent' && (
                      <div className="rmb-form-row">
                        <label>Loyer / jour ($)</label>
                        <input type="number" min={1} value={editRent} onChange={e => setEditRent(e.target.value)} />
                      </div>
                    )}
                    <div className="rmb-actions">
                      <button className="rmb-secondary" onClick={() => handleWaypoint(selOwned.positions.EXIT.x, selOwned.positions.EXIT.y)}>
                        <MapPin size={14} /> GPS
                      </button>
                      <button className="rmb-primary" style={{ background: accentColor }} onClick={saveOwnedSettings}>
                        Enregistrer
                      </button>
                    </div>
                  </div>
                )}

                {!isBoss && !selOwned.rental && (
                  <div className="rmb-form">
                    <div className="rmb-form-row">
                      <label>Mode configuré par la direction</label>
                      <div className="rmb-info-pill" style={{ borderColor: accentColor, color: accentColor }}>
                        {selOwned.listingMode === 'rent'
                          ? `Location — ${fmt(selOwned.rentPrice)} $/jour`
                          : `Vente — ${fmt(selOwned.salePrice)} $`}
                      </div>
                    </div>
                    {selOwned.listingMode === 'rent' && !selOwned.warehouse && (
                      <div className="rmb-form-row">
                        <label>Durée du bail (jours)</label>
                        <input
                          type="number"
                          min={data.config.minRentalDays}
                          max={data.config.maxRentalDays}
                          value={rentDays}
                          onChange={e => setRentDays(Math.max(
                            data.config.minRentalDays,
                            Math.min(data.config.maxRentalDays, Number(e.target.value) || data.config.minRentalDays)
                          ))}
                        />
                        <span className="rmb-form-hint">
                          Total : {fmt(selOwned.rentPrice * rentDays)} $ ({data.config.minRentalDays}-{data.config.maxRentalDays} jours)
                        </span>
                      </div>
                    )}
                    <div className="rmb-actions">
                      <button className="rmb-secondary" onClick={() => handleWaypoint(selOwned.positions.EXIT.x, selOwned.positions.EXIT.y)}>
                        <MapPin size={14} /> GPS
                      </button>
                      {selOwned.listingMode === 'sell' && (
                        <button className="rmb-primary" style={{ background: accentColor }}
                          onClick={() => callNui('realtor:sellToPlayer', { propName: selOwned.name })}>
                          <ShoppingBag size={14} /> Vendre au joueur proche
                        </button>
                      )}
                      {selOwned.listingMode === 'rent' && !selOwned.warehouse && (
                        <button className="rmb-primary" style={{ background: accentColor }}
                          onClick={() => callNui('realtor:rentToPlayer', { propName: selOwned.name, days: rentDays })}>
                          <ShoppingBag size={14} /> Louer pour {rentDays}j
                        </button>
                      )}
                    </div>
                  </div>
                )}

                {!isBoss && selOwned.rental && (
                  <div className="rmb-actions">
                    <button className="rmb-secondary" onClick={() => handleWaypoint(selOwned.positions.EXIT.x, selOwned.positions.EXIT.y)}>
                      <MapPin size={14} /> GPS
                    </button>
                  </div>
                )}
              </div>
            </div>
          </div>
        )}

        {/* ============= Modal: wallet ============= */}
        {walletOpen && (
          <div className="realtor-modal-overlay" onClick={() => setWalletOpen(false)}>
            <div className="realtor-modal realtor-wallet-modal" onClick={e => e.stopPropagation()}>
              <button className="realtor-modal-close" onClick={() => setWalletOpen(false)}>
                <X size={16} />
              </button>
              <div className="realtor-wallet-head" style={{ background: `linear-gradient(135deg, ${accentColor}33, transparent 70%)` }}>
                <div className="rwh-icon" style={{ background: accentColor }}>
                  <Wallet size={22} />
                </div>
                <div className="rwh-text">
                  <span>Coffre de l'agence</span>
                  <strong style={{ color: accentColor }}>{fmt(data.societyMoney)} $</strong>
                </div>
              </div>
              <div className="realtor-modal-body">
                <div className="rmb-segmented rwallet-tabs">
                  <button className={walletMode === 'deposit' ? 'active' : ''} onClick={() => setWalletMode('deposit')}>
                    <ArrowDownToLine size={14} /> Déposer
                  </button>
                  <button className={walletMode === 'withdraw' ? 'active' : ''} onClick={() => setWalletMode('withdraw')}
                    disabled={!isBoss} title={!isBoss ? 'Réservé à la direction' : ''}>
                    <ArrowUpFromLine size={14} /> Retirer
                  </button>
                </div>
                <div className="rmb-form-row" style={{ marginTop: 14 }}>
                  <label>Montant ($)</label>
                  <input type="number" min={1} value={walletAmount}
                    onChange={e => setWalletAmount(e.target.value)}
                    onKeyDown={e => { if (e.key === 'Enter') submitWallet(); }}
                    placeholder="0" autoFocus />
                  <div className="rwallet-quick">
                    {[100, 500, 1000, 5000, 10000].map(q => (
                      <button key={q} onClick={() => setWalletAmount(String((Number(walletAmount) || 0) + q))}>
                        +{fmt(q)}
                      </button>
                    ))}
                    <button onClick={() => setWalletAmount('')}>Reset</button>
                  </div>
                </div>
                <div className="rmb-actions">
                  <button className="rmb-secondary" onClick={() => setWalletOpen(false)}>Annuler</button>
                  <button className="rmb-primary" style={{ background: accentColor }}
                    onClick={submitWallet}
                    disabled={!walletAmount || Number(walletAmount) <= 0 || (walletMode === 'withdraw' && !isBoss)}>
                    {walletMode === 'deposit' ? <Plus size={14} /> : <Minus size={14} />}
                    {walletMode === 'deposit' ? 'Déposer' : 'Retirer'}
                  </button>
                </div>
              </div>
            </div>
          </div>
        )}

        {/* ============= Modal: lancement construction ============= */}
        {constructModal && constructionCfg && (
          <div className="realtor-modal-overlay" onClick={() => setConstructModal(false)}>
            <div className="realtor-modal" onClick={e => e.stopPropagation()}>
              <button className="realtor-modal-close" onClick={() => setConstructModal(false)}><X size={16} /></button>
              <div className="realtor-construct-head">
                <div className="rch-icon" style={{ background: '#e67e22' }}>
                  <HardHat size={24} />
                </div>
                <div>
                  <h3>Lancer une construction</h3>
                  <p>Le client le plus proche sera facturé. La maison sera disponible dans {Math.round(constructionCfg.BuildTime / 3600)}h.</p>
                </div>
              </div>
              <div className="realtor-modal-body">
                <div className="rmb-form-row">
                  <label>Type de bien à construire</label>
                  <div className="realtor-construct-type-grid">
                    {constructableTypes.map(t => (
                      <button
                        key={t.key}
                        className={`rct-type-btn ${constructType === t.key ? 'active' : ''}`}
                        style={constructType === t.key ? { borderColor: '#e67e22', background: 'rgba(230,126,34,0.12)' } : {}}
                        onClick={() => setConstructType(t.key)}
                      >
                        <HardHat size={16} />
                        <span>{t.label}</span>
                        <strong>{fmt(t.price)} $</strong>
                      </button>
                    ))}
                  </div>
                </div>
                <div className="rmb-actions">
                  <button className="rmb-secondary" onClick={() => setConstructModal(false)}>Annuler</button>
                  <button
                    className="rmb-primary"
                    style={{ background: '#e67e22' }}
                    disabled={!constructType}
                    onClick={() => {
                      if (!constructType) return;
                      setConstructModal(false);
                      fetch(`https://${GetParentResourceName()}/realtor:construct`, {
                        method: 'POST',
                        headers: { 'Content-Type': 'application/json' },
                        body: JSON.stringify({ interiorType: constructType }),
                      });
                    }}
                  >
                    <HardHat size={14} /> Lancer la construction
                  </button>
                </div>
              </div>
            </div>
          </div>
        )}

      </div>
    </div>
  );
};

// ================================================================
// Subcomponents
// ================================================================

const fmtDuration = (secs: number): string => {
  if (secs <= 0) return 'Terminé';
  const h = Math.floor(secs / 3600);
  const m = Math.floor((secs % 3600) / 60);
  const s = secs % 60;
  if (h > 0) return `${h}h ${m.toString().padStart(2, '0')}m`;
  if (m > 0) return `${m}m ${s.toString().padStart(2, '0')}s`;
  return `${s}s`;
};

const ConstructionTab: React.FC<{
  constructions: ConstructionEntry[];
  types: { key: string; label: string; price: number }[];
  cfg: ConstructionCfg;
  accentColor: string;
  tick: number;
  onLaunch: () => void;
}> = ({ constructions, cfg, accentColor, tick, onLaunch }) => {
  const nowSec = Math.floor(Date.now() / 1000);
  return (
    <div className="realtor-construct-tab">
      <div className="rct-header">
        <div className="rct-header-info">
          <HardHat size={20} style={{ color: '#e67e22' }} />
          <div>
            <h3>Chantiers en cours</h3>
            <p>Durée de construction : {Math.round(cfg.BuildTime / 3600)}h · Commission : {Math.round(cfg.CommissionPct * 100)}%</p>
          </div>
        </div>
        <button className="rct-launch-btn" style={{ background: '#e67e22' }} onClick={onLaunch}>
          <HardHat size={14} /> Nouvelle construction
        </button>
      </div>

      {constructions.length === 0 ? (
        <div className="rct-empty">
          <HardHat size={40} />
          <span>Aucun chantier en cours</span>
          <p>Lancez une construction auprès d'un client à proximité.</p>
        </div>
      ) : (
        <div className="rct-list">
          {constructions.map(c => {
            const remaining = c.finishesAt - nowSec;
            const pct = Math.max(0, Math.min(100, (1 - remaining / cfg.BuildTime) * 100));
            return (
              <div key={c.name} className="rct-item">
                <div className="rct-item-icon" style={{ background: 'rgba(230,126,34,0.15)', color: '#e67e22' }}>
                  <HardHat size={18} />
                </div>
                <div className="rct-item-body">
                  <div className="rct-item-top">
                    <span className="rct-item-label">{c.label}</span>
                    <span className="rct-item-owner">{c.ownerName}</span>
                  </div>
                  <div className="rct-item-progress">
                    <div className="rct-progress-bar">
                      <div className="rct-progress-fill" style={{ width: `${pct}%`, background: '#e67e22' }} />
                    </div>
                    <span className="rct-progress-label">
                      {remaining > 0 ? (
                        <><Timer size={11} /> {fmtDuration(remaining)}</>
                      ) : (
                        <><Check size={11} style={{ color: '#2ecc71' }} /> Terminé — en attente de sync</>
                      )}
                    </span>
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
};
const Stat: React.FC<{ label: string; value: string; accent?: string }> = ({ label, value, accent }) => (
  <div className="realtor-stat">
    <span className="rs-l">{label}</span>
    <span className="rs-v" style={accent ? { color: accent } : undefined}>{value}</span>
  </div>
);

const PhotoCarousel: React.FC<{
  interior: string; count: number; idx: number; onIdx: (n: number) => void; warehouse: boolean;
}> = ({ interior, count, idx, onIdx, warehouse }) => {
  const safeCount = Math.max(1, count);
  const prev = () => onIdx((idx - 1 + safeCount) % safeCount);
  const next = () => onIdx((idx + 1) % safeCount);
  const src = cacheImg(`realtors/interiors/${interior}_${idx + 1}.webp`);

  return (
    <div className="realtor-carousel">
      <img src={src} alt={interior}
        onError={(e) => { (e.target as HTMLImageElement).style.display = 'none'; }} />
      <div className="realtor-carousel-fallback">
        {warehouse ? <Warehouse size={56} /> : <ImageIcon size={56} />}
        <span>{interior}</span>
      </div>
      {safeCount > 1 && (
        <>
          <button className="realtor-carousel-arrow left" onClick={prev}><ChevronLeft size={18} /></button>
          <button className="realtor-carousel-arrow right" onClick={next}><ChevronRight size={18} /></button>
          <div className="realtor-carousel-dots">
            {Array.from({ length: safeCount }).map((_, i) => (
              <span key={i} className={i === idx ? 'active' : ''} onClick={() => onIdx(i)} />
            ))}
          </div>
        </>
      )}
    </div>
  );
};

// ================================================================
// Pannable + zoomable map
// ================================================================
type MapPinItem = {
  key: string;
  x: number; y: number;
  warehouse: boolean;
  topLabel: string;
  hover: { title: string; sub: string; line: string };
  onPick: () => void;
};

const ZOOM_MIN = 1;
const ZOOM_MAX = 5;
const INITIAL_ZOOM = 2.2;

const PannableMap: React.FC<{
  items: MapPinItem[]; accentColor: string; emptyMsg?: string;
}> = ({ items, accentColor, emptyMsg }) => {
  const wrapRef = useRef<HTMLDivElement>(null);
  const [zoom, setZoom] = useState(INITIAL_ZOOM);
  const [pan, setPan] = useState({ x: 0, y: 0 });
  const [drag, setDrag] = useState<{ x: number; y: number; px: number; py: number } | null>(null);
  const [hover, setHover] = useState<MapPinItem | null>(null);
  const [canvasSize, setCanvasSize] = useState({ w: 0, h: 0 });
  const [imgAspect, setImgAspect] = useState(1);

  useEffect(() => {
    const el = wrapRef.current;
    if (!el) return;
    const ro = new ResizeObserver(() => {
      setCanvasSize({ w: el.clientWidth, h: el.clientHeight });
    });
    ro.observe(el);
    setCanvasSize({ w: el.clientWidth, h: el.clientHeight });
    return () => ro.disconnect();
  }, []);

  const stageSize = useMemo(() => {
    if (canvasSize.w === 0 || canvasSize.h === 0) return { w: 0, h: 0 };
    const ca = canvasSize.w / canvasSize.h;
    if (ca > imgAspect) return { w: canvasSize.h * imgAspect, h: canvasSize.h };
    return { w: canvasSize.w, h: canvasSize.w / imgAspect };
  }, [canvasSize, imgAspect]);

  const clamp = useCallback((p: { x: number; y: number }, z: number) => {
    if (stageSize.w === 0) return { x: 0, y: 0 };
    const maxX = Math.max(0, (stageSize.w * z - canvasSize.w) / 2);
    const maxY = Math.max(0, (stageSize.h * z - canvasSize.h) / 2);
    return {
      x: Math.max(-maxX, Math.min(maxX, p.x)),
      y: Math.max(-maxY, Math.min(maxY, p.y)),
    };
  }, [stageSize, canvasSize]);

  useEffect(() => { setPan(p => clamp(p, zoom)); }, [zoom, clamp]);

  const onWheel = (e: React.WheelEvent) => {
    e.preventDefault();
    const factor = e.deltaY < 0 ? 1.15 : 1 / 1.15;
    setZoom(z => Math.max(ZOOM_MIN, Math.min(ZOOM_MAX, z * factor)));
  };
  const onMouseDown = (e: React.MouseEvent) => {
    if (e.button !== 0) return;
    setDrag({ x: e.clientX, y: e.clientY, px: pan.x, py: pan.y });
  };
  const onMouseMove = (e: React.MouseEvent) => {
    if (!drag) return;
    setPan(clamp({ x: drag.px + (e.clientX - drag.x), y: drag.py + (e.clientY - drag.y) }, zoom));
  };
  const stopDrag = () => setDrag(null);

  const reset = () => { setZoom(INITIAL_ZOOM); setPan({ x: 0, y: 0 }); };
  const zoomIn = () => setZoom(z => Math.min(ZOOM_MAX, z * 1.25));
  const zoomOut = () => setZoom(z => Math.max(ZOOM_MIN, z / 1.25));

  const isEmpty = items.length === 0 && !!emptyMsg;

  return (
    <div className="realtor-map-wrap" ref={wrapRef}>
      <div className={`realtor-map-canvas ${drag ? 'dragging' : ''}`}
        onWheel={onWheel} onMouseDown={onMouseDown}
        onMouseMove={onMouseMove} onMouseUp={stopDrag} onMouseLeave={stopDrag}>
        <div className="realtor-map-stage"
          style={{
            width: stageSize.w ? `${stageSize.w}px` : '100%',
            height: stageSize.h ? `${stageSize.h}px` : '100%',
            transform: `translate3d(${pan.x}px, ${pan.y}px, 0) scale(${zoom})`,
          }}>
          <img className="realtor-map-bg" src={MAP_IMAGE_URL} alt="GTA Map" draggable={false}
            onLoad={(e) => {
              const t = e.target as HTMLImageElement;
              if (t.naturalWidth && t.naturalHeight) {
                setImgAspect(t.naturalWidth / t.naturalHeight);
              }
            }} />
          <div className="realtor-map-overlay">
            {items.map(it => {
              const { u, v } = worldToMap(it.x, it.y);
              return (
                <button key={it.key} className="realtor-map-pin"
                  style={{
                    left: `${u * 100}%`, top: `${v * 100}%`,
                    color: accentColor,
                    transform: `translate(-50%, -100%) scale(${1 / zoom})`,
                  }}
                  onClick={(e) => { e.stopPropagation(); it.onPick(); }}
                  onMouseDown={(e) => e.stopPropagation()}
                  onMouseEnter={() => setHover(it)}
                  onMouseLeave={() => setHover(null)}
                  title={`${it.hover.title} — ${it.hover.sub}`}>
                  <span className="rmp-icon">
                    {it.warehouse ? <Warehouse size={14} /> : <Home size={14} />}
                  </span>
                  <span className="rmp-price">{it.topLabel}</span>
                  <span className="rmp-pulse" style={{ background: accentColor }} />
                </button>
              );
            })}
          </div>
        </div>

        <div className="realtor-map-controls">
          <button onClick={zoomIn} title="Zoomer"><ZoomIn size={14} /></button>
          <button onClick={zoomOut} title="Dézoomer"><ZoomOut size={14} /></button>
          <button onClick={reset} title="Recentrer"><Locate size={14} /></button>
        </div>
        <div className="realtor-map-hint">
          Maintenez clic gauche pour déplacer • Molette pour zoomer
        </div>

        {hover && (
          <div className="realtor-map-tooltip">
            <strong>{hover.hover.title}</strong>
            <span>{hover.hover.sub}</span>
            <span style={{ color: accentColor }}>{hover.hover.line}</span>
          </div>
        )}
      </div>

      {isEmpty && (
        <div className="realtor-map-empty">
          <MapIcon size={36} />
          <p>{emptyMsg}</p>
        </div>
      )}
    </div>
  );
};

// ----------------------------------------------------------------
// Owned grid (uses shopui-items-grid + own card)
// ----------------------------------------------------------------
const OwnedTab: React.FC<{
  owned: OwnedProperty[]; accentColor: string;
  onPick: (p: OwnedProperty) => void; onWaypoint: (x: number, y: number) => void;
}> = ({ owned, accentColor, onPick, onWaypoint }) => {
  if (owned.length === 0) {
    return (
      <div className="shopui-empty">
        <Building2 size={48} />
        <p>Aucun bien actuellement détenu par l'agence.</p>
      </div>
    );
  }
  return (
    <div className="realtor-owned-grid">
      {owned.map(p => (
        <div key={p.name} className="realtor-card" onClick={() => onPick(p)}>
          <div className="realtor-card-photo">
            <img src={cacheImg(`realtors/interiors/${p.interior}_1.webp`)} alt={p.interior}
              onError={(e) => { (e.target as HTMLImageElement).style.display = 'none'; }} />
            <div className="realtor-card-photo-fallback">
              {p.warehouse ? <Warehouse size={40} /> : <ImageIcon size={40} />}
            </div>
            <span className={`realtor-card-status ${p.rental ? 'rented' : 'free'}`}>
              {p.rental ? 'Loué' : (p.listingMode === 'rent' ? 'À louer' : 'À vendre')}
            </span>
          </div>
          <div className="realtor-card-body">
            <div className="realtor-card-title">{p.interiorLabel}</div>
            <div className="realtor-card-sub">{p.neighborhoodLabel}</div>
            <div className="realtor-card-foot">
              <span className="rcf-price" style={{ color: accentColor }}>
                {p.listingMode === 'rent' ? `${fmt(p.rentPrice)} $/j` : `${fmt(p.salePrice)} $`}
              </span>
              <button className="rcf-gps"
                onClick={(e) => { e.stopPropagation(); onWaypoint(p.positions.EXIT.x, p.positions.EXIT.y); }}
                title="GPS">
                <MapPin size={14} />
              </button>
            </div>
          </div>
        </div>
      ))}
    </div>
  );
};

// ----------------------------------------------------------------
const HistoryTab: React.FC<{ history: any[]; accentColor: string }> = ({ history, accentColor }) => {
  if (history.length === 0) {
    return (
      <div className="shopui-empty">
        <History size={48} />
        <p>Aucune transaction enregistrée.</p>
      </div>
    );
  }
  return (
    <div className="realtor-history">
      <table>
        <thead>
          <tr>
            <th>Date</th><th>Bien</th><th>Quartier</th><th>Mode</th>
            <th>Vendeur</th><th>Acheteur</th><th>Durée</th>
            <th style={{ textAlign: 'right' }}>Montant</th>
          </tr>
        </thead>
        <tbody>
          {history.map(h => (
            <tr key={h.id}>
              <td>{h.created_at}</td>
              <td>{h.property_label}</td>
              <td>{h.neighborhood}</td>
              <td><span className={`hbadge ${h.mode}`}>{h.mode === 'rent' ? 'Location' : 'Vente'}</span></td>
              <td>{h.seller_name}</td>
              <td>{h.buyer_name}</td>
              <td>{h.days > 0 ? `${h.days} j` : '—'}</td>
              <td style={{ textAlign: 'right', color: accentColor, fontWeight: 600 }}>{fmt(h.price)} $</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
};

export default Realtor;
