import { useState, useCallback } from 'react'
import { CrimeNetData, MarketListing, MarketCategory } from '../types'
import { postNUI } from '../nui'

interface Props {
  cnData: CrimeNetData | null
  onRefreshData: () => void
}

const CATEGORIES: { id: MarketCategory | 'all'; label: string; icon: JSX.Element }[] = [
  {
    id: 'all', label: 'TOUT',
    icon: <svg viewBox="0 0 24 24" width="14" height="14" fill="none" stroke="currentColor" strokeWidth="2"><rect x="3" y="3" width="7" height="7" /><rect x="14" y="3" width="7" height="7" /><rect x="3" y="14" width="7" height="7" /><rect x="14" y="14" width="7" height="7" /></svg>,
  },
  {
    id: 'vehicles', label: 'VÉHICULES',
    icon: <svg viewBox="0 0 24 24" width="14" height="14" fill="none" stroke="currentColor" strokeWidth="2"><path d="M5 17h14M7 9l2-4h6l2 4M4 17V9h16v8M7 13h.01M17 13h.01" /></svg>,
  },
  {
    id: 'weapons', label: 'ARMES',
    icon: <svg viewBox="0 0 24 24" width="14" height="14" fill="none" stroke="currentColor" strokeWidth="2"><path d="M14 2l8 8-2 2-4-1-3 3 1 4-2 2-8-8 2-2 4 1 3-3-1-4z" /><path d="M3 21l3-3" /></svg>,
  },
  {
    id: 'items', label: 'ITEMS',
    icon: <svg viewBox="0 0 24 24" width="14" height="14" fill="none" stroke="currentColor" strokeWidth="2"><rect x="2" y="7" width="20" height="14" rx="2" /><path d="M16 7V5a2 2 0 0 0-2-2h-4a2 2 0 0 0-2 2v2" /></svg>,
  },
  {
    id: 'drugs', label: 'DROGUES',
    icon: <svg viewBox="0 0 24 24" width="14" height="14" fill="none" stroke="currentColor" strokeWidth="2"><path d="M8 2v4M16 2v4M3 10h18M5 4h14a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2z" /></svg>,
  },
]

const CATEGORY_LABELS: Record<MarketCategory, string> = {
  vehicles: 'VÉHICULE',
  weapons: 'ARME',
  items: 'ITEM',
  drugs: 'DROGUE',
}

const CATEGORY_COLORS: Record<MarketCategory, string> = {
  vehicles: '#6b7280',
  weapons: '#9ca3af',
  items: '#6b7280',
  drugs: '#9ca3af',
}

function photoUrl(p: unknown): string | null {
  if (typeof p === 'string' && p.length > 0) return p
  if (p && typeof p === 'object' && 'url' in (p as any)) {
    const u = (p as any).url
    return typeof u === 'string' ? u : null
  }
  return null
}

type ViewMode = 'browse' | 'create' | 'detail' | 'my_listings'

