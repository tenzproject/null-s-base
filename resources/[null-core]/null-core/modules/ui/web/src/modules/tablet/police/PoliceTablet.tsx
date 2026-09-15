import React, { useState, useEffect, useCallback, useMemo, useRef } from 'react';
import {
  X, Shield, LayoutDashboard, Users, Home as HomeIcon, Car, Scale,
  Search, MapPin, Trash2, Plus, BookOpen, ChevronRight, Edit2,
  CreditCard, Briefcase, Phone, BadgeCheck, ArrowLeft, AlertTriangle, Save,
  Radio, AlertOctagon, FolderPlus
} from 'lucide-react';
const IdCard = BadgeCheck;
import { cacheImg } from '@/shared/cacheVersion';
import { generateAccentVars } from '@/utils/accentColors';
import type {
  PoliceTabletProps, PoliceTabletData, DispatchState, DispatchCard, DispatchGroup,
  PenalCode, PenalOffense, PlayerSummary, PlayerDetails, OwnedVehicle, OwnedProperty,
  CasierEntry, RadioCode
} from './types';
import './PoliceTablet.css';

const Res = () => 'null-core';
const post = (event: string, body: any = {}) =>
  fetch(`https://${Res()}/${event}`, {
    method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body),
  });

type Page = 'dispatch' | 'players' | 'properties' | 'vehicles' | 'casier' | 'penal' | 'radio';

const PAGES: Array<{ id: Page; label: string; icon: React.ReactNode }> = [
  { id: 'dispatch',   label: 'Dispatch',   icon: <LayoutDashboard size={16} /> },
  { id: 'players',    label: 'Citoyens',   icon: <Users size={16} /> },
  { id: 'properties', label: 'Propriétés', icon: <HomeIcon size={16} /> },
  { id: 'vehicles',   label: 'Véhicules',  icon: <Car size={16} /> },
  { id: 'casier',     label: 'Casier',     icon: <Scale size={16} /> },
];

const PoliceTablet: React.FC<PoliceTabletProps> = ({ visible, onClose, primaryColor }) => {
  const [data, setData] = useState<PoliceTabletData | null>(null);
  const [page, setPage] = useState<Page>('dispatch');
  const [hiding, setHiding] = useState(false);
  const [dispatch, setDispatch] = useState<DispatchState>({ cards: {}, groups: {} });
  const [penalCode, setPenalCode] = useState<PenalCode>({});
  const [radioCodes, setRadioCodes] = useState<RadioCode[]>([]);

  useEffect(() => {
    const handler = (e: MessageEvent) => {
      const { action, data: payload } = e.data || {};
      switch (action) {
        case 'policeTablet:open':
          if (payload) {
            setData(payload);
            setDispatch(payload.dispatch || { cards: {}, groups: {} });
            setPenalCode(payload.penalCode || {});
            setRadioCodes(payload.radioCodes || []);
            setPage('dispatch');
          }
          break;
        case 'policeTablet:close':
          setData(null);
          break;
        case 'policeTablet:dispatchUpdate':
          if (payload) setDispatch(payload);
          break;
        case 'policeTablet:penalUpdate':
          if (payload) setPenalCode(payload);
          break;
        case 'policeTablet:radioUpdate':
          if (payload) setRadioCodes(payload);
          break;
      }
    };
    window.addEventListener('message', handler);
    return () => window.removeEventListener('message', handler);
  }, []);

  const handleClose = useCallback(() => {
    setHiding(true);
    setTimeout(() => {
      setHiding(false);
      onClose();
      post('policeTablet:close');
    }, 280);
  }, [onClose]);

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => { if (e.key === 'Escape' && visible) handleClose(); };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [visible, handleClose]);

  const accent = primaryColor || data?.brand.accentColor || '#BEEE11';
  const brandBg = data?.brand.bgColor || '#0a0f1e';
  const accentVars = useMemo(() => generateAccentVars('--police-accent', accent), [accent]);
  const brandVars = useMemo(() => ({
    '--police-brand-bg': brandBg,
    '--police-brand-accent': accent,
  } as React.CSSProperties), [brandBg, accent]);

  if (!visible || !data) return null;

  return (
    <div className={`police-overlay ${hiding ? 'police-hiding' : ''}`}>
      <div
        className="police-container"
        style={{ ...accentVars, ...brandVars } as React.CSSProperties}
      >
        {/* Sidebar */}
        <aside className="police-sidebar">
          <div className="police-brand-hero" style={{ background: `linear-gradient(160deg, ${brandBg} 0%, ${brandBg}dd 60%, rgba(0,0,0,0.4) 100%)` }}>
            <div className="police-brand-shine" />
            <div className="police-brand-inner">
              {data.brand.logo ? (
                <img className="police-brand-logo" src={cacheImg(data.brand.logo)} alt={data.brand.name}
                  onError={(e) => { (e.target as HTMLImageElement).src = 'nui://null-cache/images/shopui/brands/lspd.png'; }} />
              ) : (
                <img className="police-brand-logo" src="nui://null-cache/images/shopui/brands/lspd.png" alt="Police" />
              )}
              <div className="police-brand-text">
                <h1>{data.brand.name}</h1>
                <p>Tablette de service</p>
              </div>
            </div>
          </div>

          <div className="police-agent-card">
            <div className="police-agent-meta">
              <strong>{data.agent.firstname} {data.agent.lastname}</strong>
              <span>{data.gradeLabel || data.grade}</span>
            </div>
          </div>

          <nav className="police-nav">
            {PAGES.map(p => (
              <button
                key={p.id}
                className={`police-nav-item ${page === p.id ? 'active' : ''}`}
                onClick={() => setPage(p.id)}
              >
                {page === p.id && <div className="police-nav-indicator" />}
                {p.icon}
                <span>{p.label}</span>
                <ChevronRight size={14} className="police-nav-arrow" />
              </button>
            ))}
            <button
              className={`police-nav-item ${page === 'penal' ? 'active' : ''}`}
              onClick={() => setPage('penal')}
            >
              {page === 'penal' && <div className="police-nav-indicator" />}
              <BookOpen size={16} />
              <span>Code Pénal</span>
              <ChevronRight size={14} className="police-nav-arrow" />
            </button>
            <button
              className={`police-nav-item ${page === 'radio' ? 'active' : ''}`}
              onClick={() => setPage('radio')}
            >
              {page === 'radio' && <div className="police-nav-indicator" />}
              <Radio size={16} />
              <span>Codes Radio</span>
              <ChevronRight size={14} className="police-nav-arrow" />
            </button>
          </nav>

          <button className="police-close-btn" onClick={handleClose}>
            <X size={16} />
            <span>Fermer</span>
          </button>
        </aside>

        {/* Main */}
        <main className="police-main">
          {page === 'dispatch' && (
            <DispatchPage data={data} dispatch={dispatch} />
          )}
          {page === 'players' && <PlayersPage data={data} penalCode={penalCode} />}
          {page === 'properties' && <PropertiesPage />}
          {page === 'vehicles' && <VehiclesPage />}
          {page === 'casier' && <CasierPage penalCode={penalCode} data={data} />}
          {page === 'penal' && <PenalCodePage penalCode={penalCode} canEdit={data.isBoss} />}
          {page === 'radio' && <RadioCodesPage radioCodes={radioCodes} canEdit={data.isBoss} />}
        </main>
      </div>
    </div>
  );
};

