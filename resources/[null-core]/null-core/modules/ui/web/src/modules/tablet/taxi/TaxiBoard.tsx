import React, { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { cacheImg } from '@/shared/cacheVersion';
import { generateAccentVars } from '@/utils/accentColors';
import { ChevronRight, X, Lock, Car, Phone, Clock, MapPin, User, Check, Crosshair } from 'lucide-react';
import { TaxiBoardData, TaxiBoardProps, TaxiBrand, TaxiMissionUI, TaxiRequest } from './types';
import './Taxi.css';

const GetParentResourceName = () => 'null-core';

const MAP_BOUNDS = {
  worldMinX: -5662, worldMaxX: 6695,
  worldMinY: -4040, worldMaxY: 8447,
};
function worldToMap(x: number, y: number) {
  const u = (x - MAP_BOUNDS.worldMinX) / (MAP_BOUNDS.worldMaxX - MAP_BOUNDS.worldMinX);
  const v = (MAP_BOUNDS.worldMaxY - y) / (MAP_BOUNDS.worldMaxY - MAP_BOUNDS.worldMinY);
  return {
    u: Math.max(0, Math.min(1, u)),
    v: Math.max(0, Math.min(1, v)),
  };
}

const MAP_IMAGE_URL =
  'https://api.null.fr/media/carte-satellite-gta-51_1777204498061.jpg?v=1777204498157';

type SectionKey = 'missions' | 'requests';

const SECTIONS: Array<{ key: SectionKey; label: string }> = [
  { key: 'missions', label: 'Missions' },
  { key: 'requests', label: 'Demandes' },
];

function fmtElapsed(ts: number): string {
  const sec = Math.max(0, Math.floor((Date.now() - ts) / 1000));
  if (sec < 60) return `${sec}s`;
  const m = Math.floor(sec / 60);
  if (m < 60) return `${m}m`;
  return `${Math.floor(m / 60)}h${m % 60}`;
}

const TaxiBoard: React.FC<TaxiBoardProps> = ({ visible, onClose, primaryColor }) => {
  const [data, setData] = useState<TaxiBoardData | null>(null);
  const [hiding, setHiding] = useState(false);
  const [section, setSection] = useState<SectionKey>('missions');
  const [requests, setRequests] = useState<TaxiRequest[]>([]);
  const [selectedReqId, setSelectedReqId] = useState<string | null>(null);

  useEffect(() => {
    const handler = (event: MessageEvent) => {
      const msg = event.data || {};
      if (msg.action === 'taxiBoard:open' && msg.data) {
        setData(msg.data);
        setHiding(false);
        setSection('missions');
      } else if (msg.action === 'taxiBoard:close') {
        setData(null);
      } else if (msg.action === 'taxiBoard:update' && msg.data) {
        setData(msg.data);
      } else if (msg.action === 'taxiBoard:requests' && Array.isArray(msg.data)) {
        setRequests(msg.data as TaxiRequest[]);
      }
    };
    window.addEventListener('message', handler);
    return () => window.removeEventListener('message', handler);
  }, []);

  const handleClose = useCallback(() => {
    setHiding(true);
    setTimeout(() => {
      setHiding(false);
      setData(null);
      onClose();
      fetch(`https://${GetParentResourceName()}/taxi:close`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({}),
      }).catch(() => {});
    }, 280);
  }, [onClose]);

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => { if (e.key === 'Escape' && visible) handleClose(); };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [visible, handleClose]);

  useEffect(() => {
    if (!visible || !data || section !== 'requests') return;
    const fetchList = () => {
      fetch(`https://${GetParentResourceName()}/taxi:listRequests`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({}),
      })
        .then((r) => r.json().catch(() => null))
        .then((res) => { if (res && Array.isArray(res.requests)) setRequests(res.requests); })
        .catch(() => {});
    };
    fetchList();
    const id = window.setInterval(fetchList, 4000);
    return () => window.clearInterval(id);
  }, [visible, data, section]);

  const brand: TaxiBrand | undefined = data?.brand;
  const brandBg     = brand?.bgColor || '#0d0d0d';
  // La tablette doit garder la couleur principale de la BRAND en priorité
  // (même logique que le ped-shop : brand d'abord, sinon primary serveur).
  const accentColor = brand?.accentColor || primaryColor || '#f5b400';
  const brandLogo   = brand?.logo ? cacheImg(brand.logo) : null;

  const accentVars = useMemo(() => generateAccentVars('--txt-accent', accentColor), [accentColor]);
  const brandVars  = useMemo(() => ({
    '--txt-brand-bg':     brandBg,
    '--txt-brand-accent': accentColor,
  } as React.CSSProperties), [brandBg, accentColor]);

  if (!visible || !data) return null;

  const profile  = data.profile;
  const xpInRank = profile.rank ? profile.xp - (profile.rank.minXp || 0) : profile.xp;
  const xpToNext = profile.nextRank ? profile.nextRank.minXp - (profile.rank?.minXp || 0) : 1;
  const xpProgress = profile.nextRank ? Math.min(100, (xpInRank / xpToNext) * 100) : 100;
  const dailyProgress = Math.min(100, (profile.todayRides / Math.max(1, profile.dailyGoal)) * 100);

  const handleStartMission = (mission: TaxiMissionUI) => {
    if (!mission.unlocked) return;
    fetch(`https://${GetParentResourceName()}/taxi:startMission`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ key: mission.key }),
    }).catch(() => {});
    handleClose();
  };

  const handleAcceptRequest = (reqId: string) => {
    fetch(`https://${GetParentResourceName()}/taxi:acceptRequest`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ id: reqId }),
    }).catch(() => {});
    handleClose();
  };

  const selectedRequest = requests.find((r) => r.id === selectedReqId) || null;

  return (
    <div className={`txt-overlay ${hiding ? 'txt-hiding' : ''}`}>
      <div
        className="txt-container"
        style={{ ...accentVars, ...brandVars } as React.CSSProperties}
      >
        <aside className="txt-sidebar">
          {brand ? (
            <div
              className="txt-brand-hero"
              style={{ background: `linear-gradient(160deg, ${brandBg} 0%, ${brandBg}dd 60%, rgba(0,0,0,0.4) 100%)` }}
            >
              <div className="txt-brand-hero-shine" />
              <div className="txt-brand-hero-inner">
                {brandLogo ? (
                  <img
                    className="txt-brand-logo"
                    src={brandLogo}
                    alt={brand.name}
                    onError={(e) => { (e.target as HTMLImageElement).style.display = 'none'; }}
                  />
                ) : (
                  <div className="txt-brand-logo-fallback"><Car size={28} /></div>
                )}
                <div className="txt-brand-hero-text">
                  {brand.tagline && <p>{brand.tagline}</p>}
                </div>
              </div>
            </div>
          ) : null}
          {brand ? null : (
            <div className="txt-sidebar-header">
              <div className="txt-sidebar-icon" style={{ background: `linear-gradient(135deg, ${accentColor}, ${accentColor}88)` }}>
                <Car size={20} />
              </div>
              <div className="txt-sidebar-title">
                <h1>Taxi</h1>
                <p>{profile.rank?.label || 'Apprenti'}</p>
              </div>
            </div>
          )}

          <div className="txt-summary-section">
            <div className="txt-summary-item">
              <span className="txt-summary-label">Rang</span>
              <span className="txt-summary-value">{profile.rank?.label || '—'}</span>
            </div>
            <div className="txt-summary-item">
              <span className="txt-summary-label">XP</span>
              <span className="txt-summary-value">{profile.xp}</span>
            </div>
          </div>

          <nav className="txt-sidebar-nav">
            {SECTIONS.map((s) => (
              <button
                key={s.key}
                className={`txt-sidebar-item ${section === s.key ? 'active' : ''}`}
                onClick={() => setSection(s.key)}
              >
                {section === s.key && <div className="txt-sidebar-indicator" style={{ background: accentColor }} />}
                <span>{s.label}</span>
                {s.key === 'requests' && requests.length > 0 && (
                  <span className="txt-sidebar-badge" style={{ background: accentColor, color: '#000' }}>
                    {requests.length}
                  </span>
                )}
                <ChevronRight size={14} className="txt-sidebar-arrow" />
              </button>
            ))}
          </nav>

          <div className="txt-sidebar-footer">
            <button className="txt-close-btn" onClick={handleClose}>
              <X size={16} />
              <span>Fermer</span>
            </button>
          </div>
        </aside>

        <div className="txt-content">
          {section === 'missions' && (
            <MissionsSection
              data={data}
              accentColor={accentColor}
              xpProgress={xpProgress}
              xpInRank={xpInRank}
              xpToNext={xpToNext}
              dailyProgress={dailyProgress}
              onStart={handleStartMission}
              pendingCount={requests.length}
              onGotoRequests={() => setSection('requests')}
            />
          )}
          {section === 'requests' && (
            <RequestsSection
              requests={requests}
              selected={selectedRequest}
              onSelect={setSelectedReqId}
              onAccept={handleAcceptRequest}
              accentColor={accentColor}
            />
          )}
        </div>
      </div>
    </div>
  );
};

