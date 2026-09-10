import React, { useState, useEffect } from 'react';
import { generateAccentVars } from '@/utils/accentColors';
import { hudPositionManager } from '../../utils/hudPositionManager';
import { getAnchorTransform } from '../../utils/anchorPositioning';
import { HUD_MODULES } from '../hud-editor/HUDModulesConfig';
import './PlayerInfoModernMinimal.css';

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
    style: 'modern' | 'compact' | 'minimal';
  };
}

interface PlayerData {
  firstName: string;
  lastName: string;
  age: number;
  job: string;
  jobGrade: string;
  illegalGroup: string;
  illegalGrade: string;
  money: number;
  dirtyMoney: number;
  uniqueId: string;
  tempId: string;
}

const PlayerInfoModernMinimal: React.FC<PlayerInfoProps> = ({
  serverConfig,
  primaryColor,
  hudEditorOpen = false,
  previewMode = false,
  previewPosition,
  previewAnchor,
  globalConfig,
}) => {
  const [visible, setVisible] = useState(true);
  const [show, setShow] = useState(true);
  const [actualPosition, setActualPosition] = useState<{ x: number; y: number; anchor: string } | null>(null);
  const [playerData, setPlayerData] = useState<PlayerData>(
    previewMode
      ? {
        firstName: 'John',
        lastName: 'Doe',
        age: 23,
        job: 'Burger Shot',
        jobGrade: 'Boss',
        illegalGroup: 'Bloods',
        illegalGrade: 'Boss',
        money: 1500,
        dirtyMoney: 500,
        uniqueId: '1057',
        tempId: '42',
      }
      : {
        firstName: '',
        lastName: '',
        age: 0,
        job: 'Citoyen',
        jobGrade: '',
        illegalGroup: '',
        illegalGrade: '',
        money: 0,
        dirtyMoney: 0,
        uniqueId: '...',
        tempId: '...',
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
          setPlayerData(prev => ({
            ...prev,
            firstName: data.firstName !== undefined ? data.firstName : prev.firstName,
            lastName: data.lastName !== undefined ? data.lastName : prev.lastName,
            age: data.age !== undefined ? data.age : prev.age,
            job: data.job || prev.job,
            jobGrade: data.jobGrade || prev.jobGrade,
            illegalGroup: data.illegalGroup !== undefined ? data.illegalGroup : prev.illegalGroup,
            illegalGrade: data.illegalGrade !== undefined ? data.illegalGrade : prev.illegalGrade,
            money: data.money !== undefined ? data.money : prev.money,
            dirtyMoney: data.dirtyMoney !== undefined ? data.dirtyMoney : prev.dirtyMoney,
            uniqueId: data.uniqueId || prev.uniqueId,
            tempId: data.tempId || prev.tempId,
          }));
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
  const anchor = previewMode ? previewAnchor || 'top-right' : actualPosition?.anchor || defaultConfig?.anchor || 'top-right';
  const isRightAnchored = typeof anchor === 'string' && anchor.includes('right');

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

  const animClass = (visible || previewMode) ? 'pinfo-min-showing' : 'pinfo-min-hiding';

  return (
    <div
      className="pinfo-min-outer"
      style={{
        ...positionStyle,
        zIndex: 100,
      }}
    >
      <div
        className={`pinfo-min-wrapper ${animClass} ${isRightAnchored ? 'pinfo-min-right' : ''}`}
        style={{
          ['--server-color' as any]: effectivePrimaryColor,
          ...generateAccentVars('--pinfo-accent', effectivePrimaryColor),
        }}
      >
        <div className="pinfo-min-content">
          <div className="pinfo-min-money">
            <div className="pinfo-min-money-row pinfo-min-money-clean">
              <span className="pinfo-min-money-value">{playerData.money.toLocaleString('fr-FR')}</span>
              <span className="pinfo-min-money-unit">$</span>
            </div>
            {playerData.dirtyMoney > 0 && (
              <div className="pinfo-min-money-row pinfo-min-money-dirty">
                <span className="pinfo-min-money-value">{playerData.dirtyMoney.toLocaleString('fr-FR')}</span>
                <span className="pinfo-min-money-unit">$</span>
              </div>
            )}
          </div>

          <div className="pinfo-min-divider" aria-hidden="true"></div>

          <div className="pinfo-min-identity">
            <div className="pinfo-min-name">
              {(playerData.firstName || playerData.lastName)
                ? `${playerData.firstName} ${playerData.lastName}`.trim()
                : 'Anonyme'}
              {playerData.age > 0 && <span className="pinfo-min-age"> ({playerData.age})</span>}
            </div>
            <div className="pinfo-min-job pinfo-min-job-legal">
              {playerData.jobGrade && <span className="pinfo-min-grade">{playerData.jobGrade} </span>}
              <span className="pinfo-min-job-label">{playerData.job}</span>
            </div>
            {playerData.illegalGroup && playerData.illegalGroup !== 'unemployed2' && (
              <div className="pinfo-min-job pinfo-min-job-illegal">
                {playerData.illegalGrade && <span className="pinfo-min-grade">{playerData.illegalGrade} </span>}
                <span className="pinfo-min-job-label">{playerData.illegalGroup}</span>
              </div>
            )}
          </div>

          {serverConfig?.serverIcon && (
            <div className="pinfo-min-logo">
              <img
                src={serverConfig.serverIcon}
                alt="Server Logo"
                className="pinfo-min-logo-img"
                onError={(e) => { (e.target as HTMLImageElement).style.display = 'none'; }}
              />
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default PlayerInfoModernMinimal;


