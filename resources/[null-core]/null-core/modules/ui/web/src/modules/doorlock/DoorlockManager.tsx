import React, { useState, useEffect, useCallback, useMemo } from 'react';
import {
  X, Plus, Lock, Unlock, Pencil, Trash2, MapPin, KeyRound,
  Briefcase, ShieldCheck, Hash, DoorClosed, Crosshair, Check, ArrowLeft,
} from 'lucide-react';
import { generateAccentVars } from '@/utils/accentColors';
import { DoorlockManagerProps, EditorDoor, DoorPhysical, JobPermissionRow } from './types';
import './DoorlockManager.css';

const GetParentResourceName = () => 'null-core';

const nui = async (event: string, data: Record<string, any> = {}) => {
  try {
    const resp = await fetch(`https://${GetParentResourceName()}/${event}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data),
    });
    return await resp.json();
  } catch {
    return null;
  }
};

const ADMIN_RANKS = ['', 'admin', 'superadmin', 'responsable', 'fondateur'];

type View = 'list' | 'form';

interface FormState {
  id: number | null;
  label: string;
  doors: DoorPhysical[];
  jobs: JobPermissionRow[];
  adminRank: string;
  code: string;
  items: string;       // CSV
  lockpick: boolean;
  autolock: number;
  locked: boolean;
}

const emptyForm = (): FormState => ({
  id: null,
  label: '',
  doors: [],
  jobs: [],
  adminRank: '',
  code: '',
  items: '',
  lockpick: true,
  autolock: 0,
  locked: true,
});

const DoorlockManager: React.FC<DoorlockManagerProps> = ({ primaryColor = '#4A90E2' }) => {
  const [open, setOpen] = useState(false);
  const [view, setView] = useState<View>('list');
  const [doors, setDoors] = useState<EditorDoor[]>([]);
  const [form, setForm] = useState<FormState>(emptyForm());
  const [selecting, setSelecting] = useState(false);
  const [selCount, setSelCount] = useState(0);

  const accentVars = useMemo(
    () => generateAccentVars('--dlm-accent', primaryColor),
    [primaryColor]
  );

  // ── NUI message handler ──────────────────────────────────────────────────
  useEffect(() => {
    const handler = (e: MessageEvent) => {
      const msg = e.data || {};
      if (!msg.type || typeof msg.type !== 'string' || !msg.type.startsWith('doorlock:')) return;

      switch (msg.type) {
        case 'doorlock:open':
          setDoors(Array.isArray(msg.doors) ? msg.doors : []);
          setView('list');
          setSelecting(false);
          setOpen(true);
          break;
        case 'doorlock:close':
          setOpen(false);
          setSelecting(false);
          break;
        case 'doorlock:selectionStart':
          setSelecting(true);
          break;
        case 'doorlock:selectionUpdate':
          setSelCount(msg.count || 0);
          break;
        case 'doorlock:selectionDone':
          setSelecting(false);
          if (Array.isArray(msg.doors) && msg.doors.length > 0) {
            setForm(prev => ({ ...prev, doors: msg.doors }));
          }
          break;
      }
    };
    window.addEventListener('message', handler);
    return () => window.removeEventListener('message', handler);
  }, []);

  // ── ESC closes ───────────────────────────────────────────────────────────
  useEffect(() => {
    if (!open) return;
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape' && !selecting) {
        e.preventDefault();
        handleClose();
      }
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [open, selecting]);

  const handleClose = useCallback(() => {
    nui('doorlock:close');
    setOpen(false);
  }, []);

  // ── List actions ─────────────────────────────────────────────────────────
  const startCreate = () => {
    setForm(emptyForm());
    setView('form');
  };

  const startEdit = (d: EditorDoor) => {
    const jobs: JobPermissionRow[] = Object.entries(d.groups || {}).map(([name, grade]) => ({
      name,
      grade: Number(grade) || 0,
    }));
    setForm({
      id: d.id,
      label: d.label || '',
      doors: d.doors || [],
      jobs,
      adminRank: d.adminRank || '',
      code: d.code || '',
      items: (d.items || []).join(', '),
      lockpick: d.lockpick !== false,
      autolock: d.autolock || 0,
      locked: d.locked !== false,
    });
    setView('form');
  };

  const deleteDoor = async (id: number) => {
    const res = await nui('doorlock:delete', { id });
    if (res?.ok) setDoors(prev => prev.filter(d => d.id !== id));
  };

  const teleport = (d: EditorDoor) => {
    const c = d.doors?.[0];
    if (c) nui('doorlock:teleport', { x: c.x, y: c.y, z: c.z });
  };

  // ── Selection (visual, in-world) ─────────────────────────────────────────
  const startSelection = () => {
    nui('doorlock:startSelection', { doors: form.doors });
  };

  // ── Form helpers ─────────────────────────────────────────────────────────
  const addJob = () => setForm(p => ({ ...p, jobs: [...p.jobs, { name: '', grade: 0 }] }));
  const updateJob = (i: number, patch: Partial<JobPermissionRow>) =>
    setForm(p => ({ ...p, jobs: p.jobs.map((j, idx) => (idx === i ? { ...j, ...patch } : j)) }));
  const removeJob = (i: number) =>
    setForm(p => ({ ...p, jobs: p.jobs.filter((_, idx) => idx !== i) }));

  const buildPayload = () => {
    const groups: Record<string, number> = {};
    form.jobs.forEach(j => {
      if (j.name.trim()) groups[j.name.trim()] = Number(j.grade) || 0;
    });
    const items = form.items
      .split(',')
      .map(s => s.trim())
      .filter(Boolean);
    return {
      id: form.id,
      label: form.label.trim() || 'Porte',
      doors: form.doors,
      groups,
      items,
      code: form.code.trim(),
      adminRank: form.adminRank,
      lockpick: form.lockpick,
      autolock: form.autolock > 0 ? form.autolock : null,
      locked: form.locked,
    };
  };

  const saveForm = async () => {
    if (form.doors.length === 0) return;
    const payload = buildPayload();
    if (form.id) {
      const res = await nui('doorlock:update', payload);
      if (res?.ok) {
        setDoors(prev =>
          prev.map(d => (d.id === form.id ? ({ ...d, ...payload, doors: form.doors } as any) : d))
        );
        setView('list');
      }
    } else {
      const res = await nui('doorlock:create', payload);
      if (res?.ok) {
        const newDoor: EditorDoor = {
          id: res.result,
          label: payload.label,
          locked: payload.locked,
          doors: payload.doors,
          groups: payload.groups,
          items: payload.items,
          code: payload.code || null,
          adminRank: payload.adminRank || null,
          lockpick: payload.lockpick,
          autolock: payload.autolock,
        };
        setDoors(prev => [...prev, newDoor]);
        setView('list');
      }
    }
  };

  if (!open) return null;

  // ── Selection overlay (lightweight, no focus) ────────────────────────────
  if (selecting) {
    return (
      <div className="dlm-selection" style={accentVars}>
        <div className="dlm-sel-card">
          <Crosshair size={20} className="dlm-sel-icon" />
          <div className="dlm-sel-texts">
            <div className="dlm-sel-title">Sélection des portes</div>
            <div className="dlm-sel-sub">
              <span className="dlm-kbd">E</span> ajouter/retirer ·
              <span className="dlm-kbd">ENTRÉE</span> valider ·
              <span className="dlm-kbd">ÉCHAP</span> annuler
            </div>
          </div>
          <div className="dlm-sel-count">{selCount}</div>
        </div>
      </div>
    );
  }

  return (
    <div className="dlm-overlay" style={accentVars}>
      <div className="dlm-panel">
        {/* Header */}
        <div className="dlm-header">
          <div className="dlm-header-left">
            {view === 'form' && (
              <button className="dlm-back" onClick={() => setView('list')}>
                <ArrowLeft size={18} />
              </button>
            )}
            <DoorClosed size={20} className="dlm-header-icon" />
            <div>
              <div className="dlm-title">Gestion des portes</div>
              <div className="dlm-subtitle">
                {view === 'list'
                  ? `${doors.length} porte${doors.length > 1 ? 's' : ''} configurée${doors.length > 1 ? 's' : ''}`
                  : form.id ? `Modifier la porte #${form.id}` : 'Nouvelle porte'}
              </div>
            </div>
          </div>
          <button className="dlm-close" onClick={handleClose}>
            <X size={18} />
          </button>
        </div>

        {/* LIST VIEW */}
        {view === 'list' && (
          <>
            <div className="dlm-list">
              {doors.length === 0 && (
                <div className="dlm-empty">
                  <DoorClosed size={40} />
                  <div>Aucune porte configurée</div>
                  <div className="dlm-empty-sub">Cliquez sur « Créer une porte » pour commencer.</div>
                </div>
              )}
              {doors.map(d => {
                const jobNames = Object.keys(d.groups || {});
                return (
                  <div key={d.id} className="dlm-row">
                    <div className={`dlm-row-status ${d.locked ? 'locked' : 'unlocked'}`}>
                      {d.locked ? <Lock size={16} /> : <Unlock size={16} />}
                    </div>
                    <div className="dlm-row-main">
                      <div className="dlm-row-label">
                        {d.label || `Porte #${d.id}`}
                        <span className="dlm-row-id">#{d.id}</span>
                      </div>
                      <div className="dlm-row-tags">
                        <span className="dlm-tag"><DoorClosed size={11} /> {d.doors?.length || 0} porte(s)</span>
                        {jobNames.length > 0 && (
                          <span className="dlm-tag"><Briefcase size={11} /> {jobNames.join(', ')}</span>
                        )}
                        {d.adminRank && (
                          <span className="dlm-tag"><ShieldCheck size={11} /> {d.adminRank}</span>
                        )}
                        {d.code && <span className="dlm-tag"><Hash size={11} /> code</span>}
                        {d.lockpick !== false && <span className="dlm-tag"><KeyRound size={11} /> crochet</span>}
                      </div>
                    </div>
                    <div className="dlm-row-actions">
                      <button className="dlm-icon-btn" title="Téléporter" onClick={() => teleport(d)}>
                        <MapPin size={15} />
                      </button>
                      <button className="dlm-icon-btn" title="Modifier" onClick={() => startEdit(d)}>
                        <Pencil size={15} />
                      </button>
                      <button className="dlm-icon-btn danger" title="Supprimer" onClick={() => deleteDoor(d.id)}>
                        <Trash2 size={15} />
                      </button>
                    </div>
                  </div>
                );
              })}
            </div>
            <div className="dlm-footer">
              <button className="dlm-btn-primary" onClick={startCreate}>
                <Plus size={16} /> Créer une porte
              </button>
            </div>
          </>
        )}

        {/* FORM VIEW */}
        {view === 'form' && (
          <>
            <div className="dlm-form">
              {/* Portes physiques */}
              <div className="dlm-section">
                <div className="dlm-section-title"><DoorClosed size={14} /> Portes physiques</div>
                <div className="dlm-doors-chips">
                  {form.doors.length === 0 && <div className="dlm-hint">Aucune porte sélectionnée.</div>}
                  {form.doors.map((d, i) => (
                    <span key={i} className="dlm-door-chip">
                      Porte {i + 1} <span className="dlm-door-coord">({d.x.toFixed(1)}, {d.y.toFixed(1)})</span>
                    </span>
                  ))}
                </div>
                <button className="dlm-btn-ghost" onClick={startSelection}>
                  <Crosshair size={14} /> {form.doors.length > 0 ? 'Re-sélectionner' : 'Sélectionner les portes'} (double-porte / garage)
                </button>
              </div>

              {/* Général */}
              <div className="dlm-section">
                <div className="dlm-section-title"><Pencil size={14} /> Général</div>
                <label className="dlm-field">
                  <span>Nom de la porte</span>
                  <input
                    type="text"
                    value={form.label}
                    placeholder="Ex: Commissariat - Entrée"
                    onChange={e => setForm(p => ({ ...p, label: e.target.value }))}
                  />
                </label>
                <div className="dlm-field-row">
                  <label className="dlm-check">
                    <input
                      type="checkbox"
                      checked={form.locked}
                      onChange={e => setForm(p => ({ ...p, locked: e.target.checked }))}
                    />
                    <span>Verrouillée par défaut</span>
                  </label>
                  <label className="dlm-check">
                    <input
                      type="checkbox"
                      checked={form.lockpick}
                      onChange={e => setForm(p => ({ ...p, lockpick: e.target.checked }))}
                    />
                    <span>Crochetable</span>
                  </label>
                </div>
                <label className="dlm-field">
                  <span>Auto-verrouillage (secondes, 0 = off)</span>
                  <input
                    type="number"
                    min={0}
                    value={form.autolock}
                    onChange={e => setForm(p => ({ ...p, autolock: Math.max(0, Number(e.target.value) || 0) }))}
                  />
                </label>
              </div>

              {/* Permissions */}
              <div className="dlm-section">
                <div className="dlm-section-title"><ShieldCheck size={14} /> Permissions</div>

                <div className="dlm-subfield">
                  <div className="dlm-subfield-head">
                    <span><Briefcase size={12} /> Jobs autorisés</span>
                    <button className="dlm-mini-btn" onClick={addJob}><Plus size={13} /></button>
                  </div>
                  {form.jobs.length === 0 && <div className="dlm-hint">Aucun job (porte non liée à un métier).</div>}
                  {form.jobs.map((j, i) => (
                    <div key={i} className="dlm-job-row">
                      <input
                        type="text"
                        placeholder="nom du job (ex: police)"
                        value={j.name}
                        onChange={e => updateJob(i, { name: e.target.value })}
                      />
                      <input
                        type="number"
                        min={0}
                        title="Grade minimum"
                        value={j.grade}
                        onChange={e => updateJob(i, { grade: Number(e.target.value) || 0 })}
                      />
                      <button className="dlm-mini-btn danger" onClick={() => removeJob(i)}><X size={13} /></button>
                    </div>
                  ))}
                </div>

                <label className="dlm-field">
                  <span><ShieldCheck size={12} /> Rang admin requis</span>
                  <select
                    value={form.adminRank}
                    onChange={e => setForm(p => ({ ...p, adminRank: e.target.value }))}
                  >
                    {ADMIN_RANKS.map(r => (
                      <option key={r} value={r}>{r === '' ? 'Aucun' : r}</option>
                    ))}
                  </select>
                </label>

                <label className="dlm-field">
                  <span><Hash size={12} /> Code de déverrouillage</span>
                  <input
                    type="text"
                    inputMode="numeric"
                    placeholder="Ex: 1234 (vide = pas de code)"
                    value={form.code}
                    onChange={e => setForm(p => ({ ...p, code: e.target.value }))}
                  />
                </label>

                <label className="dlm-field">
                  <span><KeyRound size={12} /> Items / clés (séparés par virgule)</span>
                  <input
                    type="text"
                    placeholder="Ex: cle_commissariat"
                    value={form.items}
                    onChange={e => setForm(p => ({ ...p, items: e.target.value }))}
                  />
                </label>
              </div>
            </div>

            <div className="dlm-footer">
              <button className="dlm-btn-ghost" onClick={() => setView('list')}>Annuler</button>
              <button
                className="dlm-btn-primary"
                disabled={form.doors.length === 0}
                onClick={saveForm}
              >
                <Check size={16} /> {form.id ? 'Enregistrer' : 'Créer la porte'}
              </button>
            </div>
          </>
        )}
      </div>
    </div>
  );
};

export default DoorlockManager;
