import React, { useEffect, useRef, useState } from 'react';
import { generateAccentVars } from '@/utils/accentColors';
import {
  MapPin, Navigation, User, Crown, Map as MapIcon, Zap, Heart, Smile, Frown, Meh,
  DollarSign, Clock, Route, ArrowRight, CheckCircle, Star,
} from 'lucide-react';
import { TaxiHUDData, TaxiHUDProps, TaxiSummaryData } from './types';
import './Taxi.css';

const ICONS: Record<string, React.ReactNode> = {
  user: <User size={14} />,
  crown: <Crown size={14} />,
  map: <MapIcon size={14} />,
  zap: <Zap size={14} />,
  heart: <Heart size={14} />,
};

const STEP_LABELS: Record<TaxiHUDData['step'], string> = {
  idle: 'En attente',
  toPickup: 'Aller chercher',
  atPickup: 'Récupération',
  inRide: 'Course en cours',
  atDestination: 'Arrivée',
};

function formatTime(sec: number) {
  const m = Math.floor(sec / 60);
  const s = Math.floor(sec % 60);
  return `${String(m).padStart(2, '0')}:${String(s).padStart(2, '0')}`;
}

function moodTone(p: number) {
  if (p >= 75) return { icon: <Smile size={14} />, label: 'Excellent', cls: 'taxi-mood-good' };
  if (p >= 45) return { icon: <Meh size={14} />, label: 'Correct', cls: 'taxi-mood-mid' };
  return { icon: <Frown size={14} />, label: 'Mauvais', cls: 'taxi-mood-bad' };
}

const TaxiHUD: React.FC<TaxiHUDProps> = ({ primaryColor }) => {
  const [data, setData] = useState<TaxiHUDData | null>(null);
  const [summary, setSummary] = useState<TaxiSummaryData | null>(null);
  const [hiding, setHiding] = useState(false);
  const summaryTimer = useRef<number | null>(null);

  useEffect(() => {
    const handler = (event: MessageEvent) => {
      const msg = event.data || {};
      switch (msg.action) {
        case 'taxiHUD:open':
          setHiding(false);
          break;
        case 'taxiHUD:update':
          if (msg.data) setData(msg.data);
          break;
        case 'taxiHUD:close':
          setHiding(true);
          window.setTimeout(() => { setData(null); setHiding(false); }, 320);
          break;
        case 'taxiHUD:summary':
          if (msg.data) {
            setSummary(msg.data);
            if (summaryTimer.current) window.clearTimeout(summaryTimer.current);
            summaryTimer.current = window.setTimeout(() => setSummary(null), 5500);
          }
          break;
      }
    };
    window.addEventListener('message', handler);
    return () => window.removeEventListener('message', handler);
  }, []);

  const accent = generateAccentVars('--taxi-accent', primaryColor || '#f5b400') as React.CSSProperties;

  if (!data && !summary) return null;

  const visible = data && data.visible !== false;
  const km = data ? (data.distanceMeters / 1000).toFixed(2) : '0.00';
  const mood = data ? moodTone(data.moodPercent) : null;

  return (
    <div className="taxi-hud-root" style={accent}>
      {visible && data && (
        <div className={`taxi-hud ${hiding ? 'taxi-hud-hiding' : ''}`}>
          <div className="taxi-hud-header">
            <div className="taxi-hud-pill">
              <span className="taxi-hud-pill-icon">
                {data.missionKey && ICONS[data.missionKey] ? ICONS[data.missionKey] : <Navigation size={14} />}
              </span>
              <span className="taxi-hud-pill-text">{data.missionLabel || 'Course'}</span>
            </div>
            <div className="taxi-hud-time">
              <Clock size={12} />
              <span>{formatTime(data.elapsedSec || 0)}</span>
            </div>
          </div>

          <div className="taxi-hud-step">
            <div className={`taxi-hud-step-dot taxi-step-${data.step}`} />
            <span className="taxi-hud-step-label">{STEP_LABELS[data.step] || data.step}</span>
            {data.stopCount > 0 && (
              <span className="taxi-hud-stop-counter">
                <MapPin size={11} />
                {Math.min(data.stopIndex, data.stopCount)} / {data.stopCount}
              </span>
            )}
          </div>

          {data.stopLabel && data.step !== 'idle' && (
            <div className="taxi-hud-target">
              <ArrowRight size={11} />
              <span>{data.stopLabel}</span>
            </div>
          )}

          <div className="taxi-hud-stats">
            <div className="taxi-hud-stat">
              <span className="taxi-hud-stat-icon"><Route size={12} /></span>
              <span className="taxi-hud-stat-label">Distance</span>
              <span className="taxi-hud-stat-value">{km} km</span>
            </div>
            <div className="taxi-hud-stat taxi-hud-stat-fare">
              <span className="taxi-hud-stat-icon"><DollarSign size={12} /></span>
              <span className="taxi-hud-stat-label">Course</span>
              <span className="taxi-hud-stat-value">${data.fareEstimate}</span>
            </div>
          </div>

          {mood && (
            <div className={`taxi-hud-mood ${mood.cls}`}>
              <div className="taxi-hud-mood-head">
                <span className="taxi-hud-mood-icon">{mood.icon}</span>
                <span className="taxi-hud-mood-label">Humeur client</span>
                <span className="taxi-hud-mood-value">{Math.round(data.moodPercent)}%</span>
              </div>
              <div className="taxi-hud-mood-bar">
                <div
                  className="taxi-hud-mood-fill"
                  style={{ width: `${Math.max(0, Math.min(100, data.moodPercent))}%` }}
                />
              </div>
            </div>
          )}
        </div>
      )}

      {summary && (
        <div className="taxi-summary">
          <div className="taxi-summary-head">
            <CheckCircle size={20} />
            <span>Course terminée</span>
          </div>
          <div className="taxi-summary-grid">
            <div className="taxi-summary-row">
              <span>Course</span>
              <span>${summary.fare}</span>
            </div>
            <div className="taxi-summary-row">
              <span>Pourboire</span>
              <span className="taxi-summary-tip">+${summary.tip}</span>
            </div>
            <div className="taxi-summary-row taxi-summary-total">
              <span>Total</span>
              <span>${summary.total}</span>
            </div>
            <div className="taxi-summary-row taxi-summary-xp">
              <span><Star size={12} /> XP</span>
              <span>+{summary.xpGain}</span>
            </div>
            {summary.dailyBonus > 0 && (
              <div className="taxi-summary-row taxi-summary-bonus">
                <span>Bonus journalier</span>
                <span>+${summary.dailyBonus}</span>
              </div>
            )}
          </div>
          {summary.rankUp && (
            <div className="taxi-summary-rankup">
              ⬆ Promotion : <strong>{summary.rank?.label}</strong>
            </div>
          )}
        </div>
      )}
    </div>
  );
};

export default TaxiHUD;
