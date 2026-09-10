import React, { useRef, useEffect, useState } from 'react';
import { Move, RotateCcw, Settings } from 'lucide-react';
import { HUDModule } from '../HUDModulesConfig';
import { Position, Size } from '../types';
import AnnouncementDialog from '@modules/interactions/AnnouncementDialog';
import ConfirmDialog from '@modules/interactions/ConfirmDialog';
import InfoDialog from '@modules/interactions/InfoDialog';
import InputDialog from '@modules/interactions/InputDialog';
import Menu from '@modules/menu/Menu';
import StatusBars from '@modules/hud/StatusBars';
import StatusBar from '@modules/hud/StatusBar';
import Speedometer from '@modules/hud/Speedometer';
import AmmoHud from '@modules/hud/AmmoHud';
import HelpNotification from '@modules/hud/HelpNotification';
import Indicator from '@modules/hud/Indicator';
import InventoryNotifications from '@modules/hud/InventoryNotifications';
import ProgressBar from '@modules/hud/ProgressBar';
import Chat from '@modules/chat/Chat';
import PlayerInfo from '@modules/hud/PlayerInfo';
import PlayerInfoModern from '@modules/hud/PlayerInfoModern';
import PlayerInfoModernMinimal from '@modules/hud/PlayerInfoModernMinimal';
import { getAnchorTransform } from '../../../utils/anchorPositioning';

interface DraggableModuleProps {
  module: HUDModule;
  position: Position;
  size: Size;
  onDragStart: (moduleId: string, startPos: Position) => void;
  onDrag: (moduleId: string, newPos: Position) => void;
  onDragEnd: (moduleId: string) => void;
  onReset: (moduleId: string) => void;
  onConfigure: (moduleId: string) => void;
  onAnchorChange: (moduleId: string, newAnchor: string) => void;
  primaryColor: string;
  isDragging: boolean;
  statusColors?: any;
  speedometerColors?: any;
  manualAnchor?: boolean;
  serverConfig?: {
    serverName: string;
    serverColor: string;
    serverLuaColor: string;
    serverIcon: string;
    serverDiscord: string;
  };
}

