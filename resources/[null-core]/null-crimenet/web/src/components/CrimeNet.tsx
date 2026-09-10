import { useState, useEffect } from 'react'
import { CrimeNetData, GoFastData, MissionResponse, MissionResult } from '../types'
import MessagesTab from '../tabs/MessagesTab'
import NetworkTab from '../tabs/NetworkTab'
import MarketTab from '../tabs/MarketTab'
import JobsTab from '../tabs/JobsTab'
import ProfileTab from '../tabs/ProfileTab'
import InfoTab from '../tabs/InfoTab'
import ProgressionOverlay from '../tabs/ProgressionOverlay'

type TabId = 'messages' | 'network' | 'market' | 'jobs' | 'profile'

interface Props {
  cnData: CrimeNetData | null
  goFastData: GoFastData | null
  missionResponse: MissionResponse | null
  missionResult: MissionResult | null
  betrayed: boolean
  onRequestMission: (type: 'solo' | 'crew', memberIds?: number[]) => void
  onRefreshData: () => void
  onClearMissionResponse: () => void
  onClearMissionResult: () => void
}

const TABS: { id: TabId; label: string; icon: JSX.Element }[] = [
  {
    id: 'network', label: 'RÉSEAU',
    icon: <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><circle cx="12" cy="12" r="3" /><circle cx="4" cy="6" r="2" /><circle cx="20" cy="6" r="2" /><circle cx="4" cy="18" r="2" /><circle cx="20" cy="18" r="2" /><line x1="9.5" y1="10.5" x2="5.5" y2="7.5" /><line x1="14.5" y1="10.5" x2="18.5" y2="7.5" /><line x1="9.5" y1="13.5" x2="5.5" y2="16.5" /><line x1="14.5" y1="13.5" x2="18.5" y2="16.5" /></svg>,
  },
  {
    id: 'messages', label: 'MSG',
    icon: <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z" /></svg>,
  },
  {
    id: 'market', label: 'MARCH\u00c9',
    icon: <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><rect x="2" y="7" width="20" height="14" rx="2" /><path d="M16 7V5a2 2 0 0 0-2-2h-4a2 2 0 0 0-2 2v2" /><path d="M12 12v3" /><path d="M12 12a1 1 0 1 0 0-2 1 1 0 0 0 0 2z" /></svg>,
  },
  {
    id: 'jobs', label: 'JOBS',
    icon: <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><rect x="3" y="3" width="18" height="18" rx="1" /><path d="M9 3v18" /><path d="M3 9h6" /><path d="M3 15h6" /><path d="M13 8h4" /><path d="M13 12h4" /><path d="M13 16h4" /></svg>,
  },
  {
    id: 'profile', label: 'PROFIL',
    icon: <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2" /><circle cx="12" cy="7" r="4" /></svg>,
  },
]

