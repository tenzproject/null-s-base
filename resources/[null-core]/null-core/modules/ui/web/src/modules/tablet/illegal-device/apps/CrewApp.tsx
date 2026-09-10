import React, { useState, useEffect, useCallback, useMemo } from 'react';
import { MarketData } from '../types';
import TerritoriesView from './TerritoriesView';
import ActionsView from './ActionsView';

const Res = () => 'null-core';
const post = <T = any>(event: string, body: any = {}): Promise<T> =>
  fetch(`https://${Res()}/${event}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  }).then(r => r.json()).catch(() => ({} as any));

// ============================================================================
// Types
// ============================================================================
interface CrewMember {
  idunique: string;
  firstname: string;
  lastname: string;
  grade: number;
  gradeLabel: string;
  online: boolean;
}
interface CrewGrade {
  grade: number;
  name: string;
  label: string;
}
interface CrewMission {
  id: string;
  label: string;
  description: string;
  category?: string;
  xp?: number;
  objective?: number;
  progress?: number;
  completed?: boolean;
  claimed?: boolean;
  acceptedBy?: string;
}
interface CrewData {
  mode?: 'createGroup';
  groupCreation?: {
    enabled: boolean;
    price: number;
    minNameLength: number;
    maxNameLength: number;
    minLabelLength: number;
    maxLabelLength: number;
  };
  gangname?: string;
  ganglabel?: string;
  gangcolor?: string;
  level?: number;
  xp?: number;
  requiredXP?: number;
  maxLevel?: number;
  memberCount?: number;
  maxMembers?: number;
  maxRanks?: number;
  members?: CrewMember[];
  grades?: CrewGrade[];
  missions?: { daily: CrewMission[]; weekly: CrewMission[] };
  isBoss?: boolean;
  playerGrade?: number;
  playerGradeName?: string;
  ownedTerritories?: number;
  blackmarket?: MarketData | null;
}

type Section = 'home' | 'members' | 'ranks' | 'missions' | 'territories' | 'actions';

interface CrewAppProps {
  onBack: () => void;
  onOpenMarket: () => void;
}

// ============================================================================
// Mock placeholder missions for the missions tab (display-only per spec)
// ============================================================================
const PLACEHOLDER_MISSIONS = [
  { id: 'm1', label: 'Convoi de drogue', description: 'Escortez un convoi de marchandise sans être intercepté.', tier: 'Quotidien', reward: '15 000 — 25 000$', xp: 120 },
  { id: 'm2', label: 'Vol de cargaison', description: 'Détournez une cargaison portuaire avant l\'aube.', tier: 'Quotidien', reward: '20 000 — 35 000$', xp: 180 },
  { id: 'm3', label: 'Braquage de fourgon', description: 'Interceptez un fourgon blindé sur l\'autoroute.', tier: 'Hebdo', reward: '60 000 — 90 000$', xp: 400 },
  { id: 'm4', label: 'Course de territoire', description: 'Imposez votre crew sur un territoire rival.', tier: 'Hebdo', reward: '40 000 — 70 000$', xp: 320 },
  { id: 'm5', label: 'Contrebande maritime', description: 'Récupérez un container coulé près des docks.', tier: 'Spéciale', reward: '80 000 — 120 000$', xp: 500 },
  { id: 'm6', label: 'Cambriolage VIP', description: 'Pillez la villa d\'un homme d\'affaires en vacances.', tier: 'Spéciale', reward: '100 000 — 150 000$', xp: 600 },
];

// ============================================================================
// Component
// ============================================================================
const CrewApp: React.FC<CrewAppProps> = ({ onBack, onOpenMarket }) => {
  const [section, setSection] = useState<Section>('home');
  const [data, setData] = useState<CrewData | null>(null);
  const [loading, setLoading] = useState(true);

  const refresh = useCallback(async () => {
    setLoading(true);
    const r = await post<CrewData>('illegalDevice:crew:getData');
    setData(r || null);
    setLoading(false);
  }, []);

  useEffect(() => { refresh(); }, [refresh]);

  // Listen for "groupCreated" event to refresh
  useEffect(() => {
    const onMsg = (e: MessageEvent) => {
      if (e.data?.action === 'illegalDevice:crew:groupCreated') {
        setSection('home');
        refresh();
      }
    };
    window.addEventListener('message', onMsg);
    return () => window.removeEventListener('message', onMsg);
  }, [refresh]);

  const isCreateMode = data?.mode === 'createGroup';

  return (
    <div className="idev-app-view idev-crew">
      <div className="idev-app-bar">
        <button className="idev-back" onClick={() => (section === 'home' ? onBack() : setSection('home'))}>
          ‹ {section === 'home' ? 'Accueil' : 'Crew'}
        </button>
        <div className="idev-app-title">
          <span>{isCreateMode ? 'Organisation' : (data?.ganglabel || 'Crew')}</span>
          <small>{isCreateMode ? 'Aucune organisation' : sectionTitle(section)}</small>
        </div>
        <div style={{ width: 80 }} />
      </div>

      {loading && <div className="idev-empty">Chargement…</div>}

      {!loading && isCreateMode && data?.groupCreation && (
        <CreateCrewView cfg={data.groupCreation} onCreated={refresh} />
      )}

      {!loading && !isCreateMode && data && (
        <>
          {section === 'home' && <CrewHome data={data} onNavigate={setSection} onOpenMarket={onOpenMarket} />}
          {section === 'members' && <CrewMembers data={data} onRefresh={refresh} />}
          {section === 'ranks' && <CrewRanks data={data} onRefresh={refresh} />}
          {section === 'missions' && <CrewMissions />}
          {section === 'territories' && <TerritoriesView />}
          {section === 'actions' && <ActionsView isBoss={!!data.isBoss} />}
        </>
      )}
    </div>
  );
};

const sectionTitle = (s: Section) =>
  s === 'home' ? 'Tableau de bord' :
    s === 'members' ? 'Membres' :
      s === 'ranks' ? 'Rangs & permissions' :
        s === 'missions' ? 'Missions' :
          s === 'territories' ? 'Territoires' :
            s === 'actions' ? 'Actions' :
              '';

// ============================================================================
// CreateCrewView (no crew yet — pay 500k dirty cash to create)
// ============================================================================
const ADVANTAGES = [
  { title: 'Missions hebdo & spéciales', desc: 'Débloque un flux de contrats illégaux dédiés à ton crew.' },
  { title: 'Revendication de territoire', desc: 'Capture des zones de la map et perçois des revenus passifs.' },
  { title: 'Coffre & blanchiment', desc: 'Stockage commun, marché noir et blanchiment d\'argent sale.' },
  { title: 'Hiérarchie personnalisable', desc: 'Crée tes rangs, gère les permissions, recrute en jeu.' },
];

interface CreateCrewViewProps {
  cfg: NonNullable<CrewData['groupCreation']>;
  onCreated: () => void;
}

const CreateCrewView: React.FC<CreateCrewViewProps> = ({ cfg, onCreated }) => {
  const [name, setName] = useState('');
  const [label, setLabel] = useState('');
  const [errors, setErrors] = useState<{ nameError?: string | null; labelError?: string | null }>({});
  const [submitting, setSubmitting] = useState(false);

  // Live validation (debounced)
  useEffect(() => {
    if (!name && !label) { setErrors({}); return; }
    const t = setTimeout(async () => {
      const r = await post<{ nameError?: string; labelError?: string }>(
        'illegalDevice:crew:validateGroup',
        { groupName: name, groupLabel: label }
      );
      setErrors(r || {});
    }, 250);
    return () => clearTimeout(t);
  }, [name, label]);

  const canSubmit =
    name.length >= cfg.minNameLength && name.length <= cfg.maxNameLength &&
    label.length >= cfg.minLabelLength && label.length <= cfg.maxLabelLength &&
    !errors.nameError && !errors.labelError && !submitting;

  const onSubmit = async () => {
    if (!canSubmit) return;
    setSubmitting(true);
    await post('illegalDevice:crew:createGroup', { groupName: name, groupLabel: label });
    setTimeout(() => { onCreated(); setSubmitting(false); }, 1200);
  };

  return (
    <div className="idev-crew-create">
      <div className="idev-crew-create-hero">
        <span className="idev-crew-create-eyebrow">Petite frappe</span>
        <h2>Crée ta première organisation</h2>
        <p>
          Monte ton crew, recrute, prends des contrats et étends ton emprise sur la ville.
          La création coûte <strong>${cfg.price.toLocaleString()}</strong> en argent sale.
        </p>
      </div>

      <div className="idev-crew-create-grid">
        <div className="idev-crew-advantages">
          {ADVANTAGES.map(a => (
            <div key={a.title} className="idev-crew-advantage">
              <span className="idev-crew-adv-dot" />
              <div>
                <div className="idev-crew-adv-title">{a.title}</div>
                <div className="idev-crew-adv-desc">{a.desc}</div>
              </div>
            </div>
          ))}
        </div>

        <div className="idev-crew-form">
          <label className="idev-crew-field">
            <span>Nom interne</span>
            <input
              value={name}
              onChange={e => setName(e.target.value.toLowerCase().replace(/[^a-z0-9_]/g, '').slice(0, cfg.maxNameLength))}
              placeholder="ex: ballas"
              maxLength={cfg.maxNameLength}
            />
            <small>{cfg.minNameLength}–{cfg.maxNameLength} caractères, lettres/chiffres/_</small>
            {errors.nameError && <em className="idev-crew-err">{errors.nameError}</em>}
          </label>

          <label className="idev-crew-field">
            <span>Label affiché</span>
            <input
              value={label}
              onChange={e => setLabel(e.target.value.slice(0, cfg.maxLabelLength))}
              placeholder="ex: Les Ballas"
              maxLength={cfg.maxLabelLength}
            />
            <small>{cfg.minLabelLength}–{cfg.maxLabelLength} caractères</small>
            {errors.labelError && <em className="idev-crew-err">{errors.labelError}</em>}
          </label>

          <button className="idev-card-cta idev-crew-create-cta" onClick={onSubmit} disabled={!canSubmit}>
            {submitting ? 'Création…' : `Créer pour $${cfg.price.toLocaleString()}`}
          </button>
        </div>
      </div>
    </div>
  );
};

// ============================================================================
// CrewHome — Bento grid of categories
// ============================================================================
interface CrewHomeProps {
  data: CrewData;
  onNavigate: (s: Section) => void;
  onOpenMarket: () => void;
}

const CrewHome: React.FC<CrewHomeProps> = ({ data, onNavigate, onOpenMarket }) => {
  const marketUnlocked = !!data.blackmarket?.unlocked;
  const xpPct = useMemo(() => {
    if (!data.requiredXP || !data.xp) return 0;
    return Math.min(100, (data.xp / data.requiredXP) * 100);
  }, [data.xp, data.requiredXP]);

  return (
    <div className="idev-crew-home">
      <div className="idev-crew-overview">
        <div>
          <div className="idev-crew-overview-eyebrow">Niveau {data.level || 1} · {data.memberCount || 0}/{data.maxMembers || 0} membres</div>
          <h2 className="idev-crew-overview-name">{data.ganglabel}</h2>
        </div>
        <div className="idev-crew-xp">
          <div className="idev-crew-xp-bar"><div style={{ width: `${xpPct}%`, background: data.gangcolor || '#e74c3c' }} /></div>
          <span>{(data.xp || 0).toLocaleString()} / {(data.requiredXP || 0).toLocaleString()} XP</span>
        </div>
      </div>

      <div className="idev-bento">
        <button
          className="idev-bento-cell idev-bento-large"
          onClick={() => onNavigate('missions')}
          style={{ ['--cell-bg' as any]: 'url(nui://null-cache/images/illegaltablet/crew_missions.webp)' }}
        >
          <span className="idev-bento-label">Missions</span>
        </button>

        <button
          className="idev-bento-cell idev-bento-tall"
          onClick={() => onNavigate('members')}
          style={{ ['--cell-bg' as any]: 'url(nui://null-cache/images/illegaltablet/crew_members.webp)' }}
        >
          <span className="idev-bento-label">Membres</span>
        </button>

        <button
          className="idev-bento-cell"
          onClick={() => onNavigate('ranks')}
          style={{ ['--cell-bg' as any]: 'url(nui://null-cache/images/illegaltablet/crew_ranks.webp)' }}
        >
          <span className="idev-bento-label">Rangs</span>
        </button>

        <button
          className="idev-bento-cell idev-bento-actions"
          onClick={() => onNavigate('actions')}
          style={{ ['--cell-bg' as any]: 'url(nui://null-cache/images/illegaltablet/crew_actions.webp)' }}
        >
          <span className="idev-bento-label">Actions</span>
          <span className="idev-bento-sub">Joueur le plus proche</span>
        </button>

        <button
          className={`idev-bento-cell idev-bento-wide idev-bento-market${marketUnlocked ? '' : ' idev-bento-disabled'}`}
          onClick={() => marketUnlocked && onOpenMarket()}
          disabled={!marketUnlocked}
          style={{ ['--cell-bg' as any]: 'url(nui://null-cache/images/illegaltablet/crew_market.webp)' }}
        >
          <span className="idev-bento-label">Marché noir</span>
          {!marketUnlocked && <span className="idev-bento-soon">Verrouillé</span>}
        </button>

        <button
          className="idev-bento-cell idev-bento-wide idev-bento-territories"
          onClick={() => onNavigate('territories')}
          style={{ ['--cell-bg' as any]: 'url(nui://null-cache/images/illegaltablet/crew_territoires.webp)' }}
        >
          <span className="idev-bento-label">Territoires</span>
          {(data.ownedTerritories ?? 0) > 0 && (
            <span className="idev-bento-badge">{data.ownedTerritories}</span>
          )}
        </button>
      </div>
    </div>
  );
};

// ============================================================================
// CrewMembers
// ============================================================================
const CrewMembers: React.FC<{ data: CrewData; onRefresh: () => void }> = ({ data, onRefresh }) => {
  const [selected, setSelected] = useState<CrewMember | null>(null);
  const isBoss = !!data.isBoss;

  const sortedGrades = useMemo(
    () => (data.grades || []).slice().sort((a, b) => b.grade - a.grade),
    [data.grades]
  );

  const promote = async () => {
    if (!selected) return;
    const idx = sortedGrades.findIndex(g => g.grade === selected.grade);
    const next = sortedGrades[idx - 1];
    if (!next) return;
    await post('illegalDevice:crew:changeMemberGrade', { idunique: selected.idunique, newGrade: next.grade });
    setSelected(null);
    onRefresh();
  };
  const demote = async () => {
    if (!selected) return;
    const idx = sortedGrades.findIndex(g => g.grade === selected.grade);
    const next = sortedGrades[idx + 1];
    if (!next) return;
    await post('illegalDevice:crew:changeMemberGrade', { idunique: selected.idunique, newGrade: next.grade });
    setSelected(null);
    onRefresh();
  };
  const kick = async () => {
    if (!selected) return;
    await post('illegalDevice:crew:kickMember', { idunique: selected.idunique });
    setSelected(null);
    onRefresh();
  };
  const recruitNearby = async () => {
    await post('illegalDevice:crew:recruitNearest');
  };

  return (
    <div className="idev-crew-section">
      <div className="idev-crew-toolbar">
        <div className="idev-crew-meta-line">
          {(data.memberCount || 0)}/{data.maxMembers || 0} membres
        </div>
        {isBoss && (
          <button className="idev-crew-tool-btn" onClick={recruitNearby}>+ Recruter à proximité</button>
        )}
      </div>

      <div className="idev-crew-members">
        {(data.members || []).map(m => (
          <button
            key={m.idunique}
            className={`idev-crew-member${selected?.idunique === m.idunique ? ' is-selected' : ''}`}
            onClick={() => isBoss ? setSelected(s => s?.idunique === m.idunique ? null : m) : null}
            disabled={!isBoss}
          >
            <span className={`idev-crew-status${m.online ? ' is-on' : ''}`} />
            <div className="idev-crew-member-info">
              <strong>{m.firstname} {m.lastname}</strong>
              <small>{m.gradeLabel}</small>
            </div>
          </button>
        ))}
        {(!data.members || data.members.length === 0) && (
          <div className="idev-empty">Aucun membre</div>
        )}
      </div>

      {selected && isBoss && (
        <div className="idev-crew-action-bar">
          <span>{selected.firstname} {selected.lastname} · {selected.gradeLabel}</span>
          <div>
            <button className="idev-crew-tool-btn" onClick={promote}>Promouvoir</button>
            <button className="idev-crew-tool-btn" onClick={demote}>Rétrograder</button>
            <button className="idev-crew-tool-btn idev-danger" onClick={kick}>Exclure</button>
          </div>
        </div>
      )}
    </div>
  );
};

// ============================================================================
// CrewRanks
// ============================================================================
const CrewRanks: React.FC<{ data: CrewData; onRefresh: () => void }> = ({ data, onRefresh }) => {
  const [newLabel, setNewLabel] = useState('');
  const isBoss = !!data.isBoss;
  const grades = (data.grades || []).slice().sort((a, b) => b.grade - a.grade);

  const addGrade = async () => {
    if (!newLabel || !isBoss) return;
    await post('illegalDevice:crew:addGrade', { label: newLabel });
    setNewLabel('');
    onRefresh();
  };
  const removeGrade = async (g: CrewGrade) => {
    if (!isBoss) return;
    await post('illegalDevice:crew:removeGrade', { gradeName: g.name, gradePos: g.grade });
    onRefresh();
  };

  return (
    <div className="idev-crew-section">
      <div className="idev-crew-toolbar">
        <div className="idev-crew-meta-line">
          {grades.length}/{data.maxRanks || 0} rangs
        </div>
        {isBoss && (
          <div className="idev-crew-rank-add">
            <input
              value={newLabel}
              onChange={e => setNewLabel(e.target.value.slice(0, 24))}
              placeholder="Nouveau rang"
            />
            <button className="idev-crew-tool-btn" onClick={addGrade} disabled={!newLabel}>Ajouter</button>
          </div>
        )}
      </div>

      <div className="idev-crew-ranks">
        {grades.map(g => (
          <div key={g.grade} className="idev-crew-rank">
            <div className="idev-crew-rank-info">
              <span className="idev-crew-rank-num">#{g.grade}</span>
              <strong>{g.label}</strong>
              <small>{g.name}</small>
            </div>
            {isBoss && g.name !== 'boss' && g.name !== 'recrue' && (
              <button className="idev-crew-tool-btn idev-danger" onClick={() => removeGrade(g)}>Supprimer</button>
            )}
          </div>
        ))}
      </div>
    </div>
  );
};

// ============================================================================
// CrewMissions
// ============================================================================
const CrewMissions: React.FC = () => {
  const [launching, setLaunching] = useState(false);

  const startFourgon = async () => {
    if (launching) return;
    setLaunching(true);
    await post('illegalDevice:crew:startMission', { type: 'fourgon' });
    setLaunching(false);
  };

  return (
    <div className="idev-crew-section">
      <div className="idev-cards idev-crew-missions">
        {PLACEHOLDER_MISSIONS.map(m => {
          const isFourgon = m.id === 'm3';
          return (
            <div key={m.id} className={`idev-card${isFourgon ? ' idev-card-hard' : ''}`}>
              <div className="idev-card-head">
                <span className="idev-card-label">{m.label}</span>
                <span className="idev-card-dist">{m.tier}</span>
              </div>
              <p className="idev-card-desc">{m.description}</p>
              <div className="idev-card-meta">
                <div>
                  <span className="idev-meta-k">Récompense</span>
                  <span className="idev-meta-v">{m.reward}</span>
                </div>
                <div>
                  <span className="idev-meta-k">XP</span>
                  <span className="idev-meta-v">+{m.xp}</span>
                </div>
              </div>
              {isFourgon ? (
                <button className="idev-card-cta" onClick={startFourgon} disabled={launching}>
                  {launching ? 'Lancement…' : 'Démarrer'}
                </button>
              ) : (
                <button className="idev-card-cta" disabled>Bientôt disponible</button>
              )}
            </div>
          );
        })}
      </div>
    </div>
  );
};

export default CrewApp;
