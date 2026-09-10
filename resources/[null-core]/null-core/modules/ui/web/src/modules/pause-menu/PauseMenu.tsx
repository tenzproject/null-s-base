import React, { useState, useEffect, useCallback, useMemo } from 'react';
import { generateAccentVars } from '@/utils/accentColors';
import {
  Map,
  Settings,
  Gamepad2,
  LogOut,
  Layout,
  BookOpen,
  Skull,
  ShoppingBag,
  PersonStanding,
  Briefcase,
  Shield,
  Hash,
  Fingerprint,
  ChevronRight,
  Server,
} from 'lucide-react';
import './PauseMenu.css';

const GetParentResourceName = () => 'null-core';

interface PauseMenuData {
  firstName: string;
  lastName: string;
  uniqueId: string;
  serverId: string;
  job: string;
  jobGrade: string;
  illegalGroup: string;
  illegalGrade: string;
  hasIllegalGroup: boolean;
  cash: number;
  bank: number;
  dirtyCash: number;
  playerCount: number;
  maxPlayers: number;
  vip: { isVip: boolean; type?: string };
}

interface PauseMenuProps {
  visible: boolean;
  onClose: () => void;
  primaryColor: string;
  serverConfig: {
    serverName: string;
    serverColor: string;
    serverIcon: string;
  };
}

function formatMoney(amount: number): string {
  return amount.toLocaleString('fr-FR') + ' $';
}

