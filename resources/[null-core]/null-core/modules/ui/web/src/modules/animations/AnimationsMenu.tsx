import React, { useState, useEffect, useCallback, useRef } from 'react';
import { Star, Smile, Music, Users, Box, Footprints, Drama, PawPrint, Search, X, Square, ChevronRight, Play, Heart } from 'lucide-react';
import './AnimationsMenu.css';

const GetParentResourceName = () => 'null-core';

type AnimCategory = 'favorites' | 'emotes' | 'dances' | 'shared' | 'props' | 'walks' | 'expressions' | 'animals';

interface AnimationItem {
  label?: string;
  name?: string;
  command?: string;
  category?: string;
}

interface AnimationsData {
  favorites: string[];
  emotes: Record<string, AnimationItem>;
  dances: Record<string, AnimationItem>;
  shared: Record<string, AnimationItem>;
  props: Record<string, AnimationItem>;
  walks: Record<string, AnimationItem>;
  expressions: Record<string, AnimationItem>;
  animals: Record<string, AnimationItem>;
}

interface AnimationsMenuProps {
  visible: boolean;
  onClose: () => void;
  primaryColor: string;
}

const CATEGORIES: { id: AnimCategory; label: string; icon: React.ReactNode }[] = [
  { id: 'favorites', label: 'Favoris', icon: <Star size={18} /> },
  { id: 'emotes', label: 'Émotes', icon: <Smile size={18} /> },
  { id: 'dances', label: 'Danses', icon: <Music size={18} /> },
  { id: 'shared', label: 'Partagées', icon: <Users size={18} /> },
  { id: 'props', label: 'Avec Objets', icon: <Box size={18} /> },
  { id: 'walks', label: 'Démarches', icon: <Footprints size={18} /> },
  { id: 'expressions', label: 'Expressions', icon: <Drama size={18} /> },
  { id: 'animals', label: 'Animaux', icon: <PawPrint size={18} /> },
];

const STORAGE_KEY = 'animationsMenuPosition';

