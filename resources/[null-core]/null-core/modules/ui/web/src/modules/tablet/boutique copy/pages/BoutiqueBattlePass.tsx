import React, { useState, useEffect, useRef, useCallback, useMemo } from 'react';
import { generateAccentVars } from '@/utils/accentColors';
import { BattlePassData, BPRewardLevel, BPReward } from '../types';
import { Shield, Lock, Check, Gift, ChevronLeft, ChevronRight, Star, Clock, Gem, Car, Swords, Package, DollarSign, Box, Zap, Crown, ArrowUp } from 'lucide-react';

import { cacheImg } from '@shared/cacheVersion';

const GetParentResourceName = () => 'null-core';
const BUY_LEVEL_COST = 150;

interface BoutiqueBattlePassProps {
  primaryColor: string;
  onNotification: (message: string, type: 'success' | 'error') => void;
  onCoinsUpdate?: (coins: number) => void;
}

const REWARD_ICONS: Record<string, React.ReactNode> = {
  money: <DollarSign size={18} />,
  item: <Package size={18} />,
  weapon: <Swords size={18} />,
  vehicle: <Car size={18} />,
  coins: <Gem size={18} />,
  crate: <Box size={18} />,
};

const REWARD_COLORS: Record<string, string> = {
  money: '#2ecc71',
  item: '#3498db',
  weapon: '#e74c3c',
  vehicle: '#f39c12',
  coins: '#9b59b6',
  crate: '#e67e22',
};

function getRewardImage(reward: BPReward): string | null {
  switch (reward.type) {
    case 'item':
      return reward.name ? cacheImg(`items/${reward.name}.webp`) : null;
    case 'vehicle':
      return reward.model ? cacheImg(`vehicles/${reward.model}.webp`) : null;
    case 'weapon':
      return reward.name ? cacheImg(`items/${reward.name.toLowerCase()}.webp`) : null;
    case 'crate':
      return reward.name ? cacheImg(`boutique/crates/${reward.name}.webp`) : null;
    default:
      return null;
  }
}

