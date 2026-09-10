import { useState } from 'react'
import { MenuItem } from './types'

interface ColorPanelProps {
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

const ColorPanelComponent = ({ item, index, primaryColor = '#c0c0c0', serverLuaColor }: ColorPanelProps) => {
  const [color, setColor] = useState(item.currentColor || { r: 255, g: 255, b: 255 })

  const handleColorChange = (component: 'r' | 'g' | 'b', value: number) => {
    const newColor = { ...color, [component]: value }
    setColor(newColor)
    
    fetch(`https://${(window as any).GetParentResourceName?.() || 'nui-frame-test'}/panelChanged`, {
      method: 'POST',
      body: JSON.stringify({ type: 'color', color: newColor })
    })
  }

  return (
    <div key={`colorpanel-${index}`} className="bg-black/85 px-4 py-3 mb-2" style={{ borderRadius: '8px' }}>
      {item.label && (
        <div 
          className="text-white text-sm font-semibold mb-3 uppercase tracking-wide border-b pb-2"
          style={{ borderColor: `${primaryColor}4D` }}
        >
          {parseGTAColors(item.label, serverLuaColor, primaryColor)}
        </div>
      )}
      
      {/* Color Preview */}
      <div 
        className="w-full h-16 rounded mb-3 border-2 border-white/20"
        style={{ backgroundColor: `rgb(${color.r}, ${color.g}, ${color.b})` }}
      />
      
      {/* RGB Sliders */}
      <div className="space-y-2">
        {(['r', 'g', 'b'] as const).map((component) => (
          <div key={component} className="space-y-1">
            <div className="flex justify-between text-xs">
              <span className="text-white/70 uppercase">{component}</span>
              <span className="text-white/90">{color[component]}</span>
            </div>
            <input
              type="range"
              min="0"
              max="255"
              value={color[component]}
              onChange={(e) => handleColorChange(component, parseInt(e.target.value))}
              className="w-full h-2 rounded-full appearance-none cursor-pointer"
              style={{
                background: `linear-gradient(to right, 
                  ${component === 'r' ? 'rgb(0,0,0)' : `rgb(0,${color.g},${color.b})`}, 
                  ${component === 'r' ? `rgb(255,${color.g},${color.b})` : component === 'g' ? `rgb(${color.r},255,${color.b})` : `rgb(${color.r},${color.g},255)`})`
              }}
            />
          </div>
        ))}
      </div>
    </div>
  )
}

export default ColorPanelComponent
