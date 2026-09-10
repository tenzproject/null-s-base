import { useState, useEffect, useCallback, useRef } from 'react'
import { CrimeNetData, CrimeNetMessage, CrimeNetContact } from '../types'
import { postNUI } from '../nui'

interface Props {
  cnData: CrimeNetData | null
  onRefreshData: () => void
}

type ChatView = { type: 'dm'; id: string; name: string } | { type: 'group'; id: number; name: string } | null

interface FoundPlayer {
  identifier: string
  name: string
  crimenet_id: string
  online: boolean
  is_fake: boolean
}

export default function MessagesTab({ cnData, onRefreshData }: Props) {
  const [chatView, setChatView] = useState<ChatView>(null)
  const [messages, setMessages] = useState<CrimeNetMessage[]>([])
  const [inputText, setInputText] = useState('')
  const [loading, setLoading] = useState(false)
  const [showNewGroup, setShowNewGroup] = useState(false)
  const [newGroupName, setNewGroupName] = useState('')
  const [selectedMembers, setSelectedMembers] = useState<string[]>([])
  const messagesEndRef = useRef<HTMLDivElement>(null)

  // Add contact state
  const [showAddContact, setShowAddContact] = useState(false)
  const [cnIdInput, setCnIdInput] = useState('')
  const [foundPlayer, setFoundPlayer] = useState<FoundPlayer | null>(null)
  const [lookupError, setLookupError] = useState('')
  const [searching, setSearching] = useState(false)
  const [addNotif, setAddNotif] = useState<string | null>(null)

  const conversations = cnData?.conversations || []
  const groups = cnData?.groups || []
  const myId = cnData?.profile?.identifier || ''

  const openConversation = useCallback(async (otherId: string, name: string) => {
    setChatView({ type: 'dm', id: otherId, name })
    setLoading(true)
    const msgs = await postNUI('crimenet:getConversation', { otherIdentifier: otherId, page: 1 }) as CrimeNetMessage[]
    setMessages((msgs || []).reverse())
    setLoading(false)
  }, [])

  const openGroup = useCallback(async (groupId: number, name: string) => {
    setChatView({ type: 'group', id: groupId, name })
    setLoading(true)
    const msgs = await postNUI('crimenet:getGroupMessages', { groupId, page: 1 }) as any[]
    setMessages((msgs || []).reverse())
    setLoading(false)
  }, [])

  const handleSend = useCallback(async () => {
    if (!inputText.trim() || !chatView) return
    const content = inputText.trim()
    setInputText('')

    if (chatView.type === 'dm') {
      const res = await postNUI('crimenet:sendMessage', { toIdentifier: chatView.id, content }) as { success: boolean; id: number }
      if (res?.success) {
        setMessages(prev => [...prev, { id: res.id, from_id: myId, to_id: chatView.id, content, sent_at: new Date().toISOString(), read_at: null }])
      }
    } else {
      const res = await postNUI('crimenet:sendGroupMessage', { groupId: chatView.id, content }) as { success: boolean; id: number }
      if (res?.success) {
        setMessages(prev => [...prev, { id: res.id, from_id: myId, to_id: '', content, sent_at: new Date().toISOString(), read_at: null }])
      }
    }
  }, [inputText, chatView, myId])

  const handleLeaveGroup = useCallback(async (groupId: number) => {
    const res = await postNUI('crimenet:leaveGroup', { groupId }) as { success: boolean }
    if (res?.success) {
      setChatView(null)
      setMessages([])
      onRefreshData()
    }
  }, [onRefreshData])

  const handleCreateGroup = useCallback(async () => {
    if (!newGroupName.trim() || selectedMembers.length === 0) return
    const res = await postNUI('crimenet:createGroup', { name: newGroupName.trim(), memberIdentifiers: selectedMembers }) as { success: boolean }
    if (res?.success) {
      setShowNewGroup(false)
      setNewGroupName('')
      setSelectedMembers([])
      onRefreshData()
    }
  }, [newGroupName, selectedMembers, onRefreshData])

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' })
  }, [messages])

  const getContactName = (id: string) => {
    const c = cnData?.contacts.find(ct => ct.identifier === id)
    return c?.nickname || c?.name || id.substring(0, 12)
  }

  // ---- ADD CONTACT HANDLERS ----
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
      setShowAddContact(false)
      setCnIdInput('')
      setFoundPlayer(null)
      setAddNotif('Contact ajouté')
      setTimeout(() => setAddNotif(null), 3000)
    }
  }, [onRefreshData])

  // ---- CHAT VIEW ----
  if (chatView) {
    const chatContact = chatView.type === 'dm' ? cnData?.contacts.find(ct => ct.identifier === chatView.id) : null
    const isContact = !!chatContact
    return (
      <div className="msg-tab">
        <div className="msg-chat">
          <div className="msg-chat-header">
            <button className="msg-back-btn" onClick={() => { setChatView(null); setMessages([]) }}>
              <svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" strokeWidth="2"><polyline points="15 18 9 12 15 6" /></svg>
            </button>
            <div className="msg-chat-name">{chatView.name}</div>
            <div className="msg-chat-type">{chatView.type === 'group' ? 'GROUPE' : 'DM'}</div>
            {chatView.type === 'dm' && !isContact && (
              <button className="msg-add-contact-btn" onClick={() => handleAddContact(chatView.id)} title="Ajouter en contact">
                <svg viewBox="0 0 24 24" width="14" height="14" fill="none" stroke="currentColor" strokeWidth="2">
                  <path d="M16 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" /><circle cx="8.5" cy="7" r="4" />
                  <line x1="20" y1="8" x2="20" y2="14" /><line x1="23" y1="11" x2="17" y2="11" />
                </svg>
              </button>
            )}
            {chatView.type === 'group' && (
              <button className="msg-leave-btn" onClick={() => handleLeaveGroup(chatView.id as number)} title="Quitter le groupe">
                <svg viewBox="0 0 24 24" width="14" height="14" fill="none" stroke="currentColor" strokeWidth="2">
                  <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4" /><polyline points="16 17 21 12 16 7" /><line x1="21" y1="12" x2="9" y2="12" />
                </svg>
              </button>
            )}
          </div>
          <div className="msg-chat-messages">
            {loading ? (
              <div className="msg-loading">Chargement...</div>
            ) : messages.length === 0 ? (
              <div className="msg-no-messages">Aucun message. Commence la conversation.</div>
            ) : (
              messages.map(msg => {
                const isMine = msg.from_id === myId
                return (
                  <div key={msg.id} className={`msg-bubble ${isMine ? 'msg-bubble--mine' : 'msg-bubble--other'}`}>
                    {!isMine && chatView.type === 'group' && (
                      <div className="msg-bubble-sender">{getContactName(msg.from_id)}</div>
                    )}
                    <div className="msg-bubble-content">{msg.content}</div>
                    <div className="msg-bubble-time">
                      {new Date(msg.sent_at).toLocaleTimeString('fr-FR', { hour: '2-digit', minute: '2-digit' })}
                    </div>
                  </div>
                )
              })
            )}
            <div ref={messagesEndRef} />
          </div>
          <div className="msg-input-bar">
            <input className="msg-input" type="text" placeholder="Message chiffré..." value={inputText}
              onChange={(e) => setInputText(e.target.value)} onKeyDown={(e) => e.key === 'Enter' && handleSend()} maxLength={500} />
            <button className="msg-send-btn" onClick={handleSend} disabled={!inputText.trim()}>
              <svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" strokeWidth="2">
                <line x1="22" y1="2" x2="11" y2="13" /><polygon points="22 2 15 22 11 13 2 9 22 2" />
              </svg>
            </button>
          </div>
        </div>
      </div>
    )
  }

  // ---- CREATE GROUP VIEW ----
  if (showNewGroup) {
    const contactsList = cnData?.contacts || []
    return (
      <div className="msg-tab">
        <div className="msg-new-group">
          <div className="msg-ng-header">
            <button className="msg-back-btn" onClick={() => setShowNewGroup(false)}>
              <svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" strokeWidth="2"><polyline points="15 18 9 12 15 6" /></svg>
            </button>
            <span>NOUVEAU GROUPE</span>
          </div>
          <input className="msg-ng-input" type="text" placeholder="Nom du groupe..." value={newGroupName}
            onChange={(e) => setNewGroupName(e.target.value)} maxLength={60} />
          <div className="msg-ng-label">MEMBRES</div>
          <div className="msg-ng-members">
            {contactsList.map(c => {
              const sel = selectedMembers.includes(c.identifier)
              return (
                <div key={c.identifier} className={`msg-ng-member ${sel ? 'msg-ng-member--selected' : ''}`}
                  onClick={() => setSelectedMembers(prev => sel ? prev.filter(id => id !== c.identifier) : [...prev, c.identifier])}>
                  <div className="msg-ng-member-avatar">{(c.name || '??').substring(0, 2)}</div>
                  <span>{c.nickname || c.name}</span>
                  {sel && <span className="msg-ng-check">&#10003;</span>}
                </div>
              )
            })}
          </div>
          <button className="msg-ng-create" disabled={!newGroupName.trim() || selectedMembers.length === 0} onClick={handleCreateGroup}>
            CRÉER ({selectedMembers.length} membre{selectedMembers.length > 1 ? 's' : ''})
          </button>
        </div>
      </div>
    )
  }

  // ---- ADD CONTACT PANEL ----
  if (showAddContact) {
    const contacts = cnData?.contacts || []
    return (
      <div className="msg-tab">
        <div className="msg-list-header">
          <button className="msg-back-btn" onClick={() => { setShowAddContact(false); setFoundPlayer(null); setLookupError(''); setCnIdInput('') }}>
            <svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" strokeWidth="2"><polyline points="15 18 9 12 15 6" /></svg>
          </button>
          <span>AJOUTER UN CONTACT</span>
        </div>
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
      </div>
    )
  }

  // ---- CONVERSATION LIST ----
  return (
    <div className="msg-tab">
      {addNotif && (
        <div className="jobs-notif jobs-notif--success" style={{ margin: '0 12px 8px' }}>
          <div className="jobs-notif-text">{addNotif}</div>
        </div>
      )}
      <div className="msg-list-header">
        <span>CONVERSATIONS</span>
        <div style={{ display: 'flex', gap: '6px' }}>
          <button className="msg-new-btn" onClick={() => setShowAddContact(true)}>+ CONTACT</button>
          <button className="msg-new-btn" onClick={() => setShowNewGroup(true)}>+ GROUPE</button>
        </div>
      </div>
      <div className="msg-list">
        {conversations.length === 0 && groups.length === 0 ? (
          <div className="msg-empty">
            <svg viewBox="0 0 24 24" width="32" height="32" fill="none" stroke="#333" strokeWidth="1.5">
              <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z" />
            </svg>
            <span>Aucune conversation</span>
            <span className="msg-empty-sub">Envoie un message depuis Contacts</span>
          </div>
        ) : (
          <>
            {conversations.map(conv => (
              <div key={conv.other_id} className="msg-conv" onClick={() => openConversation(conv.other_id, conv.name)}>
                <div className="msg-conv-avatar">
                  <span>{(conv.name || '??').substring(0, 2).toUpperCase()}</span>
                  {conv.online && <div className="msg-conv-online" />}
                </div>
                <div className="msg-conv-info">
                  <div className="msg-conv-name">{conv.name}</div>
                  <div className="msg-conv-preview">{conv.is_mine ? 'Vous: ' : ''}{(conv.last_message || '').substring(0, 45)}</div>
                </div>
                <div className="msg-conv-meta">
                  <div className="msg-conv-time">
                    {conv.last_sent_at ? new Date(conv.last_sent_at).toLocaleDateString('fr-FR', { day: '2-digit', month: '2-digit' }) : ''}
                  </div>
                  {conv.unread > 0 && <div className="msg-conv-unread">{conv.unread}</div>}
                </div>
              </div>
            ))}
            {groups.length > 0 && (
              <>
                <div className="msg-section-label">GROUPES</div>
                {groups.map(group => (
                  <div key={group.id} className="msg-conv msg-conv--group" onClick={() => openGroup(group.id, group.name)}>
                    <div className="msg-conv-avatar msg-conv-avatar--group">
                      <svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" strokeWidth="2">
                        <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" /><circle cx="9" cy="7" r="4" />
                        <path d="M23 21v-2a4 4 0 0 0-3-3.87" /><path d="M16 3.13a4 4 0 0 1 0 7.75" />
                      </svg>
                    </div>
                    <div className="msg-conv-info">
                      <div className="msg-conv-name">{group.name}</div>
                      <div className="msg-conv-preview">{group.member_count} membre{group.member_count > 1 ? 's' : ''}</div>
                    </div>
                  </div>
                ))}
              </>
            )}
            <div className="msg-section-label">NOUVEAU MESSAGE</div>
            {(cnData?.contacts || [])
              .filter(c => !conversations.some(cv => cv.other_id === c.identifier))
              .slice(0, 5)
              .map(c => (
                <div key={c.identifier} className="msg-conv msg-conv--new" onClick={() => openConversation(c.identifier, c.nickname || c.name)}>
                  <div className="msg-conv-avatar">
                    <span>{(c.name || '??').substring(0, 2).toUpperCase()}</span>
                    {c.online && <div className="msg-conv-online" />}
                  </div>
                  <div className="msg-conv-info">
                    <div className="msg-conv-name">{c.nickname || c.name}</div>
                    <div className="msg-conv-preview">{c.gangLabel || 'Nouveau message'}</div>
                  </div>
                </div>
              ))
            }
          </>
        )}
      </div>
    </div>
  )
}
