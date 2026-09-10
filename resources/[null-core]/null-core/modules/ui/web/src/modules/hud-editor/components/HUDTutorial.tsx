import React, { useState, useEffect, useLayoutEffect, useRef, useCallback } from 'react';
import { ChevronRight, ChevronLeft, X } from 'lucide-react';

function GetParentResourceName(): string {
  return 'null-core';
}

export interface TutorialControls {
  expandPanel: () => void;
  collapsePanel: () => void;
  openModuleConfig: (moduleId: string) => void;
  closeModuleConfig: () => void;
  openGlobalConfig: () => void;
  closeGlobalConfig: () => void;
}

type Placement = 'auto' | 'top' | 'bottom' | 'left' | 'right' | 'center';

interface TutorialStep {
  id: string;
  title: string;
  body: string;
  target?: string;
  placement?: Placement;
  padding?: number;
  advanceOnClick?: boolean;
  hint?: string;
  onEnter?: (ctx: TutorialControls) => void;
}

interface HUDTutorialProps {
  isOpen: boolean;
  onClose: () => void;
  primaryColor: string;
  controls: TutorialControls;
}

interface Rect {
  x: number;
  y: number;
  w: number;
  h: number;
}

const STEP_PADDING_DEFAULT = 8;
const COACHMARK_W = 340;
const COACHMARK_GAP = 16;
const VIEWPORT_PAD = 16;