export default TaxiBoard;

/* ============================================================ */
/*  MISSIONS  (now embeds progression below)                    */
/* ============================================================ */

interface MissionsSectionProps {
  data: TaxiBoardData;
  accentColor: string;
  xpProgress: number;
  xpInRank: number;
  xpToNext: number;
  dailyProgress: number;
  onStart: (mission: TaxiMissionUI) => void;
  pendingCount: number;
  onGotoRequests: () => void;
}

const MissionsSection: React.FC<MissionsSectionProps> = ({
  data, accentColor, xpProgress, xpInRank, xpToNext, dailyProgress, onStart,
  pendingCount, onGotoRequests,
}) => {
  const profile = data.profile;
  const blocked = pendingCount > 0;
  const handleStart = (m: TaxiMissionUI) => {
    if (blocked) { onGotoRequests(); return; }
    onStart(m);
  };
  return (
    <>
      <div className="txt-content-header">
        <div className="txt-content-header-info">
          <h2>Missions disponibles</h2>
          <p>Sélectionnez une course pour commencer votre service.</p>
        </div>
        <div className="txt-header-pills">
          <div className="txt-header-pill">
            <span className="txt-header-pill-label">Aujourd'hui</span>
            <span className="txt-header-pill-value">{profile.todayRides}/{profile.dailyGoal}</span>
          </div>
          <div className="txt-header-pill">
            <span className="txt-header-pill-label">Gains</span>
            <span className="txt-header-pill-value" style={{ color: accentColor }}>${profile.todayEarnings}</span>
          </div>
        </div>
      </div>

      {blocked && (
        <button
          className="txt-priority-banner"
          onClick={onGotoRequests}
          style={{ borderColor: accentColor, color: accentColor }}
        >
          <Phone size={14} />
          <span>
            <strong>{pendingCount} joueur{pendingCount > 1 ? 's' : ''}</strong>{' '}
            {pendingCount > 1 ? 'attendent' : 'attend'} un taxi — prenez d'abord {pendingCount > 1 ? 'leurs courses' : 'sa course'}.
          </span>
          <ChevronRight size={14} />
        </button>
      )}

      <div className={`txt-mission-grid ${blocked ? 'txt-mission-grid-blocked' : ''}`}>
        {data.missions.map((m) => (
          <div
            key={m.key}
            className={`txt-mission-card ${m.unlocked && !blocked ? '' : 'txt-mission-locked'}`}
            onClick={() => handleStart(m)}
          >
            <div className="txt-mission-head">
              <h3 className="txt-mission-label">{m.label}</h3>
              {!m.unlocked && (
                <span className="txt-mission-lock"><Lock size={12} /></span>
              )}
            </div>
            <p className="txt-mission-desc">{m.description}</p>
            <div className="txt-mission-meta">
              {m.stops && m.stops > 1 && (
                <span className="txt-mission-meta-item">{m.stops} arrêts</span>
              )}
              {!m.unlocked && (
                <span className="txt-mission-meta-item txt-mission-req">
                  Rang requis : {data.ranks.find(r => r.key === m.requireRank)?.label || m.requireRank}
                </span>
              )}
            </div>
            <button
              className="txt-mission-cta"
              disabled={!m.unlocked}
              style={m.unlocked ? { borderColor: accentColor, color: accentColor } : undefined}
            >
              {m.unlocked ? 'Commencer' : 'Verrouillé'}
            </button>
          </div>
        ))}
        {data.missions.length === 0 && (
          <div className="txt-empty"><p>Aucune mission disponible</p></div>
        )}
      </div>

      <div className="txt-section-title">Progression</div>
      <div className="txt-stats-band">
        <div className="txt-stat-card">
          <span className="txt-stat-label">Rang actuel</span>
          <span className="txt-stat-value">{profile.rank?.label || '—'}</span>
          {profile.nextRank ? (
            <>
              <div className="txt-stat-progress">
                <div className="txt-stat-progress-bar" style={{ width: `${xpProgress}%`, background: accentColor }} />
              </div>
              <span className="txt-stat-sub">
                {xpInRank} / {xpToNext} XP → {profile.nextRank.label}
              </span>
            </>
          ) : (
            <span className="txt-stat-sub">Rang maximum atteint</span>
          )}
        </div>
        <div className="txt-stat-card">
          <span className="txt-stat-label">Aujourd'hui</span>
          <span className="txt-stat-value">{profile.todayRides} courses</span>
          <div className="txt-stat-progress">
            <div className="txt-stat-progress-bar" style={{ width: `${dailyProgress}%`, background: accentColor }} />
          </div>
          <span className="txt-stat-sub">Objectif {profile.todayRides} / {profile.dailyGoal}</span>
        </div>
        <div className="txt-stat-card">
          <span className="txt-stat-label">Gains du jour</span>
          <span className="txt-stat-value" style={{ color: accentColor }}>${profile.todayEarnings}</span>
          <span className="txt-stat-sub">Multi paie ×{profile.rank?.payMul?.toFixed(2) || '1.00'}</span>
        </div>
        <div className="txt-stat-card">
          <span className="txt-stat-label">Expérience</span>
          <span className="txt-stat-value">{profile.xp} XP</span>
          <span className="txt-stat-sub">{data.ranks.length} rangs disponibles</span>
        </div>
      </div>

      <div className="txt-section-title">Échelle des rangs</div>
      <div className="txt-rank-row">
        {data.ranks.map((r, idx) => {
          const reached = profile.xp >= r.minXp;
          const current = profile.rank?.key === r.key;
          return (
            <div
              key={r.key}
              className={`txt-rank-step ${reached ? 'reached' : ''} ${current ? 'current' : ''}`}
              style={current ? { borderColor: accentColor } : undefined}
            >
              <div
                className="txt-rank-step-dot"
                style={current ? { background: accentColor, color: '#000' } : undefined}
              >
                {idx + 1}
              </div>
              <div className="txt-rank-step-meta">
                <span className="txt-rank-step-label">{r.label}</span>
                <span className="txt-rank-step-xp">{r.minXp} XP · ×{r.payMul.toFixed(2)}</span>
              </div>
            </div>
          );
        })}
      </div>
    </>
  );
};

