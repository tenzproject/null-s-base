import React, { useState, useEffect, useCallback, useMemo, useRef } from 'react';
import { cacheImg } from '@/shared/cacheVersion';
import { generateAccentVars } from '@/utils/accentColors';
import {
  Landmark, X, LayoutDashboard, ArrowLeftRight, History, CreditCard,
  Wallet, ArrowDownToLine, ArrowUpFromLine, Send, Search,
  ChevronRight, Check, Copy, MoreHorizontal, ShoppingCart, Briefcase,
  Gavel, RefreshCw, AlertTriangle, ShieldCheck, ShieldOff, KeyRound,
} from 'lucide-react';
import type { BankProps, BankData, TabType, Transaction, BankBrand } from './types';
import WaveBackground from '@/components/WaveBackground';
import './Bank.css';

const GetParentResourceName = () => 'null-core';

function hexToRgb(hex: string): string {
  const h = hex.replace('#', '');
  const r = parseInt(h.substring(0, 2), 16);
  const g = parseInt(h.substring(2, 4), 16);
  const b = parseInt(h.substring(4, 6), 16);
  return `${r}, ${g}, ${b}`;
}

function formatMoney(n: number): string {
  return n.toLocaleString('fr-FR') + '$';
}

const MONTH_LABELS = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun', 'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];

const CATEGORY_ICONS: Record<string, React.ReactNode> = {
  deposit: <ArrowDownToLine size={16} />,
  withdraw: <ArrowUpFromLine size={16} />,
  transfer: <Send size={16} />,
  purchase: <ShoppingCart size={16} />,
  salary: <Briefcase size={16} />,
  fine: <Gavel size={16} />,
  loan: <CreditCard size={16} />,
  repayment: <RefreshCw size={16} />,
  other: <MoreHorizontal size={16} />,
};

