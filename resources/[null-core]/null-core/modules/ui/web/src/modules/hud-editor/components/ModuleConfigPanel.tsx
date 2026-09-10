import React from 'react';
import { RotateCcw, Settings as SettingsIcon } from 'lucide-react';
import { HUDModule, AnchorPoint, HUD_MODULES } from '../HUDModulesConfig';
import { getAnchorName } from '../../../utils/anchorPositioning';
import StatusBar, { StatusBarStyle, STATUS_BAR_STYLES } from '../../hud/StatusBar';
import PlayerInfo from '../../hud/PlayerInfo';
import PlayerInfoModern from '../../hud/PlayerInfoModern';
import PlayerInfoModernMinimal from '../../hud/PlayerInfoModernMinimal';

const PINFO_PREVIEW_SERVER = {
  serverName: 'Null',
  serverColor: '#ffffff',
  serverIcon: '',
  serverDiscord: '',
};

const STATUS_BAR_META: Record<string, {
  key: 'mic' | 'health' | 'armor' | 'hunger' | 'thirst' | 'stamina' | 'oxygen';
  label: string;
  icon: string;
  value: number;
}> = {
  status_bar_mic:     { key: 'mic',     label: 'Microphone', icon: 'fa-solid fa-microphone-lines', value: 66 },
  status_bar_health:  { key: 'health',  label: 'Vie',        icon: 'fa-solid fa-heart',            value: 75 },
  status_bar_armor:   { key: 'armor',   label: 'Armure',     icon: 'fa-solid fa-shield',           value: 60 },
  status_bar_hunger:  { key: 'hunger',  label: 'Faim',       icon: 'fa-solid fa-burger',           value: 80 },
  status_bar_thirst:  { key: 'thirst',  label: 'Soif',       icon: 'fa-solid fa-droplet',          value: 55 },
  status_bar_stamina: { key: 'stamina', label: 'Stamina',    icon: 'fa-solid fa-person-running',   value: 90 },
  status_bar_oxygen:  { key: 'oxygen',  label: 'Oxygène',    icon: 'fa-solid fa-lungs',            value: 45 },
};

interface ModuleConfigPanelProps {
  module: HUDModule;
  anchor: AnchorPoint;
  enabled: boolean;
  colors: any;
  primaryColor: string;
  onChange: (partial: { anchor?: AnchorPoint; enabled?: boolean; colors?: any }) => void;
  onConfigureModule: (moduleId: string) => void;
}

