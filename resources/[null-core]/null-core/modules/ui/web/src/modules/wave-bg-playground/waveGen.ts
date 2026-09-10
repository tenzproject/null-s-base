// Wave background generator (Illustrator "Blend Tool" approach).
//
// Each cluster is defined by TWO independent cubic-Bezier curves
// ("outer" + "inner") whose endpoints are anchored OFF-SCREEN or on the
// canvas edges. We then linearly interpolate every control point between
// the outer and inner curve to produce N intermediate sub-curves.
//
// This is the same technique as Illustrator's blend tool: the result is
// a flowing ribbon of parallel curves that span across the canvas, not
// a "fan" sharing a single origin.
//
// The cluster shapes are stored in NORMALIZED coords (0..1 of width/height).
// Off-screen anchors use values < 0 or > 1.

export type Corner = 'tr' | 'br' | 'bl' | 'tl';

// Cubic bezier in normalized space: [sx, sy, c1x, c1y, c2x, c2y, ex, ey]
export type CubicNorm = [number, number, number, number, number, number, number, number];

export interface WaveCluster {
  outer: CubicNorm;
  inner: CubicNorm;
  lines: number;
  rotation?: number; // unused for now (we already place per-corner)
}

export interface WaveBgParams {
  width: number;
  height: number;
  bgColor: string;
  accentColor: string;
  clusters: number;        // 1..4
  linesPerCluster: number; // density per cluster
  opacity: number;         // 0..1 (peak line opacity)
  strokeWidth: number;     // px
  fadeEdges: number;       // 0..1 — fade strength on the outer-most lines
  jitter: number;          // 0..1 — random variation per seed
  autoDensity: boolean;    // scale linesPerCluster with canvas size
  seed: number;
  vignette: boolean;
}

// Reference dimension used for auto-density (matches the "tablet" preset).
const DENSITY_REFERENCE = 1024;