/* ============================================================ */
/*  REQUESTS  (map + side list)                                 */
/* ============================================================ */

interface RequestsSectionProps {
  requests: TaxiRequest[];
  selected: TaxiRequest | null;
  onSelect: (id: string | null) => void;
  onAccept: (id: string) => void;
  accentColor: string;
}

const RequestsSection: React.FC<RequestsSectionProps> = ({
  requests, selected, onSelect, onAccept, accentColor,
}) => {
  return (
    <div className="txt-requests">
      <div className="txt-content-header">
        <div className="txt-content-header-info">
          <h2>Clients en attente</h2>
          <p>Sélectionnez un client pour voir ses informations et accepter la course.</p>
        </div>
        <div className="txt-header-pills">
          <div className="txt-header-pill">
            <span className="txt-header-pill-label">En file</span>
            <span className="txt-header-pill-value" style={{ color: accentColor }}>{requests.length}</span>
          </div>
        </div>
      </div>

      <div className="txt-requests-body">
        <RequestsMap
          requests={requests}
          selectedId={selected?.id || null}
          onSelect={onSelect}
          accentColor={accentColor}
        />

        <aside className="txt-requests-aside">
          <div className="txt-requests-list">
            {requests.length === 0 && (
              <div className="txt-requests-empty">
                <Phone size={28} />
                <p>Aucune demande en attente</p>
              </div>
            )}
            {requests.map((r) => {
              const active = selected?.id === r.id;
              return (
                <button
                  key={r.id}
                  className={`txt-req-card ${active ? 'active' : ''}`}
                  onClick={() => onSelect(r.id)}
                  style={active ? { borderColor: accentColor } : undefined}
                >
                  <div className="txt-req-avatar" style={{ background: accentColor + '22', color: accentColor }}>
                    <User size={16} />
                  </div>
                  <div className="txt-req-info">
                    <span className="txt-req-name">{r.citizenName}</span>
                    <span className="txt-req-sub">
                      <MapPin size={10} /> {r.address || 'Localisation inconnue'}
                    </span>
                  </div>
                  <span className="txt-req-time">
                    <Clock size={10} /> {fmtElapsed(r.createdAt)}
                  </span>
                </button>
              );
            })}
          </div>

          {selected && (
            <div className="txt-req-detail">
              <div className="txt-req-detail-head">
                <div className="txt-req-avatar lg" style={{ background: accentColor + '22', color: accentColor }}>
                  <User size={20} />
                </div>
                <div>
                  <div className="txt-req-detail-name">{selected.citizenName}</div>
                  <div className="txt-req-detail-sub">{selected.address || '—'}</div>
                </div>
              </div>
              <div className="txt-req-detail-meta">
                <div className="txt-req-detail-meta-row">
                  <span>Position</span>
                  <span>{selected.coords.x.toFixed(0)}, {selected.coords.y.toFixed(0)}</span>
                </div>
                <div className="txt-req-detail-meta-row">
                  <span>En attente depuis</span>
                  <span>{fmtElapsed(selected.createdAt)}</span>
                </div>
                {selected.note && (
                  <div className="txt-req-detail-note">"{selected.note}"</div>
                )}
              </div>
              <button
                className="txt-req-accept"
                onClick={() => onAccept(selected.id)}
                style={{ background: accentColor, color: '#000' }}
              >
                <Check size={16} /> Accepter la course
              </button>
            </div>
          )}
        </aside>
      </div>
    </div>
  );
};

