interface MenuHeaderProps {
  title?: string
  subtitle: string
  pageInfo?: string
}

// Parse GTA color codes
const parseGTAColors = (text: string): JSX.Element[] => {
  const colorMap: Record<string, string> = {
    '~r~': '#e74c3c',
    '~g~': '#2ecc71',
    '~b~': '#3498db',
    '~y~': '#f1c40f',
    '~p~': '#9b59b6',
    '~o~': '#e67e22',
    '~c~': '#95a5a6',
    '~m~': '#e91e63',
    '~u~': '#1a1a1a',
    '~l~': '#000000',
    '~w~': '#ffffff',
    '~s~': 'inherit',
    '~h~': 'inherit',
    '~n~': 'inherit',
  }

  if (!text || typeof text !== 'string') {
    return [<span key="0">{String(text || '')}</span>]
  }
  const regex = /(~[a-z]~)/gi
  const parts = text.split(regex)
  const elements: JSX.Element[] = []
  let currentColor = 'inherit'

  parts.forEach((part, index) => {
    const lowerPart = part.toLowerCase()
    if (colorMap[lowerPart] !== undefined) {
      currentColor = colorMap[lowerPart]
    } else if (part) {
      elements.push(
        <span key={index} style={{ color: currentColor }}>
          {part}
        </span>
      )
    }
  })

  return elements
}
 
const MenuHeader = ({ subtitle, pageInfo }: MenuHeaderProps) => {
  return (
    <div>
      {/* Bannière PNG */}
      <div 
        className="relative overflow-hidden flex items-center justify-center"
        style={{ 
          borderRadius: '8px 8px 0 0',
          maxHeight: '100px',
          minHeight: '80px',
          boxShadow: '0 8px 32px rgba(0, 0, 0, 0.4)',
        }}
      >
        <img 
          src="./assets/img/banniere.png" 
          alt="Banner" 
          className="h-full object-contain"
          style={{ maxWidth: '100%' }}
        />
      </div>

      {/* Sous-titre */}
      {subtitle && (
        <div 
          className="bg-black/95 px-4 py-2 flex justify-between items-center border-b border-white/10"
        >
          <span 
            className="text-white text-sm font-semibold leading-[1.2] tracking-[.5px] uppercase tracking-wider"
            style={{
              textShadow: "0 0 20px var(--text-tertiary)"
            }}
          >
            {parseGTAColors(subtitle)} 
          </span>
          {pageInfo && (
            <span className="text-white/60 text-xs">
              {pageInfo}
            </span>
          )}
        </div>
      )}
    </div>
  )
}

export default MenuHeader