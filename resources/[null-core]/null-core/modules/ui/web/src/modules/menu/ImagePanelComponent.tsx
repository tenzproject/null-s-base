import { MenuItem } from './types'

interface ImagePanelProps {
  item: MenuItem
  index: number
  primaryColor?: string
  serverLuaColor?: string
}

const parseGTAColors = (text: string, serverLuaColor?: string, primaryColor?: string): JSX.Element[] => {
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
      // If this color code matches serverLuaColor and we have a primaryColor, use primaryColor
      if (serverLuaColor && primaryColor && lowerPart === serverLuaColor.toLowerCase()) {
        currentColor = primaryColor
      } else {
        currentColor = colorMap[lowerPart]
      }
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

const ImagePanelComponent = ({ item, index, primaryColor = '#c0c0c0', serverLuaColor }: ImagePanelProps) => {
  const handleImageClick = () => {
    if (item.clickable) {
      fetch(`https://${(window as any).GetParentResourceName?.() || 'nui-frame-test'}/panelChanged`, {
        method: 'POST',
        body: JSON.stringify({ type: 'image', action: 'click' })
      })
    }
  }

  return (
    <div key={`imagepanel-${index}`} className="bg-black/85 px-4 py-3 mb-2" style={{ borderRadius: '8px' }}>
      {item.label && (
        <div 
          className="text-white text-sm font-semibold mb-3 uppercase tracking-wide border-b pb-2"
          style={{ borderColor: `${primaryColor}4D` }}
        >
          {parseGTAColors(item.label, serverLuaColor, primaryColor)}
        </div>
      )}
      
      {/* Image */}
      <div 
        className="w-full rounded overflow-hidden border-2 transition-colors"
        style={{ 
          height: `${item.height || 200}px`,
          borderColor: 'var(--text-tertiary)',
          cursor: item.clickable ? 'pointer' : 'default'
        }}
        onClick={handleImageClick}
        onMouseEnter={(e) => {
          if (item.clickable) {
            e.currentTarget.style.borderColor = `${primaryColor}80`
          }
        }}
        onMouseLeave={(e) => {
          if (item.clickable) {
            e.currentTarget.style.borderColor = 'var(--text-tertiary)'
          }
        }}
      >
        {item.imageUrl ? (
          <img 
            src={item.imageUrl} 
            alt={item.label || 'Image'} 
            className="w-full h-full object-cover"
          />
        ) : (
          <div className="w-full h-full flex items-center justify-center bg-black/50 text-white/30 text-sm">
            Aucune image
          </div>
        )}
      </div>
    </div>
  )
}

export default ImagePanelComponent