/* ============================================================ */
/*  MAP (pannable / zoomable)                                   */
/* ============================================================ */

interface RequestsMapProps {
  requests: TaxiRequest[];
  selectedId: string | null;
  onSelect: (id: string | null) => void;
  accentColor: string;
}

const RequestsMap: React.FC<RequestsMapProps> = ({ requests, selectedId, onSelect, accentColor }) => {
  const wrapRef  = useRef<HTMLDivElement>(null);
  const stageRef = useRef<HTMLDivElement>(null);
  const imgRef   = useRef<HTMLImageElement>(null);

  const stateRef = useRef({
    scale: 1, tx: 0, ty: 0,
    imgW: 0, imgH: 0,
    minScale: 1, maxScale: 6,
    dragging: false, didMove: false,
    startX: 0, startY: 0, startTx: 0, startTy: 0,
    pointers: new Map<number, { x: number; y: number }>(),
    startDist: 0, startScale: 1,
  });

  const apply = useCallback(() => {
    const s = stateRef.current;
    if (stageRef.current) {
      stageRef.current.style.transform = `translate(${s.tx}px, ${s.ty}px) scale(${s.scale})`;
    }
  }, []);

  const clamp = useCallback(() => {
    const s = stateRef.current;
    const wrap = wrapRef.current;
    if (!wrap || !s.imgW || !s.imgH) return;
    const wW = wrap.clientWidth, wH = wrap.clientHeight;
    const sW = s.imgW * s.scale, sH = s.imgH * s.scale;
    s.tx = sW <= wW ? (wW - sW) / 2 : Math.max(wW - sW, Math.min(0, s.tx));
    s.ty = sH <= wH ? (wH - sH) / 2 : Math.max(wH - sH, Math.min(0, s.ty));
  }, []);

  const fit = useCallback(() => {
    const s = stateRef.current;
    const wrap = wrapRef.current;
    if (!wrap || !s.imgW || !s.imgH) return;
    s.minScale = Math.max(wrap.clientWidth / s.imgW, wrap.clientHeight / s.imgH);
    s.scale    = s.minScale;
    s.tx = (wrap.clientWidth  - s.imgW * s.scale) / 2;
    s.ty = (wrap.clientHeight - s.imgH * s.scale) / 2;
    apply();
  }, [apply]);

  const zoomAt = useCallback((next: number, clientX: number, clientY: number) => {
    const s = stateRef.current;
    const wrap = wrapRef.current;
    if (!wrap) return;
    const rect = wrap.getBoundingClientRect();
    const mx = clientX - rect.left, my = clientY - rect.top;
    const ratio = next / s.scale;
    s.tx = mx - (mx - s.tx) * ratio;
    s.ty = my - (my - s.ty) * ratio;
    s.scale = next;
    clamp();
    apply();
  }, [apply, clamp]);

  const onImgReady = useCallback(() => {
    const img = imgRef.current;
    if (!img) return;
    const s = stateRef.current;
    s.imgW = img.naturalWidth;
    s.imgH = img.naturalHeight;
    if (stageRef.current) {
      stageRef.current.style.width  = s.imgW + 'px';
      stageRef.current.style.height = s.imgH + 'px';
    }
    fit();
  }, [fit]);

  useEffect(() => {
    const wrap = wrapRef.current;
    if (!wrap) return;

    const onDown = (e: PointerEvent) => {
      const s = stateRef.current;
      s.pointers.set(e.pointerId, { x: e.clientX, y: e.clientY });
      s.didMove = false;
      if (s.pointers.size === 1) {
        s.dragging = true;
        s.startX = e.clientX; s.startY = e.clientY;
        s.startTx = s.tx; s.startTy = s.ty;
      } else if (s.pointers.size === 2) {
        s.dragging = false;
        const pts = Array.from(s.pointers.values());
        s.startDist  = Math.hypot(pts[0].x - pts[1].x, pts[0].y - pts[1].y);
        s.startScale = s.scale;
      }
    };
    const onMove = (e: PointerEvent) => {
      const s = stateRef.current;
      if (!s.pointers.has(e.pointerId)) return;
      s.pointers.set(e.pointerId, { x: e.clientX, y: e.clientY });
      if (s.pointers.size === 1 && s.dragging) {
        const dx = e.clientX - s.startX;
        const dy = e.clientY - s.startY;
        if (Math.abs(dx) > 4 || Math.abs(dy) > 4) s.didMove = true;
        if (s.didMove) {
          s.tx = s.startTx + dx;
          s.ty = s.startTy + dy;
          clamp();
          apply();
        }
      } else if (s.pointers.size === 2) {
        const pts = Array.from(s.pointers.values());
        const dist = Math.hypot(pts[0].x - pts[1].x, pts[0].y - pts[1].y);
        if (s.startDist > 0) {
          const next = Math.max(s.minScale, Math.min(s.maxScale, s.startScale * (dist / s.startDist)));
          s.didMove = true;
          zoomAt(next, (pts[0].x + pts[1].x) / 2, (pts[0].y + pts[1].y) / 2);
        }
      }
    };
    const onUp = (e: PointerEvent) => {
      const s = stateRef.current;
      s.pointers.delete(e.pointerId);
      if (s.pointers.size === 0) s.dragging = false;
    };
    const onWheel = (e: WheelEvent) => {
      e.preventDefault();
      const s = stateRef.current;
      const factor = e.deltaY < 0 ? 1.15 : 1 / 1.15;
      zoomAt(Math.max(s.minScale, Math.min(s.maxScale, s.scale * factor)), e.clientX, e.clientY);
    };
    const onResize = () => { clamp(); apply(); };

    wrap.addEventListener('pointerdown', onDown);
    document.addEventListener('pointermove', onMove);
    document.addEventListener('pointerup', onUp);
    document.addEventListener('pointercancel', onUp);
    wrap.addEventListener('wheel', onWheel, { passive: false });
    window.addEventListener('resize', onResize);
    return () => {
      wrap.removeEventListener('pointerdown', onDown);
      document.removeEventListener('pointermove', onMove);
      document.removeEventListener('pointerup', onUp);
      document.removeEventListener('pointercancel', onUp);
      wrap.removeEventListener('wheel', onWheel as any);
      window.removeEventListener('resize', onResize);
    };
  }, [apply, clamp, zoomAt]);

  return (
    <div className="txt-map-wrap" ref={wrapRef}>
      <div className="txt-map-stage" ref={stageRef}>
        <img
          ref={imgRef}
          className="txt-map-img"
          src={MAP_IMAGE_URL}
          alt="Map"
          draggable={false}
          onLoad={onImgReady}
        />
        <div className="txt-map-pins">
          {requests.map((r) => {
            const { u, v } = worldToMap(r.coords.x, r.coords.y);
            const active = selectedId === r.id;
            return (
              <button
                key={r.id}
                className={`txt-map-pin ${active ? 'active' : ''}`}
                style={{ left: `${u * 100}%`, top: `${v * 100}%` }}
                onClick={(e) => {
                  e.stopPropagation();
                  if (stateRef.current.didMove) { stateRef.current.didMove = false; return; }
                  onSelect(r.id);
                }}
                title={r.citizenName}
              >
                <svg viewBox="0 0 24 32" width="24" height="32">
                  <path
                    d="M12 0 C5 0 0 5 0 12 c0 8 12 20 12 20 s12 -12 12 -20 C24 5 19 0 12 0 z"
                    fill={accentColor}
                    stroke="#fff"
                    strokeWidth="1.2"
                  />
                  <circle cx="12" cy="12" r="4" fill="#fff" />
                </svg>
              </button>
            );
          })}
        </div>
      </div>

      <div className="txt-map-zoom">
        <button
          className="txt-map-zoom-btn"
          onClick={() => {
            const s = stateRef.current;
            const wrap = wrapRef.current; if (!wrap) return;
            const r = wrap.getBoundingClientRect();
            zoomAt(Math.min(s.maxScale, s.scale * 1.3), r.left + r.width / 2, r.top + r.height / 2);
          }}
        >+</button>
        <button
          className="txt-map-zoom-btn"
          onClick={() => {
            const s = stateRef.current;
            const wrap = wrapRef.current; if (!wrap) return;
            const r = wrap.getBoundingClientRect();
            zoomAt(Math.max(s.minScale, s.scale / 1.3), r.left + r.width / 2, r.top + r.height / 2);
          }}
        >−</button>
        <button
          className="txt-map-zoom-btn"
          onClick={() => fit()}
          title="Recentrer"
        >
          <Crosshair size={14} />
        </button>
      </div>
    </div>
  );
};
