import React, { useState, useEffect } from 'react';
import { generateAccentVars } from '@/utils/accentColors';
import { hudPositionManager } from '../../utils/hudPositionManager';
import { getAnchorTransform } from '../../utils/anchorPositioning';
import { HUD_MODULES } from '../hud-editor/HUDModulesConfig';
import './PlayerInfoModern.css';

interface PlayerInfoProps {
  serverConfig: {
    serverName: string;
    serverColor: string;
    serverIcon: string;
    serverDiscord: string;
  };
  primaryColor: string;
  hudEditorOpen?: boolean;
  previewMode?: boolean;
  previewPosition?: { x: number; y: number };
  previewAnchor?: string;
  globalConfig?: {
    primaryColor: string;
    theme: 'dark' | 'light';
    style: 'modern' | 'compact';
  };
}

interface PlayerData {
  firstName: string;
  lastName: string;
  uniqueId: string;
  tempId: string;
  money: number;
  dirtyMoney: number;
  job: string;
  jobGrade: string;
  illegalGroup: string;
  illegalGrade: string;
}

const formatMoney = (amount: number): string => {
  return amount.toLocaleString('fr-FR');
};

const PlayerInfo: React.FC<PlayerInfoProps> = ({
  serverConfig,
  primaryColor,
  hudEditorOpen = false,
  previewMode = false,
  previewPosition,
  previewAnchor,
  globalConfig,
}) => {
  const [visible, setVisible] = useState(true); // Default to true for safety
  const [show, setShow] = useState(true);

  const [actualPosition, setActualPosition] = useState<{ x: number; y: number; anchor: string } | null>(null);
  const [playerData, setPlayerData] = useState<PlayerData>(
    previewMode
      ? {
        firstName: 'John',
        lastName: 'Doe',
        uniqueId: '1057',
        tempId: '42',
        money: 12500,
        dirtyMoney: 3200,
        job: 'Police',
        jobGrade: 'Capitaine',
        illegalGroup: 'Cartel',
        illegalGrade: 'Boss',
      }
      : {
        firstName: '',
        lastName: '',
        uniqueId: '',
        tempId: '',
        money: 0,
        dirtyMoney: 0,
        job: 'Citoyen',
        jobGrade: '',
        illegalGroup: '',
        illegalGrade: '',
      }
  );

  const effectivePrimaryColor = globalConfig?.primaryColor || primaryColor || serverConfig?.serverColor || '#646464';

  // Show/hide with animation delay
  useEffect(() => {
    if (previewMode) {
      setShow(true);
      setVisible(true);
      return;
    }

    if (visible) {
      setShow(true);
    } else {
      const t = setTimeout(() => setShow(false), 350);
      return () => clearTimeout(t);
    }
  }, [visible, previewMode]);

  // Load position from HUD position manager
  useEffect(() => {
    if (previewMode) return;

    const readPositionFromStorage = () => {
      try {
        const saved = localStorage.getItem('hudLayout');
        if (saved) {
          const layout = JSON.parse(saved);
          const mod = layout.find((m: any) => m.id === 'player_info');
          if (mod) {
            setActualPosition({
              x: mod.position.x,
              y: mod.position.y,
              anchor: mod.anchor || 'top-right',
            });
          }
        }
      } catch (e) { }
    };

    hudPositionManager.onReady(() => {
      const savedPos = hudPositionManager.getPosition('player_info');
      if (savedPos) {
        setActualPosition(savedPos);
      }
    });

    window.addEventListener('hudLayoutChanged', readPositionFromStorage);
    return () => window.removeEventListener('hudLayoutChanged', readPositionFromStorage);
  }, [previewMode]);

  // Listen for NUI messages
  useEffect(() => {
    if (previewMode) return;

    const handleMessage = (event: MessageEvent) => {
      const data = event.data;

      switch (data.action || data.type) {
        case 'playerInfo':
          setPlayerData({
            firstName: data.firstName || '',
            lastName: data.lastName || '',
            uniqueId: data.uniqueId || '',
            tempId: data.tempId || '',
            money: data.money || 0,
            dirtyMoney: data.dirtyMoney || 0,
            job: data.job || 'Citoyen',
            jobGrade: data.jobGrade || '',
            illegalGroup: data.illegalGroup || '',
            illegalGrade: data.illegalGrade || '',
          });
          setVisible(true);
          break;

        case 'show':
          setVisible(true);
          break;

        case 'pause':
          setVisible(false);
          break;
      }
    };

    window.addEventListener('message', handleMessage);
    return () => window.removeEventListener('message', handleMessage);
  }, [previewMode]);

  const [tickerIdx, setTickerIdx] = useState(0);
  const tickerLen = (() => {
    let n = 1; // cash always
    if (playerData.job) n += 1;
    if (playerData.dirtyMoney > 0) n += 1;
    if (playerData.illegalGroup && playerData.illegalGroup !== 'unemployed2') n += 1;
    return n;
  })();
  useEffect(() => {
    if (tickerLen <= 1) return;
    const t = setInterval(() => setTickerIdx(i => (i + 1) % tickerLen), 3500);
    return () => clearInterval(t);
  }, [tickerLen]);

  if (!show && !previewMode) return null;
  if (hudEditorOpen && !previewMode) return null;

  const defaultConfig = HUD_MODULES.find(m => m.id === 'player_info');
  const positionStyle = previewMode
    ? {
      position: 'relative' as const,
      left: 0,
      top: 0,
      transform: 'none',
    }
    : actualPosition
      ? {
        position: 'fixed' as const,
        left: `${actualPosition.x}%`,
        top: `${actualPosition.y}%`,
        transform: getAnchorTransform(actualPosition.anchor as any),
      }
      : defaultConfig
        ? {
          position: 'fixed' as const,
          left: `${defaultConfig.defaultPosition.x}%`,
          top: `${defaultConfig.defaultPosition.y}%`,
          transform: getAnchorTransform(defaultConfig.anchor as any),
        }
        : {
          position: 'fixed' as const,
          right: '20px',
          top: '20px',
        };

  const animClass = (visible || previewMode) ? 'pinfo-md-showing' : 'pinfo-md-hiding';
  const fullName = `${playerData.firstName} ${playerData.lastName}`.trim() || '—';

  const currentAnchor = previewAnchor || actualPosition?.anchor || defaultConfig?.anchor || 'top-right';
  const isLeftAnchored = currentAnchor.includes('left');

  // Build ticker items based on available data
  const tickerItems: { label: string; value: string; tone?: 'cash' | 'dirty' | 'gang' }[] = [];
  if (playerData.job) {
    tickerItems.push({
      label: 'Métier',
      value: playerData.jobGrade ? `${playerData.job} · ${playerData.jobGrade}` : playerData.job,
    });
  }
  tickerItems.push({ label: 'Cash', value: `$${formatMoney(playerData.money)}`, tone: 'cash' });
  if (playerData.dirtyMoney > 0) {
    tickerItems.push({ label: 'Sale', value: `$${formatMoney(playerData.dirtyMoney)}`, tone: 'dirty' });
  }
  if (playerData.illegalGroup && playerData.illegalGroup !== 'unemployed2') {
    tickerItems.push({
      label: 'Gang',
      value: playerData.illegalGrade ? `${playerData.illegalGroup} · ${playerData.illegalGrade}` : playerData.illegalGroup,
      tone: 'gang',
    });
  }

  const currentTicker = tickerItems[tickerIdx % Math.max(1, tickerItems.length)] || tickerItems[0];

  return (
    <div
      className="pinfo-outer"
      style={{
        ...positionStyle,
        zIndex: 100,
      }}
    >
      <div
        className={`pinfo-md-wrapper ${animClass} ${isLeftAnchored ? 'pinfo-md-left' : ''}`}
        style={{
          ['--server-color' as any]: effectivePrimaryColor,
          ...generateAccentVars('--pinfo-accent', effectivePrimaryColor),
        }}
      >
        <div className="pinfo-md-panel">
          <div className="pinfo-md-fixed-rows">
            <div className="pinfo-md-row">
              <span className="pinfo-md-row-label">Pseudo</span>
              <span className="pinfo-md-row-value pinfo-md-row-value-strong">{fullName}</span>
            </div>
            <div className="pinfo-md-row">
              <span className="pinfo-md-row-label">ID</span>
              <span className="pinfo-md-row-value pinfo-md-row-value-id">{playerData.tempId || '—'}</span>
            </div>
            <div className="pinfo-md-row">
              <span className="pinfo-md-row-label">Unique</span>
              <span className="pinfo-md-row-value pinfo-md-row-value-muted">{playerData.uniqueId || '—'}</span>
            </div>
          </div>

          {currentTicker && (
            <div className="pinfo-md-ticker-row">
              <div className="pinfo-md-ticker">
                <div key={`${tickerIdx}-${currentTicker.label}`} className="pinfo-md-ticker-item">
                  <span className="pinfo-md-ticker-label">{currentTicker.label}</span>
                  <span className={`pinfo-md-ticker-value pinfo-md-ticker-value-${currentTicker.tone || 'default'}`}>
                    {currentTicker.value}
                  </span>
                </div>
              </div>
            </div>
          )}
        </div>

        {serverConfig?.serverIcon && (
          <div className="pinfo-md-logo">
            <img
              src={serverConfig.serverIcon}
              alt=""
              className="pinfo-md-logo-img"
              onError={(e) => { (e.target as HTMLImageElement).style.display = 'none'; }}
            />
          </div>
        )}
      </div>
    </div>
  );
};

export default PlayerInfo;