const AnimationsMenu: React.FC<AnimationsMenuProps> = ({ visible, onClose, primaryColor }) => {
  const [category, setCategory] = useState<AnimCategory>('favorites');
  const [search, setSearch] = useState('');
  const [playing, setPlaying] = useState<string | null>(null);
  const [pageTransition, setPageTransition] = useState(false);
  const [data, setData] = useState<AnimationsData>({
    favorites: [],
    emotes: {},
    dances: {},
    shared: {},
    props: {},
    walks: {},
    expressions: {},
    animals: {},
  });
  const searchRef = useRef<HTMLInputElement>(null);
  const containerRef = useRef<HTMLDivElement>(null);
  const dragging = useRef(false);
  const dragOffset = useRef({ x: 0, y: 0 });
  const [position, setPosition] = useState<{ x: number; y: number } | null>(() => {
    try {
      const saved = localStorage.getItem(STORAGE_KEY);
      return saved ? JSON.parse(saved) : null;
    } catch { return null; }
  });

  // Drag handlers
  const handleMouseDown = useCallback((e: React.MouseEvent) => {
    if (!containerRef.current) return;
    const rect = containerRef.current.getBoundingClientRect();
    dragOffset.current = { x: e.clientX - rect.left, y: e.clientY - rect.top };
    dragging.current = true;
  }, []);

  useEffect(() => {
    const handleMouseMove = (e: MouseEvent) => {
      if (!dragging.current || !containerRef.current) return;
      const maxX = window.innerWidth - containerRef.current.offsetWidth;
      const maxY = window.innerHeight - containerRef.current.offsetHeight;
      const x = Math.max(0, Math.min(e.clientX - dragOffset.current.x, maxX));
      const y = Math.max(0, Math.min(e.clientY - dragOffset.current.y, maxY));
      setPosition({ x, y });
    };
    const handleMouseUp = () => {
      if (dragging.current) {
        dragging.current = false;
        setPosition(prev => {
          if (prev) localStorage.setItem(STORAGE_KEY, JSON.stringify(prev));
          return prev;
        });
      }
    };
    window.addEventListener('mousemove', handleMouseMove);
    window.addEventListener('mouseup', handleMouseUp);
    return () => {
      window.removeEventListener('mousemove', handleMouseMove);
      window.removeEventListener('mouseup', handleMouseUp);
    };
  }, []);

  // NUI message handler
  useEffect(() => {
    const handler = (event: MessageEvent) => {
      const msg = event.data;
      if (msg.action === 'updateAnimationsData') {
        setData({
          favorites: msg.favorites || [],
          emotes: msg.emotes || {},
          dances: msg.dances || {},
          shared: msg.shared || {},
          props: msg.props || {},
          walks: msg.walks || {},
          expressions: msg.expressions || {},
          animals: msg.animals || {},
        });
      }
    };
    window.addEventListener('message', handler);
    return () => window.removeEventListener('message', handler);
  }, []);

  // Request data when opened
  useEffect(() => {
    if (visible) {
      fetch(`https://${GetParentResourceName()}/animations:getData`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({}),
      });
      setCategory('favorites');
      setSearch('');
      setPlaying(null);
    }
  }, [visible]);

  // ESC to close
  useEffect(() => {
    const handleKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape' && visible) {
        handleClose();
      }
    };
    window.addEventListener('keydown', handleKey);
    return () => window.removeEventListener('keydown', handleKey);
  }, [visible]);

  const handleClose = useCallback(() => {
    fetch(`https://${GetParentResourceName()}/animations:close`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({}),
    });
    onClose();
  }, [onClose]);

  const handleCategoryChange = (cat: AnimCategory) => {
    if (cat === category) return;
    setPageTransition(true);
    setSearch('');
    setTimeout(() => {
      setCategory(cat);
      requestAnimationFrame(() => setPageTransition(false));
    }, 120);
  };

  const handlePlay = (key: string, cat: string) => {
    setPlaying(key);
    fetch(`https://${GetParentResourceName()}/animations:play`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ animation: key, category: cat }),
    });
  };

  const handleStop = () => {
    setPlaying(null);
    fetch(`https://${GetParentResourceName()}/animations:stop`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({}),
    });
  };

  const handleToggleFavorite = (key: string) => {
    const newFavs = data.favorites.includes(key)
      ? data.favorites.filter(f => f !== key)
      : [...data.favorites, key];
    setData(prev => ({ ...prev, favorites: newFavs }));
    fetch(`https://${GetParentResourceName()}/animations:updateFavorites`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ favorites: newFavs }),
    });
  };

  // Get animations for current category
  const getAnimations = (): [string, AnimationItem][] => {
    if (category === 'favorites') {
      const all: Record<string, AnimationItem> = {
        ...data.emotes,
        ...data.dances,
        ...data.shared,
        ...data.props,
        ...data.walks,
        ...data.expressions,
        ...data.animals,
      };
      return data.favorites
        .filter(key => all[key])
        .map(key => [key, all[key]]);
    }
    return Object.entries(data[category] || {});
  };

  const animations = getAnimations();
  const filtered = search
    ? animations.filter(([key, anim]) => {
        const name = (anim.label || anim.name || key).toLowerCase();
        const cmd = (anim.command || key).toLowerCase();
        return name.includes(search.toLowerCase()) || cmd.includes(search.toLowerCase());
      })
    : animations;

  if (!visible) return null;

  return (
    <div className="anims-overlay">
      <div
        ref={containerRef}
        className="anims-container"
        style={position ? { left: position.x, top: position.y, transform: 'none' } : {}}
      >
        {/* Sidebar */}
        <div className="anims-sidebar">
          <div className="anims-sidebar-header" onMouseDown={handleMouseDown} style={{ cursor: 'grab' }}>
            <h2 className="anims-sidebar-title">Animations</h2>
            <button className="anims-close-btn" onClick={handleClose}>
              <X size={16} />
            </button>
          </div>

          <div className="anims-search">
            <Search size={14} className="anims-search-icon" />
            <input
              ref={searchRef}
              type="text"
              placeholder="Rechercher..."
              value={search}
              onChange={e => setSearch(e.target.value)}
              className="anims-search-input"
            />
            {search && (
              <button className="anims-search-clear" onClick={() => setSearch('')}>
                <X size={12} />
              </button>
            )}
          </div>

          <nav className="anims-categories">
            {CATEGORIES.map(cat => (
              <button
                key={cat.id}
                className={`anims-category-btn ${category === cat.id ? 'active' : ''}`}
                onClick={() => handleCategoryChange(cat.id)}
                style={category === cat.id ? { backgroundColor: primaryColor } : {}}
              >
                {cat.icon}
                <span>{cat.label}</span>
                {cat.id === 'favorites' && data.favorites.length > 0 && (
                  <span className="anims-category-count">{data.favorites.length}</span>
                )}
                <ChevronRight size={14} className="anims-category-arrow" />
              </button>
            ))}
          </nav>

          {/* Stop button */}
          {playing && (
            <div className="anims-sidebar-footer">
              <button className="anims-stop-btn" onClick={handleStop}>
                <Square size={14} />
                <span>Arrêter l'animation</span>
              </button>
            </div>
          )}
        </div>

        {/* Main content */}
        <div className="anims-main">
          <div className="anims-topbar">
            <h3 className="anims-topbar-title">
              {CATEGORIES.find(c => c.id === category)?.label}
            </h3>
            <span className="anims-topbar-count">{filtered.length} animation{filtered.length !== 1 ? 's' : ''}</span>
          </div>

          <div className={`anims-content ${pageTransition ? 'anims-content-transitioning' : 'anims-content-visible'}`}>
            {filtered.length === 0 ? (
              <div className="anims-empty">
                {category === 'favorites' ? (
                  <>
                    <Star size={40} />
                    <p>Aucun favori</p>
                    <span>Clique sur le cœur d'une animation pour l'ajouter</span>
                  </>
                ) : search ? (
                  <>
                    <Search size={40} />
                    <p>Aucun résultat</p>
                    <span>Essaie un autre terme de recherche</span>
                  </>
                ) : (
                  <>
                    <Box size={40} />
                    <p>Aucune animation</p>
                    <span>Cette catégorie est vide</span>
                  </>
                )}
              </div>
            ) : (
              <div className="anims-grid">
                {filtered.map(([key, anim], i) => {
                  const animName = anim.label || anim.name || key;
                  const animCmd = anim.command || key;
                  const isFav = data.favorites.includes(key);
                  const isPlaying = playing === key;

                  return (
                    <div
                      key={key}
                      className={`anims-item ${isPlaying ? 'playing' : ''}`}
                      style={isPlaying ? { borderColor: `${primaryColor}60` } : {}}
                    >
                      <button
                        className="anims-item-play"
                        onClick={() => handlePlay(key, category)}
                        style={isPlaying ? { backgroundColor: primaryColor } : {}}
                      >
                        <Play size={14} />
                      </button>
                      <div className="anims-item-info">
                        <span className="anims-item-name">{animName}</span>
                        <span className="anims-item-cmd">/e {animCmd}</span>
                      </div>
                      <button
                        className={`anims-item-fav ${isFav ? 'active' : ''}`}
                        onClick={() => handleToggleFavorite(key)}
                        style={isFav ? { color: primaryColor } : {}}
                      >
                        <Heart size={14} fill={isFav ? primaryColor : 'none'} />
                      </button>
                    </div>
                  );
                })}
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};

export default AnimationsMenu;
