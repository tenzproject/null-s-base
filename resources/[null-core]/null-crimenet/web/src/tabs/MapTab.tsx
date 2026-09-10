import { GoFastData } from '../types'

interface Props {
  goFastData: GoFastData | null
}

export default function MapTab({ goFastData }: Props) {
  const tiers = goFastData?.tiers || []
  const currentTierIdx = goFastData?.tier?.index || 0

  return (
    <div className="map-tab">
      {/* Zone legend */}
      <div className="map-section">
        <div className="map-section-label">ZONES D'OPÉRATION</div>
        <div className="map-legend">
          <div className="map-legend-item">
            <span className="map-legend-dot map-legend-dot--pickup" />
            <span>Points de pickup</span>
          </div>
          <div className="map-legend-item">
            <span className="map-legend-dot map-legend-dot--delivery" />
            <span>Points de livraison</span>
          </div>
          <div className="map-legend-item">
            <span className="map-legend-dot map-legend-dot--danger" />
            <span>Zone de danger</span>
          </div>
        </div>
        <div className="map-note">
          Les coordonnées exactes sont révélées lors de l'acceptation d'un contrat.
        </div>
      </div>

      {/* Tier progression */}
      <div className="map-section">
        <div className="map-section-label">PROGRESSION</div>
        <div className="map-tiers">
          {tiers.map((tier, i) => {
            const isCurrent = tier.index === currentTierIdx
            const isUnlocked = (goFastData?.xp || 0) >= tier.minXP
            return (
              <div key={tier.name} className={`map-tier ${isCurrent ? 'map-tier--current' : ''} ${isUnlocked ? 'map-tier--unlocked' : 'map-tier--locked'}`}>
                <div className="map-tier-line">
                  <div className={`map-tier-dot ${isCurrent ? 'map-tier-dot--current' : ''} ${isUnlocked ? 'map-tier-dot--unlocked' : ''}`} />
                  {i < tiers.length - 1 && (
                    <div className={`map-tier-connector ${isUnlocked ? 'map-tier-connector--unlocked' : ''}`} />
                  )}
                </div>
                <div className="map-tier-info">
                  <div className="map-tier-name">{tier.label}</div>
                  <div className="map-tier-xp">{tier.minXP} XP</div>
                  <div className="map-tier-desc">{tier.description}</div>
                </div>
                {isCurrent && <div className="map-tier-badge">ACTUEL</div>}
              </div>
            )
          })}
        </div>
      </div>

      {/* XP Progress bar */}
      {goFastData && (
        <div className="map-section">
          <div className="map-section-label">EXPÉRIENCE</div>
          <div className="map-xp-bar-container">
            <div className="map-xp-bar">
              <div
                className="map-xp-bar-fill"
                style={{ width: `${Math.min(100, ((goFastData.xp || 0) / Math.max(tiers[tiers.length - 1]?.minXP || 1, 1)) * 100)}%` }}
              />
            </div>
            <div className="map-xp-labels">
              <span>{goFastData.xp} XP</span>
              <span>{tiers[tiers.length - 1]?.minXP || '???'} XP</span>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
