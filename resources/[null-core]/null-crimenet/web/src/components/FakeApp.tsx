import { useState } from 'react'
import { 
  Pizza, Leaf, Drumstick, Apple, Croissant,
  Package, User, MapPin, CreditCard, Star, Settings, Check, Home, ClipboardList
} from 'lucide-react'

const MENU_ITEMS = [
  { name: 'Margherita', price: '8.99$', desc: 'Tomate, mozzarella, basilic', Icon: Pizza, color: '#ea580c' },
  { name: 'Pepperoni', price: '10.99$', desc: 'Double pepperoni, fromage', Icon: Pizza, color: '#dc2626' },
  { name: 'Végétarienne', price: '9.99$', desc: 'Poivrons, champignons, olives', Icon: Leaf, color: '#16a34a' },
  { name: 'BBQ Chicken', price: '12.99$', desc: 'Poulet grillé, sauce BBQ', Icon: Drumstick, color: '#d97706' },
  { name: 'Hawaïenne', price: '11.49$', desc: 'Jambon, ananas, fromage', Icon: Apple, color: '#f59e0b' },
  { name: 'Calzone', price: '13.99$', desc: 'Chausson farci, ricotta', Icon: Croissant, color: '#9333ea' },
]

export default function FakeApp() {
  const [selectedTab, setSelectedTab] = useState<'menu' | 'orders' | 'account'>('menu')
  const [cart, setCart] = useState<string[]>([])

  const addToCart = (name: string) => {
    setCart(prev => [...prev, name])
    setTimeout(() => setCart(prev => prev.filter((_, i) => i !== prev.length - 1)), 2000)
  }

  return (
    <div className="fake-app">
      {/* Header */}
      <div className="fake-header">
        <div className="fake-logo-row">
          <Pizza size={24} color="white" strokeWidth={2.5} />
          <span className="fake-logo-text">PizzaGo</span>
        </div>
        <div className="fake-subtitle">Livraison rapide à domicile</div>
      </div>

      {/* Promo banner */}
      <div className="fake-promo">
        <span className="fake-promo-badge">PROMO</span>
        <span className="fake-promo-text">-20% sur votre 1ère commande !</span>
      </div>

      {/* Content */}
      <div className="fake-content">
        {selectedTab === 'menu' && (
          <div className="fake-menu">
            <div className="fake-section-title">Notre carte</div>
            <div className="fake-grid">
              {MENU_ITEMS.map((item) => (
                <div className="fake-grid-card" key={item.name} onClick={() => addToCart(item.name)}>
                  <div className="fake-grid-img">
                    <item.Icon size={36} color={item.color} strokeWidth={1.5} />
                  </div>
                  <div className="fake-grid-info">
                    <div className="fake-grid-name">{item.name}</div>
                    <div className="fake-grid-desc">{item.desc}</div>
                    <div className="fake-grid-price">{item.price}</div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        {selectedTab === 'orders' && (
          <div className="fake-orders">
            <div className="fake-section-title">Mes commandes</div>
            <div className="fake-empty">
              <div className="fake-empty-icon">
                <Package size={40} color="#ddd" strokeWidth={1.5} />
              </div>
              <div className="fake-empty-text">Aucune commande en cours</div>
              <div className="fake-empty-sub">Passez votre première commande !</div>
            </div>
          </div>
        )}

        {selectedTab === 'account' && (
          <div className="fake-account">
            <div className="fake-section-title">Mon compte</div>
            <div className="fake-account-card">
              <div className="fake-account-avatar">
                <User size={32} color="#ea580c" strokeWidth={1.5} />
              </div>
              <div className="fake-account-info">
                <div className="fake-account-name">Utilisateur</div>
                <div className="fake-account-email">user@pizzago.com</div>
              </div>
            </div>
            <div className="fake-account-row">
              <MapPin size={18} color="#ea580c" />
              <span>Adresses de livraison</span>
              <span className="fake-chevron">›</span>
            </div>
            <div className="fake-account-row">
              <CreditCard size={18} color="#ea580c" />
              <span>Moyens de paiement</span>
              <span className="fake-chevron">›</span>
            </div>
            <div className="fake-account-row">
              <Star size={18} color="#ea580c" />
              <span>Programme fidélité</span>
              <span className="fake-chevron">›</span>
            </div>
            <div className="fake-account-row">
              <Settings size={18} color="#ea580c" />
              <span>Paramètres</span>
              <span className="fake-chevron">›</span>
            </div>
          </div>
        )}
      </div>

      {/* Cart toast */}
      {cart.length > 0 && (
        <div className="fake-toast">
          <Check size={16} /> {cart[cart.length - 1]} ajouté au panier
        </div>
      )}

      {/* Bottom nav */}
      <div className="fake-nav">
        <button className={`fake-nav-btn ${selectedTab === 'menu' ? 'active' : ''}`} onClick={() => setSelectedTab('menu')}>
          <span className="fake-nav-icon">
            <Home size={20} strokeWidth={2} />
          </span>
          <span className="fake-nav-label">Menu</span>
        </button>
        <button className={`fake-nav-btn ${selectedTab === 'orders' ? 'active' : ''}`} onClick={() => setSelectedTab('orders')}>
          <span className="fake-nav-icon">
            <ClipboardList size={20} strokeWidth={2} />
          </span>
          <span className="fake-nav-label">Commandes</span>
        </button>
        <button className={`fake-nav-btn ${selectedTab === 'account' ? 'active' : ''}`} onClick={() => setSelectedTab('account')}>
          <span className="fake-nav-icon">
            <User size={20} strokeWidth={2} />
          </span>
          <span className="fake-nav-label">Compte</span>
        </button>
      </div>
    </div>
  )
}
