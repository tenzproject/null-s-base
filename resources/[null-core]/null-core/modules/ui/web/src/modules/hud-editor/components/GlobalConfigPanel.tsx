import React from 'react';
import { Palette, Moon, Sun, Layout, RotateCcw } from 'lucide-react';

export interface GlobalConfig {
  primaryColor: string;
  theme: 'dark' | 'light';
  style: 'modern' | 'compact';
}

interface GlobalConfigPanelProps {
  config: GlobalConfig;
  defaultPrimaryColor: string;
  devMode?: boolean;
  onChange: (partial: Partial<GlobalConfig>) => void;
}

const GlobalConfigPanel: React.FC<GlobalConfigPanelProps> = ({
  config,
  defaultPrimaryColor,
  devMode = false,
  onChange,
}) => {
  const { primaryColor, theme, style } = config;

  return (
    <div className="space-y-6">
      {/* Primary Color */}
      <section>
        <div className="flex items-center justify-between mb-2">
          <div className="flex items-center gap-2">
            <Palette className="w-4 h-4" style={{ color: primaryColor }} />
            <h3 className="text-sm font-semibold" style={{ color: 'var(--text-primary)' }}>
              Couleur primaire
            </h3>
          </div>
          <button
            onClick={() => onChange({ primaryColor: defaultPrimaryColor })}
            className="p-2 rounded-lg transition-colors"
            style={{ backgroundColor: 'var(--bg-secondary)', color: 'var(--text-primary)' }}
            title="Réinitialiser la couleur"
          >
            <RotateCcw size={14} />
          </button>
        </div>
        <p className="text-xs mb-3" style={{ color: 'var(--text-secondary)' }}>
          Définit la couleur principale utilisée dans tous les éléments du HUD
        </p>
        <div
          className="flex items-center gap-3 rounded-lg p-3"
          style={{ backgroundColor: 'var(--bg-secondary)' }}
        >
          <input
            type="color"
            value={primaryColor}
            onChange={(e) => onChange({ primaryColor: e.target.value })}
            className="w-9 h-9 rounded cursor-pointer bg-transparent"
            style={{ border: '1px solid var(--bg-tertiary)' }}
          />
          <input
            type="text"
            value={primaryColor}
            onChange={(e) => onChange({ primaryColor: e.target.value })}
            className="flex-1 px-3 py-2 rounded text-sm font-mono outline-none"
            style={{
              backgroundColor: 'transparent',
              border: 'none',
              color: 'var(--text-primary)',
            }}
            placeholder="#c0c0c0"
          />
        </div>
      </section>

      {/* Theme */}
      <section className={devMode ? '' : 'relative'}>
        <div className="flex items-center justify-between mb-2">
          <div className="flex items-center gap-2">
            {theme === 'dark' ? (
              <Moon className="w-4 h-4" style={{ color: 'var(--text-primary)' }} />
            ) : (
              <Sun className="w-4 h-4" style={{ color: 'var(--text-primary)' }} />
            )}
            <h3 className="text-sm font-semibold" style={{ color: 'var(--text-primary)' }}>
              Thème
            </h3>
          </div>
          {!devMode && (
            <span
              className="px-2 py-0.5 rounded text-[10px] uppercase tracking-wide font-medium"
              style={{
                backgroundColor: 'rgba(255, 159, 26, 0.15)',
                color: '#ff9f1a',
                border: '1px solid rgba(255, 159, 26, 0.35)',
              }}
            >
              En développement
            </span>
          )}
        </div>
        <p className="text-xs mb-3" style={{ color: 'var(--text-secondary)' }}>
          Choisissez entre un thème sombre ou clair pour l'interface
        </p>
        <div
          className={`grid grid-cols-2 gap-2 ${devMode ? '' : 'opacity-50 pointer-events-none'}`}
        >
          <button
            onClick={() => devMode && onChange({ theme: 'dark' })}
            className="p-3 rounded-lg transition-all flex flex-col items-start"
            style={{
              backgroundColor: theme === 'dark' ? primaryColor : 'var(--bg-secondary)',
              color: theme === 'dark' ? 'white' : 'var(--text-secondary)',
            }}
          >
            <Moon className="w-4 h-4 mb-2" />
            <span className="text-sm font-medium">Sombre</span>
            <span className="text-[10px] opacity-70 mt-0.5">Par défaut</span>
          </button>
          <button
            onClick={() => devMode && onChange({ theme: 'light' })}
            className="p-3 rounded-lg transition-all flex flex-col items-start"
            style={{
              backgroundColor: theme === 'light' ? primaryColor : 'var(--bg-secondary)',
              color: theme === 'light' ? 'white' : 'var(--text-secondary)',
            }}
          >
            <Sun className="w-4 h-4 mb-2" />
            <span className="text-sm font-medium">Clair</span>
            <span className="text-[10px] opacity-70 mt-0.5">Lumineux</span>
          </button>
        </div>
      </section>

      {/* Style */}
      <section>
        <div className="flex items-center gap-2 mb-2">
          <Layout className="w-4 h-4" style={{ color: 'var(--text-primary)' }} />
          <h3 className="text-sm font-semibold" style={{ color: 'var(--text-primary)' }}>
            Style global
          </h3>
        </div>
        <p className="text-xs mb-3" style={{ color: 'var(--text-secondary)' }}>
          Définit l'apparence générale des éléments du HUD
        </p>
        <div className="grid grid-cols-2 gap-2">
          <button
            onClick={() => onChange({ style: 'modern' })}
            className="p-3 rounded-lg transition-all flex flex-col items-start"
            style={{
              backgroundColor: style === 'modern' ? primaryColor : 'var(--bg-secondary)',
              color: style === 'modern' ? 'white' : 'var(--text-secondary)',
            }}
          >
            <span className="text-sm font-medium">Moderne</span>
            <span className="text-[10px] opacity-70 mt-0.5">Design épuré</span>
            <div className="w-full mt-3 space-y-1.5">
              <div className="h-1.5 rounded" style={{ backgroundColor: 'rgba(255,255,255,0.3)' }} />
              <div className="h-1.5 rounded" style={{ backgroundColor: 'rgba(255,255,255,0.2)' }} />
              <div className="h-1.5 rounded" style={{ backgroundColor: 'rgba(255,255,255,0.1)' }} />
            </div>
          </button>
          <button
            onClick={() => onChange({ style: 'compact' })}
            className="p-3 rounded-lg transition-all flex flex-col items-start"
            style={{
              backgroundColor: style === 'compact' ? primaryColor : 'var(--bg-secondary)',
              color: style === 'compact' ? 'white' : 'var(--text-secondary)',
            }}
          >
            <span className="text-sm font-medium">Compact</span>
            <span className="text-[10px] opacity-70 mt-0.5">Minimaliste</span>
            <div className="w-full mt-3 space-y-1">
              <div className="h-1 rounded" style={{ backgroundColor: 'rgba(255,255,255,0.3)' }} />
              <div className="h-1 rounded" style={{ backgroundColor: 'rgba(255,255,255,0.2)' }} />
              <div className="h-1 rounded" style={{ backgroundColor: 'rgba(255,255,255,0.1)' }} />
            </div>
          </button>
        </div>
      </section>
    </div>
  );
};

export default GlobalConfigPanel;
