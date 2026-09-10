import React, { useState, useEffect, useCallback, useMemo } from 'react';
import { DeviceConfig, DeviceDifficulty, DeviceStatus, IllegalDeviceProps } from './types';
import CrewApp from './apps/CrewApp';
import MarketApp from './apps/MarketApp';
import './IllegalDevice.css';

const GetParentResourceName = () => 'null-core';

// Icônes d'app : SVG inline (toujours rendues, aucune dépendance de fichier)
const APP_ICONS: Record<string, React.ReactNode> = {
  gofast: (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M5 17h2l1.5-4.5A2 2 0 0 1 10.4 11H16a2 2 0 0 1 1.9 1.4L19 16h.5a1.5 1.5 0 0 1 1.5 1.5V18a1 1 0 0 1-1 1h-1" />
      <path d="M5 17H4a1 1 0 0 1-1-1v-.5A1.5 1.5 0 0 1 4.5 14H5" />
      <circle cx="7.5" cy="18.5" r="1.8" />
      <circle cx="17" cy="18.5" r="1.8" />
      <path d="M8 11l1-4h4l1 4" />
    </svg>
  ),
  crew: (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M16 19v-1a4 4 0 0 0-4-4H7a4 4 0 0 0-4 4v1" />
      <circle cx="9.5" cy="8" r="3.2" />
      <path d="M21 19v-1a4 4 0 0 0-3-3.85" />
      <path d="M15.5 5.15A3.2 3.2 0 0 1 15.5 11.3" />
    </svg>
  ),
  contacts: (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <rect x="5" y="3" width="14" height="18" rx="2.5" />
      <path d="M5 8h-1m1 4h-1m1 4h-1" />
      <circle cx="12" cy="10" r="2.4" />
      <path d="M8.5 16.5a3.5 3.5 0 0 1 7 0" />
    </svg>
  ),
};

const APPS = [
  { id: 'gofast', label: 'Go-Fast', gradient: 'linear-gradient(160deg, #fbbf24 0%, #f59e0b 45%, #ea580c 100%)', enabled: true },
  { id: 'crew', label: 'Organisation', gradient: 'linear-gradient(160deg, #f87171 0%, #ef4444 45%, #b91c1c 100%)', enabled: true },
  { id: 'contacts', label: 'Contacts', gradient: 'linear-gradient(160deg, #60a5fa 0%, #3b82f6 45%, #2563eb 100%)', enabled: false },
];

type Screen = 'home' | 'gofast' | 'crew' | 'market';

const IllegalDevice: React.FC<IllegalDeviceProps> = ({ visible, onClose }) => {
  const [hiding, setHiding] = useState(false);
  const [locked, setLocked] = useState(true);
  const [screen, setScreen] = useState<Screen>('home');
  const [config, setConfig] = useState<DeviceConfig>({ difficulties: [] });
  const [status, setStatus] = useState<DeviceStatus>({});
  const [now, setNow] = useState(Date.now());

  useEffect(() => {
    if (!visible) return;
    setScreen('home');
    setLocked(true);
    setHiding(false);
    const t = setInterval(() => setNow(Date.now()), 1000 * 30);
    return () => clearInterval(t);
  }, [visible]);

  useEffect(() => {
    const onMsg = (e: MessageEvent) => {
      const { action, data } = e.data || {};
      if (action === 'illegalDevice:setConfig') setConfig(data || { difficulties: [] });
      if (action === 'illegalDevice:gofast:status') setStatus(data || {});
    };
    window.addEventListener('message', onMsg);
    return () => window.removeEventListener('message', onMsg);
  }, []);

  const close = useCallback(() => {
    setHiding(true);
    setTimeout(() => {
      onClose();
      fetch(`https://${GetParentResourceName()}/illegalDevice:close`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: '{}',
      }).catch(() => { });
      setHiding(false);
    }, 250);
  }, [onClose]);

  useEffect(() => {
    if (!visible) return;
    const k = (e: KeyboardEvent) => { if (e.key === 'Escape') close(); };
    window.addEventListener('keydown', k);
    return () => window.removeEventListener('keydown', k);
  }, [visible, close]);

  const startMission = async (id: string) => {
    if (status.active) return;
    if (status.cooldown && status.cooldown > 0) return;
    await fetch(`https://${GetParentResourceName()}/illegalDevice:gofast:request`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ difficulty: id }),
    }).catch(() => { });
  };

  const { timeStr, dateStr } = useMemo(() => {
    const d = new Date(now);
    const t = `${d.getHours().toString().padStart(2, '0')}:${d.getMinutes().toString().padStart(2, '0')}`;
    const days = ['Dim', 'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam'];
    const months = ['jan', 'fév', 'mar', 'avr', 'mai', 'juin', 'juil', 'août', 'sep', 'oct', 'nov', 'déc'];
    const dt = `${days[d.getDay()]} ${d.getDate()} ${months[d.getMonth()]}`;
    return { timeStr: t, dateStr: dt };
  }, [now]);

  if (!visible && !hiding) return null;

  return (
    <div className={`idev-overlay${hiding ? ' idev-hiding' : ''}`}>
      <div className="idev-device">
        <div className="idev-side-btn idev-btn-power" />
        <div className="idev-side-btn idev-btn-vol-up" />
        <div className="idev-side-btn idev-btn-vol-down" />

        <div className="idev-screen">
          <div className="idev-camera" />
          <div className="idev-wallpaper" />

          <div className="idev-status">
            <span className="idev-status-left">
              <span className="idev-status-time">{timeStr}</span>
            </span>
            <span className="idev-status-right">
              <svg className="idev-status-wifi" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round">
                <path d="M5 12.55a11 11 0 0 1 14.08 0" />
                <path d="M1.88 4.94a18 18 0 0 1 20.24 0" />
                <path d="M8.53 16.11a6 6 0 0 1 6.95 0" />
                <line x1="12" y1="20" x2="12.01" y2="20" />
              </svg>
              <span className="idev-battery-pct">82%</span>
              <span className="idev-battery"><span className="idev-battery-fill" /></span>
            </span>
          </div>

          {locked && (
            <div className="idev-lockscreen" onClick={() => setLocked(false)}>
              <div className="idev-lock-glyph">
                <svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                  <rect x="3" y="11" width="18" height="11" rx="2" />
                  <path d="M7 11V7a5 5 0 0 1 10 0v4" />
                </svg>
              </div>
              <div className="idev-lock-clock">
                <div className="idev-lock-date">{dateStr}</div>
                <div className="idev-lock-time">{timeStr}</div>
              </div>
              <div className="idev-lock-hint">
                <span>Glissez vers le haut pour déverrouiller</span>
                <svg className="idev-lock-chevron" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
                  <polyline points="18 15 12 9 6 15" />
                </svg>
              </div>
            </div>
          )}

          <div className={`idev-content${locked ? ' idev-content-hidden' : ''}`}>
            {screen === 'home' && (
              <div className="idev-home">
                <div className="idev-app-grid">
                  {APPS.map(app => (
                    <button
                      key={app.id}
                      className={`idev-app${app.enabled ? '' : ' idev-app-disabled'}`}
                      onClick={() => app.enabled && setScreen(app.id as Screen)}
                      disabled={!app.enabled}
                    >
                      <div className="idev-app-icon" style={{ background: app.gradient }}>
                        <span className="idev-app-icon-glyph">{APP_ICONS[app.id]}</span>
                      </div>
                      <span className="idev-app-label">{app.label}</span>
                    </button>
                  ))}
                </div>
              </div>
            )}

            {screen === 'gofast' && (
              <GoFastApp
                config={config}
                status={status}
                onBack={() => setScreen('home')}
                onStart={startMission}
              />
            )}

            {screen === 'crew' && (
              <CrewApp onBack={() => setScreen('home')} onOpenMarket={() => setScreen('market')} />
            )}

            {screen === 'market' && (
              <MarketApp onBack={() => setScreen('crew')} />
            )}
          </div>

          <button
            className="idev-home-indicator"
            onClick={() => {
              if (locked) { setLocked(false); return; }
              if (screen !== 'home') { setScreen('home'); return; }
              close();
            }}
            aria-label={locked ? 'Déverrouiller' : (screen === 'home' ? 'Fermer la tablette' : 'Retour à l’accueil')}
            type="button"
          />
        </div>
      </div>
    </div>
  );
};

