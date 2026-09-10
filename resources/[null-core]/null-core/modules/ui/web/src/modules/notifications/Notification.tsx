import React, { useEffect, useState, useRef } from 'react';
import { NotificationData } from './types';

interface NotificationProps {
  data: NotificationData;
  primaryColor: string;
  serverColor?: string;
  serverLuaColor?: string;
  onRemove: (id: string) => void;
  onStack?: (id: string) => void;
  onRestartTimeout?: (id: string) => void;
  stackCount?: number;
  isBottom: boolean;
  /**
   * Mode "compact" déclenché quand une interface majeure (inventaire,
   * tablette, …) est ouverte : style + dimensions adaptés pour ne pas
   * gêner visuellement l'UI principale, tout en restant lisible.
   */
  compactMode?: boolean;
}

const Notification: React.FC<NotificationProps> = ({
  data,
  primaryColor,
  serverColor,
  serverLuaColor,
  onRemove,
  onStack,
  onRestartTimeout,
  stackCount = 1,
  isBottom,
  compactMode = false
}) => {
  const [isActive, setIsActive] = useState(false);
  const [isHiding, setIsHiding] = useState(false);
  const [isFlashing, setIsFlashing] = useState(false);
  const timeoutRef = useRef<number | null>(null);
  const prevStackCount = useRef(stackCount);

  const parseGTAColors = (text: string): JSX.Element[] => {
    // Convert serverLuaColor to hex if needed
    const convertLuaColor = (colorStr: string): string => {
      if (!colorStr) return colorStr;
      const match = colorStr.match(/rgb\((\d+),\s*(\d+),\s*(\d+)\)/);
      if (match) {
        const r = parseInt(match[1]).toString(16).padStart(2, '0');
        const g = parseInt(match[2]).toString(16).padStart(2, '0');
        const b = parseInt(match[3]).toString(16).padStart(2, '0');
        return `#${r}${g}${b}`;
      }
      return colorStr;
    };

    const serverLuaHex = serverLuaColor ? convertLuaColor(serverLuaColor).toLowerCase() : null;

    const colorMap: Record<string, string> = {
      '~r~': '#FF5454',
      '~g~': '#5fa05d',
      '~b~': '#5eb6e6',
      '~y~': '#c0a24b',
      '~p~': '#b19bd9',
      '~o~': '#fb8936',
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
      return [<span key="0">{String(text || '')}</span>];
    }
    const regex = /(~[a-z]~)/gi;
    const parts = text.split(regex);
    const elements: JSX.Element[] = [];
    let currentColor = 'inherit';
    let isBold = false;

    parts.forEach((part, index) => {
      const lowerPart = part.toLowerCase();
      if (colorMap[lowerPart]) {
        let color = colorMap[lowerPart];
        // Replace serverLuaColor with primaryColor
        if (serverLuaHex && color.toLowerCase() === serverLuaHex) {
          color = primaryColor;
        }
        currentColor = color;
      } else if (lowerPart === '~h~') {
        isBold = true;
      } else if (lowerPart === '~s~' || lowerPart === '~n~') {
        currentColor = 'inherit';
        isBold = false;
      } else if (part) {
        let displayColor = currentColor;
        // Replace serverLuaColor with primaryColor in final render
        if (serverLuaHex && currentColor.toLowerCase() === serverLuaHex) {
          displayColor = primaryColor;
        }
        elements.push(
          <span 
            key={index} 
            style={{ 
              color: displayColor,
              fontWeight: isBold ? 'bold' : 'normal'
            }}
            dangerouslySetInnerHTML={{ __html: part.replace(/\n/g, '<br />') }}
          />
        );
      }
    });

    return elements;
  };

  useEffect(() => {
    setIsActive(true);

    if (!data.pin_id && data.timeout) {
      timeoutRef.current = window.setTimeout(() => {
        handleHide();
      }, data.timeout);
    }

    return () => {
      if (timeoutRef.current) {
        clearTimeout(timeoutRef.current);
      }
    };
  }, [data.pin_id, data.timeout]);

  useEffect(() => {
    if (stackCount > prevStackCount.current && !data.pin_id && data.timeout) {
      // Clear existing timeout
      if (timeoutRef.current) {
        clearTimeout(timeoutRef.current);
      }
      // Restart timeout
      timeoutRef.current = window.setTimeout(() => {
        handleHide();
      }, data.timeout);
      
      // Flash animation to show timeout reset
      setIsFlashing(true);
      setTimeout(() => setIsFlashing(false), 300);
      
      if (onRestartTimeout) {
        onRestartTimeout(data.id);
      }
    }
    prevStackCount.current = stackCount;
  }, [stackCount, data.pin_id, data.timeout, data.id, onRestartTimeout]);

  const handleHide = () => {
    setIsHiding(true);
    setIsActive(false);
    
    setTimeout(() => {
      onRemove(data.id);
    }, 800);
  };

  const handleAccept = () => {
    fetch(`https://${(window as any).GetParentResourceName?.() || 'nui-frame-test'}/notificationResponse`, {
      method: 'POST',
      body: JSON.stringify({ 
        id: data.id,
        response: 'accept'
      })
    });
    handleHide();
  };

  const handleRefuse = () => {
    fetch(`https://${(window as any).GetParentResourceName?.() || 'nui-frame-test'}/notificationResponse`, {
      method: 'POST',
      body: JSON.stringify({ 
        id: data.id,
        response: 'refuse'
      })
    });
    handleHide();
  };

  const isColorLight = (color: string): boolean => {
    const hex = color.replace('#', '');
    const r = parseInt(hex.substr(0, 2), 16);
    const g = parseInt(hex.substr(2, 2), 16);
    const b = parseInt(hex.substr(4, 2), 16);
    const luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255;
    return luminance > 0.6;
  };

  // Replace server default color with current primaryColor
  if (data.couleurProgress && serverColor && data.couleurProgress.toLowerCase() === serverColor.toLowerCase()) {
    data.couleurProgress = primaryColor;
  }

  const progressColor = data.couleurProgress || primaryColor;
  const isLight = isColorLight(progressColor);



  
  // Styles dynamiques selon le mode (compact = interface ouverte)
  const compactStyle: React.CSSProperties = compactMode
    ? {
        width: '15vw', 
        padding: '9px 12px',
        fontSize: '10.5px',
        background:
          'var(--bg-primary)',
        border: '1px solid var(--bg-tertiary)',
        borderRadius: '10px',
        boxShadow: isFlashing
          ? `0 0 20px ${progressColor}`
          : '0 6px 20px rgba(0, 0, 0, 0.35)',
      }
    : {
        width: '16vw',
        padding: '13px 15px',
        fontSize: '11px',
        background: 'var(--bg-primary)',
        border: '1px solid var(--bg-tertiary)',
        borderRadius: '10px',
        boxShadow: isFlashing
          ? `0 0 20px ${progressColor}`
          : '0 8px 24px rgba(0, 0, 0, 0.4)',
      };

  return (
    <div
      className="transition-all duration-300 ease-out"
      style={{
        position: 'relative',
        fontFamily: 'Outfit, sans-serif',
        opacity: isActive ? '95%' : '0',
        transform: isActive ? 'translateX(0)' : 'translateX(8px)',
        color: 'var(--text-primary)',
        // Transition élargie pour l'animation lors du switch compact <-> normal
        transitionProperty: 'all',
        transitionDuration: '450ms',
        transitionTimingFunction: 'cubic-bezier(0.22, 1, 0.36, 1)',
        ...compactStyle,
      }}
    >
      {/* Pinned indicator */}
      {data.pin_id && (
        <div className="absolute top-1 right-1 w-3 h-3 bg-white rounded-full" />
      )}

      {/* Stack count */}
      {stackCount > 1 && (
        <div 
          className="absolute -top-2 -right-2 min-w-[20px] h-5 px-1.5 rounded flex items-center justify-center text-xs font-bold"
          style={{
            backgroundColor: progressColor,
            color: isLight ? '#111' : '#fff',
            boxShadow: `0 0 8px ${progressColor}99`
          }}
        >
          {stackCount}
        </div>
      )}

      {/* Standard notification */}
      {data.type === 'standard' && (
        <div style={{ fontFamily: 'Outfit, sans-serif', fontSize: '11px', textAlign: compactMode ? 'center' : 'left' }}>
          {parseGTAColors(data.message)}
        </div>
      )}

      {/* Advanced notification */}
      {data.type === 'advanced' && (
        compactMode ? (
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '10px' }}>
            {data.icon && (
              <div style={{
                width: '32px',
                height: '32px',
                borderRadius: '3px',
                overflow: 'hidden',
                flexShrink: 0,
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center'
              }}>
                <img
                  src={data.icon}
                  alt=""
                  style={{ width: '100%', height: '100%', objectFit: 'cover' }}
                />
              </div>
            )}
            <div style={{ fontFamily: 'Outfit, sans-serif', fontSize: '11px', textAlign: 'center', flex: 1, minWidth: 0 }}>
              {parseGTAColors(data.message)}
            </div>
          </div>
        ) : (
          <div>
            {data.icon && (
              <div style={{
                width: '38px',
                height: '38px',
                float: 'left',
                marginRight: '10px',
                borderRadius: '3px',
                overflow: 'hidden',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center'
              }}>
                <img
                  src={data.icon}
                  alt=""
                  style={{ width: '100%', height: '100%', objectFit: 'cover' }}
                />
              </div>
            )}
            <div style={{ overflow: 'hidden' }}>
              <div style={{ fontSize: '12px', textTransform: 'uppercase', marginTop: '-0.5%' }}>
                {data.title && (
                  <span style={{ fontFamily: 'Outfit, sans-serif' }}>
                    {parseGTAColors(data.title)}
                  </span>
                )}
                {data.subject && (
                  <span style={{ fontFamily: 'Outfit, sans-serif', marginLeft: '5px', opacity: 0.7 }}>
                    - {parseGTAColors(data.subject)}
                  </span>
                )}
              </div>
              <div style={{ fontFamily: 'Outfit, sans-serif', fontSize: '12px' }}>
                {parseGTAColors(data.message)}
              </div>
            </div>
          </div>
        )
      )}

      {/* Accept notification */}
      {data.type === 'accept' && (
        <div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '12px', marginBottom: '12px' }}>
            {data.icon && (
              <div style={{ 
                width: '40px', 
                height: '40px', 
                borderRadius: '4px', 
                overflow: 'hidden', 
                flexShrink: 0,
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                backgroundColor: 'var(--bg-secondary)'
              }}>
                <img 
                  src={data.icon} 
                  alt="" 
                  style={{ width: '100%', height: '100%', objectFit: 'cover' }}
                />
              </div>
            )}
            <div style={{ flex: 1, minWidth: 0 }}>
              {!compactMode && data.title && (
                <div style={{ 
                  fontSize: '12px', 
                  fontWeight: 600,
                  fontFamily: 'Outfit, sans-serif',
                  marginBottom: '4px',
                  color: 'var(--text-primary)'
                }}>
                  {parseGTAColors(data.title)}
                </div>
              )}
              <div style={{ 
                fontFamily: 'Outfit, sans-serif', 
                fontSize: '11px',
                color: 'rgba(255, 255, 255, 0.8)',
                lineHeight: '1.4',
                textAlign: compactMode ? 'center' : 'left'
              }}>
                {parseGTAColors(data.message)}
              </div>
            </div>
          </div>
          
          {/* Accept/Refuse buttons */}
          <div style={{ marginTop: '10px', display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: '8px' }}>
            <button
              onClick={handleAccept}
              style={{
                flex: 1,
                padding: '6px',
                fontFamily: 'Outfit, sans-serif',
                fontSize: '11px',
                textAlign: 'center',
                transition: 'all 0.2s ease',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                gap: '5px',
                backgroundColor: 'rgba(76, 175, 80, 0.1)',
                color: 'rgba(255, 255, 255, 1.0)',
                border: '1px solid rgba(0, 255, 0, 0.4)',
                cursor: 'pointer'
              }}
            >
              <span style={{ backgroundColor: 'rgba(0, 255, 0, 0.2)', padding: '2px 6px', borderRadius: '3px', fontSize: '10px', fontFamily: 'Outfit, sans-serif', fontWeight: 'bold' }}>E</span>
              Accepter
            </button>
            <button
              onClick={handleRefuse}
              style={{
                flex: 1,
                padding: '6px',
                fontFamily: 'Outfit, sans-serif',
                fontSize: '11px',
                textAlign: 'center',
                transition: 'all 0.2s ease',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                gap: '5px',
                backgroundColor: 'rgba(244, 67, 54, 0.1)',
                color: 'rgba(255, 255, 255, 1.0)',
                border: '1px solid rgba(255, 0, 0, 0.4)',
                cursor: 'pointer'
              }}
            >
              <span style={{ backgroundColor: 'rgba(255, 0, 0, 0.2)', padding: '2px 6px', borderRadius: '3px', fontSize: '10px', fontFamily: 'Outfit, sans-serif', fontWeight: 'bold' }}>Y</span>
              Refuser
            </button>
          </div>
        </div>
      )}

      {/* Progress bar — centrée à 90% de largeur sans transform (left/right symétriques) */}
      {data.progress && (
        <div
          style={{
            position: 'absolute',
            bottom: '-2px',
            left: '5%',
            right: '5%',
            height: '3px',
            backgroundColor: 'var(--bg-primary)',
            borderRadius: '15px',
            overflow: 'hidden',
          }}
        >
          <div
            className="animate-progress"
            style={{
              height: '100%',
              backgroundColor: progressColor,
              boxShadow: `0px 0px 7px ${progressColor}CC`,
              animationDuration: `${data.timeout}ms`,
              borderRadius: '15px',
            }}
          />
        </div>
      )}
    </div>
  );
};

export default Notification;
