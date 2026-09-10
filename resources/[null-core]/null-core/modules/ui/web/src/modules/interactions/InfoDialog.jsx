import React, { useState, useEffect } from 'react';
import { Check, X } from 'lucide-react';
import './styles/InfoDialog.css';
import { hudPositionManager } from '../../utils/hudPositionManager';
import { applyAnchorPosition } from '../../utils/anchorPositioning';

function InfoDialog({ serverConfig, primaryColor, serverLuaColor, previewMode = false, previewPosition = null, isStaff = false, hudEditorOpen = false, globalConfig }) {
  
  const [visible, setVisible] = useState(previewMode);
  const [data, setData] = useState(previewMode ? (isStaff ? {
    title: 'Staff Info',
    items: [
      { left: 'Joueurs en ligne', right: '64/128' },
      { left: 'Reports ouverts', right: '3' },
      { left: 'Admins connectés', right: '5' },
      { left: 'Temps de jeu', right: '2h 34m' }
    ]
  } : {
    title: 'Informations',
    items: [
      { left: 'Argent liquide', right: '$12,500' },
      { left: 'Banque', right: '$45,230' },
      { left: 'Niveau', right: '42' },
      { left: 'Job', right: 'Police' }
    ]
  }) : null);
  const [position, setPosition] = useState(previewMode ? 'middle-right' : 'middle-right');
  const [actualPosition, setActualPosition] = useState(null);
  const [isCompact, setIsCompact] = useState(false);
  
  // Handle preview mode compact detection
  useEffect(() => {
    if (previewMode && previewPosition) {
      const isCompactMode = previewPosition.y < 2 || previewPosition.y > 98;
      setIsCompact(isCompactMode);
    }
  }, [previewMode, previewPosition]);

  // Parse GTA color codes like ~g~, ~b~, ~r~, etc.
  const parseGTAColors = (text, serverLuaColor, primaryColor) => {
    const colorMap = {
      '~r~': '#e74c3c',
      '~g~': '#2ecc71',
      '~b~': '#3498db',
      '~y~': '#f1c40f',
      '~p~': '#9b59b6',
      '~o~': '#e67e22',
      '~c~': '#95a5a6',
      '~m~': '#e91e63',
      '~u~': '#1a1a1a',
      '~l~': '#000000',
      '~w~': '#ffffff',
      '~s~': 'inherit',
      '~h~': 'inherit',
      '~n~': 'inherit',
    };

    if (!text || typeof text !== 'string') {
        return <span>{String(text || '')}</span>;
    }
    const regex = /(~[a-z]~)/gi;
    const parts = text.split(regex);
    const elements = [];
    let currentColor = 'inherit';

    parts.forEach((part, index) => {
      const lowerPart = part.toLowerCase();
      if (colorMap[lowerPart] !== undefined) {
        // If this color code matches serverLuaColor and we have a primaryColor, use primaryColor
        if (serverLuaColor && primaryColor && lowerPart === serverLuaColor.toLowerCase()) {
          currentColor = primaryColor;
        } else {
          currentColor = colorMap[lowerPart];
        }
      } else if (part) {
        elements.push(
          <span key={index} style={{ color: currentColor }}>
            {part}
          </span>
        );
      }
    });

    return elements;
  };

  // Convert Lua RGB color format to hex
  const convertLuaColor = (colorStr) => {
    if (!colorStr || typeof colorStr !== 'string') return null;
    
    // Match rgb(r,g,b) format
    const match = colorStr.match(/rgb\((\d+),\s*(\d+),\s*(\d+)\)/);
    if (match) {
      const r = parseInt(match[1]).toString(16).padStart(2, '0');
      const g = parseInt(match[2]).toString(16).padStart(2, '0');
      const b = parseInt(match[3]).toString(16).padStart(2, '0');
      const hexColor = `#${r}${g}${b}`;
      
      // If converted color matches serverColor, use primaryColor instead
      if (serverConfig?.serverColor && hexColor.toLowerCase() === serverConfig.serverColor.toLowerCase()) {
        return effectivePrimaryColor;
      }
      
      return hexColor;
    }
    
    // If colorStr matches serverColor directly, use primaryColor
    if (serverConfig?.serverColor && colorStr.toLowerCase() === serverConfig.serverColor.toLowerCase()) {
      return effectivePrimaryColor;
    }
    
    return colorStr;
  };

  useEffect(() => {
    if (previewMode) return;
    
    const handleMessage = (event) => {
      const msgData = event.data;

      switch (msgData.type || msgData.action) {
        case 'SHOW_INFO':
          // Load saved position based on category using HUD Position Manager
          const category = msgData.category || 'info_dialog';
          const expectedCategory = isStaff ? 'info_dialog_staff' : 'info_dialog';
          
          // Only show if message category matches this instance's category
          if (category !== expectedCategory) {
            return;
          }
          
          setData(msgData);
          setPosition(msgData.position || 'middle-right');
          setVisible(true);
          
          hudPositionManager.onReady(() => {
            const savedPos = hudPositionManager.getPosition(category);
            if (savedPos) {
              setActualPosition(savedPos);
              const isCompactMode = savedPos.y < 2 || savedPos.y > 98;
              setIsCompact(isCompactMode);
            }
          });
          break;

        case 'HIDE_INFO':
          // Only hide if message category matches this instance's category (or if category is "all")
          const hideCategory = msgData.category || 'info_dialog';
          const expectedHideCategory = isStaff ? 'info_dialog_staff' : 'info_dialog';
          
          if (hideCategory !== expectedHideCategory && hideCategory !== 'all') {
            return;
          }
          
          setVisible(false);
          setTimeout(() => setData(null), 300);
          break;

        case 'FORCE_CAN_INFO':
          if (!msgData.bool) {
            setVisible(false);
            setTimeout(() => setData(null), 300);
          }
          break;
      }
    };

    window.addEventListener('message', handleMessage);
    return () => window.removeEventListener('message', handleMessage);
  }, [previewMode]);

  useEffect(() => {
    // Set CSS variable for server color
    if (serverConfig?.serverColor) {
      document.documentElement.style.setProperty('--server-color', serverConfig.serverColor);
    }
  }, [serverConfig]);

  if (!data) return null;

  const effectivePrimaryColor = globalConfig?.primaryColor || primaryColor || serverConfig?.serverColor || '#646464';
  const isTopMiddle = position === 'top-middle' || isCompact;
  
  // Determine logo position based on anchor
  const isLogoRight = actualPosition?.anchor && (actualPosition.anchor.includes('right') || actualPosition.anchor.includes('Right'));

  const renderItemValue = (item, isCompact = false) => {
    // For top-middle compact mode, no progress bars
    if (isCompact) {
      // Boolean: checkmark or cross
      if (typeof item.right === 'boolean') {
        return (
          <div className="info-item-boolean">
            {item.right ? (
              <Check size={14} color="#10b981" strokeWidth={3} />
            ) : (
              <X size={14} color="#ef4444" strokeWidth={3} />
            )}
          </div>
        );
      }
      
      // Regular text
      const itemColor = convertLuaColor(item.color) || 'var(--text-primary)';
      const content = item.rightIcon 
        ? `${item.right} <i class="${item.rightIcon}"></i>` 
        : item.right;

      return (
        <span 
          className="info-item-right" 
          style={{ color: itemColor }}
          dangerouslySetInnerHTML={{ __html: content }}
        />
      );
    }

    // Progress bar: detect "X/Y" format (not for compact mode)
    if (typeof item.right === 'string' && /^\d+\/\d+$/.test(item.right)) {
      const parts = item.right.split('/');
      if (parts.length === 2) {
        const [current, max] = parts.map(Number);
        const percentage = (current / max) * 100;
        const itemColor = convertLuaColor(item.color) || effectivePrimaryColor;
        
        return (
          <div className="info-item-progress">
            <span className="progress-text">{item.right}</span>
            <div className="progress-bar">
              <div 
                className="progress-fill" 
                style={{ 
                  width: `${percentage}%`,
                  backgroundColor: itemColor
                }}
              />
            </div>
          </div>
        );
      }
    }

    // Boolean: checkmark or cross
    if (typeof item.right === 'boolean') {
      return (
        <div className="info-item-boolean">
          {item.right ? (
            <Check size={16} color="#10b981" strokeWidth={3} />
          ) : (
            <X size={16} color="#ef4444" strokeWidth={3} />
          )}
        </div>
      );
    }

    // Regular text with optional icon
    const itemColor = convertLuaColor(item.color) || 'var(--text-primary)';
    const content = item.rightIcon 
      ? `${item.right} <i class="${item.rightIcon}"></i>` 
      : item.right;

    return (
      <span 
        className="info-item-right" 
        style={{ color: itemColor }}
        dangerouslySetInnerHTML={{ __html: content }}
      />
    );
  };

  const borderColor = convertLuaColor(data.color) || effectivePrimaryColor;

  return (
    <div  
      className={`info-dialog-container ${visible ? 'visible' : 'hiding'} ${isCompact ? 'top-middle' : ''} ${actualPosition ? '' : position} bg-theme-primary`}
      style={{
        display: (hudEditorOpen && !previewMode) ? 'none' : undefined,
        borderBottomColor: 'transparent',
        boxShadow: isTopMiddle 
          ? `0 4px 24px rgba(0, 0, 0, 0.3), 0 0 0 1px ${borderColor}20` 
          : `0 8px 32px rgba(0, 0, 0, 0.4), 0 0 0 1px ${borderColor}20`,
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
      <div className="info-dialog-content" style={isTopMiddle && isLogoRight ? { flexDirection: 'row-reverse' } : {}}>
        {isTopMiddle ? (
          // Compact top bar layout
          <>
            {serverConfig?.serverIcon && (
              <img src={serverConfig.serverIcon} alt="" className="info-server-icon" />
            )}
            {data.items && data.items.length > 0 && (
              <div className="info-items-compact">
                {data.items.map((item, index) => {
                  // const leftContent = item.leftIcon 
                  //   ? `<i class="${item.leftIcon}"></i> ${item.left}` 
                  //   : item.left;
                  const leftContent = item.left;

                  return (
                    <div key={index} className="info-item-compact">
                      <span 
                        className="info-item-left"
                        dangerouslySetInnerHTML={{ __html: leftContent }}
                      />
                      <span className="info-separator">:</span>
                      {renderItemValue(item, true)}
                    </div>
                  );
                })}
              </div>
            )}
          </>
        ) : (
          // Standard layout for other positions
          <>
            {(data.icon || serverConfig?.serverIcon || data.name || data.title || serverConfig?.serverName || true) && (
              <div className="info-dialog-header">
                <img 
                  src={data.icon || serverConfig?.serverIcon} 
                  alt="" 
                  className="info-icon"
                  style={{ display: (data.icon || serverConfig?.serverIcon) ? 'block' : 'none' }}
                  onError={(e) => {
                    // Fallback to server icon if specific icon fails
                    if (serverConfig?.serverIcon && e.target.src !== serverConfig.serverIcon) {
                        e.target.src = serverConfig.serverIcon;
                        e.target.style.display = 'block';
                    } else {
                        e.target.style.display = 'none';
                    }
                  }} 
                />
                <div className="info-titles">
                  <div 
                    className="info-name" 
                    style={{ 
                      color: "white",
                      textShadow: "0 0 20px var(--text-tertiary)" 
                    }}
                  >
                    {data.name || serverConfig?.serverName || 'Null'}
                  </div>
                  {data.title && (
                    <div className="info-title">{data.title}</div>
                  )}
                </div>
              </div>
            )}

            {data.items && data.items.length > 0 && (
              <div className="info-items">
                {data.items.map((item, index) => {
                  const leftContent = item.leftIcon 
                    ? `<i class="${item.leftIcon}"></i> ${item.left}` 
                    : item.left;

                  return (
                    <div key={index} className="info-item">
                      <span 
                        className="info-item-left"
                        dangerouslySetInnerHTML={{ __html: leftContent }}
                      />
                      {renderItemValue(item, false)}
                    </div>
                  );
                })}
              </div>
            )}
          </>
        )}
      </div>
    </div>
  );
}

export default InfoDialog;
