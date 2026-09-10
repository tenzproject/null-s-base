import React, { useState, useEffect, useRef } from 'react';
import { hudPositionManager } from '../../utils/hudPositionManager';
import { getAnchorTransform } from '../../utils/anchorPositioning';
import { HUD_MODULES } from '../hud-editor/HUDModulesConfig';
import './StatusBar.css';

export type StatusBarId = 'mic' | 'health' | 'armor' | 'hunger' | 'thirst' | 'stamina' | 'oxygen';

/**
 * Identifiants des 7 styles disponibles (numérotation cohérente avec la
 * maquette Figma — le « style 4 » a été retiré, donc absent ici).
 */
// export type StatusBarStyle = 1 | 2 | 3 | 5 | 6 | 7 | 8;
export type StatusBarStyle = 1 | 2 | 3 | 5;

export const STATUS_BAR_STYLES: StatusBarStyle[] = [1, 2, 3, 5];

/**
 * Convertit une couleur (hex `#rgb` / `#rrggbb` ou `rgb(...)`) en `rgba(...)`
 * avec l'alpha fourni. Utilisé pour le glow accent du Style 2 (drop-shadow
 * n'accepte pas d'opacité séparée et CSS color-mix volontairement écarté).
 */
function hexToRgba(color: string, alpha: number): string {
  if (!color) return `rgba(92, 181, 255, ${alpha})`;
  const c = color.trim();
  // Forme rgb(r, g, b) / rgba(r, g, b, a) : on remplace juste l'alpha
  const rgbMatch = c.match(/^rgba?\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)/i);
  if (rgbMatch) {
    return `rgba(${rgbMatch[1]}, ${rgbMatch[2]}, ${rgbMatch[3]}, ${alpha})`;
  }
  // Forme hex #rgb ou #rrggbb
  let hex = c.replace(/^#/, '');
  if (hex.length === 3) hex = hex.split('').map(ch => ch + ch).join('');
  if (hex.length !== 6 || !/^[0-9a-f]{6}$/i.test(hex)) {
    return `rgba(92, 181, 255, ${alpha})`;
  }
  const r = parseInt(hex.slice(0, 2), 16);
  const g = parseInt(hex.slice(2, 4), 16);
  const b = parseInt(hex.slice(4, 6), 16);
  return `rgba(${r}, ${g}, ${b}, ${alpha})`;
}

interface StatusBarProps {
  barId: StatusBarId;
  value: number;
  icon: string;
  color: string;
  /** Style visuel (1, 2, 3, 5, 6, 7 ou 8). Défaut : 1. */
  style?: StatusBarStyle;
  previewMode?: boolean;
  previewPosition?: { x: number; y: number };
  hudEditorOpen?: boolean;
  visible?: boolean;
}