const Bank: React.FC<BankProps> = ({ visible, onClose, primaryColor }) => {
  const [data, setData] = useState<BankData | null>(null);
  const [activeTab, setActiveTab] = useState<TabType>('dashboard');
  const [hiding, setHiding] = useState(false);
  const [toast, setToast] = useState<string | null>(null);
  const toastTimer = useRef<ReturnType<typeof setTimeout> | null>(null);

  // Forms
  const [transferIban, setTransferIban] = useState('');
  const [transferAmount, setTransferAmount] = useState('');
  const [transferReason, setTransferReason] = useState('');
  const [depositAmount, setDepositAmount] = useState('');
  const [withdrawAmount, setWithdrawAmount] = useState('');
  const [historySearch, setHistorySearch] = useState('');
  const [historyCategory, setHistoryCategory] = useState<string>('all');
  const [loanAmount, setLoanAmount] = useState('');
  const [loanInstallments, setLoanInstallments] = useState<number>(4);

  // PIN state (card tab)
  const [pinDigits, setPinDigits] = useState<string[]>(['', '', '', '']);
  const [pinConfirmDigits, setPinConfirmDigits] = useState<string[]>(['', '', '', '']);
  const [pinFeedback, setPinFeedback] = useState<{ type: 'error' | 'success' | 'info'; message: string } | null>(null);
  const pinRefs = useRef<(HTMLInputElement | null)[]>([]);
  const pinConfirmRefs = useRef<(HTMLInputElement | null)[]>([]);

  const brand: BankBrand | undefined = data?.brand;
  const brandBg = brand?.bgColor || '#1a1a1a';
  // Bank uses its brand accent everywhere; falls back to the server primaryColor when no brand is configured.
  const accentColor = brand?.accent || primaryColor || '#3b82f6';
  const accentRgb = hexToRgb(accentColor);
  const brandAccent = accentColor;
  const brandLogo = brand?.logo ? cacheImg(brand.logo) : null;

  const accentVars = useMemo(() => generateAccentVars('--bank-accent', accentColor), [accentColor]);
  const brandVars = useMemo(() => ({
    '--bank-brand-bg': brandBg,
    '--bank-brand-accent': brandAccent,
  } as React.CSSProperties), [brandBg, brandAccent]);

  const showToast = useCallback((msg: string) => {
    setToast(msg);
    if (toastTimer.current) clearTimeout(toastTimer.current);
    toastTimer.current = setTimeout(() => setToast(null), 3000);
  }, []);

  const handleClose = useCallback(() => {
    setHiding(true);
    setTimeout(() => {
      setHiding(false);
      setData(null);
      setActiveTab('dashboard');
      onClose();
      fetch(`https://${GetParentResourceName()}/bank:close`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({}),
      });
    }, 300);
  }, [onClose]);

  const nuiAction = useCallback((action: string, payload: any = {}) => {
    return fetch(`https://${GetParentResourceName()}/bank:${action}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
    }).then(r => r.json()).catch(() => 'error');
  }, []);

  // NUI messages
  useEffect(() => {
    const handler = (e: MessageEvent) => {
      const { action, data: d } = e.data || {};
      if (action === 'bank:open' && d) {
        setData(d);
        setActiveTab('dashboard');
        setTransferIban('');
        setTransferAmount('');
        setTransferReason('');
        setDepositAmount('');
        setWithdrawAmount('');
        setHistorySearch('');
        setHistoryCategory('all');
        setLoanAmount('');
        setLoanInstallments(d.creditConfig?.installments?.[0] || 4);
        setPinDigits(['', '', '', '']);
        setPinConfirmDigits(['', '', '', '']);
        setPinFeedback(null);
      }
      if (action === 'bank:close') handleClose();
      if (action === 'bank:update' && d) setData(d);
      if (action === 'bank:feedback' && d?.message) showToast(d.message);
      if (action === 'bank:cardResult' && d) {
        if (d.success) {
          showToast('Carte bancaire achetée');
        } else {
          showToast(d.message || 'Erreur');
        }
      }
      if (action === 'bank:pinResult' && d) {
        if (d.success) {
          setPinFeedback({ type: 'success', message: 'Code mis à jour' });
          setPinDigits(['', '', '', '']);
          setPinConfirmDigits(['', '', '', '']);
        } else {
          setPinFeedback({ type: 'error', message: d.message || 'Erreur' });
        }
      }
    };
    window.addEventListener('message', handler);
    return () => window.removeEventListener('message', handler);
  }, [handleClose, showToast]);

  // ESC
  useEffect(() => {
    if (!data) return;
    const handler = (e: KeyboardEvent) => {
      if (e.key === 'Escape') handleClose();
    };
    window.addEventListener('keydown', handler);
    return () => window.removeEventListener('keydown', handler);
  }, [data, handleClose]);

  // ---- Analytics ----
  const monthlySpending = useMemo(() => {
    if (!data) return [];
    const now = new Date();
    const months: { label: string; total: number }[] = [];
    for (let i = 5; i >= 0; i--) {
      const d = new Date(now.getFullYear(), now.getMonth() - i, 1);
      months.push({ label: MONTH_LABELS[d.getMonth()], total: 0 });
    }
    data.history.forEach(tx => {
      if (tx.amount < 0) {
        const parts = tx.date.split(' - ')[0]?.split('.');
        if (parts && parts.length === 3) {
          const txMonth = parseInt(parts[1]) - 1;
          const txYear = parseInt(parts[2]);
          for (let i = 0; i < months.length; i++) {
            const d = new Date(now.getFullYear(), now.getMonth() - (5 - i), 1);
            if (d.getMonth() === txMonth && d.getFullYear() === txYear) {
              months[i].total += Math.abs(tx.amount);
            }
          }
        }
      }
    });
    return months;
  }, [data]);

  const maxMonthly = useMemo(() => Math.max(...monthlySpending.map(m => m.total), 1), [monthlySpending]);

  const categoryBreakdown = useMemo(() => {
    if (!data) return [];
    const cats: Record<string, { count: number; total: number }> = {};
    data.history.forEach(tx => {
      const cat = tx.category || 'other';
      if (!cats[cat]) cats[cat] = { count: 0, total: 0 };
      cats[cat].count++;
      cats[cat].total += tx.amount;
    });
    return Object.entries(cats)
      .map(([key, val]) => ({ key, ...val, label: data.categories[key]?.label || key }))
      .sort((a, b) => b.count - a.count);
  }, [data]);

  const totalDebt = useMemo(() => {
    if (!data) return 0;
    return data.credits.filter(c => !c.paidOff).reduce((s, c) => s + (c.totalDue - c.paid), 0);
  }, [data]);

  const allCategories = useMemo(() => {
    if (!data) return [];
    const cats = new Set(data.history.map(tx => tx.category));
    return Array.from(cats);
  }, [data]);

  const filteredHistory = useMemo(() => {
    if (!data) return [];
    let list = data.history;
    if (historyCategory !== 'all') {
      list = list.filter(tx => tx.category === historyCategory);
    }
    if (historySearch.trim()) {
      const q = historySearch.toLowerCase();
      list = list.filter(tx =>
        tx.title.toLowerCase().includes(q) ||
        tx.description.toLowerCase().includes(q) ||
        tx.date.includes(q)
      );
    }
    return list;
  }, [data, historyCategory, historySearch]);

  // ---- Actions ----
  const handleDeposit = async () => {
    const amt = parseInt(depositAmount);
    if (!amt || amt <= 0) return;
    await nuiAction('deposit', { amount: amt });
    setDepositAmount('');
  };

  const handleWithdraw = async () => {
    const amt = parseInt(withdrawAmount);
    if (!amt || amt <= 0) return;
    await nuiAction('withdraw', { amount: amt });
    setWithdrawAmount('');
  };

  const handleTransfer = async () => {
    if (!transferIban.trim() || !transferAmount.trim()) return;
    const amt = parseInt(transferAmount);
    if (!amt || amt <= 0) return;
    await nuiAction('transfer', { iban: transferIban, amount: amt, reason: transferReason });
    setTransferIban('');
    setTransferAmount('');
    setTransferReason('');
  };

  const handleAcceptTransfer = async (id: string) => {
    await nuiAction('acceptTransfer', { id });
  };

  const handleRequestLoan = async () => {
    const amt = parseInt(loanAmount);
    if (!amt || amt <= 0) return;
    await nuiAction('requestLoan', { amount: amt, installments: loanInstallments });
    setLoanAmount('');
  };

  const handleRepayLoan = async (loanId: string, amount: number) => {
    await nuiAction('repayLoan', { loanId, amount });
  };

  const handleCopyIban = () => {
    if (data?.iban) {
      nuiAction('copyToClipboard', { text: data.iban });
      showToast('IBAN copié');
    }
  };

  const handleBuyCard = () => {
    nuiAction('buyCard', {});
  };

  const handleSetPin = () => {
    const pin = pinDigits.join('');
    const confirm = pinConfirmDigits.join('');
    if (pin.length !== 4 || !/^\d{4}$/.test(pin)) {
      setPinFeedback({ type: 'error', message: 'Le code doit contenir 4 chiffres' });
      return;
    }
    if (pin !== confirm) {
      setPinFeedback({ type: 'error', message: 'Les codes ne correspondent pas' });
      return;
    }
    nuiAction('setPin', { pin });
  };

  const handlePinDigit = (
    digits: string[],
    setDigits: (d: string[]) => void,
    refs: React.MutableRefObject<(HTMLInputElement | null)[]>,
    idx: number,
    value: string,
  ) => {
    const v = value.replace(/[^\d]/g, '').slice(-1);
    const next = [...digits];
    next[idx] = v;
    setDigits(next);
    setPinFeedback(null);
    if (v && idx < 3) refs.current[idx + 1]?.focus();
  };

  const handlePinKey = (
    digits: string[],
    setDigits: (d: string[]) => void,
    refs: React.MutableRefObject<(HTMLInputElement | null)[]>,
    idx: number,
    e: React.KeyboardEvent<HTMLInputElement>,
  ) => {
    if (e.key === 'Backspace' && !digits[idx] && idx > 0) {
      refs.current[idx - 1]?.focus();
    }
  };

  if (!visible || !data) return null;

  // ---- Render helpers ----
  const renderTxIcon = (category: string) => {
    const icon = CATEGORY_ICONS[category] || CATEGORY_ICONS.other;
    const isIncome = ['deposit', 'salary', 'loan'].includes(category);
    return (
      <div
        className="bank-tx-icon"
        style={{
          background: isIncome ? 'rgba(34, 197, 94, 0.1)' : 'rgba(239, 68, 68, 0.08)',
          color: isIncome ? '#4ade80' : '#f87171',
        }}
      >
        {icon}
      </div>
    );
  };

  const renderTransaction = (tx: Transaction) => (
    <div className="bank-tx-item" key={tx.id}>
      {renderTxIcon(tx.category)}
      <div className="bank-tx-info">
        <div className="bank-tx-title">{tx.title}</div>
        {tx.description && <div className="bank-tx-desc">{tx.description}</div>}
      </div>
      <div className="bank-tx-right">
        <div className={`bank-tx-amount ${tx.amount >= 0 ? 'income' : 'expense'}`}>
          {tx.amount >= 0 ? '+' : ''}{formatMoney(tx.amount)}
        </div>
        <div className="bank-tx-date">{tx.date}</div>
      </div>
    </div>
  );

  // ---- DASHBOARD ----
  const renderDashboard = () => (
    <div className="bank-page" key="dashboard">
      <div className="bank-content-header">
        <div className="bank-content-header-info">
          <h2>Tableau de bord</h2>
          <p>Bienvenue, {data.playerName} — IBAN <span style={{ fontFamily: "'JetBrains Mono', monospace", color: accentColor, cursor: 'pointer' }} onClick={handleCopyIban}>{data.iban}</span></p>
        </div>
      </div>

      {/* Compact balance strip (3 columns) */}
      <div className="bank-balance-strip">
        <div className="bank-strip-card">
          <div className="bank-strip-icon" style={{ background: `rgba(${accentRgb}, 0.12)`, color: accentColor }}>
            <Landmark size={18} />
          </div>
          <div className="bank-strip-body">
            <div className="bank-strip-label">Compte bancaire</div>
            <div className="bank-strip-amount">{formatMoney(data.bank)}</div>
          </div>
        </div>
        <div className="bank-strip-card">
          <div className="bank-strip-icon" style={{ background: 'rgba(34, 197, 94, 0.1)', color: '#4ade80' }}>
            <Wallet size={18} />
          </div>
          <div className="bank-strip-body">
            <div className="bank-strip-label">Espèces</div>
            <div className="bank-strip-amount income">{formatMoney(data.cash)}</div>
          </div>
        </div>
        <div className="bank-strip-card">
          <div className="bank-strip-icon" style={{
            background: totalDebt > 0 ? 'rgba(239, 68, 68, 0.1)' : 'rgba(34, 197, 94, 0.08)',
            color: totalDebt > 0 ? '#f87171' : '#4ade80',
          }}>
            <CreditCard size={18} />
          </div>
          <div className="bank-strip-body">
            <div className="bank-strip-label">Crédit en cours</div>
            <div className={`bank-strip-amount ${totalDebt > 0 ? 'negative' : ''}`}>
              {totalDebt > 0 ? '-' + formatMoney(totalDebt) : '0$'}
            </div>
          </div>
        </div>
      </div>

      {/* Quick actions */}
      <div className="bank-quick-actions">
        <div className="bank-quick-card">
          <div className="bank-quick-icon" style={{ background: 'rgba(34, 197, 94, 0.1)', color: '#4ade80' }}>
            <ArrowDownToLine size={18} />
          </div>
          <div className="bank-quick-body">
            <div className="bank-quick-label">Déposer</div>
            <div className="bank-quick-row">
              <input
                className="bank-form-input"
                type="number"
                placeholder="Montant"
                value={depositAmount}
                onChange={e => setDepositAmount(e.target.value)}
                onKeyDown={e => e.key === 'Enter' && handleDeposit()}
              />
              <button
                className="bank-btn bank-btn-icon"
                style={{ background: `rgba(${accentRgb}, 0.15)`, color: accentColor, borderColor: `rgba(${accentRgb}, 0.25)` }}
                onClick={handleDeposit}
              >
                <Check size={14} />
              </button>
            </div>
          </div>
        </div>

        <div className="bank-quick-card">
          <div className="bank-quick-icon" style={{ background: 'rgba(239, 68, 68, 0.1)', color: '#f87171' }}>
            <ArrowUpFromLine size={18} />
          </div>
          <div className="bank-quick-body">
            <div className="bank-quick-label">Retirer</div>
            <div className="bank-quick-row">
              <input
                className="bank-form-input"
                type="number"
                placeholder="Montant"
                value={withdrawAmount}
                onChange={e => setWithdrawAmount(e.target.value)}
                onKeyDown={e => e.key === 'Enter' && handleWithdraw()}
              />
              <button
                className="bank-btn bank-btn-icon"
                style={{ background: `rgba(${accentRgb}, 0.15)`, color: accentColor, borderColor: `rgba(${accentRgb}, 0.25)` }}
                onClick={handleWithdraw}
              >
                <Check size={14} />
              </button>
            </div>
          </div>
        </div>
      </div>

      {/* Monthly spending chart */}
      <div className="bank-section-header">
        <span className="bank-section-title">Dépenses mensuelles</span>
      </div>
      <div className="bank-chart-container">
        <div className="bank-chart-bars">
          {monthlySpending.map((m, i) => (
            <div className="bank-chart-bar-col" key={i}>
              <div className="bank-chart-bar-value">{m.total > 0 ? formatMoney(m.total) : ''}</div>
              <div className="bank-chart-bar-track">
                <div
                  className="bank-chart-bar-fill"
                  style={{
                    height: `${Math.max((m.total / maxMonthly) * 100, 3)}%`,
                    background: `rgba(${accentRgb}, ${0.4 + (i / 5) * 0.5})`,
                  }}
                />
              </div>
              <div className="bank-chart-bar-label">{m.label}</div>
            </div>
          ))}
        </div>
      </div>

      {/* Recent transactions */}
      <div className="bank-section-header">
        <span className="bank-section-title">Transactions récentes</span>
        <button
          className="bank-section-link"
          style={{ color: accentColor }}
          onClick={() => setActiveTab('history')}
        >
          Voir tout
        </button>
      </div>
      <div className="bank-tx-list">
        {data.history.slice(0, 5).map(renderTransaction)}
        {data.history.length === 0 && (
          <div className="bank-tx-empty">Aucune transaction</div>
        )}
      </div>
    </div>
  );

  // ---- TRANSFERS ----
  const renderTransfers = () => (
    <div className="bank-page" key="transfers">
      <div className="bank-content-header">
        <div className="bank-content-header-info">
          <h2>Virements</h2>
          <p>Envoyez de l'argent vers un autre compte</p>
        </div>
      </div>

      <div className="bank-transfer-form">
        <div className="bank-form-group">
          <label className="bank-form-label">IBAN du destinataire</label>
          <input
            className="bank-form-input mono"
            placeholder="FR00 0000 0000 0000"
            value={transferIban}
            onChange={e => setTransferIban(e.target.value)}
          />
        </div>
        <div className="bank-form-group">
          <label className="bank-form-label">Montant</label>
          <div className="bank-amount-input-wrapper">
            <input
              type="number"
              placeholder="0"
              value={transferAmount}
              onChange={e => setTransferAmount(e.target.value)}
            />
            <span className="bank-amount-suffix">$</span>
          </div>
        </div>
        <div className="bank-form-group">
          <label className="bank-form-label">Motif (optionnel)</label>
          <input
            className="bank-form-input"
            placeholder="Raison du virement..."
            value={transferReason}
            onChange={e => setTransferReason(e.target.value)}
          />
        </div>
        <button
          className="bank-btn bank-btn-accent"
          style={{ background: `rgba(${accentRgb}, 0.18)`, color: accentColor, borderColor: `rgba(${accentRgb}, 0.3)` }}
          onClick={handleTransfer}
        >
          <Send size={15} /> Envoyer le virement
        </button>
      </div>

      <div className="bank-divider" />

      <div className="bank-section-header">
        <span className="bank-section-title">Votre IBAN</span>
      </div>
      <div className="bank-iban-box" onClick={handleCopyIban}>
        <div className="bank-iban-text">{data.iban}</div>
        <Copy size={14} style={{ color: 'var(--text-secondary)' }} />
      </div>

      {data.pendingTransfers.length > 0 && (
        <>
          <div className="bank-section-header">
            <span className="bank-section-title">Virements en attente</span>
            <span className="bank-section-count">{data.pendingTransfers.length}</span>
          </div>
          <div className="bank-pending-list">
            {data.pendingTransfers.map(pt => (
              <div className="bank-pending-item" key={pt.id}>
                <div className="bank-tx-icon" style={{ background: 'rgba(34,197,94,0.1)', color: '#4ade80' }}>
                  <ArrowDownToLine size={16} />
                </div>
                <div className="bank-pending-info">
                  <div className="bank-pending-from">De: {pt.fromIban}</div>
                  <div className="bank-pending-desc">{pt.description || 'Virement reçu'}</div>
                  <div style={{ fontSize: 10, color: 'var(--text-tertiary)', marginTop: 2 }}>{pt.date}</div>
                </div>
                <div className="bank-pending-amount">+{formatMoney(pt.amount)}</div>
                <button
                  className="bank-btn bank-btn-sm bank-btn-accent"
                  style={{ background: `rgba(${accentRgb}, 0.18)`, color: accentColor, borderColor: `rgba(${accentRgb}, 0.3)` }}
                  onClick={() => handleAcceptTransfer(pt.id)}
                >
                  <Check size={14} /> Accepter
                </button>
              </div>
            ))}
          </div>
        </>
      )}
    </div>
  );

  // ---- HISTORY ----
  const renderHistory = () => (
    <div className="bank-page" key="history">
      <div className="bank-content-header">
        <div className="bank-content-header-info">
          <h2>Historique</h2>
          <p>Toutes vos transactions</p>
        </div>
      </div>

      <div className="bank-history-filters">
        <div className="bank-filter-search">
          <Search size={14} />
          <input
            placeholder="Rechercher..."
            value={historySearch}
            onChange={e => setHistorySearch(e.target.value)}
          />
        </div>
        <button
          className="bank-filter-chip"
          style={historyCategory === 'all' ? { background: `rgba(${accentRgb}, 0.15)`, color: accentColor, borderColor: `rgba(${accentRgb}, 0.3)` } : {}}
          onClick={() => setHistoryCategory('all')}
        >
          Tout
        </button>
        {allCategories.map(cat => (
          <button
            key={cat}
            className="bank-filter-chip"
            style={historyCategory === cat ? { background: `rgba(${accentRgb}, 0.15)`, color: accentColor, borderColor: `rgba(${accentRgb}, 0.3)` } : {}}
            onClick={() => setHistoryCategory(cat)}
          >
            {data.categories[cat]?.label || cat}
          </button>
        ))}
      </div>

      {historyCategory === 'all' && categoryBreakdown.length > 0 && (
        <>
          <div className="bank-section-header">
            <span className="bank-section-title">Par catégorie</span>
          </div>
          <div className="bank-categories-grid">
            {categoryBreakdown.slice(0, 6).map(cat => (
              <div className="bank-cat-item" key={cat.key}>
                <div
                  className="bank-cat-icon"
                  style={{
                    background: cat.total >= 0 ? 'rgba(34,197,94,0.1)' : 'rgba(239,68,68,0.08)',
                    color: cat.total >= 0 ? '#4ade80' : '#f87171',
                  }}
                >
                  {CATEGORY_ICONS[cat.key] || CATEGORY_ICONS.other}
                </div>
                <div className="bank-cat-info">
                  <div className="bank-cat-label">{cat.label}</div>
                  <div className="bank-cat-count">{cat.count} transaction{cat.count > 1 ? 's' : ''}</div>
                </div>
                <div className="bank-cat-amount" style={{ color: cat.total >= 0 ? '#4ade80' : '#f87171' }}>
                  {cat.total >= 0 ? '+' : ''}{formatMoney(cat.total)}
                </div>
              </div>
            ))}
          </div>
        </>
      )}

      <div className="bank-section-header">
        <span className="bank-section-title">Transactions</span>
        <span className="bank-section-count">{filteredHistory.length} résultat{filteredHistory.length !== 1 ? 's' : ''}</span>
      </div>
      <div className="bank-tx-list">
        {filteredHistory.map(renderTransaction)}
        {filteredHistory.length === 0 && (
          <div className="bank-tx-empty">Aucune transaction trouvée</div>
        )}
      </div>
    </div>
  );

  // ---- CREDITS ----
  const renderCredits = () => {
    if (!data) return null;
    const activeLoans = data.credits.filter(c => !c.paidOff);
    const paidLoans = data.credits.filter(c => c.paidOff);
    const canRequestLoan = data.creditConfig && activeLoans.length < (data.creditConfig.maxActiveLoans || 1);

    return (
      <div className="bank-page" key="credits">
        <div className="bank-content-header">
          <div className="bank-content-header-info">
            <h2>Crédits</h2>
            <p>Gérez vos emprunts et demandez un nouveau crédit</p>
          </div>
        </div>

        {data.creditConfig && canRequestLoan && (
          <>
            <div className="bank-section-header">
              <span className="bank-section-title">Nouveau crédit</span>
            </div>
            <div className="bank-credit-form">
              <div className="bank-form-group">
                <label className="bank-form-label">
                  Montant souhaité ({formatMoney(data.creditConfig.minAmount)} - {formatMoney(data.creditConfig.maxAmount)})
                </label>
                <div className="bank-amount-input-wrapper">
                  <input
                    type="number"
                    placeholder="0"
                    value={loanAmount}
                    onChange={e => setLoanAmount(e.target.value)}
                    min={data.creditConfig.minAmount}
                    max={data.creditConfig.maxAmount}
                  />
                  <span className="bank-amount-suffix">$</span>
                </div>
              </div>
              <div className="bank-form-group">
                <label className="bank-form-label">Nombre de mensualités</label>
                <div className="bank-installment-selector">
                  {data.creditConfig.installments.map(n => {
                    const amt = parseInt(loanAmount) || 0;
                    const total = amt + amt * data.creditConfig!.interestRate;
                    const perMonth = amt > 0 ? Math.ceil(total / n) : 0;
                    return (
                      <button
                        key={n}
                        className="bank-installment-option"
                        style={loanInstallments === n ? { background: `rgba(${accentRgb}, 0.15)`, borderColor: `rgba(${accentRgb}, 0.35)`, color: accentColor } : {}}
                        onClick={() => setLoanInstallments(n)}
                      >
                        {n}x
                        {perMonth > 0 && <span>{formatMoney(perMonth)}/mois</span>}
                      </button>
                    );
                  })}
                </div>
              </div>

              {parseInt(loanAmount) > 0 && (
                <div className="bank-credit-summary">
                  <div className="bank-credit-stat">
                    <div className="bank-credit-stat-label">Emprunté</div>
                    <div className="bank-credit-stat-value">{formatMoney(parseInt(loanAmount))}</div>
                  </div>
                  <div className="bank-credit-stat">
                    <div className="bank-credit-stat-label">Intérêts ({(data.creditConfig.interestRate * 100).toFixed(0)}%)</div>
                    <div className="bank-credit-stat-value" style={{ color: '#f87171' }}>
                      +{formatMoney(Math.ceil(parseInt(loanAmount) * data.creditConfig.interestRate))}
                    </div>
                  </div>
                  <div className="bank-credit-stat">
                    <div className="bank-credit-stat-label">Total à rembourser</div>
                    <div className="bank-credit-stat-value">
                      {formatMoney(Math.ceil(parseInt(loanAmount) * (1 + data.creditConfig.interestRate)))}
                    </div>
                  </div>
                </div>
              )}

              <button
                className="bank-btn bank-btn-accent"
                style={{ background: `rgba(${accentRgb}, 0.18)`, color: accentColor, borderColor: `rgba(${accentRgb}, 0.3)` }}
                onClick={handleRequestLoan}
              >
                <CreditCard size={15} /> Demander le crédit
              </button>
            </div>
            <div className="bank-divider" />
          </>
        )}

        {!canRequestLoan && data.creditConfig && (
          <div className="bank-warning-box">
            <AlertTriangle size={16} /> Vous avez déjà un crédit actif. Remboursez-le avant d'en demander un nouveau.
          </div>
        )}

        {activeLoans.length > 0 && (
          <>
            <div className="bank-section-header">
              <span className="bank-section-title">Crédits actifs</span>
            </div>
            {activeLoans.map(loan => {
              const remaining = loan.totalDue - loan.paid;
              const progress = loan.totalDue > 0 ? (loan.paid / loan.totalDue) * 100 : 0;
              return (
                <div className="bank-loan-card" key={loan.id}>
                  <div className="bank-loan-header">
                    <div className="bank-loan-title">Crédit de {formatMoney(loan.originalAmount)}</div>
                    <div className="bank-loan-badge active">En cours</div>
                  </div>
                  <div className="bank-loan-details">
                    <div>
                      <div className="bank-loan-detail-label">Montant</div>
                      <div className="bank-loan-detail-value">{formatMoney(loan.originalAmount)}</div>
                    </div>
                    <div>
                      <div className="bank-loan-detail-label">Intérêts</div>
                      <div className="bank-loan-detail-value" style={{ color: '#f87171' }}>+{formatMoney(loan.interest)}</div>
                    </div>
                    <div>
                      <div className="bank-loan-detail-label">Payé</div>
                      <div className="bank-loan-detail-value" style={{ color: '#4ade80' }}>{formatMoney(loan.paid)}</div>
                    </div>
                    <div>
                      <div className="bank-loan-detail-label">Restant</div>
                      <div className="bank-loan-detail-value">{formatMoney(remaining)}</div>
                    </div>
                  </div>
                  <div className="bank-loan-progress">
                    <div className="bank-loan-progress-fill" style={{ width: `${progress}%`, background: accentColor }} />
                  </div>
                  <div style={{ display: 'flex', gap: 8 }}>
                    <button
                      className="bank-btn bank-btn-sm bank-btn-accent"
                      style={{ background: `rgba(${accentRgb}, 0.18)`, color: accentColor, borderColor: `rgba(${accentRgb}, 0.3)`, flex: 1 }}
                      onClick={() => handleRepayLoan(loan.id, loan.perInstallment)}
                    >
                      Payer {formatMoney(Math.min(loan.perInstallment, remaining))}
                    </button>
                    <button
                      className="bank-btn bank-btn-sm bank-btn-outline"
                      style={{ flex: 1 }}
                      onClick={() => handleRepayLoan(loan.id, remaining)}
                    >
                      Tout rembourser
                    </button>
                  </div>
                </div>
              );
            })}
          </>
        )}

        {paidLoans.length > 0 && (
          <>
            <div className="bank-divider" />
            <div className="bank-section-header">
              <span className="bank-section-title">Crédits remboursés</span>
            </div>
            {paidLoans.map(loan => (
              <div className="bank-loan-card" key={loan.id} style={{ opacity: 0.6 }}>
                <div className="bank-loan-header">
                  <div className="bank-loan-title">Crédit de {formatMoney(loan.originalAmount)}</div>
                  <div className="bank-loan-badge paid">Remboursé</div>
                </div>
                <div className="bank-loan-details">
                  <div>
                    <div className="bank-loan-detail-label">Montant</div>
                    <div className="bank-loan-detail-value">{formatMoney(loan.originalAmount)}</div>
                  </div>
                  <div>
                    <div className="bank-loan-detail-label">Total payé</div>
                    <div className="bank-loan-detail-value">{formatMoney(loan.totalDue)}</div>
                  </div>
                  <div>
                    <div className="bank-loan-detail-label">Mensualités</div>
                    <div className="bank-loan-detail-value">{loan.installments}x</div>
                  </div>
                  <div>
                    <div className="bank-loan-detail-label">Date</div>
                    <div className="bank-loan-detail-value">{loan.createdDate}</div>
                  </div>
                </div>
                <div className="bank-loan-progress">
                  <div className="bank-loan-progress-fill" style={{ width: '100%', background: '#4ade80' }} />
                </div>
              </div>
            ))}
          </>
        )}

        {data.credits.length === 0 && !canRequestLoan && (
          <div className="bank-tx-empty">Aucun crédit</div>
        )}
      </div>
    );
  };

  // ---- CARD TAB ----
  const renderCard = () => {
    const cardConfig = data.cardConfig || { price: 250, itemName: 'bank_card' };
    return (
      <div className="bank-page" key="card">
        <div className="bank-content-header">
          <div className="bank-content-header-info">
            <h2>Carte bancaire</h2>
            <p>Gérez votre carte et son code d'accès aux distributeurs</p>
          </div>
        </div>

        <div className="bank-card-page">
          <div
            className="bank-card"
            style={{ background: `linear-gradient(135deg, ${accentColor}, rgba(${accentRgb}, 0.6))` }}
          >
            <div className="bank-card-bg" />
            <div className="bank-card-chip" />
            <div className="bank-card-number">{data.cardNumber}</div>
            <div className="bank-card-bottom">
              <div>
                <div className="bank-card-holder-label">Titulaire</div>
                <div className="bank-card-holder">{data.playerName}</div>
              </div>
              <div>
                <div className="bank-card-iban-label">IBAN</div>
                <div className="bank-card-iban">{data.iban}</div>
              </div>
            </div>
          </div>

          <div className="bank-card-side">
            <div className={`bank-card-status ${data.hasCard ? 'owned' : 'missing'}`}>
              <div className="bank-card-status-icon">
                {data.hasCard ? <ShieldCheck size={18} /> : <ShieldOff size={18} />}
              </div>
              <div className="bank-card-status-body">
                <div className="bank-card-status-title">
                  {data.hasCard ? 'Carte en votre possession' : 'Aucune carte physique'}
                </div>
                <div className="bank-card-status-desc">
                  {data.hasCard
                    ? 'Vous pouvez utiliser tous les distributeurs avec votre code.'
                    : 'Achetez une carte pour accéder aux distributeurs.'}
                </div>
              </div>
              {!data.hasCard && (
                <button
                  className="bank-btn bank-btn-sm bank-btn-accent"
                  style={{ background: `rgba(${accentRgb}, 0.18)`, color: accentColor, borderColor: `rgba(${accentRgb}, 0.3)` }}
                  onClick={handleBuyCard}
                  disabled={data.bank < cardConfig.price}
                >
                  Acheter ({formatMoney(cardConfig.price)})
                </button>
              )}
            </div>

            <div className="bank-card-meta">
              <div className="bank-card-meta-item">
                <div className="bank-card-meta-label">Numéro</div>
                <div className="bank-card-meta-value" style={{ fontFamily: "'JetBrains Mono', monospace", letterSpacing: 1 }}>
                  {data.cardNumber}
                </div>
              </div>
              <div className="bank-card-meta-item">
                <div className="bank-card-meta-label">Statut code</div>
                <div className="bank-card-meta-value" style={{ color: data.hasPin ? '#4ade80' : '#f87171' }}>
                  {data.hasPin ? 'Défini' : 'Non défini'}
                </div>
              </div>
            </div>

            <div className="bank-section-header">
              <span className="bank-section-title">{data.hasPin ? 'Modifier le code' : 'Définir un code'}</span>
            </div>

            <div className="bank-credit-form">
              <div className="bank-form-group">
                <label className="bank-form-label">Nouveau code (4 chiffres)</label>
                <div className="bank-pin-grid">
                  {pinDigits.map((d, i) => (
                    <input
                      key={i}
                      ref={el => { pinRefs.current[i] = el; }}
                      className={`bank-pin-cell ${d ? 'filled' : ''}`}
                      type="password"
                      inputMode="numeric"
                      maxLength={1}
                      value={d}
                      onChange={e => handlePinDigit(pinDigits, setPinDigits, pinRefs, i, e.target.value)}
                      onKeyDown={e => handlePinKey(pinDigits, setPinDigits, pinRefs, i, e)}
                    />
                  ))}
                </div>
              </div>
              <div className="bank-form-group">
                <label className="bank-form-label">Confirmer le code</label>
                <div className="bank-pin-grid">
                  {pinConfirmDigits.map((d, i) => (
                    <input
                      key={i}
                      ref={el => { pinConfirmRefs.current[i] = el; }}
                      className={`bank-pin-cell ${d ? 'filled' : ''}`}
                      type="password"
                      inputMode="numeric"
                      maxLength={1}
                      value={d}
                      onChange={e => handlePinDigit(pinConfirmDigits, setPinConfirmDigits, pinConfirmRefs, i, e.target.value)}
                      onKeyDown={e => handlePinKey(pinConfirmDigits, setPinConfirmDigits, pinConfirmRefs, i, e)}
                    />
                  ))}
                </div>
              </div>
              {pinFeedback && (
                <div className={`bank-pin-info ${pinFeedback.type}`}>
                  {pinFeedback.type === 'error' ? <AlertTriangle size={12} /> : <Check size={12} />}
                  <span>{pinFeedback.message}</span>
                </div>
              )}
              <button
                className="bank-btn bank-btn-accent"
                style={{ background: `rgba(${accentRgb}, 0.18)`, color: accentColor, borderColor: `rgba(${accentRgb}, 0.3)` }}
                onClick={handleSetPin}
              >
                <KeyRound size={15} /> {data.hasPin ? 'Modifier le code' : 'Enregistrer le code'}
              </button>
            </div>
          </div>
        </div>
      </div>
    );
  };

  // ---- MAIN RENDER ----
  const tabs: { id: TabType; label: string; icon: React.ReactNode }[] = [
    { id: 'dashboard', label: 'Tableau de bord', icon: <LayoutDashboard size={16} /> },
    { id: 'transfers', label: 'Virements', icon: <ArrowLeftRight size={16} /> },
    { id: 'history', label: 'Historique', icon: <History size={16} /> },
    { id: 'credits', label: 'Crédits', icon: <CreditCard size={16} /> },
    { id: 'card', label: 'Carte', icon: <KeyRound size={16} /> },
  ];

  return (
    <div className={`bank-overlay ${hiding ? 'bank-hiding' : ''}`}>
      <div
        className={`bank-container ${brand ? `bank-brand-${brand.id}` : ''}`}
        style={{ ...accentVars, ...brandVars } as React.CSSProperties}
      >
        <WaveBackground accentColor={accentColor} opacity={0.5} />
        {/* Sidebar */}
        <div className="bank-sidebar">
          {brand ? (
            <div
              className="bank-brand-hero"
              style={{ background: `linear-gradient(160deg, ${brandBg} 0%, ${brandBg}dd 60%, rgba(0,0,0,0.4) 100%)` }}
            >
              <div className="bank-brand-hero-shine" />
              <div className="bank-brand-hero-inner">
                {brandLogo ? (
                  <img
                    className="bank-brand-logo"
                    src={brandLogo}
                    alt={brand.name}
                    onError={(e) => { (e.target as HTMLImageElement).style.display = 'none'; }}
                  />
                ) : (
                  <div className="bank-brand-logo-fallback"><Landmark size={28} /></div>
                )}
                <div className="bank-brand-hero-text">
                  {brand.tagline && <p>{brand.tagline}</p>}
                </div>
              </div>
            </div>
          ) : (
            <div className="bank-sidebar-header">
              <div className="bank-sidebar-icon" style={{ background: `linear-gradient(135deg, ${accentColor}, ${accentColor}88)` }}>
                <Landmark size={20} />
              </div>
              <div className="bank-sidebar-title">
                <h1>Banque</h1>
                <p>Gestion de compte</p>
              </div>
            </div>
          )}

          {/* Nav */}
          <nav className="bank-sidebar-nav">
            {tabs.map(tab => (
              <button
                key={tab.id}
                className={`bank-sidebar-item ${activeTab === tab.id ? 'active' : ''}`}
                onClick={() => setActiveTab(tab.id)}
              >
                {activeTab === tab.id && <div className="bank-sidebar-indicator" style={{ background: accentColor }} />}
                {tab.icon}
                <span>{tab.label}</span>
                {tab.id === 'transfers' && data.pendingTransfers.length > 0 && (
                  <span className="bank-nav-badge">{data.pendingTransfers.length}</span>
                )}
                <ChevronRight size={14} className="bank-sidebar-arrow" />
              </button>
            ))}
          </nav>

          {/* Footer */}
          <div className="bank-sidebar-footer">
            <button className="bank-close-btn" onClick={handleClose}>
              <X size={16} />
              <span>Fermer</span>
            </button>
          </div>
        </div>

        {/* Content */}
        <div className="bank-content">
          {/* {brand && (
            <div
              className="bank-brand-ambient"
              style={{ background: `radial-gradient(circle at 0% 0%, ${brandBg}55 0%, transparent 55%)` }}
              aria-hidden
            />
          )} */}
          {activeTab === 'dashboard' && renderDashboard()}
          {activeTab === 'transfers' && renderTransfers()}
          {activeTab === 'history' && renderHistory()}
          {activeTab === 'credits' && renderCredits()}
          {activeTab === 'card' && renderCard()}
        </div>

        {toast && (
          <div className="bank-toast">
            <Check size={16} /> <span>{toast}</span>
          </div>
        )}
      </div>
    </div>
  );
};

export default Bank;
