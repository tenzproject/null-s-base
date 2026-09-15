import React, { useState, useEffect, useCallback, useRef, useMemo } from 'react';
import { generateAccentVars } from '@/utils/accentColors';
import { BoutiqueProps, BoutiqueItem, DailyShopItem, UserInfo, BoutiquePage, PlayerWeaponSummary, NightMarketCard } from './types';
import { X, ArrowLeft, ExternalLink, Star, Swords, Check, Flame } from 'lucide-react';
import BoutiqueHome from './pages/BoutiqueHome';
import BoutiqueDailyShop from './pages/BoutiqueDailyShop';
import BoutiqueItems from './pages/BoutiqueItems';
import BoutiqueCrates from './pages/BoutiqueCrates';
import BoutiqueDetail from './components/BoutiqueDetail';
import BoutiqueNightMarket from './pages/BoutiqueNightMarket';
import BoutiqueVIP from './pages/BoutiqueVIP';
import BoutiqueBattlePass from './pages/BoutiqueBattlePass';
import WaveBackground from '@/components/WaveBackground';
import './Boutique.css';

const GetParentResourceName = () => 'null-core';

const PAGE_TITLES: Record<BoutiquePage, string> = {
  home: 'Accueil',
  daily: 'Boutique du jour',
  vehicles: 'Véhicules',
  weapons: 'Armes',
  packs: 'Packs',
  boosts: 'Boosts',
  crates: 'Caisses',
  customization: "Personnalisation d'armes",
  nightmarket: 'Night Market',
  history: 'Historique',
  vip: 'VIP',
  battlepass: 'Passe de Combat',
};

