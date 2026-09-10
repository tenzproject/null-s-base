import { Rect, Position } from '../types';
import { AnchorPoint } from '../HUDModulesConfig';

/**
 * Convert anchor-based position to top-left corner position
 */
const anchorToTopLeft = (position: Position, size: { width: number; height: number }, anchor: AnchorPoint): Position => {
  let x = position.x;
  let y = position.y;

  // Adjust X based on anchor
  if (anchor.includes('center') && !anchor.includes('left') && !anchor.includes('right')) {
    x = position.x - size.width / 2;
  } else if (anchor.includes('right')) {
    x = position.x - size.width;
  }

  // Adjust Y based on anchor
  if (anchor.includes('center') && !anchor.includes('top') && !anchor.includes('bottom')) {
    y = position.y - size.height / 2;
  } else if (anchor.includes('bottom')) {
    y = position.y - size.height;
  }

  return { x, y };
};

/**
 * Vérifie si deux rectangles se chevauchent
 */
export const checkCollision = (rect1: Rect, rect2: Rect): boolean => {
  return !(
    rect1.x + rect1.width <= rect2.x ||
    rect2.x + rect2.width <= rect1.x ||
    rect1.y + rect1.height <= rect2.y ||
    rect2.y + rect2.height <= rect1.y
  );
};

/**
 * Calcule la distance d'un module aux bords de l'écran
 */
const getDistanceToEdges = (rect: Rect): {
  left: number;
  right: number;
  top: number;
  bottom: number;
} => {
  return {
    left: rect.x,
    right: 100 - (rect.x + rect.width),
    top: rect.y,
    bottom: 100 - (rect.y + rect.height),
  };
};

/**
 * Trouve le bord le plus proche d'un module
 */
const getClosestEdge = (rect: Rect): 'left' | 'right' | 'top' | 'bottom' => {
  const distances = getDistanceToEdges(rect);
  const min = Math.min(distances.left, distances.right, distances.top, distances.bottom);
  
  if (min === distances.left) return 'left';
  if (min === distances.right) return 'right';
  if (min === distances.top) return 'top';
  return 'bottom';
};

/**
 * Résout une collision en poussant le module le plus proche d'un bord
 * Système optimisé : vérifie uniquement au drop, pas pendant le drag
 */
export const resolveCollisionOnDrop = (
  droppedRect: Rect,
  collidingRect: Rect,
  droppedModuleId: string,
  collidingModuleId: string
): { movedModuleId: string; newPosition: Position } | null => {
  if (!checkCollision(droppedRect, collidingRect)) {
    return null;
  }

  // Déterminer quel module est le plus proche d'un bord
  const droppedEdge = getClosestEdge(droppedRect);
  const collidingEdge = getClosestEdge(collidingRect);
  
  const droppedDistances = getDistanceToEdges(droppedRect);
  const collidingDistances = getDistanceToEdges(collidingRect);
  
  const droppedMinDistance = Math.min(
    droppedDistances.left,
    droppedDistances.right,
    droppedDistances.top,
    droppedDistances.bottom
  );
  
  const collidingMinDistance = Math.min(
    collidingDistances.left,
    collidingDistances.right,
    collidingDistances.top,
    collidingDistances.bottom
  );

  // Le module le plus proche d'un bord reste en place, l'autre est poussé
  let moduleToMove: 'dropped' | 'colliding';
  let staticRect: Rect;
  let movingRect: Rect;
  let movingModuleId: string;

  if (droppedMinDistance < collidingMinDistance) {
    // Le module déposé est plus proche d'un bord, on pousse l'autre
    moduleToMove = 'colliding';
    staticRect = droppedRect;
    movingRect = collidingRect;
    movingModuleId = collidingModuleId;
  } else {
    // Le module existant est plus proche d'un bord, on pousse le déposé
    moduleToMove = 'dropped';
    staticRect = collidingRect;
    movingRect = droppedRect;
    movingModuleId = droppedModuleId;
  }

  // Calculer la direction de poussée basée sur le chevauchement
  const overlapX = Math.min(
    movingRect.x + movingRect.width - staticRect.x,
    staticRect.x + staticRect.width - movingRect.x
  );
  const overlapY = Math.min(
    movingRect.y + movingRect.height - staticRect.y,
    staticRect.y + staticRect.height - movingRect.y
  );

  let newX = movingRect.x;
  let newY = movingRect.y;

  // Pousser dans la direction du plus petit chevauchement
  if (overlapX < overlapY) {
    // Pousser horizontalement
    if (movingRect.x < staticRect.x) {
      newX = staticRect.x - movingRect.width - 0.5;
    } else {
      newX = staticRect.x + staticRect.width + 0.5;
    }
  } else {
    // Pousser verticalement
    if (movingRect.y < staticRect.y) {
      newY = staticRect.y - movingRect.height - 0.5;
    } else {
      newY = staticRect.y + staticRect.height + 0.5;
    }
  }

  // Contraindre dans les limites de l'écran
  newX = Math.max(0, Math.min(100 - movingRect.width, newX));
  newY = Math.max(0, Math.min(100 - movingRect.height, newY));

  return {
    movedModuleId: movingModuleId,
    newPosition: { x: newX, y: newY },
  };
};

/**
 * Résout toutes les collisions après un drop
 * Retourne un Map avec les nouvelles positions des modules déplacés
 */
export const resolveAllCollisionsOnDrop = (
  modules: Map<string, { position: Position; size: { width: number; height: number }; enabled: boolean; anchor: AnchorPoint }>,
  droppedModuleId: string
): Map<string, Position> => {
  const newPositions = new Map<string, Position>();
  const droppedModule = modules.get(droppedModuleId);
  
  if (!droppedModule || !droppedModule.enabled) return newPositions;

  // Convert anchor position to top-left for collision detection
  const droppedTopLeft = anchorToTopLeft(droppedModule.position, droppedModule.size, droppedModule.anchor);
  const droppedRect: Rect = {
    x: droppedTopLeft.x,
    y: droppedTopLeft.y,
    width: droppedModule.size.width,
    height: droppedModule.size.height,
  };

  // Vérifier les collisions avec tous les autres modules
  modules.forEach((module, moduleId) => {
    if (moduleId === droppedModuleId || !module.enabled) return;

    // Convert anchor position to top-left for collision detection
    const collidingTopLeft = anchorToTopLeft(module.position, module.size, module.anchor);
    const collidingRect: Rect = {
      x: collidingTopLeft.x,
      y: collidingTopLeft.y,
      width: module.size.width,
      height: module.size.height,
    };

    const resolution = resolveCollisionOnDrop(
      droppedRect,
      collidingRect,
      droppedModuleId,
      moduleId
    );

    if (resolution) {
      newPositions.set(resolution.movedModuleId, resolution.newPosition);
      
      // Si c'est le module déposé qui a été déplacé, mettre à jour droppedRect pour les prochaines vérifications
      if (resolution.movedModuleId === droppedModuleId) {
        droppedRect.x = resolution.newPosition.x;
        droppedRect.y = resolution.newPosition.y;
      }
    }
  });

  return newPositions;
};
