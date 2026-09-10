import { useState, useCallback } from 'react'
import { CrimeNetData, GoFastData, CrimeNetContact } from '../types'
import { postNUI } from '../nui'

interface Props {
  cnData: CrimeNetData | null
  goFastData: GoFastData | null
  onRefreshData: () => void
  onShowProgression?: () => void
}

const EDIT_ICON = <svg viewBox="0 0 24 24" width="12" height="12" fill="none" stroke="currentColor" strokeWidth="2"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7" /><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z" /></svg>

export default function ProfileTab({ cnData, goFastData, onRefreshData, onShowProgression }: Props) {
  const [editingBio, setEditingBio] = useState(false)
  const [editingName, setEditingName] = useState(false)
  const [descInput, setDescInput] = useState('')
  const [nameInput, setNameInput] = useState('')
  const [saving, setSaving] = useState(false)
  const [nameError, setNameError] = useState<string | null>(null)
  const [showContacts, setShowContacts] = useState(false)
  const [contactFilter, setContactFilter] = useState('')
  const [selectedContact, setSelectedContact] = useState<CrimeNetContact | null>(null)

  const profile = cnData?.profile
  const gf = goFastData

  const startEditBio = useCallback(() => {
    setDescInput(profile?.description || '')
    setEditingBio(true)
  }, [profile])

  const startEditName = useCallback(() => {
    setNameInput(profile?.pseudonym || profile?.name || '')
    setNameError(null)
    setEditingName(true)
  }, [profile])

  const saveField = useCallback(async (fields: Record<string, string>) => {
    setSaving(true)
    const res = await postNUI('crimenet:updateProfile', { fields }) as { success: boolean; error?: string }
    if (res?.success) {
      onRefreshData()
      setEditingBio(false)
      setEditingName(false)
      setNameError(null)
    } else if (res?.error) {
      const msgs: Record<string, string> = {
        PROFANITY: 'Pseudonyme inapproprié détecté.',
        LENGTH: 'Le pseudonyme doit faire entre 2 et 24 caractères.',
        INVALID_CHARS: 'Caractères non autorisés.',
      }
      setNameError(msgs[res.error] || 'Erreur inconnue.')
    }
    setSaving(false)
  }, [onRefreshData])

  const pickPhoto = useCallback(async () => {
    const res = await postNUI('crimenet:pickPhoto', {}) as { success: boolean; url?: string }
    if (res?.success && res.url) {
      await saveField({ avatar_url: res.url })
    }
  }, [saveField])

  const successRate = gf && gf.totalMissions > 0
    ? Math.round(((gf.totalMissions - gf.totalFailed) / gf.totalMissions) * 100)
    : 0

  return (
    <div className="prof-tab">
      {/* Identity card */}
      <div className="prof-identity">
        <div className="prof-avatar" onClick={pickPhoto} title="Changer la photo">
          {profile?.avatar_url ? (
            <img src={profile.avatar_url} alt="" className="prof-avatar-img" />
          ) : (
            <div className="prof-avatar-placeholder">
              {(profile?.name || '??').substring(0, 2).toUpperCase()}
            </div>
          )}
          <div className="prof-avatar-overlay">
            <svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" strokeWidth="2">
              <path d="M23 19a2 2 0 0 1-2 2H3a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h4l2-3h6l2 3h4a2 2 0 0 1 2 2z" />
              <circle cx="12" cy="13" r="4" />
            </svg>
          </div>
        </div>
        <div className="prof-identity-info">
          {editingName ? (
            <div className="prof-edit-name">
              <input
                className="prof-name-input"
                value={nameInput}
                onChange={(e) => { setNameInput(e.target.value); setNameError(null) }}
                maxLength={24}
                placeholder="Ton pseudonyme..."
                autoFocus
              />
              {nameError && <div className="prof-name-error">{nameError}</div>}
              <div className="prof-name-warn">Les noms inappropriés seront bannis sans avertissement.</div>
              <div className="prof-edit-actions">
                <button className="prof-save-btn" onClick={() => saveField({ pseudonym: nameInput.trim() })} disabled={saving || nameInput.trim().length < 2}>
                  {saving ? '...' : 'VALIDER'}
                </button>
                <button className="prof-cancel-btn" onClick={() => { setEditingName(false); setNameError(null) }}>ANNULER</button>
              </div>
            </div>
          ) : (
            <>
              <div className="prof-name">
                {profile?.name || 'Inconnu'}
                <button className="prof-edit-btn" onClick={startEditName}>{EDIT_ICON}</button>
              </div>
              {profile?.crimenet_id && (
                <div className="prof-cnid">{profile.crimenet_id}</div>
              )}
              {gf?.gangLabel && (
                <div className="prof-gang">{gf.gangLabel}</div>
              )}
            </>
          )}
        </div>
      </div>

      {/* Description */}
      <div className="prof-section">
        <div className="prof-section-label">
          BIO
          {!editingBio && (
            <button className="prof-edit-btn" onClick={startEditBio}>{EDIT_ICON}</button>
          )}
        </div>
        {editingBio ? (
          <div className="prof-edit-desc">
            <textarea
              className="prof-desc-input"
              value={descInput}
              onChange={(e) => setDescInput(e.target.value)}
              maxLength={200}
              rows={3}
              placeholder="Décris ton profil criminel..."
            />
            <div className="prof-edit-actions">
              <button className="prof-save-btn" onClick={() => saveField({ description: descInput.trim() })} disabled={saving}>
                {saving ? '...' : 'SAUVEGARDER'}
              </button>
              <button className="prof-cancel-btn" onClick={() => setEditingBio(false)}>ANNULER</button>
            </div>
          </div>
        ) : (
          <div className="prof-desc">
            {profile?.description || 'Aucune description. Clique pour en ajouter.'}
          </div>
        )}
      </div>

      {/* GoFast stats */}
      {gf && (
        <>
          {/* Tier header - clickable to show progression */}
          <div className="prof-tier-card" onClick={onShowProgression} style={{ cursor: onShowProgression ? 'pointer' : 'default' }}>
            <div className="prof-tier-icon">
              <svg viewBox="0 0 40 40" width="40" height="40">
                <circle cx="20" cy="20" r="18" fill="none" stroke="#dc2626" strokeWidth="1.5" />
                <circle cx="20" cy="20" r="12" fill="none" stroke="#dc2626" strokeWidth="1" opacity="0.4" />
                <circle cx="20" cy="20" r="5" fill="#dc2626" />
              </svg>
            </div>
            <div className="prof-tier-info">
              <div className="prof-tier-name">{gf.tier?.label || '---'}</div>
              <div className="prof-tier-desc">{gf.tier?.description || ''}</div>
            </div>
          </div>

          {/* Stats grid */}
          <div className="prof-stats">
            <div className="prof-stat">
              <div className="prof-stat-value">{gf.xp}</div>
              <div className="prof-stat-label">XP</div>
            </div>
            <div className="prof-stat">
              <div className="prof-stat-value">{gf.totalMissions}</div>
              <div className="prof-stat-label">MISSIONS</div>
            </div>
            <div className="prof-stat">
              <div className="prof-stat-value">{gf.totalFailed}</div>
              <div className="prof-stat-label">ÉCHECS</div>
            </div>
            <div className="prof-stat">
              <div className="prof-stat-value">{successRate}%</div>
              <div className="prof-stat-label">RÉUSSITE</div>
            </div>
          </div>

          {/* Crew info */}
          {gf.isIllegal && gf.gangname && (
            <div className="prof-section">
              <div className="prof-section-label">ORGANISATION</div>
              <div className="prof-crew-card">
                <div className="prof-crew-icon">
                  <svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="#f59e0b" strokeWidth="2">
                    <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" />
                    <circle cx="9" cy="7" r="4" />
                    <path d="M23 21v-2a4 4 0 0 0-3-3.87" />
                    <path d="M16 3.13a4 4 0 0 1 0 7.75" />
                  </svg>
                </div>
                <div className="prof-crew-info">
                  <div className="prof-crew-name">{gf.gangLabel || gf.gangname}</div>
                  {gf.crewTier && (
                    <div className="prof-crew-tier">{gf.crewTier.label}</div>
                  )}
                </div>
              </div>
            </div>
          )}

          {/* Blacklist warning */}
          {gf.blacklisted && (
            <div className="prof-blacklist">
              <div className="prof-blacklist-icon">
                <svg viewBox="0 0 24 24" width="24" height="24" fill="none" stroke="#dc2626" strokeWidth="2">
                  <path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z" />
                  <line x1="12" y1="9" x2="12" y2="13" /><line x1="12" y1="17" x2="12.01" y2="17" />
                </svg>
              </div>
              <div className="prof-blacklist-title">BLACKLISTÉ</div>
              <div className="prof-blacklist-text">
                Tu as trahi le réseau. Le cartel te cherche.
              </div>
            </div>
          )}
        </>
      )}

      {/* Network stats */}
      <div className="prof-section">
        <div className="prof-section-label">RÉSEAU</div>
        <div className="prof-stats">
          <div className="prof-stat prof-stat--clickable" onClick={() => setShowContacts(true)}>
            <div className="prof-stat-value">{cnData?.contacts.length || 0}</div>
            <div className="prof-stat-label">CONTACTS</div>
          </div>
          <div className="prof-stat">
            <div className="prof-stat-value">{cnData?.contacts.filter(c => c.online).length || 0}</div>
            <div className="prof-stat-label">EN LIGNE</div>
          </div>
          <div className="prof-stat">
            <div className="prof-stat-value">{cnData?.groups.length || 0}</div>
            <div className="prof-stat-label">GROUPES</div>
          </div>
        </div>
      </div>

      {/* Refresh button */}
      <button className="prof-refresh" onClick={onRefreshData}>
        <svg viewBox="0 0 24 24" width="14" height="14" fill="none" stroke="currentColor" strokeWidth="2">
          <polyline points="23 4 23 10 17 10" /><polyline points="1 20 1 14 7 14" />
          <path d="M3.51 9a9 9 0 0 1 14.85-3.36L23 10M1 14l4.64 4.36A9 9 0 0 0 20.49 15" />
        </svg>
        <span>ACTUALISER</span>
      </button>

      {/* Contacts overlay */}
      {showContacts && <ContactsOverlay
        contacts={cnData?.contacts || []}
        filter={contactFilter}
        onFilterChange={setContactFilter}
        selected={selectedContact}
        onSelect={setSelectedContact}
        onClose={() => { setShowContacts(false); setSelectedContact(null); setContactFilter('') }}
        onRemove={async (identifier) => {
          const res = await postNUI('crimenet:removeContact', { identifier }) as { success: boolean }
          if (res?.success) {
            setSelectedContact(null)
            onRefreshData()
          }
        }}
      />}
    </div>
  )
}

