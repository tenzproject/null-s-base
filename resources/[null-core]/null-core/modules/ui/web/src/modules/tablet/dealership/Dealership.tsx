import React, { useState, useEffect, useCallback, useMemo, useRef } from 'react';
import { DealershipData, DealershipVehicle, StockVehicle, DealerEmployee, DealerTab, GestionSubTab, ShowroomVehicle } from './types';
import { Car, Bike, Ship, Search, X, ShoppingCart, Package, History, Settings, DollarSign, Eye, UserPlus, Wallet, Landmark, Tag, Palette, Users, ChevronRight, Banknote, TrendingUp, Building2, CheckCircle, Monitor, Trash2 } from 'lucide-react';
import './Dealership.css';
import { cacheImg } from '@shared/cacheVersion';

const GetParentResourceName = () => 'null-core';

interface DealershipProps {
  visible: boolean;
  onClose: () => void;
  primaryColor: string;
}

const TYPE_ICONS: Record<string, React.ReactNode> = {
  car: <Car size={16} />,
  bike: <Bike size={16} />,
  boat: <Ship size={16} />,
};

const TYPE_ICONS_LG: Record<string, React.ReactNode> = {
  car: <Car size={36} />,
  bike: <Bike size={36} />,
  boat: <Ship size={36} />,
};

const TYPE_LABELS: Record<string, string> = {
  car: 'Automobile',
  bike: 'Moto',
  boat: 'Nautique',
};

function hexToRgb(hex: string): string {
  const h = hex.replace('#', '');
  const r = parseInt(h.substring(0, 2), 16);
  const g = parseInt(h.substring(2, 4), 16);
  const b = parseInt(h.substring(4, 6), 16);
  return `${r}, ${g}, ${b}`;
}

function formatMoney(amount: number): string {
  return amount.toLocaleString('fr-FR');
}

function getVehicleImageUrl(modelName: string): string {
  return cacheImg(`vehicles/${modelName.toLowerCase()}.webp`);
}

const COLOR_MAP: Record<string, string> = {
  black: '#1a1a1a', white: '#f0f0f0', grey: '#808080', red: '#cc2222',
  blue: '#2255cc', yellow: '#ccaa22', green: '#22aa44', orange: '#dd6622',
};

