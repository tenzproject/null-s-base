import React from 'react';
import { BoutiqueItem, DailyShopItem, CrateItem } from '../types';
import { X, Car, Swords, Eye, ShoppingCart, Package, Zap } from 'lucide-react';

interface BoutiqueDetailProps {
  item: BoutiqueItem | DailyShopItem;
  primaryColor: string;
  userCoins: number;
  onClose: () => void;
  onPurchase: (item: BoutiqueItem | DailyShopItem) => void;
  onPreview: (model: string, item?: BoutiqueItem | DailyShopItem) => void;
}

const CRATE_RARITY_COLORS: Record<number, string> = {
  1: '#b0b0b0',
  2: '#4da6ff',
  3: '#ff9f1a',
  4: '#ff4d6a',
};

const CRATE_RARITY_NAMES: Record<number, string> = {
  1: 'Commun',
  2: 'Rare',
  3: 'Légendaire',
  4: 'Ultime',
};

const DAILY_RARITY_COLORS: Record<string, string> = {
  common: '#b0b0b0',
  rare: '#4da6ff',
  epic: '#b44dff',
  legendary: '#ff9f1a',
  ultimate: '#ff4d6a',
};

const DAILY_RARITY_LABELS: Record<string, string> = {
  common: 'Commun',
  rare: 'Rare',
  epic: 'Épique',
  legendary: 'Légendaire',
  ultimate: 'Ultime',
};

const CATEGORY_LABELS: Record<string, string> = {
  vehicle: 'Véhicule',
  weapon: 'Arme',
  pack: 'Pack',
  boost: 'Boost',
  crate: 'Caisse',
};

