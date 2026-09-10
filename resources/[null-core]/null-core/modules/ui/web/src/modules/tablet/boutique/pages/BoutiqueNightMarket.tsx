import React, { useState, useEffect, useCallback, useMemo } from 'react';
import { NightMarketCard, RarityLevel } from '../types';
import { Clock, Car, Swords, ShoppingCart, Lock, Sparkles } from 'lucide-react';
import { packBento, RARITY_NATURAL_CELLS, SIZE_TO_CELLS } from '../utils/bentoPacker';

const GetParentResourceName = () => 'null-core';

interface BoutiqueNightMarketProps {
  primaryColor: string;
  cards: NightMarketCard[];
  userCoins: number;
  timeLeft: number;
  onPurchaseResult: (success: boolean, message: string, coins?: number) => void;
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

const BoutiqueNightMarket: React.FC<BoutiqueNightMarketProps> = ({
  cards,
  userCoins,
  timeLeft: initialTimeLeft,
  onPurchaseResult,
}) => {
  const [revealedCards, setRevealedCards] = useState<Record<string, boolean>>({});
  const [flippingCard, setFlippingCard] = useState<string | null>(null);
  const [purchasingCard, setPurchasingCard] = useState<string | null>(null);
  const [timeLeft, setTimeLeft] = useState(initialTimeLeft);

  const packed = useMemo(
    () => packBento(cards, card => card.cells || (card.size ? SIZE_TO_CELLS[card.size] : RARITY_NATURAL_CELLS[card.rarity] || 2)),
    [cards]
  );

  useEffect(() => { setTimeLeft(initialTimeLeft); }, [initialTimeLeft]);

  useEffect(() => {
    if (timeLeft <= 0) return;
    const interval = setInterval(() => setTimeLeft(prev => Math.max(0, prev - 1)), 1000);
    return () => clearInterval(interval);
  }, [timeLeft]);

  useEffect(() => {
    if (cards.length === 0) return;
    const cardIds = cards.map(c => c.id);
    fetch(`https://${GetParentResourceName()}/boutique:nightmarket:getRevealed`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ cardIds }),
    });
  }, [cards]);

  useEffect(() => {
    const handleMessage = (event: MessageEvent) => {
      const data = event.data;
      switch (data.action) {
        case 'boutique:nightmarket:revealedCards':
          if (data.revealed) setRevealedCards(data.revealed);
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
    fetch(`https://${GetParentResourceName()}/boutique:nightmarket:revealCard`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ cardId }),
    });
    setTimeout(() => {
      setRevealedCards(prev => ({ ...prev, [cardId]: true }));
      setFlippingCard(null);
    }, 900);
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
    if (d > 0) return `${d}j ${h}h ${m.toString().padStart(2, '0')}m`;
    const s = seconds % 60;
    return `${h}h ${m.toString().padStart(2, '0')}m ${s.toString().padStart(2, '0')}s`;
  };

  return (
    <div className="bq-page bq-page--full bq-nightmarket">
      <div className="bq-page-header">
        <div>
          <h2 className="bq-page-title-h">Night Market</h2>
          <p className="bq-page-sub">{cards.length} offres exclusives. Clique pour révéler.</p>
        </div>
        <div className="bq-page-timer">
          <Clock size={15} />
          <span>{formatTime(timeLeft)}</span>
        </div>
      </div>

      <div
        className="bq-bento bq-bento--fill bq-bento--nm"
        style={{
          gridTemplateColumns: `repeat(${packed.cols}, 1fr)`,
          gridTemplateRows: `repeat(${packed.rows}, 1fr)`,
        } as React.CSSProperties}
      >
        {packed.placed.map(({ item: card, size, col, row, w, h }, i) => {
          const isRevealed = revealedCards[card.id] || false;
          const isFlipping = flippingCard === card.id;
          const isLarge = size === 'featured' || size === 'large' || size === 'tall';
          const rarityColor = RARITY_COLORS[card.rarity] || '#b0b0b0';
          const canAfford = userCoins >= card.price;
          const isPurchasing = purchasingCard === card.id;

          return (
            <div
              key={card.id}
              className={`bq-pcard bq-pcard--${size} bq-nmcard ${isFlipping ? 'is-flipping' : ''} ${isRevealed ? 'is-revealed' : 'is-hidden'}`}
              onClick={() => !isRevealed && !isFlipping && handleReveal(card.id)}
              style={{
                animationDelay: `${i * 90}ms`,
                '--rarity-color': rarityColor,
                '--rarity-color-soft': `${rarityColor}33`,
                '--rarity-color-glow': `${rarityColor}55`,
                gridColumn: `${col + 1} / span ${w}`,
                gridRow: `${row + 1} / span ${h}`,
              } as React.CSSProperties}
            >
              <div className="bq-pcard-bg" />
              <div className="bq-nmcard-tint" />
              <div className="bq-pcard-shade" />

              {/* Hidden face */}
              {!isRevealed && (
                <div className="bq-nmcard-cover">
                  <div className="bq-nmcard-cover-glow" />
                  <div className="bq-nmcard-cover-pattern" />
                  <div className="bq-nmcard-cover-content">
                    <Sparkles size={isLarge ? 28 : 20} className="bq-nmcard-cover-icon" />
                    <span className="bq-nmcard-cover-rarity">{RARITY_LABELS[card.rarity]}</span>
                    <span className="bq-nmcard-cover-hint">Cliquer pour révéler</span>
                  </div>
                </div>
              )}

              {/* Flash effect during flip */}
              {isFlipping && <div className="bq-nmcard-flash" />}

              {/* Revealed face */}
              {isRevealed && (
                <>
                  {card.image ? (
                    <img src={card.image} alt={card.label} className="bq-pcard-img bq-nmcard-img" />
                  ) : (
                    <div className="bq-pcard-placeholder">
                      {card.type === 'vehicle' ? <Car size={48} /> : <Swords size={48} />}
                    </div>
                  )}

                  <div className="bq-pcard-rarity bq-nmcard-rarity-badge" style={{ color: rarityColor, borderColor: `${rarityColor}55` }}>
                    {RARITY_LABELS[card.rarity]}
                  </div>

                  <div className="bq-pcard-discount">-{card.discount}%</div>

                  <div className={`bq-pcard-info ${isLarge ? 'bq-pcard-info--bottom' : 'bq-pcard-info--top'}`}>
                    <span className="bq-pcard-eyebrow">{card.type === 'vehicle' ? 'Véhicule' : 'Arme'}</span>
                    <h3 className="bq-pcard-title">{card.label}</h3>
                    {isLarge && card.description && (
                      <p className="bq-pcard-desc">{card.description}</p>
                    )}
                    <div className="bq-pcard-price">
                      <span className={`bq-pcard-price-value ${!canAfford ? 'is-low' : ''}`}>{card.price.toLocaleString()}</span>
                      <span className="bq-pcard-price-label">Coins</span>
                      <span className="bq-pcard-price-original">{card.originalPrice.toLocaleString()}</span>
                    </div>
                  </div>

                  <button
                    className={`bq-nmcard-buy ${canAfford ? '' : 'is-low'}`}
                    disabled={!canAfford || isPurchasing}
                    onClick={(e) => { e.stopPropagation(); handlePurchase(card.id); }}
                  >
                    {isPurchasing ? '...' : canAfford ? (
                      <><ShoppingCart size={13} /><span>Acheter</span></>
                    ) : (
                      <><Lock size={13} /><span>Insuffisant</span></>
                    )}
                  </button>
                </>
              )}
            </div>
          );
        })}
      </div>
    </div>
  );
};

export default BoutiqueNightMarket;
