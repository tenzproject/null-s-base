import React, { useState, useEffect, useCallback } from 'react';
import { NightMarketCard } from '../types';
import { Clock, Car, Swords, Sparkles, ShoppingCart, Lock, Eye } from 'lucide-react';

const GetParentResourceName = () => 'null-core';

interface BoutiqueNightMarketProps {
  primaryColor: string;
  cards: NightMarketCard[];
  userCoins: number;
  timeLeft: number;
  onPurchaseResult: (success: boolean, message: string, coins?: number) => void;
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

const RARITY_EMOJIS: Record<string, string> = {
  common: '⚪',
  rare: '🔵',
  epic: '🟣',
  legendary: '🟠',
  ultimate: '🔴',
};

const BoutiqueNightMarket: React.FC<BoutiqueNightMarketProps> = ({
  primaryColor,
  cards,
  userCoins,
  timeLeft: initialTimeLeft,
  onPurchaseResult,
}) => {
  const [revealedCards, setRevealedCards] = useState<Record<string, boolean>>({});
  const [flippingCard, setFlippingCard] = useState<string | null>(null);
  const [purchasingCard, setPurchasingCard] = useState<string | null>(null);
  const [timeLeft, setTimeLeft] = useState(initialTimeLeft);

  // Timer countdown
  useEffect(() => {
    setTimeLeft(initialTimeLeft);
  }, [initialTimeLeft]);

  useEffect(() => {
    if (timeLeft <= 0) return;
    const interval = setInterval(() => {
      setTimeLeft(prev => Math.max(0, prev - 1));
    }, 1000);
    return () => clearInterval(interval);
  }, [timeLeft]);

  // Request revealed cards from KVP on mount
  useEffect(() => {
    if (cards.length === 0) return;
    const cardIds = cards.map(c => c.id);
    fetch(`https://${GetParentResourceName()}/boutique:nightmarket:getRevealed`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ cardIds }),
    });
  }, [cards]);

  // Listen for NUI messages
  useEffect(() => {
    const handleMessage = (event: MessageEvent) => {
      const data = event.data;
      switch (data.action) {
        case 'boutique:nightmarket:revealedCards':
          if (data.revealed) {
            setRevealedCards(data.revealed);
          }
          break;
        case 'boutique:nightmarket:purchaseResult':
          setPurchasingCard(null);
          onPurchaseResult(data.success, data.message, data.coins);
          break;
      }
    };
    window.addEventListener('message', handleMessage);
    return () => window.removeEventListener('message', handleMessage);
  }, [onPurchaseResult]);

  const handleReveal = useCallback((cardId: string) => {
    if (revealedCards[cardId] || flippingCard) return;
    setFlippingCard(cardId);

    // Save to KVP
    fetch(`https://${GetParentResourceName()}/boutique:nightmarket:revealCard`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ cardId }),
    });

    // Animate flip then reveal
    setTimeout(() => {
      setRevealedCards(prev => ({ ...prev, [cardId]: true }));
      setFlippingCard(null);
    }, 600);
  }, [revealedCards, flippingCard]);

  const handlePurchase = useCallback((cardId: string) => {
    if (purchasingCard) return;
    setPurchasingCard(cardId);
    fetch(`https://${GetParentResourceName()}/boutique:nightmarket:purchase`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ cardId }),
    });
  }, [purchasingCard]);

  const formatTime = (seconds: number) => {
    const d = Math.floor(seconds / 86400);
    const h = Math.floor((seconds % 86400) / 3600);
    const m = Math.floor((seconds % 3600) / 60);
    const s = seconds % 60;
    if (d > 0) return `${d}j ${h}h ${m.toString().padStart(2, '0')}m`;
    return `${h}h ${m.toString().padStart(2, '0')}m ${s.toString().padStart(2, '0')}s`;
  };

  return (
    <div className="boutique-nm-page">
      {/* Header */}
      <div className="boutique-nm-header">
        <div className="boutique-nm-header-left">
          {/* <div className="boutique-nm-badge">
            <Sparkles size={16} />
            <span>Night Market</span>
          </div> */}
          <h2 className="boutique-page-title">Night Market</h2>
          <p className="boutique-page-subtitle">
            5 offres exclusives avec des réductions massives. Clique sur une carte pour la révéler !
          </p>
        </div>
        <div className="boutique-nm-timer">
          <Clock size={18} />
          <div className="boutique-nm-timer-text">
            <span className="boutique-nm-timer-label">Expire dans</span>
            <span className="boutique-nm-timer-value">{formatTime(timeLeft)}</span>
          </div>
        </div>
      </div>

      {/* Cards */}
      <div className="boutique-nm-cards">
        {cards.map((card, i) => {
          const isRevealed = revealedCards[card.id] || false;
          const isFlipping = flippingCard === card.id;
          const rarityColor = RARITY_COLORS[card.rarity] || '#b0b0b0';
          const canAfford = userCoins >= card.price;
          const isPurchasing = purchasingCard === card.id;

          return (
            <div
              key={card.id}
              className={`boutique-nm-card-wrapper ${isFlipping ? 'flipping' : ''}`}
              style={{ animationDelay: `${i * 80}ms` }}
            >
              <div
                className={`boutique-nm-card ${isRevealed ? 'revealed' : 'hidden-card'}`}
                onClick={() => !isRevealed && handleReveal(card.id)}
                style={{
                  '--rarity-color': rarityColor,
                  '--rarity-glow': `${rarityColor}40`,
                } as React.CSSProperties}
              >
                {/* Hidden face */}
                {!isRevealed && (
                  <div className="boutique-nm-card-hidden">
                    <div className="boutique-nm-card-hidden-glow" style={{ backgroundColor: `${rarityColor}15` }} />
                    <div className="boutique-nm-card-hidden-icon" style={{ color: rarityColor }}>
                      <span className="boutique-nm-card-hidden-emoji">{RARITY_EMOJIS[card.rarity]}</span>
                    </div>
                    <div className="boutique-nm-card-hidden-label" style={{ color: `${rarityColor}90` }}>
                      {RARITY_LABELS[card.rarity]}
                    </div>
                    <div className="boutique-nm-card-hidden-hint">
                      <Eye size={14} />
                      <span>Cliquer pour révéler</span>
                    </div>
                    <div className="boutique-nm-card-hidden-border" style={{ borderColor: `${rarityColor}30` }} />
                  </div>
                )}

                {/* Revealed face */}
                {isRevealed && (
                  <div className="boutique-nm-card-revealed">
                    {/* <div className="boutique-nm-card-strip" /> */}

                    <div className="boutique-nm-card-rarity" style={{ backgroundColor: `${rarityColor}20`, color: rarityColor }}>
                      {RARITY_LABELS[card.rarity]}
                    </div>

                    <div className="boutique-nm-card-discount-badge">
                      -{card.discount}%
                    </div>

                    <div className="boutique-nm-card-image">
                      <div className="boutique-nm-card-placeholder">
                        {card.type === 'vehicle' ? <Car size={44} /> : <Swords size={44} />}
                      </div>
                    </div>

                    <div className="boutique-nm-card-info">
                      <span className="boutique-nm-card-type">{card.type === 'vehicle' ? 'Véhicule' : 'Arme'}</span>
                      <span className="boutique-nm-card-name">{card.label}</span>
                      {card.description && (
                        <span className="boutique-nm-card-desc">{card.description}</span>
                      )}
                    </div>

                    <div className="boutique-nm-card-footer">
                      <div className="boutique-nm-card-prices">
                        <div className={`boutique-nm-card-price ${!canAfford ? 'insufficient' : ''}`}>
                          <span>{card.price.toLocaleString()}</span>
                          <span className="boutique-price-label">Coins</span>
                        </div>
                        <span className="boutique-nm-card-original">{card.originalPrice.toLocaleString()}</span>
                      </div>
                      <button
                        className={`boutique-nm-card-buy ${canAfford ? '' : 'insufficient'}`}
                        disabled={!canAfford || isPurchasing}
                        onClick={(e) => {
                          e.stopPropagation();
                          handlePurchase(card.id);
                        }}
                      >
                        {isPurchasing ? (
                          <span>...</span>
                        ) : canAfford ? (
                          <>
                            <ShoppingCart size={14} />
                            <span>Acheter</span>
                          </>
                        ) : (
                          <>
                            <Lock size={14} />
                            <span>Insuffisant</span>
                          </>
                        )}
                      </button>
                    </div>
                  </div>
                )}
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
};

export default BoutiqueNightMarket;
