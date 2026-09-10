import React, { useState, useEffect, useCallback, useRef, useMemo } from 'react';
import { hexToRgb, hexToRgba } from '@utils/color';
import { generateAccentVars, hexToRgba as accentRgba } from '@/utils/accentColors';
import {
  Home, Users, Shield, DollarSign, Settings, Building2,
  ChevronRight, X, Search, TrendingUp, TrendingDown,
  UserMinus, ArrowUp, ArrowDown, Banknote,
  History, Pencil, Save, Plus, Trash2, MapPin, UserPlus,
  Zap, Power, PowerOff, CheckCircle2, XCircle,
  Landmark, Percent, Wine, Heart, Info,
  BadgeDollarSign, ArrowUpDown, FileText, RefreshCw,
  Crown, Briefcase, Clock, Store
} from 'lucide-react';
import {
  SocietyData, SocietyPage, SocietyEmployee, SocietyGrade,
  SocietyTabletProps, SocietyEnterprise, PropertyData
} from './types';
import './SocietyTablet.css';

const GetParentResourceName = () => 'null-core';

const SocietyTablet: React.FC<SocietyTabletProps> = ({ visible, onClose, primaryColor }) => {
  const [currentPage, setCurrentPage] = useState<SocietyPage>('home');
  const [data, setData] = useState<SocietyData | null>(null);
  const [hiding, setHiding] = useState(false);
  const [pageTransition, setPageTransition] = useState(false);
  const [notification, setNotification] = useState<{ message: string; type: 'success' | 'error' } | null>(null);
  const [employeeSearch, setEmployeeSearch] = useState('');
  const [selectedEmployee, setSelectedEmployee] = useState<SocietyEmployee | null>(null);
  const [selectedGrade, setSelectedGrade] = useState<SocietyGrade | null>(null);
  const [editingSalaryType, setEditingSalaryType] = useState<'mensuel' | '30min' | null>(null);
  const [salaryInput, setSalaryInput] = useState('');
  const [financeTab, setFinanceTab] = useState<'manage' | 'history'>('manage');
  const [moneyType, setMoneyType] = useState<'cash' | 'dirtycash'>('cash');
  const [moneyAmount, setMoneyAmount] = useState('');
  const [historyFilter, setHistoryFilter] = useState<'all' | 'income' | 'expense'>('all');
  const [historySearch, setHistorySearch] = useState('');
  const [launderAmount, setLaunderAmount] = useState('');
  const [drinkQuantities, setDrinkQuantities] = useState<Record<string, number>>({});
  const [healQuantities, setHealQuantities] = useState<Record<string, number>>({});
  const [selectedEnterprise, setSelectedEnterprise] = useState<SocietyEnterprise | null>(null);
  const [govTab, setGovTab] = useState<'enterprises' | 'economy' | 'city'>('enterprises');
  const [creatingGrade, setCreatingGrade] = useState(false);
  const [newGradeName, setNewGradeName] = useState('');
  const [newGradeLabel, setNewGradeLabel] = useState('');
  const [newGradeSalary, setNewGradeSalary] = useState('');
  const [newGradeMensuel, setNewGradeMensuel] = useState('');
  const [editingGradeMeta, setEditingGradeMeta] = useState(false);
  const [editGradeName, setEditGradeName] = useState('');
  const [editGradeLabel, setEditGradeLabel] = useState('');
  const [confirmDeleteGrade, setConfirmDeleteGrade] = useState<number | null>(null);
  const [customHistorySearch, setCustomHistorySearch] = useState('');
  const [selectedProperty, setSelectedProperty] = useState<PropertyData | null>(null);
  const notifTimer = useRef<ReturnType<typeof setTimeout> | null>(null);

  const accent = primaryColor || '#3b82f6';
  const accentRgb = hexToRgb(accent);
  const stAccentVars = useMemo(() => generateAccentVars('--st-accent', accent), [accent]);

  const showNotification = useCallback((message: string, type: 'success' | 'error') => {
    if (notifTimer.current) clearTimeout(notifTimer.current);
    setNotification({ message, type });
    notifTimer.current = setTimeout(() => setNotification(null), 3000);
  }, []);

  const nuiCallback = useCallback(async (event: string, body: any = {}) => {
    try {
      const resp = await fetch(`https://${GetParentResourceName()}/${event}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(body),
      });
      return await resp.json();
    } catch {
      return null;
    }
  }, []);

  useEffect(() => {
    const handler = (event: MessageEvent) => {
      const { action, data: payload } = event.data;
      if (action === 'societyTablet:setData') {
        setData(payload);
      } else if (action === 'societyTablet:updateAccounts') {
        setData(prev => prev ? { ...prev, accounts: payload } : prev);
      } else if (action === 'societyTablet:updateHistory') {
        setData(prev => prev ? { ...prev, history: payload } : prev);
      } else if (action === 'societyTablet:updateEmployees') {
        setData(prev => prev ? { ...prev, employees: payload, employeeCount: payload.length } : prev);
      } else if (action === 'societyTablet:updateGrades') {
        setData(prev => prev ? { ...prev, grades: payload } : prev);
      } else if (action === 'societyTablet:notification') {
        showNotification(payload.message, payload.type);
      } else if (action === 'societyTablet:updateEnterprises') {
        setData(prev => prev ? { ...prev, enterprises: payload } : prev);
      } else if (action === 'societyTablet:updateSalary') {
        setData(prev => prev ? { ...prev, salaryData: payload } : prev);
      } else if (action === 'societyTablet:updateTaxes') {
        setData(prev => prev ? { ...prev, taxesData: payload } : prev);
      } else if (action === 'societyTablet:updateCustomHistory') {
        setData(prev => prev ? { ...prev, customHistory: payload } : prev);
      } else if (action === 'societyTablet:updateProperties') {
        setData(prev => prev ? { ...prev, properties: payload } : prev);
      }
    };
    window.addEventListener('message', handler);
    return () => window.removeEventListener('message', handler);
  }, [showNotification]);

  const handleClose = useCallback(() => {
    setHiding(true);
    setTimeout(() => {
      setHiding(false);
      setCurrentPage('home');
      setData(null);
      setSelectedEmployee(null);
      setSelectedGrade(null);
      setSelectedEnterprise(null);
      setCreatingGrade(false);
      setSelectedProperty(null);
      onClose();
      nuiCallback('societyTablet:close');
    }, 300);
  }, [onClose, nuiCallback]);

  useEffect(() => {
    const handler = (e: KeyboardEvent) => {
      if (e.key === 'Escape' && visible) handleClose();
    };
    window.addEventListener('keydown', handler);
    return () => window.removeEventListener('keydown', handler);
  }, [visible, handleClose]);

  const navigateTo = useCallback((page: SocietyPage) => {
    setPageTransition(true);
    setTimeout(() => {
      setCurrentPage(page);
      setSelectedEmployee(null);
      setSelectedGrade(null);
      setSelectedEnterprise(null);
      setCreatingGrade(false);
      setEditingGradeMeta(false);
      setConfirmDeleteGrade(null);
      setSelectedProperty(null);
      setPageTransition(false);
    }, 150);
  }, []);

  if (!visible || !data) return null;

  const PAGES: { id: SocietyPage; label: string; icon: React.ReactNode; bossOnly?: boolean; govOnly?: boolean; mecanoOnly?: boolean; realEstateOnly?: boolean; nonGovOnly?: boolean }[] = [
    { id: 'home', label: 'Accueil', icon: <Home size={18} /> },
    { id: 'employees', label: 'Employés', icon: <Users size={18} />, bossOnly: true },
    { id: 'grades', label: 'Grades', icon: <Shield size={18} />, bossOnly: true },
    { id: 'finances', label: 'Finances', icon: <DollarSign size={18} />, bossOnly: true },
    { id: 'settings', label: 'Paramètres', icon: <Settings size={18} />, bossOnly: true },
    { id: 'cityinfo', label: 'Info Ville', icon: <Info size={18} />, bossOnly: true, nonGovOnly: true },
    { id: 'properties', label: 'Propriétés', icon: <MapPin size={18} />, realEstateOnly: true },
    { id: 'government', label: 'Gouvernement', icon: <Building2 size={18} />, govOnly: true },
  ];

  const visiblePages = PAGES.filter(p => {
    if (p.govOnly) return data.isGovernment && data.isBoss;
    if (p.nonGovOnly) return !data.isGovernment && data.isBoss;
    if (p.mecanoOnly) return data.isMecano && data.isBoss;
    if (p.realEstateOnly) return data.isRealEstate && data.isBoss;
    if (p.bossOnly) return data.isBoss;
    return true;
  });

  const formatMoney = (amount: number) => {
    return amount.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ' ') + '$';
  };

  const handleFireEmployee = async (emp: SocietyEmployee) => {
    const result = await nuiCallback('societyTablet:fireEmployee', { identifier: emp.identifier, idunique: emp.idunique });
    if (result?.success) {
      showNotification(`${emp.firstname} ${emp.lastname} a été viré(e)`, 'success');
      setSelectedEmployee(null);
    } else {
      showNotification(result?.message || 'Erreur', 'error');
    }
  };

  const handlePromoteEmployee = async (emp: SocietyEmployee) => {
    const result = await nuiCallback('societyTablet:promoteEmployee', { identifier: emp.identifier, idunique: emp.idunique, job_grade: emp.job_grade });
    if (result?.success) {
      showNotification(`${emp.firstname} ${emp.lastname} a été promu(e)`, 'success');
    } else {
      showNotification(result?.message || 'Impossible de promouvoir', 'error');
    }
  };

  const handleDemoteEmployee = async (emp: SocietyEmployee) => {
    const result = await nuiCallback('societyTablet:demoteEmployee', { identifier: emp.identifier, idunique: emp.idunique, job_grade: emp.job_grade });
    if (result?.success) {
      showNotification(`${emp.firstname} ${emp.lastname} a été rétrogradé(e)`, 'success');
    } else {
      showNotification(result?.message || 'Impossible de rétrograder', 'error');
    }
  };

  const handleEditSalary = async () => {
    if (!selectedGrade || !editingSalaryType || !salaryInput) return;
    const amount = parseInt(salaryInput);
    if (isNaN(amount)) return showNotification('Montant invalide', 'error');
    const result = await nuiCallback('societyTablet:editGradeSalary', {
      grade: selectedGrade.grade,
      amount,
      type: editingSalaryType === 'mensuel' ? 'Mensuel' : 'Pour 30 Min',
    });
    if (result?.success) {
      showNotification('Salaire modifié', 'success');
      setEditingSalaryType(null);
      setSalaryInput('');
    } else {
      showNotification(result?.message || 'Erreur', 'error');
    }
  };

  const handleDeposit = async () => {
    const amount = parseInt(moneyAmount);
    if (isNaN(amount) || amount <= 0) return showNotification('Montant invalide', 'error');
    const result = await nuiCallback('societyTablet:deposit', { moneyType, amount });
    if (result?.success) {
      showNotification(`${formatMoney(amount)} déposé(s)`, 'success');
      setMoneyAmount('');
    } else {
      showNotification(result?.message || 'Erreur', 'error');
    }
  };

  const handleWithdraw = async () => {
    const amount = parseInt(moneyAmount);
    if (isNaN(amount) || amount <= 0) return showNotification('Montant invalide', 'error');
    const result = await nuiCallback('societyTablet:withdraw', { moneyType, amount });
    if (result?.success) {
      showNotification(`${formatMoney(amount)} retiré(s)`, 'success');
      setMoneyAmount('');
    } else {
      showNotification(result?.message || 'Erreur', 'error');
    }
  };

  const handleRename = async () => {
    const result = await nuiCallback('societyTablet:rename', {});
    if (result?.success) showNotification('Nom modifié', 'success');
  };

  const handleLaunder = async () => {
    const amount = parseInt(launderAmount);
    if (isNaN(amount) || amount <= 0) return showNotification('Montant invalide', 'error');
    const result = await nuiCallback('societyTablet:launder', { amount });
    if (result?.success) {
      showNotification(result.message || 'Blanchiment effectué', 'success');
      setLaunderAmount('');
    } else {
      showNotification(result?.message || 'Erreur', 'error');
    }
  };

  const handleBuyDrink = async (value: string, name: string, price: number) => {
    const qty = drinkQuantities[value] || 1;
    const result = await nuiCallback('societyTablet:buyDrink', { value, name, price: price * qty, count: qty });
    if (result?.success) {
      showNotification(`${qty}x ${name} acheté(s)`, 'success');
    } else {
      showNotification(result?.message || 'Erreur', 'error');
    }
  };

  const handleBuyHeal = async (value: string, name: string, price: number) => {
    const qty = healQuantities[value] || 1;
    const result = await nuiCallback('societyTablet:buyHeal', { value, name, price: price * qty, count: qty });
    if (result?.success) {
      showNotification(`${qty}x ${name} acheté(s)`, 'success');
    } else {
      showNotification(result?.message || 'Erreur', 'error');
    }
  };

  const handleTogglePolitique = async (key: string, value: boolean) => {
    await nuiCallback('societyTablet:togglePolitique', { key, value: !value });
  };

  const handleChangeEnterpriseName = async (enterprise: SocietyEnterprise) => {
    const result = await nuiCallback('societyTablet:govRenameSociety', { name: enterprise.name });
    if (result?.success) showNotification('Nom modifié', 'success');
  };

  const handleChangeSalary = async (type: string, subtype: string) => {
    const result = await nuiCallback('societyTablet:govChangeSalary', { salaryType: type, subType: subtype });
    if (result?.success) showNotification('Salaire modifié', 'success');
  };

  const handleChangeTax = async (taxType: string) => {
    const result = await nuiCallback('societyTablet:govChangeTax', { taxType });
    if (result?.success) showNotification('Taxe modifiée', 'success');
  };

  const handleToggleElectricity = async () => {
    const result = await nuiCallback('societyTablet:govToggleElectricity', {});
    if (result?.success) showNotification('Électricité modifiée', 'success');
  };

  const handleGovTogglePolitique = async (enterprise: SocietyEnterprise, key: string, value: boolean) => {
    await nuiCallback('societyTablet:govTogglePolitique', { societyName: enterprise.name, key, value: !value });
  };

  const handleCreateGrade = async () => {
    if (!newGradeName.trim() || !newGradeLabel.trim()) return showNotification('Nom et label requis', 'error');
    const salary = parseInt(newGradeSalary) || 0;
    const mensuel = parseInt(newGradeMensuel) || 0;
    const result = await nuiCallback('societyTablet:createGrade', {
      name: newGradeName.trim(),
      label: newGradeLabel.trim(),
      salary,
      mensuelpay: mensuel,
    });
    if (result?.success) {
      showNotification('Grade créé', 'success');
      setCreatingGrade(false);
      setNewGradeName('');
      setNewGradeLabel('');
      setNewGradeSalary('');
      setNewGradeMensuel('');
    } else {
      showNotification(result?.message || 'Erreur', 'error');
    }
  };

  const handleDeleteGrade = async (grade: number) => {
    const result = await nuiCallback('societyTablet:deleteGrade', { grade });
    if (result?.success) {
      showNotification('Grade supprimé', 'success');
      setConfirmDeleteGrade(null);
      setSelectedGrade(null);
    } else {
      showNotification(result?.message || 'Erreur', 'error');
    }
  };

  const handleEditGradeMeta = async () => {
    if (!selectedGrade || !editGradeName.trim() || !editGradeLabel.trim()) return showNotification('Champs requis', 'error');
    const result = await nuiCallback('societyTablet:editGradeMeta', {
      grade: selectedGrade.grade,
      name: editGradeName.trim(),
      label: editGradeLabel.trim(),
    });
    if (result?.success) {
      showNotification('Grade modifié', 'success');
      setEditingGradeMeta(false);
    } else {
      showNotification(result?.message || 'Erreur', 'error');
    }
  };

  const handleRecruitEmployee = async () => {
    const result = await nuiCallback('societyTablet:recruitEmployee', {});
    if (result?.success) {
      showNotification('Employé recruté', 'success');
    } else {
      showNotification(result?.message || 'Aucun joueur à proximité', 'error');
    }
  };

  const handleDeleteProperty = async (prop: PropertyData) => {
    const result = await nuiCallback('societyTablet:deleteProperty', { id: prop.id, name: prop.name });
    if (result?.success) {
      showNotification('Propriété supprimée', 'success');
      setSelectedProperty(null);
    } else {
      showNotification(result?.message || 'Erreur', 'error');
    }
  };

  const handleEvictProperty = async (prop: PropertyData) => {
    const result = await nuiCallback('societyTablet:evictProperty', { id: prop.id, name: prop.name });
    if (result?.success) {
      showNotification('Propriétaire viré', 'success');
    } else {
      showNotification(result?.message || 'Erreur', 'error');
    }
  };

  const handleAssignProperty = async (prop: PropertyData, toSelf: boolean) => {
    const result = await nuiCallback('societyTablet:assignProperty', { id: prop.id, name: prop.name, toSelf });
    if (result?.success) {
      showNotification('Propriété attribuée', 'success');
    } else {
      showNotification(result?.message || 'Erreur', 'error');
    }
  };

  const handleLoadCustomHistory = async () => {
    await nuiCallback('societyTablet:loadCustomHistory', {});
  };

  const handleLoadProperties = async () => {
    await nuiCallback('societyTablet:loadProperties', {});
  };

  const filteredEmployees = data.employees.filter(emp => {
    if (!employeeSearch) return true;
    const s = employeeSearch.toLowerCase();
    return emp.firstname.toLowerCase().includes(s) || emp.lastname.toLowerCase().includes(s) || emp.name.toLowerCase().includes(s) || emp.idunique.toLowerCase().includes(s) || (emp.gradeLabel || '').toLowerCase().includes(s);
  });

  const filteredHistory = data.history.filter(entry => {
    if (historyFilter === 'income' && entry.count <= 0) return false;
    if (historyFilter === 'expense' && entry.count >= 0) return false;
    if (historySearch) {
      const s = historySearch.toLowerCase();
      return entry.label.toLowerCase().includes(s) || entry.info.toLowerCase().includes(s);
    }
    return true;
  });

  const renderHome = () => (
    <div className="st-page st-home">
      <div className="st-page-header">
        <h2>Accueil</h2>
        <span className="st-page-subtitle">Vue d'ensemble de votre entreprise</span>
      </div>
      <div className="st-home-cards">
        <div className="st-card st-card-main">
          <div className="st-card-icon" style={{ background: hexToRgba(accent, 0.2) }}>
            <Briefcase size={24} style={{ color: accent }} />
          </div>
          <div className="st-card-content">
            <span className="st-card-label">Entreprise</span>
            <span className="st-card-value">{data.societyLabel}</span>
            <span className="st-card-sub">{data.societyName}</span>
          </div>
          <div className={`st-status-badge ${data.state ? 'st-online' : 'st-offline'}`}>
            {data.state ? <><Power size={12} /> Ouverte</> : <><PowerOff size={12} /> Fermée</>}
          </div>
        </div>
        <div className="st-card">
          <div className="st-card-icon" style={{ background: accentRgba('#22c55e', 20) }}>
            <Banknote size={24} style={{ color: '#22c55e' }} />
          </div>
          <div className="st-card-content">
            <span className="st-card-label">Argent</span>
            <span className="st-card-value">{formatMoney(data.accounts.cash)}</span>
          </div>
        </div>
        <div className="st-card">
          <div className="st-card-icon" style={{ background: accentRgba('#ef4444', 20) }}>
            <BadgeDollarSign size={24} style={{ color: '#ef4444' }} />
          </div>
          <div className="st-card-content">
            <span className="st-card-label">Argent sale</span>
            <span className="st-card-value">{formatMoney(data.accounts.dirtycash)}</span>
          </div>
        </div>
        <div className="st-card">
          <div className="st-card-icon" style={{ background: accentRgba('#a855f7', 20) }}>
            <Users size={24} style={{ color: '#a855f7' }} />
          </div>
          <div className="st-card-content">
            <span className="st-card-label">Employés</span>
            <span className="st-card-value">{data.employeeCount}</span>
          </div>
        </div>
        <div className="st-card">
          <div className="st-card-icon" style={{ background: accentRgba('#f59e0b', 20) }}>
            <Crown size={24} style={{ color: '#f59e0b' }} />
          </div>
          <div className="st-card-content">
            <span className="st-card-label">Votre grade</span>
            <span className="st-card-value">{data.playerGradeLabel}</span>
          </div>
        </div>
        <div className="st-card">
          <div className="st-card-icon" style={{ background: accentRgba('#06b6d4', 20) }}>
            <Shield size={24} style={{ color: '#06b6d4' }} />
          </div>
          <div className="st-card-content">
            <span className="st-card-label">Nombre de grades</span>
            <span className="st-card-value">{data.grades.length}</span>
          </div>
        </div>
      </div>
      {data.isBoss && (
        <div className="st-home-quick-actions">
          <h3>Actions rapides</h3>
          <div className="st-quick-grid">
            <button className="st-quick-btn" onClick={() => navigateTo('employees')}><Users size={16} /> Gérer les employés</button>
            <button className="st-quick-btn" onClick={() => navigateTo('finances')}><DollarSign size={16} /> Gérer les finances</button>
            <button className="st-quick-btn" onClick={() => navigateTo('grades')}><Shield size={16} /> Gérer les grades</button>
            <button className="st-quick-btn" onClick={() => navigateTo('settings')}><Settings size={16} /> Paramètres</button>
          </div>
        </div>
      )}
    </div>
  );

  const renderEmployees = () => (
    <div className="st-page st-employees">
      <div className="st-page-header">
        <h2>Gestion des employés</h2>
        <span className="st-page-subtitle">{data.employeeCount} employé(s)</span>
      </div>
      {!data.isJob2 && (
        <button className="st-action-btn st-recruit-btn" onClick={handleRecruitEmployee} style={{ marginBottom: 12 }}>
          <UserPlus size={16} /> Recruter le joueur le plus proche
        </button>
      )}
      <div className="st-search-bar">
        <Search size={16} />
        <input type="text" placeholder="Rechercher un employé..." value={employeeSearch} onChange={e => setEmployeeSearch(e.target.value)} />
        {employeeSearch && <X size={14} className="st-search-clear" onClick={() => setEmployeeSearch('')} />}
      </div>
      {selectedEmployee ? (
        <div className="st-employee-detail">
          <button className="st-back-btn" onClick={() => setSelectedEmployee(null)}>← Retour à la liste</button>
          <div className="st-detail-header">
            <div className="st-detail-avatar" style={{ background: hexToRgba(accent, 0.3) }}>
              {selectedEmployee.firstname[0]}{selectedEmployee.lastname[0]}
            </div>
            <div className="st-detail-info">
              <h3>{selectedEmployee.firstname} {selectedEmployee.lastname}</h3>
              <span className="st-detail-sub">ID: {selectedEmployee.idunique} · {selectedEmployee.gradeLabel}</span>
              <span className={`st-online-badge ${selectedEmployee.online ? 'st-is-online' : ''}`}>
                {selectedEmployee.online ? '● En ligne' : '○ Hors ligne'}
              </span>
            </div>
          </div>
          <div className="st-detail-actions">
            <button className="st-action-btn st-promote" onClick={() => handlePromoteEmployee(selectedEmployee)}><ArrowUp size={16} /> Promouvoir</button>
            <button className="st-action-btn st-demote" onClick={() => handleDemoteEmployee(selectedEmployee)}><ArrowDown size={16} /> Rétrograder</button>
            <button className="st-action-btn st-fire" onClick={() => handleFireEmployee(selectedEmployee)}><UserMinus size={16} /> Licencier</button>
          </div>
        </div>
      ) : (
        <div className="st-employee-list">
          {filteredEmployees.length === 0 ? (
            <div className="st-empty">Aucun employé trouvé</div>
          ) : filteredEmployees.map(emp => (
            <div key={emp.idunique} className="st-employee-row" onClick={() => setSelectedEmployee(emp)}>
              <div className="st-emp-avatar" style={{ background: hexToRgba(accent, 0.2) }}>
                {emp.firstname[0]}{emp.lastname[0]}
              </div>
              <div className="st-emp-info">
                <span className="st-emp-name">{emp.firstname} {emp.lastname}</span>
                <span className="st-emp-grade">{emp.gradeLabel} · U{emp.idunique}</span>
              </div>
              <div className="st-emp-right">
                <span className={`st-online-dot ${emp.online ? 'st-dot-online' : ''}`} />
                <ChevronRight size={14} />
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );

  const renderGrades = () => (
    <div className="st-page st-grades">
      <div className="st-page-header">
        <h2>Gestion des grades</h2>
        <span className="st-page-subtitle">{data.grades.length} grade(s) · Max {data.maxGrades || 8}</span>
      </div>
      {creatingGrade ? (
        <div className="st-grade-create">
          <button className="st-back-btn" onClick={() => setCreatingGrade(false)}>← Annuler</button>
          <h3 className="st-section-title"><Plus size={16} /> Créer un nouveau grade</h3>
          <div className="st-form-grid">
            <div className="st-form-group">
              <label>Nom interne</label>
              <input type="text" placeholder="ex: manager" value={newGradeName} onChange={e => setNewGradeName(e.target.value)} />
            </div>
            <div className="st-form-group">
              <label>Label affiché</label>
              <input type="text" placeholder="ex: Manager" value={newGradeLabel} onChange={e => setNewGradeLabel(e.target.value)} />
            </div>
            <div className="st-form-group">
              <label>Salaire / 30 Min</label>
              <input type="number" placeholder="0" value={newGradeSalary} onChange={e => setNewGradeSalary(e.target.value)} />
            </div>
            <div className="st-form-group">
              <label>Salaire Mensuel</label>
              <input type="number" placeholder="0" value={newGradeMensuel} onChange={e => setNewGradeMensuel(e.target.value)} />
            </div>
          </div>
          <button className="st-action-btn st-promote" onClick={handleCreateGrade} style={{ marginTop: 12 }}>
            <Plus size={16} /> Créer le grade
          </button>
        </div>
      ) : selectedGrade ? (
        <div className="st-grade-detail">
          <button className="st-back-btn" onClick={() => { setSelectedGrade(null); setEditingSalaryType(null); setEditingGradeMeta(false); setConfirmDeleteGrade(null); }}>← Retour à la liste</button>
          <div className="st-detail-header">
            <div className="st-detail-avatar" style={{ background: hexToRgba(accent, 0.3) }}>
              <Shield size={20} style={{ color: accent }} />
            </div>
            <div className="st-detail-info">
              <h3>{selectedGrade.label}</h3>
              <span className="st-detail-sub">Grade {selectedGrade.grade} · {selectedGrade.name}</span>
            </div>
          </div>
          {editingGradeMeta ? (
            <div className="st-grade-meta-edit">
              <h4>Modifier les informations du grade</h4>
              <div className="st-form-grid">
                <div className="st-form-group">
                  <label>Nom interne</label>
                  <input type="text" value={editGradeName} onChange={e => setEditGradeName(e.target.value)} />
                </div>
                <div className="st-form-group">
                  <label>Label affiché</label>
                  <input type="text" value={editGradeLabel} onChange={e => setEditGradeLabel(e.target.value)} />
                </div>
              </div>
              <div className="st-detail-actions" style={{ marginTop: 8 }}>
                <button className="st-action-btn st-promote" onClick={handleEditGradeMeta}><Save size={14} /> Sauvegarder</button>
                <button className="st-action-btn st-demote" onClick={() => setEditingGradeMeta(false)}><X size={14} /> Annuler</button>
              </div>
            </div>
          ) : (
            <div className="st-detail-actions">
              <button className="st-action-btn st-promote" onClick={() => { setEditingGradeMeta(true); setEditGradeName(selectedGrade.name); setEditGradeLabel(selectedGrade.label); }}>
                <Pencil size={14} /> Modifier nom/label
              </button>
              {selectedGrade.name !== 'boss' && (
                confirmDeleteGrade === selectedGrade.grade ? (
                  <div className="st-confirm-delete">
                    <span>Confirmer la suppression ?</span>
                    <button className="st-action-btn st-fire" onClick={() => handleDeleteGrade(selectedGrade.grade)}><Trash2 size={14} /> Confirmer</button>
                    <button className="st-action-btn st-demote" onClick={() => setConfirmDeleteGrade(null)}><X size={14} /> Annuler</button>
                  </div>
                ) : (
                  <button className="st-action-btn st-fire" onClick={() => setConfirmDeleteGrade(selectedGrade.grade)}><Trash2 size={14} /> Supprimer le grade</button>
                )
              )}
            </div>
          )}
          <div className="st-grade-salaries">
            <div className="st-salary-card">
              <div className="st-salary-header">
                <span>Salaire Mensuel</span>
                <span className="st-salary-value">{formatMoney(selectedGrade.mensuelpay || 0)}</span>
              </div>
              {editingSalaryType === 'mensuel' ? (
                <div className="st-salary-edit">
                  <input type="number" placeholder={`Min: ${data.salaryData?.Mensuel?.min ?? 0} / Max: ${data.salaryData?.Mensuel?.max ?? 0}`} value={salaryInput} onChange={e => setSalaryInput(e.target.value)} />
                  <button className="st-save-btn" onClick={handleEditSalary}><Save size={14} /></button>
                  <button className="st-cancel-btn" onClick={() => setEditingSalaryType(null)}><X size={14} /></button>
                </div>
              ) : (
                <button className="st-edit-salary-btn" onClick={() => { setEditingSalaryType('mensuel'); setSalaryInput(''); }}><Pencil size={14} /> Modifier</button>
              )}
            </div>
            <div className="st-salary-card">
              <div className="st-salary-header">
                <span>Salaire / 30 Min</span>
                <span className="st-salary-value">{formatMoney(selectedGrade.salary || 0)}</span>
              </div>
              {editingSalaryType === '30min' ? (
                <div className="st-salary-edit">
                  <input type="number" placeholder={`Min: ${data.salaryData?.['Pour 30 Min']?.min ?? 0} / Max: ${data.salaryData?.['Pour 30 Min']?.max ?? 0}`} value={salaryInput} onChange={e => setSalaryInput(e.target.value)} />
                  <button className="st-save-btn" onClick={handleEditSalary}><Save size={14} /></button>
                  <button className="st-cancel-btn" onClick={() => setEditingSalaryType(null)}><X size={14} /></button>
                </div>
              ) : (
                <button className="st-edit-salary-btn" onClick={() => { setEditingSalaryType('30min'); setSalaryInput(''); }}><Pencil size={14} /> Modifier</button>
              )}
            </div>
          </div>
        </div>
      ) : (
        <div className="st-grade-list">
          {data.grades.length < (data.maxGrades || 8) && (
            <button className="st-add-grade-btn" onClick={() => setCreatingGrade(true)}>
              <Plus size={16} /> Ajouter un grade
            </button>
          )}
          {data.grades.map(grade => (
            <div key={grade.grade} className="st-grade-row" onClick={() => setSelectedGrade(grade)}>
              <div className="st-grade-badge" style={{ background: accentRgba(accent, 20), color: accent }}>{grade.grade}</div>
              <div className="st-grade-info">
                <span className="st-grade-name">{grade.label}</span>
                <span className="st-grade-sub">{grade.name} · Mensuel: {formatMoney(grade.mensuelpay || 0)} · /30min: {formatMoney(grade.salary || 0)}</span>
              </div>
              <ChevronRight size={14} className="st-chevron" />
            </div>
          ))}
        </div>
      )}
    </div>
  );

  const renderFinances = () => (
    <div className="st-page st-finances">
      <div className="st-page-header">
        <h2>Finances</h2>
        <span className="st-page-subtitle">Gestion du compte société</span>
      </div>
      <div className="st-finance-summary">
        <div className="st-fin-card">
          <Banknote size={20} style={{ color: '#22c55e' }} />
          <div>
            <span className="st-fin-label">Argent</span>
            <span className="st-fin-value" style={{ color: '#22c55e' }}>{formatMoney(data.accounts.cash)}</span>
          </div>
        </div>
        <div className="st-fin-card">
          <BadgeDollarSign size={20} style={{ color: '#ef4444' }} />
          <div>
            <span className="st-fin-label">Argent sale</span>
            <span className="st-fin-value" style={{ color: '#ef4444' }}>{formatMoney(data.accounts.dirtycash)}</span>
          </div>
        </div>
      </div>
      <div className="st-tab-row">
        <button className={`st-tab ${financeTab === 'manage' ? 'st-tab-active' : ''}`} onClick={() => setFinanceTab('manage')}><ArrowUpDown size={14} /> Opérations</button>
        <button className={`st-tab ${financeTab === 'history' ? 'st-tab-active' : ''}`} onClick={() => setFinanceTab('history')}><History size={14} /> Historique</button>
      </div>
      {financeTab === 'manage' ? (
        <div className="st-finance-manage">
          <div className="st-money-type-row">
            <button className={`st-money-type ${moneyType === 'cash' ? 'st-mt-active' : ''}`} onClick={() => setMoneyType('cash')}>Argent propre</button>
            <button className={`st-money-type ${moneyType === 'dirtycash' ? 'st-mt-active' : ''}`} onClick={() => setMoneyType('dirtycash')}>Argent sale</button>
          </div>
          <div className="st-money-input-row">
            <input type="number" placeholder="Montant..." value={moneyAmount} onChange={e => setMoneyAmount(e.target.value)} />
          </div>
          <div className="st-money-actions">
            <button className="st-action-btn st-deposit" onClick={handleDeposit}><TrendingUp size={16} /> Déposer</button>
            <button className="st-action-btn st-withdraw" onClick={handleWithdraw}><TrendingDown size={16} /> Retirer</button>
          </div>
        </div>
      ) : (
        <div className="st-finance-history">
          <div className="st-history-filters">
            <div className="st-search-bar st-search-sm">
              <Search size={14} />
              <input type="text" placeholder="Rechercher..." value={historySearch} onChange={e => setHistorySearch(e.target.value)} />
            </div>
            <div className="st-filter-row">
              {(['all', 'income', 'expense'] as const).map(f => (
                <button key={f} className={`st-filter-btn ${historyFilter === f ? 'st-filter-active' : ''}`} onClick={() => setHistoryFilter(f)}>
                  {f === 'all' ? 'Tous' : f === 'income' ? 'Gains' : 'Dépenses'}
                </button>
              ))}
            </div>
          </div>
          <div className="st-history-list">
            {filteredHistory.length === 0 ? (
              <div className="st-empty">Aucune transaction trouvée</div>
            ) : filteredHistory.map((entry, i) => (
              <div key={i} className="st-history-row">
                <div className={`st-hist-icon ${entry.count >= 0 ? 'st-hist-in' : 'st-hist-out'}`}>
                  {entry.count >= 0 ? <TrendingUp size={14} /> : <TrendingDown size={14} />}
                </div>
                <div className="st-hist-info">
                  <span className="st-hist-label">{entry.label}</span>
                  <span className="st-hist-sub">{entry.info.replace(/~n~/g, ' · ').replace(/~[a-z]~/g, '')}</span>
                  {entry.time && <span className="st-hist-time"><Clock size={10} /> {entry.time}</span>}
                </div>
                <span className={`st-hist-amount ${entry.count >= 0 ? 'st-positive' : 'st-negative'}`}>
                  {entry.count >= 0 ? '+' : ''}{formatMoney(entry.count)}
                </span>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );

  const renderSettings = () => (
    <div className="st-page st-settings">
      <div className="st-page-header">
        <h2>Paramètres</h2>
        <span className="st-page-subtitle">Configuration de l'entreprise</span>
      </div>
      <div className="st-settings-sections">
        <div className="st-section">
          <h3><Pencil size={16} /> Général</h3>
          <button className="st-setting-btn" onClick={handleRename}>
            <FileText size={16} /><span>Changer le nom de l'entreprise</span><ChevronRight size={14} />
          </button>
        </div>
        {data.canLaunder && (
          <div className="st-section">
            <h3><RefreshCw size={16} /> Blanchiment d'argent</h3>
            <p className="st-section-desc">Rendement : {data.blanchimentConfig.pourcentage}% · Délai : {data.blanchimentConfig.delai} min</p>
            <div className="st-launder-row">
              <input type="number" placeholder="Montant à blanchir..." value={launderAmount} onChange={e => setLaunderAmount(e.target.value)} />
              <button className="st-action-btn st-launder" onClick={handleLaunder}><RefreshCw size={14} /> Blanchir</button>
            </div>
          </div>
        )}
        {data.canBuyDrinks && data.drinks.length > 0 && (
          <div className="st-section">
            <h3><Wine size={16} /> Boissons pour le frigo</h3>
            <div className="st-shop-list">
              {data.drinks.map(drink => (
                <div key={drink.value} className="st-shop-item">
                  <span className="st-shop-name">{drink.name}</span>
                  <span className="st-shop-price">{formatMoney(drink.price * (drinkQuantities[drink.value] || 1))}</span>
                  <div className="st-qty-control">
                    <button onClick={() => setDrinkQuantities(prev => ({ ...prev, [drink.value]: Math.max(1, (prev[drink.value] || 1) - 1) }))}>-</button>
                    <span>{drinkQuantities[drink.value] || 1}</span>
                    <button onClick={() => setDrinkQuantities(prev => ({ ...prev, [drink.value]: Math.min(10, (prev[drink.value] || 1) + 1) }))}>+</button>
                  </div>
                  <button className="st-buy-btn" onClick={() => handleBuyDrink(drink.value, drink.name, drink.price)}>Acheter</button>
                </div>
              ))}
            </div>
          </div>
        )}
        {data.canBuyHeals && data.heals.length > 0 && (
          <div className="st-section">
            <h3><Heart size={16} /> Soins pour la pharmacie</h3>
            <div className="st-shop-list">
              {data.heals.map(heal => (
                <div key={heal.value} className="st-shop-item">
                  <span className="st-shop-name">{heal.name}</span>
                  <span className="st-shop-price">{formatMoney(heal.price * (healQuantities[heal.value] || 1))}</span>
                  <div className="st-qty-control">
                    <button onClick={() => setHealQuantities(prev => ({ ...prev, [heal.value]: Math.max(1, (prev[heal.value] || 1) - 1) }))}>-</button>
                    <span>{healQuantities[heal.value] || 1}</span>
                    <button onClick={() => setHealQuantities(prev => ({ ...prev, [heal.value]: Math.min(20, (prev[heal.value] || 1) + 1) }))}>+</button>
                  </div>
                  <button className="st-buy-btn" onClick={() => handleBuyHeal(heal.value, heal.name, heal.price)}>Acheter</button>
                </div>
              ))}
            </div>
          </div>
        )}
        {Object.keys(data.politique).length > 0 && (
          <div className="st-section">
            <h3><Landmark size={16} /> Politiques appliquées</h3>
            <div className="st-politique-list">
              {Object.entries(data.politique).map(([key, value]) => (
                <div key={key} className="st-politique-item">
                  <div className="st-politique-info">
                    <span className="st-politique-name">{key}</span>
                    {data.politiqueConfig[key] && <span className="st-politique-desc">{data.politiqueConfig[key].description}</span>}
                  </div>
                  <div className={`st-toggle ${value ? 'st-toggle-on' : ''}`} style={value ? { background: accent } : {}} onClick={() => handleTogglePolitique(key, value)}>
                    <div className="st-toggle-dot" />
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}
        {data.isMecano && (
          <div className="st-section">
            <h3><History size={16} /> Historique Customs</h3>
            <button className="st-action-btn st-promote" onClick={handleLoadCustomHistory} style={{ marginBottom: 8 }}><RefreshCw size={14} /> Charger l'historique</button>
            {data.customHistory.length > 0 && (
              <>
                <div className="st-search-bar st-search-sm" style={{ marginBottom: 8 }}>
                  <Search size={14} />
                  <input type="text" placeholder="Rechercher..." value={customHistorySearch} onChange={e => setCustomHistorySearch(e.target.value)} />
                </div>
                <div className="st-history-list" style={{ maxHeight: 300 }}>
                  {filteredCustomHistory.map((entry, i) => (
                    <div key={i} className="st-history-row">
                      <div className={`st-hist-icon ${entry.count >= 0 ? 'st-hist-in' : 'st-hist-out'}`}>
                        {entry.count >= 0 ? <TrendingUp size={14} /> : <TrendingDown size={14} />}
                      </div>
                      <div className="st-hist-info">
                        <span className="st-hist-label">{entry.label}</span>
                        <span className="st-hist-sub">{entry.info}</span>
                      </div>
                      <span className={`st-hist-amount ${entry.count >= 0 ? 'st-positive' : 'st-negative'}`}>
                        {entry.count >= 0 ? '+' : ''}{entry.count}
                      </span>
                    </div>
                  ))}
                </div>
              </>
            )}
          </div>
        )}
      </div>
    </div>
  );

  const renderGovernment = () => (
    <div className="st-page st-government">
      <div className="st-page-header">
        <h2>Gouvernement</h2>
        <span className="st-page-subtitle">Gestion de la ville</span>
      </div>
      <div className="st-tab-row">
        <button className={`st-tab ${govTab === 'enterprises' ? 'st-tab-active' : ''}`} onClick={() => { setGovTab('enterprises'); setSelectedEnterprise(null); }}><Building2 size={14} /> Entreprises</button>
        <button className={`st-tab ${govTab === 'economy' ? 'st-tab-active' : ''}`} onClick={() => setGovTab('economy')}><DollarSign size={14} /> Économie</button>
        <button className={`st-tab ${govTab === 'city' ? 'st-tab-active' : ''}`} onClick={() => setGovTab('city')}><Zap size={14} /> Ville</button>
      </div>
      {govTab === 'enterprises' && !selectedEnterprise && (
        <div className="st-enterprise-list">
          {data.enterprises.filter(e => e.name !== 'gouvernement').map(ent => (
            <div key={ent.name} className="st-enterprise-row" onClick={() => setSelectedEnterprise(ent)}>
              <div className={`st-ent-status ${ent.state ? 'st-ent-on' : 'st-ent-off'}`} />
              <div className="st-ent-info">
                <span className="st-ent-name">{ent.label}</span>
                <span className="st-ent-sub">{ent.name} · {ent.employeeCount} employé(s)</span>
              </div>
              <ChevronRight size={14} className="st-chevron" />
            </div>
          ))}
        </div>
      )}
      {govTab === 'enterprises' && selectedEnterprise && (
        <div className="st-enterprise-detail">
          <button className="st-back-btn" onClick={() => setSelectedEnterprise(null)}>← Retour aux entreprises</button>
          <div className="st-detail-header">
            <div className="st-detail-avatar" style={{ background: hexToRgba(accent, 0.3) }}>
              <Building2 size={20} style={{ color: accent }} />
            </div>
            <div className="st-detail-info">
              <h3>{selectedEnterprise.label}</h3>
              <span className="st-detail-sub">{selectedEnterprise.name}</span>
              <span className={`st-online-badge ${selectedEnterprise.state ? 'st-is-online' : ''}`}>
                {selectedEnterprise.state ? '● Disponible' : '○ Indisponible'}
              </span>
            </div>
          </div>
          <div className="st-detail-actions">
            <button className="st-action-btn st-promote" onClick={() => handleChangeEnterpriseName(selectedEnterprise)}><Pencil size={16} /> Changer le nom</button>
          </div>
          {selectedEnterprise.politique && Object.keys(selectedEnterprise.politique).length > 0 && (
            <div className="st-section" style={{ marginTop: 16 }}>
              <h3><Landmark size={16} /> Politiques</h3>
              <div className="st-politique-list">
                {Object.entries(selectedEnterprise.politique).map(([key, value]) => (
                  <div key={key} className="st-politique-item">
                    <div className="st-politique-info"><span className="st-politique-name">{key}</span></div>
                    <div className={`st-toggle ${value ? 'st-toggle-on' : ''}`} style={value ? { background: accent } : {}} onClick={() => handleGovTogglePolitique(selectedEnterprise, key, value)}>
                      <div className="st-toggle-dot" />
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}
        </div>
      )}
      {govTab === 'economy' && (
        <div className="st-economy">
          <div className="st-section">
            <h3><Banknote size={16} /> Salaires</h3>
            <div className="st-eco-grid">
              <div className="st-eco-item"><span>SMIC Mensuel</span><span className="st-eco-value">{formatMoney(data.salaryData?.Mensuel?.min ?? 0)}</span><button className="st-eco-btn" onClick={() => handleChangeSalary('Mensuel', 'min')}>Modifier</button></div>
              <div className="st-eco-item"><span>SMIC / 30 Min</span><span className="st-eco-value">{formatMoney(data.salaryData?.['Pour 30 Min']?.min ?? 0)}</span><button className="st-eco-btn" onClick={() => handleChangeSalary('Pour 30 Min', 'min')}>Modifier</button></div>
              <div className="st-eco-item"><span>Max Primes</span><span className="st-eco-value">{formatMoney(data.salaryData?.Primes?.max ?? 0)}</span><button className="st-eco-btn" onClick={() => handleChangeSalary('Primes', 'max')}>Modifier</button></div>
            </div>
          </div>
          <div className="st-section">
            <h3><Percent size={16} /> Taxes</h3>
            <div className="st-eco-grid">
              <div className="st-eco-item"><span>Retraits</span><span className="st-eco-value">{data.taxesData?.retrait ?? 0}%</span><button className="st-eco-btn" onClick={() => handleChangeTax('retrait')}>Modifier</button></div>
              <div className="st-eco-item"><span>Gains</span><span className="st-eco-value">{data.taxesData?.gains ?? 0}%</span><button className="st-eco-btn" onClick={() => handleChangeTax('gains')}>Modifier</button></div>
              <div className="st-eco-item"><span>Salaires</span><span className="st-eco-value">{data.taxesData?.salaire ?? 0}%</span><button className="st-eco-btn" onClick={() => handleChangeTax('salaire')}>Modifier</button></div>
              <div className="st-eco-item"><span>TVA</span><span className="st-eco-value">{data.taxesData?.tva ?? 0}%</span><button className="st-eco-btn" onClick={() => handleChangeTax('tva')}>Modifier</button></div>
            </div>
          </div>
        </div>
      )}
      {govTab === 'city' && (
        <div className="st-city">
          <div className="st-section">
            <h3><Zap size={16} /> Services de la ville</h3>
            <button className="st-setting-btn" onClick={handleToggleElectricity}><Zap size={16} /><span>Électricité de la ville</span><Power size={14} /></button>
          </div>
        </div>
      )}
    </div>
  );

  const filteredCustomHistory = data.customHistory.filter(entry => {
    if (customHistorySearch) {
      const s = customHistorySearch.toLowerCase();
      return entry.label.toLowerCase().includes(s) || entry.info.toLowerCase().includes(s);
    }
    return true;
  });

  const renderCityInfo = () => (
    <div className="st-page st-cityinfo">
      <div className="st-page-header">
        <h2>Informations sur la Ville</h2>
        <span className="st-page-subtitle">Données économiques définies par le gouvernement</span>
      </div>

      <div className="st-cityinfo-sections">
        <div className="st-section">
          <h3><Banknote size={16} /> Salaires</h3>
          <p className="st-section-desc">Grille salariale en vigueur sur le territoire</p>
          <div className="st-info-grid">
            <div className="st-info-item">
              <div className="st-info-icon" style={{ background: 'rgba(34,197,94,0.12)' }}>
                <DollarSign size={16} style={{ color: '#22c55e' }} />
              </div>
              <div className="st-info-text">
                <span className="st-info-label">SMIC Mensuel</span>
                <span className="st-info-value" style={{ color: '#22c55e' }}>{formatMoney(data.salaryData?.Mensuel?.min ?? 0)}</span>
              </div>
            </div>
            <div className="st-info-item">
              <div className="st-info-icon" style={{ background: 'rgba(59,130,246,0.12)' }}>
                <Clock size={16} style={{ color: '#3b82f6' }} />
              </div>
              <div className="st-info-text">
                <span className="st-info-label">SMIC / 30 Min</span>
                <span className="st-info-value" style={{ color: '#3b82f6' }}>{formatMoney(data.salaryData?.['Pour 30 Min']?.min ?? 0)}</span>
              </div>
            </div>
            <div className="st-info-item">
              <div className="st-info-icon" style={{ background: 'rgba(245,158,11,0.12)' }}>
                <TrendingUp size={16} style={{ color: '#f59e0b' }} />
              </div>
              <div className="st-info-text">
                <span className="st-info-label">Max Primes</span>
                <span className="st-info-value" style={{ color: '#f59e0b' }}>{formatMoney(data.salaryData?.Primes?.max ?? 0)}</span>
              </div>
            </div>
          </div>
        </div>

        <div className="st-section">
          <h3><Percent size={16} /> Taxes en vigueur</h3>
          <p className="st-section-desc">Pourcentages appliqués sur les différentes transactions</p>
          <div className="st-info-grid">
            <div className="st-info-item">
              <div className="st-info-icon" style={{ background: 'rgba(239,68,68,0.12)' }}>
                <TrendingDown size={16} style={{ color: '#ef4444' }} />
              </div>
              <div className="st-info-text">
                <span className="st-info-label">Taxes sur les retraits</span>
                <span className="st-info-value" style={{ color: '#ef4444' }}>{data.taxesData?.retrait ?? 0}%</span>
              </div>
            </div>
            <div className="st-info-item">
              <div className="st-info-icon" style={{ background: 'rgba(34,197,94,0.12)' }}>
                <TrendingUp size={16} style={{ color: '#22c55e' }} />
              </div>
              <div className="st-info-text">
                <span className="st-info-label">Taxes sur les gains</span>
                <span className="st-info-value" style={{ color: '#22c55e' }}>{data.taxesData?.gains ?? 0}%</span>
              </div>
            </div>
            <div className="st-info-item">
              <div className="st-info-icon" style={{ background: 'rgba(168,85,247,0.12)' }}>
                <Banknote size={16} style={{ color: '#a855f7' }} />
              </div>
              <div className="st-info-text">
                <span className="st-info-label">Taxes sur les salaires</span>
                <span className="st-info-value" style={{ color: '#a855f7' }}>{data.taxesData?.salaire ?? 0}%</span>
              </div>
            </div>
            <div className="st-info-item">
              <div className="st-info-icon" style={{ background: 'rgba(6,182,212,0.12)' }}>
                <Percent size={16} style={{ color: '#06b6d4' }} />
              </div>
              <div className="st-info-text">
                <span className="st-info-label">TVA</span>
                <span className="st-info-value" style={{ color: '#06b6d4' }}>{data.taxesData?.tva ?? 0}%</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );

  const renderProperties = () => (
    <div className="st-page st-properties">
      <div className="st-page-header">
        <h2>Gestion des propriétés</h2>
        <span className="st-page-subtitle">{data.properties.length} propriété(s)</span>
      </div>
      {data.properties.length === 0 && !selectedProperty ? (
        <div className="st-empty">
          <button className="st-action-btn st-promote" onClick={handleLoadProperties}><RefreshCw size={14} /> Charger les propriétés</button>
        </div>
      ) : selectedProperty ? (
        <div className="st-property-detail">
          <button className="st-back-btn" onClick={() => setSelectedProperty(null)}>← Retour à la liste</button>
          <div className="st-detail-header">
            <div className="st-detail-avatar" style={{ background: hexToRgba(accent, 0.3) }}>
              <MapPin size={20} style={{ color: accent }} />
            </div>
            <div className="st-detail-info">
              <h3>{selectedProperty.label}</h3>
              <span className="st-detail-sub">ID: {selectedProperty.id} · {selectedProperty.name}</span>
              <span className={`st-online-badge ${selectedProperty.isBuy ? 'st-is-online' : ''}`}>
                {selectedProperty.isBuy ? '● Vendu' : '○ Disponible'}
              </span>
            </div>
          </div>
          <div className="st-property-info-grid">
            <div className="st-info-item"><span className="st-info-label">Prix</span><span className="st-info-value">{formatMoney(selectedProperty.price)}</span></div>
            <div className="st-info-item"><span className="st-info-label">Propriétaire</span><span className="st-info-value">{selectedProperty.owner || 'Aucun'}</span></div>
            <div className="st-info-item"><span className="st-info-label">Immeuble</span><span className="st-info-value">{selectedProperty.immeuble === '0' ? 'Aucun' : selectedProperty.immeuble}</span></div>
          </div>
          <div className="st-detail-actions">
            <button className="st-action-btn st-fire" onClick={() => handleDeleteProperty(selectedProperty)}><Trash2 size={14} /> Supprimer</button>
            {selectedProperty.isBuy ? (
              <button className="st-action-btn st-demote" onClick={() => handleEvictProperty(selectedProperty)}><UserMinus size={14} /> Virer le propriétaire</button>
            ) : (
              <>
                <button className="st-action-btn st-promote" onClick={() => handleAssignProperty(selectedProperty, false)}><UserPlus size={14} /> Attribuer au joueur proche</button>
                <button className="st-action-btn st-promote" onClick={() => handleAssignProperty(selectedProperty, true)}><UserPlus size={14} /> Attribuer à vous</button>
              </>
            )}
          </div>
        </div>
      ) : (
        <div className="st-property-list">
          <button className="st-action-btn st-promote" onClick={handleLoadProperties} style={{ marginBottom: 12 }}><RefreshCw size={14} /> Rafraîchir</button>
          {data.properties.map(prop => (
            <div key={prop.id} className="st-property-row" onClick={() => setSelectedProperty(prop)}>
              <div className={`st-ent-status ${prop.isBuy ? 'st-ent-on' : 'st-ent-off'}`} />
              <div className="st-ent-info">
                <span className="st-ent-name">{prop.label} ({prop.id})</span>
                <span className="st-ent-sub">{prop.isBuy ? 'Vendu' : 'Disponible'} · {formatMoney(prop.price)}</span>
              </div>
              <ChevronRight size={14} className="st-chevron" />
            </div>
          ))}
        </div>
      )}
    </div>
  );

  const renderPage = () => {
    switch (currentPage) {
      case 'home': return renderHome();
      case 'employees': return renderEmployees();
      case 'grades': return renderGrades();
      case 'finances': return renderFinances();
      case 'settings': return renderSettings();
      case 'government': return renderGovernment();
      case 'cityinfo': return renderCityInfo();
      case 'properties': return renderProperties();
      default: return renderHome();
    }
  };

  return (
    <div className={`st-overlay ${hiding ? 'st-hiding' : ''}`} style={{ ...stAccentVars, '--st-accent-rgb': accentRgb } as React.CSSProperties}>
      <div className="st-container">
        <div className="st-sidebar">
          <div 
            className="st-sidebar-brand-hero"
            style={{ background: `linear-gradient(160deg, ${data.brandBg || accent} 0%, ${(data.brandBg || accent)}dd 60%, rgba(0,0,0,0.4) 100%)` }}
          >
            <div className="st-sidebar-brand-hero-shine" />
            <div className="st-sidebar-brand-hero-inner">
              {data.brandLogo ? (
                <img
                  className="st-sidebar-brand-logo"
                  src={data.brandLogo}
                  alt={data.societyLabel}
                  onError={(e) => { (e.target as HTMLImageElement).style.display = 'none'; }}
                />
              ) : (
                <div className="st-sidebar-brand-logo-fallback"><Store size={24} style={{ color: '#fff' }} /></div>
              )}
              <div className="st-sidebar-brand-hero-text">
                <h2>{data.societyLabel}</h2>
                <p>{data.brandTagline || data.playerGradeLabel}</p>
              </div>
            </div>
          </div>
          <nav className="st-sidebar-nav">
            {visiblePages.map(page => (
              <button key={page.id} className={`st-nav-btn ${currentPage === page.id ? 'st-nav-active' : ''}`} onClick={() => navigateTo(page.id)}>
                {page.icon}
                <span>{page.label}</span>
                {currentPage === page.id && <div className="st-nav-indicator" style={{ background: accent }} />}
              </button>
            ))}
          </nav>
          <div className="st-sidebar-footer">
            <button className="st-close-btn" onClick={handleClose}><X size={16} /> Fermer</button>
          </div>
        </div>
        <div className={`st-content ${pageTransition ? 'st-page-trans' : ''}`}>
          {renderPage()}
        </div>
      </div>
      {notification && (
        <div className={`st-notif ${notification.type === 'success' ? 'st-notif-success' : 'st-notif-error'}`}>
          {notification.type === 'success' ? <CheckCircle2 size={16} /> : <XCircle size={16} />}
          {notification.message}
        </div>
      )}
    </div>
  );
};

export default SocietyTablet;
