import React from 'react';
import { RotateCcw, Settings, ChevronRight } from 'lucide-react';
import { HUDModule } from '../HUDModulesConfig';

interface ModuleCardProps {
  module: HUDModule;
  isEnabled: boolean;
  onToggle: (moduleId: string, enabled: boolean) => void;
  onReset: (moduleId: string) => void;
  onConfigure: (moduleId: string) => void;
  primaryColor: string;
}

const ModuleCard: React.FC<ModuleCardProps> = ({
  module,
  isEnabled,
  onToggle,
  onReset,
  onConfigure,
  primaryColor,
}) => {
  const handleCardClick = () => {
    onConfigure(module.id);
  };

  return (
    <div
      onClick={handleCardClick}
      className="rounded-xl overflow-hidden transition-all cursor-pointer group flex flex-col"
      style={{
        backgroundColor: 'var(--bg-secondary)',
        border: '1px solid transparent',
      }}
      onMouseEnter={(e) => {
        e.currentTarget.style.borderColor = 'var(--bg-tertiary)';
      }}
      onMouseLeave={(e) => {
        e.currentTarget.style.borderColor = 'transparent';
      }}
    >
      <div className="flex flex-col p-3.5 gap-3 flex-1" 
      style={{justifyContent: 'space-between'}}>
        {/* Header */}
        <div className="flex items-start justify-between gap-2">
          <div className="min-w-0 flex-1">
            <div className="flex items-center gap-2 mb-1">
              <h3
                className="font-semibold text-sm truncate"
                style={{ color: 'var(--text-primary)' }}
              >
                {module.name}
              </h3>
              {isEnabled && (
                <span
                  className="w-1.5 h-1.5 rounded-full shrink-0"
                  style={{ backgroundColor: primaryColor }}
                />
              )}
            </div>
            <p
              className="text-[11px] line-clamp-2 leading-snug"
              style={{ color: 'var(--text-secondary)' }}
            >
              {module.description}
            </p>
          </div>

          <ChevronRight
            size={16}
            className="shrink-0 mt-0.5 transition-transform group-hover:translate-x-0.5"
            style={{ color: 'var(--text-tertiary)' }}
          />
        </div>

        {/* Footer actions */}
        <div
          className="flex items-center justify-between gap-2 pt-2"
          style={{ borderTop: '1px solid var(--bg-tertiary)', flexDirection:'row-reverse' }}
        >
          <div className="flex items-center gap-1">
            {module.isDraggable && (
              <button
                onClick={(e) => {
                  e.stopPropagation();
                  onReset(module.id);
                }}
                className="p-1.5 rounded-lg transition-colors"
                style={{ color: 'var(--text-tertiary)' }}
                title="Réinitialiser la position"
                onMouseEnter={(e) => {
                  e.currentTarget.style.backgroundColor = 'var(--bg-tertiary)';
                  e.currentTarget.style.color = 'var(--text-primary)';
                }}
                onMouseLeave={(e) => {
                  e.currentTarget.style.backgroundColor = 'transparent';
                  e.currentTarget.style.color = 'var(--text-tertiary)';
                }}
              >
                <RotateCcw size={13} />
              </button>
            )}
            <button
              onClick={(e) => {
                e.stopPropagation();
                onConfigure(module.id);
              }}
              data-tutorial="configure-btn"
              className="p-1.5 rounded-lg transition-colors"
              style={{ color: 'var(--text-tertiary)' }}
              title="Configurer"
              onMouseEnter={(e) => {
                e.currentTarget.style.backgroundColor = 'var(--bg-tertiary)';
                e.currentTarget.style.color = 'var(--text-primary)';
              }}
              onMouseLeave={(e) => {
                e.currentTarget.style.backgroundColor = 'transparent';
                e.currentTarget.style.color = 'var(--text-tertiary)';
              }}
            >
              <Settings size={13} />
            </button>
          </div>
          
          {module.isDraggable ? (
            <label
              data-tutorial="toggle-btn"
              className="relative inline-flex items-center cursor-pointer"
              onClick={(e) => e.stopPropagation()}
            >
              <input
                type="checkbox"
                checked={isEnabled}
                onChange={(e) => onToggle(module.id, e.target.checked)}
                className="sr-only peer"
              />
              <div
                className="w-9 h-5 rounded-full transition-all"
                style={{
                  backgroundColor: isEnabled ? primaryColor : 'var(--bg-tertiary)',
                }}
              >
                <div
                  className="absolute top-0.5 left-0.5 bg-white rounded-full h-4 w-4 transition-transform"
                  style={{ transform: isEnabled ? 'translateX(16px)' : 'translateX(0)' }}
                />
              </div>
            </label>
          ) : (
            <>
            </>
          )}
        </div>
      </div>
    </div>
  );
};

export default ModuleCard;