const HUDTutorial: React.FC<HUDTutorialProps> = ({ isOpen, onClose, primaryColor, controls }) => {
  const [currentStep, setCurrentStep] = useState(0);
  const [targetRect, setTargetRect] = useState<Rect | null>(null);
  const [coachRect, setCoachRect] = useState<{ left: number; top: number; placement: Exclude<Placement, 'auto'> } | null>(null);
  const coachRef = useRef<HTMLDivElement>(null);

  const steps: TutorialStep[] = [
    {
      id: 'welcome',
      title: 'Bienvenue dans l\'éditeur HUD',
      body: 'Tu vas pouvoir personnaliser entièrement l\'apparence et la position de ton interface. Suivons les bases ensemble.',
      placement: 'center',
    },
    {
      id: 'panel',
      title: 'Le panneau principal',
      body: 'Tout se passe ici. Recherche, filtres et liste des modules disponibles.',
      target: '[data-tutorial="editor-panel"]',
      placement: 'bottom',
      padding: 4,
      onEnter: (c) => c.expandPanel(),
    },
    {
      id: 'collapse',
      title: 'Réduire pour voir l\'écran',
      body: 'Le panneau prend de la place. Clique sur la flèche pour le replier et avoir une vue dégagée du jeu.',
      target: '[data-tutorial="collapse-btn"]',
      advanceOnClick: true,
      hint: 'Clique sur la flèche',
    },
    {
      id: 'modules',
      title: 'La liste des modules',
      body: 'Chaque carte représente un élément de ton HUD. Tu peux les chercher, les filtrer par catégorie, les activer et les configurer.',
      target: '[data-tutorial="modules-grid"]',
      placement: 'bottom',
      padding: 6,
      onEnter: (c) => c.expandPanel(),
    },
    {
      id: 'toggle',
      title: 'Activer un module',
      body: 'L\'interrupteur active ou désactive l\'affichage du module dans le HUD. Essaye-le.',
      target: '[data-tutorial="first-module-card"] [data-tutorial="toggle-btn"]',
      advanceOnClick: true,
      hint: 'Clique sur l\'interrupteur',
    },
    {
      id: 'configure',
      title: 'Configurer un module',
      body: 'L\'engrenage ouvre la configuration détaillée : ancrage, couleurs, options spécifiques.',
      target: '[data-tutorial="first-module-card"] [data-tutorial="configure-btn"]',
      advanceOnClick: true,
      hint: 'Clique sur l\'engrenage',
      onEnter: (c) => c.closeModuleConfig(),
    },
    {
      id: 'config-panel',
      title: 'Le panneau de configuration',
      body: 'Toutes les options du module apparaissent ici. Les changements sont appliqués en direct, sans rechargement.',
      target: '[data-tutorial="editor-panel"]',
      placement: 'bottom',
      padding: 4,
      onEnter: (c) => c.openModuleConfig('minimap'),
    },
    {
      id: 'global',
      title: 'Configuration globale',
      body: 'Couleur d\'accent, thème et style appliqués à toute l\'interface. À utiliser avec parcimonie.',
      target: '[data-tutorial="global-config-btn"]',
      onEnter: (c) => { c.closeModuleConfig(); c.closeGlobalConfig(); },
    },
    {
      id: 'save',
      title: 'Sauvegarder tes changements',
      body: 'Aucune modification n\'est persistée tant que tu n\'as pas cliqué ici. Pense à sauvegarder avant de quitter.',
      target: '[data-tutorial="save-btn"]',
      onEnter: (c) => { c.closeModuleConfig(); c.closeGlobalConfig(); },
    },
    {
      id: 'done',
      title: 'Tu es prêt',
      body: 'Tu connais maintenant l\'essentiel. Explore les modules, configure ton HUD à ta guise. Tu peux relancer ce tutoriel à tout moment.',
      placement: 'center',
    },
  ];

  const step = steps[currentStep];
  const total = steps.length;
  const isLast = currentStep === total - 1;

  // Reset on open
  useEffect(() => {
    if (isOpen) setCurrentStep(0);
  }, [isOpen]);

  // Trigger onEnter actions
  useEffect(() => {
    if (!isOpen) return;
    step.onEnter?.(controls);
  }, [isOpen, currentStep]);

  // Track target rect
  const measureTarget = useCallback(() => {
    if (!step.target) {
      setTargetRect(null);
      return;
    }
    const el = document.querySelector(step.target) as HTMLElement | null;
    if (!el) {
      setTargetRect(null);
      return;
    }
    const r = el.getBoundingClientRect();
    setTargetRect({ x: r.left, y: r.top, w: r.width, h: r.height });
  }, [step.target]);

  useLayoutEffect(() => {
    if (!isOpen) return;
    measureTarget();
    // Re-measure after small delay to capture transitions (panel collapse, config open)
    const t1 = setTimeout(measureTarget, 100);
    const t2 = setTimeout(measureTarget, 350);
    return () => { clearTimeout(t1); clearTimeout(t2); };
  }, [isOpen, currentStep, measureTarget]);

  useEffect(() => {
    if (!isOpen) return;
    const handler = () => measureTarget();
    window.addEventListener('resize', handler);
    window.addEventListener('scroll', handler, true);
    const interval = window.setInterval(measureTarget, 400);
    return () => {
      window.removeEventListener('resize', handler);
      window.removeEventListener('scroll', handler, true);
      window.clearInterval(interval);
    };
  }, [isOpen, measureTarget]);

  // Position the coachmark
  useLayoutEffect(() => {
    if (!isOpen) return;
    const coachH = coachRef.current?.offsetHeight || 160;
    const vw = window.innerWidth;
    const vh = window.innerHeight;

    const wantedPlacement = step.placement || 'auto';

    if (wantedPlacement === 'center' || !targetRect) {
      setCoachRect({
        left: Math.round((vw - COACHMARK_W) / 2),
        top: Math.round((vh - coachH) / 2),
        placement: 'center',
      });
      return;
    }

    const t = targetRect;
    const pad = step.padding ?? STEP_PADDING_DEFAULT;
    const tx = t.x - pad;
    const ty = t.y - pad;
    const tw = t.w + pad * 2;
    const th = t.h + pad * 2;

    type Cand = { p: Exclude<Placement, 'auto' | 'center'>; left: number; top: number; ok: boolean; score: number };
    const candidates: Cand[] = [
      {
        p: 'bottom',
        left: clamp(tx + tw / 2 - COACHMARK_W / 2, VIEWPORT_PAD, vw - COACHMARK_W - VIEWPORT_PAD),
        top: ty + th + COACHMARK_GAP,
        ok: ty + th + COACHMARK_GAP + coachH < vh - VIEWPORT_PAD,
        score: 0,
      },
      {
        p: 'top',
        left: clamp(tx + tw / 2 - COACHMARK_W / 2, VIEWPORT_PAD, vw - COACHMARK_W - VIEWPORT_PAD),
        top: ty - COACHMARK_GAP - coachH,
        ok: ty - COACHMARK_GAP - coachH > VIEWPORT_PAD,
        score: 0,
      },
      {
        p: 'right',
        left: tx + tw + COACHMARK_GAP,
        top: clamp(ty + th / 2 - coachH / 2, VIEWPORT_PAD, vh - coachH - VIEWPORT_PAD),
        ok: tx + tw + COACHMARK_GAP + COACHMARK_W < vw - VIEWPORT_PAD,
        score: 0,
      },
      {
        p: 'left',
        left: tx - COACHMARK_GAP - COACHMARK_W,
        top: clamp(ty + th / 2 - coachH / 2, VIEWPORT_PAD, vh - coachH - VIEWPORT_PAD),
        ok: tx - COACHMARK_GAP - COACHMARK_W > VIEWPORT_PAD,
        score: 0,
      },
    ];

    let chosen: Cand | undefined;
    if (wantedPlacement !== 'auto') {
      chosen = candidates.find((c) => c.p === wantedPlacement && c.ok);
    }
    if (!chosen) chosen = candidates.find((c) => c.ok);
    if (!chosen) chosen = candidates[0];

    setCoachRect({ left: Math.round(chosen.left), top: Math.round(chosen.top), placement: chosen.p });
  }, [targetRect, currentStep, isOpen, step.placement, step.padding]);

  // Click-to-advance on target
  useEffect(() => {
    if (!isOpen || !step.advanceOnClick || !step.target) return;
    const el = document.querySelector(step.target) as HTMLElement | null;
    if (!el) return;
    const handler = () => {
      window.setTimeout(() => goNext(), 250);
    };
    el.addEventListener('click', handler, { once: true });
    return () => el.removeEventListener('click', handler);
  }, [isOpen, currentStep, step.advanceOnClick, step.target]);

  const goNext = useCallback(() => {
    if (currentStep < total - 1) {
      setCurrentStep((s) => s + 1);
    } else {
      handleFinish();
    }
  }, [currentStep, total]);

  const goPrev = useCallback(() => {
    if (currentStep > 0) setCurrentStep((s) => s - 1);
  }, [currentStep]);

  const handleFinish = useCallback(() => {
    fetch(`https://${GetParentResourceName()}/completeTutorial`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({}),
    }).catch(() => {});
    onClose();
  }, [onClose]);

  // Keyboard navigation
  useEffect(() => {
    if (!isOpen) return;
    const handler = (e: KeyboardEvent) => {
      if (e.key === 'ArrowRight') { e.preventDefault(); goNext(); }
      else if (e.key === 'ArrowLeft') { e.preventDefault(); goPrev(); }
      else if (e.key === 'Escape') { e.preventDefault(); handleFinish(); }
    };
    window.addEventListener('keydown', handler);
    return () => window.removeEventListener('keydown', handler);
  }, [isOpen, goNext, goPrev, handleFinish]);

  if (!isOpen) return null;

  const vw = typeof window !== 'undefined' ? window.innerWidth : 1920;
  const vh = typeof window !== 'undefined' ? window.innerHeight : 1080;
  const pad = step.padding ?? STEP_PADDING_DEFAULT;
  const showSpotlight = !!targetRect && step.placement !== 'center';

  return (
    <div className="fixed inset-0 z-[10005]" style={{ pointerEvents: 'none' }}>
      {/* Backdrop with spotlight (SVG mask) */}
      <svg
        width={vw}
        height={vh}
        className="absolute inset-0"
        style={{ pointerEvents: 'auto' }}
        onClick={(e) => {
          if (e.target === e.currentTarget) handleFinish();
        }}
      >
        <defs>
          <mask id="hud-tutorial-mask">
            <rect x={0} y={0} width={vw} height={vh} fill="white" />
            {showSpotlight && targetRect && (
              <rect
                x={targetRect.x - pad}
                y={targetRect.y - pad}
                width={targetRect.w + pad * 2}
                height={targetRect.h + pad * 2}
                rx={10}
                ry={10}
                fill="black"
              />
            )}
          </mask>
        </defs>
        <rect
          x={0}
          y={0}
          width={vw}
          height={vh}
          fill="rgba(0, 0, 0, 0.68)"
          mask="url(#hud-tutorial-mask)"
          style={{
            transition: 'fill 0.2s ease',
          }}
        />
        {/* Spotlight outline + pulse */}
        {showSpotlight && targetRect && (
          <>
            <rect
              x={targetRect.x - pad}
              y={targetRect.y - pad}
              width={targetRect.w + pad * 2}
              height={targetRect.h + pad * 2}
              rx={10}
              ry={10}
              fill="none"
              stroke={primaryColor}
              strokeWidth={1.5}
              opacity={0.9}
              style={{
                filter: `drop-shadow(0 0 8px ${primaryColor})`,
                transition: 'all 0.25s cubic-bezier(0.4, 0, 0.2, 1)',
              }}
            />
            {step.advanceOnClick && (
              <rect
                x={targetRect.x - pad}
                y={targetRect.y - pad}
                width={targetRect.w + pad * 2}
                height={targetRect.h + pad * 2}
                rx={10}
                ry={10}
                fill="none"
                stroke={primaryColor}
                strokeWidth={2}
                opacity={0.5}
                style={{
                  animation: 'hud-tutorial-pulse 1.6s ease-in-out infinite',
                  transformOrigin: `${targetRect.x + targetRect.w / 2}px ${targetRect.y + targetRect.h / 2}px`,
                }}
              />
            )}
          </>
        )}
      </svg>

      {/* Coachmark */}
      {coachRect && (
        <div
          ref={coachRef}
          className="absolute"
          style={{
            left: coachRect.left,
            top: coachRect.top,
            width: COACHMARK_W,
            pointerEvents: 'auto',
            transition: 'left 0.25s cubic-bezier(0.4, 0, 0.2, 1), top 0.25s cubic-bezier(0.4, 0, 0.2, 1)',
          }}
        >
          <div
            style={{
              backgroundColor: 'var(--bg-primary-full, rgba(12, 12, 12, 1))',
              border: '1px solid var(--border-color, rgba(255, 255, 255, 0.07))',
              borderRadius: 'var(--radius, 12px)',
              boxShadow: 'var(--shadow, 0 8px 32px rgba(0, 0, 0, 0.55))',
              overflow: 'hidden',
              fontFamily: 'var(--font-base, Outfit, sans-serif)',
            }}
          >
            {/* Progress hairline */}
            <div style={{ height: 2, backgroundColor: 'var(--bg-tertiary, rgba(255,255,255,0.08))' }}>
              <div
                style={{
                  width: `${((currentStep + 1) / total) * 100}%`,
                  height: '100%',
                  backgroundColor: primaryColor,
                  transition: 'width 0.4s ease',
                }}
              />
            </div>

            <div style={{ padding: '18px 20px 16px' }}>
              {/* Step counter + close */}
              <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 10 }}>
                <span style={{
                  fontSize: 11,
                  letterSpacing: '0.8px',
                  textTransform: 'uppercase',
                  color: 'var(--text-tertiary)',
                  fontWeight: 500,
                }}>
                  Étape {currentStep + 1} sur {total}
                </span>
                <button
                  onClick={handleFinish}
                  style={{
                    background: 'transparent',
                    border: 'none',
                    color: 'var(--text-tertiary)',
                    cursor: 'pointer',
                    padding: 4,
                    borderRadius: 6,
                    display: 'inline-flex',
                  }}
                  title="Quitter le tutoriel"
                >
                  <X size={14} />
                </button>
              </div>

              {/* Title */}
              <h3 style={{
                fontSize: 17,
                fontWeight: 700,
                color: 'var(--text-primary)',
                margin: 0,
                marginBottom: 6,
                lineHeight: 1.3,
                letterSpacing: '-0.2px',
              }}>
                {step.title}
              </h3>

              {/* Body */}
              <p style={{
                fontSize: 13,
                color: 'var(--text-secondary)',
                margin: 0,
                lineHeight: 1.55,
              }}>
                {step.body}
              </p>

              {/* Hint pill (action requise) */}
              {step.hint && (
                <div style={{
                  marginTop: 12,
                  padding: '8px 12px',
                  borderRadius: 8,
                  backgroundColor: 'var(--bg-secondary, rgba(255,255,255,0.04))',
                  display: 'flex',
                  alignItems: 'center',
                  gap: 8,
                }}>
                  <span style={{
                    width: 6, height: 6, borderRadius: '50%',
                    backgroundColor: primaryColor,
                    boxShadow: `0 0 6px ${primaryColor}`,
                    animation: 'hud-tutorial-dot 1.4s ease-in-out infinite',
                  }} />
                  <span style={{ fontSize: 12, color: 'var(--text-secondary)', fontWeight: 500 }}>
                    {step.hint}
                  </span>
                </div>
              )}
            </div>

            {/* Footer */}
            <div style={{
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'space-between',
              gap: 8,
              padding: '12px 20px 14px',
              borderTop: '1px solid var(--border-color, rgba(255,255,255,0.07))',
            }}>
              <button
                onClick={goPrev}
                disabled={currentStep === 0}
                style={{
                  background: 'transparent',
                  border: 'none',
                  color: currentStep === 0 ? 'var(--text-tertiary)' : 'var(--text-secondary)',
                  cursor: currentStep === 0 ? 'default' : 'pointer',
                  fontSize: 13,
                  padding: '6px 8px',
                  borderRadius: 6,
                  display: 'inline-flex',
                  alignItems: 'center',
                  gap: 4,
                  opacity: currentStep === 0 ? 0.4 : 1,
                  fontFamily: 'inherit',
                }}
              >
                <ChevronLeft size={14} />
                Retour
              </button>

              <button
                onClick={goNext}
                style={{
                  backgroundColor: primaryColor,
                  color: '#fff',
                  border: 'none',
                  cursor: 'pointer',
                  fontSize: 13,
                  fontWeight: 600,
                  padding: '8px 16px',
                  borderRadius: 8,
                  display: 'inline-flex',
                  alignItems: 'center',
                  gap: 6,
                  fontFamily: 'inherit',
                  letterSpacing: '0.1px',
                }}
              >
                {isLast ? 'Terminer' : 'Suivant'}
                {!isLast && <ChevronRight size={14} />}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Keyframes */}
      <style>{`
        @keyframes hud-tutorial-pulse {
          0%, 100% { opacity: 0.5; transform: scale(1); }
          50%      { opacity: 0; transform: scale(1.04); }
        }
        @keyframes hud-tutorial-dot {
          0%, 100% { opacity: 1; transform: scale(1); }
          50%      { opacity: 0.5; transform: scale(0.85); }
        }
      `}</style>
    </div>
  );
};