const StatusBar: React.FC<StatusBarProps> = ({
  barId,
  value,
  icon,
  color,
  style = 1,
  previewMode = false,
  previewPosition,
  hudEditorOpen = false,
  visible = true,
}) => {
  const [actualPosition, setActualPosition] = useState<{ x: number; y: number; anchor: string } | null>(null);
  const [show, setShow] = useState(false);
  const [animState, setAnimState] = useState<'entering' | 'leaving' | 'idle'>('idle');
  const prevVisibleRef = useRef(visible);

  useEffect(() => {
    if (previewMode) return;
    hudPositionManager.onReady(() => {
      const savedPos = hudPositionManager.getPosition(`status_bar_${barId}`);
      if (savedPos) setActualPosition(savedPos);
    });
  }, [previewMode, barId]);

  useEffect(() => {
    if (visible || previewMode) {
      setShow(true);
      setAnimState('entering');
      const t = setTimeout(() => setAnimState('idle'), 300);
      return () => clearTimeout(t);
    } else {
      setAnimState('leaving');
      const t = setTimeout(() => { setShow(false); setAnimState('idle'); }, 300);
      return () => clearTimeout(t);
    }
  }, [visible, previewMode]);

  const defaultConfig = HUD_MODULES.find(m => m.id === `status_bar_${barId}`);
  const positionStyle: React.CSSProperties = previewMode && previewPosition
    ? { left: '0px', top: '0px', transform: 'none' }
    : actualPosition
    ? { left: `${actualPosition.x}%`, top: `${actualPosition.y}%`, transform: getAnchorTransform(actualPosition.anchor as any) }
    : defaultConfig
    ? { left: `${defaultConfig.defaultPosition.x}%`, top: `${defaultConfig.defaultPosition.y}%`, transform: getAnchorTransform(defaultConfig.anchor as any) }
    : {};

  const fillPercent = Math.max(0, Math.min(100, value));
  const isLow = fillPercent <= 25 && fillPercent > 0;

  if (!show && !previewMode) return null;

  const cardClass = [
    'sb-card',
    animState === 'entering' ? 'sb-entering' : '',
    animState === 'leaving' ? 'sb-leaving' : '',
    isLow && animState === 'idle' ? 'sb-low' : '',
  ].filter(Boolean).join(' ');

  // Couleur d'accent (rouge si état low pour cohérence avec l'icône)
  const accentColor = isLow ? '#ff6464' : color;
  // Même couleur avec alpha 0.2 pour le glow (drop-shadow ne supporte pas
  // l'opacité directement, on doit fournir une couleur RGBA toute prête).
  const accentShadow = hexToRgba(accentColor, 0.2);

  // Variables CSS partagées par tous les styles
  // --sb-fill-radius : pilote le border-radius du fill du Style 1 :
  //   - 100 % : on suit la carte (radius sur les 4 coins)
  //   - sinon : on laisse le CSS appliquer son défaut (bottom-only) via
  //     fallback `var(--sb-fill-radius, 0 0 var(--sb-radius) var(--sb-radius))`.
  const isFull = fillPercent >= 100;
  const wrapperVars: React.CSSProperties = {
    ...positionStyle,
    ['--sb-color' as any]: accentColor,
    ['--sb-color-shadow' as any]: accentShadow,
    ['--sb-fill' as any]: `${fillPercent}%`,
    ...(isFull ? { ['--sb-fill-radius' as any]: 'var(--sb-radius)' } : {}),
    zIndex: 100,
  };

  const wrapperClass = `sb-wrapper sb-style-${style} ${previewMode ? '' : 'fixed'}`;

  // Style 2 : gradient injecté inline pour clip:text (le pourcentage est
  // dynamique donc ne peut pas être en pur CSS).
  const style2Gradient = `linear-gradient(180deg,
    var(--border-strong) 0%,
    var(--border-strong) ${100 - fillPercent}%,
    ${accentColor} ${100 - fillPercent}%,
    ${accentColor} 100%)`;

  return (
    <div className={wrapperClass} style={wrapperVars}>
      {/* ============================================================
          Style 1 — Remplissage interne par le bas
         ============================================================ */}
      {style === 1 && (
        <div className={cardClass}>
          <div className="sb-fill" />
          <i className={`sb-icon ${icon}`} />
        </div>
      )}

      {/* ============================================================
          Style 2 — L'icône se remplit verticalement (clip-path text)
          Le gradient est injecté via la variable CSS --sb-icon-gradient
          car FontAwesome dessine le glyph sur ::before (le background
          posé sur <i> clipperait la box, pas le glyph).
         ============================================================ */}
      {style === 2 && (
        <div className={cardClass}>
          <i
            className={`sb-icon ${icon}`}
            style={{ ['--sb-icon-gradient' as any]: style2Gradient } as React.CSSProperties}
          />
        </div>
      )}

      {/* ============================================================
          Style 3 — Carte + barre détachée petite
         ============================================================ */}
      {style === 3 && (
        <>
          <div className={cardClass}>
            <i className={`sb-icon ${icon}`} />
          </div>
          <div className={`sb-extbar sb-extbar-h ${isLow ? 'sb-low-bar' : ''}`}>
            <div className="sb-extbar-fill" />
          </div>
        </>
      )}

      {/* ============================================================
          Style 5 — Carte + barre horizontale large
         ============================================================ */}
      {style === 5 && (
        <>
          <div className={cardClass}>
            <i className={`sb-icon ${icon}`} />
          </div>
          <div className={`sb-extbar sb-extbar-h ${isLow ? 'sb-low-bar' : ''}`}>
            <div className="sb-extbar-fill" />
          </div>
        </>
      )}

      {/* ============================================================
          Style 6 — Barre verticale à gauche (plus haute que la carte)
         ============================================================ */}
      {/* {style === 6 && (
        <>
          <div className={`sb-extbar sb-extbar-v ${isLow ? 'sb-low-bar' : ''}`}>
            <div className="sb-extbar-fill" />
          </div>
          <div className={cardClass}>
            <i className={`sb-icon ${icon}`} />
          </div>
        </>
      )} */}

      {/* ============================================================
          Style 7 — Carte + petite barre horizontale collée
         ============================================================ */}
      {/* {style === 7 && (
        <>
          <div className={cardClass}>
            <i className={`sb-icon ${icon}`} />
          </div>
          <div className={`sb-extbar sb-extbar-h ${isLow ? 'sb-low-bar' : ''}`}>
            <div className="sb-extbar-fill" />
          </div>
        </>
      )} */}

      {/* ============================================================
          Style 8 — Barre verticale à gauche (collée à la carte)
         ============================================================ */}
      {/* {style === 8 && (
        <>
          <div className={`sb-extbar sb-extbar-v ${isLow ? 'sb-low-bar' : ''}`}>
            <div className="sb-extbar-fill" />
          </div>
          <div className={cardClass}>
            <i className={`sb-icon ${icon}`} />
          </div>
        </>
      )} */}
    </div>
  );
};

export default React.memo(StatusBar);
