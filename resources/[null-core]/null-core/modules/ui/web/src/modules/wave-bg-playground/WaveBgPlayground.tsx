import React, { useCallback, useEffect, useMemo, useState } from 'react';
import { X, Copy, Download, RefreshCw, Wand2 } from 'lucide-react';
import { hashSize, renderWaveBgSVG, WaveBgParams } from './waveGen';
import './WaveBgPlayground.css';

const GetParentResourceName = () => 'null-core';

interface Props {
  visible: boolean;
  onClose: () => void;
  primaryColor: string;
}

const DEFAULTS: WaveBgParams = {
  width: 1280,
  height: 800,
  bgColor: 'rgb(12, 12, 12)',
  accentColor: '#4e8bee',
  clusters: 2,
  linesPerCluster: 12,
  opacity: 0.5,
  strokeWidth: 2.6,
  fadeEdges: 1,
  jitter: 0.2,
  autoDensity: true,
  seed: hashSize(1280, 800),
  vignette: true,
};

const WaveBgPlayground: React.FC<Props> = ({ visible, onClose, primaryColor }) => {
  const [params, setParams] = useState<WaveBgParams>(() => ({
    ...DEFAULTS,
    accentColor: primaryColor || DEFAULTS.accentColor,
  }));
  const [autoSeed, setAutoSeed] = useState(true);

  useEffect(() => {
    if (autoSeed) {
      setParams(p => ({ ...p, seed: hashSize(p.width, p.height) }));
    }
  }, [params.width, params.height, autoSeed]);

  const svg = useMemo(() => renderWaveBgSVG(params), [params]);

  const update = useCallback(<K extends keyof WaveBgParams>(k: K, v: WaveBgParams[K]) => {
    setParams(p => ({ ...p, [k]: v }));
  }, []);

  const randomSeed = () => setParams(p => ({ ...p, seed: Math.floor(Math.random() * 0xffffffff) }));
  const resetFromSize = () => setParams(p => ({ ...p, seed: hashSize(p.width, p.height) }));

  const copySVG = () => {
    fetch(`https://${GetParentResourceName()}/copyToClipboard`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ text: svg }),
    }).catch(() => {});
    try { navigator.clipboard.writeText(svg); } catch {}
  };

  const downloadSVG = () => {
    const blob = new Blob([svg], { type: 'image/svg+xml' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `wave-bg-${params.width}x${params.height}-${params.seed}.svg`;
    a.click();
    URL.revokeObjectURL(url);
  };

  if (!visible) return null;

  return (
    <div className="wbg-overlay" style={{ ['--wbg-accent' as any]: params.accentColor }}>
      <div className="wbg-shell">
        <header className="wbg-header">
          <div>
            <h1>Wave Background Playground</h1>
            <p>Génère des fonds en lignes/waves SVG, déterministes par taille.</p>
          </div>
          <button className="wbg-close" onClick={onClose}><X size={18} /></button>
        </header>

        <div className="wbg-body">
          <aside className="wbg-controls">
            <Section title="Dimensions">
              <NumberRow label="Largeur" value={params.width} min={200} max={3840} step={10} onChange={v => update('width', v)} />
              <NumberRow label="Hauteur" value={params.height} min={200} max={3840} step={10} onChange={v => update('height', v)} />
              <Preset label="Tablet 1280×800" onClick={() => setParams(p => ({ ...p, width: 1280, height: 800 }))} />
              <Preset label="Phone 420×780" onClick={() => setParams(p => ({ ...p, width: 420, height: 780 }))} />
              <Preset label="HUD 600×400" onClick={() => setParams(p => ({ ...p, width: 600, height: 400 }))} />
            </Section>

            <Section title="Couleurs">
              <ColorRow label="Fond" value={params.bgColor} onChange={v => update('bgColor', v)} />
              <ColorRow label="Accent" value={params.accentColor} onChange={v => update('accentColor', v)} />
            </Section>

            <Section title="Composition">
              <SliderRow label="Clusters" value={params.clusters} min={1} max={4} step={1} onChange={v => update('clusters', v)} />
              <SliderRow label="Lignes / cluster" value={params.linesPerCluster} min={4} max={60} step={1} onChange={v => update('linesPerCluster', v)} />
              <ToggleRow label="Auto-densité (taille)" value={params.autoDensity} onChange={v => update('autoDensity', v)} />
              <SliderRow label="Jitter" value={params.jitter} min={0} max={1} step={0.01} onChange={v => update('jitter', v)} />
            </Section>

            <Section title="Style des traits">
              <SliderRow label="Opacité" value={params.opacity} min={0.05} max={1} step={0.01} onChange={v => update('opacity', v)} />
              <SliderRow label="Épaisseur" value={params.strokeWidth} min={0.3} max={3} step={0.1} onChange={v => update('strokeWidth', v)} />
              <SliderRow label="Fade bords" value={params.fadeEdges} min={0} max={1} step={0.01} onChange={v => update('fadeEdges', v)} />
              <ToggleRow label="Vignette" value={params.vignette} onChange={v => update('vignette', v)} />
            </Section>

            <Section title="Seed">
              <ToggleRow label="Auto depuis la taille" value={autoSeed} onChange={setAutoSeed} />
              <NumberRow label="Seed" value={params.seed} min={0} max={0xffffffff} step={1} onChange={v => { setAutoSeed(false); update('seed', v >>> 0); }} />
              <div className="wbg-row-actions">
                <button className="wbg-btn" onClick={() => { setAutoSeed(false); randomSeed(); }}><RefreshCw size={13} /> Aléatoire</button>
                <button className="wbg-btn" onClick={() => { setAutoSeed(true); resetFromSize(); }}><Wand2 size={13} /> Depuis taille</button>
              </div>
            </Section>

            <div className="wbg-export">
              <button className="wbg-btn wbg-btn--primary" onClick={copySVG}><Copy size={14} /> Copier SVG</button>
              <button className="wbg-btn" onClick={downloadSVG}><Download size={14} /> Télécharger</button>
            </div>
          </aside>

          <main className="wbg-stage">
            <div className="wbg-stage-meta">
              <span>{params.width} × {params.height}</span>
              <span className="wbg-dot" />
              <span>seed {params.seed.toString(16)}</span>
            </div>
            <div className="wbg-canvas-wrap">
              <div
                className="wbg-canvas"
                style={{
                  width: params.width,
                  height: params.height,
                  maxWidth: '100%',
                  maxHeight: '100%',
                }}
                dangerouslySetInnerHTML={{ __html: svg }}
              />
            </div>
          </main>
        </div>
      </div>
    </div>
  );
};

const Section: React.FC<{ title: string; children: React.ReactNode }> = ({ title, children }) => (
  <div className="wbg-section">
    <h3>{title}</h3>
    <div className="wbg-section-body">{children}</div>
  </div>
);

const SliderRow: React.FC<{ label: string; value: number; min: number; max: number; step: number; onChange: (v: number) => void }> = ({ label, value, min, max, step, onChange }) => (
  <label className="wbg-row">
    <span className="wbg-row-label">{label}</span>
    <input type="range" min={min} max={max} step={step} value={value} onChange={e => onChange(Number(e.target.value))} />
    <span className="wbg-row-value">{Number.isInteger(step) ? value : Number(value).toFixed(2)}</span>
  </label>
);

const NumberRow: React.FC<{ label: string; value: number; min: number; max: number; step: number; onChange: (v: number) => void }> = ({ label, value, min, max, step, onChange }) => (
  <label className="wbg-row">
    <span className="wbg-row-label">{label}</span>
    <input type="number" min={min} max={max} step={step} value={value} onChange={e => onChange(Number(e.target.value))} />
  </label>
);

const ColorRow: React.FC<{ label: string; value: string; onChange: (v: string) => void }> = ({ label, value, onChange }) => (
  <label className="wbg-row">
    <span className="wbg-row-label">{label}</span>
    <input type="color" value={value} onChange={e => onChange(e.target.value)} />
    <input type="text" className="wbg-text" value={value} onChange={e => onChange(e.target.value)} />
  </label>
);

const ToggleRow: React.FC<{ label: string; value: boolean; onChange: (v: boolean) => void }> = ({ label, value, onChange }) => (
  <label className="wbg-row wbg-row--toggle">
    <span className="wbg-row-label">{label}</span>
    <button
      type="button"
      className={`wbg-toggle ${value ? 'is-on' : ''}`}
      onClick={() => onChange(!value)}
      aria-pressed={value}
    >
      <span className="wbg-toggle-knob" />
    </button>
  </label>
);

const Preset: React.FC<{ label: string; onClick: () => void }> = ({ label, onClick }) => (
  <button className="wbg-preset" onClick={onClick}>{label}</button>
);

export default WaveBgPlayground;