const Boutique: React.FC<BoutiqueProps> = ({ visible, onClose, primaryColor, initialData, serverConfig }) => {
  const overlayRef = useRef<HTMLDivElement | null>(null);
  const [serverBackground, setServerBackground] = useState<string>(serverConfig.serverBackground || '');

  useEffect(() => {
    // Synchronise aussi une valeur vide : le Panel Admin doit pouvoir retirer
    // une ancienne bannière sans devoir fermer puis rouvrir la boutique.
    setServerBackground(serverConfig.serverBackground || '');
  }, [serverConfig.serverBackground]);

  useEffect(() => {
    if (!overlayRef.current) return;
    if (serverBackground) {
      overlayRef.current.style.setProperty('--bq-server-bg', `url("${serverBackground}")`);
    } else {
      overlayRef.current.style.removeProperty('--bq-server-bg');
    }
  }, [serverBackground, visible]);

  const boutiqueAccentVars = useMemo(
    () => generateAccentVars('--boutique-accent', primaryColor),
    [primaryColor]
  );
  const [currentPage, setCurrentPage] = useState<BoutiquePage>('home');
  const [items, setItems] = useState<Record<string, BoutiqueItem[]>>({});
  const [dailyItems, setDailyItems] = useState<DailyShopItem[]>([]);
  const [userInfo, setUserInfo] = useState<UserInfo>({ coins: 0 });
  const [selectedItem, setSelectedItem] = useState<BoutiqueItem | DailyShopItem | null>(null);
  const [detailOpen, setDetailOpen] = useState(false);
  const [notification, setNotification] = useState<{ message: string; type: 'success' | 'error' } | null>(null);
  const [hiding, setHiding] = useState(false);
  const [boutiqueLink, setBoutiqueLink] = useState('');
  const [previewMode, setPreviewMode] = useState(false);
  const [pageTransition, setPageTransition] = useState(false);
  const pageTransitionRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const [playerWeapons, setPlayerWeapons] = useState<PlayerWeaponSummary[]>([]);
  const [nightMarketActive, setNightMarketActive] = useState(false);
  const [nightMarketCards, setNightMarketCards] = useState<NightMarketCard[]>([]);
  const [nightMarketTimeLeft, setNightMarketTimeLeft] = useState(0);

  const normalizeItems = useCallback((rawItems: any = {}) => ({
    vehicles: rawItems.vehicles || rawItems.vehicle || [],
    weapons: rawItems.weapons || rawItems.weapon || [],
    packs: rawItems.packs || rawItems.pack || [],
    boosts: rawItems.boosts || rawItems.boost || [],
    crates: rawItems.crates || rawItems.crate || [],
  }), []);

  const normalizeCategory = useCallback((category: string) => {
    const aliases: Record<string, string> = {
      vehicle: 'vehicles',
      weapon: 'weapons',
      pack: 'packs',
      boost: 'boosts',
      crate: 'crates',
    };
    return aliases[category] || category;
  }, []);

  const applyOpenData = useCallback((data: any) => {
    if (!data) return;

    if (data.userInfo) setUserInfo(data.userInfo);
    if (data.items) setItems(normalizeItems(data.items));
    if (data.dailyItems) setDailyItems(data.dailyItems);
    if (data.boutiqueLink) setBoutiqueLink(data.boutiqueLink);
    if (Object.prototype.hasOwnProperty.call(data, 'serverBackground')) {
      setServerBackground(data.serverBackground || '');
    }
    if (data.nightMarket) {
      setNightMarketActive(data.nightMarket.active || false);
      setNightMarketCards((data.nightMarket.cards || []).map((c: any) => ({ ...c, revealed: false })));
      setNightMarketTimeLeft(data.nightMarket.timeLeft || 0);
    }
    setCurrentPage('home');
    setDetailOpen(false);
    setSelectedItem(null);
    setHiding(false);
    setPreviewMode(false);
  }, [normalizeItems]);

  useEffect(() => {
    if (visible) applyOpenData(initialData);
  }, [visible, initialData, applyOpenData]);

  useEffect(() => {
    const handleMessage = (event: MessageEvent) => {
      const data = event.data;
      switch (data.action || data.type) {
        case 'boutique:open':
          applyOpenData(data);
          break;
        case 'boutique:updateCoins':
          setUserInfo(prev => ({ ...prev, coins: data.coins }));
          break;
        case 'boutique:items':
          setItems(prev => ({ ...prev, [normalizeCategory(data.category)]: data.items || [] }));
          break;
        case 'boutique:dailyItems':
          setDailyItems(data.items || []);
          break;
        case 'boutique:purchaseResult':
          if (data.success) {
            showNotification(data.message || 'Achat effectué !', 'success');
            if (data.coins !== undefined) setUserInfo(prev => ({ ...prev, coins: data.coins }));
          } else {
            showNotification(data.message || "Erreur lors de l'achat", 'error');
          }
          break;
        case 'boutique:crateResult':
          if (data.reward) {
            showNotification(`Tu as obtenu : ${data.reward.label} !`, 'success');
            if (data.coins !== undefined) setUserInfo(prev => ({ ...prev, coins: data.coins }));
          }
          break;
        case 'boutique:startPreview':
          setPreviewMode(true);
          break;
        case 'boutique:stopPreview':
          setPreviewMode(false);
          break;
        case 'boutique:previewDenied':
          showNotification('Tu dois être en safezone pour prévisualiser un véhicule.', 'error');
          break;
        case 'boutique:weaponsList':
          if (data.weapons) {
            setPlayerWeapons(data.weapons.map((w: any) => ({
              name: w.name,
              label: w.label,
              componentCount: (w.components || []).filter((c: any) => c.hash).length,
              installedCount: (w.components || []).filter((c: any) => c.hash && c.installed).length,
            })));
          }
          break;
        case 'boutique:nightmarket:started':
          setNightMarketActive(true);
          break;
        case 'boutique:nightmarket:stopped':
          setNightMarketActive(false);
          setNightMarketCards([]);
          if (currentPage === 'nightmarket') setCurrentPage('home');
          break;
      }
    };
    window.addEventListener('message', handleMessage);
    return () => window.removeEventListener('message', handleMessage);
  }, [applyOpenData, currentPage, normalizeCategory]);

  useEffect(() => {
    if (!visible) return;
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        if (previewMode) handleStopPreview();
        else if (detailOpen) { setDetailOpen(false); setSelectedItem(null); }
        else if (currentPage !== 'home') handlePageChange('home');
        else handleClose();
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [visible, detailOpen, previewMode, currentPage]);

  const showNotification = (message: string, type: 'success' | 'error') => {
    // setNotification({ message, type });
    // setTimeout(() => setNotification(null), 3000);
  };

  const handleClose = useCallback(() => {
    setHiding(true);
    fetch(`https://${GetParentResourceName()}/boutique:close`, { method: 'POST' });
    setTimeout(() => { setHiding(false); onClose(); }, 300);
  }, [onClose]);

  const handlePurchase = useCallback((item: BoutiqueItem | DailyShopItem, quantity?: number) => {
    fetch(`https://${GetParentResourceName()}/boutique:purchase`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        id: item.id,
        category: 'category' in item ? item.category : item.type,
        quantity: quantity || 1,
        price: item.price,
      }),
    });
  }, []);

  const handleOpenCrate = useCallback((crateId: string, quantity: number) => {
    fetch(`https://${GetParentResourceName()}/boutique:openCrate`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ crateId, quantity }),
    });
  }, []);

  const handleOpenTebex = useCallback(() => {
    if (!boutiqueLink) return;
    const url = 'https://' + boutiqueLink;
    fetch(`https://${GetParentResourceName()}/boutique:openTebex`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ url }),
    });
  }, [boutiqueLink]);

  const handlePreviewVehicle = useCallback((model: string, item?: BoutiqueItem | DailyShopItem) => {
    const itemData = item ? {
      id: item.id,
      category: 'category' in item ? item.category : item.type,
      price: item.price,
    } : undefined;
    fetch(`https://${GetParentResourceName()}/boutique:previewVehicle`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ model, itemData }),
    });
  }, []);

  const handleRotatePreview = useCallback((direction: 'left' | 'right') => {
    fetch(`https://${GetParentResourceName()}/boutique:rotate`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ direction }),
    });
  }, []);

  const handleStopPreview = useCallback(() => {
    fetch(`https://${GetParentResourceName()}/boutique:stopPreview`, { method: 'POST' });
    setPreviewMode(false);
  }, []);

  const handleBuyFromPreview = useCallback(() => {
    fetch(`https://${GetParentResourceName()}/boutique:buyFromPreview`, { method: 'POST' });
    setPreviewMode(false);
  }, []);

  const handleItemClick = (item: BoutiqueItem | DailyShopItem) => {
    setSelectedItem(item);
    setDetailOpen(true);
  };

  const handlePageChange = (page: BoutiquePage) => {
    if (page === currentPage) return;
    setDetailOpen(false);
    setSelectedItem(null);

    if (['vehicles', 'weapons', 'packs', 'boosts', 'crates'].includes(page)) {
      fetch(`https://${GetParentResourceName()}/boutique:getItems`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ category: page }),
      });
    }

    if (page === 'customization') {
      fetch(`https://${GetParentResourceName()}/boutique:getWeapons`, { method: 'POST' });
    }

    if (pageTransitionRef.current) {
      clearTimeout(pageTransitionRef.current);
      pageTransitionRef.current = null;
    }

    setPageTransition(true);
    pageTransitionRef.current = setTimeout(() => {
      pageTransitionRef.current = null;
      setCurrentPage(page);
      requestAnimationFrame(() => {
        requestAnimationFrame(() => setPageTransition(false));
      });
    }, 120);
  };

  if (!visible) return null;

  const renderContent = () => {
    switch (currentPage) {
      case 'home':
        return (
          <BoutiqueHome
            primaryColor={primaryColor}
            serverConfig={serverConfig}
            dailyItems={dailyItems}
            nightMarketActive={nightMarketActive}
            nightMarketTimeLeft={nightMarketTimeLeft}
            onNavigate={handlePageChange}
            onItemClick={handleItemClick}
          />
        );
      case 'daily':
        return (
          <BoutiqueDailyShop
            primaryColor={primaryColor}
            items={dailyItems}
            onItemClick={handleItemClick}
            userCoins={userInfo.coins}
          />
        );
      case 'vehicles':
      case 'weapons':
      case 'packs':
      case 'boosts':
        return (
          <BoutiqueItems
            primaryColor={primaryColor}
            items={items[currentPage] || []}
            category={currentPage}
            loading={false}
            onItemClick={handleItemClick}
            onPreview={currentPage === 'vehicles' ? handlePreviewVehicle : undefined}
          />
        );
      case 'crates':
        return (
          <BoutiqueCrates
            primaryColor={primaryColor}
            items={items.crates || []}
            loading={false}
            onItemClick={handleItemClick}
            onOpenCrate={handleOpenCrate}
            userCoins={userInfo.coins}
          />
        );
      case 'nightmarket':
        return nightMarketActive ? (
          <BoutiqueNightMarket
            primaryColor={primaryColor}
            cards={nightMarketCards}
            userCoins={userInfo.coins}
            timeLeft={nightMarketTimeLeft}
            onPurchaseResult={(success, message, coins) => {
              showNotification(message, success ? 'success' : 'error');
              if (success && coins !== undefined) setUserInfo(prev => ({ ...prev, coins }));
            }}
          />
        ) : (
          <div className="boutique-nm-inactive">
            <Flame size={48} className="boutique-nm-inactive-icon" />
            <p>Aucun Night Market en cours</p>
            <span>Reviens plus tard, un événement sera peut-être lancé !</span>
          </div>
        );
      case 'customization':
        return (
          <div className="boutique-wcustom-page">
            <div className="boutique-items-header">
              <div className="boutique-items-header-info">
                <h2>Personnalisation d'armes</h2>
                <p>Sélectionne une arme pour la personnaliser</p>
              </div>
              <span className="boutique-items-count">
                {playerWeapons.length} arme{playerWeapons.length > 1 ? 's' : ''}
              </span>
            </div>
            {playerWeapons.length > 0 ? (
              <div className="boutique-wcustom-grid">
                {playerWeapons.map((weapon, i) => {
                  const hasCustom = weapon.componentCount > 0;
                  return (
                    <div
                      key={i}
                      className={`boutique-wcustom-card ${!hasCustom ? 'no-custom' : ''}`}
                      onClick={() => {
                        if (!hasCustom) return;
                        fetch(`https://${GetParentResourceName()}/boutique:openWeaponCustom`, {
                          method: 'POST',
                          headers: { 'Content-Type': 'application/json' },
                          body: JSON.stringify({ weaponName: weapon.name }),
                        });
                      }}
                    >
                      <div className="boutique-wcustom-card-icon"><Swords size={28} /></div>
                      <div className="boutique-wcustom-card-info">
                        <span className="boutique-wcustom-card-name">{weapon.label}</span>
                        {hasCustom ? (
                          <span className="boutique-wcustom-card-count">
                            {weapon.installedCount}/{weapon.componentCount} installés
                          </span>
                        ) : (
                          <span className="boutique-wcustom-card-count">Aucune personnalisation</span>
                        )}
                      </div>
                      {hasCustom && weapon.installedCount === weapon.componentCount && (
                        <div className="boutique-wcustom-card-complete"><Check size={16} /></div>
                      )}
                    </div>
                  );
                })}
              </div>
            ) : (
              <div className="boutique-empty">
                <Swords size={48} className="boutique-empty-icon" />
                <p>Tu ne possèdes aucune arme</p>
              </div>
            )}
          </div>
        );
      case 'vip':
        return (
          <BoutiqueVIP
            primaryColor={primaryColor}
            userCoins={userInfo.coins}
            onPurchaseResult={(success, message, coins) => {
              showNotification(message, success ? 'success' : 'error');
              if (success && coins !== undefined) setUserInfo(prev => ({ ...prev, coins }));
            }}
          />
        );
      case 'battlepass':
        return (
          <BoutiqueBattlePass
            primaryColor={primaryColor}
            onNotification={showNotification}
            onCoinsUpdate={(coins) => setUserInfo(prev => ({ ...prev, coins }))}
          />
        );
      default:
        return null;
    }
  };

  const fidelity = userInfo.fidelity || 0;
  const fidelityPct = Math.min((fidelity / 5000) * 100, 100);
  const isHome = currentPage === 'home';

  return (
    <div
      ref={overlayRef}
      className={`boutique-overlay ${hiding ? 'boutique-hiding' : ''} ${previewMode ? 'boutique-preview-active' : ''}`}
      style={boutiqueAccentVars as React.CSSProperties}
    >
      <div className="bq-container">
        {/* <WaveBackground accentColor={serverConfig.serverColor || '#4e8bee'} /> */}
        {/* Top bar */}
        <header className="bq-topbar">
          <div className="bq-topbar-left">
            {isHome ? (
              <>
                {serverConfig.serverIcon && (
                  <img src={serverConfig.serverIcon} alt="" className="bq-topbar-logo" />
                )}
                <div className="bq-topbar-brand">
                  <span className="bq-topbar-brand-name">{serverConfig.serverName || 'Null'}</span>
                  <span className="bq-topbar-brand-sub">Boutique officielle</span>
                </div>
              </>
            ) : (
              <>
                <button className="bq-back-btn" onClick={() => handlePageChange('home')} aria-label="Retour">
                  <ArrowLeft size={16} />
                  <span>Retour</span>
                </button>
                <div className="bq-topbar-page">
                  <span className="bq-topbar-page-label">{PAGE_TITLES[currentPage]}</span>
                </div>
              </>
            )}
          </div>

          <div className="bq-topbar-right">
            <div className="bq-fidelity-inline" title={`${fidelity.toLocaleString()} / 5 000 points`}>
              {/* <Star size={13} /> */}
              <div className="bq-fidelity-bar"><div className="bq-fidelity-fill" style={{ width: `${fidelityPct}%` }} /></div>
              <span className="bq-fidelity-value">{fidelity.toLocaleString()}</span>
              <span className="bq-fidelity-label">/5,000</span>
            </div>

            <div className="bq-coins-inline">
              <span className="bq-coins-value">{userInfo.coins.toLocaleString()}</span>
              <span className="bq-coins-label">Coins</span>
            </div>

            {boutiqueLink && (
              <button className="bq-tebex-btn" onClick={handleOpenTebex}>
                <ExternalLink size={14} />
                <span>Recharger</span>
              </button>
            )}

            <button className="bq-icon-btn" onClick={handleClose} aria-label="Fermer">
              <X size={16} />
            </button>
          </div>
        </header>

        {/* Content */}
        <div className={`bq-content ${pageTransition ? 'bq-content-transitioning' : 'bq-content-visible'}`}>
          {renderContent()}
        </div>

        {detailOpen && selectedItem && (
          <BoutiqueDetail
            item={selectedItem}
            primaryColor={primaryColor}
            userCoins={userInfo.coins}
            onClose={() => { setDetailOpen(false); setSelectedItem(null); }}
            onPurchase={handlePurchase}
            onPreview={handlePreviewVehicle}
          />
        )}

        {notification && (
          <div
            className={`boutique-notification boutique-notification-${notification.type}`}
            style={notification.type === 'success' ? { borderColor: primaryColor } : {}}
          >
            {notification.message}
          </div>
        )}
      </div>
    </div>
  );
};

export default Boutique;
