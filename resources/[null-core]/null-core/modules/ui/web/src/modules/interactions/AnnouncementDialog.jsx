import React, { useState, useEffect } from 'react';
import { AlertCircle, Shield, Megaphone } from 'lucide-react';
import './styles/AnnouncementDialog.css';
import { hudPositionManager } from '../../utils/hudPositionManager';
import { applyAnchorPosition } from '../../utils/anchorPositioning';

function AnnouncementDialog({ serverConfig, primaryColor, previewMode = false, previewPosition = null, hudEditorOpen = false }) {
  
  const [visible, setVisible] = useState(previewMode);
  const [data, setData] = useState(previewMode ? {
    announcementType: 'global',
    message: 'Ceci est un exemple d\'annonce serveur',
    subtitle: 'Information importante',
    duration: 10
  } : null);
  const [progress, setProgress] = useState(100);
  const [actualPosition, setActualPosition] = useState(null);
  const [positionReady, setPositionReady] = useState(false);
  
  // Load saved position immediately on mount
  useEffect(() => {
    if (previewMode) {
      setPositionReady(true);
      return;
    }
    
    hudPositionManager.onReady(() => {
      const savedPos = hudPositionManager.getPosition('announcement');
      if (savedPos) {
        setActualPosition(savedPos);
      }
      setPositionReady(true);
    });
  }, [previewMode]);

  useEffect(() => {
    const handleMessage = (event) => {
      const msgData = event.data;
      
      switch (msgData.type || msgData.action) {
        case 'SHOW_ANNOUNCEMENT':
          setData(msgData);
          setVisible(true);
          setProgress(100);
          break;

        case 'HIDE_ANNOUNCEMENT':
          setVisible(false);
          setTimeout(() => {
            setData(null);
            setProgress(100);
          }, 300);
          break;
      }
    };

    window.addEventListener('message', handleMessage);
    return () => window.removeEventListener('message', handleMessage);
  }, []);

  useEffect(() => {
    if (previewMode) return;
    if (visible && data && data.duration) {
      const startTime = Date.now();
      const duration = data.duration * 1000;

      const interval = setInterval(() => {
        const elapsed = Date.now() - startTime;
        const remaining = Math.max(0, 100 - (elapsed / duration) * 100);
        setProgress(remaining);

        if (remaining <= 0) {
          clearInterval(interval);
          setVisible(false);
          setTimeout(() => {
            setData(null);
            setProgress(100);
          }, 300);
        }
      }, 50);

      return () => clearInterval(interval);
    }
  }, [visible, data, previewMode]);

  useEffect(() => {
    const actualColor = primaryColor || serverConfig?.serverColor || '#646464';
    document.documentElement.style.setProperty('--server-color', actualColor);
  }, [serverConfig, primaryColor]);

  if (!data || (!previewMode && !positionReady)) return null;

  const getAnnouncementConfig = () => {
    switch (data.announcementType) {
      case 'staff':
        return {
          icon: Shield,
          title: 'Annonce Staff',
          color: '#f59e0b',
        };
      case 'warning':
        return {
          icon: AlertCircle,
          title: 'Avertissement',
          color: '#ef4444',
        };
      default: // global
        return {
          icon: Megaphone,
          title: 'Annonce',
          color: primaryColor || serverConfig?.serverColor || '#646464',
        };
    }
  };

  const config = getAnnouncementConfig();
  const Icon = config.icon;

  return (
    <div 
      className={`announcement-dialog-container ${visible ? 'visible' : 'hiding'}`}
      style={{
        display: (hudEditorOpen && !previewMode) ? 'none' : undefined,
        '--announcement-color': config.color,
        ...(previewMode ? {
          position: 'relative',
          left: 0,
          top: 0,
          transform: 'none'
        } : actualPosition?.anchor ? applyAnchorPosition({
          anchor: actualPosition.anchor,
          position: { x: actualPosition.x, y: actualPosition.y }
        }) : {})
      }}
    >
      <div className="announcement-content">
        <div className="announcement-header">
          <img 
            src={serverConfig?.serverIcon} 
            alt="" 
            className="announcement-server-icon"
            style={{ display: serverConfig?.serverIcon ? 'block' : 'none' }}
            onError={(e) => e.target.style.display = 'none'} 
          />
          <div className="announcement-titles">
            <div 
              className="announcement-server-name"
              style={{ 
                textShadow: "0 0 20px var(--text-tertiary)"
              }}
            >
              {serverConfig?.serverName || 'Null'}
            </div>
            <div className="announcement-type-row">
               <Icon size={14} color={config.color} />
               <div className="announcement-type-title" style={{ color: config.color }}>
                 {config.title}
               </div>
            </div>
          </div>
        </div>

        <div className="announcement-body">
            {data.subtitle && (
              <div className="announcement-subtitle">{data.subtitle}</div>
            )}
            <div className="announcement-message">
              {data.message}
            </div>
        </div>
      </div>

      <div className="announcement-progress-container">
        <div 
          className="announcement-progress-bar"
          style={{ 
            width: `${progress}%`,
            backgroundColor: config.color,
            boxShadow: `0 0 12px ${config.color}60`
          }}
        />
      </div>
    </div>
  );
}

export default AnnouncementDialog;
