import React, { useState, useEffect } from 'react';
import { generateAccentVars } from '@/utils/accentColors';
import { hudPositionManager } from '../../utils/hudPositionManager';
import { getAnchorTransform } from '../../utils/anchorPositioning';
import { HUD_MODULES } from '../hud-editor/HUDModulesConfig';
import './PlayerInfo.css';

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
  return amount.toLocaleString('en-US');
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
  const [visible, setVisible] = useState(previewMode);
  const [show, setShow] = useState(previewMode);
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

  const effectivePrimaryColor = globalConfig?.primaryColor || primaryColor || serverConfig.serverColor || '#646464';

  // Show/hide with animation delay
  useEffect(() => {
    if (visible || previewMode) {
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

  const animClass = (visible || previewMode) ? 'pinfo-showing' : 'pinfo-hiding';

  const fullName = `${playerData.firstName} ${playerData.lastName}`.trim() || '—';

  return (
    <div
      style={{
        ...positionStyle,
        zIndex: 100,
      }}
    >
      <div
        className={`pinfo-container ${animClass}`}
        style={{
          ['--server-color' as any]: effectivePrimaryColor,
          ...generateAccentVars('--pinfo-accent', effectivePrimaryColor),
        }}
      >
        <div className="pinfo-panel">
          {/* Header — server name + logo */}
          <div className="pinfo-header">
            {serverConfig?.serverIcon && (
              <img
                src={serverConfig.serverIcon}
                alt=""
                className="pinfo-logo"
                onError={(e) => { (e.target as HTMLImageElement).style.display = 'none'; }}
              />
            )}
            <span className="pinfo-server-name">{serverConfig?.serverName || 'Server'}</span>
          </div>

          {/* Identity & IDs */}
          <div className="pinfo-fixed-rows">
            <div className="pinfo-row">
              <span className="pinfo-row-label">IDENTITÉ</span>
              <span className="pinfo-row-value">{fullName}</span>
            </div>
            <div className="pinfo-row">
              <span className="pinfo-row-label"></span>
              <span className="pinfo-row-value">
                <span className="pinfo-row-label" style={{ fontSize: '9px', marginRight: '4px' }}>ID</span>
                <span>{playerData.tempId || '—'}</span>
                <span style={{ color: 'rgba(255,255,255,0.1)', margin: '0 6px' }}>|</span>
                <span className="pinfo-row-label" style={{ fontSize: '9px', marginRight: '4px' }}>UNIQUE</span>
                <span style={{ color: effectivePrimaryColor }}>{playerData.uniqueId || '—'}</span>
              </span>
            </div>
          </div>

          {/* Separator below IDs */}
          <div className="pinfo-separator" />

          {/* Job & Money info */}
          <div className="pinfo-fixed-rows">
            <div className="pinfo-row">
              <span className="pinfo-row-label">METIER</span>
              <span className="pinfo-row-value">{playerData.job}</span>
            </div>
            {playerData.illegalGroup && playerData.illegalGroup !== 'unemployed2' && (
              <div className="pinfo-row">
                <span className="pinfo-row-label">GROUPE</span>
                <span className="pinfo-row-value pinfo-red">
                  {playerData.illegalGroup}{playerData.illegalGrade ? ` - ${playerData.illegalGrade}` : ''}
                </span>
              </div>
            )}
            <div className="pinfo-row">
              <span className="pinfo-row-label">ARGENT</span>
              <span className="pinfo-row-value pinfo-green">${formatMoney(playerData.money)}</span>
            </div>
            {playerData.dirtyMoney > 0 && (
              <div className="pinfo-row">
                <span className="pinfo-row-label">ARGENT SALE</span>
                <span className="pinfo-row-value pinfo-red">${formatMoney(playerData.dirtyMoney)}</span>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};

export default PlayerInfo;
