import React, { useState, useEffect, useMemo } from 'react';
import { DailyShopItem, RarityLevel } from '../types';
import { Clock, Car, Swords, ShoppingBag } from 'lucide-react';
import { packBento, RARITY_NATURAL_CELLS, SIZE_TO_CELLS } from '../utils/bentoPacker';

interface BoutiqueDailyShopProps {
  primaryColor: string;
  items: DailyShopItem[];
  onItemClick: (item: DailyShopItem) => void;
  userCoins: number;
}

const RARITY_COLORS: Record<RarityLevel, string> = {
  common: '#b0b0b0',
  rare: '#4da6ff',
  epic: '#b44dff',
  legendary: '#ff9f1a',
  ultimate: '#ff4d6a',
};

const RARITY_LABELS: Record<RarityLevel, string> = {
  common: 'Commun',
  rare: 'Rare',
  epic: 'Épique',
  legendary: 'Légendaire',
  ultimate: 'Ultime',
};

const BoutiqueDailyShop: React.FC<BoutiqueDailyShopProps> = ({ items, onItemClick, userCoins }) => {
  const [timeLeft, setTimeLeft] = useState('');

  const packed = useMemo(
    () => packBento(items, item => item.cells || (item.size ? SIZE_TO_CELLS[item.size] : RARITY_NATURAL_CELLS[item.rarity] || 2)),
    [items]
  );

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
    <div className="bq-page bq-page--full">
      <div className="bq-page-header">
        <div>
          <h2 className="bq-page-title-h">Boutique du Jour</h2>
          <p className="bq-page-sub">{items.length} items uniques renouvelés chaque jour</p>
        </div>
        <div className="bq-page-timer">
          <Clock size={15} />
          <span>{timeLeft}</span>
        </div>
      </div>

      <div
        className="bq-bento bq-bento--fill"
        style={{
          gridTemplateColumns: `repeat(${packed.cols}, 1fr)`,
          gridTemplateRows: `repeat(${packed.rows}, 1fr)`,
        } as React.CSSProperties}
      >
        {packed.placed.map(({ item, size, col, row, w, h }, i) => {
          const isLarge = size === 'featured' || size === 'large' || size === 'tall';
          const rarityColor = RARITY_COLORS[item.rarity] || '#b0b0b0';
          const canAfford = userCoins >= item.price;

          return (
            <button
              key={i}
              className={`bq-pcard bq-pcard--${size}`}
              onClick={() => onItemClick(item)}
              style={{
                '--rarity-color': rarityColor,
                gridColumn: `${col + 1} / span ${w}`,
                gridRow: `${row + 1} / span ${h}`,
              } as React.CSSProperties}
            >
              <div className="bq-pcard-bg" />
              <div className="bq-pcard-shade" />
              {item.image ? (
                <img src={item.image} alt={item.label} className="bq-pcard-img" />
              ) : (
                <div className="bq-pcard-placeholder">
                  {item.type === 'vehicle' ? <Car size={48} /> : <Swords size={48} />}
                </div>
              )}

              {/* <div className="bq-pcard-rarity" style={{ color: rarityColor, borderColor: `${rarityColor}55` }}>
                {RARITY_LABELS[item.rarity]}
              </div> */}

              {/* {item.discount && item.discount > 0 && (
                <div className="bq-pcard-discount">-{item.discount}%</div>
              )} */}

              <div className={`bq-pcard-info ${isLarge ? 'bq-pcard-info--bottom' : 'bq-pcard-info--top'}`}>
                <span className="bq-pcard-eyebrow">{item.type === 'vehicle' ? 'Véhicule' : 'Arme'}</span>
                <h3 className="bq-pcard-title">{item.label}</h3>
                {isLarge && item.description && (
                  <p className="bq-pcard-desc">{item.description}</p>
                )}
                <div className="bq-pcard-price">
                  <span className={`bq-pcard-price-value ${!canAfford ? 'is-low' : ''}`}>{item.price.toLocaleString()}</span>
                  <span className="bq-pcard-price-label">Coins</span>
                  {item.originalPrice && item.originalPrice > item.price && (
                    <span className="bq-pcard-price-original">{item.originalPrice.toLocaleString()}</span>
                  )}
                </div>
              </div>
            </button>
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