const Dealership: React.FC<DealershipProps> = ({ visible, onClose, primaryColor }) => {
  const [data, setData] = useState<DealershipData | null>(null);
  const [activeTab, setActiveTab] = useState<DealerTab>('catalogue');
  const [gestionSub, setGestionSub] = useState<GestionSubTab>('stock');
  const [search, setSearch] = useState('');
  const [stockSearch, setStockSearch] = useState('');
  const [selectedCategory, setSelectedCategory] = useState<string | null>(null);
  const [selectedVehicle, setSelectedVehicle] = useState<DealershipVehicle | null>(null);
  const [selectedStock, setSelectedStock] = useState<StockVehicle | null>(null);
  const [selectedEmployee, setSelectedEmployee] = useState<DealerEmployee | null>(null);
  const [selectedColor, setSelectedColor] = useState(0);
  const [isClosing, setIsClosing] = useState(false);
  const [actionFeedback, setActionFeedback] = useState<string | null>(null);
  const [previewVisible, setPreviewVisible] = useState(false);
  const [paySuccess, setPaySuccess] = useState<{ name: string; net: number } | null>(null);
  const [showroomData, setShowroomData] = useState<Record<string, ShowroomVehicle>>({});
  const [showroomSlot, setShowroomSlot] = useState<string | null>(null); // selected slot key
  const feedbackTimer = useRef<ReturnType<typeof setTimeout> | null>(null);
  const [failedImages, setFailedImages] = useState<Set<string>>(new Set());

  const showFeedback = useCallback((msg: string) => {
    if (feedbackTimer.current) clearTimeout(feedbackTimer.current);
    setActionFeedback(msg);
    feedbackTimer.current = setTimeout(() => setActionFeedback(null), 3000);
  }, []);

  useEffect(() => {
    const handler = (event: MessageEvent) => {
      const { action, data: msgData } = event.data;
      switch (action) {
        case 'dealership:open':
          setData(msgData);
          setActiveTab('catalogue');
          setGestionSub('stock');
          setSearch('');
          setStockSearch('');
          setSelectedCategory(null);
          setSelectedVehicle(null);
          setSelectedStock(null);
          setSelectedEmployee(null);
          setSelectedColor(0);
          setIsClosing(false);
          setFailedImages(new Set());
          setPaySuccess(null);
          setShowroomData(msgData?.showroomData || {});
          setShowroomSlot(null);
          break;

        case 'dealership:close':
          handleClose();
          break;

        case 'dealership:hideForPreview':
          setIsClosing(true);
          setTimeout(() => {
            setData(null);
            setSelectedVehicle(null);
            setSelectedStock(null);
            setSelectedEmployee(null);
            setIsClosing(false);
            onClose();
          }, 150);
          break;

        case 'dealership:showPreviewHint':
          setPreviewVisible(true);
          break;

        case 'dealership:hidePreviewHint':
          setPreviewVisible(false);
          break;

        case 'dealership:feedback':
          if (msgData?.message) showFeedback(msgData.message);
          break;

        case 'dealership:updateData':
          setData(prev => prev ? { ...prev, ...msgData } : null);
          break;

        case 'dealership:saleCompleted': {
          // Live-update employee stats when a sale is made without reopening tablet
          const newEntry = {
            type: 'sale' as const,
            model: msgData.model,
            plate: msgData.plate,
            buyer: msgData.buyerName,
            price: msgData.price,
            date: msgData.date,
          };
          setData(prev => {
            if (!prev) return prev;
            return {
              ...prev,
              societyMoney: msgData.societyMoney ?? prev.societyMoney,
              employees: prev.employees.map(e =>
                e.firstname + ' ' + e.lastname === msgData.sellerName
                  ? {
                      ...e,
                      totalCA: e.totalCA + msgData.price,
                      totalSales: e.totalSales + 1,
                      sales: [newEntry, ...e.sales],
                    }
                  : e
              ),
            };
          });
          setSelectedEmployee(prev => {
            if (!prev) return prev;
            if (prev.firstname + ' ' + prev.lastname !== msgData.sellerName) return prev;
            return {
              ...prev,
              totalCA: prev.totalCA + msgData.price,
              totalSales: prev.totalSales + 1,
              sales: [newEntry, ...prev.sales],
            };
          });
          break;
        }

        case 'dealership:showroomUpdated':
          setShowroomData(msgData || {});
          break;

        case 'dealership:paySuccess':
          setPaySuccess({ name: msgData.name, net: msgData.net });
          // Refresh employee to zero
          if (msgData.identifier) {
            setData(prev => {
              if (!prev) return prev;
              return {
                ...prev,
                employees: prev.employees.map(e =>
                  e.identifier === msgData.identifier
                    ? { ...e, totalCA: 0, totalSales: 0, sales: [] }
                    : e
                )
              };
            });
            setSelectedEmployee(prev =>
              prev && prev.identifier === msgData.identifier
                ? { ...prev, totalCA: 0, totalSales: 0, sales: [] }
                : prev
            );
          }
          setTimeout(() => setPaySuccess(null), 4000);
          break;
      }
    };

    window.addEventListener('message', handler);
    return () => window.removeEventListener('message', handler);
  }, []);

  const handleClose = useCallback(() => {
    setIsClosing(true);
    setTimeout(() => {
      setData(null);
      setSelectedVehicle(null);
      setSelectedStock(null);
      setSelectedEmployee(null);
      setIsClosing(false);
      setPreviewVisible(false);
      onClose();
      fetch(`https://${GetParentResourceName()}/dealership:close`, { method: 'POST', body: '{}' });
    }, 250);
  }, [onClose]);

  useEffect(() => {
    if (!visible || !data) return;
    const handleKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        if (selectedVehicle) { setSelectedVehicle(null); return; }
        if (selectedStock) { setSelectedStock(null); return; }
        if (selectedEmployee) { setSelectedEmployee(null); return; }
        handleClose();
      }
    };
    window.addEventListener('keydown', handleKey);
    return () => window.removeEventListener('keydown', handleKey);
  }, [visible, data, selectedVehicle, selectedStock, selectedEmployee, handleClose]);

  const filteredVehicles = useMemo(() => {
    if (!data) return [];
    let vehicles = data.vehicles;
    if (selectedCategory) vehicles = vehicles.filter(v => v.category === selectedCategory);
    if (search) {
      const q = search.toLowerCase();
      vehicles = vehicles.filter(v => v.label.toLowerCase().includes(q) || v.model.toLowerCase().includes(q));
    }
    return vehicles;
  }, [data, selectedCategory, search]);

  const filteredStock = useMemo(() => {
    if (!data) return data?.stock ?? [];
    if (!stockSearch) return data.stock;
    const q = stockSearch.toLowerCase();
    return data.stock.filter(s => s.label.toLowerCase().includes(q) || s.model.toLowerCase().includes(q) || s.plate.toLowerCase().includes(q));
  }, [data, stockSearch]);

  const stockCounts = useMemo(() => {
    if (!data) return {};
    const counts: Record<string, number> = {};
    for (const s of data.stock) {
      counts[s.model] = (counts[s.model] || 0) + 1;
    }
    return counts;
  }, [data]);

  // --- NUI Callbacks ---
  const handlePreview = useCallback((model: string, colorId: number) => {
    fetch(`https://${GetParentResourceName()}/dealership:preview`, {
      method: 'POST',
      body: JSON.stringify({ model, colorId })
    });
  }, []);

  const handleBuyForStock = useCallback((model: string, price: number, colorId: number) => {
    fetch(`https://${GetParentResourceName()}/dealership:buyForStock`, {
      method: 'POST',
      body: JSON.stringify({ model, price, colorId })
    });
  }, []);

  const handleSellToPlayer = useCallback((stockIndex: number) => {
    fetch(`https://${GetParentResourceName()}/dealership:sellToPlayer`, {
      method: 'POST',
      body: JSON.stringify({ stockIndex })
    });
  }, []);

  const handleStockPreview = useCallback((stockIndex: number) => {
    fetch(`https://${GetParentResourceName()}/dealership:stockPreview`, {
      method: 'POST',
      body: JSON.stringify({ stockIndex })
    });
  }, []);

  const handleSocietyMenu = useCallback(() => {
    fetch(`https://${GetParentResourceName()}/dealership:societyMenu`, {
      method: 'POST', body: '{}'
    });
  }, []);

  const handlePayEmployee = useCallback((identifier: string) => {
    fetch(`https://${GetParentResourceName()}/dealership:payEmployee`, {
      method: 'POST',
      body: JSON.stringify({ identifier })
    });
  }, []);

  // Preview hint overlay (shown even when tablet is closed)
  if (!visible || !data) {
    if (previewVisible) {
      return (
        <div className="dealer-preview-overlay">
          <div className="dealer-preview-controls">
            <div className="dealer-preview-key-row">
              <div className="dealer-preview-key">
                <span className="dealer-preview-arrow">←</span>
              </div>
              <span className="dealer-preview-key-label">Gauche</span>
            </div>
            <div className="dealer-preview-key-row">
              <div className="dealer-preview-key">
                <span className="dealer-preview-arrow">→</span>
              </div>
              <span className="dealer-preview-key-label">Droite</span>
            </div>
            <div className="dealer-preview-key-row dealer-preview-key-row-exit">
              <div className="dealer-preview-key dealer-preview-key-exit">
                <span>SUPPR</span>
              </div>
              <span className="dealer-preview-key-label">Quitter</span>
            </div>
          </div>
        </div>
      );
    }
    return null;
  }

  const accentColor = primaryColor || '#3b82f6';
  const accentRgb = hexToRgb(accentColor);
  const isPublic = data.mode === 'public';
  const canSell = data.mode === 'employee' || data.mode === 'boss';
  const canBoss = data.mode === 'boss';
  const restockPct = data.restockPercent || 0.6;
  const saleMargin = 1.25;

  const tabs: { key: DealerTab; label: string; icon: React.ReactNode; show: boolean }[] = [
    { key: 'catalogue', label: 'Catalogue', icon: <ShoppingCart size={15} />, show: true },
    { key: 'gestion', label: 'Gestion', icon: <Settings size={15} />, show: canSell },
  ];

  const hasShowroom = canBoss && data.showroomSlots && data.showroomSlots.length > 0;

  const gestionSubTabs: { key: GestionSubTab; label: string; icon: React.ReactNode; show: boolean }[] = [
    { key: 'stock',     label: `Stock (${data.stock.length})`, icon: <Package size={14} />,  show: true },
    { key: 'history',  label: 'Historique',                   icon: <History size={14} />,   show: true },
    { key: 'showroom', label: data.showroomTitle || 'Showroom', icon: <Monitor size={14} />, show: hasShowroom },
    { key: 'employees',label: 'Employés',                     icon: <Users size={14} />,     show: canBoss },
    { key: 'society',  label: 'Société',                      icon: <Landmark size={14} />,  show: canBoss },
  ];

  const renderVehicleImage = (model: string) => {
    const displayName = model.toLowerCase();
    const hasImage = !failedImages.has(displayName);
    if (hasImage) {
      return (
        <img
          src={getVehicleImageUrl(displayName)}
          alt={model}
          className="dealer-card-img"
          onError={() => setFailedImages(prev => new Set(prev).add(displayName))}
          draggable={false}
        />
      );
    }
    return (
      <div className="dealer-card-placeholder">
        {TYPE_ICONS_LG[data.shopType]}
      </div>
    );
  };

  const getColorHex = (colorName: string) => COLOR_MAP[colorName] || '#666';
  const currentColorId = data.colors[selectedColor]?.id ?? 0;

  const getEmployeeStats = (emp: DealerEmployee) => {
    const ca = emp.totalCA;
    const salaireTaxRate = (data.taxRates?.salaire ?? 10) / 100;
    const retraitTaxRate = (data.taxRates?.retrait ?? 10) / 100;
    // Company keeps 10% of CA
    const companyRevenue = Math.floor(ca * 0.10);
    // Salary = 5% of CA, then taxed at salaireTaxRate
    const rawSalary = Math.floor(ca * 0.05);
    const salaryTax = Math.floor(rawSalary * salaireTaxRate);
    const netSalary = rawSalary - salaryTax;
    // Gov CA tax = retraitTaxRate of CA
    const govCATax = Math.floor(ca * retraitTaxRate);
    return { ca, companyRevenue, rawSalary, netSalary, salaryTax, govCATax };
  };

  return (
    <div className={`dealer-overlay ${isClosing ? 'dealer-closing' : ''}`}>
      <div className="dealer-backdrop" onClick={handleClose} />
      <div className="dealer-container">
        <div className="dealer-main">
          {/* Left panel */}
          <div className="dealer-left">
            <div className="dealer-header">
              <div className="dealer-header-left">
                <div className="dealer-header-icon" style={{ background: `rgba(${accentRgb}, 0.18)`, color: accentColor }}>
                  {TYPE_ICONS[data.shopType] || <Car size={20} />}
                </div>
                <div>
                  <h2 className="dealer-title">{data.shopLabel}</h2>
                  <span className="dealer-subtitle">{TYPE_LABELS[data.shopType]}</span>
                </div>
              </div>
              <button className="dealer-close-btn" onClick={handleClose}>
                <X size={18} />
              </button>
            </div>

            <div className="dealer-tabs">
              {tabs.filter(t => t.show).map(t => (
                <button
                  key={t.key}
                  className={`dealer-tab ${activeTab === t.key ? 'active' : ''}`}
                  style={activeTab === t.key ? { background: `rgba(${accentRgb}, 0.15)`, color: accentColor } : undefined}
                  onClick={() => { setActiveTab(t.key); setSelectedVehicle(null); setSelectedStock(null); setSelectedEmployee(null); }}
                >
                  {t.icon}
                  <span>{t.label}</span>
                </button>
              ))}
            </div>

            {canSell && (
              <div className="dealer-society-bar">
                <Wallet size={13} />
                <span>Société: <span className="dealer-society-amount">{formatMoney(data.societyMoney)}$</span></span>
              </div>
            )}

            {/* ========== CATALOGUE TAB ========== */}
            {activeTab === 'catalogue' && (
              <>
                <div className="dealer-categories">
                  <button
                    className="dealer-cat-pill"
                    style={!selectedCategory ? { background: `rgba(${accentRgb}, 0.18)`, color: accentColor } : undefined}
                    onClick={() => setSelectedCategory(null)}
                  >Tout</button>
                  {data.categories.map(cat => (
                    <button
                      key={cat}
                      className="dealer-cat-pill"
                      style={selectedCategory === cat ? { background: `rgba(${accentRgb}, 0.18)`, color: accentColor } : undefined}
                      onClick={() => setSelectedCategory(cat)}
                    >{cat}</button>
                  ))}
                </div>

                <div className="dealer-filters">
                  <div className="dealer-search">
                    <Search size={14} />
                    <input
                      type="text"
                      placeholder="Rechercher un véhicule..."
                      value={search}
                      onChange={e => setSearch(e.target.value)}
                    />
                    {search && (
                      <button className="dealer-search-clear" onClick={() => setSearch('')}>
                        <X size={12} />
                      </button>
                    )}
                  </div>
                  <span className="dealer-count">{filteredVehicles.length} véhicule{filteredVehicles.length !== 1 ? 's' : ''}</span>
                </div>

                <div className="dealer-vehicle-grid">
                  {filteredVehicles.length === 0 ? (
                    <div className="dealer-empty">
                      {TYPE_ICONS_LG[data.shopType]}
                      <span>Aucun véhicule trouvé</span>
                    </div>
                  ) : (
                    filteredVehicles.map((v, idx) => (
                      <div
                        key={`${v.model}-${v.category}-${idx}`}
                        className={`dealer-card ${selectedVehicle?.model === v.model ? 'selected' : ''}`}
                        style={selectedVehicle?.model === v.model ? { borderColor: `rgba(${accentRgb}, 0.4)` } : undefined}
                        onClick={() => { setSelectedVehicle(v); setSelectedStock(null); setSelectedEmployee(null); }}
                      >
                        <div className="dealer-card-image">
                          {renderVehicleImage(v.model)}
                          <div className="dealer-card-badges">
                            {canSell && stockCounts[v.model] > 0 && (
                              <span className="dealer-badge dealer-badge-stock">
                                <Package size={10} /> {stockCounts[v.model]} en stock
                              </span>
                            )}
                          </div>
                        </div>
                        <div className="dealer-card-body">
                          <div className="dealer-card-name">{v.label}</div>
                          <div className="dealer-card-price" style={{ color: '#3b82f6' }}>{formatMoney(v.salePrice ?? Math.floor(v.price * saleMargin))}$</div>
                          <div className="dealer-card-category">{v.category}</div>
                        </div>
                      </div>
                    ))
                  )}
                </div>
              </>
            )}

            {/* ========== GESTION TAB ========== */}
            {activeTab === 'gestion' && canSell && (
              <>
                {/* Sub-navigation */}
                <div className="dealer-gestion-subnav">
                  {gestionSubTabs.filter(t => t.show).map(st => (
                    <button
                      key={st.key}
                      className={`dealer-gestion-subbtn ${gestionSub === st.key ? 'active' : ''}`}
                      style={gestionSub === st.key ? { background: `rgba(${accentRgb}, 0.15)`, color: accentColor, borderColor: `rgba(${accentRgb}, 0.3)` } : undefined}
                      onClick={() => { setGestionSub(st.key); setSelectedStock(null); setSelectedEmployee(null); setPaySuccess(null); }}
                    >
                      {st.icon}
                      <span>{st.label}</span>
                    </button>
                  ))}
                </div>

                {/* ---- STOCK sub-tab ---- */}
                {gestionSub === 'stock' && (
                  <div className="dealer-stock-section">
                    <div className="dealer-search" style={{ margin: '8px 14px 4px' }}>
                      <Search size={14} />
                      <input
                        type="text"
                        placeholder="Rechercher dans le stock..."
                        value={stockSearch}
                        onChange={e => setStockSearch(e.target.value)}
                      />
                      {stockSearch && (
                        <button className="dealer-search-clear" onClick={() => setStockSearch('')}>
                          <X size={12} />
                        </button>
                      )}
                    </div>
                    <div className="dealer-stock-list">
                      {(filteredStock ?? []).length === 0 ? (
                        <div className="dealer-empty">
                          <Package size={32} />
                          <span>{stockSearch ? 'Aucun résultat' : 'Aucun véhicule en stock'}</span>
                        </div>
                      ) : (
                        (filteredStock ?? []).map((s, i) => (
                          <div
                            key={`${s.plate}-${i}`}
                            className={`dealer-stock-item ${!s.available ? 'unavailable' : ''} ${selectedStock?.index === s.index ? 'selected' : ''}`}
                            style={selectedStock?.index === s.index ? { borderColor: `rgba(${accentRgb}, 0.4)` } : undefined}
                            onClick={() => { setSelectedStock(s); setSelectedVehicle(null); setSelectedEmployee(null); }}
                          >
                            <div className="dealer-stock-info">
                              <div className="dealer-stock-name">
                                {!s.available && <span style={{ color: '#f87171' }}>[SORTI] </span>}
                                {s.label}
                              </div>
                              <div className="dealer-stock-meta">
                                <span>{s.plate}</span>
                                <span>{s.colorLabel}</span>
                              </div>
                            </div>
                            <div className="dealer-stock-price" style={{ color: accentColor }}>
                              {formatMoney(s.price)}$
                            </div>
                          </div>
                        ))
                      )}
                    </div>
                  </div>
                )}

                {/* ---- EMPLOYEES sub-tab ---- */}
                {gestionSub === 'employees' && (
                  <div className="dealer-employee-list">
                    {paySuccess && (
                      <div className="dealer-pay-success">
                        <CheckCircle size={16} />
                        <span>Paye versée à <strong>{paySuccess.name}</strong> — {formatMoney(paySuccess.net)}$ net</span>
                      </div>
                    )}
                    {(!data.employees || data.employees.length === 0) ? (
                      <div className="dealer-empty">
                        <Users size={32} />
                        <span>Aucun employé</span>
                      </div>
                    ) : selectedEmployee ? (
                      <div className="dealer-emp-detail">
                        <button className="dealer-back-btn" onClick={() => { setSelectedEmployee(null); setPaySuccess(null); }}>← Retour aux employés</button>

                        <div className="dealer-emp-detail-header">
                          <div className="dealer-emp-avatar" style={{ background: `rgba(${accentRgb}, 0.2)`, color: accentColor }}>
                            {selectedEmployee.firstname[0]}{selectedEmployee.lastname[0]}
                          </div>
                          <div className="dealer-emp-detail-info">
                            <div className="dealer-emp-detail-name">{selectedEmployee.firstname} {selectedEmployee.lastname}</div>
                            <div className="dealer-emp-detail-grade">{selectedEmployee.gradeLabel}</div>
                            <span className={`dealer-emp-online ${selectedEmployee.online ? 'is-online' : ''}`}>
                              {selectedEmployee.online ? '● En ligne' : '○ Hors ligne'}
                            </span>
                          </div>
                        </div>

                        {/* Stats */}
                        {(() => {
                          const stats = getEmployeeStats(selectedEmployee);
                          return (
                            <div className="dealer-emp-stats">
                              <div className="dealer-emp-stat-card">
                                <div className="dealer-emp-stat-icon" style={{ background: `rgba(${accentRgb}, 0.15)`, color: accentColor }}>
                                  <TrendingUp size={16} />
                                </div>
                                <div className="dealer-emp-stat-content">
                                  <span className="dealer-emp-stat-label">Chiffre d'affaires</span>
                                  <span className="dealer-emp-stat-value" style={{ color: accentColor }}>{formatMoney(stats.ca)}$</span>
                                </div>
                              </div>
                              <div className="dealer-emp-stat-card">
                                <div className="dealer-emp-stat-icon" style={{ background: 'rgba(46, 204, 113, 0.15)', color: '#4ade80' }}>
                                  <Building2 size={16} />
                                </div>
                                <div className="dealer-emp-stat-content">
                                  <span className="dealer-emp-stat-label">Part entreprise (10% CA)</span>
                                  <span className="dealer-emp-stat-value" style={{ color: '#4ade80' }}>{formatMoney(stats.companyRevenue)}$</span>
                                </div>
                              </div>
                              <div className="dealer-emp-stat-card">
                                <div className="dealer-emp-stat-icon" style={{ background: 'rgba(251, 191, 36, 0.15)', color: '#fbbf24' }}>
                                  <Banknote size={16} />
                                </div>
                                <div className="dealer-emp-stat-content">
                                  <span className="dealer-emp-stat-label">Salaire net (5% -{data.taxRates?.salaire ?? 10}% imp.)</span>
                                  <span className="dealer-emp-stat-value" style={{ color: '#fbbf24' }}>{formatMoney(stats.netSalary)}$</span>
                                </div>
                              </div>
                            </div>
                          );
                        })()}

                        {/* Pay button */}
                        {(() => {
                          const stats = getEmployeeStats(selectedEmployee);
                          return stats.netSalary > 0 && !paySuccess ? (
                            <button
                              className="dealer-btn dealer-btn-accent dealer-btn-full"
                              style={{ backgroundColor: accentColor, marginBottom: 14 }}
                              onClick={() => handlePayEmployee(selectedEmployee.identifier)}
                            >
                              <Banknote size={15} />
                              Donner sa paye — {formatMoney(stats.netSalary)}$ net
                            </button>
                          ) : paySuccess ? (
                            <div className="dealer-pay-success" style={{ marginBottom: 14 }}>
                              <CheckCircle size={15} />
                              <span>Paye versée — {formatMoney(paySuccess.net)}$ net</span>
                            </div>
                          ) : null;
                        })()}

                        {/* Activity list */}
                        <div className="dealer-emp-sales-title">Activité ({selectedEmployee.sales.length})</div>
                        <div className="dealer-emp-sales">
                          {selectedEmployee.sales.length === 0 ? (
                            <div className="dealer-empty" style={{ padding: '20px 0' }}>
                              <span>Aucune activité enregistrée</span>
                            </div>
                          ) : (
                            selectedEmployee.sales.map((sale, i) => (
                              <div key={i} className="dealer-emp-sale-item">
                                <div className="dealer-emp-sale-info">
                                  <div className="dealer-emp-sale-vehicle">
                                    <span className={`dealer-activity-badge ${sale.type === 'sale' ? 'badge-sale' : 'badge-purchase'}`}>
                                      {sale.type === 'sale' ? 'Vente' : 'Achat stock'}
                                    </span>
                                    {sale.model} — {sale.plate}
                                  </div>
                                  <div className="dealer-emp-sale-meta">
                                    {sale.type === 'sale' ? `Acheteur: ${sale.buyer} · ` : ''}{sale.date}
                                  </div>
                                </div>
                                <div className="dealer-emp-sale-price" style={{ color: sale.type === 'sale' ? '#4ade80' : '#f87171' }}>
                                  {sale.type === 'sale' ? '+' : ''}{formatMoney(sale.price)}$
                                </div>
                              </div>
                            ))
                          )}
                        </div>
                      </div>
                    ) : (
                      data.employees.map(emp => (
                        <div
                          key={emp.identifier}
                          className="dealer-emp-row"
                          onClick={() => { setSelectedEmployee(emp); setPaySuccess(null); }}
                        >
                          <div className="dealer-emp-avatar-sm" style={{ background: `rgba(${accentRgb}, 0.15)`, color: accentColor }}>
                            {emp.firstname[0]}{emp.lastname[0]}
                          </div>
                          <div className="dealer-emp-info">
                            <div className="dealer-emp-name">{emp.firstname} {emp.lastname}</div>
                            <div className="dealer-emp-grade-line">
                              {emp.gradeLabel} · {emp.totalSales} vente{emp.totalSales !== 1 ? 's' : ''}
                              <span className={`dealer-emp-dot ${emp.online ? 'dot-online' : ''}`} />
                            </div>
                          </div>
                          <div className="dealer-emp-ca" style={{ color: accentColor }}>
                            {formatMoney(emp.totalCA)}$
                          </div>
                          <ChevronRight size={14} style={{ color: 'var(--text-tertiary)' }} />
                        </div>
                      ))
                    )}
                  </div>
                )}

                {/* ---- HISTORY sub-tab ---- */}
                {gestionSub === 'history' && (
                  <div className="dealer-history-list">
                    {data.salesHistory.length === 0 ? (
                      <div className="dealer-empty">
                        <History size={32} />
                        <span>Aucune vente enregistrée</span>
                      </div>
                    ) : (
                      data.salesHistory.map((h, i) => (
                        <div key={i} className="dealer-history-item">
                          <div className="dealer-history-info">
                            <div className="dealer-history-vehicle">{h.model} — {h.plate}</div>
                            <div className="dealer-history-meta">
                              Vendeur: {h.seller} · Acheteur: {h.buyer} · {h.date}
                            </div>
                          </div>
                          <div className="dealer-history-price" style={{ color: '#4ade80' }}>
                            {formatMoney(h.price)}$
                          </div>
                        </div>
                      ))
                    )}
                  </div>
                )}

                {/* ---- SHOWROOM sub-tab ---- */}
                {gestionSub === 'showroom' && canBoss && (
                  <div className="dealer-showroom-section">
                    <div className="dealer-showroom-header">
                      <Monitor size={15} />
                      <span>{data.showroomTitle || 'Showroom'}</span>
                    </div>

                    {(data.showroomSlots || []).map(slot => {
                      const assigned = showroomData[slot.key];
                      const isSelected = showroomSlot === slot.key;

                      return (
                        <div key={slot.key} className={`dealer-showroom-slot ${isSelected ? 'slot-selected' : ''}`}
                          style={isSelected ? { borderColor: `rgba(${accentRgb}, 0.5)`, background: `rgba(${accentRgb}, 0.06)` } : undefined}>
                          <div className="dealer-showroom-slot-header">
                            <span className="dealer-showroom-slot-label">{slot.label}</span>
                            {assigned ? (
                              <button className="dealer-showroom-clear-btn"
                                title="Vider l'emplacement"
                                onClick={() => {
                                  fetch(`https://${GetParentResourceName()}/dealership:setShowroomVehicle`, {
                                    method: 'POST', body: JSON.stringify({ slotKey: slot.key, stockIndex: null })
                                  });
                                  setShowroomSlot(null);
                                }}>
                                <Trash2 size={12} />
                              </button>
                            ) : null}
                          </div>

                          {assigned ? (
                            <div className="dealer-showroom-assigned">
                              <div className="dealer-showroom-assigned-info">
                                <span className="dealer-showroom-model">{assigned.model}</span>
                                <span className="dealer-showroom-plate">{assigned.plate}</span>
                              </div>
                              <span className="dealer-showroom-price" style={{ color: accentColor }}>
                                {formatMoney(Math.floor(assigned.price * saleMargin))}$
                              </span>
                            </div>
                          ) : (
                            <div className="dealer-showroom-empty-slot">
                              <span>Aucun véhicule</span>
                              <button
                                className="dealer-btn dealer-btn-outline"
                                style={{ fontSize: 11, padding: '4px 10px' }}
                                onClick={() => setShowroomSlot(isSelected ? null : slot.key)}
                              >
                                {isSelected ? 'Annuler' : 'Choisir'}
                              </button>
                            </div>
                          )}

                          {isSelected && !assigned && (
                            <div className="dealer-showroom-picker">
                              <div className="dealer-showroom-picker-title">Choisir dans le stock :</div>
                              {data.stock.length === 0 ? (
                                <div className="dealer-showroom-no-stock">Stock vide</div>
                              ) : (
                                data.stock.map(s => (
                                  <div key={s.index} className="dealer-showroom-pick-item"
                                    onClick={() => {
                                      fetch(`https://${GetParentResourceName()}/dealership:setShowroomVehicle`, {
                                        method: 'POST', body: JSON.stringify({ slotKey: slot.key, stockIndex: s.index })
                                      });
                                      setShowroomSlot(null);
                                    }}>
                                    <div className="dealer-showroom-pick-info">
                                      <span className="dealer-showroom-pick-label">{s.label}</span>
                                      <span className="dealer-showroom-pick-plate">{s.plate} · {s.colorLabel}</span>
                                    </div>
                                    <span className="dealer-showroom-pick-price" style={{ color: accentColor }}>
                                      {formatMoney(Math.floor(s.price * saleMargin))}$
                                    </span>
                                  </div>
                                ))
                              )}
                            </div>
                          )}

                          {assigned && (
                            <button
                              className="dealer-btn dealer-btn-outline dealer-btn-full"
                              style={{ marginTop: 8, fontSize: 11 }}
                              onClick={() => setShowroomSlot(isSelected ? null : slot.key)}
                            >
                              {isSelected ? 'Annuler' : 'Changer de véhicule'}
                            </button>
                          )}

                          {isSelected && assigned && (
                            <div className="dealer-showroom-picker">
                              <div className="dealer-showroom-picker-title">Remplacer par :</div>
                              {data.stock.length === 0 ? (
                                <div className="dealer-showroom-no-stock">Stock vide</div>
                              ) : (
                                data.stock.map(s => (
                                  <div key={s.index} className="dealer-showroom-pick-item"
                                    onClick={() => {
                                      fetch(`https://${GetParentResourceName()}/dealership:setShowroomVehicle`, {
                                        method: 'POST', body: JSON.stringify({ slotKey: slot.key, stockIndex: s.index })
                                      });
                                      setShowroomSlot(null);
                                    }}>
                                    <div className="dealer-showroom-pick-info">
                                      <span className="dealer-showroom-pick-label">{s.label}</span>
                                      <span className="dealer-showroom-pick-plate">{s.plate} · {s.colorLabel}</span>
                                    </div>
                                    <span className="dealer-showroom-pick-price" style={{ color: accentColor }}>
                                      {formatMoney(Math.floor(s.price * saleMargin))}$
                                    </span>
                                  </div>
                                ))
                              )}
                            </div>
                          )}
                        </div>
                      );
                    })}
                  </div>
                )}

                {/* ---- SOCIETY sub-tab ---- */}
                {gestionSub === 'society' && (
                  <div className="dealer-settings">
                    <div className="dealer-setting-card">
                      <div className="dealer-setting-header">
                        <span className="dealer-setting-title">Gestion de société</span>
                      </div>
                      <span className="dealer-setting-desc">
                        Gérer les employés, grades et finances
                      </span>
                      <button
                        className="dealer-btn dealer-btn-outline dealer-btn-full"
                        style={{ marginTop: 10 }}
                        onClick={handleSocietyMenu}
                      >
                        <Landmark size={14} />
                        Ouvrir la gestion
                      </button>
                    </div>
                  </div>
                )}
              </>
            )}

            <div className="dealer-footer">
              <span>{data.mode === 'public' ? 'Client' : data.playerJob}</span>
              <span className="dealer-footer-type">
                {TYPE_ICONS[data.shopType]} {TYPE_LABELS[data.shopType]}
              </span>
            </div>
          </div>

          {/* Right panel — detail */}
          <div className={`dealer-right ${(selectedVehicle || selectedStock) ? 'has-vehicle' : ''}`}>
            {selectedVehicle ? (
              <div className="dealer-detail">
                <div className="dealer-detail-image">
                  {renderVehicleImage(selectedVehicle.model)}
                </div>

                <div className="dealer-detail-header">
                  <div className="dealer-detail-category">
                    {TYPE_ICONS[data.shopType]}
                    <span>{selectedVehicle.category}</span>
                  </div>
                </div>

                <h3 className="dealer-detail-title">{selectedVehicle.label}</h3>
                <span className="dealer-detail-model">{selectedVehicle.model}</span>

                <div className="dealer-detail-infos">
                  <div className="dealer-detail-info-row">
                    <DollarSign size={13} />
                    <span className="dealer-detail-info-label">Prix de vente client</span>
                    <span className="dealer-detail-info-value" style={{ color: '#3b82f6' }}>
                      {formatMoney(selectedVehicle.salePrice ?? Math.floor(selectedVehicle.price * saleMargin))}$
                    </span>
                  </div>
                  {canSell && (
                    <div className="dealer-detail-info-row">
                      <Package size={13} />
                      <span className="dealer-detail-info-label">Coût restock</span>
                      <span className="dealer-detail-info-value" style={{ color: '#fbbf24' }}>
                        {formatMoney(Math.floor(selectedVehicle.price * restockPct))}$
                      </span>
                    </div>
                  )}
                  <div className="dealer-detail-info-row">
                    <Tag size={13} />
                    <span className="dealer-detail-info-label">Catégorie</span>
                    <span className="dealer-detail-info-value">{selectedVehicle.category}</span>
                  </div>
                  {canSell && stockCounts[selectedVehicle.model] > 0 && (
                    <div className="dealer-detail-info-row">
                      <Package size={13} />
                      <span className="dealer-detail-info-label">En stock</span>
                      <span className="dealer-detail-info-value" style={{ color: '#4ade80' }}>
                        {stockCounts[selectedVehicle.model]}
                      </span>
                    </div>
                  )}
                </div>

                {/* Color picker */}
                <div style={{ marginBottom: 12 }}>
                  <div style={{ fontSize: 11, fontWeight: 600, color: 'var(--text-secondary)', marginBottom: 6, display: 'flex', alignItems: 'center', gap: 6 }}>
                    <Palette size={12} /> Couleur: {data.colors[selectedColor]?.label}
                  </div>
                  <div className="dealer-colors">
                    {data.colors.map((c, i) => (
                      <button
                        key={c.id}
                        className={`dealer-color-btn ${selectedColor === i ? 'active' : ''}`}
                        style={{ background: getColorHex(c.name) }}
                        onClick={() => setSelectedColor(i)}
                        title={c.label}
                      />
                    ))}
                  </div>
                </div>

                <div className="dealer-detail-actions">
                  {/* Preview only in public mode */}
                  {isPublic && (
                    <button
                      className="dealer-btn dealer-btn-outline dealer-btn-full"
                      onClick={() => handlePreview(selectedVehicle.model, currentColorId)}
                    >
                      <Eye size={15} />
                      Aperçu
                    </button>
                  )}

                  {canSell && (
                    <button
                      className="dealer-btn dealer-btn-accent dealer-btn-full"
                      style={{ backgroundColor: accentColor }}
                      onClick={() => handleBuyForStock(selectedVehicle.model, selectedVehicle.price, currentColorId)}
                    >
                      <Package size={15} />
                      Acheter pour le stock — {formatMoney(Math.floor(selectedVehicle.price * restockPct))}$
                    </button>
                  )}
                </div>
              </div>
            ) : selectedStock ? (
              <div className="dealer-detail">
                <div className="dealer-detail-image">
                  {renderVehicleImage(selectedStock.model)}
                </div>

                <h3 className="dealer-detail-title">{selectedStock.label}</h3>
                <span className="dealer-detail-model">{selectedStock.model}</span>

                <div className="dealer-detail-infos">
                  <div className="dealer-detail-info-row">
                    <Tag size={13} />
                    <span className="dealer-detail-info-label">Plaque</span>
                    <span className="dealer-detail-info-value">{selectedStock.plate}</span>
                  </div>
                  <div className="dealer-detail-info-row">
                    <Palette size={13} />
                    <span className="dealer-detail-info-label">Couleur</span>
                    <span className="dealer-detail-info-value">{selectedStock.colorLabel}</span>
                  </div>
                  <div className="dealer-detail-info-row">
                    <DollarSign size={13} />
                    <span className="dealer-detail-info-label">Prix vente</span>
                    <span className="dealer-detail-info-value" style={{ color: accentColor }}>
                      {formatMoney(selectedStock.price)}$
                    </span>
                  </div>
                </div>

                <div className="dealer-detail-actions">
                  {selectedStock.available && (
                    <>
                      <button
                        className="dealer-btn dealer-btn-outline dealer-btn-full"
                        onClick={() => handleStockPreview(selectedStock.index)}
                      >
                        <Eye size={15} />
                        Aperçu
                      </button>

                      <button
                        className="dealer-btn dealer-btn-accent dealer-btn-full"
                        style={{ backgroundColor: accentColor }}
                        onClick={() => handleSellToPlayer(selectedStock.index)}
                      >
                        <UserPlus size={15} />
                        Vendre au client le plus proche
                      </button>
                    </>
                  )}
                  {!selectedStock.available && (
                    <div className="dealer-badge dealer-badge-nostock" style={{ justifyContent: 'center', padding: 10 }}>
                      Véhicule déjà sorti
                    </div>
                  )}
                </div>
              </div>
            ) : (
              <div className="dealer-detail-empty">
                {TYPE_ICONS_LG[data.shopType]}
                <span>Sélectionnez un véhicule</span>
              </div>
            )}
          </div>
        </div>

        {actionFeedback && (
          <div className="dealer-toast">{actionFeedback}</div>
        )}
      </div>
    </div>
  );
};

export default Dealership;
