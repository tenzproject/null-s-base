import React from 'react';
import { Save, X, Settings, GraduationCap, ArrowLeft, Search, ChevronUp, ChevronDown } from 'lucide-react';
import { HUD_MODULES, HUDModule, AnchorPoint, HUDModuleState } from '../HUDModulesConfig';
import ModuleCard from './ModuleCard';
import ModuleConfigPanel from './ModuleConfigPanel';
import GlobalConfigPanel, { GlobalConfig } from './GlobalConfigPanel';

interface ModuleSelectorProps {
  enabledModules: Set<string>;
  moduleStates: Map<string, HUDModuleState>;
  configuringModuleId: string | null;
  globalConfigOpen: boolean;
  globalConfig: GlobalConfig;
  defaultPrimaryColor: string;
  devMode?: boolean;
  onToggleModule: (moduleId: string, enabled: boolean) => void;
  onResetModule: (moduleId: string) => void;
  onConfigureModule: (moduleId: string) => void;
  onBackToList: () => void;
  onConfigChange: (moduleId: string, partial: { anchor?: AnchorPoint; enabled?: boolean; colors?: any }) => void;
  onGlobalConfigChange: (partial: Partial<GlobalConfig>) => void;
  onSave: () => void;
  onClose: () => void;
  onOpenGlobalConfig: () => void;
  onOpenTutorial: () => void;
  primaryColor: string;
  statusColors?: any;
  speedometerColors?: any;
  hasUnsavedChanges?: boolean;
  isCollapsed: boolean;
  onToggleCollapse: () => void;
}

const CATEGORY_LABELS: Record<string, string> = {
  HUD: 'HUD',
  Status: 'Statut',
  Info: 'Informations',
  Notification: 'Notifications',
  Interaction: 'Interactions',
  Menu: 'Menus',
};

