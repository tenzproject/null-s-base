import React, { useState, useEffect, useCallback } from 'react';
import { Swords, Gem, Check, ChevronLeft, Crosshair, Loader2, Shield, X, ChevronDown, ChevronRight, Eye, EyeOff } from 'lucide-react';
import './WeaponCustomMenu.css';

const GetParentResourceName = () => 'null-core';

interface WeaponComponent {
  name: string;
  label: string;
  hash: string;
  price: number;
  installed: boolean;
}

interface PlayerWeapon {
  name: string;
  label: string;
  components: WeaponComponent[];
}

interface WeaponCustomMenuProps {
  visible: boolean;
  onClose: () => void;
  primaryColor: string;
}

// Group component types
const COMPONENT_GROUPS: Record<string, { label: string; icon: string }> = {
  clip: { label: 'Chargeurs', icon: '🔫' },
  flashlight: { label: 'Lampes', icon: '🔦' },
  suppressor: { label: 'Silencieux', icon: '🔇' },
  scope: { label: 'Viseurs', icon: '🔭' },
  grip: { label: 'Poignées', icon: '✊' },
  luxary_finish: { label: 'Finitions', icon: '✨' },
  stock: { label: 'Crosses', icon: '📏' },
  mount: { label: 'Montages', icon: '🔩' },
  body: { label: 'Corps', icon: '🛡️' },
  barrel: { label: 'Canons', icon: '🔧' },
  other: { label: 'Autres', icon: '⚙️' },
};

const getComponentGroup = (name: string): string => {
  const lower = name.toLowerCase();
  for (const key of Object.keys(COMPONENT_GROUPS)) {
    if (key !== 'other' && lower.includes(key)) return key;
  }
  // Check for barrel/canon in label
  if (lower.includes('canon') || lower.includes('barrel')) return 'barrel';
  return 'other';
};

