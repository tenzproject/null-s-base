import React, { useState, useEffect, useRef } from 'react'
import './index.css'
import MenuHeader from './MenuHeader'
import MenuItem from './MenuItem'
import ColorPanelComponent from './ColorPanelComponent'
import GridPanelComponent from './GridPanelComponent'
import ImagePanelComponent from './ImagePanelComponent'
import ImageSelectorComponent from './ImageSelectorComponent'
import { MenuProps } from './types'
import { hudPositionManager } from '../../utils/hudPositionManager'
import { applyAnchorPosition } from '../../utils/anchorPositioning'

// Parse GTA color codes like ~g~, ~b~, ~r~, etc.
const parseGTAColors = (text: string | null | undefined, serverLuaColor?: string, primaryColor?: string): JSX.Element[] => {
  // Handle null, undefined, or non-string values
  if (!text || typeof text !== 'string') {
    return [<span key="0">{String(text || '')}</span>]
  }

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

// Parse description with colors and newlines
const parseDescription = (text: string | null | undefined, serverLuaColor?: string, primaryColor?: string): JSX.Element[] => {
  if (!text || typeof text !== 'string') {
    return [<span key="0">{String(text || '')}</span>]
  }
  const lines = text.split('\\n')
  return lines.map((line, lineIndex) => (
    <span key={lineIndex}>
      {parseGTAColors(line, serverLuaColor, primaryColor)}
      {lineIndex < lines.length - 1 && <br />}
    </span>
  ))
}

export default function Menu({
  title,
  subtitle,
  items,
  selectedIndex,
  position,
  previewImage,
  maxVisibleItems = 10,
  primaryColor = '#c0c0c0',
  serverLuaColor = '~b~',
  previewMode = false,
  previewPosition = null,
  hudEditorOpen = false,
  isHiding = false,
  transition = null
}: MenuProps & { previewMode?: boolean; previewPosition?: { x: number; y: number } | null; hudEditorOpen?: boolean; isHiding?: boolean; transition?: 'forward' | 'back' | null }) {
  
  // Compteur pour forcer le re-mount du wrapper animé lors des transitions
  const [transitionKey, setTransitionKey] = useState(0)
  useEffect(() => {
    if (transition) {
      setTransitionKey(prev => prev + 1)
    }
  }, [title, subtitle, transition])
  
  const displayTitle = previewMode ? 'Menu' : title;
  const displaySubtitle = previewMode ? 'Exemple de menu' : subtitle;
  const displayItems = previewMode ? [
    { type: 'button' as const, label: 'Action rapide', description: 'Effectuer une action' },
    { type: 'button' as const, label: 'Inventaire', description: 'Ouvrir l\'inventaire' },
    { type: 'list' as const, label: 'Véhicule', items: ['Sortir', 'Ranger', 'Réparer'], value: 0 },
    { type: 'checkbox' as const, label: 'Notifications', checked: true },
    { type: 'separator' as const, label: 'Section suivante' },
    { type: 'button' as const, label: 'Téléphone', description: 'Ouvrir le téléphone' },
    { type: 'slider' as const, label: 'Volume', value: 75, min: 0, max: 100 },
    { type: 'button' as const, label: 'GPS', description: 'Définir un point' },
    { type: 'list' as const, label: 'Animation', items: ['Saluer', 'Danser', 'S\'asseoir'], value: 1 },
    { type: 'separator' as const, label: 'Section suivante' },
    { type: 'button' as const, label: 'Paramètres', description: 'Configuration' },
    { type: 'checkbox' as const, label: 'Mode discret', checked: false },
    { type: 'button' as const, label: 'Déconnexion', description: 'Quitter le serveur' }
  ] : items;

  const containerRef = useRef<HTMLDivElement>(null)
  const itemsRef = useRef<HTMLDivElement>(null)
  
  // Apply primary color as CSS variable
  useEffect(() => {
    if (containerRef.current) {
      containerRef.current.style.setProperty('--primary', primaryColor);
      containerRef.current.style.setProperty('--primary-light', primaryColor);
    } else {
      console.warn('[Menu] containerRef.current is null, cannot set CSS variables');
    }
  }, [primaryColor]);
  
  // Load saved position from HUD editor
  const [actualPosition, setActualPosition] = useState<any>(position)
  
  useEffect(() => {
    if (previewMode) return
    
    // Wait for HUD Position Manager to be ready
    hudPositionManager.onReady(() => {
      const savedPos = hudPositionManager.getPosition('menu')
      if (savedPos) {
        setActualPosition(savedPos)
      }
    })
  }, [previewMode, position])

  // Calculer le nombre d'items à afficher (incluant separators) pour avoir maxVisibleItems sélectionnables
  const selectableItems = displayItems.filter(item => item.type !== 'separator' && item.type !== 'info' && item.type !== 'infopanel')
  const displayItemsList = displayItems.filter(item => item.type !== 'info' && item.type !== 'infopanel')
  
  // Calculer l'index réel parmi les items sélectionnables uniquement
  const selectableIndex = displayItems.slice(0, selectedIndex + 1).filter(item => 
    item.type !== 'separator' && item.type !== 'info' && item.type !== 'infopanel'
  ).length
  
  // Calculer la hauteur max basée sur le nombre d'items sélectionnables
  // Si on a <= maxVisibleItems sélectionnables, pas de limite de hauteur (afficher tout)
  // Sinon, calculer combien d'items totaux correspondent à maxVisibleItems sélectionnables
  let maxHeightPx: number | undefined
  if (selectableItems.length > maxVisibleItems) {
    // Compter les items jusqu'à avoir maxVisibleItems sélectionnables
    let selectableCount = 0
    let visibleItemsCount = 0
    for (const item of displayItemsList) {
      visibleItemsCount++
      if (item.type !== 'separator') {
        selectableCount++
        if (selectableCount >= maxVisibleItems) break
      }
    }
    maxHeightPx = visibleItemsCount * 38
  }

  // Extraire les items Info et InfoPanel pour le panneau séparé
  const infoItems = displayItems.filter(item => item.type === 'info')
  const infoPanelItems = displayItems.filter(item => item.type === 'infopanel')
  
  // Extraire les panels interactifs pour le panneau séparé
  const colorPanelItems = displayItems.filter(item => item.type === 'colorpanel')
  const gridPanelItems = displayItems.filter(item => item.type === 'gridpanel')
  const imagePanelItems = displayItems.filter(item => item.type === 'imagepanel')
  const imageSelectorItems = displayItems.filter(item => item.type === 'imageselector')

  useEffect(() => {
    if (itemsRef.current) {
      const selectedElement = itemsRef.current.children[selectedIndex] as HTMLElement
      if (selectedElement) {
        const container = itemsRef.current
        const containerRect = container.getBoundingClientRect()
        const elementRect = selectedElement.getBoundingClientRect()
        
        // Calculer la position de scroll nécessaire
        const elementTop = elementRect.top - containerRect.top + container.scrollTop
        const elementBottom = elementTop + elementRect.height
        const containerScrollTop = container.scrollTop
        const containerHeight = container.clientHeight
        
        // Calculer la position de scroll optimale
        let targetScrollTop = containerScrollTop
        
        if (elementTop < containerScrollTop) {
          // Élément au-dessus de la zone visible
          targetScrollTop = elementTop
        } else if (elementBottom > containerScrollTop + containerHeight) {
          // Élément en-dessous de la zone visible
          targetScrollTop = elementBottom - containerHeight
        }
        
        // Scroll smooth avec scrollTo au lieu de scrollIntoView
        container.scrollTo({
          top: targetScrollTop,
          behavior: 'smooth'
        })
      }
    } 
  }, [selectedIndex])

  return (
    <div
      className="rageui-menu-container flex gap-2"
      style={{
        display: (hudEditorOpen && !previewMode) ? 'none' : undefined,
        overflow: "visible",
        ...(previewMode ? {
          position: 'relative',
          left: 0,
          top: 0
        } : actualPosition?.anchor ? applyAnchorPosition({
          anchor: actualPosition.anchor,
          position: { x: actualPosition.x, y: actualPosition.y }
        }) : {})
      }}
    >
      {/* Menu Principal */}
      <div 
        key={transitionKey}
        ref={containerRef}
        style={{ 
          width: '400px',
        }}
        className={isHiding ? 'animate-fade-out' : transition ? `menu-transition-${transition}` : 'animate-fade-in'}
      >
        {/* Header */}
        <MenuHeader 
          title={displayTitle} 
          subtitle={displaySubtitle} 
          pageInfo={`${selectableIndex} / ${selectableItems.length}`}
        />

        {/* Items Container */}
        <div 
          ref={itemsRef}
          className="bg-theme-primary overflow-y-auto pointer-events-none select-none"
          style={{ 
            // overflow: "visible",
            borderRadius: '0 0 8px 8px',
            boxShadow: '0 8px 32px rgba(0, 0, 0, 0.4)',
            ...(maxHeightPx && { maxHeight: `${maxHeightPx}px` }),
          }}
          onClick={(e) => e.stopPropagation()}
          onMouseDown={(e) => e.preventDefault()}
          onMouseMove={(e) => e.stopPropagation()}
          onMouseEnter={(e) => e.stopPropagation()}
          onMouseLeave={(e) => e.stopPropagation()}
          onWheel={(e) => e.preventDefault()}
          onScroll={(e) => e.preventDefault()}
        >
          {displayItems.map((item, index) => (
            <MenuItem
              key={index}
              item={item}
              isSelected={index === selectedIndex}
              serverLuaColor={serverLuaColor}
              primaryColor={primaryColor}
            />
          ))}
        </div>

        {/* Description */}
        {items[selectedIndex]?.description && (
          <div 
            className="bg-theme-primary px-3 py-2 mt-1 text-xs text-theme-secondary"
            style={{ 
              borderRadius: '8px',
            }}
          >
            {parseDescription(items[selectedIndex].description, serverLuaColor, primaryColor)}
          </div>
        )}

        {/* Preview Image */}
        {previewImage && (
          <div 
            className="mt-2 overflow-hidden"
            style={{ 
              borderRadius: '8px',
            }}
          >
            <img 
              src={previewImage} 
              alt="Preview" 
              className="w-full h-auto object-cover"
              style={{ maxHeight: '200px' }}
            />
          </div>
        )}
      </div>

      {/* Panneau Info et Panels Interactifs à droite */}
      {(infoItems.length > 0 || infoPanelItems.length > 0 || colorPanelItems.length > 0 || gridPanelItems.length > 0 || imagePanelItems.length > 0 || imageSelectorItems.length > 0) && (
        <div className={isHiding ? 'animate-fade-out' : 'animate-fade-in'} style={{ width: '300px' }}>
          {/* ColorPanel items */}
          {colorPanelItems.map((item, index) => (
            <ColorPanelComponent key={`colorpanel-${index}`} item={item} index={index} primaryColor={primaryColor} serverLuaColor={serverLuaColor} />
          ))}
          
          {/* GridPanel items */}
          {gridPanelItems.map((item, index) => (
            <GridPanelComponent key={`gridpanel-${index}`} item={item} index={index} primaryColor={primaryColor} serverLuaColor={serverLuaColor} />
          ))}
          
          {/* ImagePanel items */}
          {imagePanelItems.map((item, index) => (
            <ImagePanelComponent key={`imagepanel-${index}`} item={item} index={index} primaryColor={primaryColor} serverLuaColor={serverLuaColor} />
          ))}
          
          {/* ImageSelector items */}
          {imageSelectorItems.map((item, index) => (
            <ImageSelectorComponent key={`imageselector-${index}`} item={item} index={index} primaryColor={primaryColor} serverLuaColor={serverLuaColor} />
          ))}

          
          {/* InfoPanel items */}
          {infoPanelItems.map((item, index) => (
            <div key={`infopanel-${index}`} className="bg-theme-primary px-4 py-3 mb-2" style={{ borderRadius: '8px' }}>
              {/* Title */}
              {item.label && (
                <div className="text-theme-primary text-sm font-semibold mb-3 uppercase tracking-wide border-b border-theme pb-2">
                  {parseGTAColors(item.label, serverLuaColor, primaryColor)}
                </div>
              )}
              
              {/* Panel Items */}
              {item.panelItems && (
                <div className="space-y-2">
                  {item.panelItems.map((panelItem, idx) => {
                    const hasKey = panelItem.key && panelItem.key.trim() !== ''
                    const hasValue = panelItem.value !== undefined && panelItem.value !== null && String(panelItem.value).trim() !== ''
                    
                    return (
                      <div key={`panel-item-${idx}`} className="flex justify-between items-center gap-2">
                        {/* Label */}
                        <div className="text-xs text-theme-secondary flex items-center gap-1.5 flex-1">
                          {/* <div className="w-1 h-1 rounded-full bg-white/10" /> */}
                          <span>{parseGTAColors(panelItem.label, serverLuaColor, primaryColor)}</span>
                        </div>
                        
                        {/* Key Badge */}
                        {hasKey && (
                          <div className="px-2 py-0.5 bg-theme-tertiary border border-theme-strong rounded text-[10px] font-bold text-theme-primary uppercase tracking-wider">
                            {panelItem.key}
                          </div>
                        )}
                        
                        {/* Value */}
                        {hasValue && (
                          <div className="text-xs font-medium text-theme-primary flex items-center gap-1">
                            {String(panelItem.value) === 'true' ? (
                              <svg className="w-3.5 h-3.5 text-green-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={3} d="M5 13l4 4L19 7" />
                              </svg>
                            ) : String(panelItem.value) === 'false' ? (
                              <svg className="w-3.5 h-3.5 text-red-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={3} d="M6 18L18 6M6 6l12 12" />
                              </svg>
                            ) : typeof panelItem.value === 'string' && String(panelItem.value).includes('%') ? (
                              <div className="flex items-center gap-2 min-w-[100px]">
                                <div className="flex-1 h-1.5 bg-white/20 rounded-full overflow-hidden">
                                  <div 
                                    className="h-full bg-primary rounded-full"
                                    style={{ width: String(panelItem.value) }}
                                  />
                                </div>
                                <span className="text-[10px] text-theme-secondary min-w-[28px]">{String(panelItem.value)}</span>
                              </div>
                            ) : typeof panelItem.value === 'string' && String(panelItem.value).includes('/') ? (
                              <div className="flex items-center gap-2 min-w-[100px]">
                                <div className="flex-1 h-1.5 bg-white/20 rounded-full overflow-hidden">
                                  <div 
                                    className="h-full bg-primary rounded-full"
                                    style={{ 
                                      width: `${(parseInt(String(panelItem.value).split('/')[0]) / parseInt(String(panelItem.value).split('/')[1])) * 100}%` 
                                    }}
                                  />
                                </div>
                                <span className="text-[10px] text-theme-secondary min-w-[28px]">{String(panelItem.value)}</span>
                              </div>
                            ) : (
                              parseGTAColors(String(panelItem.value), serverLuaColor, primaryColor)
                            )}
                          </div>
                        )}
                      </div>
                    )
                  })}
                </div>
              )}
            </div>
          ))}
          
          {/* Info items */}
          {infoItems.map((item, index) => (
            <div key={`info-${index}`} className="bg-theme-primary px-4 py-3 mb-2" style={{ borderRadius: '8px' }}>
              {/* Title */}
              {item.label && (
                <div className="text-theme-primary text-sm font-semibold mb-3 uppercase tracking-wide border-b border-theme pb-2">
                  {parseGTAColors(item.label, serverLuaColor, primaryColor)}
                </div>
              )}
              
              {/* Content Grid */}
              <div className="space-y-2">
                {/* Left and Right Items */}
                {item.leftItems && item.rightItems && (
                  <div className="space-y-1.5">
                    {item.leftItems.map((leftItem, idx) => {
                      const rightValue = item.rightItems?.[idx]
                      return (
                        <div key={`info-row-${idx}`} className="flex justify-between items-center gap-2">
                          <div className="text-xs text-theme-secondary flex items-center gap-1.5">
                            {/* <div className="w-1 h-1 rounded-full bg-primary/60" /> */}
                            <span>{parseGTAColors(leftItem, serverLuaColor, primaryColor)}</span>
                          </div>
                          <div className="text-xs font-medium text-theme-primary flex items-center gap-1">
                            {/* Boolean avec checkmark vert */}
                            {String(rightValue) === 'true' ? (
                              <div className="flex items-center gap-1">
                                <svg className="w-3.5 h-3.5 text-green-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={3} d="M5 13l4 4L19 7" />
                                </svg>
                              </div>
                            ) : String(rightValue) === 'false' ? (
                              <div className="flex items-center gap-1">
                                <svg className="w-3.5 h-3.5 text-red-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={3} d="M6 18L18 6M6 6l12 12" />
                                </svg>
                              </div>
                            ) : typeof rightValue === 'string' && rightValue.includes('%') ? (
                              /* Progressbar avec pourcentage */
                              <div className="flex items-center gap-2 min-w-[100px]">
                                <div className="flex-1 h-1.5 bg-white/20 rounded-full overflow-hidden">
                                  <div 
                                    className="h-full bg-primary rounded-full"
                                    style={{ width: rightValue }}
                                  />
                                </div>
                                <span className="text-[10px] text-theme-secondary min-w-[28px]">{rightValue}</span>
                              </div>
                            ) : typeof rightValue === 'string' && rightValue.includes('/') ? (
                              /* Progressbar avec valeurs min/max */
                              <div className="flex items-center gap-2 min-w-[100px]">
                                <div className="flex-1 h-1.5 bg-white/20 rounded-full overflow-hidden">
                                  <div 
                                    className="h-full bg-primary rounded-full"
                                    style={{ 
                                      width: `${(parseInt(rightValue.split('/')[0]) / parseInt(rightValue.split('/')[1])) * 100}%` 
                                    }}
                                  />
                                </div>
                                <span className="text-[10px] text-theme-secondary min-w-[28px]">{rightValue}</span>
                              </div>
                            ) : Array.isArray(rightValue) ? (
                              /* Liste d'items */
                              <div className="flex flex-col gap-0.5">
                                {rightValue.map((listItem, listIdx) => (
                                  <div key={listIdx} className="text-[10px] text-theme-secondary flex items-center gap-1.5">
                                    {parseGTAColors(String(listItem), serverLuaColor, primaryColor)}
                                  </div>
                                ))}
                              </div>
                            ) : (
                              /* Texte normal */
                              parseGTAColors(String(rightValue || ''), serverLuaColor, primaryColor)
                            )}
                          </div>
                        </div>
                      )
                    })}
                  </div>
                )}
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}