function clamp(v: number, min: number, max: number): number {
  return Math.max(min, Math.min(max, v));
}

// Welcome prompt (shown on first open)
export const TutorialPrompt: React.FC<{
  isOpen: boolean;
  onStartTutorial: () => void;
  onSkip: () => void;
  primaryColor: string;
}> = ({ isOpen, onStartTutorial, onSkip, primaryColor }) => {
  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-[10005] flex items-center justify-center" style={{ backgroundColor: 'rgba(0, 0, 0, 0.55)' }}>
      <div
        onClick={onSkip}
        className="absolute inset-0"
      />
      <div
        className="relative"
        style={{
          width: 440,
          backgroundColor: 'var(--bg-primary-full, rgba(12, 12, 12, 1))',
          border: '1px solid var(--border-color, rgba(255, 255, 255, 0.07))',
          borderRadius: 'var(--radius, 12px)',
          boxShadow: 'var(--shadow, 0 8px 32px rgba(0, 0, 0, 0.55))',
          fontFamily: 'var(--font-base, Outfit, sans-serif)',
          overflow: 'hidden',
        }}
      >
        <div style={{ height: 2, backgroundColor: primaryColor }} />

        <div style={{ padding: '28px 28px 24px' }}>
          <div style={{ display: 'flex', alignItems: 'baseline', gap: 10, marginBottom: 6 }}>
            <span style={{
              fontSize: 11,
              letterSpacing: '1.2px',
              textTransform: 'uppercase',
              color: 'var(--text-tertiary)',
              fontWeight: 500,
            }}>
              Première visite
            </span>
            <span style={{
              width: 4, height: 4, borderRadius: '50%',
              backgroundColor: primaryColor,
              alignSelf: 'center',
            }} />
            <span style={{
              fontSize: 11,
              letterSpacing: '0.5px',
              color: 'var(--text-tertiary)',
            }}>
              ~1 min
            </span>
          </div>

          <h2 style={{
            fontSize: 24,
            fontWeight: 700,
            color: 'var(--text-primary)',
            margin: 0,
            marginBottom: 10,
            letterSpacing: '-0.4px',
            lineHeight: 1.2,
          }}>
            Apprends à personnaliser ton HUD
          </h2>

          <p style={{
            fontSize: 13.5,
            color: 'var(--text-secondary)',
            margin: 0,
            marginBottom: 22,
            lineHeight: 1.55,
            maxWidth: 360,
          }}>
            On te guide à travers les bases : activer un module, le déplacer, le configurer, et sauvegarder.
          </p>

          <div style={{ display: 'flex', gap: 8 }}>
            <button
              onClick={onStartTutorial}
              style={{
                flex: 1,
                backgroundColor: primaryColor,
                color: '#fff',
                border: 'none',
                cursor: 'pointer',
                fontSize: 14,
                fontWeight: 600,
                padding: '12px 18px',
                borderRadius: 8,
                fontFamily: 'inherit',
                letterSpacing: '0.1px',
              }}
            >
              Lancer le tutoriel
            </button>
            <button
              onClick={onSkip}
              style={{
                backgroundColor: 'transparent',
                color: 'var(--text-secondary)',
                border: 'none',
                cursor: 'pointer',
                fontSize: 13,
                padding: '12px 14px',
                borderRadius: 8,
                fontFamily: 'inherit',
              }}
            >
              Passer
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default HUDTutorial;