const PauseMenu: React.FC<PauseMenuProps> = ({ visible, onClose, primaryColor, serverConfig }) => {
  const [show, setShow] = useState(false);
  const [data, setData] = useState<PauseMenuData | null>(null);
  const [pedOccluded, setPedOccluded] = useState(false);
  const accent = primaryColor || '#646464';
  const accentVars = useMemo(() => generateAccentVars('--pm-accent', accent), [accent]);

  const nuiCallback = useCallback((event: string, payload: any = {}) => {
    fetch(`https://${GetParentResourceName()}/${event}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
    }).catch(() => {});
  }, []);

  useEffect(() => {
    const handler = (event: MessageEvent) => {
      const { action, data: msgData } = event.data;
      if (action === 'pauseMenu:open') {
        setData(msgData);
        requestAnimationFrame(() => setShow(true));
      }
      if (action === 'pauseMenu:close') {
        setShow(false);
        setPedOccluded(false);
      }
      if (action === 'pauseMenu:pedVisibility') {
        setPedOccluded(!msgData?.visible);
      }
      if (action === 'pauseMenu:updateData') {
        setData(msgData);
      }
    };
    window.addEventListener('message', handler);
    return () => window.removeEventListener('message', handler);
  }, []);

  useEffect(() => {
    if (!visible) {
      setShow(false);
      setData(null);
      setPedOccluded(false);
    }
  }, [visible]);

  const handleClose = useCallback(() => {
    nuiCallback('pauseMenu:close');
    onClose();
  }, [nuiCallback, onClose]);

  const handleKeyDown = useCallback(
    (e: KeyboardEvent) => {
      if (!show) return;
      if (e.key === 'Escape') {
        e.preventDefault();
        handleClose();
      }
    },
    [show, handleClose]
  );

  useEffect(() => {
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [handleKeyDown]);

  const openModule = useCallback(
    (module: string) => {
      nuiCallback('pauseMenu:openModule', { module });
      onClose();
    },
    [nuiCallback, onClose]
  );

  const openMinimap = useCallback(() => {
    nuiCallback('pauseMenu:openMinimap');
    onClose();
  }, [nuiCallback, onClose]);

  const openGTASettings = useCallback(() => {
    nuiCallback('pauseMenu:openGTASettings');
    onClose();
  }, [nuiCallback, onClose]);

  const quitServer = useCallback(() => {
    nuiCallback('pauseMenu:quitServer');
    onClose();
  }, [nuiCallback, onClose]);

  if (!visible && !show) return null;

  const d = data || {
    firstName: '...',
    lastName: '...',
    uniqueId: '?',
    serverId: '?',
    job: 'Citoyen',
    jobGrade: '',
    illegalGroup: '',
    illegalGrade: '',
    hasIllegalGroup: false,
    cash: 0,
    bank: 0,
    dirtyCash: 0,
    playerCount: 0,
    maxPlayers: 64,
    vip: { isVip: false },
  };

  return (
    <div className={`pm-overlay ${show ? 'pm-visible' : ''}`} style={accentVars as React.CSSProperties}>
      {/* Left: Ped display area */}
      <div className="pm-left">
        <div className={`pm-ped-occluded-bg ${pedOccluded ? 'pm-ped-occluded-active' : ''}`} />
        <div className="pm-left-gradient pm-left-gradient-top" />
        <div className="pm-left-gradient pm-left-gradient-bottom" />
        <div className="pm-left-gradient pm-left-gradient-left" />
        <div className="pm-left-gradient pm-left-gradient-right" />

        <div className="pm-ped-info">
          <div className="pm-ped-name"> 
            {d.firstName} {d.lastName}
          </div>
          <div className="pm-ped-subtitle">
            ID <span>{d.serverId}</span> · <span>{d.uniqueId}</span>
          </div>
        </div>
      </div>

      {/* Right: Content */}
      <div className="pm-right">
        {/* Header */}
        <div className="pm-header">
          <div className="pm-header-left">
            {serverConfig.serverIcon ? (
              <img src={serverConfig.serverIcon} alt="" className="pm-server-logo" />
            ) : (
              <div className="pm-server-logo-placeholder">
                <Server size={16} style={{ opacity: 0.3 }} />
              </div>
            )}
            <span className="pm-server-name" style={{ color: accent }}>
              {serverConfig.serverName}
            </span>
          </div>
          <div className="pm-header-right">
            <div className="pm-player-count">
              <div className="pm-player-count-dot" style={{ background: accent }} />
              {d.playerCount} / {d.maxPlayers}
            </div>
            <div className="pm-close-hint">
              <kbd>ESC</kbd> Fermer
            </div>
          </div>
        </div>

        {/* Player info */}
        <div className="pm-section">
          <div className="pm-section-label">Informations</div>
          <div className="pm-info-grid">
            <div className="pm-info-item">
              <div className="pm-info-icon"><Briefcase size={15} /></div>
              <div className="pm-info-text">
                <span className="pm-info-label">Emploi</span>
                <span className="pm-info-value">{d.job}{d.jobGrade ? ` · ${d.jobGrade}` : ''}</span>
              </div>
            </div>
            <div className="pm-info-item">
              <div className="pm-info-icon"><Hash size={15} /></div>
              <div className="pm-info-text">
                <span className="pm-info-label">Identifiant</span>
                <span className="pm-info-value">ID {d.serverId}</span>
              </div>
            </div>
            {d.hasIllegalGroup && (
              <div className="pm-info-item">
                <div className="pm-info-icon"><Shield size={15} /></div>
                <div className="pm-info-text">
                  <span className="pm-info-label">Organisation</span>
                  <span className="pm-info-value">{d.illegalGroup}{d.illegalGrade ? ` · ${d.illegalGrade}` : ''}</span>
                </div>
              </div>
            )}
            <div className="pm-info-item">
              <div className="pm-info-icon"><Fingerprint size={15} /></div>
              <div className="pm-info-text">
                <span className="pm-info-label">ID Unique</span>
                <span className="pm-info-value">{d.uniqueId}</span>
              </div>
            </div>
          </div>
        </div>

        {/* Money */}
        <div className="pm-section">
          <div className="pm-section-label">Finances</div>
          <div className="pm-money-row">
            <div className="pm-money-pill">
              <div className="pm-money-dot" />
              <div>
                <div className="pm-money-label">Espèces</div>
                <div className="pm-money-value">{formatMoney(d.cash)}</div>
              </div>
            </div>
            <div className="pm-money-pill">
              <div className="pm-money-dot" style={{ opacity: 0.5 }} />
              <div>
                <div className="pm-money-label">Banque</div>
                <div className="pm-money-value">{formatMoney(d.bank)}</div>
              </div>
            </div>
            <div className="pm-money-pill">
              <div className="pm-money-dot" style={{ opacity: 0.3 }} />
              <div>
                <div className="pm-money-label">Sale</div>
                <div className="pm-money-value">{formatMoney(d.dirtyCash)}</div>
              </div>
            </div>
          </div>
        </div>

        {/* Actions */}
        <div className="pm-section">
          <div className="pm-section-label">Actions</div>
          <div className="pm-actions-list">
            <button className="pm-action-item" onClick={openMinimap}>
              <Map size={16} />
              <span className="pm-action-item-label">Ouvrir la carte</span>
              <ChevronRight size={14} className="pm-action-item-arrow" />
            </button>
            <button className="pm-action-item" onClick={() => openModule('settings')}>
              <Settings size={16} />
              <span className="pm-action-item-label">Réglages</span>
              <ChevronRight size={14} className="pm-action-item-arrow" />
            </button>
            <button className="pm-action-item" onClick={openGTASettings}>
              <Gamepad2 size={16} />
              <span className="pm-action-item-label">Paramètres GTA</span>
              <ChevronRight size={14} className="pm-action-item-arrow" />
            </button>
          </div>
        </div>

        {/* Modules */}
        <div className="pm-section">
          <div className="pm-section-label">Raccourcis</div>
          <div className="pm-modules-grid">
            <button className="pm-module-card" onClick={() => openModule('hudEditor')}>
              <Layout size={18} />
              HUD Editor
            </button>
            <button className="pm-module-card" onClick={() => openModule('rules')}>
              <BookOpen size={18} />
              Règlement
            </button>
            <button className="pm-module-card" onClick={() => openModule('boutique')}>
              <ShoppingBag size={18} />
              Boutique
            </button>
            <button className="pm-module-card" onClick={() => openModule('animations')}>
              <PersonStanding size={18} />
              Animations
            </button>
            {d.hasIllegalGroup && (
              <button className="pm-module-card" onClick={() => openModule('illegalTablet')}>
                <Skull size={18} />
                Tablette
              </button>
            )}
          </div>
        </div>

        {/* Footer */}
        <div className="pm-footer">
          <button className="pm-quit-btn" onClick={quitServer}>
            <LogOut size={15} />
            Quitter le serveur
          </button>
        </div>
      </div>
    </div>
  );
};

export default PauseMenu;
