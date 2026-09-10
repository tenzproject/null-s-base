import React, { useState, useEffect, useCallback, useRef, useMemo } from 'react';
import { generateAccentVars } from '@/utils/accentColors';
import { BoutiqueProps, BoutiqueItem, DailyShopItem, UserInfo, BoutiquePage, PlayerWeaponSummary, NightMarketCard } from './types';
import { Home, ShoppingBag, Car, Swords, Package, Zap, Box, History, X, ChevronRight, ExternalLink, Star, Crosshair, Check, Flame, Crown, Shield } from 'lucide-react';
import BoutiqueHome from './pages/BoutiqueHome';
import BoutiqueDailyShop from './pages/BoutiqueDailyShop';
import BoutiqueItems from './pages/BoutiqueItems';
import BoutiqueCrates from './pages/BoutiqueCrates';
import BoutiqueDetail from './components/BoutiqueDetail';
import BoutiqueNightMarket from './pages/BoutiqueNightMarket';
import BoutiqueVIP from './pages/BoutiqueVIP';
import BoutiqueBattlePass from './pages/BoutiqueBattlePass';
import './Boutique.css';

const GetParentResourceName = () => 'null-core';

const Boutique: React.FC<BoutiqueProps> = ({ visible, onClose, primaryColor, serverConfig }) => {
  const boutiqueAccentVars = useMemo(() => generateAccentVars('--boutique-accent', primaryColor), [primaryColor]);
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

  // Listen for NUI messages
  useEffect(() => {
    const handleMessage = (event: MessageEvent) => {
      const data = event.data;

      switch (data.action) {
        case 'boutique:open':
          // Data comes with items, daily shop, user info
          if (data.userInfo) setUserInfo(data.userInfo);
          if (data.items) setItems(data.items);
          if (data.dailyItems) setDailyItems(data.dailyItems);
          if (data.boutiqueLink) setBoutiqueLink(data.boutiqueLink);
          if (data.nightMarket) {
            setNightMarketActive(data.nightMarket.active || false);
            setNightMarketCards((data.nightMarket.cards || []).map((c: any) => ({ ...c, revealed: false })));
            setNightMarketTimeLeft(data.nightMarket.timeLeft || 0);
          }
          setCurrentPage('home');
          break;

        case 'boutique:updateCoins':
          setUserInfo(prev => ({ ...prev, coins: data.coins }));
          break;

        case 'boutique:items':
          setItems(prev => ({ ...prev, [data.category]: data.items }));
          break;

        case 'boutique:dailyItems':
          setDailyItems(data.items || []);
          break;

        case 'boutique:purchaseResult':
          if (data.success) {
            showNotification(data.message || 'Achat effectué !', 'success');
            if (data.coins !== undefined) {
              setUserInfo(prev => ({ ...prev, coins: data.coins }));
            }
          } else {
            showNotification(data.message || 'Erreur lors de l\'achat', 'error');
          }
          break;

        case 'boutique:crateResult':
          // Handle crate opening result
          if (data.reward) {
            showNotification(`Tu as obtenu : ${data.reward.label} !`, 'success');
            if (data.coins !== undefined) {
              setUserInfo(prev => ({ ...prev, coins: data.coins }));
            }
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
  }, []);

  // ESC key handler
  useEffect(() => {
    if (!visible) return;

    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        if (previewMode) {
          handleStopPreview();
        } else if (detailOpen) {
          setDetailOpen(false);
          setSelectedItem(null);
        } else {
          handleClose();
        }
      }
    };

    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [visible, detailOpen, previewMode]);

  const showNotification = (message: string, type: 'success' | 'error') => {
    setNotification({ message, type });
    setTimeout(() => setNotification(null), 3000);
  };

  const handleClose = useCallback(() => {
    setHiding(true);
    fetch(`https://${GetParentResourceName()}/boutique:close`, { method: 'POST' });
    setTimeout(() => {
      setHiding(false);
      onClose();
    }, 300);
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
    fetch(`https://${GetParentResourceName()}/boutique:stopPreview`, {
      method: 'POST',
    });
    setPreviewMode(false);
  }, []);

  const handleBuyFromPreview = useCallback(() => {
    fetch(`https://${GetParentResourceName()}/boutique:buyFromPreview`, {
      method: 'POST',
    });
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

    // Request weapon loadout when entering customization page
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
        requestAnimationFrame(() => {
          setPageTransition(false);
        });
      });
    }, 120);
  };

  if (!visible) return null;

  const sidebarItems: { id: BoutiquePage; label: string; icon: React.ReactNode }[] = [
    { id: 'home', label: 'Accueil', icon: <Home size={18} /> },
    { id: 'daily', label: 'Boutique du Jour', icon: <ShoppingBag size={18} /> },
    ...(nightMarketActive ? [{ id: 'nightmarket' as BoutiquePage, label: 'Night Market', icon: <Flame size={18} /> }] : []),
    { id: 'battlepass' as BoutiquePage, label: 'Passe de Combat', icon: <Shield size={18} /> },
    { id: 'vip' as BoutiquePage, label: 'VIP', icon: <Crown size={18} /> },
    { id: 'vehicles', label: 'Véhicules', icon: <Car size={18} /> },
    { id: 'weapons', label: 'Armes', icon: <Swords size={18} /> },
    { id: 'packs', label: 'Packs', icon: <Package size={18} /> },
    // { id: 'boosts', label: 'Boosts', icon: <Zap size={18} /> },
    // { id: 'crates', label: 'Caisses', icon: <Box size={18} /> },
    { id: 'customization', label: 'Personnalisation', icon: <Crosshair size={18} /> },
    // { id: 'history', label: 'Historique', icon: <History size={18} /> },
  ];

  const renderContent = () => {
    switch (currentPage) {
      case 'home':
        return (
          <BoutiqueHome
            primaryColor={primaryColor}
            serverConfig={serverConfig}
            dailyItems={dailyItems}
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
              if (success && coins !== undefined) {
                setUserInfo(prev => ({ ...prev, coins }));
              }
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
                      <div className="boutique-wcustom-card-icon">
                        <Swords size={28} />
                      </div>
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
                        <div className="boutique-wcustom-card-complete">
                          <Check size={16} />
                        </div>
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
      case 'history':
        return (
          <div className="boutique-history-page">
            <div className="boutique-items-header">
              <div className="boutique-items-header-info">
                <h2>Historique</h2>
                <p>Toutes tes transactions de la boutique</p>
              </div>
            </div>
            {userInfo.history && userInfo.history.length > 0 ? (
              <div className="boutique-history-list">
                {userInfo.history.map((entry, i) => (
                  <div key={i} className="boutique-history-entry">
                    <div className="boutique-history-info">
                      <span className="boutique-history-label">{entry.label}</span>
                      <span className="boutique-history-date">{entry.date}</span>
                    </div>
                    <div className="boutique-history-price" style={{ color: entry.isCredit ? '#2ecc71' : '#ff4d6a' }}>
                      <span>{entry.isCredit ? '+' : '-'}{entry.price.toLocaleString()} Coins</span>
                    </div>
                  </div>
                ))}
              </div>
            ) : (
              <div className="boutique-empty">
                <History size={48} className="boutique-empty-icon" />
                <p>Aucune transaction pour le moment</p>
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
              if (success && coins !== undefined) {
                setUserInfo(prev => ({ ...prev, coins }));
              }
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

  return (
    <div className={`boutique-overlay ${hiding ? 'boutique-hiding' : ''} ${previewMode ? 'boutique-preview-active' : ''}`} style={boutiqueAccentVars as React.CSSProperties}>
      <div className="boutique-container">
        {/* Sidebar */}
        <div className="boutique-sidebar">
          <div className="boutique-sidebar-header">
            {serverConfig.serverIcon && (
              <img src={serverConfig.serverIcon} alt="" className="boutique-sidebar-logo" />
            )}
            <div className="boutique-sidebar-title">
              <h1>Boutique</h1>
              <p>{serverConfig.serverName}</p>
            </div>
          </div>

          <nav className="boutique-sidebar-nav">
            {sidebarItems.map((item) => (
              <button
                key={item.id}
                className={`boutique-sidebar-item ${currentPage === item.id ? 'active' : ''} ${item.id === 'nightmarket' ? 'nightmarket-active' : ''}`}
                onClick={() => handlePageChange(item.id)}
                style={item.id === 'nightmarket' && currentPage !== item.id ? { color: '#ff4d6a' } : {}}
              >
                <span className="boutique-sidebar-indicator" />
                {item.icon}
                <span>{item.label}</span>
                {item.id === 'daily' && (
                  <span className="boutique-sidebar-badge">NEW</span>
                )}
                {item.id === 'nightmarket' && (
                  <span className="boutique-sidebar-badge boutique-sidebar-badge-live">LIVE</span>
                )}
                <ChevronRight size={14} className="boutique-sidebar-arrow" />
              </button>
            ))}
          </nav>

          <div className="boutique-sidebar-footer">
            {/* Tebex Button */}
            {boutiqueLink && (
              <button className="boutique-tebex-btn" onClick={handleOpenTebex}>
                <ExternalLink size={16} />
                <span>Acheter des Coins</span>
              </button>
            )}
            {/* Coins */}
            <div className="boutique-coins">
              <span className="boutique-coins-amount">{userInfo.coins.toLocaleString()}</span>
              <span className="boutique-coins-label">Coins</span>
            </div>
            {/* Fidelity Progress */}
            <div className="boutique-fidelity">
              <div className="boutique-fidelity-header">
                <Star size={14} />
                <span className="boutique-fidelity-label">Fidélité</span>
                <span className="boutique-fidelity-value">{(userInfo.fidelity || 0).toLocaleString()} / 5 000</span>
              </div>
              <div className="boutique-fidelity-bar">
                <div
                  className="boutique-fidelity-bar-fill"
                  style={{
                    width: `${Math.min(((userInfo.fidelity || 0) / 5000) * 100, 100)}%`,
                  }}
                />
              </div>
            </div>
            {/* Close Button */}
            <button className="boutique-close-btn" onClick={handleClose}>
              <X size={16} />
              <span>Fermer</span>
            </button>
          </div>
        </div>

        {/* Main Content */}
        <div className="boutique-main">
          {/* Content */}
          <div className={`boutique-content ${pageTransition ? 'boutique-content-transitioning' : 'boutique-content-visible'}`}>
            {renderContent()}
          </div>
        </div>

        {/* Detail Overlay */}
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

        {/* Notification */}
        {notification && (
          <div className={`boutique-notification boutique-notification-${notification.type}`}
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
