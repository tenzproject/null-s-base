import React, { useState, useEffect, useCallback, useMemo, useRef } from 'react';
import { VehicleData, GarageData, TabType, SortType } from './types';
import {
  Car, Ship, Plane, Search, X, MapPin, Warehouse, Tag, Star, PenLine,
  UserPlus, Building2, Swords, CircleDollarSign, Wrench, ChevronDown,
  Navigation, AlertTriangle, ChevronRight, Check
} from 'lucide-react';
import './Garage.css';
import { cacheImg } from '@/shared/cacheVersion';
import { generateAccentVars } from '@/utils/accentColors';

const GetParentResourceName = () => 'null-core';

interface GarageProps {
  visible: boolean;
  onClose: () => void;
  primaryColor: string;
  serverConfig?: {
    serverName: string;
    serverIcon: string;
  };
}

const TYPE_ICONS: Record<string, React.ReactNode> = {
  car: <Car size={16} />,
  boat: <Ship size={16} />,
  aircraft: <Plane size={16} />,
};

const TYPE_ICONS_LG: Record<string, React.ReactNode> = {
  car: <Car size={36} />,
  boat: <Ship size={36} />,
  aircraft: <Plane size={36} />,
};

const TYPE_LABELS: Record<string, string> = {
  car: 'Terrestre',
  boat: 'Nautique',
  aircraft: 'Aérien',
};

function getVehicleImageUrl(modelName: string): string {
  return cacheImg(`vehicles/${modelName.toLowerCase()}.webp`);
}

