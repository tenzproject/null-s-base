import React, { useState, useEffect, useRef } from 'react';
import './ContextMenu.css';
import { ContextMenuProps, ContextMenuItem } from './types';
import { soundManager } from '@core/SoundManager';

const GetParentResourceName = () => {
  return 'null-core';
};

// Fonction pour parser les codes couleur FiveM
const parseColorCodes = (text: string): React.ReactNode => {
  if (!text) return text;
  
  const colorMap: { [key: string]: string } = {
    '~r~': '#ff4444',  // Rouge
    '~b~': '#4444ff',  // Bleu
    '~g~': '#44ff44',  // Vert
    '~y~': '#ffff44',  // Jaune
    '~p~': '#ff44ff',  // Rose/Violet
    '~o~': '#ff8844',  // Orange
    '~c~': '#888888',  // Gris
    '~m~': '#222222',  // Noir
    '~u~': '#000000',  // Noir complet
    '~w~': '#ffffff',  // Blanc
    '~s~': '#ffffff',  // Blanc (reset)
  };
  
  const parts: React.ReactNode[] = [];
  let currentText = '';
  let currentColor = '#ffffff';
  let i = 0;
  
  while (i < text.length) {
    if (text[i] === '~' && i + 2 < text.length && text[i + 2] === '~') {
      const code = text.substring(i, i + 3);
      if (colorMap[code]) {
        if (currentText) {
          parts.push(
            <span key={parts.length} style={{ color: currentColor }}>
              {currentText}
            </span>
          );
          currentText = '';
        }
        currentColor = colorMap[code];
        i += 3;
        continue;
      }
    }
    currentText += text[i];
    i++;
  }
  
  if (currentText) {
    parts.push(
      <span key={parts.length} style={{ color: currentColor }}>
        {currentText}
      </span>
    );
  }
  
  return parts.length > 0 ? <>{parts}</> : text;
};

