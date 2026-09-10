import { GoFastData } from '../types'

interface Props {
  goFastData: GoFastData | null
  onClose: () => void
}

export default function ProgressionOverlay({ goFastData, onClose }: Props) {
  const tiers = goFastData?.tiers || []
  const currentTierIdx = goFastData?.tier?.index || 0
  const playerXP = goFastData?.xp || 0

  return (
    <div className="prog-overlay" onClick={onClose}>
      <div className="prog-panel" onClick={e => e.stopPropagation()}>
        {/* Header */}
        <div className="prog-header">
          <button className="prog-back" onClick={onClose}>
            <svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" strokeWidth="2">
              <polyline points="15 18 9 12 15 6" />
            </svg>
          </button>
          <span className="prog-title">PROGRESSION</span>
        </div>

        {/* Current status */}
        <div className="prog-current">
          <div className="prog-current-xp">{playerXP} XP</div>
          <div className="prog-current-tier">
            {goFastData?.tier?.label || '---'}
          </div>
        </div>

        {/* Tier progression */}
        <div className="prog-tiers">
          {tiers.map((tier, i) => {
            const isCurrent = tier.index === currentTierIdx
            const isUnlocked = playerXP >= tier.minXP
            const isNext = !isUnlocked && (i === 0 || playerXP >= tiers[i - 1].minXP)

            return (
              <div
                key={tier.name}
                className={`prog-tier ${isCurrent ? 'prog-tier--current' : ''} ${isUnlocked ? 'prog-tier--unlocked' : ''} ${isNext ? 'prog-tier--next' : ''}`}
              >
                <div className="prog-tier-line">
                  <div className={`prog-tier-dot ${isCurrent ? 'prog-tier-dot--current' : ''} ${isUnlocked ? 'prog-tier-dot--unlocked' : ''}`} />
                  {i < tiers.length - 1 && (
                    <div className={`prog-tier-connector ${isUnlocked ? 'prog-tier-connector--unlocked' : ''}`} />
                  )}
                </div>
                <div className="prog-tier-info">
                  <div className="prog-tier-name">{tier.label}</div>
                  <div className="prog-tier-xp">{tier.minXP} XP requis</div>
                  <div className="prog-tier-desc">{tier.description}</div>
                </div>
                {isCurrent && (
                  <div className="prog-tier-badge">ACTUEL</div>
                )}
                {isNext && !isCurrent && (
                  <div className="prog-tier-remaining">
                    +{tier.minXP - playerXP} XP
                  </div>
                )}
              </div>
            )
          })}
        </div>

        {/* XP Progress bar */}
        <div className="prog-xp-section">
          <div className="prog-xp-label">EXPÉRIENCE TOTALE</div>
          <div className="prog-xp-bar-container">
            <div className="prog-xp-bar">
              <div
                className="prog-xp-bar-fill"
                style={{ width: `${Math.min(100, ((playerXP || 0) / Math.max(tiers[tiers.length - 1]?.minXP || 1, 1)) * 100)}%` }}
              />
            </div>
            <div className="prog-xp-labels">
              <span>0 XP</span>
              <span>{tiers[tiers.length - 1]?.minXP || '???'} XP</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