export default function CrimeNet({
  cnData, goFastData, missionResponse, missionResult, betrayed,
  onRequestMission, onRefreshData, onClearMissionResponse, onClearMissionResult,
}: Props) {
  const [activeTab, setActiveTab] = useState<TabId>('network')
  const [mounted, setMounted] = useState(false)
  const [showInfo, setShowInfo] = useState(false)
  const [showProgression, setShowProgression] = useState(false)

  useEffect(() => {
    requestAnimationFrame(() => setMounted(true))
  }, [])

  const totalUnread = cnData?.conversations?.reduce((sum, c) => sum + c.unread, 0) || 0

  return (
    <div className={`cn ${mounted ? 'cn--mounted' : ''}`}>
      {/* Header */}
      <div className="cn-header">
        <div className="cn-header-left">
          <div className="cn-header-logo">
            <svg viewBox="0 0 20 20" width="16" height="16">
              <circle cx="10" cy="10" r="8" fill="none" stroke="#dc2626" strokeWidth="1.5" />
              <circle cx="10" cy="10" r="3" fill="#dc2626" />
              <circle cx="10" cy="4" r="1.5" fill="#dc2626" />
              <circle cx="4" cy="13" r="1.5" fill="#dc2626" />
              <circle cx="16" cy="13" r="1.5" fill="#dc2626" />
              <line x1="10" y1="4" x2="4" y2="13" stroke="#dc2626" strokeWidth="0.8" opacity="0.5" />
              <line x1="10" y1="4" x2="16" y2="13" stroke="#dc2626" strokeWidth="0.8" opacity="0.5" />
              <line x1="4" y1="13" x2="16" y2="13" stroke="#dc2626" strokeWidth="0.8" opacity="0.5" />
            </svg>
          </div>
          <span className="cn-header-title">CRIMENET</span>
          <button className="cn-header-info-btn" onClick={() => setShowInfo(v => !v)} title="Informations">
            <svg viewBox="0 0 24 24" width="14" height="14" fill="none" stroke="currentColor" strokeWidth="2"><circle cx="12" cy="12" r="10" /><line x1="12" y1="16" x2="12" y2="12" /><line x1="12" y1="8" x2="12.01" y2="8" /></svg>
          </button>
        </div>
        <div className="cn-header-right">
          <div className="cn-header-status">
            <span className="cn-status-dot" />
            <span className="cn-status-label">ENCRYPTED</span>
          </div>
        </div>
      </div>

      {/* Tab content */}
      <div className="cn-content">
        {activeTab === 'network' && (
          <NetworkTab cnData={cnData} />
        )}
        {activeTab === 'messages' && (
          <MessagesTab cnData={cnData} onRefreshData={onRefreshData} />
        )}
        {activeTab === 'market' && (
          <MarketTab cnData={cnData} onRefreshData={onRefreshData} />
        )}
        {activeTab === 'jobs' && (
          <JobsTab
            goFastData={goFastData}
            missionResponse={missionResponse}
            missionResult={missionResult}
            onRequestMission={onRequestMission}
            onClearMissionResponse={onClearMissionResponse}
            onClearMissionResult={onClearMissionResult}
          />
        )}
        {activeTab === 'profile' && (
          <ProfileTab
            cnData={cnData}
            goFastData={goFastData}
            onRefreshData={onRefreshData}
            onShowProgression={() => setShowProgression(true)}
          />
        )}
      </div>

      {/* Progression overlay */}
      {showProgression && (
        <ProgressionOverlay
          goFastData={goFastData}
          onClose={() => setShowProgression(false)}
        />
      )}

      {/* Info overlay */}
      {showInfo && (
        <div className="cn-info-overlay">
          <button className="cn-info-close" onClick={() => setShowInfo(false)}>✕</button>
          <InfoTab />
        </div>
      )}

      {/* Blacklist overlay */}
      {goFastData?.blacklisted && (
        <div className="cn-blacklist-overlay">
          <div className="cn-blacklist-icon">
            <svg viewBox="0 0 24 24" width="48" height="48" fill="none" stroke="#dc2626" strokeWidth="2">
              <path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z" />
              <line x1="12" y1="9" x2="12" y2="13" /><line x1="12" y1="17" x2="12.01" y2="17" />
            </svg>
          </div>
          <div className="cn-blacklist-title">ACCÈS REFUSÉ</div>
          <div className="cn-blacklist-text">
            Ton identité a été compromise.<br />
            Le réseau ne te fait plus confiance.
          </div>
        </div>
      )}

      {/* Bottom tab bar */}
      <div className="cn-tabbar">
        {TABS.map(tab => (
          <button
            key={tab.id}
            className={`cn-tabbar-btn ${activeTab === tab.id ? 'active' : ''}`}
            onClick={() => setActiveTab(tab.id)}
          >
            <span className="cn-tabbar-icon">{tab.icon}</span>
            <span className="cn-tabbar-label">{tab.label}</span>
            {tab.id === 'messages' && totalUnread > 0 && (
              <span className="cn-tabbar-badge">{totalUnread > 9 ? '9+' : totalUnread}</span>
            )}
          </button>
        ))}
      </div>
    </div>
  )
}