const ContextMenu: React.FC<ContextMenuProps> = ({ visible, data, primaryColor = '#646464', onClose }) => {
  const [activeSubmenu, setActiveSubmenu] = useState<number | null>(null);
  const [submenuPosition, setSubmenuPosition] = useState<{ x: number; y: number } | null>(null);
  const menuRef = useRef<HTMLDivElement>(null);
  const submenuRef = useRef<HTMLDivElement>(null);
  const [hiding, setHiding] = useState(false);
  const closingRef = useRef(false);

  useEffect(() => {
    if (!visible) {
      setActiveSubmenu(null);
      setSubmenuPosition(null);
      setHiding(false);
      closingRef.current = false;
    }
  }, [visible]);

  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (closingRef.current) {
        return;
      }
      
      const target = event.target as Node;
      const isInsideMenu = menuRef.current && menuRef.current.contains(target);
      const isInsideSubmenu = submenuRef.current && submenuRef.current.contains(target);
      if (!isInsideMenu && !isInsideSubmenu) {
        handleClose();
      }
    };

    if (visible) {
      document.addEventListener('mousedown', handleClickOutside);
    }

    return () => {
      document.removeEventListener('mousedown', handleClickOutside);
    };
  }, [visible]);

  const handleClose = (keepNuiFocus?: boolean) => {
    if (closingRef.current) {
      return;
    }
    
    closingRef.current = true;
    setHiding(true);
    onClose(keepNuiFocus);
    setHiding(false);
  };

  const handleItemClick = (item: ContextMenuItem, index: number) => {
    if (item.disabled) {
      return;
    }

    if (item.type === 'submenu' && item.items) {
      if (activeSubmenu === index) {
        setActiveSubmenu(null);
        setSubmenuPosition(null);
      } else {
        const menuElement = menuRef.current;
        if (menuElement) {
          const itemElement = menuElement.querySelector(`[data-index="${index}"]`);
          if (itemElement) {
            const rect = itemElement.getBoundingClientRect();
            
            // Calculer la position du sous-menu pour éviter qu'il sorte de l'écran
            const submenuWidth = 240; // Largeur du sous-menu
            const submenuHeight = Math.min((item.items?.length || 0) * 40 + 16, 500);
            const viewportWidth = window.innerWidth;
            const viewportHeight = window.innerHeight;
            
            let x = rect.right + 8;
            let y = rect.top;
            
            // Si le sous-menu dépasse à droite, le placer à gauche du menu principal
            if (x + submenuWidth > viewportWidth - 20) {
              x = rect.left - submenuWidth - 8;
            }
            
            // Si le sous-menu dépasse en bas, l'ajuster
            if (y + submenuHeight > viewportHeight - 20) {
              y = Math.max(20, viewportHeight - submenuHeight - 20);
            }
            
            // S'assurer que le sous-menu ne sort pas en haut
            y = Math.max(20, y);
            
            // Si le sous-menu sort à gauche après ajustement, forcer à droite avec marge
            if (x < 20) {
              x = rect.right + 8;
              // Si toujours pas de place, placer au bord droit de l'écran
              if (x + submenuWidth > viewportWidth - 20) {
                x = viewportWidth - submenuWidth - 20;
              }
            }
            
            // S'assurer que le sous-menu ne sort pas en haut
            y = Math.max(10, y);
            
            setSubmenuPosition({
              x: x,
              y: y
            });
          }
        }
        setActiveSubmenu(index);
      }
    } else if (item.type === 'checkbox') {
      soundManager.play('toggle');
      fetch(`https://${GetParentResourceName()}/contextMenuAction`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          action: item.action,
          checked: !item.checked
        })
      }).then(() => {
        if (item.closeOnClick === true) {
          handleClose();
        }
      });
    } else if (item.type === 'button') {
      soundManager.play('click');
      fetch(`https://${GetParentResourceName()}/contextMenuAction`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          action: item.action
        })
      }).then(() => {
        if (item.closeOnClick === true) {
          handleClose(item.keepNuiFocus);
        }
      });
    }
  };

  const handleSubmenuItemClick = (item: ContextMenuItem) => {
    if (item.disabled) return;

    if (item.type === 'checkbox') {
      fetch(`https://${GetParentResourceName()}/contextMenuAction`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          action: item.action,
          checked: !item.checked
        })
      }).then(() => {
        if (item.closeOnClick === true) {
          handleClose();
        }
      });
    } else if (item.type === 'button') {
      fetch(`https://${GetParentResourceName()}/contextMenuAction`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          action: item.action
        })
      }).then(() => {
        if (item.closeOnClick === true) {
          handleClose(item.keepNuiFocus);
        }
      });
    }
  };

  const renderItem = (item: ContextMenuItem, index: number) => {
    if (item.type === 'separator') {
      return (
        <div key={index} className="context-menu-separator">
          {item.label && <span className="context-menu-separator-label">{item.label}</span>}
        </div>
      );
    }

    if (item.type === 'text') {
      return (
        <div key={index} className="context-menu-text-item">
          {item.label}
        </div>
      );
    }

    const isActive = activeSubmenu === index;

    return (
      <div
        key={index}
        data-index={index}
        className={`context-menu-item ${item.disabled ? 'disabled' : ''} ${isActive ? 'active' : ''}`}
        onClick={() => handleItemClick(item, index)}
        onMouseEnter={() => !item.disabled && soundManager.play('hover')}
        style={{
          '--primary-color': primaryColor
        } as React.CSSProperties}
      >
        {item.icon && <span className="context-menu-item-icon">{item.icon}</span>}
        <span className="context-menu-item-label">{parseColorCodes(item.label)}</span>
        
        {item.type === 'checkbox' && (
          <div className="context-menu-checkbox">
            <div className={`context-menu-checkbox-box ${item.checked ? 'checked' : ''}`}>
              {item.checked && (
                <svg width="12" height="12" viewBox="0 0 12 12" fill="none">
                  <path d="M2 6L5 9L10 3" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                </svg>
              )}
            </div>
          </div>
        )}
        
        {item.type === 'submenu' && (
          <span className="context-menu-arrow">›</span>
        )}
        
        {item.description && (
          <div className="context-menu-item-description">{parseColorCodes(item.description)}</div>
        )}
      </div>
    );
  };

  const renderSubmenu = () => {
    if (activeSubmenu === null || !data || !submenuPosition) return null;

    const parentItem = data.items[activeSubmenu];
    if (!parentItem || !parentItem.items) return null;

    return (
      <div
        ref={submenuRef}
        className="context-submenu"
        style={{
          left: `${submenuPosition.x}px`,
          top: `${submenuPosition.y}px`
        }}
      >
        {parentItem.items.map((item, index) => (
          <div
            key={index}
            className={`context-menu-item ${item.disabled ? 'disabled' : ''}`}
            onClick={() => handleSubmenuItemClick(item)}
            onMouseEnter={() => !item.disabled && soundManager.play('hover')}
            style={{
              '--primary-color': primaryColor
            } as React.CSSProperties}
          >
            {item.icon && <span className="context-menu-item-icon">{item.icon}</span>}
            <span className="context-menu-item-label">{parseColorCodes(item.label)}</span>
            
            {item.type === 'checkbox' && (
              <div className="context-menu-checkbox">
                <div className={`context-menu-checkbox-box ${item.checked ? 'checked' : ''}`}>
                  {item.checked && (
                    <svg width="12" height="12" viewBox="0 0 12 12" fill="none">
                      <path d="M2 6L5 9L10 3" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                    </svg>
                  )}
                </div>
              </div>
            )}
            
            {item.description && (
              <div className="context-menu-item-description">{parseColorCodes(item.description)}</div>
            )}
          </div>
        ))}
      </div>
    );
  };

  if (!visible || !data) return null;

  // Calculer la position du menu pour éviter qu'il sorte de l'écran
  const calculatePosition = () => {
    if (!data.position) return { left: '50%', top: '50%' };
    
    const menuWidth = 240; // Largeur réelle du menu
    const itemHeight = 40; // Hauteur d'un item
    const headerHeight = data.title ? 40 : 0;
    const menuHeight = Math.min(data.items.length * itemHeight + headerHeight + 16, 600);
    const viewportWidth = window.innerWidth;
    const viewportHeight = window.innerHeight;
    
    let left = data.position.x;
    let top = data.position.y;
    
    // Vérifier si le menu dépasse à droite
    if (left + menuWidth > viewportWidth - 20) {
      left = viewportWidth - menuWidth - 20;
    }
    
    // Vérifier si le menu dépasse en bas
    if (top + menuHeight > viewportHeight - 20) {
      top = viewportHeight - menuHeight - 20;
    }
    
    // S'assurer que le menu ne sort pas à gauche ou en haut
    left = Math.max(20, left);
    top = Math.max(20, top);
    
    return { left: `${left}px`, top: `${top}px` };
  };

  const menuPosition = calculatePosition();

  return (
    <>
      <div
        ref={menuRef}
        className={`context-menu-container ${visible ? 'visible' : ''} ${hiding ? 'hiding' : ''}`}
        style={{
          left: menuPosition.left,
          top: menuPosition.top,
          '--primary-color': primaryColor
        } as React.CSSProperties}
      >
        {data.title && (
          <div className="context-menu-header">
            {parseColorCodes(data.title)}
          </div>
        ) || (
          <div className="context-menu-header">
          </div>
        )}
        <div className="context-menu-items">
          {data.items.map((item, index) => renderItem(item, index))}
        </div>
      </div>
      {renderSubmenu()}
    </>
  );
};

export default ContextMenu;
