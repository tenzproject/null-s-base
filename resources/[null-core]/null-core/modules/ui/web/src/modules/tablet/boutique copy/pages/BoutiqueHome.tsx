import React from 'react';
import { DailyShopItem, BoutiquePage } from '../types';
import { ShoppingBag, Clock, ChevronRight, Car, Swords } from 'lucide-react';

const RARITY_COLORS: Record<string, string> = {
  common: '#b0b0b0',
  rare: '#4da6ff',
  epic: '#b44dff',
  legendary: '#ff9f1a',
  ultimate: '#ff4d6a',
};

interface BoutiqueHomeProps {
  primaryColor: string;
  serverConfig: {
    serverName: string;
    serverColor: string;
    serverIcon: string;
    serverDiscord: string;
  };
  dailyItems: DailyShopItem[];
  onNavigate: (page: BoutiquePage) => void;
  onItemClick: (item: DailyShopItem) => void;
}

const CAT_IMAGES_BASE = 'nui://null-cache/images/boutique/categories';

const MAIN_CATEGORIES: { page: BoutiquePage; label: string; sub: string; img: string }[] = [
  { page: 'vehicles', label: 'Véhicules', sub: 'Découvre notre flotte exclusive', img: `${CAT_IMAGES_BASE}/vehicules.png` },
  { page: 'weapons',  label: 'Armes',     sub: 'Équipement de haute précision',  img: `${CAT_IMAGES_BASE}/armes.png` },
];

const SUB_CATEGORIES: { page: BoutiquePage; label: string; sub: string; img: string }[] = [
  { page: 'packs',       label: 'Packs',          sub: 'Investissez intelligemment.', img: `${CAT_IMAGES_BASE}/packs.png` },
  { page: 'vip',         label: 'VIP',            sub: 'Débloquez des avantages exclusifs', img: `${CAT_IMAGES_BASE}/vip.png` },
  { page: 'battlepass',  label: 'Passe de Combat', sub: 'Des avantages uniques pour les joueurs les plus actifs.', img: `${CAT_IMAGES_BASE}/battlepass.png` },
];

const BoutiqueHome: React.FC<BoutiqueHomeProps> = ({ primaryColor, serverConfig, dailyItems, onNavigate, onItemClick }) => {
  const now = new Date();
  const midnight = new Date(now);
  midnight.setHours(24, 0, 0, 0);
  const hoursLeft = Math.floor((midnight.getTime() - now.getTime()) / (1000 * 60 * 60));
  const minutesLeft = Math.floor(((midnight.getTime() - now.getTime()) % (1000 * 60 * 60)) / (1000 * 60));

  return (
    <div className="boutique-home">
      {/* Hero Banner */}
      <div className="boutique-hero">
        <img src="assets/img/banniere.png" alt="Bannière" className="boutique-hero-banner" />
        <div className="boutique-hero-overlay">
          <div className="boutique-hero-content">
            <h1 className="boutique-hero-title">
              {serverConfig.serverName}
              <span className="boutique-hero-title-accent"> Store</span>
            </h1>
            <p className="boutique-hero-desc">
              Véhicules exclusifs, armes, packs et privilèges VIP.
            </p>
            <div className="boutique-hero-actions">
              <button className="boutique-hero-cta" onClick={() => onNavigate('daily')}>
                <ShoppingBag size={16} />
                Boutique du Jour
                <ChevronRight size={14} />
              </button>
              <div className="boutique-hero-timer">
                <Clock size={13} />
                <span>{hoursLeft}h {minutesLeft}min</span>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Daily Shop Preview */}
      {dailyItems.length > 0 && (
        <div className="boutique-home-section">
          <div className="boutique-section-header">
            <div className="boutique-section-title-row">
              <h2>Boutique du Jour</h2>
            </div>
            <button className="boutique-section-more" onClick={() => onNavigate('daily')}>
              Voir tout <ChevronRight size={14} />
            </button>
          </div>
          <div className="boutique-daily-preview-grid">
            {dailyItems.slice(0, 3).map((item, i) => (
              <div
                key={i}
                className="boutique-daily-preview-card"
                onClick={() => onItemClick(item)}
              >
                <div
                  className="boutique-daily-preview-rarity"
                  style={{ backgroundColor: RARITY_COLORS[item.rarity] }}
                >
                  {item.rarity.charAt(0).toUpperCase() + item.rarity.slice(1)}
                </div>
                <div className="boutique-daily-preview-image">
                  {item.image ? (
                    <img src={item.image} alt={item.label} />
                  ) : (
                    <div
                      className="boutique-daily-preview-placeholder"
                      style={{ color: RARITY_COLORS[item.rarity] }}
                    >
                      {item.type === 'vehicle' ? <Car size={32} /> : <Swords size={32} />}
                    </div>
                  )}
                </div>
                <div className="boutique-daily-preview-info">
                  <span className="boutique-daily-preview-name">{item.label}</span>
                  <span className="boutique-daily-preview-price">{item.price} Coins</span>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Main category buttons — 2 large side by side */}
      <div className="bh-main-grid">
        {MAIN_CATEGORIES.map((cat) => (
          <button
            key={cat.page}
            className="bh-main-btn"
            onClick={() => onNavigate(cat.page)}
          >
            <img src={cat.img} alt={cat.label} className="bh-main-btn-img" />
            <div className="bh-main-btn-overlay" />
            <div className="bh-main-btn-content">
              <span className="bh-main-btn-label">{cat.label}</span>
              <span className="bh-main-btn-sub">{cat.sub}</span>
            </div>
            <ChevronRight size={16} className="bh-main-btn-arrow" />
          </button>
        ))}
      </div>

      {/* Sub category buttons — 3 smaller */}
      <div className="bh-sub-grid">
        {SUB_CATEGORIES.map((cat) => (
          <button
            key={cat.page}
            className="bh-sub-btn"
            onClick={() => onNavigate(cat.page)}
          >
            <img src={cat.img} alt={cat.label} className="bh-sub-btn-img" />
            <div className="bh-sub-btn-overlay" />
            <span className="bh-sub-btn-label">{cat.label}</span>
            <span className="bh-sub-btn-sub">{cat.sub}</span>
          </button>
        ))}
      </div>
    </div>
  );
};

export default BoutiqueHome;