const DraggableModule: React.FC<DraggableModuleProps> = ({
  module,
  position,
  size,
  onDragStart,
  onDrag,
  onDragEnd,
  onReset,
  onConfigure,
  onAnchorChange,
  primaryColor,
  isDragging,
  statusColors,
  speedometerColors,
  manualAnchor,
  serverConfig,
}) => {
  const moduleRef = useRef<HTMLDivElement>(null);
  const contentRef = useRef<HTMLDivElement>(null);
  const [dragOffset, setDragOffset] = useState<Position>({ x: 0, y: 0 });
  const [actualSize, setActualSize] = useState(size);

  const handleMouseDown = (e: React.MouseEvent) => {
    if (!moduleRef.current?.parentElement) return;

    const parentRect = moduleRef.current.parentElement.getBoundingClientRect();

    // Calculate offset from current position percentage (anchor point)
    // This ensures consistent drag behavior regardless of anchor type
    const anchorX = parentRect.left + (position.x / 100) * parentRect.width;
    const anchorY = parentRect.top + (position.y / 100) * parentRect.height;

    const offsetX = e.clientX - anchorX;
    const offsetY = e.clientY - anchorY;

    setDragOffset({ x: offsetX, y: offsetY });
    onDragStart(module.id, position);
  };

  useEffect(() => {
    if (!isDragging) return;

    const handleMouseMove = (e: MouseEvent) => {
      if (!moduleRef.current?.parentElement) return;

      const parentRect = moduleRef.current.parentElement.getBoundingClientRect();
      const elementRect = moduleRef.current.getBoundingClientRect();

      // Calculate element width/height as percentage of parent
      const elementWidthPercent = (elementRect.width / parentRect.width) * 100;
      const elementHeightPercent = (elementRect.height / parentRect.height) * 100;

      const newX = ((e.clientX - dragOffset.x - parentRect.left) / parentRect.width) * 100;
      const newY = ((e.clientY - dragOffset.y - parentRect.top) / parentRect.height) * 100;

      // Adjust constraints based on anchor point
      let minX = 0, maxX = 100, minY = 0, maxY = 100;

      switch (module.anchor) {
        case 'top-left':
          maxX = 100 - elementWidthPercent;
          maxY = 100 - elementHeightPercent;
          break;
        case 'top-center':
          minX = elementWidthPercent / 2;
          maxX = 100 - elementWidthPercent / 2;
          maxY = 100 - elementHeightPercent;
          break;
        case 'top-right':
          minX = elementWidthPercent;
          maxY = 100 - elementHeightPercent;
          break;
        case 'center-left':
          maxX = 100 - elementWidthPercent;
          minY = elementHeightPercent / 2;
          maxY = 100 - elementHeightPercent / 2;
          break;
        case 'center':
          minX = elementWidthPercent / 2;
          maxX = 100 - elementWidthPercent / 2;
          minY = elementHeightPercent / 2;
          maxY = 100 - elementHeightPercent / 2;
          break;
        case 'center-right':
          minX = elementWidthPercent;
          minY = elementHeightPercent / 2;
          maxY = 100 - elementHeightPercent / 2;
          break;
        case 'bottom-left':
          maxX = 100 - elementWidthPercent;
          minY = elementHeightPercent;
          break;
        case 'bottom-center':
          minX = elementWidthPercent / 2;
          maxX = 100 - elementWidthPercent / 2;
          minY = elementHeightPercent;
          break;
        case 'bottom-right':
          minX = elementWidthPercent;
          minY = elementHeightPercent;
          break;
      }

      const constrainedX = Math.max(minX, Math.min(maxX, newX));
      const constrainedY = Math.max(minY, Math.min(maxY, newY));

      onDrag(module.id, { x: constrainedX, y: constrainedY });
    };

    const handleMouseUp = (e: MouseEvent) => {
      // Intelligent anchor point adaptation based on drop position
      // Skip if anchor was manually set by user
      if (moduleRef.current?.parentElement && !manualAnchor && !module.disableAutoAnchor) {
        const parentRect = moduleRef.current.parentElement.getBoundingClientRect();
        const dropX = ((e.clientX - parentRect.left) / parentRect.width) * 100;
        const dropY = ((e.clientY - parentRect.top) / parentRect.height) * 100;

        // Define zones for intelligent anchor adaptation (with dead zones)
        const edgeThreshold = 20; // 20% from edge
        const centerThreshold = 20; // 20% around center

        let newAnchor = module.anchor;

        // Determine vertical anchor
        let verticalAnchor = '';
        if (dropY < edgeThreshold) {
          verticalAnchor = 'top';
        } else if (dropY > 100 - edgeThreshold) {
          verticalAnchor = 'bottom';
        }
        else if (Math.abs(dropY - 50) < centerThreshold) {
          verticalAnchor = 'center';
        }

        // Determine horizontal anchor
        let horizontalAnchor = '';
        if (dropX < edgeThreshold) {
          horizontalAnchor = 'left';
        } else if (dropX > 100 - edgeThreshold) {
          horizontalAnchor = 'right';
        } else if (Math.abs(dropX - 50) < centerThreshold) {
          horizontalAnchor = 'center';
        }

        // Construct new anchor if we detected a zone
        if (verticalAnchor || horizontalAnchor) {
          if (verticalAnchor === 'center' && horizontalAnchor) {
            newAnchor = `center-${horizontalAnchor}` as any;
          } else if (horizontalAnchor === 'center' && verticalAnchor) {
            newAnchor = `${verticalAnchor}-center` as any;
          } else if (verticalAnchor && horizontalAnchor) {
            newAnchor = `${verticalAnchor}-${horizontalAnchor}` as any;
          } else if (verticalAnchor === 'center' && horizontalAnchor === 'center') {
            newAnchor = 'center';
          }

          // Update anchor if it changed - adjust position to prevent visual jump
          if (newAnchor !== module.anchor) {
            // Calculate visual position before anchor change
            const elementRect = moduleRef.current.getBoundingClientRect();
            const elementWidthPercent = (elementRect.width / parentRect.width) * 100;
            const elementHeightPercent = (elementRect.height / parentRect.height) * 100;

            // Get current visual center position
            const visualCenterX = ((elementRect.left + elementRect.width / 2 - parentRect.left) / parentRect.width) * 100;
            const visualCenterY = ((elementRect.top + elementRect.height / 2 - parentRect.top) / parentRect.height) * 100;

            // Calculate new position that maintains visual center
            let newPosX = visualCenterX;
            let newPosY = visualCenterY;

            // Adjust based on new anchor
            if (newAnchor.includes('left')) {
              newPosX = visualCenterX - elementWidthPercent / 2;
            } else if (newAnchor.includes('right')) {
              newPosX = visualCenterX + elementWidthPercent / 2;
            }

            if (newAnchor.includes('top')) {
              newPosY = visualCenterY - elementHeightPercent / 2;
            } else if (newAnchor.includes('bottom')) {
              newPosY = visualCenterY + elementHeightPercent / 2;
            }

            // Update position first, then anchor
            onDrag(module.id, { x: newPosX, y: newPosY });
            onAnchorChange(module.id, newAnchor);
          }
        }
      }

      onDragEnd(module.id);
    };

    document.addEventListener('mousemove', handleMouseMove);
    document.addEventListener('mouseup', handleMouseUp);

    return () => {
      document.removeEventListener('mousemove', handleMouseMove);
      document.removeEventListener('mouseup', handleMouseUp);
    };
  }, [isDragging, dragOffset, module.id, onDrag, onDragEnd]);

  const categoryColors: Record<string, string> = {
    Info: '#3b82f6',
    Interaction: '#10b981',
    Menu: '#8b5cf6',
    Notification: '#f59e0b',
    Status: '#ef4444',
  };

  const categoryColor = categoryColors[module.category] || primaryColor;

  const defaultServerConfig = {
    serverName: 'Null',
    serverColor: primaryColor,
    serverLuaColor: '~b~',
    serverIcon: '',
    serverDiscord: ''
  };

  const actualServerConfig = serverConfig || defaultServerConfig;

  // Use actual position for preview - no centering
  const previewPosition = { x: position.x, y: position.y };

  // Compact placeholder card shown in the editor when a module is running in
  // its "3D hologram" variant (no 2D preview to render).
  const render3DPlaceholder = (title: string, subtitle: string, faIcon: string) => (
    <div
      className="flex items-center gap-[1vh] rounded-lg"
      style={{
        padding: '0.7vh 1.2vh',
        background: 'var(--bg-primary)',
        boxShadow: '0 2px 10px rgba(0, 0, 0, 0.35)',
        border: `1px dashed ${primaryColor}55`,
        fontFamily: 'Outfit, sans-serif',
        color: 'var(--text-primary)',
      }}
    >
      <div
        className="flex items-center justify-center"
        style={{
          width: '3.4vh',
          height: '3.4vh',
          borderRadius: 9,
          background: `${primaryColor}22`,
          border: `1px solid ${primaryColor}55`,
        }}
      >
        <i className={faIcon} style={{ fontSize: '1.6vh', color: primaryColor }} />
      </div>
      <div className="flex flex-col" style={{ lineHeight: 1.1 }}>
        <span style={{ fontSize: '1.35vh', fontWeight: 600 }}>{title}</span>
        <span style={{ fontSize: '1vh', color: 'var(--text-secondary)' }}>{subtitle}</span>
      </div>
    </div>
  );

  const renderModulePreview = () => {
    switch (module.id) {
      case 'announcement':
        return <AnnouncementDialog serverConfig={actualServerConfig} primaryColor={primaryColor} previewMode={true} previewPosition={previewPosition} />;
      case 'confirm_dialog':
        return <ConfirmDialog visible={false} data={null} onClose={() => { }} serverConfig={actualServerConfig} primaryColor={primaryColor} previewMode={true} previewPosition={previewPosition} />;
      case 'info_dialog':
        return <InfoDialog serverConfig={actualServerConfig} primaryColor={primaryColor} serverLuaColor={actualServerConfig.serverLuaColor} previewMode={true} previewPosition={previewPosition} isStaff={false} globalConfig={{ primaryColor, theme: 'dark', style: 'modern' }} />;
      case 'info_dialog_staff':
        return <InfoDialog serverConfig={actualServerConfig} primaryColor={primaryColor} serverLuaColor={actualServerConfig.serverLuaColor} previewMode={true} previewPosition={previewPosition} isStaff={true} globalConfig={{ primaryColor, theme: 'dark', style: 'modern' }} />;
      case 'input_dialog':
        return <InputDialog visible={false} data={null} onClose={() => { }} serverConfig={actualServerConfig} primaryColor={primaryColor} previewMode={true} previewPosition={previewPosition} />;
      case 'menu':
        return <Menu title="" subtitle="" items={[]} selectedIndex={0} position={{ x: 0, y: 0 }} maxVisibleItems={13} primaryColor={primaryColor} previewMode={true} previewPosition={previewPosition} />;
      case 'status_bars':
        return <StatusBars serverConfig={serverConfig} previewMode={true} previewPosition={previewPosition} statusColors={statusColors} />;
      case 'status_bar_mic':
        return <StatusBar barId="mic" value={100} icon="fa-solid fa-microphone-lines" color={statusColors?.mic || primaryColor} style={statusColors?.barStyle || 1} previewMode={true} previewPosition={previewPosition} />;
      case 'status_bar_health':
        return <StatusBar barId="health" value={100} icon="fa-solid fa-heart" color={statusColors?.health || primaryColor} style={statusColors?.barStyle || 1} previewMode={true} previewPosition={previewPosition} />;
      case 'status_bar_armor':
        return <StatusBar barId="armor" value={50} icon="fa-solid fa-shield" color={statusColors?.armor || primaryColor} style={statusColors?.barStyle || 1} previewMode={true} previewPosition={previewPosition} />;
      case 'status_bar_hunger':
        return <StatusBar barId="hunger" value={100} icon="fa-solid fa-burger" color={statusColors?.hunger || primaryColor} style={statusColors?.barStyle || 1} previewMode={true} previewPosition={previewPosition} />;
      case 'status_bar_thirst':
        return <StatusBar barId="thirst" value={100} icon="fa-solid fa-droplet" color={statusColors?.thirst || primaryColor} style={statusColors?.barStyle || 1} previewMode={true} previewPosition={previewPosition} />;
      case 'status_bar_stamina':
        return <StatusBar barId="stamina" value={100} icon="fa-solid fa-person-running" color={statusColors?.stamina || primaryColor} style={statusColors?.barStyle || 1} previewMode={true} previewPosition={previewPosition} />;
      case 'status_bar_oxygen':
        return <StatusBar barId="oxygen" value={100} icon="fa-solid fa-lungs" color={statusColors?.oxygen || primaryColor} style={statusColors?.barStyle || 1} previewMode={true} previewPosition={previewPosition} />;
      case 'speedometer': {
        const variant = (module as any).colors?.variant || 'hologram';
        if (variant === '2d') {
          return <Speedometer serverConfig={serverConfig} previewMode={true} previewPosition={previewPosition} speedometerColors={speedometerColors} globalConfig={{ primaryColor, theme: 'dark', style: 'modern' }} />;
        }
        return render3DPlaceholder('Compteur 3D', 'Attaché au véhicule', 'fa-solid fa-gauge-high');
      }
      case 'ammo': {
        const variant = (module as any).colors?.variant || 'hologram';
        if (variant === '2d') {
          return <AmmoHud previewMode={true} previewPosition={previewPosition} primaryColor={primaryColor} />;
        }
        return render3DPlaceholder('Munitions 3D', 'Touche E pour afficher', 'fa-solid fa-gun');
      }
      case 'progress_bar':
        return <ProgressBar serverConfig={serverConfig} previewMode={true} previewPosition={previewPosition} globalConfig={{ primaryColor, theme: 'dark', style: 'modern' }} />;
      case 'chat':
        return <Chat hudEditorOpen={false} primaryColor={primaryColor} previewMode={true} previewPosition={previewPosition} />;
      case 'notifications':
        return (
          <div
            className="bg-theme-primary rounded-sm"
            style={{
              width: '16vw',
              padding: '15px',
              fontSize: '11px',
              fontFamily: 'Outfit, sans-serif',
              color: 'var(--text-primary)',
              opacity: '95%'
            }}
          >
            <div style={{ fontFamily: 'Outfit, sans-serif', fontSize: '11px' }}>
              Exemple de notification
            </div>
            <div style={{ position: 'absolute', bottom: 0, left: 0, width: '100%', height: '3px', backgroundColor: 'var(--bg-primary)' }}>
              <div
                style={{
                  height: '100%',
                  width: '50%',
                  backgroundColor: primaryColor,
                  boxShadow: `0px 0px 7px ${primaryColor}CC`,
                  borderRadius: '15px'
                }}
              />
            </div>
          </div>
        );
      case 'player_info': {
        const variant = (module as any).colors?.variant || 'modern';
        if (variant === 'minimal') {
          return <PlayerInfoModernMinimal serverConfig={actualServerConfig} primaryColor={primaryColor} previewMode={true} previewPosition={previewPosition} previewAnchor={module.anchor} globalConfig={{ primaryColor, theme: 'dark', style: 'modern' }} />;
        }
        if (variant === 'modern') {
          return <PlayerInfoModern serverConfig={actualServerConfig} primaryColor={primaryColor} previewMode={true} previewPosition={previewPosition} previewAnchor={module.anchor} globalConfig={{ primaryColor, theme: 'dark', style: 'modern' }} />;
        }
        return <PlayerInfo serverConfig={actualServerConfig} primaryColor={primaryColor} previewMode={true} previewPosition={previewPosition} previewAnchor={module.anchor} globalConfig={{ primaryColor, theme: 'dark', style: 'modern' }} />;
      }
      case 'help_notification':
        return <HelpNotification previewMode={true} previewPosition={previewPosition} primaryColor={primaryColor} />;
      case 'indicator':
        return <Indicator previewMode={true} previewPosition={previewPosition} previewAnchor={module.anchor} primaryColor={primaryColor} />;
      case 'inventory_notifications':
        return <InventoryNotifications previewMode={true} />;
      case 'minimap':
        // Get map type from module colors config (default to square)
        const mapType = (module as any).colors?.mapType || 'square';
        const isCircle = mapType === 'circle';

        // GTA minimap realistic dimensions (from real game values)
        // Square: 310px width x 200px height
        // Circle: 292px width x 237px height (actual measurements on 1920x1080)
        return (
          <div
            className="bg-theme-primary border-2 border-theme-strong flex items-center justify-center relative overflow-hidden"
            style={{
              width: isCircle ? '292px' : '310px',
              height: isCircle ? '237px' : '200px',
              borderRadius: isCircle ? '50%' : '0px',
            }}
          >
            {/* Grid pattern to simulate map */}
            <div
              className="absolute inset-0 opacity-20"
              style={{
                backgroundImage: `
                  linear-gradient(rgba(100, 200, 255, 0.3) 1px, transparent 1px),
                  linear-gradient(90deg, rgba(100, 200, 255, 0.3) 1px, transparent 1px)
                `,
                backgroundSize: '20px 20px',
              }}
            />
            {/* Center indicator */}
            <div className="absolute inset-0 flex items-center justify-center">
              <div
                className="bg-blue-500/60 border-2 border-white/80"
                style={{
                  width: '12px',
                  height: '12px',
                  borderRadius: '50%',
                  boxShadow: '0 0 10px rgba(59, 130, 246, 0.8)'
                }}
              />
            </div>
            {/* Map type label */}
            <div className="absolute bottom-1 right-2 text-theme-tertiary text-[10px] font-semibold">
              {isCircle ? 'RONDE' : 'CARRÉE'}
            </div>
          </div>
        );
      default:
        return null;
    }
  };

  return (
    <div
      ref={moduleRef}
      className="absolute pointer-events-auto"
      style={{
        left: `${position.x}%`,
        top: `${position.y}%`,
        transform: getAnchorTransform(module.anchor),
        opacity: isDragging ? 0.9 : 1,
        zIndex: isDragging ? 10002 : 10001,
      }}
      onMouseDown={handleMouseDown}
    >
      {/* Content wrapper with border */}
      <div
        className="relative rounded-lg pointer-events-none"
        style={{
          border: isDragging ? `3px dashed ${primaryColor}` : '3px dashed var(--text-tertiary)',
        }}
      >
        {/* Actual UI component */}
        <div ref={contentRef}>
          {renderModulePreview()}
        </div>
      </div>


      {/* Anchor point visualization */}
      <div
        className="absolute pointer-events-none"
        style={{
          width: '15px',
          height: '15px',
          borderRadius: '50%',
          background: primaryColor,
          border: '2px solid white/10',
          boxShadow: '0 2px 8px rgba(0,0,0,0.3)',
          left: module.anchor.includes('left') ? '0' : module.anchor.includes('right') ? '100%' : '50%',
          top: module.anchor.includes('top') ? '0' : module.anchor.includes('bottom') ? '100%' : '50%',
          transform: 'translate(-50%, -50%)',
          zIndex: 10004,
        }}
      />

      {/* Action icons - dynamically positioned based on Y position */}
      <div
        className={`absolute right-0 flex gap-1 p-1 pointer-events-auto ${position.y < 10 ? '-bottom-9' : '-top-9'}`}
        style={{ zIndex: 10004 }}
        onClick={(e) => e.stopPropagation()}
      >
        <button
          onClick={(e) => {
            e.stopPropagation();
            onReset(module.id);
          }}
          className="p-1 transition-colors border-[3px] border-dashed rounded-full"
          style={{
            borderColor: isDragging ? primaryColor : 'rgba(177,177,177,0.3)'
          }}
          onMouseEnter={(e) => {
            if (!isDragging) e.currentTarget.style.borderColor = primaryColor;
          }}
          onMouseLeave={(e) => {
            if (!isDragging) e.currentTarget.style.borderColor = 'rgba(177,177,177,0.3)';
          }}
          title="Réinitialiser"
        >
          <RotateCcw
            size={14}
            className="text-gray-300 transition-colors"
            style={{ color: isDragging ? primaryColor : undefined }}
            onMouseEnter={(e) => {
              if (!isDragging) (e.currentTarget as SVGElement).style.color = primaryColor;
            }}
            onMouseLeave={(e) => {
              if (!isDragging) (e.currentTarget as SVGElement).style.color = '';
            }}
          />
        </button>
        <button
          onClick={(e) => {
            e.stopPropagation();
            onConfigure(module.id);
          }}
          className="p-1 transition-colors border-[3px] border-dashed rounded-full"
          style={{
            borderColor: isDragging ? primaryColor : 'rgba(177,177,177,0.3)'
          }}
          onMouseEnter={(e) => {
            if (!isDragging) e.currentTarget.style.borderColor = primaryColor;
          }}
          onMouseLeave={(e) => {
            if (!isDragging) e.currentTarget.style.borderColor = 'rgba(177,177,177,0.3)';
          }}
          title="Configurer"
        >
          <Settings
            size={14}
            className="text-gray-300 transition-colors"
            style={{ color: isDragging ? primaryColor : undefined }}
            onMouseEnter={(e) => {
              if (!isDragging) (e.currentTarget as SVGElement).style.color = primaryColor;
            }}
            onMouseLeave={(e) => {
              if (!isDragging) (e.currentTarget as SVGElement).style.color = '';
            }}
          />
        </button>
      </div>
    </div>
  );
};

export default DraggableModule;
