import React from 'react';
import { BoutiqueItem } from '../types';
import { Car, Swords, Package, Zap, Eye, Loader2 } from 'lucide-react';

interface BoutiqueItemsProps {
  primaryColor: string;
  items: BoutiqueItem[];
  category: string;
  loading: boolean;
  onItemClick: (item: BoutiqueItem) => void;
  onPreview?: (model: string, item?: BoutiqueItem) => void;
}

const CATEGORY_TITLES: Record<string, string> = {
  vehicles: 'Véhicules',
  weapons: 'Armes',
  packs: 'Packs',
  boosts: 'Boosts',
};

const CATEGORY_DESCS: Record<string, string> = {
  vehicles: 'Découvre notre sélection de véhicules exclusifs',
  weapons: 'Des armes puissantes pour dominer le terrain',
  packs: 'Packs entreprise, gang et VIP',
  boosts: 'Multiplie tes gains avec nos boosts',
};

const CATEGORY_ICONS: Record<string, React.ReactNode> = {
  vehicles: <Car size={20} />,
  weapons: <Swords size={20} />,
  packs: <Package size={20} />,
  boosts: <Zap size={20} />,
};

const BoutiqueItems: React.FC<BoutiqueItemsProps> = ({ primaryColor, items, category, loading, onItemClick, onPreview }) => {
  if (loading) {
    return (
      <div className="boutique-loading">
        <Loader2 size={32} className="boutique-spinner" />
        <p>Chargement...</p>
      </div>
    );
  }

  return (
    <div className="boutique-items-page">
      {/* Header */}
      <div className="boutique-items-header">
        <div className="boutique-items-header-info">
          <h2>{CATEGORY_TITLES[category] || category}</h2>
          <p>{CATEGORY_DESCS[category]}</p>
        </div>
        <span className="boutique-items-count">
          {items.length} article{items.length > 1 ? 's' : ''}
        </span>
      </div>

      {/* Items Grid */}
      <div className="boutique-items-grid">
        {items.map((item, i) => (
          <div
            key={i}
            className="boutique-item-card"
            onClick={() => onItemClick(item)}
          >
            {/* Image */}
            <div className="boutique-item-card-image">
              {item.image ? (
                <img src={item.image} alt={item.label} />
              ) : (
                <div className="boutique-item-card-placeholder">
                  {category === 'vehicles' ? <Car size={36} /> : 
                   category === 'weapons' ? <Swords size={36} /> :
                   category === 'packs' ? <Package size={36} /> :
                   <Zap size={36} />}
                </div>
              )}
              {/* Tags */}
              {item.tags && item.tags.length > 0 && (
                <div className="boutique-item-card-tags">
                  {item.tags.map((tag, j) => (
                    <span key={j} className="boutique-item-card-tag">{tag}</span>
                  ))}
                </div>
              )}
              {/* Preview button for vehicles */}
              {category === 'vehicles' && item.model && onPreview && (
                <button
                  className="boutique-item-card-preview"
                  onClick={(e) => {
                    e.stopPropagation();
                    onPreview(item.model!, item);
                  }}
                >
                  <Eye size={14} />
                  <span>Aperçu</span>
                </button>
              )}
            </div>

            {/* Info */}
            <div className="boutique-item-card-body">
              <span className="boutique-item-card-name">{item.label}</span>
              {item.description && (
                <span className="boutique-item-card-desc">{item.description}</span>
              )}

              {/* Stats preview (first 3) */}
              {item.stats && (
                <div className="boutique-item-card-stats">
                  {Object.entries(item.stats).slice(0, 3).map(([stat, value]) => (
                    <div key={stat} className="boutique-item-card-stat">
                      <span className="boutique-item-card-stat-label">{stat}</span>
                      <div className="boutique-item-card-stat-bar">
                        <div
                          className="boutique-item-card-stat-fill"
                          style={{
                            width: `${(value / 10) * 100}%`,
                          }}
                        />
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>

            {/* Footer */}
            <div className="boutique-item-card-footer">
              {item.buyable !== false ? (
                <div className="boutique-item-card-price">
                  <span>{item.price.toLocaleString()}</span>
                  <span className="boutique-price-label">Coins</span>
                </div>
              ) : (
                <span className="boutique-item-card-unavailable">Non achetable</span>
              )}
            </div>
          </div>
        ))}
      </div>

      {items.length === 0 && !loading && (
        <div className="boutique-empty">
          {CATEGORY_ICONS[category]}
          <p>Aucun article disponible dans cette catégorie</p>
        </div>
      )}
    </div>
  );
};

export default BoutiqueItems;
