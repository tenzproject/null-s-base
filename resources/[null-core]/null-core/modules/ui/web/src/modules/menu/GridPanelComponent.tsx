import { useState } from 'react'
import { MenuItem } from './types'

interface GridPanelProps {
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

const GridPanelComponent = ({ item, index, primaryColor = '#c0c0c0', serverLuaColor }: GridPanelProps) => {
  const [gridPos, setGridPos] = useState({ 
    x: item.currentX || 0.5, 
    y: item.currentY || 0.5 
  })
  const [isDragging, setIsDragging] = useState(false)

  const handleGridClick = (e: React.MouseEvent<HTMLDivElement>) => {
    const rect = e.currentTarget.getBoundingClientRect()
    const x = (e.clientX - rect.left) / rect.width
    const y = (e.clientY - rect.top) / rect.height
    const newPos = { x: Math.max(0, Math.min(1, x)), y: Math.max(0, Math.min(1, y)) }
    setGridPos(newPos)
    
    fetch(`https://${(window as any).GetParentResourceName?.() || 'nui-frame-test'}/panelChanged`, {
      method: 'POST',
      body: JSON.stringify({ type: 'grid', x: newPos.x, y: newPos.y })
    })
  }

  const handleGridDrag = (e: React.MouseEvent<HTMLDivElement>) => {
    if (!isDragging) return
    const rect = e.currentTarget.getBoundingClientRect()
    const x = (e.clientX - rect.left) / rect.width
    const y = (e.clientY - rect.top) / rect.height
    const newPos = { x: Math.max(0, Math.min(1, x)), y: Math.max(0, Math.min(1, y)) }
    setGridPos(newPos)
    
    fetch(`https://${(window as any).GetParentResourceName?.() || 'nui-frame-test'}/panelChanged`, {
      method: 'POST',
      body: JSON.stringify({ type: 'grid', x: newPos.x, y: newPos.y })
    })
  }

  return (
    <div key={`gridpanel-${index}`} className="bg-black/85 px-4 py-3 mb-2" style={{ borderRadius: '8px' }}>
      {item.label && (
        <div 
          className="text-white text-sm font-semibold mb-3 uppercase tracking-wide border-b pb-2"
          style={{ borderColor: `${primaryColor}4D` }}
        >
          {parseGTAColors(item.label, serverLuaColor, primaryColor)}
        </div>
      )}
      
      {/* Grid */}
      <div 
        className="relative w-full h-48 bg-black/50 rounded border border-white/20 cursor-crosshair"
        onClick={handleGridClick}
        onMouseDown={() => setIsDragging(true)}
        onMouseUp={() => setIsDragging(false)}
        onMouseLeave={() => setIsDragging(false)}
        onMouseMove={handleGridDrag}
      >
        {/* Grid lines */}
        <div className="absolute inset-0 grid grid-cols-5 grid-rows-5">
          {Array.from({ length: 25 }).map((_, i) => (
            <div key={i} className="border border-white/5" />
          ))}
        </div>
        
        {/* Crosshair */}
        <div 
          className="absolute w-3 h-3 rounded-full border-2 border-white transform -translate-x-1/2 -translate-y-1/2 pointer-events-none"
          style={{ 
            left: `${gridPos.x * 100}%`, 
            top: `${gridPos.y * 100}%`,
            backgroundColor: primaryColor
          }}
        />
        
        {/* Horizontal line */}
        <div 
          className="absolute w-full h-px pointer-events-none"
          style={{ 
            top: `${gridPos.y * 100}%`,
            backgroundColor: `${primaryColor}4D`
          }}
        />
        
        {/* Vertical line */}
        <div 
          className="absolute h-full w-px pointer-events-none"
          style={{ 
            left: `${gridPos.x * 100}%`,
            backgroundColor: `${primaryColor}4D`
          }}
        />
      </div>
      
      {/* Labels */}
      <div className="flex justify-between mt-2 text-xs">
        <span className="text-white/70">
          {item.labelX || 'X'}: <span className="text-white/90">{(gridPos.x * 100).toFixed(0)}%</span>
        </span>
        <span className="text-white/70">
          {item.labelY || 'Y'}: <span className="text-white/90">{(gridPos.y * 100).toFixed(0)}%</span>
        </span>
      </div>
    </div>
  )
}

export default GridPanelComponent
