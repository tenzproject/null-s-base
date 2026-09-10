import React, { useState, useEffect, useCallback, useRef, useMemo } from 'react';
import { generateAccentVars } from '@/utils/accentColors';
import { X, Search, Package, ShoppingBag, Check, AlertCircle } from 'lucide-react';
import { CatalogTabletProps, CatalogData, CatalogItem } from './types';
import './CatalogTablet.css';

const GetParentResourceName = () => 'null-core';

const CatalogTablet: React.FC<CatalogTabletProps> = ({ visible, onClose, primaryColor }) => {
  const [catalogData, setCatalogData] = useState<CatalogData | null>(null);
  const [hiding, setHiding] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedItem, setSelectedItem] = useState<CatalogItem | null>(null);
  const [selectedOption, setSelectedOption] = useState<string>('');
  const [purchasing, setPurchasing] = useState(false);
  const [notification, setNotification] = useState<{ message: string; type: 'success' | 'error' } | null>(null);
  const searchRef = useRef<HTMLInputElement>(null);

  const accentColor = primaryColor || '#3498db';
  const catalogAccentVars = useMemo(() => generateAccentVars('--catalog-accent', accentColor), [accentColor]);

  // Listen for NUI messages
  useEffect(() => {
    const handleMessage = (event: MessageEvent) => {
      const { action, data } = event.data;

      switch (action) {
        case 'catalog:open':
          if (data) {
            setCatalogData(data);
            setSearchQuery('');
            setSelectedItem(null);
            setSelectedOption('');
            setPurchasing(false);
          }
          break;

        case 'catalog:close':
          setCatalogData(null);
          setSelectedItem(null);
          break;

        case 'catalog:purchaseResult':
          setPurchasing(false);
          if (data?.success) {
            showNotification(data.message || 'Achat effectué avec succès !', 'success');
            setSelectedItem(null);
          } else {
            showNotification(data?.message || 'Erreur lors de l\'achat', 'error');
          }
          break;
      }
    };
    window.addEventListener('message', handleMessage);
    return () => window.removeEventListener('message', handleMessage);
  }, []);

  const showNotification = useCallback((message: string, type: 'success' | 'error') => {
    setNotification({ message, type });
    setTimeout(() => setNotification(null), 3000);
  }, []);

  const handleClose = useCallback(() => {
    setHiding(true);
    setTimeout(() => {
      setHiding(false);
      onClose();
      fetch(`https://${GetParentResourceName()}/catalog:close`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({}),
      });
    }, 300);
  }, [onClose]);

  // Escape to close (or close modal)
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape' && visible) {
        if (selectedItem) {
          setSelectedItem(null);
        } else {
          handleClose();
        }
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [visible, handleClose, selectedItem]);

  const handleCardClick = (item: CatalogItem) => {
    setSelectedItem(item);
    setSelectedOption(item.options?.[0]?.value || '');
  };

  const handlePurchase = async () => {
    if (!selectedItem || !catalogData || purchasing) return;
    setPurchasing(true);

    try {
      await fetch(`https://${GetParentResourceName()}/catalog:buy`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          itemId: selectedItem.id,
          option: selectedOption || null,
          callbackEvent: catalogData.callbackEvent,
          metadata: selectedItem.metadata || {},
        }),
      });
    } catch (e) {
      setPurchasing(false);
    }
  };

  const currency = catalogData?.currency || '$';

  const filteredItems = catalogData?.items.filter(item => {
    if (!searchQuery) return true;
    return item.label.toLowerCase().includes(searchQuery.toLowerCase()) ||
           (item.description || '').toLowerCase().includes(searchQuery.toLowerCase());
  }) || [];

  if (!visible || !catalogData) return null;

  return (
    <div className={`catalog-overlay ${hiding ? 'catalog-hiding' : ''}`}>
      <div className="catalog-container" style={catalogAccentVars as React.CSSProperties}>

        {/* Header */}
        <div className="catalog-header">
          <div className="catalog-header-left">
            <div
              className="catalog-header-icon"
              style={{ background: `linear-gradient(135deg, ${accentColor}, ${accentColor}88)` }}
            >
              <ShoppingBag size={20} />
            </div>
            <div className="catalog-header-text">
              <h1>{catalogData.title}</h1>
              {catalogData.subtitle && <p>{catalogData.subtitle}</p>}
            </div>
          </div>
          <div className="catalog-header-right">
            <div className="catalog-search">
              <Search size={16} />
              <input
                ref={searchRef}
                type="text"
                placeholder="Rechercher..."
                value={searchQuery}
                onChange={e => setSearchQuery(e.target.value)}
              />
            </div>
            <button className="catalog-close-btn" onClick={handleClose}>
              <X size={18} />
            </button>
          </div>
        </div>

        {/* Grid */}
        <div className="catalog-grid-wrapper">
          <div className="catalog-grid">
            {filteredItems.map((item) => (
              <div
                key={item.id}
                className="catalog-card"
                onClick={() => handleCardClick(item)}
              >
                <div className="catalog-card-image">
                  {(catalogData.imagePath || item.image) && (
                    <img
                      src={item.image || `${catalogData.imagePath}${item.id}.png`}
                      alt={item.label}
                      onError={(e) => { (e.target as HTMLImageElement).style.display = 'none'; }}
                    />
                  )}
                  <div className="catalog-card-image-fallback">
                    <Package size={32} />
                  </div>
                </div>
                <div className="catalog-card-info">
                  <span className="catalog-card-label">{item.label}</span>
                  {item.description && (
                    <span className="catalog-card-desc">{item.description}</span>
                  )}
                </div>
                <span className="catalog-card-price" style={{ color: accentColor }}>
                  {currency}{item.price.toLocaleString()}
                </span>
              </div>
            ))}
            {filteredItems.length === 0 && (
              <div className="catalog-empty">
                <Search size={48} />
                <p>Aucun article trouvé</p>
              </div>
            )}
          </div>
        </div>

        {/* Detail Modal */}
        {selectedItem && (
          <div className="catalog-modal-overlay" onClick={() => setSelectedItem(null)}>
            <div className="catalog-modal" onClick={(e) => e.stopPropagation()}>
              <div className="catalog-modal-image">
                {(catalogData.imagePath || selectedItem.image) && (
                  <img
                    src={selectedItem.image || `${catalogData.imagePath}${selectedItem.id}.png`}
                    alt={selectedItem.label}
                    onError={(e) => { (e.target as HTMLImageElement).style.display = 'none'; }}
                  />
                )}
                <div className="catalog-modal-image-fallback">
                  <Package size={48} />
                </div>
                <button className="catalog-modal-close" onClick={() => setSelectedItem(null)}>
                  <X size={16} />
                </button>
              </div>

              <div className="catalog-modal-body">
                <h2 className="catalog-modal-title">{selectedItem.label}</h2>
                {selectedItem.description && (
                  <p className="catalog-modal-description">{selectedItem.description}</p>
                )}
                <span className="catalog-modal-price" style={{ color: accentColor }}>
                  {currency}{selectedItem.price.toLocaleString()}
                </span>

                {/* Options */}
                {selectedItem.options && selectedItem.options.length > 0 && (
                  <div className="catalog-modal-options">
                    <span className="catalog-modal-options-label">Options</span>
                    <select
                      className="catalog-modal-select"
                      value={selectedOption}
                      onChange={(e) => setSelectedOption(e.target.value)}
                    >
                      {selectedItem.options.map((opt) => (
                        <option key={opt.value} value={opt.value}>{opt.label}</option>
                      ))}
                    </select>
                  </div>
                )}

                {/* Buy button */}
                <button
                  className="catalog-modal-buy"
                  onClick={handlePurchase}
                  disabled={purchasing}
                  style={{ backgroundColor: accentColor }}
                >
                  <ShoppingBag size={16} />
                  {purchasing ? 'Achat en cours...' : 'Acheter'}
                </button>
              </div>
            </div>
          </div>
        )}

        {/* Notification */}
        {notification && (
          <div className={`catalog-notification ${notification.type}`}>
            {notification.type === 'success' ? <Check size={16} /> : <AlertCircle size={16} />}
            <span>{notification.message}</span>
          </div>
        )}
      </div>
    </div>
  );
};

export default CatalogTablet;
