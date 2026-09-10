import React, { useState, useEffect, useCallback, useMemo, useRef } from 'react';
import { generateAccentVars } from '@/utils/accentColors';
import {
  ArrowDownToLine, ArrowUpFromLine, LogOut, Delete, Wallet, Landmark,
  TrendingDown, Loader2, Check, X, AlertTriangle, KeyRound, ChevronLeft,
} from 'lucide-react';
import type { ATMData, ATMProps } from './types';
import './ATM.css';

const GetParentResourceName = () => 'null-core';

type Screen = 'boot' | 'pin' | 'menu' | 'withdraw' | 'deposit' | 'spending' | 'processing' | 'success';

function fmt(n: number): string {
  return n.toLocaleString('fr-FR') + '$';
}

const QUICK_AMOUNTS = [50, 100, 250, 500, 1000, 2500];

const ATM: React.FC<ATMProps> = ({ visible, onClose, primaryColor }) => {
  const [data, setData] = useState<ATMData | null>(null);
  const [hiding, setHiding] = useState(false);
  const [screen, setScreen] = useState<Screen>('boot');
  const [pin, setPin] = useState<string>('');
  const [pinError, setPinError] = useState<string | null>(null);
  const [pinAttempts, setPinAttempts] = useState(0);
  const [amount, setAmount] = useState<string>('');
  const [feedback, setFeedback] = useState<{ type: 'success' | 'error'; message: string } | null>(null);
  const [lastOp, setLastOp] = useState<{ type: 'withdraw' | 'deposit'; amount: number } | null>(null);
  const bootTimer = useRef<ReturnType<typeof setTimeout> | null>(null);

  const accent = data?.brand?.accent || primaryColor || '#10b981';
  const accentVars = useMemo(() => generateAccentVars('--atm-accent', accent), [accent]);

  const nuiAction = useCallback((action: string, payload: any = {}) => {
    return fetch(`https://${GetParentResourceName()}/atm:${action}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
    }).then(r => r.json()).catch(() => null);
  }, []);

  const doClose = useCallback(() => {
    setHiding(true);
    setTimeout(() => {
      setHiding(false);
      setData(null);
      setScreen('boot');
      setPin('');
      setPinError(null);
      setPinAttempts(0);
      setAmount('');
      setFeedback(null);
      setLastOp(null);
      onClose();
      fetch(`https://${GetParentResourceName()}/atm:close`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({}),
      });
    }, 300);
  }, [onClose]);

  // NUI bridge
  useEffect(() => {
    const handler = (e: MessageEvent) => {
      const { action, data: d } = e.data || {};
      if (action === 'atm:open') {
        if (d) setData(d);
        setScreen('boot');
        setPin('');
        setPinError(null);
        setPinAttempts(0);
        setAmount('');
        setFeedback(null);
        setLastOp(null);
        if (bootTimer.current) clearTimeout(bootTimer.current);
        bootTimer.current = setTimeout(() => setScreen('pin'), 1400);
      }
      if (action === 'atm:close') doClose();
      if (action === 'atm:update' && d) setData(prev => prev ? { ...prev, ...d } : d);
      if (action === 'atm:opResult' && d) {
        if (d.success) {
          setFeedback({ type: 'success', message: d.message || 'Opération réussie' });
          setLastOp({ type: d.type, amount: d.amount });
          setScreen('success');
          setAmount('');
          setTimeout(() => setScreen('menu'), 2200);
        } else {
          setFeedback({ type: 'error', message: d.message || 'Opération refusée' });
          setScreen('menu');
        }
        setTimeout(() => setFeedback(null), 3000);
      }
    };
    window.addEventListener('message', handler);
    return () => window.removeEventListener('message', handler);
  }, [doClose, pinAttempts]);

  // ESC handler
  useEffect(() => {
    if (!visible) return;
    const h = (e: KeyboardEvent) => { if (e.key === 'Escape') doClose(); };
    window.addEventListener('keydown', h);
    return () => window.removeEventListener('keydown', h);
  }, [visible, doClose]);

  const submitPin = useCallback((p: string) => {
    nuiAction('verifyPin', { pin: p }).then((res: any) => {
      if (res && res.success) {
        setPinError(null);
        setScreen('menu');
      } else {
        setPinAttempts(a => a + 1);
        setPinError(res?.message || 'Code incorrect');
        setPin('');
        setTimeout(() => {
          setPinError(null);
        }, 1500);
      }
    });
  }, [nuiAction]);

  const onDigit = (digit: string) => {
    if (screen === 'pin') {
      if (pin.length < 4) {
        const next = pin + digit;
        setPin(next);
        setPinError(null);
        if (next.length === 4) {
          setTimeout(() => submitPin(next), 250);
        }
      }
    } else if (screen === 'withdraw' || screen === 'deposit') {
      if (amount.length < 8) setAmount(amount + digit);
    }
  };

  const onClear = () => {
    if (screen === 'pin') {
      setPin('');
      setPinError(null);
    } else {
      setAmount('');
    }
  };

  const onBack = () => {
    if (screen === 'pin') {
      setPin(pin.slice(0, -1));
      setPinError(null);
    } else {
      setAmount(amount.slice(0, -1));
    }
  };

  const doOperation = (type: 'withdraw' | 'deposit') => {
    const amt = parseInt(amount);
    if (!amt || amt <= 0) {
      setFeedback({ type: 'error', message: 'Montant invalide' });
      setTimeout(() => setFeedback(null), 2000);
      return;
    }
    setScreen('processing');
    nuiAction(type, { amount: amt });
  };

  if (!visible || !data) return null;

  const maxSpending = Math.max(...(data.spending?.map(s => s.total) || [1]), 1);
  const totalSpending = (data.spending || []).reduce((s, m) => s + m.total, 0);

  const renderKeypad = (mode: 'pin' | 'amount') => (
    <div className="atm-keypad">
      {['1','2','3','4','5','6','7','8','9'].map(d => (
        <button key={d} className="atm-key" onClick={() => onDigit(d)}>
          <span>{d}</span>
        </button>
      ))}
      <button className="atm-key atm-key-action" onClick={onClear}>
        <span>EFF</span>
      </button>
      <button className="atm-key" onClick={() => onDigit('0')}>
        <span>0</span>
      </button>
      <button className="atm-key atm-key-action" onClick={onBack}>
        <Delete size={18} />
      </button>
    </div>
  );

  return (
    <div className={`atm-overlay ${hiding ? 'atm-hiding' : ''}`} style={accentVars as React.CSSProperties}>
      <div className="atm-machine">
        {/* Top bezel */}
        <div className="atm-bezel-top">
          <div className="atm-brand">
            <span className="atm-brand-dot" />
            {data.brand?.name || 'Fleeca Bank'}
          </div>
          <div className="atm-bezel-info">
            <span>ATM #{data.atmId}</span>
            <span className="atm-led atm-led-on" /> EN LIGNE
          </div>
        </div>

        {/* Screen */}
        <div className="atm-screen">
          <div className="atm-screen-scanline" aria-hidden />
          <div className="atm-screen-glow" aria-hidden />

          {screen === 'boot' && (
            <div className="atm-view atm-boot">
              <Loader2 className="atm-spinner" size={32} />
              <div className="atm-boot-text">Lecture de la carte...</div>
              <div className="atm-card-hint">{data.cardNumber}</div>
            </div>
          )}

          {screen === 'pin' && (
            <div className="atm-view atm-pin-view">
              <div className="atm-screen-header">
                <KeyRound size={14} />
                <span>Authentification requise</span>
              </div>
              <div className="atm-pin-title">Entrez votre code à 4 chiffres</div>
              <div className="atm-pin-dots">
                {[0,1,2,3].map(i => (
                  <div key={i} className={`atm-pin-dot ${pin.length > i ? 'filled' : ''} ${pinError ? 'error' : ''}`} />
                ))}
              </div>
              {pinError && (
                <div className="atm-error">
                  <AlertTriangle size={14} />
                  <span>{pinError}{pinAttempts > 0 ? ` — Tentative ${pinAttempts}/3` : ''}</span>
                </div>
              )}
              {!pinError && !data.hasPin && (
                <div className="atm-warning">
                  <AlertTriangle size={14} />
                  <span>Aucun code défini. Allez à la banque pour le configurer.</span>
                </div>
              )}
              {renderKeypad('pin')}
            </div>
          )}

          {screen === 'menu' && (
            <div className="atm-view atm-menu">
              <div className="atm-balance-block">
                <div className="atm-balance-label">Solde disponible</div>
                <div className="atm-balance-amount">{fmt(data.bank)}</div>
                <div className="atm-balance-iban">{data.iban}</div>
              </div>

              <div className="atm-actions">
                <button className="atm-action atm-action-primary" onClick={() => { setAmount(''); setScreen('withdraw'); }}>
                  <ArrowUpFromLine size={20} />
                  <div>
                    <span>Retirer</span>
                    <small>Espèces · Cash {fmt(data.cash)}</small>
                  </div>
                </button>
                <button className="atm-action" onClick={() => { setAmount(''); setScreen('deposit'); }}>
                  <ArrowDownToLine size={20} />
                  <div>
                    <span>Déposer</span>
                    <small>Espèces vers compte</small>
                  </div>
                </button>
                <button className="atm-action" onClick={() => setScreen('spending')}>
                  <TrendingDown size={20} />
                  <div>
                    <span>Mes dépenses</span>
                    <small>Graphique 6 mois</small>
                  </div>
                </button>
                <button className="atm-action atm-action-exit" onClick={doClose}>
                  <LogOut size={20} />
                  <div>
                    <span>Éjecter la carte</span>
                    <small>Fin de session</small>
                  </div>
                </button>
              </div>

              {data.recent && data.recent.length > 0 && (
                <div className="atm-recent">
                  <div className="atm-recent-title">Dernières opérations</div>
                  {data.recent.slice(0, 3).map(tx => (
                    <div key={tx.id} className="atm-recent-row">
                      <span className="atm-recent-title-text">{tx.title}</span>
                      <span className={`atm-recent-amount ${tx.amount >= 0 ? 'income' : 'expense'}`}>
                        {tx.amount >= 0 ? '+' : ''}{fmt(tx.amount)}
                      </span>
                    </div>
                  ))}
                </div>
              )}
            </div>
          )}

          {(screen === 'withdraw' || screen === 'deposit') && (
            <div className="atm-view atm-amount-view">
              <button className="atm-back" onClick={() => { setAmount(''); setScreen('menu'); }}>
                <ChevronLeft size={14} /> Retour
              </button>
              <div className="atm-screen-header">
                {screen === 'withdraw' ? <ArrowUpFromLine size={14} /> : <ArrowDownToLine size={14} />}
                <span>{screen === 'withdraw' ? 'Retrait d\'espèces' : 'Dépôt sur compte'}</span>
              </div>

              <div className="atm-amount-display">
                <div className="atm-amount-label">Montant</div>
                <div className="atm-amount-value">{amount ? fmt(parseInt(amount)) : '0$'}</div>
                <div className="atm-amount-sub">
                  {screen === 'withdraw' ? `Disponible: ${fmt(data.bank)}` : `Espèces: ${fmt(data.cash)}`}
                </div>
              </div>

              <div className="atm-quick">
                {QUICK_AMOUNTS.map(q => (
                  <button key={q} className="atm-quick-btn" onClick={() => setAmount(String(q))}>
                    {fmt(q)}
                  </button>
                ))}
              </div>

              {renderKeypad('amount')}

              <button
                className="atm-confirm"
                onClick={() => doOperation(screen)}
                disabled={!amount || parseInt(amount) <= 0}
              >
                <Check size={16} /> Valider
              </button>
            </div>
          )}

          {screen === 'spending' && (
            <div className="atm-view atm-spending-view">
              <button className="atm-back" onClick={() => setScreen('menu')}>
                <ChevronLeft size={14} /> Retour
              </button>
              <div className="atm-screen-header">
                <TrendingDown size={14} />
                <span>Dépenses · 6 derniers mois</span>
              </div>

              <div className="atm-spending-total">
                <div className="atm-spending-total-label">Total</div>
                <div className="atm-spending-total-value">{fmt(totalSpending)}</div>
              </div>

              <div className="atm-chart">
                {(data.spending || []).map((m, i) => (
                  <div className="atm-chart-col" key={i}>
                    <div className="atm-chart-value">{m.total > 0 ? fmt(m.total) : ''}</div>
                    <div className="atm-chart-track">
                      <div
                        className="atm-chart-fill"
                        style={{ height: `${Math.max((m.total / maxSpending) * 100, 3)}%` }}
                      />
                    </div>
                    <div className="atm-chart-label">{m.label}</div>
                  </div>
                ))}
              </div>
            </div>
          )}

          {screen === 'processing' && (
            <div className="atm-view atm-processing">
              <Loader2 className="atm-spinner" size={36} />
              <div className="atm-processing-text">Transaction en cours...</div>
            </div>
          )}

          {screen === 'success' && lastOp && (
            <div className="atm-view atm-success">
              <div className="atm-success-icon">
                <Check size={36} />
              </div>
              <div className="atm-success-title">
                {lastOp.type === 'withdraw' ? 'Retrait validé' : 'Dépôt validé'}
              </div>
              <div className="atm-success-amount">{fmt(lastOp.amount)}</div>
              <div className="atm-success-hint">Récupérez votre argent</div>
            </div>
          )}
        </div>

        {/* Bottom bezel */}
        <div className="atm-bezel-bottom">
          <div className="atm-slot atm-slot-card">
            <div className="atm-slot-line" />
            <span>CARTE</span>
          </div>
          <div className="atm-slot atm-slot-cash">
            <div className="atm-slot-line wide" />
            <span>BILLETS</span>
          </div>
        </div>

        {feedback && (
          <div className={`atm-toast ${feedback.type}`}>
            {feedback.type === 'success' ? <Check size={14} /> : <X size={14} />}
            <span>{feedback.message}</span>
          </div>
        )}
      </div>
    </div>
  );
};

export default ATM;
