import React, { useState, useEffect, useCallback } from 'react';
import { AlertTriangle, ShieldCheck, X, UserCog, Trash2, UserPlus, Check } from 'lucide-react';
import './ShowcaseLayer.css';

const GetParentResourceName = () => 'null-core';

const nuiCall = (event: string, data: Record<string, any> = {}) => {
  fetch(`https://${GetParentResourceName()}/${event}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data),
  }).catch(() => { });
};

interface ShowcaseData {
  version?: string;
  lastUpdate?: string;
  groups?: string[];
  currentGroup?: string;
  serverName?: string;
}

interface ShowcaseLayerProps {
  primaryColor: string;
  serverConfig: {
    serverName: string;
    serverIcon: string;
  };
}

const ShowcaseLayer: React.FC<ShowcaseLayerProps> = ({ primaryColor, serverConfig }) => {
  const accent = primaryColor || '#4A90E2';
  const [enabled, setEnabled] = useState(false);
  const [watermark, setWatermark] = useState<{ version: string; lastUpdate: string } | null>(null);
  const [welcome, setWelcome] = useState<ShowcaseData | null>(null);
  const [tablet, setTablet] = useState<ShowcaseData | null>(null);
  const [group, setGroup] = useState('');

  useEffect(() => {
    const handle = (e: MessageEvent) => {
      const { action, data } = e.data || {};
      switch (action) {
        case 'showcase:init':
          setEnabled(true);
          if (data) setWatermark({ version: data.version, lastUpdate: data.lastUpdate });
          break;
        case 'showcase:welcome:open':
          setEnabled(true);
          setWelcome(data || {});
          break;
        case 'showcase:tablet:open':
          setEnabled(true);
          setTablet(data || {});
          setGroup(data?.currentGroup || '');
          break;
      }
    };
    window.addEventListener('message', handle);
    return () => window.removeEventListener('message', handle);
  }, []);

  const closeWelcome = useCallback(() => {
    setWelcome(null);
    nuiCall('showcase:close');
  }, []);

  const closeTablet = useCallback(() => {
    setTablet(null);
    nuiCall('showcase:close');
  }, []);

  const accentVars = { '--sc-accent': accent } as React.CSSProperties;

  if (!enabled) return null;

  return (
    <div className="sc-root" style={accentVars}>
      {/* Watermark permanent */}
      {watermark && (
        <div className="sc-watermark">
          {/* <span className="sc-watermark-dot" /> */}
          BASE DE TEST · v{watermark.version}
        </div>
      )}

      {/* Écran de bienvenue */}
      {welcome && (
        <div className="sc-overlay">
          <div className="sc-vignette" aria-hidden />
          <div className="sc-card">
            <button className="sc-card-close" onClick={closeWelcome} title="Fermer"><X size={16} /></button>

            <div className="sc-card-head">
              {serverConfig.serverIcon && <img src={serverConfig.serverIcon} alt="" className="sc-logo" />}
              <div className="sc-card-titles">
                <span className="sc-eyebrow">Base de test · Showcase</span>
                <h1 className="sc-title">{welcome.serverName || serverConfig.serverName || 'Null'}</h1>
              </div>
            </div>

            <p className="sc-lead">
              Bienvenue sur la version <strong>vitrine</strong> de la base. Cet environnement sert
              uniquement à la démonstration — merci d'en prendre soin.
            </p>

            <div className="sc-notes">
              <div className="sc-note">
                <AlertTriangle size={16} />
                <span>Aucun <strong>mapping</strong>, ni <strong>pack de vêtements</strong>, ni <strong>pack de véhicules</strong> n'est inclus.</span>
              </div>
              <div className="sc-note">
                <ShieldCheck size={16} />
                <span>Vous disposez de <strong>permissions</strong> et d'un <strong>menu dédié</strong> — commande <code>/showcase</code>.</span>
              </div>
              <div className="sc-note">
                <AlertTriangle size={16} />
                <span>Restez <strong>respectueux</strong> : impossible d'agir (wipe, ban, kill…) sur les autres joueurs.</span>
              </div>
            </div>

            <div className="sc-meta">
              <span>Version <strong>v{welcome.version || '?'}</strong></span>
              <span className="sc-meta-sep">·</span>
              <span>Mise à jour le <strong>{welcome.lastUpdate || '?'}</strong></span>
            </div>

            <button className="sc-cta" onClick={closeWelcome}>
              <Check size={16} /> J'ai compris
            </button>
          </div>
        </div>
      )}

      {/* Tablette showcaser */}
      {tablet && (
        <div className="sc-overlay">
          <div className="sc-vignette" aria-hidden />
          <div className="sc-tablet">
            <div className="sc-tablet-head">
              <div className="sc-tablet-titles">
                <span className="sc-eyebrow">Menu showcaser</span>
                <h2>Outils de test</h2>
              </div>
              <button className="sc-card-close" onClick={closeTablet} title="Fermer"><X size={16} /></button>
            </div>

            <div className="sc-section">
              <label className="sc-label"><UserCog size={14} /> Mon groupe</label>
              <div className="sc-row">
                <select className="sc-select" value={group} onChange={(e) => setGroup(e.target.value)}>
                  {(tablet.groups || []).map((g) => <option key={g} value={g}>{g}</option>)}
                </select>
                <button
                  className="sc-btn sc-btn-accent"
                  onClick={() => { if (group) nuiCall('showcase:setGroup', { group }); }}
                >
                  Appliquer
                </button>
              </div>
            </div>

            <div className="sc-section">
              <label className="sc-label"><UserPlus size={14} /> Mon personnage</label>
              <div className="sc-row">
                <button className="sc-btn" onClick={() => nuiCall('showcase:register')}>
                  <UserPlus size={15} /> Se register
                </button>
                <button className="sc-btn sc-btn-danger" onClick={() => nuiCall('showcase:wipe')}>
                  <Trash2 size={15} /> Se wipe
                </button>
              </div>
            </div>

            <p className="sc-tablet-foot">Ces actions ne s'appliquent qu'à <strong>vous-même</strong>.</p>
          </div>
        </div>
      )}
    </div>
  );
};

export default ShowcaseLayer;
