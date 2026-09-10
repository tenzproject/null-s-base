import { MenuItem } from './types'
import { Check, ChevronLeft, ChevronRight, ChevronDown } from 'lucide-react'
import { hexToRgba } from '@/utils/accentColors'

interface MenuItemProps {
  item: MenuItem
  isSelected: boolean
  index?: number
  serverLuaColor?: string
  primaryColor?: string
}

// Parse GTA color codes like ~g~, ~b~, ~r~, etc.
const parseGTAColors = (text: string, color: boolean = true, serverLuaColor?: string, primaryColor?: string): JSX.Element[] => {
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
      if (color) {
        // If this color code matches serverLuaColor and we have a primaryColor, use primaryColor
        if (serverLuaColor && primaryColor && lowerPart === serverLuaColor.toLowerCase()) {
          currentColor = primaryColor
        } else {
          currentColor = colorMap[lowerPart]
        }
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

const MenuItemComponent = ({ item, isSelected, serverLuaColor, primaryColor }: MenuItemProps) => {
  const isDisabled = item.enabled === false
  
  // Collapsible header (parent) — looks like a section header at all times.
  // Quand l'item est sélectionné (curseur clavier), on ajoute uniquement la
  // pastille latérale + une légère surbrillance blanche, exactement comme
  // les items normaux. Plus de bg coloré, plus de chevron tinté, plus de
  // lignes accent — l'header reste visuellement un séparateur de section.
  if (item.type === 'collapsible' && (item as any)._isHeader) {
    const isExpanded = !item.collapsed
    const accentColor = primaryColor || '#c0c0c0'

    return (
      <div
        className="relative px-3 py-2.5 flex items-center gap-2 pointer-events-none"
        style={{
          backgroundColor: isSelected ? 'var(--bg-tertiary)' : 'transparent',
          transition: 'background-color 0.2s cubic-bezier(0.22, 1, 0.36, 1)',
        }}
      >
        {/* Pastille d'accent (gauche) — indicateur de sélection unique */}
        {isSelected && (
          <span
            aria-hidden
            style={{
              position: 'absolute',
              left: 0,
              top: '50%',
              transform: 'translateY(-50%)',
              width: '2px',
              height: '60%',
              backgroundColor: accentColor,
              borderRadius: '0 2px 2px 0',
              boxShadow: `0 0 6px ${accentColor}`,
              opacity: 0.95,
              pointerEvents: 'none',
              transition: 'height 0.25s cubic-bezier(0.22, 1, 0.36, 1), opacity 0.2s ease',
            }}
          />
        )}

        {/* Chevron — toujours neutre, pas de tinte d'accent */}
        <div className="flex items-center justify-center w-5 h-5 rounded flex-shrink-0 text-theme-tertiary">
          {isExpanded ? (
            <ChevronDown size={14} strokeWidth={2.5} />
          ) : (
            <ChevronRight size={14} strokeWidth={2.5} />
          )}
        </div>

        {/* Ligne gauche */}
        <div className="flex-1 h-px bg-theme" />

        {/* Label — toujours blanc, légèrement plus marqué quand sélectionné */}
        <span
          className={`text-xs font-semibold uppercase tracking-wider ${isSelected ? 'text-theme-primary' : 'text-theme-secondary'}`}
        >
          {parseGTAColors(item.label, true, serverLuaColor, primaryColor)}
        </span>

        {/* Ligne droite */}
        <div className="flex-1 h-px bg-theme" />
      </div>
    )
  }
  
  // Separator
  if (item.type === 'separator') {
    return (
      <div className="px-3 py-2 flex items-center gap-2">
        <div className="flex-1 h-px bg-theme" />
        {item.label && (
          <>
            <span className="text-theme-secondary text-xs font-medium uppercase tracking-wider">
              {parseGTAColors(item.label, true, serverLuaColor, primaryColor)}
            </span>
            <div className="flex-1 h-px bg-theme" />
          </>
        )}
      </div>
    )
  }

  // Info Panel et Panels Interactifs - gérés dans Menu.tsx comme panneau séparé, invisibles dans le menu
  if (item.type === 'info' || item.type === 'infopanel' || item.type === 'colorpanel' || item.type === 'gridpanel' || item.type === 'imagepanel' || item.type === 'imageselector') {
    return <div style={{ display: 'none' }} />
  }

  // Check if item is inside a collapsible
  const isInsideCollapsible = (item as any)._isCollapsibleChild
  
  // const baseClasses = `
  //   relative flex items-center justify-between
  //   transition-all duration-150 pointer-events-none
  //   ${isDisabled ? 'opacity-50' : ''}
  //   ${isInsideCollapsible ? 'px-3 py-2.5 pl-6' : 'px-3 py-2.5'}
  // `

  const baseClasses = `
      relative flex items-center justify-between
      transition-all duration-150 pointer-events-none
      ${isDisabled ? 'opacity-50' : ''}
      ${isInsideCollapsible ? 'px-3 py-2.5 pl-6' : 'px-3 py-2.5'}
    `

  const accent = primaryColor || '#c0c0c0'

  return (
    <div 
      className={`isolate ${baseClasses}`}
      style={{
        ['--item-primary' as any]: accent,
        // Surbrillance neutre quand l'item est sélectionné (même esprit que
        // le context-menu : surbrillance blanche subtile, pas de couleur).
        backgroundColor: isSelected ? 'var(--bg-tertiary)' : 'transparent',
        transition: 'background-color 0.2s cubic-bezier(0.22, 1, 0.36, 1)',
      }}
    >
      {/* Pastille d'accent (barre fine 2px, ~60% de la hauteur, centrée verticalement)
       * Affichée UNIQUEMENT lorsque l'item est sélectionné — les items dans un
       * collapsible (non sélectionnés) ne montrent aucun indicateur, ils ont
       * exactement le même rendu que les items racines non sélectionnés. */}
      {isSelected && (
        <span
          aria-hidden
          style={{
            position: 'absolute',
            left: '-1px',
            top: '50%',
            transform: 'translateY(-50%)',
            width: '3px',
            height: '60%',
            backgroundColor: accent,
            borderRadius: '2px',
            boxShadow: `0 0 6px ${accent}`,
            opacity: 0.95,
            pointerEvents: 'none',
            transition: 'height 0.25s cubic-bezier(0.22, 1, 0.36, 1), opacity 0.2s ease',
          }}
        />
      )}
      {/* Left side */}
      <div className="flex items-center gap-2 flex-1 min-w-0">
        <span className={`text-sm truncate ${isSelected ? 'text-theme-primary font-medium' : 'text-theme-secondary'}`}>
          {parseGTAColors(item.label, true, serverLuaColor, primaryColor)}
        </span>
      </div>

      {/* Right side */}
      <div className="flex items-center gap-2 ml-2">
        {/* Button with right label (skip if it's just an arrow) */}
        {item.type === 'button' && item.rightLabel && item.rightLabel !== '→' && (
          <span className={`text-sm ${isSelected ? 'text-primary' : 'text-theme-tertiary'}`}>
            {isSelected ? parseGTAColors(item.rightLabel, false, serverLuaColor, primaryColor) : parseGTAColors(item.rightLabel, true, serverLuaColor, primaryColor)}
          </span>
        )}

        {/* Arrow for buttons */} 
        {item.type === 'button' && (
          <div 
            className={`
              flex items-center justify-center w-5 h-5 rounded -mr-1 border
              transition-all duration-200
              ${isSelected ? '' : 'text-theme-tertiary border-theme'}
            `}
            style={isSelected ? {
              backgroundColor: primaryColor || '#c0c0c0',
              borderColor: `${primaryColor || '#c0c0c0'}80`
            } : undefined}
          >
            <ChevronRight size={14} strokeWidth={2} />
          </div>
        )}

        {/* List */}
        {item.type === 'list' && item.items && (
          <div className="flex items-center gap-1">
            <ChevronLeft 
              size={14} 
              className={`${isSelected ? 'text-primary' : 'text-theme-tertiary'}`}
            />
            <span className={`text-sm min-w-[60px] text-center ${isSelected ? 'text-theme-primary' : 'text-theme-secondary'}`}>
              {parseGTAColors(item.items[(item.value as number) - 1] || item.items[0], true, serverLuaColor, primaryColor)}
            </span>
            <ChevronRight 
              size={14} 
              className={`${isSelected ? 'text-primary' : 'text-theme-tertiary'}`}
            />
          </div>
        )}

        {/* Checkbox */}
        {item.type === 'checkbox' && (
          <div 
            className="w-5 h-5 rounded border-2 flex items-center justify-center transition-all duration-150"
            style={{
              backgroundColor: item.checked ? primaryColor : 'transparent',
              borderColor: item.checked 
                ? primaryColor 
                : isSelected 
                  ? `${primaryColor}99` 
                  : 'var(--text-tertiary)'
            }}
          >
            {item.checked && <Check size={12} className="text-white" strokeWidth={3} />}
          </div>
        )}

        {/* Slider */}
        {item.type === 'slider' && (
          <div className="flex items-center gap-2">
            <div className="w-24 h-1.5 bg-theme-tertiary rounded-full overflow-hidden">
              <div 
                className="h-full rounded-full transition-all duration-150"
                style={{ 
                  width: `${((item.value as number) - (item.min || 0)) / ((item.max || 100) - (item.min || 0)) * 100}%`,
                  backgroundColor: primaryColor
                }}
              />
            </div>
            <span className={`text-xs min-w-[30px] text-right ${isSelected ? 'text-theme-primary' : 'text-theme-secondary'}`}>
              {item.value}
            </span>
          </div>
        )}

        {/* Percentage Panel */}
        {item.type === 'percentagepanel' && (
          <div className="flex items-center gap-2">
            <ChevronLeft
              size={14}
              className={`${isSelected ? 'text-primary' : 'text-theme-tertiary'}`}
              style={isSelected ? { color: primaryColor } : undefined}
            />
            {item.minText && (
              <span className={`text-[10px] uppercase tracking-wider ${isSelected ? 'text-theme-secondary' : 'text-theme-tertiary'}`}>
                {item.minText}
              </span>
            )}
            <div className="w-24 h-1.5 bg-theme-tertiary rounded-full overflow-hidden">
              <div
                className="h-full rounded-full transition-all duration-150"
                style={{
                  width: `${Math.max(0, Math.min(100, (item.value as number) || 0))}%`,
                  backgroundColor: primaryColor
                }}
              />
            </div>
            {item.maxText && (
              <span className={`text-[10px] uppercase tracking-wider ${isSelected ? 'text-theme-secondary' : 'text-theme-tertiary'}`}>
                {item.maxText}
              </span>
            )}
            <span className={`text-xs min-w-[38px] text-right font-medium ${isSelected ? 'text-theme-primary' : 'text-theme-secondary'}`}>
              {Math.round((item.value as number) || 0)}%
            </span>
            <ChevronRight
              size={14}
              className={`${isSelected ? 'text-primary' : 'text-theme-tertiary'}`}
              style={isSelected ? { color: primaryColor } : undefined}
            />
          </div>
        )}
      </div>

      {/* Selection indicator glow */}
      {isSelected && (
        <div 
          className="absolute inset-0 pointer-events-none"
          style={{
            background: `linear-gradient(90deg, transparent 0%, ${primaryColor || '#c0c0c0'}0D 50%, transparent 100%)`
          }}
        />
      )} 
    </div>
  )
}

export default MenuItemComponent
