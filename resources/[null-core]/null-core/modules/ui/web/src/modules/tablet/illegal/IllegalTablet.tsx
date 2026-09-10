import React, { useState, useEffect, useCallback, useRef, useMemo } from 'react';
import { generateAccentVars } from '@/utils/accentColors';
import {
  Home, Users, Shield, Target, Trophy, Map,
  ChevronRight, X, Star, Zap, Lock, Unlock,
  UserPlus, UserMinus, Check, Clock, Award,
  TrendingUp, Crown, Swords, Package, Percent,
  Palette, Activity, Crosshair, HeartHandshake, Heart,
  Flame, ArrowUpDown, DollarSign, Calendar, CalendarDays, CalendarRange,
  Search, FileText, Car, CarFront, ShoppingCart, Minus, Plus, AlertTriangle
} from 'lucide-react';
import { cacheImg } from '@shared/cacheVersion';
import { TabletData, TabletPage, TabletMission, TabletMember, TabletGrade, TabletPermissions, CreateGroupData, GangTier, BlackmarketItem } from './types';
import './IllegalTablet.css';

const GetParentResourceName = () => 'null-core';

const CATEGORY_COLORS: Record<string, string> = {
  territories: '#e74c3c',
  gofast: '#f39c12',
  laboratory: '#2ecc71',
  robbery: '#9b59b6',
  general: '#3498db',
};

const CATEGORY_LABELS: Record<string, string> = {
  territories: 'Territoires',
  gofast: 'Go-Fast',
  laboratory: 'Laboratoire',
  robbery: 'Braquage',
  general: 'Général',
};

const PERM_LABELS: Record<string, string> = {
  perms_coffre: 'Accès au coffre',
  perms_recruter: 'Recruter des membres',
  perms_promouvoir: 'Promouvoir / Rétrograder',
  perms_gestionmembre: 'Gestion des membres',
  perms_vente: "Vente d'armes",
  perms_fabrication: "Fabrication d'armes",
};

// ========== BLACKMARKET CARD SUB-COMPONENT ==========

interface BlackmarketCardProps {
  item: BlackmarketItem;
  type: 'weapon' | 'item';
  canBuy: boolean;
  discount: number;
  accentColor: string;
  onBuy: (quantity: number) => Promise<void>;
}

const BlackmarketCard: React.FC<BlackmarketCardProps> = ({ item, type, canBuy, discount, accentColor, onBuy }) => {
  const [quantity, setQuantity] = useState(1);
  const [buying, setBuying] = useState(false);

  const totalPrice = item.price * quantity;
  const iconUrl = type === 'weapon'
    ? cacheImg(`items/${item.name.toLowerCase()}.webp`)
    : cacheImg(`items/${item.name}.webp`);

  const handleBuy = async () => {
    if (!canBuy || buying) return;
    setBuying(true);
    try {
      await onBuy(quantity);
    } finally {
      setTimeout(() => setBuying(false), 2000);
    }
  };

  return (
    <div className="tablet-bm-card">
      <div className="tablet-bm-card-icon">
        <img
          src={iconUrl}
          alt={item.label}
          onError={(e) => { (e.target as HTMLImageElement).style.display = 'none'; }}
        />
        {type === 'weapon' ? <Swords size={20} className="tablet-bm-card-fallback-icon" /> : <Package size={20} className="tablet-bm-card-fallback-icon" />}
      </div>
      <div className="tablet-bm-card-info">
        <span className="tablet-bm-card-label">{item.label}</span>
        <div className="tablet-bm-card-prices">
          {discount > 0 && (
            <span className="tablet-bm-card-base-price">${item.basePrice.toLocaleString()}</span>
          )}
          <span className="tablet-bm-card-price" style={{ color: accentColor }}>${item.price.toLocaleString()}</span>
        </div>
      </div>
      <div className="tablet-bm-card-actions">
        <div className="tablet-bm-card-qty">
          <button
            className="tablet-bm-qty-btn"
            onClick={() => setQuantity(Math.max(1, quantity - 1))}
            disabled={quantity <= 1}
          >
            <Minus size={12} />
          </button>
          <span className="tablet-bm-qty-value">{quantity}</span>
          <button
            className="tablet-bm-qty-btn"
            onClick={() => setQuantity(Math.min(10, quantity + 1))}
            disabled={quantity >= 10}
          >
            <Plus size={12} />
          </button>
        </div>
        <button
          className={`tablet-bm-buy-btn ${buying ? 'buying' : ''}`}
          style={{ backgroundColor: canBuy ? accentColor : '#555' }}
          disabled={!canBuy || buying}
          onClick={handleBuy}
        >
          {buying ? (
            <><Clock size={14} /> Envoi...</>
          ) : (
            <><ShoppingCart size={14} /> ${totalPrice.toLocaleString()}</>
          )}
        </button>
      </div>
    </div>
  );
};

interface IllegalTabletProps {
  visible: boolean;
  onClose: () => void;
  primaryColor: string;
}

