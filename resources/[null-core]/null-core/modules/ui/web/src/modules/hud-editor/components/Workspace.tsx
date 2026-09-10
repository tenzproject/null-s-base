import React from 'react';
import { HUD_MODULES } from '../HUDModulesConfig';
import DraggableModule from './DraggableModule';
import { Position } from '../types';
import { HUDModuleState } from '../HUDModulesConfig';

interface WorkspaceProps {
  enabledModules: Set<string>;
  modulePositions: Map<string, Position>;
  moduleSizes: Map<string, { width: number; height: number }>;
  moduleStates: Map<string, HUDModuleState>;
  draggingModuleId: string | null;
  onDragStart: (moduleId: string, startPos: Position) => void;
  onDrag: (moduleId: string, newPos: Position) => void;
  onDragEnd: (moduleId: string) => void;
  onReset: (moduleId: string) => void;
  onConfigure: (moduleId: string) => void;
  onAnchorChange: (moduleId: string, newAnchor: string) => void;
  primaryColor: string;
  statusColors?: any;
  speedometerColors?: any;
  serverConfig?: {
    serverName: string;
    serverColor: string;
    serverLuaColor: string;
    serverIcon: string;
    serverDiscord: string;
  };
}

const Workspace: React.FC<WorkspaceProps> = ({
  enabledModules,
  modulePositions,
  moduleSizes,
  moduleStates,
  draggingModuleId,
  onDragStart,
  onDrag,
  onDragEnd,
  onReset,
  onConfigure,
  onAnchorChange,
  primaryColor,
  statusColors,
  speedometerColors,
  serverConfig,
}) => {
  return (
    <div className="fixed inset-0 z-[10000]">
      {/* Overlay */}
      <div className="absolute inset-0 bg-black/60" />

      {/* Grid Helper */}
      <div
        className="absolute inset-0"
        style={{
          backgroundImage: `
            linear-gradient(rgba(255, 255, 255, 0.03) 1px, transparent 1px),
            linear-gradient(90deg, rgba(255, 255, 255, 0.03) 1px, transparent 1px)
          `,
          backgroundSize: '50px 50px',
        }}
      />

      {/* Draggable Modules */}
      <div className="relative w-full h-full">
        {HUD_MODULES.filter((module) => {
          if (!enabledModules.has(module.id) || !module.isDraggable) return false;
          // Hide the draggable preview entirely when a speedometer/ammo module is
          // running in its "hologram" (3D) variant — the 3D UI is attached to the
          // vehicle/weapon in-world and has no meaningful 2D position.
          if (module.id === 'speedometer' || module.id === 'ammo') {
            const variant = moduleStates.get(module.id)?.colors?.variant || 'hologram';
            if (variant !== '2d') return false;
          }
          return true;
        }).map((module) => {
          const position = modulePositions.get(module.id) || module.defaultPosition;
          const size = moduleSizes.get(module.id) || module.defaultSize;
          const moduleState = moduleStates.get(module.id);
          const currentAnchor = moduleState?.anchor || module.anchor;
          const manualAnchor = moduleState?.manualAnchor || false;
          const moduleColors = moduleState?.colors;

          return (
            <DraggableModule
              key={module.id}
              module={{ ...module, anchor: currentAnchor, colors: moduleColors }}
              position={position}
              size={size}
              onDragStart={onDragStart}
              onDrag={onDrag}
              onDragEnd={onDragEnd}
              onReset={onReset}
              onConfigure={onConfigure}
              onAnchorChange={onAnchorChange}
              primaryColor={primaryColor}
              isDragging={draggingModuleId === module.id}
              serverConfig={serverConfig}
              statusColors={statusColors}
              speedometerColors={speedometerColors}
              manualAnchor={manualAnchor}
            />
          );
        })}
      </div>

      {/* Instructions */}
      {/* <div className="absolute bottom-8 left-1/2 -translate-x-1/2 bg-black/90 px-6 py-3 rounded-full border border-white/20">
        <p className="text-white/80 text-sm">
          <span className="font-semibold" style={{ color: primaryColor }}>
            Glissez-déposez
          </span>{' '}
          les modules pour les repositionner
        </p>
      </div> */}
    </div>
  );
};

export default Workspace;