const BoutiqueBattlePass: React.FC<BoutiqueBattlePassProps> = ({ primaryColor, onNotification, onCoinsUpdate }) => {
  const [data, setData] = useState<BattlePassData | null>(null);
  const [loading, setLoading] = useState(true);
  const [claiming, setClaiming] = useState<string | null>(null);
  const [buyingLevel, setBuyingLevel] = useState(false);
  const trackRef = useRef<HTMLDivElement>(null);

  const fetchData = useCallback(() => {
    fetch(`https://${GetParentResourceName()}/battlepass:getData`, { method: 'POST' })
      .then(r => r.json())
      .then(result => {
        if (result && result.level) {
          setData(result);
        }
        setLoading(false);
      })
      .catch(() => setLoading(false));
  }, []);

  useEffect(() => {
    fetchData();

    const handleMessage = (event: MessageEvent) => {
      const msg = event.data;
      if (msg.action === 'battlepass:xpGain' && data) {
        setData(prev => prev ? { ...prev, xp: msg.xp, level: msg.level, requiredXP: msg.requiredXP } : prev);
      }
      if (msg.action === 'battlepass:levelUp' && data) {
        setData(prev => prev ? { ...prev, level: msg.level, xp: 0 } : prev);
      }
    };

    window.addEventListener('message', handleMessage);
    return () => window.removeEventListener('message', handleMessage);
  }, []);

  // Auto scroll to current level on load
  useEffect(() => {
    if (data && trackRef.current) {
      const levelIndex = Math.max(0, data.level - 2);
      const scrollTo = levelIndex * 160;
      trackRef.current.scrollLeft = scrollTo;
    }
  }, [data?.level]);

  const handleScroll = (direction: 'left' | 'right') => {
    if (!trackRef.current) return;
    const delta = direction === 'left' ? -480 : 480;
    trackRef.current.scrollBy({ left: delta, behavior: 'smooth' });
  };

  const handleClaim = (level: number, track: 'free' | 'premium') => {
    if (claiming) return;
    setClaiming(`${level}-${track}`);

    fetch(`https://${GetParentResourceName()}/battlepass:claimReward`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ level, track }),
    })
      .then(r => r.json())
      .then(result => {
        if (result.success) {
          onNotification(`Récompense récupérée : ${result.message}`, 'success');
          if (result.claimedFree || result.claimedPremium) {
            setData(prev => prev ? {
              ...prev,
              claimedFree: result.claimedFree || prev.claimedFree,
              claimedPremium: result.claimedPremium || prev.claimedPremium,
            } : prev);
          }
        } else {
          onNotification(result.message || 'Erreur', 'error');
        }
        setClaiming(null);
      })
      .catch(() => {
        onNotification('Erreur de connexion', 'error');
        setClaiming(null);
      });
  };

  const handleBuyLevel = () => {
    if (buyingLevel || !data || data.level >= data.maxLevel) return;
    setBuyingLevel(true);

    fetch(`https://${GetParentResourceName()}/battlepass:buyLevel`, { method: 'POST' })
      .then(r => r.json())
      .then(result => {
        if (result.success) {
          onNotification(result.message, 'success');
          if (result.coins !== undefined && onCoinsUpdate) onCoinsUpdate(result.coins);
          setData(prev => prev ? {
            ...prev,
            level: result.level ?? prev.level,
            xp: result.xp ?? prev.xp,
            requiredXP: result.requiredXP ?? prev.requiredXP,
          } : prev);
        } else {
          onNotification(result.message || 'Erreur', 'error');
        }
        setBuyingLevel(false);
      })
      .catch(() => {
        onNotification('Erreur de connexion', 'error');
        setBuyingLevel(false);
      });
  };

  // Compute unclaimed rewards that the player has reached (for quick-claim grid)
  // Must be before any conditional returns to respect Rules of Hooks
  const pendingRewards = useMemo(() => {
    if (!data) return [];
    const pending: { level: number; track: 'free' | 'premium'; reward: BPReward }[] = [];
    for (const r of data.rewards) {
      if (r.level > data.level) continue;
      if (r.free && !data.claimedFree.includes(r.level)) {
        pending.push({ level: r.level, track: 'free', reward: r.free });
      }
      if (r.premium && !data.claimedPremium.includes(r.level) && data.hasPremium) {
        pending.push({ level: r.level, track: 'premium', reward: r.premium });
      }
    }
    pending.sort((a, b) => b.level - a.level);
    return pending;
  }, [data]);

  const renderRewardCard = (reward: BPReward | null, level: number, track: 'free' | 'premium', isReached: boolean, isClaimed: boolean, compact?: boolean) => {
    if (!reward) {
      return <div className="bbp-reward-empty" />;
    }

    const color = REWARD_COLORS[reward.type] || '#44a5ff';
    const canClaim = isReached && !isClaimed && (track === 'free' || data?.hasPremium);
    const isLocked = track === 'premium' && !data?.hasPremium;
    const isClaiming = claiming === `${level}-${track}`;
    const image = getRewardImage(reward);

    return (
      <div
        className={`bbp-reward-card ${isClaimed ? 'claimed' : ''} ${canClaim ? 'claimable' : ''} ${isLocked ? 'locked' : ''} ${!isReached ? 'unreached' : ''} ${compact ? 'compact' : ''}`}
        style={generateAccentVars('--reward-color', color) as React.CSSProperties}
        onClick={() => canClaim && handleClaim(level, track)}
      >
        {/* Image or icon area */}
        <div className="bbp-reward-visual">
          {image ? (
            <img src={image} alt={reward.label} className="bbp-reward-img" draggable={false} onError={(e) => { (e.target as HTMLImageElement).style.display = 'none'; (e.target as HTMLImageElement).nextElementSibling?.classList.remove('bbp-reward-icon-hidden'); }} />
          ) : null}
          <div className={`bbp-reward-icon-fallback ${image ? 'bbp-reward-icon-hidden' : ''}`} style={{ color, backgroundColor: `${color}18` }}>
            {REWARD_ICONS[reward.type] || <Gift size={18} />}
          </div>
          {/* Type badge */}
          <div className="bbp-reward-type-badge" style={{ backgroundColor: `${color}`, color: '#fff' }}>
            {REWARD_ICONS[reward.type]}
          </div>
        </div>

        {/* Label */}
        <div className="bbp-reward-info">
          <span className="bbp-reward-label">{reward.label}</span>
          {reward.amount && reward.amount > 1 && reward.type !== 'money' && reward.type !== 'coins' && (
            <span className="bbp-reward-amount">x{reward.amount}</span>
          )}
        </div>

        {/* Track + level indicator for compact cards */}
        {compact && (
          <div className="bbp-reward-compact-meta">
            <span className={`bbp-reward-compact-track ${track === 'premium' ? 'is-premium' : ''}`}>
              {track === 'premium' ? <Shield size={9} /> : <Gift size={9} />}
              {track === 'premium' ? 'Premium' : 'Gratuit'}
            </span>
            <span className="bbp-reward-compact-lvl">Niv. {level}</span>
          </div>
        )}

        {/* Status overlays */}
        {isClaimed && (
          <div className="bbp-reward-overlay claimed-overlay">
            <Check size={20} strokeWidth={3} />
          </div>
        )}
        {isLocked && !isClaimed && (
          <div className="bbp-reward-overlay locked-overlay">
            <Lock size={16} />
          </div>
        )}
        {!compact && canClaim && (
          <div className="bbp-reward-claim-glow" style={{ boxShadow: `0 0 16px 2px ${color}40` }}>
            <button className="bbp-reward-claim-btn" style={{ backgroundColor: color }}>
              {isClaiming ? '...' : 'Récupérer'}
            </button>
          </div>
        )}
      </div>
    );
  };

  if (loading) {
    return (
      <div className="bbp-loading">
        <Shield size={36} className="bbp-loading-icon" />
        <p>Chargement du Passe de Combat...</p>
      </div>
    );
  }

  if (!data) {
    return (
      <div className="bbp-loading">
        <Shield size={36} className="bbp-loading-icon" />
        <p>Le Passe de Combat n'est pas disponible</p>
      </div>
    );
  }

  const xpPercent = data.requiredXP > 0 ? Math.min((data.xp / data.requiredXP) * 100, 100) : 100;

  // Build level columns (1 to maxLevel)
  const allLevels: number[] = [];
  for (let i = 1; i <= data.maxLevel; i++) allLevels.push(i);

  // Map rewards by level
  const rewardMap = new Map<number, BPRewardLevel>();
  for (const r of data.rewards) {
    rewardMap.set(r.level, r);
  }

  const formatTimeLeft = (seconds: number) => {
    const d = Math.floor(seconds / 86400);
    const h = Math.floor((seconds % 86400) / 3600);
    if (d > 0) return `${d}j ${h}h`;
    const m = Math.floor((seconds % 3600) / 60);
    return `${h}h ${m}min`;
  };

  return (
    <div className="bbp-page">
      {/* Header bar */}
      <div className="bbp-header">
        <div className="bbp-header-left">
          <div className="bbp-season-icon">
            <Shield size={18} />
          </div>
          <div className="bbp-header-text">
            <h2>{data.season?.name || 'Passe de Combat'}</h2>
            <span className="bbp-header-sub">Niveau {data.level} / {data.maxLevel}</span>
          </div>
        </div>
        <div className="bbp-header-right">
          {data.hasPremium ? (
            <div className="bbp-premium-tag active">
              <Crown size={12} />
              Premium
            </div>
          ) : (
            <div className="bbp-premium-tag">
              <Lock size={12} />
              Premium non actif
            </div>
          )}
          {data.season && (
            <div className="bbp-timer-tag">
              <Clock size={12} />
              {formatTimeLeft(data.season.timeLeft)}
            </div>
          )}
        </div>
      </div>

      {/* Quick-claim section */}
      {pendingRewards.length > 0 && (
        <div className="bbp-quickclaim">
          <div className="bbp-quickclaim-header">
            <Gift size={14} />
            <span>Récompenses à récupérer ({pendingRewards.length})</span>
          </div>
          <div className="bbp-quickclaim-grid">
            {pendingRewards.map(({ level, track, reward }) => (
              <div key={`${level}-${track}`} className="bbp-quickclaim-item">
                {renderRewardCard(reward, level, track, true, false, true)}
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Reward Track */}
      <div className="bbp-track-wrapper">
        <button className="bbp-track-nav left" onClick={() => handleScroll('left')}>
          <ChevronLeft size={20} />
        </button>
        <button className="bbp-track-nav right" onClick={() => handleScroll('right')}>
          <ChevronRight size={20} />
        </button>

        {/* Track labels (Premium / Gratuit) */}
        <div className="bbp-track-labels">
          <div className="bbp-track-label premium">
            <Shield size={12} />
            Premium
          </div>
          <div className="bbp-track-label free">
            <Gift size={12} />
            Gratuit
          </div>
        </div>

        <div className="bbp-track" ref={trackRef}>
          <div className="bbp-track-inner">
            {allLevels.map(lvl => {
              const rw = rewardMap.get(lvl);
              const isReached = data.level >= lvl;
              const isCurrent = data.level === lvl;
              const isFreeClaimed = data.claimedFree.includes(lvl);
              const isPremiumClaimed = data.claimedPremium.includes(lvl);
              const hasFreeReward = rw && rw.free;
              const hasPremiumReward = rw && rw.premium;

              return (
                <div key={lvl} className={`bbp-track-col ${isReached ? 'reached' : ''} ${isCurrent ? 'current' : ''} ${!hasFreeReward && !hasPremiumReward ? 'empty-col' : ''}`}>
                  {/* Premium reward (top) */}
                  <div className="bbp-track-slot premium">
                    {renderRewardCard(rw?.premium || null, lvl, 'premium', isReached, isPremiumClaimed)}
                  </div>

                  {/* Level node */}
                  <div className="bbp-track-node">
                    <div className={`bbp-track-line-left ${isReached ? 'reached' : ''}`} />
                    <div
                      className={`bbp-track-dot ${isReached ? 'reached' : ''} ${isCurrent ? 'current' : ''}`}
                    >
                      {lvl}
                    </div>
                    <div className={`bbp-track-line-right ${isReached && data.level > lvl ? 'reached' : ''}`} />
                  </div>

                  {/* Free reward (bottom) */}
                  <div className="bbp-track-slot free">
                    {renderRewardCard(rw?.free || null, lvl, 'free', isReached, isFreeClaimed)}
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      </div>

      {/* XP Progress + Buy Level (bottom) */}
      <div className="bbp-xp-row">
        <div className="bbp-xp-bar-wrapper">
          <div className="bbp-xp-bar-info">
            <div className="bbp-xp-level-badge">
              <Star size={12} />
              {data.level}
            </div>
            <div className="bbp-xp-bar-track">
              <div className="bbp-xp-bar-fill" style={{ width: `${xpPercent}%` }} />
            </div>
            <div className="bbp-xp-level-badge next">
              {data.level < data.maxLevel ? data.level + 1 : <Star size={12} />}
            </div>
          </div>
          <div className="bbp-xp-text">
            {data.level < data.maxLevel
              ? <>{data.xp} <span>/ {data.requiredXP} XP</span></>
              : <span style={{ color: '#f59e0b' }}>Niveau MAX atteint</span>
            }
          </div>
        </div>
        {data.level < data.maxLevel && (
          <button
            className="bbp-buy-level-btn"
            onClick={handleBuyLevel}
            disabled={buyingLevel}
          >
            <ArrowUp size={16} />
            <div className="bbp-buy-level-text">
              <span className="bbp-buy-level-title">Passer un palier</span>
              <span className="bbp-buy-level-cost">
                {BUY_LEVEL_COST} Coins
              </span>
            </div>
          </button>
        )}
      </div>
    </div>
  );
};

export default BoutiqueBattlePass;
