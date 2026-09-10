export default function InfoTab() {
  return (
    <div className="info-tab">
      <div className="info-header">
        <div className="info-logo">
          <svg viewBox="0 0 40 40" width="40" height="40">
            <circle cx="20" cy="20" r="16" fill="none" stroke="#888" strokeWidth="1.5" />
            <circle cx="20" cy="20" r="6" fill="#888" />
            <circle cx="20" cy="8" r="3" fill="#888" />
            <circle cx="8" cy="26" r="3" fill="#888" />
            <circle cx="32" cy="26" r="3" fill="#888" />
            <line x1="20" y1="8" x2="8" y2="26" stroke="#888" strokeWidth="0.8" opacity="0.5" />
            <line x1="20" y1="8" x2="32" y2="26" stroke="#888" strokeWidth="0.8" opacity="0.5" />
            <line x1="8" y1="26" x2="32" y2="26" stroke="#888" strokeWidth="0.8" opacity="0.5" />
          </svg>
        </div>
        <div className="info-header-text">
          <div className="info-title">CRIMENET</div>
          <div className="info-version">Réseau Social Chiffré</div>
        </div>
      </div>

      <div className="info-section">
        <div className="info-section-icon">
          <svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" strokeWidth="2">
            <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z" />
          </svg>
        </div>
        <div className="info-section-title">AVERTISSEMENT LÉGAL</div>
        <div className="info-section-body">
          CrimeNet est une plateforme de mise en relation chiffrée. L'application ne propose, n'organise et ne cautionne <strong>aucune activité illégale</strong>.
        </div>
        <div className="info-section-body">
          Les utilisateurs sont <strong>seuls responsables</strong> de l'usage qu'ils font de cette plateforme et de leurs actions. CrimeNet se décharge de toute responsabilité concernant les conséquences subies par ses utilisateurs.
        </div>
      </div>

      <div className="info-divider" />

      <div className="info-section">
        <div className="info-section-icon info-section-icon--danger">
          <svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" strokeWidth="2">
            <path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z" />
            <line x1="12" y1="9" x2="12" y2="13" /><line x1="12" y1="17" x2="12.01" y2="17" />
          </svg>
        </div>
        <div className="info-section-title">TRAHISON &amp; SANCTIONS</div>
        <div className="info-section-body">
          Toute <strong>trahison</strong> envers le réseau CrimeNet entraînera des conséquences immédiates et irréversibles :
        </div>
        <ul className="info-list">
          <li>Bannissement définitif de la plateforme</li>
          <li>Signalement à l'ensemble du réseau</li>
          <li>Traque active par les services de CrimeNet</li>
          <li>Perte de tous les contacts et données</li>
        </ul>
        <div className="info-warn-box">
          Le réseau n'oublie jamais. Réfléchissez avant d'agir.
        </div>
      </div>

      <div className="info-divider" />

      <div className="info-section">
        <div className="info-section-icon">
          <svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" strokeWidth="2">
            <rect x="3" y="11" width="18" height="11" rx="2" ry="2" />
            <path d="M7 11V7a5 5 0 0 1 10 0v4" />
          </svg>
        </div>
        <div className="info-section-title">CONFIDENTIALITÉ</div>
        <div className="info-section-body">
          Toutes les communications transitant par CrimeNet sont <strong>chiffrées de bout en bout</strong>. Aucune donnée n'est partagée avec des tiers.
        </div>
        <div className="info-section-body">
          Les pseudonymes inappropriés, insultants ou faisant référence au staff seront <strong>bannis sans avertissement</strong>.
        </div>
      </div>

      <div className="info-divider" />

      <div className="info-section">
        <div className="info-section-icon">
          <svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" strokeWidth="2">
            <circle cx="12" cy="12" r="10" /><line x1="12" y1="16" x2="12" y2="12" /><line x1="12" y1="8" x2="12.01" y2="8" />
          </svg>
        </div>
        <div className="info-section-title">RÈGLES D'UTILISATION</div>
        <ul className="info-list">
          <li>Ne partagez jamais vos informations personnelles réelles</li>
          <li>Utilisez un pseudonyme approprié et respectueux</li>
          <li>Ne tentez pas de compromettre le réseau</li>
          <li>Respectez les autres membres du réseau</li>
        </ul>
      </div>

      <div className="info-footer">
        <span>CRIMENET v2.0</span>
        <span>PROTOCOLE CHIFFRÉ</span>
      </div>
    </div>
  )
}
