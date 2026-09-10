import { useState } from 'react'
import { MenuItem } from './types'

interface ImageSelectorProps {
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

const ImageSelectorComponent = ({ item, index, primaryColor = '#c0c0c0', serverLuaColor }: ImageSelectorProps) => {
  const [selectedIdx, setSelectedIdx] = useState(item.selectedIndex || 0)
  const images = item.images || []
  const columns = item.columns || 3

  const handleImageClick = (idx: number) => {
    setSelectedIdx(idx)
    
    fetch(`https://${(window as any).GetParentResourceName?.() || 'nui-frame-test'}/panelChanged`, {
      method: 'POST',
      body: JSON.stringify({ 
        type: 'imageselector', 
        index: idx,
        image: images[idx]
      })
    })
  }

  return (
    <div key={`imageselector-${index}`} className="bg-black/85 px-4 py-3 mb-2" style={{ borderRadius: '8px' }}>
      {item.label && (
        <div 
          className="text-white text-sm font-semibold mb-3 uppercase tracking-wide border-b pb-2"
          style={{ borderColor: `${primaryColor}4D` }}
        >
          {parseGTAColors(item.label, serverLuaColor, primaryColor)}
        </div>
      )}
      
      {/* Image Grid */}
      <div 
        className="grid gap-2"
        style={{ 
          gridTemplateColumns: `repeat(${columns}, 1fr)` 
        }}
      >
        {images.map((img, idx) => (
          <div
            key={idx}
            className="relative cursor-pointer rounded overflow-hidden border-2 transition-all"
            onClick={() => handleImageClick(idx)}
            style={{ 
              aspectRatio: '1',
              borderColor: selectedIdx === idx ? primaryColor : 'var(--text-tertiary)',
              boxShadow: selectedIdx === idx ? `0 10px 15px -3px ${primaryColor}80, 0 4px 6px -4px ${primaryColor}80` : 'none'
            }}
            onMouseEnter={(e) => {
              if (selectedIdx !== idx) {
                e.currentTarget.style.borderColor = 'var(--text-secondary)'
              }
            }}
            onMouseLeave={(e) => {
              if (selectedIdx !== idx) {
                e.currentTarget.style.borderColor = 'var(--text-tertiary)'
              }
            }}
          >
            <img 
              src={img.url} 
              alt={img.label || `Image ${idx + 1}`}
              className="w-full h-full object-cover"
            />
            
            {/* Selected Indicator */}
            {selectedIdx === idx && (
              <div 
                className="absolute top-1 right-1 w-5 h-5 rounded-full flex items-center justify-center"
                style={{ backgroundColor: primaryColor }}
              >
                <svg className="w-3 h-3 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={3} d="M5 13l4 4L19 7" />
                </svg>
              </div>
            )}
            
            {/* Label */}
            {img.label && (
              <div className="absolute bottom-0 left-0 right-0 bg-black/85 px-2 py-1">
                <span className="text-white text-[10px] font-medium truncate block">
                  {img.label}
                </span>
              </div>
            )}
          </div>
        ))}
      </div>
    </div>
  )
}

export default ImageSelectorComponent