const BoutiqueDetail: React.FC<BoutiqueDetailProps> = ({ item, userCoins, onClose, onPurchase, onPreview }) => {
  const isDailyItem = 'rarity' in item && typeof item.rarity === 'string';
  const isCrate = 'inside' in item && (item as BoutiqueItem).inside;
  const canAfford = userCoins >= item.price;
  const isBuyable = !('buyable' in item) || item.buyable !== false;

  const category =
    ('category' in item && item.category) ||
    ('type' in item && item.type) ||
    'item';
  const eyebrow = CATEGORY_LABELS[category] || category;

  const rarity = isDailyItem ? (item as DailyShopItem).rarity : null;
  const rarityColor = rarity ? DAILY_RARITY_COLORS[rarity] : null;

  const isVehicle = category === 'vehicle';
  const isWeapon = category === 'weapon';
  const isPack = category === 'pack';
  const isBoost = category === 'boost';

  const placeholderIcon = isVehicle
    ? <Car size={64} />
    : isWeapon
    ? <Swords size={64} />
    : isPack
    ? <Package size={64} />
    : isBoost
    ? <Zap size={64} />
    : <ShoppingCart size={64} />;

  const stats = (item as any).stats as Record<string, number> | undefined;
  const info2 = (item as BoutiqueItem).info2;
  const time = (item as BoutiqueItem).time;
  const activeBoost = (item as BoutiqueItem).activeBoost;
  const tags = (item as BoutiqueItem).tags;
  const originalPrice = (item as DailyShopItem).originalPrice;
  const discount = (item as DailyShopItem).discount;

  return (
    <div className="bq-modal-overlay" onClick={onClose}>
      <div className="bq-modal" onClick={(e) => e.stopPropagation()}>
        <div className="bq-modal-bg" />
        <div className="bq-modal-shade" />

        <button className="bq-modal-close" onClick={onClose} aria-label="Fermer">
          <X size={18} />
        </button>

        {/* Visual side — item image floating */}
        <div className="bq-modal-visual">
          {item.image ? (
            <img src={item.image} alt={item.label} className="bq-modal-img" />
          ) : (
            <div className="bq-modal-placeholder">{placeholderIcon}</div>
          )}
        </div>

        {/* Info side */}
        <div className="bq-modal-info">
          <div className="bq-modal-meta">
            <span className="bq-modal-eyebrow">{eyebrow}</span>
            {rarity && rarityColor && (
              <span
                className="bq-modal-rarity"
                style={{ color: rarityColor, borderColor: `${rarityColor}55`, backgroundColor: `${rarityColor}1a` }}
              >
                {DAILY_RARITY_LABELS[rarity]}
              </span>
            )}
            {tags && tags.length > 0 && tags.slice(0, 3).map((tag, i) => (
              <span key={i} className="bq-modal-tag">{tag}</span>
            ))}
          </div>

          <h2 className="bq-modal-title">{item.label}</h2>

          {item.description && (
            <p className="bq-modal-desc">{item.description}</p>
          )}

          <div className="bq-modal-body">
            {/* Stats */}
            {stats && Object.keys(stats).length > 0 && (
              <section className="bq-modal-section">
                <h3 className="bq-modal-section-title">Statistiques</h3>
                <div className="bq-modal-stats">
                  {Object.entries(stats).map(([stat, value]) => (
                    <div key={stat} className="bq-modal-stat">
                      <div className="bq-modal-stat-row">
                        <span className="bq-modal-stat-label">{stat}</span>
                        <span className="bq-modal-stat-value">{value}/10</span>
                      </div>
                      <div className="bq-modal-stat-bar">
                        <div className="bq-modal-stat-fill" style={{ width: `${(value / 10) * 100}%` }} />
                      </div>
                    </div>
                  ))}
                </div>
              </section>
            )}

            {/* Pack info */}
            {info2 && Object.keys(info2).length > 0 && (
              <section className="bq-modal-section">
                <h3 className="bq-modal-section-title">Détails du pack</h3>
                <div className="bq-modal-kv">
                  {Object.entries(info2).map(([key, value]) => (
                    <div key={key} className="bq-modal-kv-row">
                      <span className="bq-modal-kv-key">{key}</span>
                      <span className="bq-modal-kv-value">{value}</span>
                    </div>
                  ))}
                </div>
              </section>
            )}

            {/* Boost info */}
            {time && (
              <section className="bq-modal-section">
                <h3 className="bq-modal-section-title">Détails du boost</h3>
                <div className="bq-modal-kv">
                  <div className="bq-modal-kv-row">
                    <span className="bq-modal-kv-key">Durée</span>
                    <span className="bq-modal-kv-value">{time}h</span>
                  </div>
                </div>
                {activeBoost && Object.keys(activeBoost).length > 0 && (
                  <div className="bq-modal-boost-grid">
                    {Object.entries(activeBoost).map(([key, value]) => (
                      <div key={key} className="bq-modal-boost">
                        <span className="bq-modal-boost-mult">×{value}</span>
                        <span className="bq-modal-boost-name">{key}</span>
                      </div>
                    ))}
                  </div>
                )}
              </section>
            )}

            {/* Crate contents */}
            {isCrate && (item as BoutiqueItem).inside && (
              <section className="bq-modal-section">
                <h3 className="bq-modal-section-title">Contenu</h3>
                <div className="bq-modal-crate">
                  {[4, 3, 2, 1].map(rarity => {
                    const rarityItems = (item as BoutiqueItem).inside!.filter((ci: CrateItem) => ci.rarity === rarity);
                    if (rarityItems.length === 0) return null;
                    return (
                      <div key={rarity} className="bq-modal-crate-group">
                        <span
                          className="bq-modal-crate-rarity"
                          style={{ color: CRATE_RARITY_COLORS[rarity], borderColor: `${CRATE_RARITY_COLORS[rarity]}55` }}
                        >
                          {CRATE_RARITY_NAMES[rarity]}
                        </span>
                        <div className="bq-modal-crate-items">
                          {rarityItems.map((ci: CrateItem, j: number) => (
                            <div key={j} className="bq-modal-crate-item">
                              <span className="bq-modal-crate-item-name">{ci.label}</span>
                              <span className="bq-modal-crate-item-type">{ci.typeLot}</span>
                            </div>
                          ))}
                        </div>
                      </div>
                    );
                  })}
                </div>
              </section>
            )}
          </div>

          {/* Footer */}
          <div className="bq-modal-footer">
            <div className="bq-modal-price">
              {isBuyable && item.price > 0 ? (
                <>
                  <div className="bq-modal-price-main">
                    <span className="bq-modal-price-value">{item.price.toLocaleString()}</span>
                    <span className="bq-modal-price-label">Coins</span>
                  </div>
                  {originalPrice && originalPrice > item.price && (
                    <div className="bq-modal-price-sub">
                      <span className="bq-modal-price-original">{originalPrice.toLocaleString()}</span>
                      {discount && discount > 0 && (
                        <span className="bq-modal-price-discount">-{discount}%</span>
                      )}
                    </div>
                  )}
                </>
              ) : (
                <span className="bq-modal-price-unavailable">Non achetable</span>
              )}
            </div>

            <div className="bq-modal-actions">
              {isVehicle && item.model && (
                <button className="bq-modal-btn bq-modal-btn--ghost" onClick={() => onPreview(item.model!, item)}>
                  <Eye size={15} />
                  <span>Aperçu</span>
                </button>
              )}
              {isBuyable && item.price > 0 && (
                <button
                  className="bq-modal-btn bq-modal-btn--primary"
                  onClick={() => onPurchase(item)}
                  disabled={!canAfford}
                >
                  <ShoppingCart size={15} />
                  <span>{canAfford ? 'Acheter' : 'Coins insuffisants'}</span>
                </button>
              )}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default BoutiqueDetail;
