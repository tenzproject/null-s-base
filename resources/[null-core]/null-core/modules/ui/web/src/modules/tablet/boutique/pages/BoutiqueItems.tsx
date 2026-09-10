import React, { useMemo } from 'react';
import { BoutiqueItem } from '../types';
import { Car, Swords, Package, Zap, Eye, Loader2 } from 'lucide-react';
import { packBento, SIZE_TO_CELLS } from '../utils/bentoPacker';

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

const CAT_LABELS: Record<string, string> = {
  vehicles: 'Véhicule',
  weapons: 'Arme',
  packs: 'Pack',
  boosts: 'Boost',
};

const BoutiqueItems: React.FC<BoutiqueItemsProps> = ({ items, category, loading, onItemClick, onPreview }) => {
  const packed = useMemo(
    () => packBento(items, item => item.cells || (item.size ? SIZE_TO_CELLS[item.size] : 2)),
    [items]
  );

  if (loading) {
    return (
      <div className="boutique-loading">
        <Loader2 size={32} className="boutique-spinner" />
        <p>Chargement...</p>
      </div>
    );
  }

  return (
    <div className="bq-page">
      <div className="bq-page-header">
        <div>
          <h2 className="bq-page-title-h">{CATEGORY_TITLES[category] || category}</h2>
          <p className="bq-page-sub">{CATEGORY_DESCS[category]}</p>
        </div>
        <span className="bq-page-count">{items.length} article{items.length > 1 ? 's' : ''}</span>
      </div>

      <div className="bq-bento">
        {packed.placed.map(({ item, size, col, row, w, h }, i) => {
          const isLarge = size === 'featured' || size === 'large' || size === 'tall';
          return (
            <button
              key={i}
              className={`bq-pcard bq-pcard--${size}`}
              onClick={() => onItemClick(item)}
              style={{
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
                  {CATEGORY_ICONS[category]}
                </div>
              )}

              {/* {category === 'vehicles' && item.model && onPreview && (
                <button
                  className="bq-pcard-preview"
                  onClick={(e) => { e.stopPropagation(); onPreview(item.model!, item); }}
                >
                  <Eye size={13} />
                  <span>Aperçu</span>
                </button>
              )} */}

              {item.tags && item.tags.length > 0 && (
                <div className="bq-pcard-tags">
                  {item.tags.slice(0, 2).map((tag, j) => (
                    <span key={j} className="bq-pcard-tag">{tag}</span>
                  ))}
                </div>
              )}

              <div className={`bq-pcard-info ${isLarge ? 'bq-pcard-info--bottom' : 'bq-pcard-info--top'}`}>
                <span className="bq-pcard-eyebrow">{CAT_LABELS[category] || category}</span>
                <h3 className="bq-pcard-title">{item.label}</h3>
                {isLarge && item.description && (
                  <p className="bq-pcard-desc">{item.description}</p>
                )}
                <div className="bq-pcard-price">
                  {item.buyable !== false ? (
                    <>
                      <span className="bq-pcard-price-value">{item.price.toLocaleString()}</span>
                      <span className="bq-pcard-price-label">Coins</span>
                    </>
                  ) : (
                    <span className="bq-pcard-unavailable">Non achetable</span>
                  )}
                </div>
              </div>
            </button>
          );
        })}
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
