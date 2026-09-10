import React, { useState, useEffect, useRef, useCallback, useMemo } from 'react'
import { cacheImg } from '@shared/cacheVersion'

export interface GridItem {
  name: string
  label: string
  category?: string
}

interface ItemGridPanelProps {
  visible: boolean
  items: GridItem[]
  title: string
  mode: 'item' | 'weapon' | 'vehicle'
  primaryColor: string
}

const BATCH_SIZE = 80

const getImageUrl = (name: string, mode: string): string => {
  if (mode === 'vehicle') {
    return cacheImg(`vehicles/${name}.webp`)
  }
  return cacheImg(`items/${name}.webp`)
}

const getFallbackUrl = (): string => cacheImg('items/box.png')

const GetParentResourceName = () => (window as any).GetParentResourceName?.() || 'null-core'

const ItemCell = React.memo(({ item, mode, primaryColor, onClick }: {
  item: GridItem
  mode: string
  primaryColor: string
  onClick: () => void
}) => {
  const [loaded, setLoaded] = useState(false)
  const [error, setError] = useState(false)
  const cellRef = useRef<HTMLDivElement>(null)
  const [inView, setInView] = useState(false)

  useEffect(() => {
    const el = cellRef.current
    if (!el) return
    const obs = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting) {
          setInView(true)
          obs.disconnect()
        }
      },
      { rootMargin: '200px' }
    )
    obs.observe(el)
    return () => obs.disconnect()
  }, [])

  return (
    <div className="igp-cell" ref={cellRef} onClick={onClick}>
      <div className="igp-cell-img">
        {inView && !error ? (
          <img
            src={getImageUrl(item.name, mode)}
            alt={item.label}
            loading="lazy"
            decoding="async"
            onLoad={() => setLoaded(true)}
            onError={() => setError(true)}
            className={loaded ? 'igp-img-loaded' : 'igp-img-loading'}
          />
        ) : null}
        {error && (
          <img
            src={getFallbackUrl()}
            alt={item.label}
            className="igp-img-loaded"
          />
        )}
        {!inView && !error && (
          <div className="igp-img-placeholder">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" className="igp-placeholder-icon">
              <path d="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4"/>
            </svg>
          </div>
        )}
      </div>
      <div className="igp-cell-label" title={item.label}>{item.label}</div>
      <div className="igp-cell-name" title={item.name}>{item.name}</div>
    </div>
  )
})

export default function ItemGridPanelComponent({ visible, items, title, mode, primaryColor }: ItemGridPanelProps) {
  const [search, setSearch] = useState('')
  const [visibleCount, setVisibleCount] = useState(BATCH_SIZE)
  const scrollRef = useRef<HTMLDivElement>(null)
  const searchRef = useRef<HTMLInputElement>(null)

  useEffect(() => {
    if (visible) {
      setSearch('')
      setVisibleCount(BATCH_SIZE)
      setTimeout(() => searchRef.current?.focus(), 50)
    }
  }, [visible])

  const filtered = useMemo(() => {
    if (!search) return items
    const lower = search.toLowerCase()
    return items.filter(item =>
      item.label.toLowerCase().includes(lower) ||
      item.name.toLowerCase().includes(lower)
    )
  }, [items, search])

  const displayed = useMemo(() => filtered.slice(0, visibleCount), [filtered, visibleCount])

  const handleScroll = useCallback(() => {
    const el = scrollRef.current
    if (!el) return
    if (el.scrollTop + el.clientHeight >= el.scrollHeight - 200) {
      setVisibleCount(prev => Math.min(prev + BATCH_SIZE, filtered.length))
    }
  }, [filtered.length])

  const handleSelect = useCallback((item: GridItem) => {
    fetch(`https://${GetParentResourceName()}/itemGridSelected`, {
      method: 'POST',
      body: JSON.stringify({ name: item.name, label: item.label, mode })
    })
  }, [mode])

  const handleClose = useCallback(() => {
    fetch(`https://${GetParentResourceName()}/itemGridClosed`, {
      method: 'POST',
      body: JSON.stringify({})
    })
  }, [])

  useEffect(() => {
    if (!visible) return
    const handler = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        e.preventDefault()
        e.stopPropagation()
        handleClose()
      }
    }
    window.addEventListener('keydown', handler, true)
    return () => window.removeEventListener('keydown', handler, true)
  }, [visible, handleClose])

  if (!visible) return null

  const modeLabels: Record<string, string> = {
    item: 'Items',
    weapon: 'Armes',
    vehicle: 'Véhicules',
  }

  return (
    <div className="igp-overlay" onClick={handleClose}>
      <div
        className="igp-panel"
        onClick={e => e.stopPropagation()}
        style={{ '--igp-accent': primaryColor } as React.CSSProperties}
      >
        {/* Header */}
        <div className="igp-header">
          <div className="igp-header-left">
            <div className="igp-title">{title}</div>
            <div className="igp-subtitle">{modeLabels[mode] || mode}</div>
          </div>
          <div className="igp-header-right">
            <div className="igp-count">{filtered.length} résultat{filtered.length !== 1 ? 's' : ''}</div>
            <button className="igp-close" onClick={handleClose}>
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round">
                <path d="M18 6L6 18M6 6l12 12"/>
              </svg>
            </button>
          </div>
        </div>

        {/* Search */}
        <div className="igp-search-wrap">
          <svg className="igp-search-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
            <circle cx="11" cy="11" r="8"/>
            <path d="M21 21l-4.35-4.35" strokeLinecap="round"/>
          </svg>
          <input
            ref={searchRef}
            className="igp-search"
            type="text"
            placeholder="Rechercher par nom..."
            value={search}
            onChange={e => {
              setSearch(e.target.value)
              setVisibleCount(BATCH_SIZE)
              if (scrollRef.current) scrollRef.current.scrollTop = 0
            }}
            onKeyDown={e => {
              if (e.key === 'Escape') {
                if (search) {
                  e.stopPropagation()
                  setSearch('')
                } else {
                  handleClose()
                }
              }
            }}
          />
          {search && (
            <button className="igp-search-clear" onClick={() => { setSearch(''); searchRef.current?.focus() }}>
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round">
                <path d="M18 6L6 18M6 6l12 12"/>
              </svg>
            </button>
          )}
        </div>

        {/* Grid */}
        <div className="igp-grid-wrap" ref={scrollRef} onScroll={handleScroll}>
          {displayed.length > 0 ? (
            <div className="igp-grid">
              {displayed.map((item) => (
                <ItemCell
                  key={item.name}
                  item={item}
                  mode={mode}
                  primaryColor={primaryColor}
                  onClick={() => handleSelect(item)}
                />
              ))}
            </div>
          ) : (
            <div className="igp-empty">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" className="igp-empty-icon">
                <circle cx="11" cy="11" r="8"/>
                <path d="M21 21l-4.35-4.35" strokeLinecap="round"/>
                <path d="M8 11h6" strokeLinecap="round"/>
              </svg>
              <span>Aucun résultat pour "{search}"</span>
            </div>
          )}
        </div>

        {/* Footer */}
        <div className="igp-footer">
          <span className="igp-footer-hint">Cliquez sur un élément pour le sélectionner</span>
          <span className="igp-footer-hint">ESC pour fermer</span>
        </div>
      </div>
    </div>
  )
}