const IllegalTablet: React.FC<IllegalTabletProps> = ({ visible, onClose, primaryColor }) => {
  const [currentPage, setCurrentPage] = useState<TabletPage>('home');
  const [data, setData] = useState<TabletData | null>(null);
  const [hiding, setHiding] = useState(false);
  const [pageTransition, setPageTransition] = useState(false);
  const [notification, setNotification] = useState<{ message: string; type: 'success' | 'error' } | null>(null);
  const [selectedMember, setSelectedMember] = useState<TabletMember | null>(null);
  const [selectedGrade, setSelectedGrade] = useState<TabletGrade | null>(null);
  const [addGradeMode, setAddGradeMode] = useState(false);
  const [newGradeLabel, setNewGradeLabel] = useState('');
  const [showColorPicker, setShowColorPicker] = useState(false);
  const [createGroupData, setCreateGroupData] = useState<CreateGroupData | null>(null);
  const [cgName, setCgName] = useState('');
  const [cgLabel, setCgLabel] = useState('');
  const [cgLoading, setCgLoading] = useState(false);
  const [cgNameError, setCgNameError] = useState<string | null>(null);
  const [cgLabelError, setCgLabelError] = useState<string | null>(null);
  const [cgValidating, setCgValidating] = useState(false);
  const cgValidateTimer = useRef<ReturnType<typeof setTimeout> | null>(null);
  const pageTransitionRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  const accentColor = data?.gangcolor || '#e74c3c';
  const tabletAccentVars = useMemo(() => generateAccentVars('--tablet-accent', accentColor), [accentColor]);
  const tabletCreateVars = useMemo(() => generateAccentVars('--tablet-accent', '#e74c3c'), []);

  const PRESET_COLORS = [
    '#e74c3c', '#e91e63', '#9b59b6', '#8b5cf6', '#3498db',
    '#00bcd4', '#2ecc71', '#4caf50', '#f39c12', '#ff9800',
    '#ff5722', '#795548', '#607d8b', '#f1c40f', '#1abc9c',
  ];

  useEffect(() => {
    const handleMessage = (event: MessageEvent) => {
      const { action, data: msgData } = event.data;
      if (action === 'illegalTablet:open' && msgData) {
        if (msgData.mode === 'createGroup') {
          setCreateGroupData(msgData as CreateGroupData);
          setData(null);
          setCgName('');
          setCgLabel('');
          setCgLoading(false);
        } else {
          setCreateGroupData(null);
          setData(msgData);
          setCurrentPage('home');
          setSelectedMember(null);
          setSelectedGrade(null);
        }
      }
    };
    window.addEventListener('message', handleMessage);
    return () => window.removeEventListener('message', handleMessage);
  }, []);

  // Debounced real-time validation for group creation
  useEffect(() => {
    if (!createGroupData) return;
    if (cgValidateTimer.current) clearTimeout(cgValidateTimer.current);
    if (cgName.length === 0 && cgLabel.length === 0) {
      setCgNameError(null);
      setCgLabelError(null);
      setCgValidating(false);
      return;
    }
    setCgValidating(true);
    cgValidateTimer.current = setTimeout(async () => {
      try {
        const resp = await fetch(`https://${GetParentResourceName()}/illegalTablet:validateGroup`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ groupName: cgName, groupLabel: cgLabel }),
        });
        const result = await resp.json();
        setCgNameError(result.nameError || null);
        setCgLabelError(result.labelError || null);
      } catch (e) {
        // ignore
      }
      setCgValidating(false);
    }, 500);
    return () => { if (cgValidateTimer.current) clearTimeout(cgValidateTimer.current); };
  }, [cgName, cgLabel, createGroupData]);

  const showNotification = useCallback((message: string, type: 'success' | 'error') => {
    setNotification({ message, type });
    setTimeout(() => setNotification(null), 3000);
  }, []);

  const refreshData = useCallback(async () => {
    try {
      const resp = await fetch(`https://${GetParentResourceName()}/illegalTablet:refresh`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({}),
      });
      const result = await resp.json();
      if (result) setData(result);
    } catch (e) {
      console.error('[IllegalTablet] refresh error:', e);
    }
  }, []);

  const handleClose = useCallback(() => {
    setHiding(true);
    setTimeout(() => {
      setHiding(false);
      onClose();
      fetch(`https://${GetParentResourceName()}/illegalTablet:close`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({}),
      });
    }, 300);
  }, [onClose]);

  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape' && visible) {
        handleClose();
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [visible, handleClose]);

  const handlePageChange = (page: TabletPage) => {
    if (page === currentPage) return;
    if (pageTransitionRef.current) {
      clearTimeout(pageTransitionRef.current);
    }
    setPageTransition(true);
    pageTransitionRef.current = setTimeout(() => {
      setCurrentPage(page);
      setSelectedMember(null);
      setSelectedGrade(null);
      setAddGradeMode(false);
      requestAnimationFrame(() => {
        requestAnimationFrame(() => setPageTransition(false));
      });
    }, 120);
  };

  const nuiCallback = async (endpoint: string, body: any) => {
    try {
      const resp = await fetch(`https://${GetParentResourceName()}/${endpoint}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(body),
      });
      const result = await resp.json();
      if (result && typeof result === 'object' && result.gangname) {
        setData(result);
      }
      return result;
    } catch (e) {
      console.error(`[IllegalTablet] ${endpoint} error:`, e);
      return null;
    }
  };

  // ========== RENDER HELPERS ==========

  const xpPercent = data ? (data.requiredXP > 0 ? Math.min((data.xp / data.requiredXP) * 100, 100) : 100) : 0;

  const renderHome = () => {
    if (!data) return null;
    const nextUnlock = data.nextUnlocks?.[0];
    return (
      <div className="tablet-home">
        <div className="tablet-home-header">
          <div className="tablet-home-gang-icon" style={{ background: `linear-gradient(135deg, ${accentColor}, ${accentColor}88)` }}>
            <Crown size={32} />
          </div>
          <div className="tablet-home-gang-info">
            <h2>{data.ganglabel}</h2>
            <span className="tablet-home-gang-name">@{data.gangname}</span>
          </div>
          <div className="tablet-home-level-badge" style={{ borderColor: accentColor }}>
            <span className="tablet-home-level-number">{data.level}</span>
            <span className="tablet-home-level-label">Niveau</span>
          </div>
        </div>

        {data.gangTiers && data.tier && (() => {
          const ti = data.gangTiers[data.tier - 1];
          return ti ? (
            <div className="tablet-home-tier-section">
              <div className="tablet-home-tier-badge" style={{ borderColor: ti.color }}>
                <Crown size={16} style={{ color: ti.color }} />
                <div className="tablet-home-tier-info">
                  <span className="tablet-home-tier-name" style={{ color: ti.color }}>{ti.name}</span>
                  <span className="tablet-home-tier-spec">Spécialisation : {ti.specialization}</span>
                </div>
              </div>
              <p className="tablet-home-tier-desc">{ti.description}</p>
            </div>
          ) : null;
        })()}

        <div className="tablet-home-xp-section">
          <div className="tablet-home-xp-header">
            <span><Zap size={14} /> Expérience</span>
            <span>{data.xp.toLocaleString()} / {data.requiredXP.toLocaleString()} XP</span>
          </div>
          <div className="tablet-home-xp-bar">
            <div className="tablet-home-xp-fill" style={{ width: `${xpPercent}%`, background: `linear-gradient(90deg, ${accentColor}, ${accentColor}cc)` }} />
          </div>
          {data.level >= data.maxLevel && (
            <span className="tablet-home-max-level">Niveau Maximum Atteint !</span>
          )}
        </div>

        <div className="tablet-home-stats">
          <div className="tablet-home-stat">
            <Users size={18} />
            <div>
              <span className="tablet-home-stat-value">{data.memberCount} / {data.maxMembers}</span>
              <span className="tablet-home-stat-label">Membres</span>
            </div>
          </div>
          <div className="tablet-home-stat">
            <Shield size={18} />
            <div>
              <span className="tablet-home-stat-value">{data.grades.length} / {data.maxRanks}</span>
              <span className="tablet-home-stat-label">Rangs</span>
            </div>
          </div>
          <div className="tablet-home-stat">
            <Map size={18} />
            <div>
              <span className="tablet-home-stat-value">{data.ownedTerritories}</span>
              <span className="tablet-home-stat-label">Territoires</span>
            </div>
          </div>
          <div className="tablet-home-stat">
            <Percent size={18} />
            <div>
              <span className="tablet-home-stat-value">{data.blackmarketDiscount}%</span>
              <span className="tablet-home-stat-label">Réduction</span>
            </div>
          </div>
        </div>

        <div className="tablet-home-description">
          <p>
            Bienvenue sur la tablette de votre organisation. Gérez vos membres, rangs, 
            missions et territoires depuis cette interface. Complétez des missions pour 
            gagner de l'XP et monter en niveau pour débloquer de nouveaux avantages.
          </p>
        </div>

        <div className="tablet-home-group-stats">
          <h3><Activity size={14} /> Réputation du groupe</h3>
          <div className="tablet-home-group-stats-grid">
            {[
              { key: 'criminalité', label: 'Criminalité', icon: <Crosshair size={14} /> },
              { key: 'confiance', label: 'Confiance', icon: <HeartHandshake size={14} /> },
              { key: 'honneur', label: 'Honneur', icon: <Swords size={14} /> },
              { key: 'morale', label: 'Morale', icon: <Heart size={14} /> },
            ].map(stat => {
              const value = data.groupStats?.[stat.key as keyof typeof data.groupStats] ?? 0;
              return (
                <div key={stat.key} className="tablet-home-group-stat-item">
                  <div className="tablet-home-group-stat-header">
                    <span className="tablet-home-group-stat-icon">{stat.icon}</span>
                    <span className="tablet-home-group-stat-label">{stat.label}</span>
                    <span className="tablet-home-group-stat-value">{Math.round(value)}%</span>
                  </div>
                  <div className="tablet-home-group-stat-bar">
                    <div
                      className="tablet-home-group-stat-fill"
                      style={{ width: `${value}%` }}
                    />
                  </div>
                </div>
              );
            })}
          </div>
        </div>

        {/* <div className="tablet-home-dirty-money">
          <h3><DollarSign size={14} /> Argent sale généré</h3>
          <div className="tablet-home-dirty-money-grid">
            {[
              { key: 'today', label: "Aujourd'hui", icon: <Calendar size={14} /> },
              { key: 'week', label: 'Cette semaine', icon: <CalendarDays size={14} /> },
              { key: 'month', label: 'Ce mois', icon: <CalendarRange size={14} /> },
              { key: 'total', label: 'Total', icon: <DollarSign size={14} /> },
            ].map(item => {
              const value = data.dirtyMoney?.[item.key as keyof typeof data.dirtyMoney] ?? 0;
              return (
                <div key={item.key} className="tablet-home-dirty-money-item">
                  <div className="tablet-home-dirty-money-icon">
                    {item.icon}
                  </div>
                  <div className="tablet-home-dirty-money-info">
                    <span className="tablet-home-dirty-money-label">{item.label}</span>
                    <span className="tablet-home-dirty-money-value">${value.toLocaleString()}</span>
                  </div>
                </div>
              );
            })}
          </div>
        </div> */}

        <div className="tablet-home-unlocks">
          <h3><Lock size={14} /> Avantages débloqués</h3>
          <div className="tablet-home-unlock-list">
            {data.hasWeaponSell && (
              <div className="tablet-home-unlock-item unlocked">
                <Swords size={14} />
                <span>Vente d'armes</span>
              </div>
            )}
            {data.hasWeaponCraft && (
              <div className="tablet-home-unlock-item unlocked">
                <Package size={14} />
                <span>Fabrication d'armes</span>
              </div>
            )}
            {data.blackmarketDiscount > 0 && (
              <div className="tablet-home-unlock-item unlocked">
                <Percent size={14} />
                <span>{data.blackmarketDiscount}% réduction BlackMarket</span>
              </div>
            )}
            {data.unlocks?.dealwp_tier && Number(data.unlocks.dealwp_tier) >= 2 && (
              <div className="tablet-home-unlock-item unlocked">
                <DollarSign size={14} />
                <span>DealWP Tier {Number(data.unlocks.dealwp_tier)} — {Number(data.unlocks.dealwp_tier) >= 3 ? 'quantités 8-30, +5% prix' : 'quantités 3-15'}</span>
              </div>
            )}
            {data.unlocks?.territory_tier && Number(data.unlocks.territory_tier) >= 2 && (
              <div className="tablet-home-unlock-item unlocked">
                <Map size={14} />
                <span>Territoires Tier {Number(data.unlocks.territory_tier)} — {Number(data.unlocks.territory_tier) >= 3 ? '+6 unités, +20% prix' : '+3 unités, +10% prix'}</span>
              </div>
            )}
          </div>
          {nextUnlock && (
            <div className="tablet-home-next-unlock">
              <Lock size={14} />
              <span>Prochain : <strong>{nextUnlock.description}</strong> (Niv. {nextUnlock.level})</span>
            </div>
          )}
        </div>

        {data.isBoss && (
          <div className="tablet-home-color-section">
            <div className="tablet-home-color-header" onClick={() => setShowColorPicker(!showColorPicker)}>
              <Palette size={16} style={{ color: accentColor }} />
              <span>Couleur du groupe</span>
              <div className="tablet-home-color-preview" style={{ backgroundColor: accentColor }} />
              <ChevronRight size={14} className={`tablet-home-color-arrow ${showColorPicker ? 'open' : ''}`} />
            </div>
            {showColorPicker && (
              <div className="tablet-home-color-picker">
                <div className="tablet-home-color-presets">
                  {PRESET_COLORS.map(color => (
                    <button
                      key={color}
                      className={`tablet-home-color-swatch ${accentColor === color ? 'active' : ''}`}
                      style={{ backgroundColor: color }}
                      onClick={async () => {
                        await nuiCallback('illegalTablet:changeColor', { color });
                        showNotification('Couleur du groupe modifiée', 'success');
                      }}
                    />
                  ))}
                </div>
                <div className="tablet-home-color-custom">
                  <input
                    type="color"
                    value={accentColor}
                    onChange={async (e) => {
                      const color = e.target.value;
                      await nuiCallback('illegalTablet:changeColor', { color });
                    }}
                  />
                  <span>Couleur personnalisée</span>
                </div>
              </div>
            )}
          </div>
        )}
      </div>
    );
  };

  const renderMembers = () => {
    if (!data) return null;
    const sortedMembers = [...data.members].sort((a, b) => {
      if (a.online !== b.online) return a.online ? -1 : 1;
      return b.grade - a.grade;
    });

    const canManage = data.isBoss || (data.permissions.perms_gestionmembre[String(data.playerGrade)] === true);

    if (selectedMember) {
      return (
        <div className="tablet-member-detail">
          <button className="tablet-back-btn" onClick={() => setSelectedMember(null)}>
            ← Retour
          </button>
          <div className="tablet-member-detail-header">
            <div className="tablet-member-avatar" style={{ borderColor: selectedMember.online ? '#2ecc71' : '#555' }}>
              {selectedMember.firstname[0]}{selectedMember.lastname[0]}
            </div>
            <div>
              <h3>{selectedMember.firstname} {selectedMember.lastname}</h3>
              <span className="tablet-member-grade-label">{selectedMember.gradeLabel}</span>
              <span className={`tablet-member-status ${selectedMember.online ? 'online' : 'offline'}`}>
                {selectedMember.online ? '● En ligne' : '○ Hors ligne'}
              </span>
            </div>
          </div>
          {canManage && (
            <div className="tablet-member-actions">
              <h4>Changer le grade</h4>
              <div className="tablet-member-grade-list">
                {data.grades.filter(g => g.name !== 'boss').map(g => (
                  <button
                    key={g.grade}
                    className={`tablet-grade-btn ${g.grade === selectedMember.grade ? 'active' : ''}`}
                    onClick={async () => {
                      await nuiCallback('illegalTablet:changeMemberGrade', {
                        idunique: selectedMember.idunique,
                        newGrade: g.grade,
                      });
                      showNotification(`Grade changé en ${g.label}`, 'success');
                      setSelectedMember(null);
                    }}
                  >
                    {g.label}
                    {g.grade === selectedMember.grade && <Check size={14} />}
                  </button>
                ))}
              </div>
              <button
                className="tablet-kick-btn"
                onClick={async () => {
                  await nuiCallback('illegalTablet:kickMember', { idunique: selectedMember.idunique });
                  showNotification(`${selectedMember.firstname} ${selectedMember.lastname} a été exclu`, 'success');
                  setSelectedMember(null);
                }}
              >
                <UserMinus size={16} />
                Exclure du groupe
              </button>
            </div>
          )}
        </div>
      );
    }

    return (
      <div className="tablet-members">
        <div className="tablet-section-header">
          <div className="tablet-section-header-icon" style={{ backgroundColor: `${accentColor}15`, color: accentColor }}>
            <Users size={20} />
          </div>
          <div>
            <h2>Membres</h2>
            <p>{data.memberCount} / {data.maxMembers} membres</p>
          </div>
        </div>

        {canManage && (
          <div className="tablet-members-quick-actions">
            <h3>Actions rapides</h3>
            <div className="tablet-members-quick-actions-grid">
              <button
                className="tablet-quick-action-btn recruit"
                onClick={async () => {
                  await nuiCallback('illegalTablet:recruitNearest', {});
                  showNotification('Recrutement du joueur le plus proche...', 'success');
                }}
              >
                <UserPlus size={16} />
                <span>Recruter le plus proche</span>
              </button>
              <button
                className="tablet-quick-action-btn fire"
                onClick={async () => {
                  await nuiCallback('illegalTablet:fireNearest', {});
                  showNotification('Renvoi du joueur le plus proche...', 'success');
                }}
              >
                <UserMinus size={16} />
                <span>Virer le plus proche</span>
              </button>
              <button
                className="tablet-quick-action-btn promote"
                onClick={async () => {
                  await nuiCallback('illegalTablet:promoteNearest', {});
                  showNotification('Promotion du joueur le plus proche...', 'success');
                }}
              >
                <ArrowUpDown size={16} />
                <span>Promouvoir le plus proche</span>
              </button>
              <button
                className="tablet-quick-action-btn demote"
                onClick={async () => {
                  await nuiCallback('illegalTablet:demoteNearest', {});
                  showNotification('Rétrogradation du joueur le plus proche...', 'success');
                }}
              >
                <ArrowUpDown size={16} />
                <span>Rétrograder le plus proche</span>
              </button>
            </div>
          </div>
        )}

        <div className="tablet-members-list">
          {sortedMembers.map(member => (
            <div
              key={member.idunique}
              className={`tablet-member-item ${canManage ? 'clickable' : ''}`}
              onClick={() => canManage && setSelectedMember(member)}
            >
              <div className="tablet-member-avatar-small" style={{ borderColor: member.online ? '#2ecc71' : '#555' }}>
                {member.firstname[0]}{member.lastname[0]}
              </div>
              <div className="tablet-member-info">
                <span className="tablet-member-name">{member.firstname} {member.lastname}</span>
                <span className="tablet-member-grade">{member.gradeLabel}</span>
              </div>
              <span className={`tablet-member-dot ${member.online ? 'online' : 'offline'}`} />
              {canManage && <ChevronRight size={14} className="tablet-member-arrow" />}
            </div>
          ))}
        </div>
      </div>
    );
  };

  const renderRanks = () => {
    if (!data) return null;

    if (selectedGrade) {
      const permKeys = Object.keys(PERM_LABELS) as (keyof TabletPermissions)[];
      const filteredPerms = permKeys.filter(pk => {
        if (pk === 'perms_vente' && !data.hasWeaponSell) return false;
        if (pk === 'perms_fabrication' && !data.hasWeaponCraft) return false;
        return true;
      });

      return (
        <div className="tablet-rank-detail">
          <button className="tablet-back-btn" onClick={() => setSelectedGrade(null)}>
            ← Retour
          </button>
          <div className="tablet-rank-detail-header">
            <Shield size={24} style={{ color: accentColor }} />
            <h3>{selectedGrade.label}</h3>
            {selectedGrade.name === 'boss' && <Crown size={16} style={{ color: '#f1c40f' }} />}
          </div>
          {selectedGrade.name !== 'boss' && data.isBoss && (
            <>
              <h4>Permissions</h4>
              <div className="tablet-perms-list">
                {filteredPerms.map(permKey => {
                  const gradeKey = String(selectedGrade.grade);
                  const isEnabled = data.permissions[permKey]?.[gradeKey] === true;
                  return (
                    <div
                      key={permKey}
                      className={`tablet-perm-item ${isEnabled ? 'enabled' : ''}`}
                      onClick={async () => {
                        const newVal = !isEnabled;
                        await nuiCallback('illegalTablet:changePerms', {
                          permType: permKey,
                          gradeKey: gradeKey,
                          value: newVal,
                        });
                        setData(prev => {
                          if (!prev) return prev;
                          const newPerms = { ...prev.permissions };
                          newPerms[permKey] = { ...newPerms[permKey], [gradeKey]: newVal };
                          return { ...prev, permissions: newPerms };
                        });
                      }}
                    >
                      <div className={`tablet-perm-toggle ${isEnabled ? 'on' : 'off'}`}>
                        <div className="tablet-perm-toggle-dot" />
                      </div>
                      <span>{PERM_LABELS[permKey]}</span>
                    </div>
                  );
                })}
              </div>
              <button
                className="tablet-delete-grade-btn"
                onClick={async () => {
                  await nuiCallback('illegalTablet:removeGrade', {
                    gradeName: selectedGrade.name,
                    gradePos: selectedGrade.grade,
                  });
                  showNotification(`Grade "${selectedGrade.label}" supprimé`, 'success');
                  setSelectedGrade(null);
                }}
              >
                Supprimer ce rang
              </button>
            </>
          )}
          {selectedGrade.name === 'boss' && (
            <p className="tablet-rank-boss-note">Le grade Boss possède toutes les permissions et ne peut pas être modifié.</p>
          )}
        </div>
      );
    }

    return (
      <div className="tablet-ranks">
        <div className="tablet-section-header">
          <div className="tablet-section-header-icon" style={{ backgroundColor: `${accentColor}15`, color: accentColor }}>
            <Shield size={20} />
          </div>
          <div>
            <h2>Rangs</h2>
            <p>{data.grades.length} / {data.maxRanks} rangs</p>
          </div>
        </div>
        <div className="tablet-ranks-list">
          {data.grades.map(grade => (
            <div
              key={grade.grade}
              className={`tablet-rank-item ${data.isBoss ? 'clickable' : ''}`}
              onClick={() => data.isBoss && setSelectedGrade(grade)}
            >
              <Shield size={16} style={{ color: grade.name === 'boss' ? '#f1c40f' : accentColor }} />
              <div className="tablet-rank-info">
                <span className="tablet-rank-label">{grade.label}</span>
                {grade.name === 'boss' && <Crown size={12} style={{ color: '#f1c40f' }} />}
              </div>
              {data.isBoss && <ChevronRight size={14} className="tablet-rank-arrow" />}
            </div>
          ))}
        </div>
        {data.isBoss && (
          <div className="tablet-add-grade-section">
            {addGradeMode ? (
              <div className="tablet-add-grade-form">
                <input
                  type="text"
                  placeholder="Nom du nouveau rang..."
                  value={newGradeLabel}
                  onChange={e => setNewGradeLabel(e.target.value)}
                  maxLength={30}
                  autoFocus
                />
                <div className="tablet-add-grade-actions">
                  <button
                    className="tablet-add-grade-confirm"
                    onClick={async () => {
                      if (!newGradeLabel.trim()) return;
                      await nuiCallback('illegalTablet:addGrade', { label: newGradeLabel.trim() });
                      showNotification(`Rang "${newGradeLabel}" créé`, 'success');
                      setNewGradeLabel('');
                      setAddGradeMode(false);
                    }}
                  >
                    <Check size={16} /> Créer
                  </button>
                  <button className="tablet-add-grade-cancel" onClick={() => { setAddGradeMode(false); setNewGradeLabel(''); }}>
                    Annuler
                  </button>
                </div>
              </div>
            ) : (
              <button
                className="tablet-add-grade-btn"
                onClick={() => {
                  if (data.grades.length >= data.maxRanks) {
                    showNotification(`Nombre max de rangs atteint (${data.maxRanks})`, 'error');
                    return;
                  }
                  setAddGradeMode(true);
                }}
                style={{ borderColor: accentColor, color: accentColor }}
              >
                + Ajouter un rang
              </button>
            )}
          </div>
        )}
      </div>
    );
  };

  const renderMissionCard = (mission: TabletMission, type: 'daily' | 'weekly') => {
    const catColor = CATEGORY_COLORS[mission.category] || '#888';
    const progressPercent = mission.objective > 0 ? Math.min((mission.progress / mission.objective) * 100, 100) : 0;
    const isAccepted = mission.acceptedBy !== null;

    return (
      <div key={mission.id} className={`tablet-mission-card ${mission.completed ? 'completed' : ''} ${mission.claimed ? 'claimed' : ''}`}>
        <div className="tablet-mission-card-top">
          <span className="tablet-mission-category" style={{ backgroundColor: `${catColor}20`, color: catColor }}>
            {CATEGORY_LABELS[mission.category] || mission.category}
          </span>
          <span className="tablet-mission-xp">
            <Zap size={12} /> +{mission.xp} XP
          </span>
        </div>
        <h4 className="tablet-mission-label">{mission.label}</h4>
        <p className="tablet-mission-desc">{mission.description}</p>
        <div className="tablet-mission-progress-section">
          <div className="tablet-mission-progress-bar">
            <div
              className="tablet-mission-progress-fill"
              style={{ width: `${progressPercent}%`, backgroundColor: mission.completed ? '#2ecc71' : catColor }}
            />
          </div>
          <span className="tablet-mission-progress-text">
            {mission.progress.toLocaleString()} / {mission.objective.toLocaleString()}
          </span>
        </div>
        <div className="tablet-mission-card-bottom">
          {mission.claimed ? (
            <span className="tablet-mission-claimed-badge"><Check size={14} /> Réclamé</span>
          ) : mission.completed ? (
            <button
              className="tablet-mission-claim-btn"
              onClick={() => nuiCallback('illegalTablet:claimMission', { missionId: mission.id, missionType: type })}
            >
              <Award size={14} /> Réclamer {mission.xp} XP
            </button>
          ) : isAccepted ? (
            <span className="tablet-mission-accepted-badge"><Clock size={14} /> En cours</span>
          ) : (
            <button
              className="tablet-mission-accept-btn"
              style={{ borderColor: catColor, color: catColor }}
              onClick={() => nuiCallback('illegalTablet:acceptMission', { missionId: mission.id, missionType: type })}
            >
              Accepter
            </button>
          )}
        </div>
      </div>
    );
  };

  const renderMissions = () => {
    if (!data) return null;
    return (
      <div className="tablet-missions">
        <div className="tablet-section-header">
          <div className="tablet-section-header-icon" style={{ backgroundColor: `${accentColor}15`, color: accentColor }}>
            <Target size={20} />
          </div>
          <div>
            <h2>Missions</h2>
            <p>Complétez des missions pour gagner de l'XP</p>
          </div>
        </div>

        <div className="tablet-missions-section">
          <h3 className="tablet-missions-type-title">
            <Clock size={16} /> Missions Quotidiennes
          </h3>
          <div className="tablet-missions-grid">
            {data.missions.daily.map(m => renderMissionCard(m, 'daily'))}
          </div>
        </div>

        <div className="tablet-missions-section">
          <h3 className="tablet-missions-type-title">
            <Star size={16} /> Missions Hebdomadaires
          </h3>
          <div className="tablet-missions-grid">
            {data.missions.weekly.map(m => renderMissionCard(m, 'weekly'))}
          </div>
        </div>
      </div>
    );
  };

  const renderRanking = () => {
    if (!data) return null;
    return (
      <div className="tablet-ranking">
        <div className="tablet-section-header">
          <div className="tablet-section-header-icon" style={{ backgroundColor: `${accentColor}15`, color: accentColor }}>
            <Trophy size={20} />
          </div>
          <div>
            <h2>Classement</h2>
            <p>Classement des groupes illégaux</p>
          </div>
        </div>
        <div className="tablet-ranking-list">
          {data.ranking.map((entry, index) => {
            const isOwn = entry.name === data.gangname;
            const medalColor = index === 0 ? '#f1c40f' : index === 1 ? '#bdc3c7' : index === 2 ? '#cd7f32' : undefined;
            return (
              <div key={entry.name} className={`tablet-ranking-item ${isOwn ? 'own' : ''}`}>
                <div className="tablet-ranking-position" style={medalColor ? { color: medalColor } : {}}>
                  {index < 3 ? <Trophy size={18} /> : <span>#{index + 1}</span>}
                </div>
                <div className="tablet-ranking-info">
                  <span className="tablet-ranking-name">{entry.label}</span>
                  <div className="tablet-ranking-details">
                    <span><TrendingUp size={12} /> Niv. {entry.level}</span>
                    <span><Users size={12} /> {entry.memberCount}</span>
                    <span><Map size={12} /> {entry.totalTerritoriesWon} terr.</span>
                  </div>
                </div>
                <div className="tablet-ranking-level">
                  <span className="tablet-ranking-level-number">{entry.level}</span>
                </div>
              </div>
            );
          })}
        </div>
      </div>
    );
  };

  const renderTerritories = () => {
    if (!data) return null;
    const territories = Object.values(data.territories).filter(t => t.active);

    return (
      <div className="tablet-territories">
        <div className="tablet-section-header">
          <div className="tablet-section-header-icon" style={{ backgroundColor: `${accentColor}15`, color: accentColor }}>
            <Map size={20} />
          </div>
          <div>
            <h2>Territoires</h2>
            <p>{data.ownedTerritories} territoire{data.ownedTerritories > 1 ? 's' : ''} contrôlé{data.ownedTerritories > 1 ? 's' : ''}</p>
          </div>
        </div>
        <div className="tablet-territories-list">
          {territories.map(territory => {
            const isOwned = territory.owner === data.gangname;
            const myPoints = territory.data?.[data.gangname]?.count || 0;
            const ownerPoints = territory.ownerCount || 0;
            const progressPercent = ownerPoints > 0 ? Math.min((myPoints / ownerPoints) * 100, 100) : (myPoints > 0 ? 100 : 0);

            return (
              <div key={territory.id} className={`tablet-territory-card ${isOwned ? 'owned' : ''}`}>
                <div className="tablet-territory-header">
                  <Map size={16} style={{ color: isOwned ? '#2ecc71' : '#e74c3c' }} />
                  <span className="tablet-territory-name">{territory.name}</span>
                  {isOwned && <span className="tablet-territory-owned-badge">✓ Contrôlé</span>}
                </div>
                <div className="tablet-territory-info">
                  <div className="tablet-territory-row">
                    <span>Contrôlé par</span>
                    <span className="tablet-territory-value">
                      {territory.ownerLabel || 'Aucun'}
                    </span>
                  </div>
                  <div className="tablet-territory-row">
                    <span>Points du contrôleur</span>
                    <span className="tablet-territory-value">{ownerPoints}</span>
                  </div>
                  <div className="tablet-territory-row">
                    <span>Vos points</span>
                    <span className="tablet-territory-value" style={{ color: accentColor }}>{myPoints}</span>
                  </div>
                </div>
                {!isOwned && ownerPoints > 0 && (
                  <div className="tablet-territory-progress">
                    <div className="tablet-territory-progress-bar">
                      <div
                        className="tablet-territory-progress-fill"
                        style={{ width: `${progressPercent}%` }}
                      />
                    </div>
                    <span className="tablet-territory-progress-text">
                      {myPoints} / {ownerPoints} points
                    </span>
                  </div>
                )}
                {isOwned && (
                  <div className="tablet-territory-progress">
                    <div className="tablet-territory-progress-bar full">
                      <div className="tablet-territory-progress-fill owned" style={{ width: '100%' }} />
                    </div>
                    <span className="tablet-territory-progress-text owned-text">Territoire sécurisé</span>
                  </div>
                )}
              </div>
            );
          })}
          {territories.length === 0 && (
            <div className="tablet-empty">
              <Map size={48} />
              <p>Aucun territoire disponible</p>
            </div>
          )}
        </div>
      </div>
    );
  };

  const renderActions = () => {
    const actions = [
      {
        id: 'fouiller',
        label: 'Fouiller',
        description: 'Fouiller le joueur le plus proche (mains en l\'air)',
        icon: <Search size={18} />,
        callback: 'illegalTablet:fouiller',
      },
      ...(data.isBoss ? [{
        id: 'facture',
        label: 'Facture',
        description: 'Envoyer une facture au joueur le plus proche',
        icon: <FileText size={18} />,
        callback: 'illegalTablet:facture',
      }] : []),
      {
        id: 'putInVehicle',
        label: 'Mettre dans le véhicule',
        description: 'Mettre le joueur le plus proche dans votre véhicule (mains en l\'air)',
        icon: <Car size={18} />,
        callback: 'illegalTablet:putInVehicle',
      },
      {
        id: 'outVehicle',
        label: 'Sortir du véhicule',
        description: 'Sortir le joueur le plus proche du véhicule',
        icon: <CarFront size={18} />,
        callback: 'illegalTablet:outVehicle',
      },
     // {
      //  id: 'forceOpen',
      //  label: 'Ouvrir / fermer de force',
      //  description: 'Crocheter le véhicule le plus proche',
      //  icon: <Unlock size={18} />,
      //  callback: 'illegalTablet:forceOpen',
    //  },
    ];

    return (
      <div className="tablet-page">
        <div className="tablet-section-header">
          <div className="tablet-section-header-icon" style={{ backgroundColor: `${accentColor}15`, color: accentColor }}>
            <Zap size={20} />
          </div>
          <div>
            <h2>Actions</h2>
            <p>Actions rapides sur les joueurs et véhicules à proximité</p>
          </div>
        </div>
        <div className="tablet-actions-list">
          {actions.map(action => (
            <button
              key={action.id}
              className="tablet-action-item"
              onClick={async () => {
                await nuiCallback(action.callback, {});
              }}
            >
              <div className="tablet-action-icon">
                {action.icon}
              </div>
              <div className="tablet-action-info">
                <span className="tablet-action-label">{action.label}</span>
                <span className="tablet-action-desc">{action.description}</span>
              </div>
              <ChevronRight size={14} className="tablet-action-arrow" />
            </button>
          ))}
        </div>
      </div>
    );
  };

  const renderCreateGroup = () => {
    if (!createGroupData) return null;
    const tiers = createGroupData.gangTiers;
    const cfg = createGroupData.groupCreation;
    const tierInfo = tiers[0]; // Lua [1] becomes index 0 in JSON array — Petite frappe

    return (
      <div className="tablet-create-group">
        <div className="tablet-section-header">
          <div className="tablet-section-header-icon" style={{ backgroundColor: '#e74c3c15', color: '#e74c3c' }}>
            <Crown size={20} />
          </div>
          <div>
            <h2>Créer votre groupe</h2>
            <p>Fondez votre propre organisation criminelle</p>
          </div>
        </div>

        <div className="tablet-create-group-tier-preview">
          <div className="tablet-create-group-tier-badge" style={{ borderColor: tierInfo?.color || '#95a5a6' }}>
            <Crown size={18} style={{ color: tierInfo?.color || '#95a5a6' }} />
            <span style={{ color: tierInfo?.color || '#95a5a6' }}>{tierInfo?.name || 'Petite frappe'}</span>
          </div>
          <p className="tablet-create-group-tier-desc">{tierInfo?.description || ''}</p>
          <div className="tablet-create-group-tier-spec">
            <span>Spécialisation : <strong>{tierInfo?.specialization || 'Indéfini'}</strong></span>
          </div>
        </div>

        <div className="tablet-create-group-tiers-overview">
          <h3><TrendingUp size={14} /> Progression des titres</h3>
          <div className="tablet-create-group-tiers-list">
            {Object.entries(tiers).map(([key, tier]) => {
              const tierNum = Number(key) + 1;
              return (
                <div key={key} className={`tablet-create-group-tier-item ${tierNum === 1 ? 'current' : 'locked'}`}>
                  <div className="tablet-create-group-tier-dot" style={{ backgroundColor: tier.color }} />
                  <div className="tablet-create-group-tier-item-info">
                    <span className="tablet-create-group-tier-item-name" style={{ color: tierNum === 1 ? tier.color : '#666' }}>
                      Niv. {tierNum} — {tier.name}
                    </span>
                    <span className="tablet-create-group-tier-item-spec">{tier.specialization}</span>
                  </div>
                  {tierNum > 1 && <Lock size={12} style={{ color: '#555' }} />}
                </div>
              );
            })}
          </div>
        </div>

        <div className="tablet-create-group-form">
          <h3><FileText size={14} /> Informations du groupe</h3>
          <div className={`tablet-create-group-field ${cgNameError ? 'has-error' : cgName.length >= cfg.minNameLength && !cgValidating && !cgNameError ? 'has-success' : ''}`}>
            <label>Nom interne <span className="tablet-create-group-hint">(minuscules, chiffres, underscores)</span></label>
            <input
              type="text"
              value={cgName}
              onChange={e => setCgName(e.target.value.toLowerCase().replace(/[^a-z0-9_]/g, ''))}
              placeholder="mon_groupe"
              maxLength={cfg.maxNameLength}
              disabled={cgLoading}
            />
            <span className="tablet-create-group-counter">{cgName.length}/{cfg.maxNameLength}</span>
            {cgNameError && <span className="tablet-create-group-error">{cgNameError}</span>}
            {!cgNameError && cgName.length >= cfg.minNameLength && !cgValidating && (
              <span className="tablet-create-group-success"><Check size={12} /> Disponible</span>
            )}
          </div>
          <div className={`tablet-create-group-field ${cgLabelError ? 'has-error' : cgLabel.length >= cfg.minLabelLength && !cgValidating && !cgLabelError ? 'has-success' : ''}`}>
            <label>Nom affiché</label>
            <input
              type="text"
              value={cgLabel}
              onChange={e => setCgLabel(e.target.value)}
              placeholder="Mon Groupe"
              maxLength={cfg.maxLabelLength}
              disabled={cgLoading}
            />
            <span className="tablet-create-group-counter">{cgLabel.length}/{cfg.maxLabelLength}</span>
            {cgLabelError && <span className="tablet-create-group-error">{cgLabelError}</span>}
            {!cgLabelError && cgLabel.length >= cfg.minLabelLength && !cgValidating && (
              <span className="tablet-create-group-success"><Check size={12} /> Disponible</span>
            )}
          </div>

          {cfg.price > 0 && (
            <div className="tablet-create-group-price">
              <DollarSign size={14} />
              <span>Coût : <strong>${cfg.price.toLocaleString()}</strong> en argent sale</span>
            </div>
          )}

          <button
            className="tablet-create-group-submit"
            disabled={cgLoading || cgValidating || !!cgNameError || !!cgLabelError || cgName.length < cfg.minNameLength || cgLabel.length < cfg.minLabelLength}
            onClick={async () => {
              setCgLoading(true);
              await fetch(`https://${GetParentResourceName()}/illegalTablet:createGroup`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ groupName: cgName, groupLabel: cgLabel }),
              });
            }}
          >
            {cgLoading ? (
              <><Clock size={16} /> Création en cours...</>
            ) : cgValidating ? (
              <><Clock size={16} /> Vérification...</>
            ) : (
              <><Crown size={16} /> Fonder le groupe — ${cfg.price.toLocaleString()}</>
            )}
          </button>
        </div>
      </div>
    );
  };

  const renderBlackmarket = () => {
    if (!data) return null;
    const bm = data.blackmarket;

    if (!bm || !bm.unlocked) {
      return (
        <div className="tablet-blackmarket">
          <div className="tablet-section-header">
            <div className="tablet-section-header-icon" style={{ backgroundColor: `${accentColor}15`, color: accentColor }}>
              <ShoppingCart size={20} />
            </div>
            <div>
              <h2>BlackMarket</h2>
              <p>Marché noir d'armes et d'équipements</p>
            </div>
          </div>
          <div className="tablet-blackmarket-locked">
            <Lock size={48} />
            <h3>BlackMarket verrouillé</h3>
            <p>
              {!data.kitArme || (data.kitArme !== 1 && data.kitArme !== true)
                ? "Votre groupe n'a pas accès au kit d'armes."
                : "Montez en niveau pour débloquer l'accès au BlackMarket."}
            </p>
          </div>
        </div>
      );
    }

    const canBuy = data.permissions.perms_vente[String(data.playerGrade)] === true;

    return (
      <div className="tablet-blackmarket">
        <div className="tablet-section-header">
          <div className="tablet-section-header-icon" style={{ backgroundColor: `${accentColor}15`, color: accentColor }}>
            <ShoppingCart size={20} />
          </div>
          <div>
            <h2>BlackMarket</h2>
            <p>Marché noir — Paiement en argent sale</p>
          </div>
          {bm.discount > 0 && (
            <div className="tablet-blackmarket-discount-badge" style={{ backgroundColor: accentColor }}>
              <Percent size={12} />
              <span>-{bm.discount}%</span>
            </div>
          )}
        </div>

        {!canBuy && (
          <div className="tablet-blackmarket-warning">
            <AlertTriangle size={16} />
            <span>Vous n'avez pas la permission d'acheter. Contactez votre chef.</span>
          </div>
        )}

        {bm.weapons && bm.weapons.length > 0 && (
          <div className="tablet-blackmarket-section">
            <h3><Swords size={14} /> Armes</h3>
            <div className="tablet-blackmarket-grid">
              {bm.weapons.map(weapon => (
                <BlackmarketCard
                  key={weapon.id}
                  item={weapon}
                  type="weapon"
                  canBuy={canBuy}
                  discount={bm.discount || 0}
                  accentColor={accentColor}
                  onBuy={async (qty) => {
                    await nuiCallback('illegalTablet:buyWeapon', { weaponId: weapon.id, quantity: qty });
                    showNotification(`Achat de ${qty}x ${weapon.label} en cours...`, 'success');
                  }}
                />
              ))}
            </div>
          </div>
        )}

        {bm.items && bm.items.length > 0 && (
          <div className="tablet-blackmarket-section">
            <h3><Package size={14} /> Équipements</h3>
            <div className="tablet-blackmarket-grid">
              {bm.items.map(item => (
                <BlackmarketCard
                  key={item.id}
                  item={item}
                  type="item"
                  canBuy={canBuy}
                  discount={bm.discount || 0}
                  accentColor={accentColor}
                  onBuy={async (qty) => {
                    await nuiCallback('illegalTablet:buyItem', { itemId: item.id, quantity: qty });
                    showNotification(`Achat de ${qty}x ${item.label} en cours...`, 'success');
                  }}
                />
              ))}
            </div>
          </div>
        )}
      </div>
    );
  };

  const renderContent = () => {
    switch (currentPage) {
      case 'home': return renderHome();
      case 'members': return renderMembers();
      case 'ranks': return renderRanks();
      case 'missions': return renderMissions();
      case 'ranking': return renderRanking();
      case 'territories': return renderTerritories();
      case 'actions': return renderActions();
      case 'blackmarket': return renderBlackmarket();
      default: return null;
    }
  };

  if (!visible || (!data && !createGroupData)) return null;

  // ========== CREATE GROUP MODE (unemployed2 players) ==========
  if (createGroupData) {
    return (
      <div className={`tablet-overlay ${hiding ? 'tablet-hiding' : ''}`}>
        <div className="tablet-container tablet-container-single" style={tabletCreateVars as React.CSSProperties}>
          <div className="tablet-create-group-layout">
            <div className="tablet-create-group-sidebar">
              <div className="tablet-sidebar-header">
                <div className="tablet-sidebar-icon" style={{ background: 'linear-gradient(135deg, #e74c3c, #e74c3c88)' }}>
                  <Crown size={20} />
                </div>
                <div className="tablet-sidebar-title">
                  <h1>Organisation</h1>
                  <p>Création de groupe</p>
                </div>
              </div>
              <div className="tablet-sidebar-footer">
                <button className="tablet-close-btn" onClick={handleClose}>
                  <X size={16} />
                  <span>Fermer</span>
                </button>
              </div>
            </div>
            <div className="tablet-content">
              {renderCreateGroup()}
            </div>
          </div>

          {notification && (
            <div className={`tablet-notification ${notification.type}`}>
              {notification.type === 'success' ? <Check size={16} /> : <X size={16} />}
              <span>{notification.message}</span>
            </div>
          )}
        </div>
      </div>
    );
  }

  // ========== NORMAL GANG MODE ==========
  if (!data) return null;

  const canManageMembers = data.isBoss
    || data.permissions.perms_gestionmembre[String(data.playerGrade)] === true
    || data.permissions.perms_recruter[String(data.playerGrade)] === true
    || data.permissions.perms_promouvoir[String(data.playerGrade)] === true;

  const sidebarItems: { id: TabletPage; label: string; icon: React.ReactNode }[] = [
    { id: 'home', label: 'Accueil', icon: <Home size={18} /> },
    ...(canManageMembers ? [{ id: 'members' as TabletPage, label: 'Membres', icon: <Users size={18} /> }] : []),
    ...(data.isBoss ? [{ id: 'ranks' as TabletPage, label: 'Rangs', icon: <Shield size={18} /> }] : []),
    { id: 'missions', label: 'Missions', icon: <Target size={18} /> },
    { id: 'ranking', label: 'Classement', icon: <Trophy size={18} /> },
    { id: 'territories', label: 'Territoires', icon: <Map size={18} /> },
    { id: 'actions', label: 'Actions', icon: <Zap size={18} /> },
    ...(data.blackmarket ? [{ id: 'blackmarket' as TabletPage, label: 'BlackMarket', icon: <ShoppingCart size={18} /> }] : []),
  ];

  return (
    <div className={`tablet-overlay ${hiding ? 'tablet-hiding' : ''}`}>
      <div className="tablet-container" style={tabletAccentVars as React.CSSProperties}>
        {/* Sidebar */}
        <div className="tablet-sidebar">
          <div className="tablet-sidebar-header">
            <div className="tablet-sidebar-icon" style={{ background: `linear-gradient(135deg, ${accentColor}, ${accentColor}88)` }}>
              <Crown size={20} />
            </div>
            <div className="tablet-sidebar-title">
              <h1>{data.ganglabel}</h1>
              <p>Niveau {data.level}</p>
            </div>
          </div>

          <div className="tablet-sidebar-xp">
            <div className="tablet-sidebar-xp-bar">
              <div className="tablet-sidebar-xp-fill" style={{ width: `${xpPercent}%`, backgroundColor: accentColor }} />
            </div>
            <span className="tablet-sidebar-xp-text">{data.xp} / {data.requiredXP} XP</span>
          </div>

          <nav className="tablet-sidebar-nav">
            {sidebarItems.map(item => (
              <button
                key={item.id}
                className={`tablet-sidebar-item ${currentPage === item.id ? 'active' : ''}`}
                onClick={() => handlePageChange(item.id)}
                style={currentPage === item.id ? {
                  backgroundColor: accentColor,
                } : {}}
              >
                {item.icon}
                <span>{item.label}</span>
                {item.id === 'missions' && (
                  <span className="tablet-sidebar-badge" style={{ backgroundColor: accentColor }}>
                    {data.missions.daily.filter(m => !m.claimed).length + data.missions.weekly.filter(m => !m.claimed).length}
                  </span>
                )}
                <ChevronRight size={14} className="tablet-sidebar-arrow" />
              </button>
            ))}
          </nav>

          <div className="tablet-sidebar-footer">
            <button className="tablet-close-btn" onClick={handleClose}>
              <X size={16} />
              <span>Fermer</span>
            </button>
          </div>
        </div>

        {/* Content */}
        <div className={`tablet-content ${pageTransition ? 'tablet-page-transition' : ''}`}>
          {renderContent()}
        </div>

        {/* Notification */}
        {notification && (
          <div className={`tablet-notification ${notification.type}`}>
            {notification.type === 'success' ? <Check size={16} /> : <X size={16} />}
            <span>{notification.message}</span>
          </div>
        )}
      </div>
    </div>
  );
};

export default IllegalTablet;