// ---- CONTACTS OVERLAY COMPONENT ----
function ContactsOverlay({ contacts, filter, onFilterChange, selected, onSelect, onClose, onRemove }: {
  contacts: CrimeNetContact[]
  filter: string
  onFilterChange: (v: string) => void
  selected: CrimeNetContact | null
  onSelect: (c: CrimeNetContact | null) => void
  onClose: () => void
  onRemove: (identifier: string) => void
}) {
  const filtered = filter
    ? contacts.filter(c =>
        (c.name || '').toLowerCase().includes(filter.toLowerCase()) ||
        (c.nickname || '').toLowerCase().includes(filter.toLowerCase()) ||
        (c.gangLabel || '').toLowerCase().includes(filter.toLowerCase())
      )
    : contacts

  return (
    <div className="prof-contacts-overlay">
      <div className="prof-contacts-header">
        <button className="mkt-back" onClick={onClose}>
          <svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" strokeWidth="2"><polyline points="15 18 9 12 15 6" /></svg>
        </button>
        <span className="prof-contacts-title">CONTACTS ({contacts.length})</span>
      </div>

      <div className="ct-topbar" style={{ borderBottom: 'none' }}>
        <input
          className="ct-filter-input"
          type="text"
          placeholder="Filtrer les contacts..."
          value={filter}
          onChange={(e) => onFilterChange(e.target.value)}
        />
      </div>

      <div className="ct-header">
        <span className="ct-count">{contacts.length} CONTACT{contacts.length !== 1 ? 'S' : ''}</span>
        <span className="ct-online">{contacts.filter(c => c.online).length} en ligne</span>
      </div>

      <div className="ct-list">
        {filtered.length === 0 ? (
          <div className="ct-empty">
            {filter ? 'Aucun contact correspondant' : 'Aucun contact.'}
          </div>
        ) : (
          filtered.map(contact => (
            <div
              key={contact.identifier}
              className={`ct-item ${selected?.identifier === contact.identifier ? 'ct-item--selected' : ''}`}
              onClick={() => onSelect(selected?.identifier === contact.identifier ? null : contact)}
            >
              <div className="ct-item-avatar">
                {contact.avatar_url ? (
                  <img src={contact.avatar_url} alt="" />
                ) : (
                  <span>{(contact.name || '??').substring(0, 2).toUpperCase()}</span>
                )}
                {contact.online && <div className="ct-item-online-dot" />}
              </div>
              <div className="ct-item-info">
                <div className="ct-item-name">
                  {contact.nickname || contact.name}
                  {contact.is_boss && <span className="ct-badge ct-badge--boss">BOSS</span>}
                  {contact.is_important && <span className="ct-badge ct-badge--imp">&#9733;</span>}
                </div>
                <div className="ct-item-sub">
                  {contact.gangLabel || contact.description || 'Contact du réseau'}
                </div>
              </div>
              <div className={`ct-item-status ${contact.online ? 'ct-item-status--on' : ''}`}>
                {contact.online ? '●' : '○'}
              </div>
            </div>
          ))
        )}
      </div>

      {/* Contact detail panel */}
      {selected && (
        <div className="ct-detail">
          <div className="ct-detail-top">
            <div className="ct-detail-avatar">
              {(selected.name || '??').substring(0, 2).toUpperCase()}
            </div>
            <div className="ct-detail-name">{selected.nickname || selected.name}</div>
            {selected.gangLabel && (
              <div className="ct-detail-gang">{selected.gangLabel}</div>
            )}
            {selected.is_boss && <div className="ct-detail-tag">BOSS</div>}
          </div>
          {selected.description && (
            <div className="ct-detail-desc">{selected.description}</div>
          )}
          <div className="ct-detail-meta">
            <span>Statut: {selected.online ? 'En ligne' : 'Hors ligne'}</span>
          </div>
          <div className="ct-detail-actions">
            <button className="ct-action-btn ct-action-btn--danger" onClick={() => onRemove(selected.identifier)}>
              SUPPRIMER
            </button>
          </div>
        </div>
      )}
    </div>
  )
}
