import { useState, useCallback } from 'react'
import { CrimeNetData, CrimeNetContact } from '../types'
import { postNUI } from '../nui'

interface Props {
  cnData: CrimeNetData | null
  onRefreshData: () => void
}

interface FoundPlayer {
  identifier: string
  name: string
  crimenet_id: string
  online: boolean
  is_fake: boolean
}

export default function ContactsTab({ cnData, onRefreshData }: Props) {
  const [cnIdInput, setCnIdInput] = useState('')
  const [filterQuery, setFilterQuery] = useState('')
  const [foundPlayer, setFoundPlayer] = useState<FoundPlayer | null>(null)
  const [lookupError, setLookupError] = useState('')
  const [searching, setSearching] = useState(false)
  const [showLookup, setShowLookup] = useState(false)
  const [selectedContact, setSelectedContact] = useState<CrimeNetContact | null>(null)

  const contacts = cnData?.contacts || []

  const filteredContacts = filterQuery
    ? contacts.filter(c =>
        (c.name || '').toLowerCase().includes(filterQuery.toLowerCase()) ||
        (c.nickname || '').toLowerCase().includes(filterQuery.toLowerCase()) ||
        (c.gangLabel || '').toLowerCase().includes(filterQuery.toLowerCase())
      )
    : contacts

  const handleLookup = useCallback(async () => {
    const val = cnIdInput.trim().toUpperCase()
    if (!val) return
    setSearching(true)
    setLookupError('')
    setFoundPlayer(null)
    const res = await postNUI('crimenet:findByCrimenetId', { crimenetId: val }) as { success: boolean; player?: FoundPlayer; error?: string }
    if (res?.success && res.player) {
      setFoundPlayer(res.player)
    } else {
      const errMap: Record<string, string> = {
        SELF_ADD: 'Tu ne peux pas t\'ajouter toi-même.',
        NOT_FOUND: 'Aucun utilisateur avec cet identifiant.',
      }
      setLookupError(errMap[res?.error || ''] || 'Identifiant introuvable.')
    }
    setSearching(false)
  }, [cnIdInput])

  const handleAddContact = useCallback(async (identifier: string) => {
    const res = await postNUI('crimenet:addContact', { identifier, nickname: null }) as { success: boolean; error?: string }
    if (res?.success) {
      onRefreshData()
      setShowLookup(false)
      setCnIdInput('')
      setFoundPlayer(null)
    }
  }, [onRefreshData])

  const handleRemoveContact = useCallback(async (identifier: string) => {
    const res = await postNUI('crimenet:removeContact', { identifier }) as { success: boolean }
    if (res?.success) {
      setSelectedContact(null)
      onRefreshData()
    }
  }, [onRefreshData])

  return (
    <div className="contacts-tab">
      {/* Top bar: filter + add button */}
      <div className="ct-topbar">
        <input
          className="ct-filter-input"
          type="text"
          placeholder="Filtrer les contacts..."
          value={filterQuery}
          onChange={(e) => setFilterQuery(e.target.value)}
        />
        <button className="ct-add-toggle" onClick={() => { setShowLookup(v => !v); setFoundPlayer(null); setLookupError(''); setCnIdInput('') }}>
          {showLookup ? '✕' : '+ AJOUTER'}
        </button>
      </div>

      {/* CrimeNet ID lookup panel */}
      {showLookup && (
        <div className="ct-lookup-panel">
          <div className="ct-lookup-label">AJOUTER PAR NUMÉRO CRIMENET</div>
          <div className="ct-lookup-row">
            <input
              className="ct-lookup-input"
              type="text"
              placeholder="CN-XXXXX"
              value={cnIdInput}
              onChange={(e) => setCnIdInput(e.target.value.toUpperCase())}
              onKeyDown={(e) => e.key === 'Enter' && handleLookup()}
              maxLength={10}
            />
            <button className="ct-lookup-btn" onClick={handleLookup} disabled={searching || !cnIdInput.trim()}>
              {searching ? '...' : 'RECHERCHER'}
            </button>
          </div>
          {lookupError && <div className="ct-lookup-error">{lookupError}</div>}
          {foundPlayer && (
            <div className="ct-lookup-result">
              <div className="ct-result-avatar">{foundPlayer.name.substring(0, 2).toUpperCase()}</div>
              <div className="ct-result-info">
                <div className="ct-result-name">{foundPlayer.name}</div>
                <div className="ct-result-cid">{foundPlayer.crimenet_id}</div>
              </div>
              {contacts.some(c => c.identifier === foundPlayer.identifier) ? (
                <span className="ct-badge ct-badge--added">DÉJÀ AJOUTÉ</span>
              ) : (
                <button className="ct-add-btn" onClick={() => handleAddContact(foundPlayer.identifier)}>
                  + AJOUTER
                </button>
              )}
            </div>
          )}
          <div className="ct-lookup-hint">Demande le numéro CrimeNet à la personne que tu veux ajouter.</div>
        </div>
      )}

      {/* Contact list */}
      {!showLookup && (
        <>
          <div className="ct-header">
            <span className="ct-count">{contacts.length} CONTACT{contacts.length !== 1 ? 'S' : ''}</span>
            <span className="ct-online">{contacts.filter(c => c.online).length} en ligne</span>
          </div>

          <div className="ct-list">
            {filteredContacts.length === 0 ? (
              <div className="ct-empty">
                {filterQuery ? 'Aucun contact correspondant' : 'Aucun contact. Utilise + AJOUTER avec un numéro CrimeNet.'}
              </div>
            ) : (
              filteredContacts.map(contact => (
                <div
                  key={contact.identifier}
                  className={`ct-item ${selectedContact?.identifier === contact.identifier ? 'ct-item--selected' : ''}`}
                  onClick={() => setSelectedContact(selectedContact?.identifier === contact.identifier ? null : contact)}
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
                      {contact.is_important && <span className="ct-badge ct-badge--imp">★</span>}
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
        </>
      )}

      {/* Contact detail panel */}
      {selectedContact && !showLookup && (
        <div className="ct-detail">
          <div className="ct-detail-top">
            <div className="ct-detail-avatar">
              {(selectedContact.name || '??').substring(0, 2).toUpperCase()}
            </div>
            <div className="ct-detail-name">{selectedContact.nickname || selectedContact.name}</div>
            {selectedContact.gangLabel && (
              <div className="ct-detail-gang">{selectedContact.gangLabel}</div>
            )}
            {selectedContact.is_boss && <div className="ct-detail-tag">BOSS</div>}
            {selectedContact.is_important && selectedContact.admin_label && (
              <div className="ct-detail-tag ct-detail-tag--imp">{selectedContact.admin_label}</div>
            )}
          </div>
          {selectedContact.description && (
            <div className="ct-detail-desc">{selectedContact.description}</div>
          )}
          <div className="ct-detail-meta">
            <span>Statut: {selectedContact.online ? 'En ligne' : 'Hors ligne'}</span>
          </div>
          <div className="ct-detail-actions">
            <button className="ct-action-btn ct-action-btn--danger" onClick={() => handleRemoveContact(selectedContact.identifier)}>
              SUPPRIMER
            </button>
          </div>
        </div>
      )}
    </div>
  )
}
