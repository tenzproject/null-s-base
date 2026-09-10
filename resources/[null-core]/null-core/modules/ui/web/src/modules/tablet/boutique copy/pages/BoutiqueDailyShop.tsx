import React, { useState, useEffect } from 'react';
import { DailyShopItem } from '../types';
import { Clock, Car, Swords, Sparkles, ShoppingBag } from 'lucide-react';

interface BoutiqueDailyShopProps {
  primaryColor: string;
  items: DailyShopItem[];
  onItemClick: (item: DailyShopItem) => void;
  userCoins: number;
}

const RARITY_COLORS: Record<string, string> = {
  common: '#b0b0b0',
  rare: '#4da6ff',
  epic: '#b44dff',
  legendary: '#ff9f1a',
  ultimate: '#ff4d6a',
};

const RARITY_LABELS: Record<string, string> = {
  common: 'Commun',
  rare: 'Rare',
  epic: 'Épique',
  legendary: 'Légendaire',
  ultimate: 'Ultime',
};

const BoutiqueDailyShop: React.FC<BoutiqueDailyShopProps> = ({ primaryColor, items, onItemClick, userCoins }) => {
  const [timeLeft, setTimeLeft] = useState('');

  useEffect(() => {
    const updateTimer = () => {
      const now = new Date();
      const midnight = new Date(now);
      midnight.setHours(24, 0, 0, 0);
      const diff = midnight.getTime() - now.getTime();
      const h = Math.floor(diff / (1000 * 60 * 60));
      const m = Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60));
      const s = Math.floor((diff % (1000 * 60)) / 1000);
      setTimeLeft(`${h}h ${m.toString().padStart(2, '0')}m ${s.toString().padStart(2, '0')}s`);
    };

    updateTimer();
    const interval = setInterval(updateTimer, 1000);
    return () => clearInterval(interval);
  }, []);

  return (
    <div className="boutique-daily-page">
      {/* Header */}
      <div className="boutique-daily-header">
        <div className="boutique-daily-header-left">
          {/* <div className="boutique-daily-header-badge">
            <Sparkles size={16} />
            <span>Exclusif</span>
          </div> */}
          <h2 className="boutique-page-title">Boutique du Jour</h2>
          <p className="boutique-page-subtitle">
            6 items uniques générés spécialement pour toi. Ils changent toutes les 24 heures !
          </p>
        </div>
        <div className="boutique-daily-timer">
          <Clock size={18} />
          <div className="boutique-daily-timer-text">
            <span className="boutique-daily-timer-label">Renouvellement dans</span>
            <span className="boutique-daily-timer-value">{timeLeft}</span>
          </div>
        </div>
      </div>

      {/* Items Grid */}
      <div className="boutique-daily-grid">
        {items.map((item, i) => {
          const rarityColor = RARITY_COLORS[item.rarity] || '#b0b0b0';
          const canAfford = userCoins >= item.price;

          return (
            <div
              key={i}
              className="boutique-daily-card"
              onClick={() => onItemClick(item)}
              style={{ '--rarity-color': rarityColor } as React.CSSProperties}
            >
              {/* Rarity strip */}
              {/* <div className="boutique-daily-card-strip" /> */}

              {/* Rarity badge */}
              <div className="boutique-daily-card-rarity" style={{ backgroundColor: `${rarityColor}20`, color: rarityColor }}>
                {RARITY_LABELS[item.rarity]}
              </div>

              {/* Discount badge */}
              {item.discount && item.discount > 0 && (
                <div className="boutique-daily-card-discount">
                  -{item.discount}%
                </div>
              )}

              {/* Image */}
              <div className="boutique-daily-card-image">
                {item.image ? (
                  <img src={item.image} alt={item.label} />
                ) : (
                  <div className="boutique-daily-card-placeholder">
                    {item.type === 'vehicle' ? <Car size={48} /> : <Swords size={48} />}
                  </div>
                )}
              </div>

              {/* Info */}
              <div className="boutique-daily-card-info">
                <span className="boutique-daily-card-type">{item.type === 'vehicle' ? 'Véhicule' : 'Arme'}</span>
                <span className="boutique-daily-card-name">{item.label}</span>
                {item.description && (
                  <span className="boutique-daily-card-desc">{item.description}</span>
                )}
              </div>

              {/* Price */}
              <div className="boutique-daily-card-footer">
                <div className={`boutique-daily-card-price ${!canAfford ? 'insufficient' : ''}`}>
                  <span>{item.price.toLocaleString()}</span>
                  <span className="boutique-price-label">Coins</span>
                  {item.originalPrice && item.originalPrice > item.price && (
                    <span className="boutique-daily-card-original">{item.originalPrice.toLocaleString()}</span>
                  )}
                </div>
              </div>
            </div>
          );
        })}
      </div>

      {items.length === 0 && (
        <div className="boutique-empty">
          <ShoppingBag size={48} className="boutique-empty-icon" />
          <p>La boutique du jour est en cours de chargement...</p>
        </div>
      )}
    </div>
  );
};

export default BoutiqueDailyShop;