// ============================================================================
// GoFast App
// ============================================================================

interface GoFastAppProps {
  config: DeviceConfig;
  status: DeviceStatus;
  onBack: () => void;
  onStart: (id: string) => void;
}

const GF_IMAGES: Record<string, string> = {
  easy: 'gfdeb.webp',
  medium: 'gfmoy.webp',
  expert: 'gfexp.webp',
};

const GoFastApp: React.FC<GoFastAppProps> = ({ config, status, onBack, onStart }) => {
  const locked = !!status.active || (status.cooldown ?? 0) > 0;
  const cooldownLabel = useMemo(() => {
    if (!status.cooldown || status.cooldown <= 0) return null;
    const m = Math.ceil(status.cooldown / 60);
    return `${m} min`;
  }, [status.cooldown]);

  const formatDistance = (m: number) => {
    if (m >= 1000) return `${(m / 1000).toFixed(0)} km`;
    return `${m} m`;
  };

  return (
    <div className="idev-app-view">
      <div className="idev-app-bar">
        <button className="idev-back" onClick={onBack}>‹ Accueil</button>
        <div className="idev-app-title">
          <span>Go-Fast</span>
          <small>Sélectionne ta difficulté</small>
        </div>
        <div style={{ width: 64 }} />
      </div>

      {status.active && (
        <div className="idev-banner idev-banner-warn">
          Mission en cours. Termine ta livraison avant d'en démarrer une autre.
        </div>
      )}
      {!status.active && cooldownLabel && (
        <div className="idev-banner">Cooldown actif : {cooldownLabel}</div>
      )}

      <div className="idev-cards">
        {config.difficulties.map((d: DeviceDifficulty, idx: number) => {
          const variant = idx === 0 ? 'easy' : idx === 1 ? 'medium' : 'hard';
          const img = GF_IMAGES[d.id] ?? (idx === 0 ? 'gfdeb.webp' : idx === 1 ? 'gfmoy.webp' : 'gfexp.webp');
          return (
            <div
              key={d.id}
              className={`idev-gf-card idev-gf-${variant}`}
            >
              <div className="idev-gf-bg" style={{ backgroundImage: `url('nui://null-cache/images/illegaltablet/${img}')` }} />
              <div className="idev-gf-reward">
                ${d.payment[0].toLocaleString()} — ${d.payment[1].toLocaleString()}
              </div>
              <div className="idev-gf-body">
                <div className="idev-gf-dist">{formatDistance(d.distance)}</div>
                <div className="idev-gf-label">{d.label}</div>
                <p className="idev-gf-desc">{d.description}</p>
                <button
                  className="idev-gf-cta"
                  disabled={locked}
                  onClick={() => onStart(d.id)}
                >
                  {locked ? 'Indisponible' : 'Démarrer'}
                </button>
              </div>
            </div>
          );
        })}
        {config.difficulties.length === 0 && (
          <div className="idev-empty">Chargement des contrats…</div>
        )}
      </div>
    </div>
  );
};

export default IllegalDevice;