const Garage: React.FC<GarageProps> = ({ visible, onClose, primaryColor, serverConfig }) => {
  const [data, setData] = useState<GarageData | null>(null);
  const [activeTab, setActiveTab] = useState<TabType>('personal');
  const [search, setSearch] = useState('');
  const [sortBy, setSortBy] = useState<SortType>('name');
  const [selectedVehicle, setSelectedVehicle] = useState<VehicleData | null>(null);
  const [hiding, setHiding] = useState(false);
  const [renaming, setRenaming] = useState(false);
  const [renameValue, setRenameValue] = useState('');
  const renameInputRef = useRef<HTMLInputElement>(null);
  const [notification, setNotification] = useState<{ message: string; type: 'success' | 'error' } | null>(null);
  const [failedImages, setFailedImages] = useState<Set<string>>(new Set());

  const accentColor = primaryColor || '#BEEE11';
  const garageAccentVars = useMemo(() => generateAccentVars('--garage-accent', accentColor), [accentColor]);

  const showNotification = useCallback((message: string, type: 'success' | 'error') => {
    setNotification({ message, type });
    setTimeout(() => setNotification(null), 3000);
  }, []);

  useEffect(() => {
    const handler = (event: MessageEvent) => {
      const { action, data: msgData } = event.data;

      switch (action) {
        case 'garage:open':
          setData(msgData);
          setActiveTab('personal');
          setSearch('');
          setSelectedVehicle(null);
          setRenaming(false);
          setHiding(false);
          setFailedImages(new Set());
          break;

        case 'garage:close':
          handleClose();
          break;

        case 'garage:feedback':
          if (msgData?.message) showNotification(msgData.message, 'success');
          break;

        case 'garage:updateVehicles':
          setData(prev => prev ? { ...prev, vehicles: msgData.vehicles } : null);
          break;
      }
    };

    window.addEventListener('message', handler);
    return () => window.removeEventListener('message', handler);
  }, []);

  const handleClose = useCallback(async () => {
    setHiding(true);
    // Call NUI callback to release focus immediately
    try {
      await fetch(`https://${GetParentResourceName()}/garage:close`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
      });
    } catch (e) {
      // Ignore errors
    }
    setTimeout(() => {
      setData(null);
      setSelectedVehicle(null);
      setRenaming(false);
      setHiding(false);
      onClose();
    }, 300);
  }, [onClose]);

  useEffect(() => {
    if (!visible || !data) return;
    const handleKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        if (renaming) { setRenaming(false); return; }
        if (selectedVehicle) { setSelectedVehicle(null); return; }
        handleClose();
      }
    };
    window.addEventListener('keydown', handleKey);
    return () => window.removeEventListener('keydown', handleKey);
  }, [visible, data, selectedVehicle, renaming, handleClose]);

  useEffect(() => {
    if (renaming && renameInputRef.current) {
      renameInputRef.current.focus();
    }
  }, [renaming]);

  const filteredVehicles = useMemo(() => {
    if (!data) return [];

    let vehicles = data.vehicles.filter(v => {
      if (activeTab === 'personal' && v.ownerCategory !== 'personal') return false;
      if (activeTab === 'job' && v.ownerCategory !== 'job') return false;
      if (activeTab === 'org' && v.ownerCategory !== 'org') return false;

      if (data.mode === 'garage' && !v.state) return false;
      if (data.mode === 'impound' && v.state) return false;

      if (v.type !== data.garageType) return false;

      if (search) {
        const q = search.toLowerCase();
        const matchName = v.modelLabel.toLowerCase().includes(q);
        const matchPlate = v.plate.toLowerCase().includes(q);
        const matchLabel = v.label?.toLowerCase().includes(q);
        if (!matchName && !matchPlate && !matchLabel) return false;
      }

      return true;
    });

    vehicles.sort((a, b) => {
      if (sortBy === 'name') return a.modelLabel.localeCompare(b.modelLabel);
      if (sortBy === 'status') {
        if (a.spawned !== b.spawned) return a.spawned ? -1 : 1;
        return a.modelLabel.localeCompare(b.modelLabel);
      }
      return 0;
    });

    return vehicles;
  }, [data, activeTab, search, sortBy]);

  const handleSpawn = useCallback((v: VehicleData) => {
    fetch(`https://${GetParentResourceName()}/garage:spawn`, {
      method: 'POST',
      body: JSON.stringify({ plate: v.plate, vehicle: v.vehicle })
    });
  }, []);

  const handleImpoundSpawn = useCallback((v: VehicleData) => {
    fetch(`https://${GetParentResourceName()}/garage:impoundSpawn`, {
      method: 'POST',
      body: JSON.stringify({ plate: v.plate, vehicle: v.vehicle })
    });
  }, []);

  const handleStore = useCallback(() => {
    fetch(`https://${GetParentResourceName()}/garage:store`, { method: 'POST', body: JSON.stringify({}) });
  }, []);

  const handleStoreWithRepair = useCallback(() => {
    fetch(`https://${GetParentResourceName()}/garage:storeWithRepair`, { method: 'POST', body: JSON.stringify({}) });
  }, []);

  const handleRename = useCallback((v: VehicleData, newLabel: string) => {
    if (!newLabel.trim()) return;
    fetch(`https://${GetParentResourceName()}/garage:rename`, {
      method: 'POST',
      body: JSON.stringify({ plate: v.plate, owner: v.owner, vehicle: v.vehicle, label: newLabel.trim() })
    });
    setRenaming(false);
    showNotification('Véhicule renommé', 'success');
  }, [showNotification]);

  const handleGive = useCallback((v: VehicleData) => {
    fetch(`https://${GetParentResourceName()}/garage:give`, {
      method: 'POST',
      body: JSON.stringify({ plate: v.plate, vehicle: v.vehicle, owner: v.owner })
    });
  }, []);

  const handleAssign = useCallback((v: VehicleData, type: 'job' | 'job2') => {
    fetch(`https://${GetParentResourceName()}/garage:assign`, {
      method: 'POST',
      body: JSON.stringify({ plate: v.plate, vehicle: v.vehicle, type })
    });
  }, []);

  const handleLocate = useCallback((v: VehicleData) => {
    fetch(`https://${GetParentResourceName()}/garage:locate`, {
      method: 'POST',
      body: JSON.stringify({ plate: v.plate })
    });
    showNotification('GPS activé', 'success');
  }, [showNotification]);

  const handleTabClick = (tabKey: TabType) => {
    setActiveTab(tabKey);
    setSelectedVehicle(null);
  };

  if (!visible || !data) return null;

  const isStore = data.mode === 'store';
  const isImpound = data.mode === 'impound';

  const tabs: { key: TabType; label: string; icon: React.ReactNode; show: boolean }[] = [
    { key: 'personal', label: 'Mes Véhicules', icon: <Car size={16} />, show: true },
    { key: 'job', label: data.jobLabel || 'Entreprise', icon: <Building2 size={16} />, show: data.hasJob },
    { key: 'org', label: data.orgLabel || 'Organisation', icon: <Swords size={16} />, show: data.hasOrg },
  ];

  const vehicleCount = filteredVehicles.length;
  const totalVehicles = data.vehicles.filter(v => v.type === data.garageType).length;
  const spawnedVehicles = data.vehicles.filter(v => v.type === data.garageType && v.spawned).length;

  const renderVehicleImage = (v: VehicleData, className: string = 'garage-card-img') => {
    const imageName = v.model?.toLowerCase() || '';
    const hasImage = imageName && !failedImages.has(imageName);

    if (hasImage) {
      return (
        <img
          src={getVehicleImageUrl(imageName)}
          alt={v.modelLabel}
          className={className}
          onError={() => setFailedImages(prev => new Set(prev).add(imageName))}
          draggable={false}
        />
      );
    }
    return (
      <div className="garage-card-placeholder">
        {TYPE_ICONS_LG[v.type]}
      </div>
    );
  };

  return (
    <div className={`garageui-overlay ${hiding ? 'garageui-hiding' : ''}`}>
      <div
        className="garageui-container"
        style={garageAccentVars as React.CSSProperties}
      >
        {/* Sidebar */}
        <div className="garageui-sidebar">
          {/* Brand Hero Header */}
          <div className="garageui-brand-hero">
            <div className="garageui-brand-hero-inner">
              {serverConfig?.serverIcon && (
                <img src={serverConfig.serverIcon} alt="" className="garageui-brand-logo" />
              )}
              <div className="garageui-brand-hero-text">
                <h1>{serverConfig?.serverName || 'Null'}</h1>
                <p>{isImpound ? 'Fourrière' : 'Garage'}</p>
              </div>
            </div>
          </div>

          {/* Stats section */}
          <div className="garageui-stats-section">
            <div className="garageui-stat-item">
              <span className="garageui-stat-label">Total</span>
              <span className="garageui-stat-value">{totalVehicles}</span>
            </div>
            <div className="garageui-stat-item">
              <span className="garageui-stat-label">Sortis</span>
              <span className="garageui-stat-value" style={{ color: accentColor }}>{spawnedVehicles}</span>
            </div>
          </div>

          {/* Tabs as sidebar nav */}
          <nav className="garageui-sidebar-nav">
            {tabs.filter(t => t.show).map((t) => (
              <button
                key={t.key}
                className={`garageui-sidebar-item ${activeTab === t.key ? 'active' : ''}`}
                onClick={() => handleTabClick(t.key)}
              >
                {activeTab === t.key && <div className="garageui-sidebar-indicator" style={{ background: accentColor }} />}
                {t.icon}
                <span>{t.label}</span>
                <ChevronRight size={14} className="garageui-sidebar-arrow" />
              </button>
            ))}
          </nav>

          {/* Footer */}
          <div className="garageui-sidebar-footer">
            <div className="garageui-vehicle-count">
              <Car size={14} />
              <span>{vehicleCount} véhicule{vehicleCount !== 1 ? 's' : ''}</span>
            </div>
            <button className="garageui-close-btn" onClick={handleClose}>
              <X size={16} />
              <span>Fermer</span>
            </button>
          </div>
        </div>

        {/* Main content */}
        <div className="garageui-content">
          {/* Ambient gradient tint */}
          {/* <div
            className="garageui-brand-ambient"
            style={{
              background: `radial-gradient(circle at 0% 0%, ${accentColor}33 0%, transparent 55%)`,
            }}
            aria-hidden
          /> */}
          {isStore ? (
            /* Store view */
            <div className="garageui-store-view">
              <div className="garageui-content-header">
                <div className="garageui-content-header-info">
                  <h2>Ranger le véhicule</h2>
                  <p>Stockez votre véhicule actuel dans ce garage</p>
                </div>
              </div>

              <div className="garageui-store-card">
                <div className="garageui-store-icon" style={{ background: `linear-gradient(135deg, ${accentColor}33, ${accentColor}11)` }}>
                  <Warehouse size={32} style={{ color: accentColor }} />
                </div>

                {data.vehicleDamaged ? (
                  <>
                    <div className="garageui-store-warning">
                      <AlertTriangle size={18} />
                      <span>Votre véhicule est endommagé</span>
                    </div>
                    <button
                      className="garageui-btn garageui-btn-accent"
                      style={{ backgroundColor: accentColor }}
                      onClick={handleStoreWithRepair}
                    >
                      <Wrench size={15} />
                      Réparer & Ranger — {data.repairPrice}$
                    </button>
                  </>
                ) : (
                  <button
                    className="garageui-btn garageui-btn-accent"
                    style={{ backgroundColor: accentColor }}
                    onClick={handleStore}
                  >
                    <Warehouse size={15} />
                    Ranger le véhicule
                  </button>
                )}

                <button className="garageui-btn garageui-btn-ghost" onClick={handleClose}>
                  Annuler
                </button>
              </div>
            </div>
          ) : (
            <>
              {/* Header with search and sort */}
              <div className="garageui-content-header">
                <div className="garageui-content-header-info">
                  <h2>{tabs.find(t => t.key === activeTab)?.label || 'Véhicules'}</h2>
                  <p>{isImpound ? 'Récupérez vos véhicules en fourrière' : 'Gérez vos véhicules et sortez-les du garage'}</p>
                </div>
                <div className="garageui-header-actions">
                  <div className="garageui-search">
                    <Search size={16} />
                    <input
                      type="text"
                      placeholder="Rechercher..."
                      value={search}
                      onChange={e => setSearch(e.target.value)}
                    />
                    {search && (
                      <button className="garageui-search-clear" onClick={() => setSearch('')}>
                        <X size={12} />
                      </button>
                    )}
                  </div>
                  <div className="garageui-sort">
                    <ChevronDown size={12} />
                    <select value={sortBy} onChange={e => setSortBy(e.target.value as SortType)}>
                      <option value="name">Nom</option>
                      <option value="status">Statut</option>
                    </select>
                  </div>
                </div>
              </div>

              {/* Vehicles grid with detail panel */}
              <div className="garageui-main-layout">
                {/* Left: Vehicle grid */}
                <div className="garageui-vehicle-grid">
                  {vehicleCount === 0 ? (
                    <div className="garageui-empty">
                      <Warehouse size={48} />
                      <p>Aucun véhicule</p>
                    </div>
                  ) : (
                    filteredVehicles.map(v => (
                      <div
                        key={v.plate}
                        className={`garageui-vehicle-card ${selectedVehicle?.plate === v.plate ? 'selected' : ''} ${v.spawned ? 'spawned' : ''}`}
                        onClick={() => setSelectedVehicle(v)}
                      >
                        <div className="garageui-vehicle-image">
                          {renderVehicleImage(v, 'garageui-vehicle-img')}
                          <div className="garageui-vehicle-badges">
                            {v.spawned ? (
                              <span className="garageui-badge garageui-badge-out">
                                <MapPin size={10} />
                                {v.distance !== null ? `${Math.round(v.distance)}m` : 'Sorti'}
                              </span>
                            ) : v.state ? (
                              <span className="garageui-badge garageui-badge-in">Garé</span>
                            ) : (
                              <span className="garageui-badge garageui-badge-impound">Fourrière</span>
                            )}
                            {v.boutique && (
                              <span className="garageui-badge garageui-badge-boutique">
                                <Star size={9} />
                              </span>
                            )}
                          </div>
                        </div>
                        <div className="garageui-vehicle-info">
                          <span className="garageui-vehicle-name">{v.label || v.modelLabel}</span>
                          {v.label && (
                            <span className="garageui-vehicle-model">{v.modelLabel}</span>
                          )}
                          <span className="garageui-vehicle-plate">{v.plate}</span>
                        </div>
                      </div>
                    ))
                  )}
                </div>

                {/* Right: Detail panel */}
                <div className={`garageui-detail-panel ${selectedVehicle ? 'has-vehicle' : ''}`}>
                  {selectedVehicle ? (
                    <div className="garageui-detail">
                      <div className="garageui-detail-image">
                        {renderVehicleImage(selectedVehicle, 'garageui-detail-img')}
                      </div>

                      <div className="garageui-detail-header">
                        <div className="garageui-detail-type-badge">
                          {TYPE_ICONS[selectedVehicle.type]}
                          <span>{TYPE_LABELS[selectedVehicle.type]}</span>
                        </div>
                        {selectedVehicle.boutique && (
                          <div className="garageui-detail-boutique">
                            <Star size={12} />
                            Boutique
                          </div>
                        )}
                      </div>

                      <div className="garageui-detail-name-section">
                        {renaming ? (
                          <div className="garageui-rename-row">
                            <input
                              ref={renameInputRef}
                              className="garageui-rename-input"
                              value={renameValue}
                              onChange={e => setRenameValue(e.target.value)}
                              onKeyDown={e => {
                                if (e.key === 'Enter') handleRename(selectedVehicle, renameValue);
                                if (e.key === 'Escape') setRenaming(false);
                              }}
                              placeholder="Nouveau nom..."
                              maxLength={30}
                            />
                            <button
                              className="garageui-btn garageui-btn-sm garageui-btn-accent"
                              style={{ backgroundColor: accentColor }}
                              onClick={() => handleRename(selectedVehicle, renameValue)}
                            >
                              <Check size={14} />
                            </button>
                            <button className="garageui-btn garageui-btn-sm garageui-btn-ghost" onClick={() => setRenaming(false)}>
                              <X size={14} />
                            </button>
                          </div>
                        ) : (
                          <>
                            <h3 className="garageui-detail-title">
                              {selectedVehicle.label || selectedVehicle.modelLabel}
                            </h3>
                            {selectedVehicle.label && (
                              <span className="garageui-detail-model">{selectedVehicle.modelLabel}</span>
                            )}
                          </>
                        )}
                      </div>

                      <div className="garageui-detail-infos">
                        <div className="garageui-detail-info-row">
                          <Tag size={13} />
                          <span className="garageui-detail-info-label">Plaque</span>
                          <span className="garageui-detail-info-value">{selectedVehicle.plate}</span>
                        </div>
                        <div className="garageui-detail-info-row">
                          <Warehouse size={13} />
                          <span className="garageui-detail-info-label">Statut</span>
                          <span className="garageui-detail-info-value">
                            {selectedVehicle.spawned ? (
                              <span className="garageui-badge garageui-badge-out">
                                <MapPin size={10} />
                                Sortie {selectedVehicle.distance !== null && `— ${Math.round(selectedVehicle.distance)}m`}
                              </span>
                            ) : selectedVehicle.state ? (
                              <span className="garageui-badge garageui-badge-in">Garé</span>
                            ) : (
                              <span className="garageui-badge garageui-badge-impound">Fourrière</span>
                            )}
                          </span>
                        </div>
                      </div>

                      <div className="garageui-detail-actions">
                        {isImpound ? (
                          <button
                            className="garageui-btn garageui-btn-accent garageui-btn-full"
                            style={{ backgroundColor: accentColor }}
                            onClick={() => handleImpoundSpawn(selectedVehicle)}
                          >
                            Récupérer — {data.impoundPrice}$
                          </button>
                        ) : (
                          <>
                            {!selectedVehicle.spawned ? (
                              <button
                                className="garageui-btn garageui-btn-accent garageui-btn-full"
                                style={{ backgroundColor: accentColor }}
                                onClick={() => handleSpawn(selectedVehicle)}
                              >
                                Sortir le véhicule
                              </button>
                            ) : (
                              <button className="garageui-btn garageui-btn-outline garageui-btn-full" onClick={() => handleLocate(selectedVehicle)}>
                                Localiser sur le GPS
                              </button>
                            )}

                            <button className="garageui-btn garageui-btn-outline" onClick={() => {
                              setRenaming(true);
                              setRenameValue(selectedVehicle.label || '');
                            }}>
                              Renommer
                            </button>

                            {!selectedVehicle.boutique && selectedVehicle.ownerCategory === 'personal' && (
                              <>
                                <button className="garageui-btn garageui-btn-outline" onClick={() => handleGive(selectedVehicle)}>
                                  Donner
                                </button>

                                {data.hasJob && (
                                  <button className="garageui-btn garageui-btn-outline garageui-btn-warning" onClick={() => handleAssign(selectedVehicle, 'job')}>
                                    Attribuer à l'entreprise
                                  </button>
                                )}

                                {data.hasOrg && (
                                  <button className="garageui-btn garageui-btn-outline garageui-btn-warning" onClick={() => handleAssign(selectedVehicle, 'job2')}>
                                    <Swords size={14} />
                                    Attribuer au gang
                                  </button>
                                )}
                              </>
                            )}
                          </>
                        )}
                      </div>
                    </div>
                  ) : (
                    <div className="garageui-detail-empty">
                      <Car size={48} />
                      <span>Sélectionnez un véhicule</span>
                    </div>
                  )}
                </div>
              </div>
            </>
          )}
        </div>

        {/* Notification */}
        {notification && (
          <div className={`garageui-notification ${notification.type}`}>
            {notification.type === 'success' ? <Check size={16} /> : <AlertTriangle size={16} />}
            <span>{notification.message}</span>
          </div>
        )}
      </div>
    </div>
  );
};

export default Garage;
