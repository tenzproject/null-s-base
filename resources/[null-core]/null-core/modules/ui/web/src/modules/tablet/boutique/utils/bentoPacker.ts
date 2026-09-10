import { BoutiqueCardSize, RarityLevel } from '../types';

const COLS = 6;

export const SIZE_TO_CELLS: Record<BoutiqueCardSize, number> = {
  featured: 8,
  large: 4,
  tall: 4,
  normal: 2,
};

export const RARITY_NATURAL_CELLS: Record<RarityLevel, number> = {
  ultimate: 8,
  legendary: 4,
  epic: 4,
  rare: 2,
  common: 2,
};

export interface PlacedItem<T> {
  item: T;
  cells: number;
  w: number;
  h: number;
  col: number;
  row: number;
  size: BoutiqueCardSize;
}

export interface PackResult<T> {
  placed: PlacedItem<T>[];
  rows: number;
  cols: number;
}

function shapeOptions(cells: number): Array<{ w: number; h: number }> {
  if (cells >= 12) return [{ w: 6, h: 2 }, { w: 4, h: 2 }];
  if (cells >= 8) return [{ w: 4, h: 2 }, { w: 6, h: 2 }];
  if (cells === 6) return [{ w: 6, h: 1 }, { w: 3, h: 2 }];
  if (cells === 4) return [{ w: 4, h: 1 }, { w: 2, h: 2 }];
  if (cells === 3) return [{ w: 3, h: 1 }];
  if (cells === 2) return [{ w: 2, h: 1 }];
  if (cells === 1) return [{ w: 1, h: 1 }];
  return [{ w: 2, h: 1 }];
}

function sizeClassFor(w: number, h: number): BoutiqueCardSize {
  if (w >= 4 && h >= 2) return 'featured';
  if (w >= 4) return 'large';
  if (h >= 2) return 'tall';
  return 'normal';
}

/**
 * 2D bento packer.
 * - Items are described by a number of cells (e.g. 8, 4, 2).
 * - Grid is 6 columns wide, rows are added as needed.
 * - Row direction alternates: row 0 LTR, row 1 RTL, row 2 LTR, ...
 *   This guarantees the first (most featured) item of row 0 is left-aligned,
 *   while subsequent rows mirror to break monotony.
 * - For each item we try its possible shapes (e.g. 4×1 or 2×2 for cells=4)
 *   and pick the placement on the topmost row, then preference order.
 * - Holes in the last row are filled by widening the trailing item.
 */
export function packBento<T>(
  items: T[],
  getCells: (item: T) => number
): PackResult<T> {
  const grid: boolean[][] = [];
  const placed: PlacedItem<T>[] = [];

  const ensureRow = (r: number) => {
    while (grid.length <= r) grid.push(new Array(COLS).fill(false));
  };

  const isFree = (row: number, col: number, w: number, h: number): boolean => {
    if (col < 0 || col + w > COLS || row < 0) return false;
    for (let r = row; r < row + h; r++) {
      ensureRow(r);
      for (let c = col; c < col + w; c++) {
        if (grid[r][c]) return false;
      }
    }
    return true;
  };

  const occupy = (row: number, col: number, w: number, h: number) => {
    for (let r = row; r < row + h; r++) {
      ensureRow(r);
      for (let c = col; c < col + w; c++) grid[r][c] = true;
    }
  };

  const findFirstFreeRow = (): number => {
    for (let r = 0; r < grid.length; r++) {
      if (grid[r].some(v => !v)) return r;
    }
    return grid.length;
  };

  for (const item of items) {
    const rawCells = getCells(item);
    const cells = Math.max(1, Math.min(12, rawCells || 2));
    const shapes = shapeOptions(cells);

    type Cand = { w: number; h: number; col: number; row: number; pref: number };
    const candidates: Cand[] = [];
    const startRow = findFirstFreeRow();

    for (let pi = 0; pi < shapes.length; pi++) {
      const { w, h } = shapes[pi];
      let found = false;
      for (let row = startRow; row < startRow + 30 && !found; row++) {
        const ltr = row % 2 === 0;
        const colCount = COLS - w + 1;
        for (let i = 0; i < colCount; i++) {
          const col = ltr ? i : COLS - w - i;
          if (isFree(row, col, w, h)) {
            candidates.push({ w, h, col, row, pref: pi });
            found = true;
            break;
          }
        }
      }
    }

    if (candidates.length === 0) continue;
    candidates.sort((a, b) => a.row - b.row || a.pref - b.pref);
    const best = candidates[0];

    occupy(best.row, best.col, best.w, best.h);
    placed.push({
      item,
      cells,
      w: best.w,
      h: best.h,
      col: best.col,
      row: best.row,
      size: sizeClassFor(best.w, best.h),
    });
  }

  // Fill last-row holes by widening the trailing item along row direction.
  if (grid.length > 0) {
    const lastRow = grid.length - 1;
    const ltr = lastRow % 2 === 0;
    const onLastRow = placed.filter(p => p.row + p.h - 1 === lastRow);
    if (onLastRow.length > 0) {
      let holeStart = -1;
      let holeEnd = -1;
      for (let c = 0; c < COLS; c++) {
        if (!grid[lastRow][c]) {
          if (holeStart === -1) holeStart = c;
          holeEnd = c;
        }
      }
      if (holeStart !== -1 && holeEnd - holeStart + 1 < COLS) {
        const tail = ltr
          ? onLastRow.reduce((a, b) => (a.col + a.w >= b.col + b.w ? a : b))
          : onLastRow.reduce((a, b) => (a.col <= b.col ? a : b));

        if (ltr && tail.col + tail.w === holeStart) {
          tail.w = holeEnd - tail.col + 1;
          for (let c = holeStart; c <= holeEnd; c++) grid[lastRow][c] = true;
          tail.size = sizeClassFor(tail.w, tail.h);
        } else if (!ltr && holeEnd + 1 === tail.col) {
          tail.w = tail.col + tail.w - holeStart;
          tail.col = holeStart;
          for (let c = holeStart; c <= holeEnd; c++) grid[lastRow][c] = true;
          tail.size = sizeClassFor(tail.w, tail.h);
        }
      }
    }
  }

  return { placed, rows: Math.max(1, grid.length), cols: COLS };
}