/* =========================================================================
   DISPATCH PAGE
   ========================================================================= */
const DispatchPage: React.FC<{ data: PoliceTabletData; dispatch: DispatchState }> = ({ data, dispatch }) => {
  const boardRef = useRef<HTMLDivElement>(null);
  const [matricule, setMatricule] = useState('');
  const [color, setColor] = useState('#3b82f6');
  const [drag, setDrag] = useState<{ type: 'card' | 'group'; id: string } | null>(null);
  const dragRef = useRef<{
    el: HTMLElement;
    startX: number;
    startY: number;
    origLeft: number;
    origTop: number;
    boardRect: DOMRect;
  } | null>(null);
  const [hoverGroup, setHoverGroup] = useState<string | null>(null);
  const [groupName, setGroupName] = useState('');
  const [showGroupForm, setShowGroupForm] = useState(false);

  const myCard = dispatch.cards[data.agent.identifier];
  const cards = Object.values(dispatch.cards);
  const groups = Object.values(dispatch.groups);

  const handleCreateCard = () => {
    if (!matricule.trim()) return;
    post('policeTablet:createCard', { matricule: matricule.trim(), color, x: 80, y: 80 });
    setMatricule('');
  };

  const handleCreateGroup = () => {
    if (!groupName.trim()) return;
    post('policeTablet:createGroup', { name: groupName.trim(), color: '#1e3a8a', x: 220, y: 220 });
    setGroupName('');
    setShowGroupForm(false);
  };

  const handleDeleteCard = () => {
    if (!myCard) return;
    post('policeTablet:deleteCard', { identifier: data.agent.identifier });
  };

  const onPointerDownCard = (e: React.PointerEvent, card: DispatchCard) => {
    if (card.identifier !== data.agent.identifier && !data.isBoss) return;
    if ((e.target as HTMLElement).closest('button, .police-group-delete')) return;
    const el = e.currentTarget as HTMLElement;
    el.classList.add('dragging');
    (e.currentTarget as HTMLElement).setPointerCapture(e.pointerId);
    dragRef.current = {
      el,
      startX: e.clientX, startY: e.clientY,
      origLeft: card.x, origTop: card.y,
      boardRect: boardRef.current!.getBoundingClientRect(),
    };
    setDrag({ type: 'card', id: card.identifier });
  };

  const onPointerDownGroup = (e: React.PointerEvent, g: DispatchGroup) => {
    if ((e.target as HTMLElement).closest('button, .police-group-delete')) return;
    const el = (e.currentTarget as HTMLElement).parentElement as HTMLElement;
    el.classList.add('dragging');
    (e.currentTarget as HTMLElement).setPointerCapture(e.pointerId);
    dragRef.current = {
      el,
      startX: e.clientX, startY: e.clientY,
      origLeft: g.x, origTop: g.y,
      boardRect: boardRef.current!.getBoundingClientRect(),
    };
    setDrag({ type: 'group', id: g.id });
  };

  const onPointerMove = (e: React.PointerEvent) => {
    if (!dragRef.current || !boardRef.current || !drag) return;
    const d = dragRef.current;
    const dx = e.clientX - d.startX;
    const dy = e.clientY - d.startY;
    const w = drag.type === 'group' ? 280 : 60;
    const h = drag.type === 'group' ? 200 : 30;
    const x = Math.max(0, Math.min(d.boardRect.width - w, d.origLeft + dx));
    const y = Math.max(0, Math.min(d.boardRect.height - h, d.origTop + dy));
    d.el.style.left = `${x}px`;
    d.el.style.top = `${y}px`;

    if (drag.type === 'card') {
      const cx = e.clientX - d.boardRect.left;
      const cy = e.clientY - d.boardRect.top;
      let targetGroup: string | null = null;
      for (const g of groups) {
        if (cx >= g.x && cx <= g.x + 280 && cy >= g.y && cy <= g.y + 200) {
          targetGroup = g.id; break;
        }
      }
      setHoverGroup(prev => prev !== targetGroup ? targetGroup : prev);
    }
  };

  const onPointerUp = (e: React.PointerEvent) => {
    if (!dragRef.current || !boardRef.current || !drag) return;
    const d = dragRef.current;
    d.el.classList.remove('dragging');

    const dx = e.clientX - d.startX;
    const dy = e.clientY - d.startY;
    const w = drag.type === 'group' ? 280 : 60;
    const h = drag.type === 'group' ? 200 : 30;
    const x = Math.max(0, Math.min(d.boardRect.width - w, d.origLeft + dx));
    const y = Math.max(0, Math.min(d.boardRect.height - h, d.origTop + dy));

    if (drag.type === 'card') {
      const card = dispatch.cards[drag.id];
      const groupId = hoverGroup;
      post('policeTablet:moveCard', { identifier: drag.id, x, y, groupId: groupId !== null ? groupId : (card?.groupId || '') });
    } else {
      post('policeTablet:moveGroup', { id: drag.id, x, y });
    }
    dragRef.current = null;
    setDrag(null);
    setHoverGroup(null);
  };

  return (
    <div className="police-page police-page-dispatch">
      <header className="police-page-header">
        <div>
          <h2>Centre de dispatch</h2>
          <p>Créez votre carte agent, formez des patrouilles en glissant-déposant.</p>
        </div>
        <div className="police-toolbar">
          {!myCard ? (
            <>
              <input
                className="police-input"
                placeholder="Matricule"
                value={matricule}
                onChange={(e) => setMatricule(e.target.value)}
                maxLength={10}
              />
              <input type="color" className="police-color" value={color} onChange={(e) => setColor(e.target.value)} />
              <button className="police-btn police-btn-primary" onClick={handleCreateCard}>
               Créer ma carte
              </button>
            </>
          ) : (
            <button className="police-btn police-btn-danger" onClick={handleDeleteCard}>
               Retirer ma carte
            </button>
          )}
          {showGroupForm ? (
            <>
              <input className="police-input" placeholder="Nom du groupement" value={groupName} onChange={(e) => setGroupName(e.target.value)} />
              <button className="police-btn police-btn-primary" onClick={handleCreateGroup}><Save size={14} /></button>
              <button className="police-btn police-btn-ghost" onClick={() => setShowGroupForm(false)}><X size={14} /></button>
            </>
          ) : (
            <button className="police-btn police-btn-secondary" onClick={() => setShowGroupForm(true)}>
             Groupement
            </button>
          )}
        </div>
      </header>

      <div
        ref={boardRef}
        className="police-board"
        onPointerMove={onPointerMove}
        onPointerUp={onPointerUp}
      >
        {groups.length === 0 && cards.length === 0 && (
          <div className="police-empty-board">
            <LayoutDashboard size={40} />
            <h3>Tableau vide</h3>
            <p>Créez votre carte agent pour commencer puis formez une patrouille.</p>
          </div>
        )}

        {groups.map(g => {
          const groupCards = cards.filter(c => c.groupId === g.id);
          return (
            <div
              key={g.id}
              className={`police-group ${hoverGroup === g.id ? 'hover' : ''}`}
              style={{ left: g.x, top: g.y, borderColor: g.color }}
            >
              <div
                className="police-group-header"
                style={{ background: `linear-gradient(135deg, ${g.color}, ${g.color}99)` }}
                onPointerDown={(e) => onPointerDownGroup(e, g)}
              >
                <Users size={14} />
                <span>{g.name}</span>
                <span className="police-group-count">{groupCards.length}</span>
                {(g.createdBy === data.agent.identifier || data.isBoss) && (
                  <button className="police-group-delete" onPointerDown={(e) => e.stopPropagation()} onClick={() => post('policeTablet:deleteGroup', { id: g.id })}>
                    <X size={12} />
                  </button>
                )}
              </div>
              <div className="police-group-slots">
                {groupCards.length === 0 ? (
                  <div className="police-group-empty">Glissez une carte ici</div>
                ) : groupCards.map(c => (
                  <div key={c.identifier} className="police-group-slot" style={{ borderLeftColor: c.color }}>
                    <strong>#{c.matricule}</strong>
                    <span>{c.firstname} {c.lastname}</span>
                  </div>
                ))}
              </div>
            </div>
          );
        })}

        {cards.filter(c => !c.groupId).map(c => (
          <div
            key={c.identifier}
            className={`police-card ${c.identifier === data.agent.identifier ? 'mine' : ''}`}
            style={{ left: c.x, top: c.y, borderColor: c.color }}
            onPointerDown={(e) => onPointerDownCard(e, c)}
          >
            <div className="police-card-header" style={{ background: c.color }}>
              <Shield size={12} />
              <span>#{c.matricule}</span>
            </div>
            <div className="police-card-body">
              <strong>{c.firstname}</strong>
              <span>{c.lastname}</span>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};

/* =========================================================================
   PLAYERS PAGE
   ========================================================================= */
const PlayersPage: React.FC<{ data: PoliceTabletData; penalCode: PenalCode }> = ({ data, penalCode }) => {
  const [query, setQuery] = useState('');
  const [results, setResults] = useState<PlayerSummary[]>([]);
  const [selected, setSelected] = useState<PlayerDetails | null>(null);
  const [loading, setLoading] = useState(false);
  const [showAdd, setShowAdd] = useState(false);
  const [isPreview, setIsPreview] = useState(true);

  useEffect(() => {
    (async () => {
      setLoading(true);
      const r = await post('policeTablet:searchPlayers', { query: '' });
      setResults((await r.json()) || []);
      setIsPreview(true);
      setLoading(false);
    })();
  }, []);

  const search = async () => {
    if (!query.trim()) return;
    setLoading(true);
    const r = await post('policeTablet:searchPlayers', { query: query.trim() });
    const j = await r.json();
    setResults(j || []);
    setIsPreview(false);
    setLoading(false);
  };

  const loadDetails = async (identifier: string) => {
    setLoading(true);
    const r = await post('policeTablet:getPlayerDetails', { identifier });
    const j = await r.json();
    setSelected(j && j.summary ? j : null);
    setLoading(false);
  };

  if (selected) {
    return (
      <PlayerDetailsView
        details={selected}
        onBack={() => setSelected(null)}
        penalCode={penalCode}
        agentMatricule={data.agent.identifier}
        onAddCasier={() => setShowAdd(true)}
        showAdd={showAdd}
        closeAdd={() => setShowAdd(false)}
        afterAdd={() => { setShowAdd(false); loadDetails(selected.summary.identifier); }}
      />
    );
  }

  return (
    <div className="police-page">
      <header className="police-page-header">
        <div>
          <h2>Recherche citoyens</h2>
          <p>Recherchez un citoyen par prénom, nom ou ID unique.</p>
        </div>
        <div className="police-toolbar">
          <div className="police-search">
            <Search size={14} />
            <input
              placeholder="Prénom, nom ou ID"
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              onKeyDown={(e) => { if (e.key === 'Enter') search(); }}
            />
          </div>
          <button className="police-btn police-btn-primary" onClick={search}>Rechercher</button>
        </div>
      </header>

      <div className="police-results">
        {loading && <div className="police-loading">Recherche en cours…</div>}
        {!loading && results.length === 0 && (
          <EmptyState icon={<Users size={36} />} title="Aucun résultat" subtitle="Tapez un nom ou prénom pour commencer." />
        )}
        {!loading && isPreview && results.length > 0 && (
          <PreviewLabel text="Citoyens récents" />
        )}
        {results.map((r, i) => (
          <button key={r.identifier} className="police-result-card police-anim-in" style={{ animationDelay: `${i * 0.035}s` }} onClick={() => loadDetails(r.identifier)}>
            <div className="police-result-avatar"><Users size={18} /></div>
            <div className="police-result-info">
              <strong>{r.firstname} {r.lastname}</strong>
              <span>ID: {r.idunique} · {r.job}</span>
            </div>
            <ChevronRight size={14} className="police-result-arrow" />
          </button>
        ))}
      </div>
    </div>
  );
};

const PlayerDetailsView: React.FC<{
  details: PlayerDetails; onBack: () => void; penalCode: PenalCode;
  agentMatricule: string; onAddCasier: () => void; showAdd: boolean;
  closeAdd: () => void; afterAdd: () => void;
}> = ({ details, onBack, penalCode, onAddCasier, showAdd, closeAdd, afterAdd }) => {
  const { summary, vehicles, properties, casier } = details;
  const [expandedSection, setExpandedSection] = useState<'casier' | 'vehicles' | 'properties' | null>(null);

  return (
    <div className="police-page police-page-details">
      <header className="police-page-header">
        <div className="police-details-top">
          <button className="police-btn police-btn-ghost" onClick={onBack}><ArrowLeft size={14} /> Retour</button>
          <div>
            <h2>{summary.firstname} {summary.lastname}</h2>
            <p>ID: {summary.idunique} · {summary.sex === 'm' ? 'Homme' : 'Femme'} · Né(e) le {summary.dateofbirth || '—'}</p>
          </div>
        </div>
        <button className="police-btn police-btn-primary" onClick={onAddCasier}>
          <Plus size={14} /> Ajouter au casier
        </button>
      </header>

      <div className="police-detail-grid">
        <div className="police-detail-card police-anim-in" style={{ animationDelay: '0s' }}>
          <div className="police-detail-card-icon"><CreditCard size={16} /></div>
          <div><span>Compte bancaire</span><strong>${summary.bank.toLocaleString()}</strong></div>
        </div>
        <div className="police-detail-card police-anim-in" style={{ animationDelay: '0.05s' }}>
          <div className="police-detail-card-icon"><Briefcase size={16} /></div>
          <div><span>Métier</span><strong>{summary.job} {summary.jobGrade ? `(${summary.jobGrade})` : ''}</strong></div>
        </div>
        <div className="police-detail-card police-anim-in" style={{ animationDelay: '0.1s' }}>
          <div className="police-detail-card-icon"><Phone size={16} /></div>
          <div><span>Téléphone</span><strong>{summary.phone || '—'}</strong></div>
        </div>
        <div className="police-detail-card police-anim-in" style={{ animationDelay: '0.15s' }}>
          <div className="police-detail-card-icon"><Scale size={16} /></div>
          <div><span>Antécédents</span><strong>{casier.length} entrée(s)</strong></div>
        </div>
      </div>

      <section className="police-section">
        <div className="police-section-header">
          <h3> Casier judiciaire</h3>
          <button className="police-link" onClick={() => setExpandedSection(expandedSection === 'casier' ? null : 'casier')}>
            {expandedSection === 'casier' ? 'Réduire' : 'Voir plus'}
          </button>
        </div>
        {casier.length === 0 ? (
          <div className="police-section-empty">Aucun antécédent.</div>
        ) : (
          (expandedSection === 'casier' ? casier : casier.slice(0, 2)).map(c => (
            <CasierItem key={c.id} entry={c} />
          ))
        )}
      </section>

      <section className="police-section">
        <div className="police-section-header">
          <h3> Véhicules ({vehicles.length})</h3>
          <button className="police-link" onClick={() => setExpandedSection(expandedSection === 'vehicles' ? null : 'vehicles')}>
            {expandedSection === 'vehicles' ? 'Réduire' : 'Voir plus'}
          </button>
        </div>
        {vehicles.length === 0 ? (
          <div className="police-section-empty">Aucun véhicule enregistré.</div>
        ) : (
          <div className="police-mini-grid">
            {(expandedSection === 'vehicles' ? vehicles : vehicles.slice(0, 4)).map(v => (
              <div key={v.plate} className="police-mini-card">
                <Car size={14} />
                <div>
                  <strong>{v.label || v.vehicle}</strong>
                  <span>Plaque {v.plate} · {v.state === 'out' ? 'En circulation' : 'Au garage'}</span>
                </div>
              </div>
            ))}
          </div>
        )}
      </section>

      <section className="police-section">
        <div className="police-section-header">
          <h3> Propriétés ({properties.length})</h3>
          <button className="police-link" onClick={() => setExpandedSection(expandedSection === 'properties' ? null : 'properties')}>
            {expandedSection === 'properties' ? 'Réduire' : 'Voir plus'}
          </button>
        </div>
        {properties.length === 0 ? (
          <div className="police-section-empty">Aucune propriété.</div>
        ) : (
          <div className="police-mini-grid">
            {(expandedSection === 'properties' ? properties : properties.slice(0, 4)).map(p => (
              <div key={p.name} className="police-mini-card">
                <HomeIcon size={14} />
                <div>
                  <strong>{p.label}</strong>
                  <span>${p.price.toLocaleString()}</span>
                </div>
                {p.coords && (
                  <button className="police-mini-action" onClick={() => post('policeTablet:setWaypoint', { x: p.coords!.x, y: p.coords!.y })}>
                    <MapPin size={12} />
                  </button>
                )}
              </div>
            ))}
          </div>
        )}
      </section>

      {showAdd && (
        <AddCasierModal
          penalCode={penalCode}
          target={summary}
          onClose={closeAdd}
          onSaved={afterAdd}
        />
      )}
    </div>
  );
};

const CasierItem: React.FC<{ entry: CasierEntry }> = ({ entry }) => (
  <div className="police-casier-item">
    <div className="police-casier-head">
      <div>
        <strong>Agent: {entry.agentName}</strong>
        <span>Matricule #{entry.agentMatricule} · {new Date(entry.createdAt).toLocaleString('fr-FR')}</span>
      </div>
      <div className="police-casier-totals">
        <span className="police-tag police-tag-money">${entry.totalAmount}</span>
        {entry.totalJail > 0 && <span className="police-tag police-tag-jail">{entry.totalJail}s prison</span>}
      </div>
    </div>
    <ul className="police-casier-offenses">
      {entry.offenses.map((o, i) => (
        <li key={i}>
          <span>{o.label}</span>
          <em>${o.price}{o.jail > 0 ? ` · ${o.jail}s` : ''}</em>
        </li>
      ))}
    </ul>
    {entry.notes && <p className="police-casier-notes">{entry.notes}</p>}
  </div>
);

const AddCasierModal: React.FC<{
  penalCode: PenalCode; target: PlayerSummary; onClose: () => void; onSaved: () => void;
}> = ({ penalCode, target, onClose, onSaved }) => {
  const [selected, setSelected] = useState<PenalOffense[]>([]);
  const [notes, setNotes] = useState('');
  const [matricule, setMatricule] = useState('');
  const [activeCat, setActiveCat] = useState<string | null>(Object.keys(penalCode)[0] || null);

  const total = selected.reduce((s, o) => s + o.price, 0);
  const jail = selected.reduce((s, o) => s + o.jail, 0);

  const submit = () => {
    if (selected.length === 0) return;
    post('policeTablet:addCasier', {
      identifier: target.identifier,
      targetName: `${target.firstname} ${target.lastname}`,
      targetIdunique: target.idunique,
      agentMatricule: matricule,
      offenses: selected.map(o => ({ label: o.label, price: o.price, jail: o.jail, category: activeCat || '' })),
      notes,
    });
    setTimeout(onSaved, 400);
  };

  return (
    <div className="police-modal-overlay" onClick={onClose}>
      <div className="police-modal" onClick={(e) => e.stopPropagation()}>
        <header className="police-modal-header">
          <h3>Nouveau dossier · {target.firstname} {target.lastname}</h3>
          <button className="police-icon-btn" onClick={onClose}><X size={14} /></button>
        </header>
        <div className="police-modal-body">
          <div className="police-modal-left">
            <div className="police-modal-cats">
              {Object.keys(penalCode).map(cat => (
                <button key={cat} className={`police-modal-cat ${activeCat === cat ? 'active' : ''}`} onClick={() => setActiveCat(cat)}>
                  {cat}
                </button>
              ))}
            </div>
            <div className="police-modal-offenses">
              {(penalCode[activeCat || ''] || []).map(o => (
                <button key={o.id} className="police-offense-row" onClick={() => setSelected(s => [...s, o])}>
                  <span>{o.label}</span>
                  <em>${o.price}{o.jail > 0 ? ` · ${o.jail}s` : ''}</em>
                  <Plus size={12} />
                </button>
              ))}
            </div>
          </div>
          <div className="police-modal-right">
            <label className="police-field">
              <span>Votre matricule</span>
              <input value={matricule} onChange={(e) => setMatricule(e.target.value)} placeholder="ex: 113" />
            </label>
            <div className="police-selected">
              <h4>Infractions retenues</h4>
              {selected.length === 0 ? <p className="police-empty-mini">Aucune infraction sélectionnée</p> :
                selected.map((o, i) => (
                  <div key={i} className="police-selected-row">
                    <span>{o.label}</span>
                    <em>${o.price}{o.jail > 0 ? ` · ${o.jail}s` : ''}</em>
                    <button onClick={() => setSelected(s => s.filter((_, j) => j !== i))}><X size={11} /></button>
                  </div>
                ))
              }
            </div>
            <label className="police-field">
              <span>Notes</span>
              <textarea value={notes} onChange={(e) => setNotes(e.target.value)} rows={3} />
            </label>
            <div className="police-modal-totals">
              <div><span>Total amende</span><strong>${total.toLocaleString()}</strong></div>
              <div><span>Total prison</span><strong>{jail}s</strong></div>
            </div>
            <button className="police-btn police-btn-primary" onClick={submit} disabled={selected.length === 0}>
              <Save size={14} /> Valider le dossier
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

/* =========================================================================
   PROPERTIES
   ========================================================================= */
const PropertiesPage: React.FC = () => {
  const [query, setQuery] = useState('');
  const [results, setResults] = useState<OwnedProperty[]>([]);
  const [loading, setLoading] = useState(false);
  const [isPreview, setIsPreview] = useState(true);

  useEffect(() => {
    (async () => {
      setLoading(true);
      const r = await post('policeTablet:searchProperties', { query: '' });
      setResults((await r.json()) || []);
      setIsPreview(true);
      setLoading(false);
    })();
  }, []);

  const search = async () => {
    if (!query.trim()) return;
    setLoading(true);
    const r = await post('policeTablet:searchProperties', { query: query.trim() });
    setResults((await r.json()) || []);
    setIsPreview(false);
    setLoading(false);
  };

  return (
    <div className="police-page">
      <header className="police-page-header">
        <div><h2>Propriétés</h2><p>Recherchez par nom de propriété ou propriétaire.</p></div>
        <div className="police-toolbar">
          <div className="police-search">
            <Search size={14} />
            <input placeholder="Nom propriété ou propriétaire" value={query} onChange={(e) => setQuery(e.target.value)}
              onKeyDown={(e) => { if (e.key === 'Enter') search(); }} />
          </div>
          <button className="police-btn police-btn-primary" onClick={search}>Rechercher</button>
        </div>
      </header>
      <div className="police-results">
        {loading && <div className="police-loading">Recherche…</div>}
        {!loading && results.length === 0 && <EmptyState icon={<HomeIcon size={36} />} title="Aucun résultat" subtitle="Tapez un nom de propriété ou propriétaire." />}
        {!loading && isPreview && results.length > 0 && <PreviewLabel text="Propriétés récentes" />}
        {results.map((p, i) => (
          <div key={p.name} className="police-result-card police-anim-in" style={{ animationDelay: `${i * 0.035}s` }}>
            <div className="police-result-avatar"><HomeIcon size={18} /></div>
            <div className="police-result-info">
              <strong>{p.label}</strong>
              <span>Propriétaire: {p.ownerName || p.owner || '—'} · ${p.price.toLocaleString()}</span>
            </div>
            {p.coords && (
              <button className="police-btn police-btn-secondary" onClick={() => post('policeTablet:setWaypoint', { x: p.coords!.x, y: p.coords!.y })}>
                <MapPin size={12} /> GPS
              </button>
            )}
          </div>
        ))}
      </div>
    </div>
  );
};

/* =========================================================================
   VEHICLES
   ========================================================================= */
const VehiclesPage: React.FC = () => {
  const [query, setQuery] = useState('');
  const [results, setResults] = useState<OwnedVehicle[]>([]);
  const [loading, setLoading] = useState(false);
  const [isPreview, setIsPreview] = useState(true);

  useEffect(() => {
    (async () => {
      setLoading(true);
      const r = await post('policeTablet:searchVehicles', { query: '' });
      setResults((await r.json()) || []);
      setIsPreview(true);
      setLoading(false);
    })();
  }, []);

  const search = async () => {
    if (!query.trim()) return;
    setLoading(true);
    const r = await post('policeTablet:searchVehicles', { query: query.trim() });
    setResults((await r.json()) || []);
    setIsPreview(false);
    setLoading(false);
  };

  return (
    <div className="police-page">
      <header className="police-page-header">
        <div><h2>Véhicules</h2><p>Recherchez par plaque ou propriétaire.</p></div>
        <div className="police-toolbar">
          <div className="police-search">
            <Search size={14} />
            <input placeholder="Plaque ou nom du propriétaire" value={query} onChange={(e) => setQuery(e.target.value)}
              onKeyDown={(e) => { if (e.key === 'Enter') search(); }} />
          </div>
          <button className="police-btn police-btn-primary" onClick={search}>Rechercher</button>
        </div>
      </header>
      <div className="police-results">
        {loading && <div className="police-loading">Recherche…</div>}
        {!loading && results.length === 0 && <EmptyState icon={<Car size={36} />} title="Aucun véhicule" subtitle="Tapez une plaque ou un nom de propriétaire." />}
        {!loading && isPreview && results.length > 0 && <PreviewLabel text="Véhicules récents" />}
        {results.map((v, i) => (
          <div key={v.plate} className="police-result-card police-anim-in" style={{ animationDelay: `${i * 0.035}s` }}>
            <div className="police-result-avatar"><Car size={18} /></div>
            <div className="police-result-info">
              <strong>{v.label || v.vehicle}</strong>
              <span>Plaque <code>{v.plate}</code> · {v.ownerName || v.owner || '—'} · {v.state === 'out' ? 'En circulation' : 'Au garage'}</span>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};

/* =========================================================================
   CASIER (search by name → see all entries)
   ========================================================================= */
const CasierPage: React.FC<{ penalCode: PenalCode; data: PoliceTabletData }> = ({ penalCode, data }) => {
  const [query, setQuery] = useState('');
  const [results, setResults] = useState<PlayerSummary[]>([]);
  const [selected, setSelected] = useState<PlayerSummary | null>(null);
  const [entries, setEntries] = useState<CasierEntry[]>([]);
  const [loading, setLoading] = useState(false);
  const [showAdd, setShowAdd] = useState(false);
  const [recent, setRecent] = useState<(CasierEntry & { targetIdentifier?: string })[]>([]);
  const [searched, setSearched] = useState(false);

  useEffect(() => {
    (async () => {
      const r = await post('policeTablet:recentCasier', {});
      setRecent((await r.json()) || []);
    })();
  }, []);

  const search = async () => {
    if (!query.trim()) return;
    setLoading(true);
    const r = await post('policeTablet:searchPlayers', { query: query.trim() });
    setResults((await r.json()) || []);
    setSearched(true);
    setLoading(false);
  };

  const loadCasier = async (p: PlayerSummary) => {
    setSelected(p);
    setLoading(true);
    const r = await post('policeTablet:getCasier', { identifier: p.identifier });
    setEntries((await r.json()) || []);
    setLoading(false);
  };

  if (selected) {
    return (
      <div className="police-page">
        <header className="police-page-header">
          <div className="police-details-top">
            <button className="police-btn police-btn-ghost" onClick={() => { setSelected(null); setEntries([]); }}>
              <ArrowLeft size={14} /> Retour
            </button>
            <div>
              <h2>Casier · {selected.firstname} {selected.lastname}</h2>
              <p>ID {selected.idunique} · {entries.length} entrée(s)</p>
            </div>
          </div>
          <button className="police-btn police-btn-primary" onClick={() => setShowAdd(true)}>
            <Plus size={14} /> Nouveau dossier
          </button>
        </header>

        <div className="police-results">
          {loading && <div className="police-loading">Chargement…</div>}
          {!loading && entries.length === 0 && (
            <EmptyState icon={<Scale size={36} />} title="Casier vierge" subtitle="Aucun antécédent n'a été enregistré." />
          )}
          {entries.map(e => (
            <div key={e.id} className="police-casier-full">
              <CasierItem entry={e} />
              {data.isBoss && (
                <button className="police-btn police-btn-danger police-btn-small" onClick={() => post('policeTablet:deleteCasier', { id: e.id })}>
                  <Trash2 size={12} /> Supprimer
                </button>
              )}
            </div>
          ))}
        </div>

        {showAdd && (
          <AddCasierModal
            penalCode={penalCode}
            target={selected}
            onClose={() => setShowAdd(false)}
            onSaved={() => { setShowAdd(false); loadCasier(selected); }}
          />
        )}
      </div>
    );
  }

  return (
    <div className="police-page">
      <header className="police-page-header">
        <div><h2>Casier judiciaire</h2><p>Recherchez un citoyen pour consulter ou enrichir son casier.</p></div>
        <div className="police-toolbar">
          <div className="police-search">
            <Search size={14} />
            <input placeholder="Prénom ou nom" value={query} onChange={(e) => setQuery(e.target.value)}
              onKeyDown={(e) => { if (e.key === 'Enter') search(); }} />
          </div>
          <button className="police-btn police-btn-primary" onClick={search}>Rechercher</button>
        </div>
      </header>
      <div className="police-results">
        {loading && <div className="police-loading">Recherche…</div>}
        {!loading && searched && results.length === 0 && <EmptyState icon={<Scale size={36} />} title="Aucun résultat" subtitle="Tapez un nom pour consulter un casier." />}
        {!loading && !searched && recent.length === 0 && <EmptyState icon={<Scale size={36} />} title="Aucun dossier récent" subtitle="Recherchez un citoyen pour consulter son casier." />}
        {!loading && searched && results.map((r, i) => (
          <button key={r.identifier} className="police-result-card police-anim-in" style={{ animationDelay: `${i * 0.035}s` }} onClick={() => loadCasier(r)}>
            <div className="police-result-avatar"><Scale size={18} /></div>
            <div className="police-result-info">
              <strong>{r.firstname} {r.lastname}</strong>
              <span>ID: {r.idunique}</span>
            </div>
            <ChevronRight size={14} className="police-result-arrow" />
          </button>
        ))}
        {!loading && !searched && recent.length > 0 && <PreviewLabel text="Derniers dossiers" />}
        {!loading && !searched && recent.map((e, i) => (
          <button
            key={e.id}
            className="police-result-card police-anim-in"
            style={{ animationDelay: `${i * 0.035}s` }}
            onClick={() => e.targetIdentifier && loadCasier({
              identifier: e.targetIdentifier, idunique: '', firstname: (e.targetName || '').split(' ')[0] || e.targetName || '',
              lastname: (e.targetName || '').split(' ').slice(1).join(' '), bank: 0, job: '', jobGrade: 0, sex: 'm', dateofbirth: '', phone: '',
            })}
          >
            <div className="police-result-avatar"><Scale size={18} /></div>
            <div className="police-result-info">
              <strong>{e.targetName || 'Inconnu'}</strong>
              <span>Agent #{e.agentMatricule} · {new Date(e.createdAt).toLocaleDateString('fr-FR')}</span>
            </div>
            <div className="police-casier-totals">
              <span className="police-tag police-tag-money">${e.totalAmount}</span>
              {e.totalJail > 0 && <span className="police-tag police-tag-jail">{e.totalJail}s</span>}
            </div>
          </button>
        ))}
      </div>
    </div>
  );
};

/* =========================================================================
   PENAL CODE (boss only) — redesigned
   ========================================================================= */
const PenalCodePage: React.FC<{ penalCode: PenalCode; canEdit: boolean }> = ({ penalCode, canEdit }) => {
  const categories = Object.keys(penalCode);
  const [activeCat, setActiveCat] = useState<string | null>(categories[0] || null);
  const [editing, setEditing] = useState<PenalOffense | null>(null);
  const [creating, setCreating] = useState(false);
  const [showNewCat, setShowNewCat] = useState(false);
  const [newCatName, setNewCatName] = useState('');
  const [search, setSearch] = useState('');

  useEffect(() => {
    if (!activeCat && categories.length > 0) setActiveCat(categories[0]);
    if (activeCat && !penalCode[activeCat] && categories.length > 0) setActiveCat(categories[0]);
  }, [penalCode]);

  const offenses = (penalCode[activeCat || ''] || []).filter(o =>
    !search || o.label.toLowerCase().includes(search.toLowerCase())
  );

  const totalOffenses = Object.values(penalCode).reduce((s, l) => s + l.length, 0);

  const handleCreateCat = () => {
    const name = newCatName.trim();
    if (!name) return;
    setActiveCat(name);
    setNewCatName('');
    setShowNewCat(false);
    setCreating(true);
  };

  return (
    <div className="police-page police-page-penal">
      <header className="police-page-header police-penal-hero">
        <div>
          <span className="police-eyebrow">{canEdit ? 'Administration' : 'Consultation'}</span>
          <h2>Code pénal</h2>
          <p>{totalOffenses} infractions · {categories.length} catégories</p>
        </div>
        {canEdit && (
          <button className="police-btn police-btn-primary" onClick={() => setCreating(true)} disabled={!activeCat}>
            <Plus size={14} /> Nouvelle infraction
          </button>
        )}
      </header>

      <div className="police-penal-layout">
        <aside className="police-penal-cats">
          <div className="police-penal-cats-head">
            <span>Catégories</span>
            {canEdit && (
              <button className="police-icon-btn" onClick={() => setShowNewCat(v => !v)} title="Nouvelle catégorie">
                <FolderPlus size={14} />
              </button>
            )}
          </div>
          {canEdit && showNewCat && (
            <div className="police-penal-newcat">
              <input
                autoFocus placeholder="Nom de la catégorie"
                value={newCatName} onChange={e => setNewCatName(e.target.value)}
                onKeyDown={e => e.key === 'Enter' && handleCreateCat()}
              />
              <button className="police-icon-btn" onClick={handleCreateCat}><Save size={12} /></button>
              <button className="police-icon-btn" onClick={() => { setShowNewCat(false); setNewCatName(''); }}><X size={12} /></button>
            </div>
          )}
          {categories.length === 0 && !showNewCat && (
            <div className="police-penal-empty-cats">
              Aucune catégorie. Créez-en une pour commencer.
            </div>
          )}
          {categories.map(cat => (
            <button
              key={cat}
              className={`police-penal-cat ${activeCat === cat ? 'active' : ''}`}
              onClick={() => setActiveCat(cat)}
            >
              <span>{cat}</span>
              <em>{penalCode[cat].length}</em>
            </button>
          ))}
        </aside>

        <section className="police-penal-main">
          {activeCat ? (
            <>
              <div className="police-penal-toolbar">
                <div>
                  <h3>{activeCat}</h3>
                  <span>{penalCode[activeCat]?.length || 0} infractions</span>
                </div>
                <div className="police-search police-penal-search">
                  <Search size={14} />
                  <input
                    placeholder="Rechercher une infraction…"
                    value={search} onChange={e => setSearch(e.target.value)}
                  />
                </div>
              </div>

              <div className="police-penal-grid">
                {offenses.length === 0 ? (
                  <EmptyState
                    icon={<BookOpen size={28} />}
                    title="Aucune infraction"
                    subtitle={search ? "Aucun résultat pour cette recherche." : "Cliquez sur « Nouvelle infraction » pour en ajouter une."}
                  />
                ) : offenses.map((o, i) => (
                  <article key={o.id} className="police-penal-card police-anim-in" style={{ animationDelay: `${i * 0.03}s` }}>
                    <div className="police-penal-card-body">
                      <strong>{o.label}</strong>
                      <div className="police-penal-card-meta">
                        <span> ${o.price.toLocaleString()}</span>
                        {o.jail > 0 && <span>{o.jail}s</span>}
                      </div>
                    </div>
                    {canEdit && (
                      <div className="police-penal-card-actions">
                        <button className="police-icon-btn" onClick={() => setEditing(o)}><Edit2 size={12} /></button>
                        <button className="police-icon-btn police-icon-danger" onClick={() => post('policeTablet:deletePenal', { id: o.id })}><Trash2 size={12} /></button>
                      </div>
                    )}
                  </article>
                ))}
              </div>
            </>
          ) : (
            <EmptyState
              icon={<BookOpen size={28} />}
              title="Sélectionnez une catégorie"
              subtitle="Choisissez ou créez une catégorie pour gérer les infractions."
            />
          )}
        </section>
      </div>

      {canEdit && (editing || creating) && activeCat && (
        <PenalEditModal
          offense={editing}
          category={activeCat}
          categories={categories}
          onClose={() => { setEditing(null); setCreating(false); }}
        />
      )}
    </div>
  );
};

const PenalEditModal: React.FC<{
  offense: PenalOffense | null; category: string; categories: string[]; onClose: () => void;
}> = ({ offense, category, categories, onClose }) => {
  const isEdit = !!offense;
  const [label, setLabel] = useState(offense?.label || '');
  const [price, setPrice] = useState(offense?.price?.toString() || '0');
  const [jail, setJail] = useState(offense?.jail?.toString() || '0');
  const [cat, setCat] = useState(category);

  const save = () => {
    if (!label.trim() || !cat.trim()) return;
    if (isEdit) {
      post('policeTablet:updatePenal', { id: offense!.id, category: cat, label: label.trim(), price: parseInt(price) || 0, jail: parseInt(jail) || 0 });
    } else {
      post('policeTablet:addPenal', { category: cat, label: label.trim(), price: parseInt(price) || 0, jail: parseInt(jail) || 0 });
    }
    onClose();
  };

  return (
    <div className="police-modal-overlay" onClick={onClose}>
      <div className="police-modal police-modal-edit" onClick={e => e.stopPropagation()}>
        <header className="police-modal-head">
          <div>
            <span className="police-eyebrow">{isEdit ? 'Modification' : 'Création'}</span>
            <h3>{isEdit ? 'Modifier l\'infraction' : 'Nouvelle infraction'}</h3>
          </div>
          <button className="police-icon-btn" onClick={onClose}><X size={14} /></button>
        </header>

        <div className="police-modal-form">
          <label>
            <span>Catégorie</span>
            <input list="penal-cats" value={cat} onChange={e => setCat(e.target.value)} />
            <datalist id="penal-cats">
              {categories.map(c => <option key={c} value={c} />)}
            </datalist>
          </label>
          <label>
            <span>Libellé</span>
            <input autoFocus value={label} onChange={e => setLabel(e.target.value)} placeholder="Ex: Excès de vitesse" />
          </label>
          <div className="police-modal-form-row">
            <label>
              <span>Amende ($)</span>
              <input type="number" value={price} onChange={e => setPrice(e.target.value)} />
            </label>
            <label>
              <span>Prison (s)</span>
              <input type="number" value={jail} onChange={e => setJail(e.target.value)} />
            </label>
          </div>
        </div>

        <footer className="police-modal-foot">
          <button className="police-btn" onClick={onClose}>Annuler</button>
          <button className="police-btn police-btn-primary" onClick={save}>
            <Save size={13} /> {isEdit ? 'Enregistrer' : 'Créer'}
          </button>
        </footer>
      </div>
    </div>
  );
};

/* =========================================================================
   RADIO CODES (boss only)
   ========================================================================= */
const RadioCodesPage: React.FC<{ radioCodes: RadioCode[]; canEdit: boolean }> = ({ radioCodes, canEdit }) => {
  const [editing, setEditing] = useState<RadioCode | null>(null);
  const [creating, setCreating] = useState(false);
  const [search, setSearch] = useState('');
  const [filter, setFilter] = useState<'all' | 'urgent' | 'normal'>('all');

  const filtered = radioCodes.filter(rc => {
    if (search) {
      const s = search.toLowerCase();
      if (!rc.code.toLowerCase().includes(s) && !rc.label.toLowerCase().includes(s)) return false;
    }
    if (filter === 'urgent' && rc.priority !== 1) return false;
    if (filter === 'normal' && rc.priority !== 0) return false;
    return true;
  });

  const urgentCount = radioCodes.filter(rc => rc.priority === 1).length;

  return (
    <div className="police-page police-page-radio">
      <header className="police-page-header police-radio-hero">
        <div>
          <span className="police-eyebrow">Communications</span>
          <h2>Codes Radio</h2>
          <p>{radioCodes.length} codes · {urgentCount} prioritaires</p>
        </div>
        {canEdit && (
          <button className="police-btn police-btn-primary" onClick={() => setCreating(true)}>
            <Plus size={14} /> Nouveau code
          </button>
        )}
      </header>

      <div className="police-radio-toolbar">
        <div className="police-search police-radio-search">
          <Search size={14} />
          <input placeholder="Rechercher un code ou libellé…" value={search} onChange={e => setSearch(e.target.value)} />
        </div>
        <div className="police-radio-filters">
          <button className={filter === 'all' ? 'active' : ''} onClick={() => setFilter('all')}>Tous</button>
          <button className={filter === 'urgent' ? 'active' : ''} onClick={() => setFilter('urgent')}>
            <AlertOctagon size={11} /> Prioritaires
          </button>
          <button className={filter === 'normal' ? 'active' : ''} onClick={() => setFilter('normal')}>Standards</button>
        </div>
      </div>

      <div className="police-radio-grid">
        {filtered.length === 0 ? (
          <EmptyState
            icon={<Radio size={28} />}
            title="Aucun code"
            subtitle={search || filter !== 'all' ? "Aucun résultat avec ces filtres." : "Ajoutez un premier code radio."}
          />
        ) : filtered.map((rc, i) => (
          <article key={rc.id} className={`police-radio-card police-anim-in ${rc.priority === 1 ? 'urgent' : ''}`} style={{ animationDelay: `${i * 0.03}s` }}>
            <div className="police-radio-tag">{rc.code}</div>
            <div className="police-radio-card-body">
              <strong>{rc.label}</strong>
              {rc.priority === 1 && <span className="police-radio-badge"><AlertOctagon size={10} /> Prioritaire</span>}
            </div>
            {canEdit && (
              <div className="police-radio-card-actions">
                <button className="police-icon-btn" onClick={() => setEditing(rc)}><Edit2 size={12} /></button>
                <button className="police-icon-btn police-icon-danger" onClick={() => post('policeTablet:deleteRadio', { id: rc.id })}><Trash2 size={12} /></button>
              </div>
            )}
          </article>
        ))}
      </div>

      {canEdit && (editing || creating) && (
        <RadioEditModal
          code={editing}
          onClose={() => { setEditing(null); setCreating(false); }}
        />
      )}
    </div>
  );
};

const RadioEditModal: React.FC<{ code: RadioCode | null; onClose: () => void }> = ({ code, onClose }) => {
  const isEdit = !!code;
  const [codeStr, setCodeStr] = useState(code?.code || '10-');
  const [label, setLabel] = useState(code?.label || '');
  const [priority, setPriority] = useState(code?.priority || 0);

  const save = () => {
    if (!codeStr.trim() || !label.trim()) return;
    if (isEdit) {
      post('policeTablet:updateRadio', { id: code!.id, code: codeStr.trim(), label: label.trim(), priority });
    } else {
      post('policeTablet:addRadio', { code: codeStr.trim(), label: label.trim(), priority });
    }
    onClose();
  };

  return (
    <div className="police-modal-overlay" onClick={onClose}>
      <div className="police-modal police-modal-edit" onClick={e => e.stopPropagation()}>
        <header className="police-modal-head">
          <div>
            <span className="police-eyebrow">{isEdit ? 'Modification' : 'Création'}</span>
            <h3>{isEdit ? 'Modifier le code radio' : 'Nouveau code radio'}</h3>
          </div>
          <button className="police-icon-btn" onClick={onClose}><X size={14} /></button>
        </header>

        <div className="police-modal-form">
          <label>
            <span>Code</span>
            <input autoFocus value={codeStr} onChange={e => setCodeStr(e.target.value)} placeholder="10-1" />
          </label>
          <label>
            <span>Libellé</span>
            <input value={label} onChange={e => setLabel(e.target.value)} placeholder="Ex: Mauvaise réception radio" />
          </label>
          <label className="police-modal-toggle">
            <span>Prioritaire</span>
            <button
              className={`police-toggle ${priority === 1 ? 'on' : ''}`}
              onClick={() => setPriority(p => p === 1 ? 0 : 1)}
              type="button"
            >
              <div className="police-toggle-dot" />
            </button>
          </label>
        </div>

        <footer className="police-modal-foot">
          <button className="police-btn" onClick={onClose}>Annuler</button>
          <button className="police-btn police-btn-primary" onClick={save}>
            <Save size={13} /> {isEdit ? 'Enregistrer' : 'Créer'}
          </button>
        </footer>
      </div>
    </div>
  );
};

const EmptyState: React.FC<{ icon: React.ReactNode; title: string; subtitle: string }> = ({ icon, title, subtitle }) => (
  <div className="police-empty">
    <div className="police-empty-icon">{icon}</div>
    <h3>{title}</h3>
    <p>{subtitle}</p>
  </div>
);

const PreviewLabel: React.FC<{ text: string }> = ({ text }) => (
  <div className="police-preview-label">
    <span>{text}</span>
    <em>Aperçu</em>
  </div>
);

export default PoliceTablet;
