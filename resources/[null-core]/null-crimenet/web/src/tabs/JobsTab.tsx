import { useState, useEffect, useCallback } from 'react'
import { GoFastData, GoFastContract, MissionResponse, MissionResult, CrewMember } from '../types'
import { postNUI } from '../nui'

interface Props {
  goFastData: GoFastData | null
  missionResponse: MissionResponse | null
  missionResult: MissionResult | null
  onRequestMission: (type: 'solo' | 'crew', memberIds?: number[]) => void
  onClearMissionResponse: () => void
  onClearMissionResult: () => void
}

type ContractFilter = 'all' | 'solo' | 'crew' | 'fixed'

export default function JobsTab({
  goFastData, missionResponse, missionResult,
  onRequestMission, onClearMissionResponse, onClearMissionResult,
}: Props) {
  const [cooldown, setCooldown] = useState(0)
  const [cooldownEnd, setCooldownEnd] = useState(0)
  const [notification, setNotification] = useState<{ type: 'success' | 'error'; title: string; text: string } | null>(null)
  const [filter, setFilter] = useState<ContractFilter>('all')
  const [selectedContract, setSelectedContract] = useState<GoFastContract | null>(null)
  const [showCrewModal, setShowCrewModal] = useState(false)
  const [crewMembers, setCrewMembers] = useState<CrewMember[]>([])
  const [selectedMembers, setSelectedMembers] = useState<Set<number>>(new Set())
  const [crewLoading, setCrewLoading] = useState(false)
  const [accepting, setAccepting] = useState(false)
  const [contracts, setContracts] = useState<GoFastContract[]>([])
  const [contractsLoading, setContractsLoading] = useState(false)

  const playerXP = goFastData?.xp || 0
  const hasActive = !!goFastData?.activeMission
  const isBlacklisted = !!goFastData?.blacklisted

  // Fetch contracts from server on mount
  useEffect(() => {
    setContractsLoading(true)
    postNUI('crimenet:getContracts').then((data) => {
      setContracts((data as GoFastContract[]) || [])
      setContractsLoading(false)
    }).catch(() => {
      setContracts([])
      setContractsLoading(false)
    })
  }, [])

  // Refresh contracts every minute
  useEffect(() => {
    const interval = setInterval(() => {
      postNUI('crimenet:getContracts').then((data) => {
        setContracts((data as GoFastContract[]) || [])
      })
    }, 60000)
    return () => clearInterval(interval)
  }, [])

  const filteredContracts = contracts.filter(c => {
    if (filter === 'solo') return c.type === 'solo'
    if (filter === 'crew') return c.type === 'crew'
    if (filter === 'fixed') return !!c.fixedTime
    return true
  })

  // Store absolute cooldown end time when data arrives
  useEffect(() => {
    const cd = Math.max(goFastData?.soloCooldown || 0, goFastData?.crewCooldown || 0)
    if (cd > 0) {
      setCooldownEnd(Date.now() + cd * 1000)
    } else {
      setCooldownEnd(0)
      setCooldown(0)
    }
  }, [goFastData?.soloCooldown, goFastData?.crewCooldown])

  // Recompute remaining from absolute end time (survives tab switches)
  useEffect(() => {
    if (cooldownEnd <= 0) { setCooldown(0); return }
    const tick = () => {
      const remaining = Math.max(0, Math.ceil((cooldownEnd - Date.now()) / 1000))
      setCooldown(remaining)
      if (remaining <= 0) setCooldownEnd(0)
    }
    tick()
    const interval = setInterval(tick, 1000)
    return () => clearInterval(interval)
  }, [cooldownEnd])

  // Handle mission response
  useEffect(() => {
    if (!missionResponse) return
    if (missionResponse.error) {
      const msgs: Record<string, string> = {
        BLACKLISTED: 'Accès refusé — blacklisté',
        COOLDOWN: `Cooldown actif (${Math.ceil((missionResponse.remaining || 0) / 60)} min)`,
        ALREADY_ACTIVE: 'Mission déjà en cours',
        NO_GANG: 'Pas de groupe illégal',
        NOT_ENOUGH_CREW: `Membres insuffisants: ${missionResponse.online}/${missionResponse.required}`,
        XP_TOO_LOW: 'XP insuffisante pour ce contrat',
        CONTRACT_EXPIRED: 'Ce contrat a expiré',
        CONTRACT_TAKEN: 'Ce contrat a déjà été accepté',
      }
      setNotification({ type: 'error', title: 'ERREUR', text: msgs[missionResponse.error] || 'Erreur inconnue' })
    } else if (missionResponse.success) {
      setNotification({ type: 'success', title: 'CONTRAT ACCEPTÉ', text: 'Rendez-vous au point de pickup' })
      setSelectedContract(null)
    }
    setAccepting(false)
    const t = setTimeout(() => { setNotification(null); onClearMissionResponse() }, 5000)
    return () => clearTimeout(t)
  }, [missionResponse, onClearMissionResponse])

  // Handle mission result
  useEffect(() => {
    if (!missionResult) return
    if (missionResult.success) {
      setNotification({
        type: 'success',
        title: 'MISSION TERMINÉE',
        text: `Récompense: $${missionResult.payment} — XP: +${missionResult.xpGain}${missionResult.speedBonus ? ' — BONUS VITESSE!' : ''}`,
      })
    } else {
      setNotification({ type: 'error', title: 'MISSION ÉCHOUÉE', text: `XP perdue: -${missionResult.xpLost || 0}` })
    }
    const t = setTimeout(() => { setNotification(null); onClearMissionResult() }, 8000)
    return () => clearTimeout(t)
  }, [missionResult, onClearMissionResult])

  const formatTime = (s: number) => {
    const m = Math.floor(s / 60)
    const sec = s % 60
    return `${String(m).padStart(2, '0')}:${String(sec).padStart(2, '0')}`
  }

  const acceptSoloContract = useCallback(async (contract: GoFastContract) => {
    setAccepting(true)
    const res = await postNUI('crimenet:acceptContract', { contractId: contract.id, type: 'solo' }) as { success: boolean; result?: any }
    if (res?.success) {
      setNotification({ type: 'success', title: 'CONTRAT ACCEPTÉ', text: 'Rendez-vous au point de pickup' })
      setSelectedContract(null)
      // Refresh contracts after acceptance
      postNUI('crimenet:getContracts').then((data) => setContracts((data as GoFastContract[]) || []))
    } else {
      setNotification({ type: 'error', title: 'ERREUR', text: 'Impossible d\'accepter ce contrat' })
    }
    setAccepting(false)
  }, [])

  const openCrewModal = useCallback((contract: GoFastContract) => {
    setSelectedContract(contract)
    setCrewLoading(true)
    setShowCrewModal(true)
    setSelectedMembers(new Set())
    postNUI('crimenet:getCrewMembers').then((members) => {
      setCrewMembers((members as CrewMember[]) || [])
      setCrewLoading(false)
    }).catch(() => {
      setCrewMembers([])
      setCrewLoading(false)
    })
  }, [])

  const toggleMember = useCallback((serverId: number) => {
    setSelectedMembers(prev => {
      const next = new Set(prev)
      if (next.has(serverId)) next.delete(serverId)
      else next.add(serverId)
      return next
    })
  }, [])

  const launchCrewMission = useCallback(async () => {
    if (!selectedContract) return
    const ids = Array.from(selectedMembers)
    setShowCrewModal(false)
    setAccepting(true)
    const res = await postNUI('crimenet:acceptContract', { 
      contractId: selectedContract.id, 
      type: 'crew',
      crewMembers: ids 
    }) as { success: boolean; result?: any }
    if (res?.success) {
      setNotification({ type: 'success', title: 'CONTRAT ACCEPTÉ', text: 'Rendez-vous au point de pickup avec votre équipage' })
      setSelectedContract(null)
      postNUI('crimenet:getContracts').then((data) => setContracts((data as GoFastContract[]) || []))
    } else {
      setNotification({ type: 'error', title: 'ERREUR', text: 'Impossible d\'accepter ce contrat' })
    }
    setAccepting(false)
  }, [selectedContract, selectedMembers])

  const getContractStatus = (c: GoFastContract) => {
    if (c.status === 'accepted') return { label: 'ACCEPTÉ', color: '#dc2626' }
    if (c.status === 'expired') return { label: 'EXPIRÉ', color: '#555' }
    if (playerXP < c.minXP) return { label: `${c.minXP} XP REQ.`, color: '#555' }
    return { label: 'DISPONIBLE', color: '#dc2626' }
  } 

  const canAccept = (c: GoFastContract) => {
    return c.status === 'available' && playerXP >= c.minXP && !hasActive && !isBlacklisted && cooldown <= 0
  }

  // ---- CONTRACT DETAIL VIEW ----
  if (selectedContract && !showCrewModal) {
    const c = selectedContract
    const status = getContractStatus(c)
    const locked = playerXP < c.minXP
    return (
      <div className="jobs-tab">
        {notification && (
          <div className={`jobs-notif jobs-notif--${notification.type}`}>
            <div className="jobs-notif-title">{notification.title}</div>
            <div className="jobs-notif-text">{notification.text}</div>
          </div>
        )}

        <div className="ctr-detail-header">
          <button className="mkt-back" onClick={() => setSelectedContract(null)}>
            <svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" strokeWidth="2"><polyline points="15 18 9 12 15 6" /></svg>
          </button>
          <span className="ctr-detail-title">DÉTAILS DU CONTRAT</span>
        </div>

        <div className="ctr-detail">
          <div className="ctr-detail-badge" style={{ borderColor: status.color }}>
            <span style={{ color: status.color }}>{status.label}</span>
            <span className="ctr-detail-type">{c.type === 'crew' ? 'CREW' : 'SOLO'}</span>
          </div>

          <div className="ctr-detail-name">{c.label}</div>
          {c.description && <div className="ctr-detail-desc">{c.description}</div>}

          <div className="ctr-detail-grid">
            <div className="ctr-detail-cell">
              <div className="ctr-detail-cell-label">VÉHICULE</div>
              <div className="ctr-detail-cell-value">{c.vehicleLabel}</div>
            </div>
            <div className="ctr-detail-cell">
              <div className="ctr-detail-cell-label">CARGAISON</div>
              <div className="ctr-detail-cell-value">{c.cargoEstimate}</div>
            </div>
            <div className="ctr-detail-cell">
              <div className="ctr-detail-cell-label">REVENU</div>
              <div className="ctr-detail-cell-value ctr-detail-cell-value--money">${c.revenue.toLocaleString()}</div>
            </div>
            <div className="ctr-detail-cell">
              <div className="ctr-detail-cell-label">XP</div>
              <div className="ctr-detail-cell-value">+{c.xpReward}</div>
            </div>
            <div className="ctr-detail-cell">
              <div className="ctr-detail-cell-label">DEADLINE</div>
              <div className="ctr-detail-cell-value">{c.deadline} min</div>
            </div>
            {c.fixedTime && (
              <div className="ctr-detail-cell">
                <div className="ctr-detail-cell-label">DÉPART</div>
                <div className="ctr-detail-cell-value ctr-detail-cell-value--fixed">{c.fixedTime}</div>
              </div>
            )}
            {c.type === 'crew' && (
              <div className="ctr-detail-cell">
                <div className="ctr-detail-cell-label">ÉQUIPAGE</div>
                <div className="ctr-detail-cell-value">{c.crewMin || 2}–{c.crewMax || 6}</div>
              </div>
            )}
          </div>

          {/* Difficulty bar */}
          <div className="ctr-detail-diff">
            <span className="ctr-detail-diff-label">DIFFICULTÉ</span>
            <div className="ctr-detail-diff-bar">
              {Array.from({ length: 10 }).map((_, di) => (
                <div key={di} className={`jobs-diff-seg ${di < c.difficulty ? 'jobs-diff-seg--active' : ''}`} />
              ))}
            </div>
          </div>

          {/* XP requirement warning */}
          {locked && (
            <div className="ctr-detail-locked">
              <svg viewBox="0 0 24 24" width="14" height="14" fill="none" stroke="currentColor" strokeWidth="2">
                <rect x="3" y="11" width="18" height="11" rx="2" ry="2" /><path d="M7 11V7a5 5 0 0 1 10 0v4" />
              </svg>
              <span>XP insuffisante — {playerXP}/{c.minXP} XP requis</span>
            </div>
          )}

          {/* Fixed time warning */}
          {c.fixedTime && (
            <div className="ctr-detail-fixed-warn">
              <svg viewBox="0 0 24 24" width="14" height="14" fill="none" stroke="currentColor" strokeWidth="2">
                <circle cx="12" cy="12" r="10" /><polyline points="12 6 12 12 16 14" />
              </svg>
              <span>Contrat à heure fixe — Ne pas compléter entraîne une perte de réputation</span>
            </div>
          )}

          {/* Accept button */}
          <div className="ctr-detail-actions">
            {c.type === 'solo' ? (
              <button
                className="jobs-btn jobs-btn--primary"
                disabled={!canAccept(c) || accepting}
                onClick={() => acceptSoloContract(c)}
              >
                <svg viewBox="0 0 24 24" width="14" height="14" fill="none" stroke="currentColor" strokeWidth="2"><polygon points="5 3 19 12 5 21 5 3" /></svg>
                <span>{accepting ? 'ACCEPTATION...' : 'ACCEPTER LE CONTRAT'}</span>
              </button>
            ) : (
              <button
                className="jobs-btn jobs-btn--primary"
                disabled={!canAccept(c) || accepting || !goFastData?.isIllegal}
                onClick={() => openCrewModal(c)}
              >
                <svg viewBox="0 0 24 24" width="14" height="14" fill="none" stroke="currentColor" strokeWidth="2">
                  <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" /><circle cx="9" cy="7" r="4" />
                </svg>
                <span>FORMER L'ÉQUIPAGE</span>
              </button>
            )}
          </div>
        </div>
      </div>
    )
  }

  // ---- CREW MEMBER SELECTION MODAL ----
  const crewModalEl = showCrewModal && selectedContract ? (
    <div className="crew-modal-overlay" onClick={() => { setShowCrewModal(false); setSelectedContract(null) }}>
      <div className="crew-modal" onClick={e => e.stopPropagation()}>
        <div className="crew-modal-header">
          <div className="crew-modal-title">SÉLECTION ÉQUIPAGE</div>
          <div className="crew-modal-subtitle">
            {selectedContract.crewMin || 2}–{selectedContract.crewMax || 6} membres (vous inclus) — {selectedMembers.size + 1}
          </div>
          <button className="crew-modal-close" onClick={() => { setShowCrewModal(false); setSelectedContract(null) }}>✕</button>
        </div>

        <div className="crew-modal-body">
          {crewLoading ? (
            <div className="crew-modal-loading">Chargement des membres...</div>
          ) : crewMembers.length === 0 ? (
            <div className="crew-modal-empty">Aucun membre en ligne</div>
          ) : (
            crewMembers.map(member => {
              const selected = selectedMembers.has(member.serverId)
              return (
                <div
                  key={member.serverId}
                  className={`crew-member ${selected ? 'crew-member--selected' : ''}`}
                  onClick={() => toggleMember(member.serverId)}
                >
                  <div className="crew-member-check">
                    {selected ? (
                      <svg viewBox="0 0 24 24" width="14" height="14" fill="none" stroke="#22c55e" strokeWidth="3"><polyline points="20 6 9 17 4 12" /></svg>
                    ) : (
                      <div className="crew-member-check-empty" />
                    )}
                  </div>
                  <div className="crew-member-info">
                    <div className="crew-member-name">{member.name}</div>
                    <div className="crew-member-grade">{member.grade}</div>
                  </div>
                  <div className="crew-member-id">ID: {member.serverId}</div>
                </div>
              )
            })
          )}
        </div>

        <div className="crew-modal-footer">
          <button
            className="jobs-btn jobs-btn--primary crew-modal-launch"
            disabled={selectedMembers.size + 1 < (selectedContract.crewMin || 2)}
            onClick={launchCrewMission}
          >
            <svg viewBox="0 0 24 24" width="14" height="14" fill="none" stroke="currentColor" strokeWidth="2"><polygon points="5 3 19 12 5 21 5 3" /></svg>
            <span>LANCER ({selectedMembers.size + 1}/{selectedContract.crewMin || 2})</span>
          </button>
        </div>
      </div>
    </div>
  ) : null

  // ---- MAIN CONTRACTS LIST VIEW ----
  return (
    <div className="jobs-tab">
      {crewModalEl}

      {/* Notification */}
      {notification && (
        <div className={`jobs-notif jobs-notif--${notification.type}`}>
          <div className="jobs-notif-title">{notification.title}</div>
          <div className="jobs-notif-text">{notification.text}</div>
        </div>
      )}

      {/* Active mission */}
      {goFastData?.activeMission && (
        <div className="jobs-active">
          <div className="jobs-active-badge">MISSION ACTIVE</div>
          <div className="jobs-active-name">{goFastData.activeMission.tierName || 'Mission'}</div>
          <div className="jobs-active-meta">
            {goFastData.activeMission.isCrew ? 'CREW' : 'SOLO'} — {goFastData.activeMission.state?.toUpperCase()}
          </div>
        </div>
      )}

      {/* Cooldown */}
      {cooldown > 0 && !hasActive && (
        <div className="jobs-cooldown">
          <div className="jobs-cooldown-label">PROCHAIN CONTRAT</div>
          <div className="jobs-cooldown-timer">{formatTime(cooldown)}</div>
        </div>
      )}

      {/* Filter bar */}
      <div className="ctr-filters">
        {([
          { id: 'all', label: 'TOUS' },
          { id: 'solo', label: 'SOLO' },
          { id: 'crew', label: 'CREW' },
          { id: 'fixed', label: 'HEURE FIXE' },
        ] as { id: ContractFilter; label: string }[]).map(f => (
          <button
            key={f.id}
            className={`ctr-filter ${filter === f.id ? 'ctr-filter--active' : ''}`}
            onClick={() => setFilter(f.id)}
          >
            {f.label}
          </button>
        ))}
      </div>

      {/* XP indicator */}
      <div className="ctr-xp-bar">
        <span className="ctr-xp-label">TON XP</span>
        <span className="ctr-xp-value">{playerXP}</span>
      </div>

      {/* Contract list */}
      <div className="ctr-section-label">
        CONTRATS DISPONIBLES
        <span className="ctr-section-count">{filteredContracts.length}</span>
      </div>

      <div className="ctr-list">
        {filteredContracts.length === 0 ? (
          <div className="jobs-empty">Aucun contrat disponible actuellement</div>
        ) : (
          filteredContracts.map((c, i) => {
            const status = getContractStatus(c)
            const locked = playerXP < c.minXP
            return (
              <div
                key={c.id}
                className={`ctr-card ${locked ? 'ctr-card--locked' : ''} ${c.fixedTime ? 'ctr-card--fixed' : ''}`}
                style={{ animationDelay: `${i * 0.04}s` }}
                onClick={() => !locked && setSelectedContract(c)}
              >
                <div className="ctr-card-left">
                  <div className="ctr-card-type" style={{ background: c.type === 'crew' ? '#7c3aed' : '#2563eb' }}>
                    {c.type === 'crew' ? 'C' : 'S'}
                  </div>
                </div>
                <div className="ctr-card-body">
                  <div className="ctr-card-top">
                    <span className="ctr-card-label">{c.label}</span>
                    <span className="ctr-card-status" style={{ color: status.color }}>{status.label}</span>
                  </div>
                  <div className="ctr-card-info">
                    <span>{c.vehicleLabel}</span>
                    <span className="ctr-card-sep">•</span>
                    <span>{c.cargoEstimate}</span>
                    {c.fixedTime && (
                      <>
                        <span className="ctr-card-sep">•</span>
                        <span className="ctr-card-fixed-time">{c.fixedTime}</span>
                      </>
                    )}
                  </div>
                  <div className="ctr-card-bottom">
                    <span className="ctr-card-revenue">${c.revenue.toLocaleString()}</span>
                    <span className="ctr-card-deadline">{c.deadline}min</span>
                    <div className="ctr-card-diff">
                      {Array.from({ length: 5 }).map((_, di) => (
                        <div key={di} className={`jobs-diff-seg ${di < Math.ceil(c.difficulty / 2) ? 'jobs-diff-seg--active' : ''}`} />
                      ))}
                    </div>
                  </div>
                </div>
                {locked && (
                  <div className="ctr-card-lock">
                    <svg viewBox="0 0 24 24" width="14" height="14" fill="none" stroke="currentColor" strokeWidth="2">
                      <rect x="3" y="11" width="18" height="11" rx="2" ry="2" /><path d="M7 11V7a5 5 0 0 1 10 0v4" />
                    </svg>
                  </div>
                )}
              </div>
            )
          })
        )}
      </div>
    </div>
  )
}