const WeaponCustomMenu: React.FC<WeaponCustomMenuProps> = ({ visible, onClose, primaryColor }) => {
  const [weapons, setWeapons] = useState<PlayerWeapon[]>([]);
  const [selectedWeapon, setSelectedWeapon] = useState<PlayerWeapon | null>(null);
  const [purchasing, setPurchasing] = useState<string | null>(null);
  const [previewingComp, setPreviewingComp] = useState<string | null>(null);
  const [collapsedGroups, setCollapsedGroups] = useState<Record<string, boolean>>({});
  const [notification, setNotification] = useState<{ message: string; type: 'success' | 'error' } | null>(null);
  const [userCoins, setUserCoins] = useState(0);

  // NUI message handler
  useEffect(() => {
    const handleMessage = (event: MessageEvent) => {
      const data = event.data;
      switch (data.action) {
        case 'weaponCustom:open':
          if (data.weapons) setWeapons(data.weapons);
          if (data.coins !== undefined) setUserCoins(data.coins);
          setPreviewingComp(null);
          setPurchasing(null);
          // Auto-select weapon if specified (opened from boutique)
          if (data.selectedWeapon && data.weapons) {
            const found = (data.weapons as PlayerWeapon[]).find(
              w => w.name.toUpperCase() === data.selectedWeapon.toUpperCase()
            );
            setSelectedWeapon(found || null);
            setCollapsedGroups({});
          } else {
            setSelectedWeapon(null);
          }
          break;

        case 'weaponCustom:data':
          if (data.weapons) setWeapons(data.weapons);
          if (data.coins !== undefined) setUserCoins(data.coins);
          break;

        case 'weaponCustom:componentPurchased':
          setPurchasing(null);
          if (data.success) {
            showNotification(data.message || 'Composant installé !', 'success');
            if (data.coins !== undefined) setUserCoins(data.coins);
            // Update local state
            if (data.weaponName && data.componentHash) {
              setWeapons(prev => prev.map(w => {
                if (w.name !== data.weaponName) return w;
                return {
                  ...w,
                  components: w.components.map(c =>
                    c.hash === data.componentHash ? { ...c, installed: true } : c
                  ),
                };
              }));
              setSelectedWeapon(prev => {
                if (!prev || prev.name !== data.weaponName) return prev;
                return {
                  ...prev,
                  components: prev.components.map(c =>
                    c.hash === data.componentHash ? { ...c, installed: true } : c
                  ),
                };
              });
            }
          } else {
            showNotification(data.message || 'Erreur lors de l\'achat', 'error');
          }
          break;
      }
    };

    window.addEventListener('message', handleMessage);
    return () => window.removeEventListener('message', handleMessage);
  }, []);

  // ESC handler
  useEffect(() => {
    if (!visible) return;
    const handleKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        if (previewingComp) {
          handleStopPreviewComponent();
        } else if (selectedWeapon) {
          handleBack();
        } else {
          handleClose();
        }
      }
    };
    window.addEventListener('keydown', handleKey);
    return () => window.removeEventListener('keydown', handleKey);
  }, [visible, selectedWeapon, previewingComp]);

  const showNotification = (message: string, type: 'success' | 'error') => {
    setNotification({ message, type });
    setTimeout(() => setNotification(null), 3000);
  };

  const handleClose = useCallback(() => {
    if (previewingComp) handleStopPreviewComponent();
    fetch(`https://${GetParentResourceName()}/weaponCustom:close`, { method: 'POST' });
    onClose();
  }, [onClose, previewingComp]);

  const handleSelectWeapon = (weapon: PlayerWeapon) => {
    setSelectedWeapon(weapon);
    setCollapsedGroups({});
    setPreviewingComp(null);
    // Tell Lua to equip this weapon
    fetch(`https://${GetParentResourceName()}/weaponCustom:selectWeapon`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ weaponName: weapon.name }),
    });
  };

  const handleBack = () => {
    if (previewingComp) handleStopPreviewComponent();
    setSelectedWeapon(null);
  };

  const handleBuy = (comp: WeaponComponent) => {
    if (comp.installed || purchasing) return;
    setPurchasing(comp.hash);
    fetch(`https://${GetParentResourceName()}/weaponCustom:buyComponent`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        weaponName: selectedWeapon!.name,
        componentHash: comp.hash,
        price: comp.price,
      }),
    });
  };

  const handlePreviewComponent = (comp: WeaponComponent) => {
    if (comp.installed) return;
    // If already previewing this one, stop
    if (previewingComp === comp.hash) {
      handleStopPreviewComponent();
      return;
    }
    setPreviewingComp(comp.hash);
    fetch(`https://${GetParentResourceName()}/weaponCustom:previewComponent`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        weaponName: selectedWeapon!.name,
        componentHash: comp.hash,
      }),
    });
  };

  const handleStopPreviewComponent = () => {
    if (!previewingComp || !selectedWeapon) return;
    fetch(`https://${GetParentResourceName()}/weaponCustom:stopPreviewComponent`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        weaponName: selectedWeapon.name,
        componentHash: previewingComp,
      }),
    });
    setPreviewingComp(null);
  };

  const toggleGroup = (group: string) => {
    setCollapsedGroups(prev => ({ ...prev, [group]: !prev[group] }));
  };

  if (!visible) return null;

  // Group components by type
  const groupedComponents = selectedWeapon
    ? selectedWeapon.components.filter(c => c.hash).reduce((acc, comp) => {
        const group = getComponentGroup(comp.name);
        if (!acc[group]) acc[group] = [];
        acc[group].push(comp);
        return acc;
      }, {} as Record<string, WeaponComponent[]>)
    : {};

  const orderedGroups = Object.keys(COMPONENT_GROUPS).filter(g => groupedComponents[g]?.length);

  return (
    <div className="wcm-overlay">
      <div className="wcm-container">
        {/* Header */}
        <div className="wcm-header">
          <div className="wcm-header-left">
            {selectedWeapon ? (
              <button className="wcm-back-btn" onClick={handleBack}>
                <ChevronLeft size={14} />
              </button>
            ) : (
              <div className="wcm-header-icon">
                <Crosshair size={16} style={{ color: primaryColor }} />
              </div>
            )}
            <div className="wcm-header-text">
              <h2 className="wcm-title">
                {selectedWeapon ? selectedWeapon.label : 'Personnalisation'}
              </h2>
              <span className="wcm-subtitle">
                {selectedWeapon ? 'Composants disponibles' : 'Armes & modifications'}
              </span>
            </div>
          </div>
          <div className="wcm-header-right">
            <div className="wcm-coins">
              <Gem size={12} />
              <span>{userCoins.toLocaleString()}</span>
            </div>
            <button className="wcm-close-btn" onClick={handleClose}>
              <X size={14} />
            </button>
          </div>
        </div>

        {/* Content */}
        <div className="wcm-content">
          {!selectedWeapon ? (
            // Weapon list
            weapons.length > 0 ? (
              <>
              <div className="wcm-section-label">Tes armes</div>
              <div className="wcm-weapons-grid">
                {weapons.map((weapon, i) => {
                  const customizable = weapon.components.filter(c => c.hash);
                  const installed = customizable.filter(c => c.installed).length;
                  const hasCustom = customizable.length > 0;

                  return (
                    <div
                      key={i}
                      className={`wcm-weapon-card ${!hasCustom ? 'no-custom' : ''}`}
                      onClick={() => hasCustom ? handleSelectWeapon(weapon) : undefined}
                    >
                      <div className="wcm-weapon-icon" style={{ color: primaryColor }}>
                        <Swords size={22} />
                      </div>
                      <div className="wcm-weapon-info">
                        <span className="wcm-weapon-name">{weapon.label}</span>
                        {hasCustom ? (
                          <span className="wcm-weapon-count">
                            <span style={{ color: installed === customizable.length ? primaryColor : undefined }}>
                              {installed}/{customizable.length}
                            </span> composants
                          </span>
                        ) : (
                          <span className="wcm-weapon-count dim">Aucune personnalisation</span>
                        )}
                      </div>
                      {hasCustom && installed === customizable.length && (
                        <Check size={16} style={{ color: primaryColor }} className="wcm-weapon-check" />
                      )}
                      {hasCustom && (
                        <ChevronRight size={14} className="wcm-weapon-arrow" />
                      )}
                    </div>
                  );
                })}
              </div>
              </>
            ) : (
              <div className="wcm-empty">
                <Swords size={40} />
                <p>Tu ne possèdes aucune arme</p>
              </div>
            )
          ) : (
            // Component list grouped by type
            orderedGroups.length > 0 ? (
              <>
              <div className="wcm-section-label">Modifications</div>
              <div className="wcm-groups">
                {orderedGroups.map(groupKey => {
                  const group = COMPONENT_GROUPS[groupKey];
                  const comps = groupedComponents[groupKey];
                  const isCollapsed = collapsedGroups[groupKey] ?? false;
                  const installedInGroup = comps.filter(c => c.installed).length;

                  return (
                    <div key={groupKey} className="wcm-group">
                      <button className="wcm-group-header" onClick={() => toggleGroup(groupKey)}>
                        <span className="wcm-group-label">{group.label}</span>
                        <span className="wcm-group-count" style={{ color: primaryColor }}>
                          {installedInGroup}/{comps.length}
                        </span>
                        <ChevronDown size={14} className={`wcm-group-chevron ${isCollapsed ? 'collapsed' : ''}`} />
                      </button>
                      {!isCollapsed && (
                        <div className="wcm-group-items">
                          {comps.map((comp, i) => {
                            const canAfford = userCoins >= comp.price;
                            const isPurchasing = purchasing === comp.hash;
                            const isPreviewing = previewingComp === comp.hash;

                            return (
                              <div
                                key={i}
                                className={`wcm-comp ${comp.installed ? 'installed' : ''} ${isPreviewing ? 'previewing' : ''}`}
                                style={{
                                  borderColor: comp.installed ? `${primaryColor}25` : isPreviewing ? `${primaryColor}40` : undefined,
                                }}
                              >
                                <div className="wcm-comp-info">
                                  <span className="wcm-comp-name">{comp.label}</span>
                                </div>
                                <div className="wcm-comp-actions">
                                  {comp.installed ? (
                                    <div className="wcm-comp-installed" style={{ color: primaryColor }}>
                                      <Check size={12} />
                                      <span>Installé</span>
                                    </div>
                                  ) : (
                                    <>
                                      {/* Preview toggle */}
                                      <button
                                        className={`wcm-comp-preview-btn ${isPreviewing ? 'active' : ''}`}
                                        onClick={() => handlePreviewComponent(comp)}
                                        title={isPreviewing ? 'Arrêter la prévisualisation' : 'Prévisualiser'}
                                        style={isPreviewing ? { color: primaryColor, borderColor: `${primaryColor}40` } : {}}
                                      >
                                        {isPreviewing ? <EyeOff size={12} /> : <Eye size={12} />}
                                      </button>
                                      {/* Buy button */}
                                      <button
                                        className="wcm-comp-buy"
                                        disabled={!canAfford || isPurchasing}
                                        onClick={() => handleBuy(comp)}
                                        style={canAfford && !isPurchasing ? { backgroundColor: primaryColor } : {}}
                                      >
                                        {isPurchasing ? (
                                          <Loader2 size={12} className="wcm-spinner" />
                                        ) : (
                                          <>
                                            <Gem size={11} />
                                            <span>{comp.price}</span>
                                          </>
                                        )}
                                      </button>
                                    </>
                                  )}
                                </div>
                              </div>
                            );
                          })}
                        </div>
                      )}
                    </div>
                  );
                })}
              </div>
              </>
            ) : (
              <div className="wcm-empty">
                <Shield size={40} />
                <p>Aucune personnalisation disponible</p>
              </div>
            )
          )}
        </div>

        {/* Notification */}
        {notification && (
          <div className={`wcm-notification wcm-notification-${notification.type}`}
            style={notification.type === 'success' ? { borderColor: primaryColor } : {}}
          >
            {notification.message}
          </div>
        )}
      </div>
    </div>
  );
};

export default WeaponCustomMenu;