export default function MarketTab({ cnData, onRefreshData }: Props) {
  const [view, setView] = useState<ViewMode>('browse')
  const [activeCategory, setActiveCategory] = useState<MarketCategory | 'all'>('all')
  const [selectedListing, setSelectedListing] = useState<MarketListing | null>(null)
  const [notification, setNotification] = useState<{ type: 'success' | 'error'; text: string } | null>(null)

  // Create form state
  const [formCategory, setFormCategory] = useState<MarketCategory>('items')
  const [formTitle, setFormTitle] = useState('')
  const [formDesc, setFormDesc] = useState('')
  const [formPrice, setFormPrice] = useState('')
  const [formPhotos, setFormPhotos] = useState<string[]>([])
  const [creating, setCreating] = useState(false)

  const listings = cnData?.marketplace || []
  const myId = cnData?.profile?.identifier || ''

  const filteredListings = activeCategory === 'all'
    ? listings.filter(l => l.status === 'active')
    : listings.filter(l => l.status === 'active' && l.category === activeCategory)

  const myListings = listings.filter(l => l.is_mine)

  const showNotif = useCallback((type: 'success' | 'error', text: string) => {
    setNotification({ type, text })
    setTimeout(() => setNotification(null), 4000)
  }, [])

  const handleCreate = useCallback(async () => {
    if (!formTitle.trim() || !formPrice.trim()) return
    setCreating(true)
    const res = await postNUI('crimenet:market:create', {
      category: formCategory,
      title: formTitle.trim(),
      description: formDesc.trim(),
      price: parseInt(formPrice) || 0,
      photos: formPhotos,
    }) as { success: boolean; error?: string }
    if (res?.success) {
      showNotif('success', 'Annonce publiée')
      setView('browse')
      setFormTitle('')
      setFormDesc('')
      setFormPrice('')
      setFormPhotos([])
      onRefreshData()
    } else {
      showNotif('error', res?.error || 'Erreur lors de la publication')
    }
    setCreating(false)
  }, [formCategory, formTitle, formDesc, formPrice, formPhotos, showNotif, onRefreshData])

  const handleMarkSold = useCallback(async (listingId: number) => {
    const res = await postNUI('crimenet:market:markSold', { listingId }) as { success: boolean }
    if (res?.success) {
      showNotif('success', 'Annonce marquée comme vendue')
      onRefreshData()
      setSelectedListing(null)
    }
  }, [showNotif, onRefreshData])

  const handleDelete = useCallback(async (listingId: number) => {
    const res = await postNUI('crimenet:market:delete', { listingId }) as { success: boolean }
    if (res?.success) {
      showNotif('success', 'Annonce supprimée')
      onRefreshData()
      setSelectedListing(null)
      if (view === 'detail') setView('browse')
    }
  }, [showNotif, onRefreshData, view])

  const handleContact = useCallback(async (sellerId: string, sellerName: string) => {
    await postNUI('crimenet:market:contact', { sellerId, sellerName })
    showNotif('success', 'Conversation ouverte avec ' + sellerName)
  }, [showNotif])

  const handleAddPhoto = useCallback(async () => {
    if (formPhotos.length >= 3) return
    const res = await postNUI('crimenet:pickPhoto', {}) as { success: boolean; url?: string }
    if (res?.success && res.url) {
      setFormPhotos(prev => [...prev, res.url!])
    }
  }, [formPhotos])

  // ---- NOTIFICATION ----
  const NotifBanner = notification ? (
    <div className={`mkt-notif mkt-notif--${notification.type}`}>
      {notification.text}
    </div>
  ) : null

  // ---- CREATE VIEW ----
  if (view === 'create') {
    return (
      <div className="mkt-tab">
        {NotifBanner}
        <div className="mkt-header">
          <button className="mkt-back" onClick={() => setView('browse')}>
            <svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" strokeWidth="2"><polyline points="15 18 9 12 15 6" /></svg>
          </button>
          <span className="mkt-header-title">NOUVELLE ANNONCE</span>
        </div>

        <div className="mkt-form">
          <div className="mkt-form-label">CATÉGORIE</div>
          <div className="mkt-form-cats">
            {CATEGORIES.filter(c => c.id !== 'all').map(cat => (
              <button
                key={cat.id}
                className={`mkt-form-cat ${formCategory === cat.id ? 'mkt-form-cat--active' : ''}`}
                onClick={() => setFormCategory(cat.id as MarketCategory)}
              >
                {cat.icon}
                <span>{cat.label}</span>
              </button>
            ))}
          </div>

          <div className="mkt-form-label">TITRE</div>
          <input
            className="mkt-form-input"
            type="text"
            placeholder="Ex: Sultan RS Custom..."
            value={formTitle}
            onChange={(e) => setFormTitle(e.target.value)}
            maxLength={60}
          />

          <div className="mkt-form-label">DESCRIPTION</div>
          <textarea
            className="mkt-form-textarea"
            placeholder="Détails sur l'article..."
            value={formDesc}
            onChange={(e) => setFormDesc(e.target.value)}
            maxLength={300}
            rows={3}
          />

          <div className="mkt-form-label">PRIX ($)</div>
          <input
            className="mkt-form-input"
            type="number"
            placeholder="50000"
            value={formPrice}
            onChange={(e) => setFormPrice(e.target.value)}
            min="0"
          />

          {formCategory === 'vehicles' && (
            <>
              <div className="mkt-form-label">PHOTOS ({formPhotos.length}/3)</div>
              <div className="mkt-form-photos">
                {formPhotos.map((url, i) => (
                  <div key={i} className="mkt-form-photo">
                    <img src={url} alt="" />
                    <button className="mkt-form-photo-remove" onClick={() => setFormPhotos(prev => prev.filter((_, idx) => idx !== i))}>✕</button>
                  </div>
                ))}
                {formPhotos.length < 3 && (
                  <button className="mkt-form-photo-add" onClick={handleAddPhoto}>
                    <svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor" strokeWidth="2">
                      <path d="M23 19a2 2 0 0 1-2 2H3a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h4l2-3h6l2 3h4a2 2 0 0 1 2 2z" />
                      <circle cx="12" cy="13" r="4" />
                    </svg>
                    <span>AJOUTER</span>
                  </button>
                )}
              </div>
            </>
          )}

          <button
            className="mkt-form-submit"
            disabled={creating || !formTitle.trim() || !formPrice.trim()}
            onClick={handleCreate}
          >
            {creating ? 'PUBLICATION...' : 'PUBLIER L\'ANNONCE'}
          </button>
        </div>
      </div>
    )
  }

  // ---- DETAIL VIEW ----
  if (view === 'detail' && selectedListing) {
    const l = selectedListing
    const isMine = l.is_mine
    const catColor = CATEGORY_COLORS[l.category]
    return (
      <div className="mkt-tab">
        {NotifBanner}
        <div className="mkt-header">
          <button className="mkt-back" onClick={() => { setView('browse'); setSelectedListing(null) }}>
            <svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" strokeWidth="2"><polyline points="15 18 9 12 15 6" /></svg>
          </button>
          <span className="mkt-header-title">DÉTAILS</span>
        </div>

        {l.photos && l.photos.length > 0 && (
          <div className="mkt-detail-photos">
            {l.photos.map((p, i) => {
              const src = photoUrl(p)
              return src ? <img key={i} src={src} alt="" className="mkt-detail-photo" /> : null
            })}
          </div>
        )}

        <div className="mkt-detail-body">
          <div className="mkt-detail-cat">{CATEGORY_LABELS[l.category]}</div>
          <div className="mkt-detail-title">{l.title}</div>
          <div className="mkt-detail-price">${l.price.toLocaleString()}</div>
          {l.status === 'sold' && <div className="mkt-detail-sold-badge">VENDU</div>}
          {l.description && <div className="mkt-detail-desc">{l.description}</div>}

          <div className="mkt-detail-seller">
            <div className="mkt-detail-seller-avatar">
              {l.seller_name.substring(0, 2).toUpperCase()}
            </div>
            <div className="mkt-detail-seller-info">
              <div className="mkt-detail-seller-name">{l.seller_name}</div>
              <div className={`mkt-detail-seller-status ${l.seller_online ? 'mkt-detail-seller-status--on' : ''}`}>
                {l.seller_online ? '● En ligne' : '○ Hors ligne'}
              </div>
            </div>
          </div>

          <div className="mkt-detail-meta">
            Publié le {new Date(l.created_at).toLocaleDateString('fr-FR')}
          </div>

          <div className="mkt-detail-actions">
            {isMine ? (
              <>
                {l.status === 'active' && (
                  <button className="mkt-btn mkt-btn--success" onClick={() => handleMarkSold(l.id)}>
                    MARQUER VENDU
                  </button>
                )}
                <button className="mkt-btn mkt-btn--danger" onClick={() => handleDelete(l.id)}>
                  SUPPRIMER
                </button>
              </>
            ) : (
              l.status === 'active' && (
                <button className="mkt-btn mkt-btn--primary" onClick={() => handleContact(l.seller_id, l.seller_name)}>
                  <svg viewBox="0 0 24 24" width="14" height="14" fill="none" stroke="currentColor" strokeWidth="2"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z" /></svg>
                  CONTACTER LE VENDEUR
                </button>
              )
            )}
          </div>
        </div>
      </div>
    )
  }

  // ---- MY LISTINGS VIEW ----
  if (view === 'my_listings') {
    return (
      <div className="mkt-tab">
        {NotifBanner}
        <div className="mkt-header">
          <button className="mkt-back" onClick={() => setView('browse')}>
            <svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" strokeWidth="2"><polyline points="15 18 9 12 15 6" /></svg>
          </button>
          <span className="mkt-header-title">MES ANNONCES</span>
        </div>

        <div className="mkt-list">
          {myListings.length === 0 ? (
            <div className="mkt-empty">Aucune annonce publiée</div>
          ) : (
            myListings.map(l => (
              <div
                key={l.id}
                className={`mkt-card mkt-card--${l.status}`}
                onClick={() => { setSelectedListing(l); setView('detail') }}
              >
                {l.photos && l.photos[0] && photoUrl(l.photos[0]) && (
                  <div className="mkt-card-thumb">
                    <img src={photoUrl(l.photos[0])!} alt="" />
                  </div>
                )}
                <div className="mkt-card-body">
                  <div className="mkt-card-cat" style={{ color: CATEGORY_COLORS[l.category] }}>
                    {CATEGORY_LABELS[l.category]}
                    {l.status === 'sold' && <span className="mkt-card-sold">VENDU</span>}
                  </div>
                  <div className="mkt-card-title">{l.title}</div>
                  <div className="mkt-card-price">${l.price.toLocaleString()}</div>
                </div>
              </div>
            ))
          )}
        </div>
      </div>
    )
  }

  // ---- BROWSE VIEW (default) ----
  return (
    <div className="mkt-tab">
      {NotifBanner}

      {/* Top actions */}
      <div className="mkt-topbar">
        <button className="mkt-topbar-btn" onClick={() => setView('create')}>
          + VENDRE
        </button>
        <button className="mkt-topbar-btn mkt-topbar-btn--sec" onClick={() => setView('my_listings')}>
          MES ANNONCES ({myListings.length})
        </button>
      </div>

      {/* Category filters */}
      <div className="mkt-cats">
        {CATEGORIES.map(cat => (
          <button
            key={cat.id}
            className={`mkt-cat ${activeCategory === cat.id ? 'mkt-cat--active' : ''}`}
            onClick={() => setActiveCategory(cat.id)}
          >
            {cat.icon}
            <span>{cat.label}</span>
          </button>
        ))}
      </div>

      {/* Listings */}
      <div className="mkt-list">
        {filteredListings.length === 0 ? (
          <div className="mkt-empty">
            <svg viewBox="0 0 24 24" width="32" height="32" fill="none" stroke="#333" strokeWidth="1.5">
              <rect x="2" y="7" width="20" height="14" rx="2" /><path d="M16 7V5a2 2 0 0 0-2-2h-4a2 2 0 0 0-2 2v2" />
            </svg>
            <span>Aucune annonce dans cette catégorie</span>
          </div>
        ) : (
          filteredListings.map((l, i) => (
            <div
              key={l.id}
              className="mkt-card"
              style={{ animationDelay: `${i * 0.04}s` }}
              onClick={() => { setSelectedListing(l); setView('detail') }}
            >
              {l.photos && l.photos[0] && photoUrl(l.photos[0]) && (
                <div className="mkt-card-thumb">
                  <img src={photoUrl(l.photos[0])!} alt="" />
                </div>
              )}
              <div className="mkt-card-body">
                <div className="mkt-card-cat" style={{ color: CATEGORY_COLORS[l.category] }}>
                  {CATEGORY_LABELS[l.category]}
                </div>
                <div className="mkt-card-title">{l.title}</div>
                <div className="mkt-card-price">${l.price.toLocaleString()}</div>
              </div>
              <div className="mkt-card-seller">
                <span className={l.seller_online ? 'mkt-online' : ''}>{l.seller_name}</span>
              </div>
            </div>
          ))
        )}
      </div>
    </div>
  )
}
