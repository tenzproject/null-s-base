/**
 * Anchor-based positioning utility
 * Converts anchor point + position to CSS transform
 */

export type AnchorPoint = 'top-left' | 'top-center' | 'top-right' | 'center-left' | 'center' | 'center-right' | 'bottom-left' | 'bottom-center' | 'bottom-right';

export interface AnchorConfig {
  anchor: AnchorPoint;
  position: { x: number; y: number }; // Percentage (0-100)
}

/**
 * Get CSS transform based on anchor point
 */
export function getAnchorTransform(anchor: AnchorPoint): string {
  switch (anchor) {
    case 'top-left':
      return 'translate(0%, 0%)';
    case 'top-center':
      return 'translate(-50%, 0%)';
    case 'top-right':
      return 'translate(-100%, 0%)';
    case 'center-left':
      return 'translate(0%, -50%)';
    case 'center':
      return 'translate(-50%, -50%)';
    case 'center-right':
      return 'translate(-100%, -50%)';
    case 'bottom-left':
      return 'translate(0%, -100%)';
    case 'bottom-center':
      return 'translate(-50%, -100%)';
    case 'bottom-right':
      return 'translate(-100%, -100%)';
    default:
      return 'translate(0%, 0%)';
  }
}

/**
 * Apply anchor-based positioning to an element
 */
export function applyAnchorPosition(config: AnchorConfig): React.CSSProperties {
  return {
    position: 'fixed',
    left: `${config.position.x}%`,
    top: `${config.position.y}%`,
    transform: getAnchorTransform(config.anchor),
  };
}

/**
 * Get anchor point name for display
 */
export function getAnchorName(anchor: AnchorPoint): string {
  const names: Record<AnchorPoint, string> = {
    'top-left': 'Haut Gauche',
    'top-center': 'Haut Centre',
    'top-right': 'Haut Droite',
    'center-left': 'Centre Gauche',
    'center': 'Centre',
    'center-right': 'Centre Droite',
    'bottom-left': 'Bas Gauche',
    'bottom-center': 'Bas Centre',
    'bottom-right': 'Bas Droite',
  };
  return names[anchor] || anchor;
}
