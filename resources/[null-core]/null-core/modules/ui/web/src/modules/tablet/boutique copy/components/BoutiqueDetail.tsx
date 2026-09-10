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

const RARITY_COLORS: Record<number, string> = {
  1: '#b0b0b0',
  2: '#4da6ff',
  3: '#ff9f1a',
  4: '#ff4d6a',
};

const RARITY_NAMES: Record<number, string> = {
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

const BoutiqueDetail: React.FC<BoutiqueDetailProps> = ({ item, primaryColor, userCoins, onClose, onPurchase, onPreview }) => {
  const isDailyItem = 'rarity' in item && typeof item.rarity === 'string';
  const isCrate = 'inside' in item && (item as BoutiqueItem).inside;
  const canAfford = userCoins >= item.price;
  const isBuyable = !('buyable' in item) || item.buyable !== false;

  return (
    <div className="boutique-detail-overlay" onClick={onClose}>
      <div className="boutique-detail-modal" onClick={(e) => e.stopPropagation()}>
        {/* Close button */}
        <button className="boutique-detail-close" onClick={onClose}>
          <X size={20} />
        </button>

        {/* Image section */}
        <div className="boutique-detail-image-section">
          {item.image ? (
            <img src={item.image} alt={item.label} className="boutique-detail-image" />
          ) : (
            <div className="boutique-detail-placeholder">
              {('category' in item && item.category === 'vehicle') || ('type' in item && item.type === 'vehicle')
                ? <Car size={64} />
                : ('category' in item && item.category === 'weapon') || ('type' in item && item.type === 'weapon')
                ? <Swords size={64} />
                : ('category' in item && item.category === 'pack')
                ? <Package size={64} />
                : ('category' in item && item.category === 'boost')
                ? <Zap size={64} />
                : <ShoppingCart size={64} />
              }
            </div>
          )}

          {/* Daily rarity badge */}
          {isDailyItem && (
            <div
              className="boutique-detail-rarity-badge"
              style={{ backgroundColor: DAILY_RARITY_COLORS[(item as DailyShopItem).rarity] }}
            >
              {(item as DailyShopItem).rarity.charAt(0).toUpperCase() + (item as DailyShopItem).rarity.slice(1)}
            </div>
          )}
        </div>

        {/* Content */}
        <div className="boutique-detail-content">
          <h2 className="boutique-detail-title">{item.label}</h2>
          {item.description && (
            <p className="boutique-detail-description">{item.description}</p>
          )}

          {/* Stats */}
          {item.stats && Object.keys(item.stats).length > 0 && (
            <div className="boutique-detail-stats-section">
              <h3 className="boutique-detail-section-title">Statistiques</h3>
              <div className="boutique-detail-stats">
                {Object.entries(item.stats).map(([stat, value]) => (
                  <div key={stat} className="boutique-detail-stat-row">
                    <span className="boutique-detail-stat-label">{stat}</span>
                    <div className="boutique-detail-stat-bar-bg">
                      <div
                        className="boutique-detail-stat-bar-fill"
                        style={{
                          width: `${(value / 10) * 100}%`,
                        }}
                      />
                    </div>
                    <span className="boutique-detail-stat-value">{value}/10</span>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* Pack info */}
          {'info2' in item && (item as BoutiqueItem).info2 && (
            <div className="boutique-detail-info-section">
              <h3 className="boutique-detail-section-title">Détails du pack</h3>
              <div className="boutique-detail-info-list">
                {Object.entries((item as BoutiqueItem).info2!).map(([key, value]) => (
                  <div key={key} className="boutique-detail-info-row">
                    <span className="boutique-detail-info-key">{key}</span>
                    <span className="boutique-detail-info-value">{value}</span>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* Boost info */}
          {'time' in item && (item as BoutiqueItem).time && (
            <div className="boutique-detail-info-section">
              <h3 className="boutique-detail-section-title">Détails du boost</h3>
              <div className="boutique-detail-info-row">
                <span className="boutique-detail-info-key">Durée</span>
                <span className="boutique-detail-info-value">{(item as BoutiqueItem).time}h</span>
              </div>
              {(item as BoutiqueItem).activeBoost && (
                <div className="boutique-detail-boost-grid">
                  {Object.entries((item as BoutiqueItem).activeBoost!).map(([key, value]) => (
                    <div key={key} className="boutique-detail-boost-item">
                      <span className="boutique-detail-boost-name">{key}</span>
                      <span className="boutique-detail-boost-value">x{value}</span>
                    </div>
                  ))}
                </div>
              )}
            </div>
          )}

          {/* Crate contents */}
          {isCrate && (item as BoutiqueItem).inside && (
            <div className="boutique-detail-info-section">
              <h3 className="boutique-detail-section-title">Contenu de la caisse</h3>
              <div className="boutique-detail-crate-contents">
                {[4, 3, 2, 1].map(rarity => {
                  const rarityItems = (item as BoutiqueItem).inside!.filter((ci: CrateItem) => ci.rarity === rarity);
                  if (rarityItems.length === 0) return null;
                  return (
                    <div key={rarity} className="boutique-detail-crate-rarity">
                      <div className="boutique-detail-crate-rarity-header">
                        <span
                          className="boutique-detail-crate-rarity-badge"
                          style={{ backgroundColor: `${RARITY_COLORS[rarity]}20`, color: RARITY_COLORS[rarity] }}
                        >
                          {RARITY_NAMES[rarity]}
                        </span>
                      </div>
                      <div className="boutique-detail-crate-items">
                        {rarityItems.map((ci: CrateItem, j: number) => (
                          <div key={j} className="boutique-detail-crate-item" style={{ borderColor: `${RARITY_COLORS[rarity]}15` }}>
                            <span>{ci.label}</span>
                            <span className="boutique-detail-crate-item-type">{ci.typeLot}</span>
                          </div>
                        ))}
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>
          )}
        </div>

        {/* Footer actions */}
        <div className="boutique-detail-footer">
          {/* Preview button for vehicles */}
          {(('category' in item && item.category === 'vehicle') || ('type' in item && item.type === 'vehicle')) && item.model && (
            <button
              className="boutique-detail-preview-btn"
              onClick={() => onPreview(item.model!, item)}
            >
              <Eye size={16} />
              Aperçu 3D
            </button>
          )}

          {/* Price & Buy */}
          {isBuyable && item.price > 0 && (
            <button
              className="boutique-detail-buy-btn"
              onClick={() => onPurchase(item)}
              disabled={!canAfford}
            >
              <span>{item.price.toLocaleString()} Coins</span>
              {!canAfford && <span className="boutique-detail-insufficient">Coins insuffisants</span>}
            </button>
          )}
        </div>
      </div>
    </div>
  );
};

export default BoutiqueDetail;