// ----- PRNG / hashing -----
export function mulberry32(seed: number) {
  let a = seed >>> 0;
  return () => {
    a = (a + 0x6D2B79F5) >>> 0;
    let t = a;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

export function hashSize(width: number, height: number): number {
  let h = 0x811c9dc5;
  const data = `${Math.round(width)}x${Math.round(height)}`;
  for (let i = 0; i < data.length; i++) {
    h ^= data.charCodeAt(i);
    h = Math.imul(h, 0x01000193);
  }
  return h >>> 0;
}

// ----- Cluster templates (normalized coords) -----
// Designed so endpoints sit off-canvas (negative or >1) for clean entries/exits.
// outer = larger sweep, inner = shorter/tighter curve.
const TEMPLATES: Record<Corner, { outer: CubicNorm; inner: CubicNorm }> = {
  tr: {
    outer: [-0.10, -0.05, 0.20, 0.10, 0.65, 0.45, 1.10, 0.55],
    inner: [ 0.55, -0.05, 0.78, 0.00, 0.95, 0.10, 1.10, 0.20],
  },
  br: {
    outer: [ 0.35,  1.10, 0.65, 1.00, 0.95, 0.85, 1.10, 0.45],
    inner: [ 0.80,  1.10, 0.95, 1.05, 1.05, 0.95, 1.10, 0.80],
  },
  bl: {
    outer: [-0.10,  0.55, 0.05, 0.85, 0.35, 1.00, 0.65,  1.10],
    inner: [-0.10,  0.80, 0.00, 0.95, 0.10, 1.05, 0.20,  1.10],
  },
  tl: {
    outer: [-0.10,  0.45, 0.05, 0.20, 0.35, 0.05, 0.65, -0.10],
    inner: [-0.10,  0.20, 0.00, 0.10, 0.10, 0.00, 0.20, -0.10],
  },
};

function jitterCurve(c: CubicNorm, amount: number, rng: () => number): CubicNorm {
  // Only jitter the control points (indices 2,3,4,5) and a tiny bit the endpoints.
  const j = (i: number) => (rng() - 0.5) * 2 * amount * (i === 2 || i === 3 || i === 4 || i === 5 ? 0.12 : 0.04);
  return c.map((v, i) => v + j(i)) as CubicNorm;
}

export function buildClusters(p: WaveBgParams): WaveCluster[] {
  const rng = mulberry32(p.seed);
  // Fixed corner order: 1 cluster -> TL, 2 -> TL + BR, 3 -> + TR, 4 -> + BL.
  const corners: Corner[] = ['tl', 'br', 'tr', 'bl'];
  const N = Math.max(1, Math.min(p.clusters, 4));

  let lines = p.linesPerCluster;
  if (p.autoDensity) {
    const refSqrt = Math.sqrt(DENSITY_REFERENCE * DENSITY_REFERENCE);
    const curSqrt = Math.sqrt(p.width * p.height);
    lines = Math.max(3, Math.round(p.linesPerCluster * (curSqrt / refSqrt)));
  }

  const out: WaveCluster[] = [];
  for (let i = 0; i < N; i++) {
    const tpl = TEMPLATES[corners[i]];
    out.push({
      outer: jitterCurve(tpl.outer, p.jitter, rng),
      inner: jitterCurve(tpl.inner, p.jitter, rng),
      lines,
    });
  }
  return out;
}

// Linear interpolation between the 8-component cubic curves.
function lerpCurve(a: CubicNorm, b: CubicNorm, t: number): CubicNorm {
  const r = new Array(8) as number[];
  for (let i = 0; i < 8; i++) r[i] = a[i] + (b[i] - a[i]) * t;
  return r as CubicNorm;
}

// Smooth easing for opacity profile (peak at center, soft at edges).
function bell(t: number): number {
  // t in [0..1] -> 0..1..0
  const x = t * 2 - 1; // -1..1
  return Math.max(0, 1 - x * x);
}

export function renderClusterSVG(c: WaveCluster, p: WaveBgParams): string {
  const w = p.width;
  const h = p.height;
  const N = Math.max(2, c.lines);
  const paths: string[] = [];
  for (let i = 0; i < N; i++) {
    const t = i / (N - 1);
    const cur = lerpCurve(c.outer, c.inner, t);
    const sx = cur[0] * w;
    const sy = cur[1] * h;
    const c1x = cur[2] * w;
    const c1y = cur[3] * h;
    const c2x = cur[4] * w;
    const c2y = cur[5] * h;
    const ex = cur[6] * w;
    const ey = cur[7] * h;

    // Opacity profile: bell-shape centered at t=0.5, with edge fade.
    const fade = p.fadeEdges;
    const profile = bell(t) * (1 - fade) + (1 - Math.abs(t - 0.5) * 2) * fade;
    const op = (p.opacity * Math.max(0.06, profile)).toFixed(3);

    paths.push(
      `<path d="M ${sx.toFixed(2)} ${sy.toFixed(2)} C ${c1x.toFixed(2)} ${c1y.toFixed(2)}, ${c2x.toFixed(2)} ${c2y.toFixed(2)}, ${ex.toFixed(2)} ${ey.toFixed(2)}" stroke="${p.accentColor}" stroke-width="${p.strokeWidth}" fill="none" opacity="${op}" stroke-linecap="round" />`
    );
  }
  return `<g>${paths.join('')}</g>`;
}

export function renderWaveBgSVG(p: WaveBgParams): string {
  const clusters = buildClusters(p);
  const inner = clusters.map(c => renderClusterSVG(c, p)).join('');

  const defs = p.vignette
    ? `<defs><radialGradient id="vg" cx="50%" cy="50%" r="75%">
        <stop offset="55%" stop-color="rgb(0,0,0)" stop-opacity="0" />
        <stop offset="100%" stop-color="rgb(0,0,0)" stop-opacity="0.55" />
      </radialGradient></defs>`
    : '';
  const vignetteRect = p.vignette
    ? `<rect width="${p.width}" height="${p.height}" fill="url(#vg)" />`
    : '';

  return `<svg xmlns="http://www.w3.org/2000/svg" width="${p.width}" height="${p.height}" viewBox="0 0 ${p.width} ${p.height}">
${defs}
<rect width="${p.width}" height="${p.height}" fill="${p.bgColor}" />
${inner}
${vignetteRect}
</svg>`;
}
