import React, { useState, useEffect } from 'react';
import { Info, AlertTriangle, XCircle, CheckCircle } from 'lucide-react';
import './styles/ConfirmDialog.css';
import { soundManager } from '@core/SoundManager';
import { hudPositionManager } from '../../utils/hudPositionManager';
import { applyAnchorPosition } from '../../utils/anchorPositioning';

function ConfirmDialog({ visible, data, onClose, serverConfig, primaryColor, previewMode = false, previewPosition = null, hudEditorOpen = false }) {
  
  const [actualPosition, setActualPosition] = useState(null);
  
  // Load saved position
  useEffect(() => {
    if (previewMode) return;
    
    hudPositionManager.onReady(() => {
      const savedPos = hudPositionManager.getPosition('confirm_dialog');
      if (savedPos) {
        setActualPosition(savedPos);
      }
    });
  }, [previewMode]);
  const isVisible = previewMode || visible;
  const dialogData = previewMode ? {
    type: 'info',
    title: 'Confirmation',
    message: 'Êtes-vous sûr de vouloir effectuer cette action ?',
    yesLabel: 'Oui',
    noLabel: 'Non'
  } : data;
  useEffect(() => {
    if (!visible || previewMode) return;

    const handleKeyDown = (e) => {
      if (e.key === 'Escape') {
        handleNo();
      } else if (e.key === 'Enter') {
        e.preventDefault();
        handleYes();
      }
    };

    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [visible]);

  const handleYes = () => {
    soundManager.play('success');
    fetch(`https://${GetParentResourceName()}/confirmDialogYes`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({})
    });

    onClose();
  };

  const handleNo = () => {
    soundManager.play('back');
    fetch(`https://${GetParentResourceName()}/confirmDialogNo`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({})
    });

    onClose();
  };

  if (!isVisible || !dialogData) return null;

  const actualPrimaryColor = primaryColor || serverConfig?.serverColor || '#646464';
  
  const getIconAndColor = () => {
    switch (data.type) {
      case 'warning':
        return { icon: AlertTriangle, color: '#f59e0b' };
      case 'error':
        return { icon: XCircle, color: '#ef4444' };
      case 'success':
        return { icon: CheckCircle, color: '#10b981' };
      case 'info':
      default:
        return { icon: Info, color: actualPrimaryColor };
    }
  };

  const iconData = previewMode ? { icon: Info, color: actualPrimaryColor } : (() => {
    switch (dialogData.type) {
      case 'warning':
        return { icon: AlertTriangle, color: '#f59e0b' };
      case 'error':
        return { icon: XCircle, color: '#ef4444' };
      case 'success':
        return { icon: CheckCircle, color: '#10b981' };
      case 'info':
      default:
        return { icon: Info, color: actualPrimaryColor };
    }
  })();
  const { icon: Icon, color } = iconData;
  const buttonShadow = `0 4px 15px ${color}40`;

  return (
    <div className={`confirm-dialog-overlay ${isVisible ? 'visible' : 'hiding'}`} style={{
        display: (hudEditorOpen && !previewMode) ? 'none' : undefined,
        ...(previewMode ? {
          position: 'relative',
          left: 0,
          top: 0,
          transform: 'none'
        } : actualPosition?.anchor ? applyAnchorPosition({
          anchor: actualPosition.anchor,
          position: { x: actualPosition.x, y: actualPosition.y }
        }) : {})
      }}>
      <div 
        className="confirm-dialog-container"
        // style={{ borderBottom: `2px solid ${color}` }}
      >
        <div className="confirm-dialog-header">
            {serverConfig?.serverIcon && (
              <img src={serverConfig.serverIcon} alt="" style={{ width: 24, height: 24, borderRadius: 4, objectFit: 'contain' }} />
            )}
            <div style={{ display: 'flex', flexDirection: 'column' }}>
                {serverConfig?.serverName && (
                  <span style={{ fontSize: 9, opacity: 0.5, fontWeight: 600, letterSpacing: 1, textTransform: 'uppercase', color: 'white' }}>
                    {serverConfig.serverName}
                  </span>
                )}
            </div>
        </div>

        <div className="confirm-dialog-content-wrapper">
            {/* <div className="confirm-dialog-icon" style={{ backgroundColor: `${color}15`, color: color }}>
              <Icon size={28} strokeWidth={2} />
            </div> */}

            <div className="confirm-dialog-title">
              {dialogData.title || 'Confirmation'}
            </div>

            <div className="confirm-dialog-message">
              {dialogData.message || 'Êtes-vous sûr ?'}
            </div>
        </div>

        <div className="confirm-dialog-footer">
            <div className="confirm-dialog-buttons">
              <button 
                className="confirm-dialog-button no" 
                onClick={previewMode ? undefined : handleNo}
                onMouseEnter={() => !previewMode && soundManager.play('hover')}
                style={previewMode ? { pointerEvents: 'none' } : {}}
              >
                {dialogData.noLabel || 'Non'}
              </button>
              <button 
                className="confirm-dialog-button yes" 
                onClick={previewMode ? undefined : handleYes}
                onMouseEnter={() => !previewMode && soundManager.play('hover')}
                style={{ 
                  backgroundColor: color,
                  boxShadow: buttonShadow,
                  ...(previewMode ? { pointerEvents: 'none' } : {})
                }}
              >
                {dialogData.yesLabel || 'Oui'}
              </button>
            </div>

            {/* <div className="confirm-dialog-hint">
              <span className="hint-key">ESC</span> Annuler · <span className="hint-key">ENTER</span> Confirmer
            </div> */}
        </div>
      </div>
    </div>
  );
}

function GetParentResourceName() {
  return window.GetParentResourceName ? window.GetParentResourceName() : 'null-core';
}

export default ConfirmDialog;
