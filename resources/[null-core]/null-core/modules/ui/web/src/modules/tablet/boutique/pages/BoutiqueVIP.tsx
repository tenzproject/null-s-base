import React, { useState, useEffect } from 'react';
import { VIPData, VIPAdvantageInfo } from '../types';
import { Crown, Shield, Zap, Star, Check, X, Clock, ChevronRight, Wrench, Heart, Package, TrendingUp, Sprout, Wheat, Briefcase, Move, User, Sparkles, Lock, ArrowUp } from 'lucide-react';

const GetParentResourceName = () => 'null-core';

interface BoutiqueVIPProps {
  primaryColor: string;
  userCoins: number;
  onPurchaseResult: (success: boolean, message: string, coins?: number) => void;
}

interface TierPurchaseInfo {
  price: number;
  blocked: boolean;
  blockedReason: string | null;
  upgradeDiscount: number;
}

const ICON_MAP: Record<string, React.ReactNode> = {
  zap: <Zap size={16} />,
  wrench: <Wrench size={16} />,
  heart: <Heart size={16} />,
  package: <Package size={16} />,
  trending: <TrendingUp size={16} />,
  sprout: <Sprout size={16} />,
  wheat: <Wheat size={16} />,
  briefcase: <Briefcase size={16} />,
  move: <Move size={16} />,
  user: <User size={16} />,
  shield: <Shield size={16} />,
  sparkles: <Sparkles size={16} />,
  crown: <Crown size={16} />,
};

const TIERS = [
  { key: 'Basic', label: 'VIP Basic', color: '#f59e0b', icon: '⭐', price: 1000, durationDays: 31 },
  { key: 'Premium', label: 'VIP Premium', color: '#a855f7', icon: '💎', price: 2500, durationDays: 31 },
];

