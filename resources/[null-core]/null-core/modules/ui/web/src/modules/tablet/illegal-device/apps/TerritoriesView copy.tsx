import React, { useState, useEffect, useCallback, useMemo, useRef } from 'react';
import { Territory, TerritoriesPayload } from '../types';

const Res = () => 'null-core';
const post = <T = any>(event: string, body: any = {}): Promise<T> =>
  fetch(`https://${Res()}/${event}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  }).then(r => r.json()).catch(() => ({} as any));

const MAP_BOUNDS = {
  worldMinX: -5662, worldMaxX: 6695,
  worldMinY: -4040, worldMaxY: 8447,
};
const MAP_W = MAP_BOUNDS.worldMaxX - MAP_BOUNDS.worldMinX;
const MAP_H = MAP_BOUNDS.worldMaxY - MAP_BOUNDS.worldMinY;
const worldToMap = (x: number, y: number) => ({
  u: (x - MAP_BOUNDS.worldMinX) / MAP_W,
  v: (MAP_BOUNDS.worldMaxY - y) / MAP_H,
});

const MAP_IMAGE_URL = 'nui://null-cache/images/statellite-named.jpg';

const ZOOM_MIN = 1;
const ZOOM_MAX = 5;
const INITIAL_ZOOM = 1.8;

const TerritoriesView: React.FC = () => {
  const [data, setData] = useState<TerritoriesPayload | null>(null);
  const [loading, setLoading] = useState(true);
  const [imgLoaded, setImgLoaded] = useState(false);
  const [hovered, setHovered] = useState<Territory | null>(null);

  const wrapRef = useRef<HTMLDivElement>(null);
  const [zoom, setZoom] = useState(INITIAL_ZOOM);
  const [pan, setPan] = useState({ x: 0, y: 0 });
  const [drag, setDrag] = useState<{ x: number; y: number; px: number; py: number } | null>(null);
  const [canvasSize, setCanvasSize] = useState({ w: 0, h: 0 });
  const [imgAspect, setImgAspect] = useState(1);
  const [imgNaturalSize, setImgNaturalSize] = useState<{ w: number; h: number } | null>(null);

  useEffect(() => {
    (async () => {
      const r = await post<TerritoriesPayload>('illegalDevice:territories:getData');
      setData(r || { territories: [] });
      setLoading(false);
    })();
  }, []);

  useEffect(() => {
    const el = wrapRef.current;
    if (!el) return;
    const ro = new ResizeObserver(() => setCanvasSize({ w: el.clientWidth, h: el.clientHeight }));
    ro.observe(el);
    setCanvasSize({ w: el.clientWidth, h: el.clientHeight });
    return () => ro.disconnect();
  }, []);

  const stageSize = useMemo(() => {
    if (canvasSize.w === 0 || canvasSize.h === 0) return { w: 0, h: 0 };

    if (imgNaturalSize) {
      const MAX_STAGE = 6000;
      let w = imgNaturalSize.w;
      let h = imgNaturalSize.h;
      const maxDim = Math.max(w, h);
      if (maxDim > MAX_STAGE) {
        const ratio = MAX_STAGE / maxDim;
        w *= ratio;
        h *= ratio;
      }
      return { w, h };
    }

    const ca = canvasSize.w / canvasSize.h;
    if (ca > imgAspect) return { w: canvasSize.h * imgAspect, h: canvasSize.h };
    return { w: canvasSize.w, h: canvasSize.w / imgAspect };
  }, [canvasSize, imgAspect, imgNaturalSize]);

  const clamp = useCallback((p: { x: number; y: number }, z: number) => {
    if (stageSize.w === 0) return { x: 0, y: 0 };
    const maxX = Math.max(0, (stageSize.w * z - canvasSize.w) / 2);
    const maxY = Math.max(0, (stageSize.h * z - canvasSize.h) / 2);
    return {
      x: Math.max(-maxX, Math.min(maxX, p.x)),
      y: Math.max(-maxY, Math.min(maxY, p.y)),
    };
  }, [stageSize, canvasSize]);

  useEffect(() => { setPan(p => clamp(p, zoom)); }, [zoom, clamp]);

  const onWheel = (e: React.WheelEvent) => {
    const factor = e.deltaY < 0 ? 1.15 : 1 / 1.15;
    setZoom(z => Math.max(ZOOM_MIN, Math.min(ZOOM_MAX, z * factor)));
  };
  const onMouseDown = (e: React.MouseEvent) => {
    if (e.button !== 0) return;
    setDrag({ x: e.clientX, y: e.clientY, px: pan.x, py: pan.y });
  };
  const onMouseMove = (e: React.MouseEvent) => {
    if (!drag) return;
    setPan(clamp({ x: drag.px + (e.clientX - drag.x), y: drag.py + (e.clientY - drag.y) }, zoom));
  };
  const stopDrag = () => setDrag(null);

  const reset = () => { setZoom(INITIAL_ZOOM); setPan({ x: 0, y: 0 }); };
  const zoomIn = () => setZoom(z => Math.min(ZOOM_MAX, z * 1.25));
  const zoomOut = () => setZoom(z => Math.max(ZOOM_MIN, z / 1.25));

  const territories = data?.territories || [];
  const owned = useMemo(() => territories.filter(t => t.isOwned).length, [territories]);

  return (
    <div className="idev-crew-section idev-terr">
      <div className="idev-terr-bar">
        <div className="idev-terr-meta">
          <strong>{owned}</strong>
          <span>territoire{owned > 1 ? 's' : ''} contrôlé{owned > 1 ? 's' : ''}</span>
          <span className="idev-terr-sep" />
          <strong>{territories.length}</strong>
          <span>sur la carte</span>
        </div>
        <div className="idev-terr-controls">
          <button onClick={zoomOut} title="Dézoomer">−</button>
          <button onClick={reset} title="Recentrer">Reset</button>
          <button onClick={zoomIn} title="Zoomer">+</button>
        </div>
      </div>

      <div className="idev-tmap-wrap" ref={wrapRef}>
        {loading && <div className="idev-empty">Chargement de la carte…</div>}

        {!loading && !imgLoaded && (
          <div className="idev-tmap-skeleton">
            <div className="idev-tmap-skeleton-pulse" />
            <span>Chargement de la carte…</span>
          </div>
        )}

        {!loading && (
          <div
            className={`idev-tmap-canvas${drag ? ' is-dragging' : ''}${imgLoaded ? '' : ' is-hidden'}`}
            onWheel={onWheel}
            onMouseDown={onMouseDown}
            onMouseMove={onMouseMove}
            onMouseUp={stopDrag}
            onMouseLeave={stopDrag}
          >
            <div
              className="idev-tmap-stage"
              style={{
                width: stageSize.w ? `${stageSize.w}px` : '100%',
                height: stageSize.h ? `${stageSize.h}px` : '100%',
                transform: `translate3d(${pan.x}px, ${pan.y}px, 0) scale(${zoom})`,
              }}
            >
              <img
                className="idev-tmap-bg"
                src={MAP_IMAGE_URL}
                alt="Carte"
                draggable={false}
                onLoad={(e) => {
                  const t = e.target as HTMLImageElement;
                  if (t.naturalWidth && t.naturalHeight) {
                    setImgNaturalSize({ w: t.naturalWidth, h: t.naturalHeight });
                    setImgAspect(t.naturalWidth / t.naturalHeight);
                  }
                  setImgLoaded(true);
                }}
              />
              <div className="idev-tmap-dark" />

              <svg
                className="idev-tmap-svg"
                viewBox={`0 0 100 ${imgAspect ? 100 / imgAspect : 100}`}
                preserveAspectRatio="none"
              >
                {territories.map(t => {
                  const poly = (t.territoryPoints && t.territoryPoints.length >= 3) ? t.territoryPoints : t.points;
                  if (!poly || poly.length < 3) return null;
                  const pts = poly.map(p => {
                    const { u, v } = worldToMap(p.x, p.y);
                    return `${(u * 100).toFixed(3)},${(v * 100).toFixed(3)}`;
                  }).join(' ');
                  const isHovered = hovered?.id === t.id;
                  const color = t.color || '#9aa0a6';
                  return (
                    <polygon
                      key={t.id}
                      points={pts}
                      fill={color}
                      fillOpacity={t.isOwned ? 0.42 : (isHovered ? 0.40 : 0.22)}
                      stroke={color}
                      strokeOpacity={t.isOwned ? 0.95 : (isHovered ? 0.85 : 0.55)}
                      strokeWidth={t.isOwned ? 0.18 : 0.12}
                      vectorEffect="non-scaling-stroke"
                      style={{ pointerEvents: 'auto', cursor: 'pointer' }}
                      onMouseEnter={() => setHovered(t)}
                      onMouseLeave={() => setHovered(prev => prev?.id === t.id ? null : prev)}
                    />
                  );
                })}
              </svg>
            </div>

            {hovered && (
              <div className="idev-tmap-tip">
                <div className="idev-tmap-tip-head">
                  <span
                    className="idev-tmap-tip-dot"
                    style={{ background: hovered.color || '#9aa0a6' }}
                  />
                  <strong>{hovered.name}</strong>
                </div>
                <div className="idev-tmap-tip-row">
                  <span>Contrôle</span>
                  <span>{hovered.ownerLabel || '— Libre —'}</span>
                </div>
                {(hovered.ownerCount ?? 0) > 0 && (
                  <div className="idev-tmap-tip-row">
                    <span>Points contrôleur</span>
                    <span>{hovered.ownerCount}</span>
                  </div>
                )}
                {(hovered.myPoints ?? 0) > 0 && !hovered.isOwned && (
                  <div className="idev-tmap-tip-row">
                    <span>Vos points</span>
                    <span>{hovered.myPoints}</span>
                  </div>
                )}
                {hovered.isOwned && <div className="idev-tmap-tip-badge">Territoire sécurisé</div>}
              </div>
            )}
          </div>
        )}
      </div>

      <div className="idev-tmap-legend">
        <div><span className="idev-tmap-swatch is-mine" /> Sous votre contrôle</div>
        <div><span className="idev-tmap-swatch is-other" /> Contrôlé par un rival</div>
        <div><span className="idev-tmap-swatch is-free" /> Libre</div>
      </div>
    </div>
  );
};

export default TerritoriesView;
