import { useState, useEffect } from 'react'

interface Props {
  onComplete: () => void
}

export default function IntroAnimation({ onComplete }: Props) {
  const [phase, setPhase] = useState(0)
  // 0: black screen
  // 1: glitch flash
  // 2: logo reveal
  // 3: text typing
  // 4: fade out

  useEffect(() => {
    const timers = [
      setTimeout(() => setPhase(1), 400),
      setTimeout(() => setPhase(2), 1000),
      setTimeout(() => setPhase(3), 2000),
      setTimeout(() => setPhase(4), 3200),
      setTimeout(() => onComplete(), 3800),
    ]
    return () => timers.forEach(clearTimeout)
  }, [onComplete])

  return (
    <div className={`intro ${phase >= 4 ? 'intro--fadeout' : ''}`}>
      {/* Scanline overlay */}
      <div className="intro-scanlines" />

      {/* Glitch flash */}
      {phase >= 1 && phase < 3 && (
        <div className="intro-glitch-flash" />
      )}

      {/* Logo */}
      <div className={`intro-logo ${phase >= 2 ? 'intro-logo--visible' : ''}`}>
        <svg viewBox="0 0 100 100" className="intro-logo-svg">
          <circle cx="50" cy="50" r="45" fill="none" stroke="#dc2626" strokeWidth="2" className="intro-circle" />
          <circle cx="50" cy="50" r="35" fill="none" stroke="#dc2626" strokeWidth="1" opacity="0.4" className="intro-circle-inner" />
          {/* Network nodes */}
          <circle cx="50" cy="30" r="3" fill="#dc2626" className="intro-node" />
          <circle cx="30" cy="55" r="3" fill="#dc2626" className="intro-node" />
          <circle cx="70" cy="55" r="3" fill="#dc2626" className="intro-node" />
          <circle cx="50" cy="70" r="3" fill="#dc2626" className="intro-node" />
          {/* Lines */}
          <line x1="50" y1="30" x2="30" y2="55" stroke="#dc2626" strokeWidth="1" opacity="0.6" className="intro-line" />
          <line x1="50" y1="30" x2="70" y2="55" stroke="#dc2626" strokeWidth="1" opacity="0.6" className="intro-line" />
          <line x1="30" y1="55" x2="50" y2="70" stroke="#dc2626" strokeWidth="1" opacity="0.6" className="intro-line" />
          <line x1="70" y1="55" x2="50" y2="70" stroke="#dc2626" strokeWidth="1" opacity="0.6" className="intro-line" />
          <line x1="30" y1="55" x2="70" y2="55" stroke="#dc2626" strokeWidth="1" opacity="0.3" className="intro-line" />
          {/* Center dot */}
          <circle cx="50" cy="50" r="5" fill="#dc2626" className="intro-center" />
        </svg>
      </div>

      {/* Title text */}
      <div className={`intro-title ${phase >= 3 ? 'intro-title--visible' : ''}`}>
        <div className="intro-title-main">CRIMENET</div>
        <div className="intro-title-sub">RÉSEAU SÉCURISÉ</div>
      </div>

      {/* Noise grain */}
      <div className="intro-noise" />
    </div>
  )
}
