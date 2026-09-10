import React, { useState } from 'react';
import { BoutiqueItem } from '../types';
import { Box, Loader2, Eye, Minus, Plus } from 'lucide-react';

interface BoutiqueCratesProps {
  primaryColor: string;
  items: BoutiqueItem[];
  loading: boolean;
  onItemClick: (item: BoutiqueItem) => void;
  onOpenCrate: (crateId: string, quantity: number) => void;
  userCoins: number;
}

const RARITY_NAMES: Record<number, string> = {
  1: 'Commun',
  2: 'Rare',
  3: 'Légendaire',
  4: 'Ultime',
};

const RARITY_COLORS: Record<number, string> = {
  1: '#b0b0b0',
  2: '#4da6ff',
  3: '#ff9f1a',
  4: '#ff4d6a',
};

const BoutiqueCrates: React.FC<BoutiqueCratesProps> = ({ primaryColor, items, loading, onItemClick, onOpenCrate, userCoins }) => {
  const [quantities, setQuantities] = useState<Record<string, number>>({});

  const getQuantity = (id: string) => quantities[id] || 1;

  const setQuantity = (id: string, qty: number) => {
    setQuantities(prev => ({ ...prev, [id]: Math.max(1, Math.min(qty, 10)) }));
  };

  if (loading) {
    return (
      <div className="boutique-loading">
        <Loader2 size={32} className="boutique-spinner" />
        <p>Chargement...</p>
      </div>
    );
  }

  return (
    <div className="boutique-crates-page">
      <div className="boutique-items-header">
        <div className="boutique-items-header-info">
          <h2>Caisses</h2>
          <p>Ouvre des caisses et tente ta chance pour obtenir des récompenses rares</p>
        </div>
      </div>

      <div className="boutique-crates-grid">
        {items.map((crate, i) => {
          const qty = getQuantity(crate.id);
          const totalPrice = crate.price * qty;
          const canAfford = userCoins >= totalPrice;
          const isBuyable = crate.buyable !== false && crate.price > 0;

          return (
            <div key={i} className="boutique-crate-card">
              {/* Crate header */}
              <div className="boutique-crate-header">
                <div className="boutique-crate-image">
                  {crate.image ? (
                    <img src={crate.image} alt={crate.label} />
                  ) : (
                    <div className="boutique-crate-placeholder">
                      <Box size={48} />
                    </div>
                  )}
                </div>
                <div className="boutique-crate-info">
                  <span className="boutique-crate-name">{crate.label}</span>
                  {isBuyable && (
                    <div className="boutique-crate-price">
                      <span>{crate.price.toLocaleString()}</span>
                      <span className="boutique-price-label">Coins</span>
                      <span className="boutique-crate-price-unit">/ caisse</span>
                    </div>
                  )}
                  {!isBuyable && (
                    <span className="boutique-crate-special">Caisse spéciale</span>
                  )}
                </div>
              </div>

              {/* Crate contents preview */}
              <div className="boutique-crate-contents">
                <span className="boutique-crate-contents-title">Contenu possible :</span>
                <div className="boutique-crate-rarities">
                  {[4, 3, 2, 1].map(rarity => {
                    const rarityItems = crate.inside?.filter(item => item.rarity === rarity) || [];
                    if (rarityItems.length === 0) return null;
                    return (
                      <div key={rarity} className="boutique-crate-rarity-row">
                        <span className="boutique-crate-rarity-badge" style={{ backgroundColor: `${RARITY_COLORS[rarity]}20`, color: RARITY_COLORS[rarity] }}>
                          {RARITY_NAMES[rarity]}
                        </span>
                        <span className="boutique-crate-rarity-count">{rarityItems.length} item{rarityItems.length > 1 ? 's' : ''}</span>
                      </div>
                    );
                  })}
                </div>
              </div>

              {/* View contents button */}
              <button
                className="boutique-crate-view-btn"
                onClick={() => onItemClick(crate)}
              >
                <Eye size={14} />
                Voir le contenu complet
              </button>

              {/* Buy section */}
              {isBuyable && (
                <div className="boutique-crate-buy">
                  <div className="boutique-crate-qty">
                    <button
                      className="boutique-crate-qty-btn"
                      onClick={() => setQuantity(crate.id, qty - 1)}
                      disabled={qty <= 1}
                    >
                      <Minus size={14} />
                    </button>
                    <span className="boutique-crate-qty-value">{qty}</span>
                    <button
                      className="boutique-crate-qty-btn"
                      onClick={() => setQuantity(crate.id, qty + 1)}
                      disabled={qty >= 10}
                    >
                      <Plus size={14} />
                    </button>
                  </div>
                  <button
                    className="boutique-crate-buy-btn"
                    onClick={() => onOpenCrate(crate.id, qty)}
                    disabled={!canAfford}
                  >
                    <span>{totalPrice.toLocaleString()} Coins</span>
                    <span className="boutique-crate-buy-label">Ouvrir</span>
                  </button>
                </div>
              )}

              {/* Multi-buy options */}
              {isBuyable && crate.five && crate.five > 0 && (
                <div className="boutique-crate-bundles">
                  <button
                    className="boutique-crate-bundle"
                    onClick={() => onOpenCrate(crate.id, 5)}
                    disabled={userCoins < crate.five}
                  >
                    <span>x5</span>
                    <span className="boutique-crate-bundle-price">
                      {crate.five?.toLocaleString()} Coins
                    </span>
                  </button>
                  {crate.teen && crate.teen > 0 && (
                    <button
                      className="boutique-crate-bundle"
                      onClick={() => onOpenCrate(crate.id, 10)}
                      disabled={userCoins < crate.teen}
                    >
                      <span>x10</span>
                      <span className="boutique-crate-bundle-price">
                        {crate.teen?.toLocaleString()} Coins
                      </span>
                    </button>
                  )}
                </div>
              )}
            </div>
          );
        })}
      </div>

      {items.length === 0 && !loading && (
        <div className="boutique-empty">
          <Box size={48} className="boutique-empty-icon" />
          <p>Aucune caisse disponible</p>
        </div>
      )}
    </div>
  );
};

export default BoutiqueCrates;
