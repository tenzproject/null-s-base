import React, { useMemo } from 'react';
import {
  Activity, Droplet, HeartPulse, Gauge, Wind, AlertTriangle, Sparkles, Utensils,
} from 'lucide-react';
import { MetabolismData } from '../types';

interface Props {
  data: MetabolismData | null;
}

const fmt = (n: number, digits = 1) => (isFinite(n) ? n.toFixed(digits) : '—');

const Bar: React.FC<{ label: string; value: number; icon: React.FC<any>; hint?: string }> = (
  { label, value, icon: Icon, hint }
) => {
  const pct = Math.max(0, Math.min(100, value));
  const tone = pct < 33 ? 'bad' : pct < 66 ? 'mid' : 'good';
  return (
    <div className="ni-meta-stat">
      <div className="ni-meta-stat-head">
        <div className="ni-meta-stat-label"><Icon size={14} /><span>{label}</span></div>
        <div className="ni-meta-stat-value">{Math.round(pct)}<span className="ni-meta-stat-unit">%</span></div>
      </div>
      <div className="ni-meta-stat-track">
        <div className={`ni-meta-stat-fill ni-meta-tone-${tone}`} style={{ width: `${pct}%` }} />
      </div>
      {hint && <div className="ni-meta-stat-hint">{hint}</div>}
    </div>
  );
};

const MetabolismTab: React.FC<Props> = ({ data }) => {
  const effects = useMemo(() => {
    if (!data?.effects) return null;
    const eff = data.effects;
    const t   = (data.score ?? 50) / 100;
    return {
      sprint:  eff.sprint.min  + t * (eff.sprint.max  - eff.sprint.min),
      stamina: eff.stamina.min + t * (eff.stamina.max - eff.stamina.min),
      regen:   eff.regen.min   + t * (eff.regen.max   - eff.regen.min),
    };
  }, [data]);

  if (!data) {
    return (
      <div className="ni-meta-empty">
        <Activity size={28} />
        <div className="ni-meta-empty-title">Forme indisponible</div>
        <div className="ni-meta-empty-sub">Les données n'ont pas encore été synchronisées.</div>
      </div>
    );
  }

  const score = data.score ?? 0;
  const scorePct = Math.max(0, Math.min(100, score));
  const scoreTone = scorePct < 33 ? 'bad' : scorePct < 66 ? 'mid' : 'good';
  const scoreLabel =
    scorePct < 25 ? 'En mauvaise forme' :
    scorePct < 50 ? 'Forme correcte' :
    scorePct < 75 ? 'En forme' : 'Excellente forme';

  return (
    <div className="ni-meta-root">
      {/* ---- Barre Forme principale ---- */}
      <div className="ni-meta-header">
        <div className="ni-meta-header-left">
          <div className="ni-meta-header-eyebrow">État général</div>
          <div className="ni-meta-header-tier">{scoreLabel}</div>
        </div>
        <div className="ni-meta-header-right">
          <div className="ni-meta-score">
            <div className="ni-meta-score-value">{Math.round(scorePct)}</div>
            <div className="ni-meta-score-unit">/100</div>
          </div>
          <div className="ni-meta-score-label">Forme</div>
        </div>
      </div>
      <div className="ni-meta-stat-track" style={{ marginBottom: '16px' }}>
        <div className={`ni-meta-stat-fill ni-meta-tone-${scoreTone}`} style={{ width: `${scorePct}%` }} />
      </div>

      {/* ---- Deux stats secondaires ---- */}
      <div className="ni-meta-section-title">Détail</div>
      <div className="ni-meta-grid">
        <Bar label="Hydratation" value={data.hydration} icon={Droplet}
             hint="Boire régulièrement améliore l'endurance." />
        <Bar label="Alimentation" value={data.fitness} icon={Utensils}
             hint="Repas en restaurant pour progresser plus vite." />
      </div>

      {/* ---- Effets ---- */}
      {effects && (
        <>
          <div className="ni-meta-section-title">Effets sur le personnage</div>
          <div className="ni-meta-effects">
            <div className="ni-meta-effect">
              <Gauge size={14} />
              <div className="ni-meta-effect-body">
                <div className="ni-meta-effect-label">Multiplicateur de course</div>
                <div className="ni-meta-effect-value">×{fmt(effects.sprint)}</div>
              </div>
            </div>
            <div className="ni-meta-effect">
              <Wind size={14} />
              <div className="ni-meta-effect-body">
                <div className="ni-meta-effect-label">Endurance maximale</div>
                <div className="ni-meta-effect-value">{fmt(effects.stamina, 0)}/100</div>
              </div>
            </div>
            <div className="ni-meta-effect">
              <HeartPulse size={14} />
              <div className="ni-meta-effect-body">
                <div className="ni-meta-effect-label">Régénération de PV</div>
                <div className="ni-meta-effect-value">+{fmt(effects.regen)}/s</div>
              </div>
            </div>
          </div>
        </>
      )}

      {/* ---- Conseils ---- */}
      <div className="ni-meta-section-title">Conseils</div>
      <div className="ni-meta-tips">
        {score < 40 && (
          <div className="ni-meta-tip ni-meta-tip-warn">
            <AlertTriangle size={14} />
            <div>Votre forme est faible. Mangez et buvez régulièrement.</div>
          </div>
        )}
        {data.hydration < 35 && (
          <div className="ni-meta-tip">
            <Droplet size={14} />
            <div>Hydratation faible — buvez de l'eau ou du jus.</div>
          </div>
        )}
        {data.fitness < 35 && (
          <div className="ni-meta-tip">
            <Utensils size={14} />
            <div>Alimentation insuffisante — un repas en restaurant vous aidera.</div>
          </div>
        )}
        {score >= 75 && (
          <div className="ni-meta-tip ni-meta-tip-good">
            <Sparkles size={14} />
            <div>Excellente forme — vos performances sont au top.</div>
          </div>
        )}
      </div>
    </div>
  );
};

export default MetabolismTab;