const ModuleSelector: React.FC<ModuleSelectorProps> = ({
  enabledModules,
  moduleStates,
  configuringModuleId,
  globalConfigOpen,
  globalConfig,
  defaultPrimaryColor,
  devMode,
  onToggleModule,
  onResetModule,
  onConfigureModule,
  onBackToList,
  onConfigChange,
  onGlobalConfigChange,
  onSave,
  onClose,
  onOpenGlobalConfig,
  onOpenTutorial,
  primaryColor,
  statusColors,
  speedometerColors,
  hasUnsavedChanges,
  isCollapsed,
  onToggleCollapse,
}) => {
  const [search, setSearch] = React.useState('');
  const [activeCategory, setActiveCategory] = React.useState<string | null>(null);

  const configuringModule = configuringModuleId
    ? HUD_MODULES.find((m) => m.id === configuringModuleId) || null
    : null;
  const configuringState = configuringModuleId ? moduleStates.get(configuringModuleId) : null;

  const inConfigMode = !!configuringModule;
  const inGlobalMode = globalConfigOpen && !inConfigMode;
  const inSubMode = inConfigMode || inGlobalMode;

  // Modules visibles dans la liste : pas de sous-modules (status_bar_*) — accessibles via le panel de config de status_bars
  const allModules = HUD_MODULES.filter((m) => !m.isSubModule);
  const categories = Array.from(new Set(allModules.map((m) => m.category)));

  const visibleModules = allModules.filter((m) => {
    if (activeCategory && m.category !== activeCategory) return false;
    if (search.trim()) {
      const q = search.toLowerCase();
      if (!m.name.toLowerCase().includes(q) && !m.description.toLowerCase().includes(q)) {
        return false;
      }
    }
    return true;
  });

  const enabledCount = enabledModules.size;
  const totalCount = allModules.length;

  // Couleurs du module en cours de configuration (avec fallback parent pour status_bar_*)
  const configColors = configuringModule
    ? configuringModule.parentId === 'status_bars'
      ? (statusColors || moduleStates.get('status_bars')?.colors || {})
      : (configuringState?.colors
          || (configuringModule.id === 'status_bars'
              ? statusColors
              : configuringModule.id === 'speedometer'
                ? speedometerColors
                : {}))
    : {};

  return (
    <div
      className="fixed top-0 left-1/2 -translate-x-1/2 z-[10001]"
      data-tutorial="editor-panel"
      style={{
        width: '60%',
        maxWidth: '900px',
      }}
    >
      <div
        className="rounded-b-2xl shadow-2xl overflow-hidden"
        style={{
          backgroundColor: 'var(--bg-primary)',
          border: '1px solid var(--border-color, rgba(255,255,255,0.08))',
          borderTop: 'none',
        }}
      >
        {/* HEADER */}
        <div
          className="flex items-center justify-between gap-4 px-6 py-4"
          style={{ borderBottom: '1px solid var(--border-color, rgba(255,255,255,0.08))' }}
        >
          <div className="flex items-center gap-3 min-w-0">
            {inSubMode ? (
              <button
                onClick={onBackToList}
                className="p-2 rounded-lg transition-colors flex items-center gap-2"
                style={{ backgroundColor: 'var(--bg-secondary)', color: 'var(--text-primary)' }}
                title="Retour à la liste"
              >
                <ArrowLeft size={18} />
                <span className="text-sm">Retour</span>
              </button>
            ) : (
              <button
                onClick={onToggleCollapse}
                data-tutorial="collapse-btn"
                className="p-2 rounded-lg transition-colors"
                style={{ color: 'var(--text-secondary)' }}
                title={isCollapsed ? 'Déplier' : 'Réduire'}
              >
                {isCollapsed ? <ChevronDown size={18} /> : <ChevronUp size={18} />}
              </button>
            )}
            <div className="min-w-0">
              <h2 className="font-bold text-lg truncate" style={{ color: 'var(--text-primary)' }}>
                {inConfigMode
                  ? configuringModule!.name
                  : inGlobalMode
                    ? 'Configuration globale'
                    : 'Éditeur HUD'}
              </h2>
              <p className="text-xs truncate" style={{ color: 'var(--text-secondary)' }}>
                {inConfigMode
                  ? configuringModule!.description
                  : inGlobalMode
                    ? 'Couleur, thème et style appliqués à tout le HUD'
                    : `${enabledCount} / ${totalCount} module${totalCount > 1 ? 's' : ''} actif${enabledCount > 1 ? 's' : ''}`}
              </p>
            </div>
          </div>

          <div className="flex items-center gap-2 shrink-0">
            {!inSubMode && (
              <button
                onClick={onOpenTutorial}
                className="p-2 rounded-lg transition-colors"
                style={{ color: 'var(--text-secondary)' }}
                title="Tutoriel"
              >
                <GraduationCap size={18} />
              </button>
            )}
            {!inSubMode && (
              <button
                onClick={onOpenGlobalConfig}
                data-tutorial="global-config-btn"
                className="px-3 py-2 rounded-lg transition-colors flex items-center gap-2 text-sm"
                style={{ color: 'var(--text-primary)', backgroundColor: 'var(--bg-secondary)' }}
                title="Configuration globale"
              >
                <Settings size={16} />
                <span>Config Globale</span>
              </button>
            )}
            <button
              onClick={onSave}
              data-tutorial="save-btn"
              className="px-4 py-2 rounded-lg font-semibold text-sm flex items-center gap-2 transition-all"
              style={{
                backgroundColor: primaryColor,
                color: 'white',
                opacity: hasUnsavedChanges ? 1 : 0.85,
              }}
            >
              <Save size={16} />
              <span>Sauvegarder</span>
              {hasUnsavedChanges && (
                <span
                  className="w-1.5 h-1.5 rounded-full"
                  style={{ backgroundColor: 'white' }}
                />
              )}
            </button>
            <button
              onClick={onClose}
              className="p-2 rounded-lg transition-colors"
              style={{ color: 'var(--text-secondary)' }}
              title="Fermer"
            >
              <X size={18} />
            </button>
          </div>
        </div>

        {/* BODY */}
        <div
          className="overflow-y-auto"
          style={{
            maxHeight: isCollapsed && !inSubMode ? 0 : 'calc(85vh - 76px)',
            transition: 'max-height 0.25s ease',
          }}
        >
          {inGlobalMode ? (
            <div className="p-6">
              <GlobalConfigPanel
                config={globalConfig}
                defaultPrimaryColor={defaultPrimaryColor}
                devMode={devMode}
                onChange={onGlobalConfigChange}
              />
            </div>
          ) : !inConfigMode ? (
            <div className="p-6 space-y-5">
              {/* Recherche + filtres */}
              <div className="flex flex-col md:flex-row md:items-center gap-3">
                <div
                  className="flex items-center gap-2 px-3 py-2 rounded-lg flex-1"
                  style={{ backgroundColor: 'var(--bg-secondary)' }}
                >
                  <Search size={14} style={{ color: 'var(--text-tertiary)' }} />
                  <input
                    type="text"
                    placeholder="Rechercher un module..."
                    value={search}
                    onChange={(e) => setSearch(e.target.value)}
                    className="bg-transparent outline-none text-sm flex-1"
                    style={{ color: 'var(--text-primary)' }}
                  />
                </div>
                <div className="flex items-center gap-1.5 flex-wrap">
                  <button
                    onClick={() => setActiveCategory(null)}
                    className="px-3 py-1.5 rounded-lg text-xs font-medium transition-colors"
                    style={{
                      backgroundColor: activeCategory === null ? primaryColor : 'var(--bg-secondary)',
                      color: activeCategory === null ? 'white' : 'var(--text-secondary)',
                    }}
                  >
                    Tous
                  </button>
                  {categories.map((cat) => (
                    <button
                      key={cat}
                      onClick={() => setActiveCategory(activeCategory === cat ? null : cat)}
                      className="px-3 py-1.5 rounded-lg text-xs font-medium transition-colors"
                      style={{
                        backgroundColor: activeCategory === cat ? primaryColor : 'var(--bg-secondary)',
                        color: activeCategory === cat ? 'white' : 'var(--text-secondary)',
                      }}
                    >
                      {CATEGORY_LABELS[cat] || cat}
                    </button>
                  ))}
                </div>
              </div>

              {/* Grille de modules */}
              {visibleModules.length === 0 ? (
                <div
                  className="text-center py-12 rounded-xl"
                  style={{ backgroundColor: 'var(--bg-secondary)', color: 'var(--text-tertiary)' }}
                >
                  <p className="text-sm">Aucun module ne correspond à la recherche</p>
                </div>
              ) : (
                <div data-tutorial="modules-grid" className="overflow-y-auto grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-3" style={{maxHeight:'39vh'}} >
                  {visibleModules.map((module, idx) => (
                    <div key={module.id} data-tutorial={idx === 0 ? 'first-module-card' : undefined}>
                      <ModuleCard
                        module={module}
                        isEnabled={enabledModules.has(module.id)}
                        onToggle={onToggleModule}
                        onReset={onResetModule}
                        onConfigure={onConfigureModule}
                        primaryColor={primaryColor}
                      />
                    </div>
                  ))}
                </div>
              )}
            </div>
          ) : (
            configuringModule && configuringState && (
              <div className="p-6">
                <ModuleConfigPanel
                  module={configuringModule}
                  anchor={configuringState.anchor}
                  enabled={configuringState.enabled}
                  colors={configColors}
                  primaryColor={primaryColor}
                  onChange={(partial) => onConfigChange(configuringModule.id, partial)}
                  onConfigureModule={onConfigureModule}
                />
              </div>
            )
          )}
        </div>
      </div>
    </div>
  );
};

export default ModuleSelector;