const BoutiqueVIP: React.FC<BoutiqueVIPProps> = ({ primaryColor, userCoins, onPurchaseResult }) => {
  const [vipData, setVipData] = useState<VIPData | null>(null);
  const [purchaseInfo, setPurchaseInfo] = useState<Record<string, TierPurchaseInfo>>({});
  const [loading, setLoading] = useState(true);
  const [buying, setBuying] = useState<string | null>(null);

  const fetchAllData = () => {
    Promise.all([
      fetch(`https://${GetParentResourceName()}/boutique:getVipData`, { method: 'POST' }).then(r => r.json()),
      fetch(`https://${GetParentResourceName()}/boutique:getVipPurchaseInfo`, { method: 'POST' }).then(r => r.json()),
    ])
      .then(([vip, info]) => {
        setVipData(vip);
        setPurchaseInfo(info || {});
        setLoading(false);
      })
      .catch(() => setLoading(false));
  };

  useEffect(() => {
    fetchAllData();
  }, []);

  const handleBuy = (tierKey: string) => {
    const info = purchaseInfo[tierKey];
    if (info?.blocked) return;

    const effectivePrice = info?.price ?? TIERS.find(t => t.key === tierKey)?.price ?? 0;
    if (userCoins < effectivePrice) {
      onPurchaseResult(false, 'Coins insuffisants');
      return;
    }
    setBuying(tierKey);
    fetch(`https://${GetParentResourceName()}/boutique:buyVip`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ tier: tierKey }),
    })
      .then(() => {
        setTimeout(() => {
          fetchAllData();
        }, 1500);
        setBuying(null);
      })
      .catch(() => setBuying(null));
  };

  const renderAdvantageValue = (val: boolean | string) => {
    if (val === true) return <Check size={14} className="bvip-check" />;
    if (val === false) return <X size={14} className="bvip-cross" />;
    return <span className="bvip-val">{val}</span>;
  };

  const advantages: VIPAdvantageInfo[] = vipData?.advantages || [];

  return (
    <div className="bvip-page">
      {/* Header */}
      <div className="boutique-items-header">
        <div className="boutique-items-header-info">
          <h2>VIP</h2>
          <p>Débloquez des avantages exclusifs</p>
        </div>
      </div>

      {/* Current VIP Status */}
      {vipData?.isVip && vipData.type && (
        <div className="bvip-status" style={{
          borderColor: TIERS.find(t => t.key === vipData.type)?.color || primaryColor,
          background: `linear-gradient(135deg, ${TIERS.find(t => t.key === vipData.type)?.color || primaryColor}12, transparent)`,
        }}>
          <div className="bvip-status-icon" style={{ color: TIERS.find(t => t.key === vipData.type)?.color }}>
            <Crown size={22} />
          </div>
          <div className="bvip-status-info">
            <span className="bvip-status-label" style={{ color: TIERS.find(t => t.key === vipData.type)?.color }}>
              {TIERS.find(t => t.key === vipData.type)?.icon} {TIERS.find(t => t.key === vipData.type)?.label || vipData.type}
            </span>
            {vipData.time && (
              <span className="bvip-status-time">
                <Clock size={12} />
                Expire dans {vipData.time.days}j {vipData.time.hours}h {vipData.time.minutes}min
              </span>
            )}
          </div>
          <div className="bvip-status-badge" style={{ backgroundColor: TIERS.find(t => t.key === vipData.type)?.color }}>
            Actif
          </div>
        </div>
      )}

      {/* Tier Cards */}
      <div className="bvip-tiers">
        {TIERS.map(tier => {
          const info = purchaseInfo[tier.key];
          const isActive = info?.blockedReason === 'already_active';
          const isDowngrade = info?.blockedReason === 'downgrade';
          const isBlocked = info?.blocked || false;
          const isUpgrade = !isBlocked && vipData?.isVip && (info?.upgradeDiscount ?? 0) > 0;
          const effectivePrice = info?.price ?? tier.price;
          const discount = info?.upgradeDiscount ?? 0;
          const canAfford = userCoins >= effectivePrice;

          return (
            <div
              key={tier.key}
              className={`bvip-tier-card ${isActive ? 'active' : ''} ${isDowngrade ? 'downgrade' : ''} ${tier.key === 'Premium' ? 'premium' : ''}`}
              style={{ borderColor: `${tier.color}40` }}
            >
              <div className="bvip-tier-header" style={{ background: `linear-gradient(135deg, ${tier.color}20, ${tier.color}08)` }}>
                <div className="bvip-tier-title">
                  <h3 style={{ color: tier.color }}>{tier.label}</h3>
                  <span>{tier.durationDays} jours</span>
                </div>
                {tier.key === 'Premium' && <span className="bvip-tier-popular" style={{ backgroundColor: tier.color }}>Populaire</span>}
              </div>

              <div className="bvip-tier-price">
                {isUpgrade && discount > 0 ? (
                  <>
                    <span className="bvip-tier-price-original">{tier.price.toLocaleString()}</span>
                    <span className="bvip-tier-price-amount">{effectivePrice.toLocaleString()}</span>
                  </>
                ) : (
                  <span className="bvip-tier-price-amount">{effectivePrice.toLocaleString()}</span>
                )}
                <span className="bvip-tier-price-label">Coins</span>
              </div>

              {isUpgrade && discount > 0 && (
                <div className="bvip-upgrade-info" style={{ color: tier.color }}>
                  <ArrowUp size={12} />
                  <span>-{discount.toLocaleString()} coins (VIP restant déduit)</span>
                </div>
              )}

              <div className="bvip-tier-features">
                {advantages.map((adv, i) => {
                  const val = tier.key === 'Basic' ? adv.basic : adv.premium;
                  const hasFeature = val !== false;
                  return (
                    <div key={i} className={`bvip-tier-feature ${!hasFeature ? 'disabled' : ''}`}>
                      <div className="bvip-tier-feature-check" style={hasFeature ? { color: tier.color } : {}}>
                        {hasFeature ? <Check size={12} /> : <X size={12} />}
                      </div>
                      <span className="bvip-tier-feature-label">{adv.label}</span>
                      {typeof val === 'string' && <span className="bvip-tier-feature-val" style={{ color: tier.color }}>{val}</span>}
                    </div>
                  );
                })}
              </div>

              <button
                className="bvip-tier-btn"
                style={{
                  backgroundColor: isBlocked ? 'transparent' : tier.color,
                  borderColor: tier.color,
                  color: isBlocked ? tier.color : '#fff',
                  opacity: (isDowngrade || (!canAfford && !isBlocked)) ? 0.5 : 1,
                }}
                disabled={isBlocked || buying !== null || !canAfford}
                onClick={() => handleBuy(tier.key)}
              >
                {buying === tier.key ? 'Achat en cours...'
                  : isActive ? 'Actif'
                  : isDowngrade ? <><Lock size={12} /> VIP supérieur actif</>
                  : isUpgrade ? <><ArrowUp size={12} /> Passer au {tier.label}</>
                  : !canAfford ? 'Coins insuffisants'
                  : 'Acheter'}
                {!isBlocked && canAfford && buying !== tier.key && <ChevronRight size={14} />}
              </button>
            </div>
          );
        })}
      </div>

      {/* Advantages Comparison Table */}
      <div className="bvip-comparison">
        <h3 className="bvip-comparison-title">
          <Star size={16} />
          Comparaison détaillée
        </h3>
        <div className="bvip-table">
          <div className="bvip-table-header">
            <div className="bvip-table-cell bvip-table-label">Avantage</div>
            <div className="bvip-table-cell bvip-table-default">Sans VIP</div>
            <div className="bvip-table-cell" style={{ color: TIERS[0].color }}>Basic</div>
            <div className="bvip-table-cell" style={{ color: TIERS[1].color }}>Premium</div>
          </div>
          {advantages.map((adv, i) => (
            <div key={i} className="bvip-table-row">
              <div className="bvip-table-cell bvip-table-label">
                <span className="bvip-table-icon">
                  {ICON_MAP[adv.icon] || <Star size={14} />}
                </span>
                <div>
                  <span className="bvip-table-name">{adv.label}</span>
                  <span className="bvip-table-desc">{adv.desc}</span>
                </div>
              </div>
              <div className="bvip-table-cell bvip-table-default">
                {adv.default ? <span className="bvip-val">{adv.default}</span> : <X size={14} className="bvip-cross" />}
              </div>
              <div className="bvip-table-cell">{renderAdvantageValue(adv.basic)}</div>
              <div className="bvip-table-cell">{renderAdvantageValue(adv.premium)}</div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};

export default BoutiqueVIP;
