/**
 * Convert a hex color to an RGB triplet string "r, g, b"
 */
export function hexToRgb(hex: string): string {
  const h = hex.replace('#', '');
  const r = parseInt(h.substring(0, 2), 16);
  const g = parseInt(h.substring(2, 4), 16);
  const b = parseInt(h.substring(4, 6), 16);
  return `${r}, ${g}, ${b}`;
}

/**
 * Convert a hex color to rgba with given opacity (0-1)
 */
export function hexToRgba(hex: string, opacity: number): string {
  return `rgba(${hexToRgb(hex)}, ${opacity})`;
}