const ModuleConfigPanel: React.FC<ModuleConfigPanelProps> = ({
  module,
  anchor,
  enabled,
  colors,
  primaryColor,
  onChange,
  onConfigureModule,
}) => {
  const isStatusBarSub = module.parentId === 'status_bars';
  const subMeta = isStatusBarSub ? STATUS_BAR_META[module.id] : null;
  const isStatusBarsParent = module.id === 'status_bars';

  const setColors = (next: any) => onChange({ colors: next });
  const patchColors = (patch: any) => onChange({ colors: { ...colors, ...patch } });

  const anchorOptions: AnchorPoint[] = [
    'top-left', 'top-center', 'top-right',
    'center-left', 'center', 'center-right',
    'bottom-left', 'bottom-center', 'bottom-right'
  ];

  const subBars = isStatusBarsParent
    ? HUD_MODULES.filter(m => m.parentId === 'status_bars')
    : [];

  return (
    <div className="space-y-6">
      {/* Activer / Désactiver */}
      {!module.alwaysEnabled ? (
        <section className="rounded-xl p-3.5" style={{ backgroundColor: 'var(--bg-secondary)' }}>
          <div className="flex items-center justify-between gap-3">
            <div className="min-w-0">
              <h3 className="text-sm font-semibold" style={{ color: 'var(--text-primary)' }}>
                Activer le module
              </h3>
              <p className="text-xs mt-0.5" style={{ color: 'var(--text-secondary)' }}>
                Affiche ou masque ce module dans le HUD
              </p>
            </div>
            <label className="relative inline-flex items-center cursor-pointer shrink-0">
              <input
                type="checkbox"
                checked={enabled}
                onChange={(e) => onChange({ enabled: e.target.checked })}
                className="sr-only peer"
              />
              <div
                className="w-11 h-6 rounded-full transition-all"
                style={{ backgroundColor: enabled ? primaryColor : 'var(--bg-tertiary)' }}
              >
                <div
                  className="absolute top-0.5 left-0.5 bg-white rounded-full h-5 w-5 transition-transform"
                  style={{ transform: enabled ? 'translateX(20px)' : 'translateX(0)' }}
                />
              </div>
            </label>
          </div>
        </section>
      ) : (
        <section className="rounded-xl p-3.5" style={{ backgroundColor: 'var(--bg-secondary)' }}>
          <h3 className="text-sm font-semibold" style={{ color: 'var(--text-primary)' }}>
            Module toujours actif
          </h3>
          <p className="text-xs mt-0.5" style={{ color: 'var(--text-secondary)' }}>
            Ce module est essentiel et ne peut pas être désactivé
          </p>
        </section>
      )}

      {/* Point d'ancrage */}
      {module.isDraggable && (
        <section>
          <h3 className="text-sm font-semibold mb-1" style={{ color: 'var(--text-primary)' }}>
            Point d'ancrage
          </h3>
          <p className="text-xs mb-3" style={{ color: 'var(--text-secondary)' }}>
            Définit le coin de référence pour positionner le module
          </p>
          <div className="grid grid-cols-3 gap-2">
            {anchorOptions.map((option) => {
              const active = anchor === option;
              return (
                <button
                  key={option}
                  onClick={() => onChange({ anchor: option })}
                  className="px-3 py-2 rounded-lg text-xs font-medium transition-all"
                  style={{
                    backgroundColor: active ? primaryColor : 'var(--bg-secondary)',
                    color: active ? 'white' : 'var(--text-secondary)',
                  }}
                >
                  {getAnchorName(option)}
                </button>
              );
            })}
          </div>
        </section>
      )}

      {/* Sous-barres (pour status_bars parent) */}
      {isStatusBarsParent && subBars.length > 0 && (
        <section>
          <h3 className="text-sm font-semibold mb-1" style={{ color: 'var(--text-primary)' }}>
            Barres individuelles
          </h3>
          <p className="text-xs mb-3" style={{ color: 'var(--text-secondary)' }}>
            Configure chaque barre individuellement (couleur, position)
          </p>
          <div className="grid grid-cols-2 gap-2">
            {subBars.map((bar) => {
              const meta = STATUS_BAR_META[bar.id];
              if (!meta) return null;
              const barColor = colors?.[meta.key] || primaryColor;
              return (
                <button
                  key={bar.id}
                  onClick={() => onConfigureModule(bar.id)}
                  className="flex items-center gap-3 px-3 py-2 rounded-lg transition-all hover:opacity-90"
                  style={{ backgroundColor: 'var(--bg-secondary)' }}
                >
                  <i className={meta.icon} style={{ color: barColor, fontSize: 16 }} />
                  <span className="text-xs flex-1 text-left" style={{ color: 'var(--text-primary)' }}>
                    {meta.label}
                  </span>
                  <SettingsIcon size={12} style={{ color: 'var(--text-tertiary)' }} />
                </button>
              );
            })}
          </div>
        </section>
      )}

      {/* Style des barres (status_bars parent OU sous-barre) */}
      {(isStatusBarsParent || isStatusBarSub) && (
        <section>
          <h3 className="text-sm font-semibold mb-1" style={{ color: 'var(--text-primary)' }}>
            Style des barres
          </h3>
          <p className="text-xs mb-3" style={{ color: 'var(--text-secondary)' }}>
            Apparence appliquée à toutes les barres de statut
          </p>
          <div className="grid grid-cols-4 gap-2">
            {STATUS_BAR_STYLES.map((styleId) => {
              const isActive = (colors?.barStyle || 1) === styleId;
              const previewKey = subMeta?.key || 'health';
              const previewIcon = subMeta?.icon || 'fa-solid fa-heart';
              const previewColor = colors?.[previewKey] || primaryColor;
              return (
                <button
                  key={styleId}
                  onClick={() => patchColors({ barStyle: styleId })}
                  className="rounded-lg text-xs font-medium transition-all flex flex-col items-center justify-between gap-1 py-2 px-1"
                  style={{
                    backgroundColor: isActive ? 'var(--bg-tertiary)' : 'var(--bg-secondary)',
                    color: isActive ? 'var(--text-primary)' : 'var(--text-secondary)',
                    border: `1px solid ${isActive ? primaryColor : 'var(--bg-tertiary)'}`,
                  }}
                >
                  <div
                    className="flex items-center justify-center"
                    style={{
                      width: '100%',
                      height: 52,
                      overflow: 'hidden',
                      transform: 'scale(0.85)',
                      pointerEvents: 'none',
                    }}
                  >
                    <StatusBar
                      barId={previewKey}
                      value={75}
                      icon={previewIcon}
                      color={previewColor}
                      style={styleId as StatusBarStyle}
                      previewMode={true}
                      previewPosition={{ x: 0, y: 0 }}
                      visible={true}
                    />
                  </div>
                  <span>Style {styleId}</span>
                </button>
              );
            })}
          </div>
        </section>
      )}

      {/* Couleurs de toutes les barres (status_bars parent) */}
      {isStatusBarsParent && (
        <section>
          <div className="flex items-center justify-between mb-3">
            <div>
              <h3 className="text-sm font-semibold" style={{ color: 'var(--text-primary)' }}>
                Couleurs des barres
              </h3>
              <p className="text-xs mt-1" style={{ color: 'var(--text-secondary)' }}>
                Personnalise la couleur de chaque barre
              </p>
            </div>
            <button
              onClick={() => patchColors({ mic: undefined, health: undefined, armor: undefined, hunger: undefined, thirst: undefined, stamina: undefined, oxygen: undefined })}
              className="p-2 rounded-lg transition-colors"
              style={{ backgroundColor: 'var(--bg-secondary)', color: 'var(--text-primary)' }}
              title="Réinitialiser les couleurs"
            >
              <RotateCcw size={14} />
            </button>
          </div>
          <div className="grid grid-cols-2 gap-2">
            {[
              { key: 'mic', label: 'Microphone' },
              { key: 'health', label: 'Vie' },
              { key: 'armor', label: 'Armure' },
              { key: 'hunger', label: 'Faim' },
              { key: 'thirst', label: 'Soif' },
              { key: 'stamina', label: 'Stamina' },
              { key: 'oxygen', label: 'Oxygène' },
            ].map(({ key, label }) => (
              <div key={key} className="flex items-center justify-between rounded-lg p-2.5" style={{ backgroundColor: 'var(--bg-secondary)' }}>
                <label className="text-xs" style={{ color: 'var(--text-secondary)' }}>{label}</label>
                <input
                  type="color"
                  value={colors?.[key] || primaryColor}
                  onChange={(e) => patchColors({ [key]: e.target.value })}
                  className="w-8 h-8 rounded cursor-pointer bg-transparent"
                  style={{ border: '1px solid var(--bg-tertiary)' }}
                />
              </div>
            ))}
          </div>
        </section>
      )}

      {/* Couleur d'une barre individuelle */}
      {isStatusBarSub && subMeta && (
        <section>
          <div className="flex items-center justify-between mb-3">
            <div>
              <h3 className="text-sm font-semibold" style={{ color: 'var(--text-primary)' }}>
                Couleur « {subMeta.label} »
              </h3>
              <p className="text-xs mt-1" style={{ color: 'var(--text-secondary)' }}>
                Couleur de cette barre uniquement
              </p>
            </div>
            <button
              onClick={() => {
                const next = { ...colors };
                delete next[subMeta.key];
                setColors(next);
              }}
              className="p-2 rounded-lg transition-colors"
              style={{ backgroundColor: 'var(--bg-secondary)', color: 'var(--text-primary)' }}
              title="Réinitialiser"
            >
              <RotateCcw size={14} />
            </button>
          </div>
          <div className="flex items-center justify-between rounded-lg p-3" style={{ backgroundColor: 'var(--bg-secondary)' }}>
            <div className="flex items-center gap-3">
              <i className={subMeta.icon} style={{ color: colors?.[subMeta.key] || primaryColor, fontSize: 18 }} />
              <span className="text-sm" style={{ color: 'var(--text-secondary)' }}>{subMeta.label}</span>
            </div>
            <input
              type="color"
              value={colors?.[subMeta.key] || primaryColor}
              onChange={(e) => patchColors({ [subMeta.key]: e.target.value })}
              className="w-10 h-10 rounded cursor-pointer bg-transparent"
              style={{ border: '1px solid var(--bg-tertiary)' }}
            />
          </div>
        </section>
      )}

      {/* Minimap */}
      {module.id === 'minimap' && (
        <section className="space-y-4">
          <div>
            <h3 className="text-sm font-semibold mb-1" style={{ color: 'var(--text-primary)' }}>Type de carte</h3>
            <p className="text-xs mb-3" style={{ color: 'var(--text-secondary)' }}>Forme de la minimap</p>
            <div className="flex gap-2">
              {[
                { key: 'square', label: '■ Carrée' },
                { key: 'circle', label: '● Ronde' },
              ].map(({ key, label }) => {
                const selected = (colors?.mapType || 'square') === key;
                return (
                  <button
                    key={key}
                    onClick={() => patchColors({ mapType: key })}
                    className="flex-1 px-4 py-2 rounded-lg transition-colors"
                    style={{
                      backgroundColor: selected ? primaryColor : 'var(--bg-secondary)',
                      color: selected ? 'white' : 'var(--text-secondary)',
                    }}
                  >
                    {label}
                  </button>
                );
              })}
            </div>
          </div>
          <div className="rounded-lg p-3 flex items-center justify-between" style={{ backgroundColor: 'var(--bg-secondary)' }}>
            <div>
              <h3 className="text-sm font-semibold" style={{ color: 'var(--text-primary)' }}>Uniquement en véhicule</h3>
              <p className="text-xs mt-1" style={{ color: 'var(--text-secondary)' }}>Cache la carte hors véhicule</p>
            </div>
            <label className="relative inline-flex items-center cursor-pointer">
              <input
                type="checkbox"
                checked={!!colors?.vehicleOnly}
                onChange={(e) => patchColors({ vehicleOnly: e.target.checked })}
                className="sr-only peer"
              />
              <div
                className="w-11 h-6 rounded-full transition-all"
                style={{ backgroundColor: colors?.vehicleOnly ? primaryColor : 'var(--bg-tertiary)' }}
              >
                <div
                  className="absolute top-0.5 left-0.5 bg-white rounded-full h-5 w-5 transition-transform"
                  style={{ transform: colors?.vehicleOnly ? 'translateX(20px)' : 'translateX(0)' }}
                />
              </div>
            </label>
          </div>
        </section>
      )}

      {/* Speedometer colors */}
      {module.id === 'speedometer' && (
        <section>
          <div className="flex items-center justify-between mb-3">
            <div>
              <h3 className="text-sm font-semibold" style={{ color: 'var(--text-primary)' }}>Couleurs du compteur</h3>
              <p className="text-xs mt-1" style={{ color: 'var(--text-secondary)' }}>Vitesse et carburant</p>
            </div>
            <button
              onClick={() => setColors({ ...(colors || {}), speed: undefined, fuel: undefined })}
              className="p-2 rounded-lg transition-colors"
              style={{ backgroundColor: 'var(--bg-secondary)', color: 'var(--text-primary)' }}
              title="Réinitialiser"
            >
              <RotateCcw size={14} />
            </button>
          </div>
          <div className="grid grid-cols-2 gap-3">
            {[
              { key: 'speed', label: 'Vitesse' },
              { key: 'fuel', label: 'Carburant' },
            ].map(({ key, label }) => (
              <div key={key} className="flex items-center justify-between rounded-lg p-3" style={{ backgroundColor: 'var(--bg-secondary)' }}>
                <label className="text-sm" style={{ color: 'var(--text-secondary)' }}>{label}</label>
                <input
                  type="color"
                  value={colors?.[key] || primaryColor}
                  onChange={(e) => patchColors({ [key]: e.target.value })}
                  className="w-9 h-9 rounded cursor-pointer bg-transparent"
                  style={{ border: '1px solid var(--bg-tertiary)' }}
                />
              </div>
            ))}
          </div>
        </section>
      )}

      {/* Variant selector (speedometer / ammo) */}
      {(module.id === 'speedometer' || module.id === 'ammo') && (
        <section>
          <h3 className="text-sm font-semibold mb-1" style={{ color: 'var(--text-primary)' }}>Type d'affichage</h3>
          <p className="text-xs mb-3" style={{ color: 'var(--text-secondary)' }}>
            {module.id === 'speedometer'
              ? 'Compteur holographique 3D ou affichage 2D classique'
              : 'Hologramme 3D de munitions ou 2D à côté de la minimap'}
          </p>
          <div className="grid grid-cols-2 gap-2">
            {[
              { key: 'hologram', label: 'Hologramme 3D', sub: 'Par défaut' },
              { key: '2d', label: 'Affichage 2D', sub: 'Classique' },
            ].map(({ key, label, sub }) => {
              const selected = (colors?.variant || 'hologram') === key;
              return (
                <button
                  key={key}
                  onClick={() => patchColors({ variant: key })}
                  className="px-3 py-2.5 rounded-lg transition-colors flex flex-col items-start"
                  style={{
                    backgroundColor: selected ? 'var(--bg-tertiary)' : 'var(--bg-secondary)',
                    color: selected ? 'var(--text-primary)' : 'var(--text-secondary)',
                    border: `1px solid ${selected ? primaryColor : 'transparent'}`,
                  }}
                >
                  <span className="text-sm font-medium">{label}</span>
                  <span className="text-[10px] opacity-70 mt-0.5">{sub}</span>
                </button>
              );
            })}
          </div>
        </section>
      )}

      {/* Player Info variant */}
      {module.id === 'player_info' && (
        <section>
          <h3 className="text-sm font-semibold mb-1" style={{ color: 'var(--text-primary)' }}>Style de l'interface</h3>
          <p className="text-xs mb-3" style={{ color: 'var(--text-secondary)' }}>Apparence du panneau d'infos joueur</p>
          <div className="grid grid-cols-3 gap-2">
            {[
              { key: 'modern', label: 'Moderne', sub: 'Design épuré', scale: 0.55, Comp: PlayerInfoModern },
              { key: 'compact', label: 'Compact', sub: 'Design classique', scale: 0.55, Comp: PlayerInfo },
              { key: 'minimal', label: 'Minimal', sub: "L'essentiel", scale: 0.45, Comp: PlayerInfoModernMinimal },
            ].map(({ key, label, sub, scale, Comp }) => {
              const selected = (colors?.variant || 'modern') === key;
              return (
                <button
                  key={key}
                  onClick={() => patchColors({ variant: key })}
                  className="rounded-lg transition-colors flex flex-col items-stretch overflow-hidden text-left"
                  style={{
                    backgroundColor: selected ? 'var(--bg-tertiary)' : 'var(--bg-secondary)',
                    color: selected ? 'var(--text-primary)' : 'var(--text-secondary)',
                    border: `1px solid ${selected ? primaryColor : 'transparent'}`,
                  }}
                >
                  <div
                    className="w-full flex items-center justify-center"
                    style={{
                      height: 70,
                      backgroundColor: 'rgba(0,0,0,0.35)',
                      overflow: 'hidden',
                      pointerEvents: 'none',
                    }}
                  >
                    <div style={{ transform: `scale(${scale})`, transformOrigin: 'center center' }}>
                      <Comp
                        serverConfig={PINFO_PREVIEW_SERVER}
                        primaryColor={primaryColor}
                        previewMode={true}
                        previewAnchor="top-right"
                        globalConfig={{ primaryColor, theme: 'dark', style: 'modern' }}
                      />
                    </div>
                  </div>
                  <div className="px-3 py-2 flex flex-col">
                    <span className="text-sm font-medium">{label}</span>
                    <span className="text-[10px] opacity-70 mt-0.5">{sub}</span>
                  </div>
                </button>
              );
            })}
          </div>
        </section>
      )}

      {/* 3D UI */}
      {module.id === 'ui_3d' && (
        <section className="space-y-5">
          <div>
            <h3 className="text-sm font-semibold mb-1" style={{ color: 'var(--text-primary)' }}>Pack graphique</h3>
            <p className="text-xs mb-3" style={{ color: 'var(--text-secondary)' }}>
              Pack Réaliste = fond sombre derrière le texte des hologrammes (utile si reflets gênants)
            </p>
            <div className="flex gap-2">
              {[
                { key: 'basic', label: 'Vanilla' },
                { key: 'realistic', label: 'Pack Réaliste' },
              ].map(({ key, label }) => {
                const selected = (colors?.packMode || 'basic') === key;
                return (
                  <button
                    key={key}
                    onClick={() => patchColors({ packMode: key })}
                    className="flex-1 px-4 py-2 rounded-lg transition-colors"
                    style={{
                      backgroundColor: selected ? 'var(--bg-tertiary)' : 'var(--bg-secondary)',
                      color: selected ? 'var(--text-primary)' : 'var(--text-secondary)',
                      border: `1px solid ${selected ? primaryColor : 'transparent'}`,
                    }}
                  >
                    {label}
                  </button>
                );
              })}
            </div>
          </div>
          <div>
            <h3 className="text-sm font-semibold mb-1" style={{ color: 'var(--text-primary)' }}>Qualité de rendu</h3>
            <p className="text-xs mb-3" style={{ color: 'var(--text-secondary)' }}>
              Résolution des textures 3D. Baisser si pertes de FPS.
            </p>
            <div className="grid grid-cols-3 gap-2">
              {[
                { key: 'low', label: 'Basse', sub: '512×512' },
                { key: 'medium', label: 'Moyenne', sub: '1024×1024' },
                { key: 'high', label: 'Haute', sub: '2048×2048' },
              ].map(({ key, label, sub }) => {
                const selected = (colors?.quality || 'medium') === key;
                return (
                  <button
                    key={key}
                    onClick={() => patchColors({ quality: key })}
                    className="px-3 py-2.5 rounded-lg transition-colors flex flex-col items-start"
                    style={{
                      backgroundColor: selected ? 'var(--bg-tertiary)' : 'var(--bg-secondary)',
                      color: selected ? 'var(--text-primary)' : 'var(--text-secondary)',
                      border: `1px solid ${selected ? primaryColor : 'transparent'}`,
                    }}
                  >
                    <span className="text-sm font-medium">{label}</span>
                    <span className="text-[10px] opacity-70 mt-0.5">{sub}</span>
                  </button>
                );
              })}
            </div>
          </div>
        </section>
      )}

      {/* Aperçu ancrage */}
      {module.isDraggable && (
        <section>
          <h3 className="text-sm font-semibold mb-2" style={{ color: 'var(--text-primary)' }}>Aperçu de l'ancrage</h3>
          <div className="relative w-full h-32 rounded-lg" style={{ backgroundColor: 'var(--bg-secondary)' }}>
            <div
              className="absolute w-3 h-3 rounded-full"
              style={{
                backgroundColor: primaryColor,
                border: '2px solid white',
                left: anchor.includes('left') ? '0' : anchor.includes('right') ? '100%' : '50%',
                top: anchor.includes('top') ? '0' : anchor.includes('bottom') ? '100%' : '50%',
                transform: 'translate(-50%, -50%)',
              }}
            />
            <div className="absolute inset-0 flex items-center justify-center">
              <div
                className="w-16 h-12 rounded"
                style={{ border: `2px dashed ${primaryColor}`, backgroundColor: 'rgba(255,255,255,0.04)' }}
              />
            </div>
          </div>
        </section>
      )}
    </div>
  );
};

export default ModuleConfigPanel;
