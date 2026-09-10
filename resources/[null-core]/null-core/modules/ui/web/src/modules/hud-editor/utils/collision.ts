import { Rect, Position } from '../types';

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
 * Calcule la nouvelle position d'un module pour éviter la collision
 * avec un effet de "poussée"
 */
export const resolveCollision = (
  movingRect: Rect,
  staticRect: Rect,
  direction: 'horizontal' | 'vertical' | 'auto' = 'auto'
): Position => {
  const overlapX = Math.min(
    movingRect.x + movingRect.width - staticRect.x,
    staticRect.x + staticRect.width - movingRect.x
  );
  const overlapY = Math.min(
    movingRect.y + movingRect.height - staticRect.y,
    staticRect.y + staticRect.height - movingRect.y
  );

  let newX = staticRect.x;
  let newY = staticRect.y;

  if (direction === 'auto') {
    direction = overlapX < overlapY ? 'horizontal' : 'vertical';
  }

  if (direction === 'horizontal') {
    if (movingRect.x < staticRect.x) {
      newX = movingRect.x + movingRect.width + 1;
    } else {
      newX = movingRect.x - staticRect.width - 1;
    }
  } else {
    if (movingRect.y < staticRect.y) {
      newY = movingRect.y + movingRect.height + 1;
    } else {
      newY = movingRect.y - staticRect.height - 1;
    }
  }

  // Contraindre dans les limites de l'écran (0-100%)
  newX = Math.max(0, Math.min(100 - staticRect.width, newX));
  newY = Math.max(0, Math.min(100 - staticRect.height, newY));

  return { x: newX, y: newY };
};

/**
 * Résout toutes les collisions pour un ensemble de modules
 * Retourne un Map avec les nouvelles positions
 */
export const resolveAllCollisions = (
  modules: Map<string, { position: Position; size: { width: number; height: number }; enabled: boolean }>,
  movingModuleId: string
): Map<string, Position> => {
  const newPositions = new Map<string, Position>();
  const movingModule = modules.get(movingModuleId);
  
  if (!movingModule || !movingModule.enabled) return newPositions;

  const movingRect: Rect = {
    x: movingModule.position.x,
    y: movingModule.position.y,
    width: movingModule.size.width,
    height: movingModule.size.height,
  };

  // Vérifier les collisions avec tous les autres modules
  modules.forEach((module, moduleId) => {
    if (moduleId === movingModuleId || !module.enabled) return;

    const staticRect: Rect = {
      x: module.position.x,
      y: module.position.y,
      width: module.size.width,
      height: module.size.height,
    };

    if (checkCollision(movingRect, staticRect)) {
      const newPos = resolveCollision(movingRect, staticRect);
      newPositions.set(moduleId, newPos);
    }
  });

  return newPositions;
};
