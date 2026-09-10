/**
 * Convert a hex color (#RRGGBB) + opacity percent (0-100) to an rgba string.
 */
export function hexToRgba(hex: string, percent: number): string {
  const h = hex.replace('#', '');
  const r = parseInt(h.substring(0, 2), 16);
  const g = parseInt(h.substring(2, 4), 16);
  const b = parseInt(h.substring(4, 6), 16);
  return `rgba(${r}, ${g}, ${b}, ${(percent / 100).toFixed(2)})`;
}

/**
 * Mix a hex color with white at a given percentage.
 * percent=70 means 70% of the color + 30% white.
 */
export function hexMixWhite(hex: string, percent: number): string {
  const h = hex.replace('#', '');
  const r = parseInt(h.substring(0, 2), 16);
  const g = parseInt(h.substring(2, 4), 16);
  const b = parseInt(h.substring(4, 6), 16);
  const p = percent / 100;
  const mr = Math.round(r * p + 255 * (1 - p));
  const mg = Math.round(g * p + 255 * (1 - p));
  const mb = Math.round(b * p + 255 * (1 - p));
  return `rgb(${mr}, ${mg}, ${mb})`;
}

const OPACITY_STEPS = [4, 5, 6, 8, 10, 12, 15, 20, 25, 30, 40, 50, 60, 70];

/**
 * Generate CSS custom properties for an accent color with all opacity variants.
 *
 * @param prefix  CSS variable name, e.g. '--pm-accent'
 * @param hex     Hex color string, e.g. '#8b5cf6'
 * @returns       Record to spread into a style prop, e.g.
 *                { '--pm-accent': '#8b5cf6', '--pm-accent-10': 'rgba(139,92,246,0.10)', ... }
 */
export function generateAccentVars(prefix: string, hex: string): Record<string, string> {
  if (!hex || !hex.startsWith('#') || hex.length < 7) {
    hex = '#646464';
  }
  const vars: Record<string, string> = { [prefix]: hex };
  for (const step of OPACITY_STEPS) {
    vars[`${prefix}-${step}`] = hexToRgba(hex, step);
  }
  vars[`${prefix}-70w`] = hexMixWhite(hex, 70);
  return vars;
}
