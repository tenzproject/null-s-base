import React, { useState, useEffect, useCallback } from 'react';
import { generateAccentVars } from '@/utils/accentColors';
import {
  X, Briefcase, MapPin, DollarSign, ChevronRight, Axe, Waves, Forklift,
  TrendingUp, Loader2
} from 'lucide-react';
import { FreejobTabletProps, FreejobMetier } from './types';
import './Freejob.css';

const GetParentResourceName = () => 'null-core';

const ICON_MAP: Record<string, React.ReactNode> = {
  axe: <Axe size={22} />,
  pool: <Waves size={22} />,
  forklift: <Forklift size={22} />,
};

const DEFAULT_IMAGES: Record<string, string> = {
  bucheron: 'nui://null-cache/images/freejobs/woodcuting.webp',
  cleanpool: 'nui://null-cache/images/freejobs/poolcleaner.webp',
  entrepot: 'nui://null-cache/images/freejobs/cariste.webp',
};

const FreejobTablet: React.FC<FreejobTabletProps> = ({ visible, onClose, primaryColor }) => {
  const [metiers, setMetiers] = useState<FreejobMetier[]>([]);
  const [hiding, setHiding] = useState(false);
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const accentColor = primaryColor || '#3b82f6';

  useEffect(() => {
    const handler = (event: MessageEvent) => {
      const { action, data } = event.data || {};
      if (action === 'freejobTablet:setData' && data) {
        setMetiers(data.metiers || []);
      }
    };
    window.addEventListener('message', handler);
    return () => window.removeEventListener('message', handler);
  }, []);

  useEffect(() => {
    if (visible) {
      setSelectedId(null);
    }
  }, [visible]);

  const handleClose = useCallback(() => {
    setHiding(true);
    setTimeout(() => {
      setHiding(false);
      onClose();
      fetch(`https://${GetParentResourceName()}/freejobTablet:close`, { method: 'POST' }).catch(() => {});
    }, 250);
  }, [onClose]);

  const handleSelect = useCallback((metier: FreejobMetier) => {
    setSelectedId(metier.id);
    setTimeout(() => {
      fetch(`https://${GetParentResourceName()}/freejobTablet:selectJob`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ jobId: metier.id }),
      }).catch(() => {});
      setHiding(true);
      setTimeout(() => {
        setHiding(false);
        onClose();
      }, 250);
    }, 300);
  }, [onClose]);

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape' && visible) handleClose();
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [visible, handleClose]);

  if (!visible && !hiding) return null;

  return (
    <div className={`fj-tablet-overlay ${hiding ? 'fj-hiding' : ''}`} style={generateAccentVars('--fj-accent', accentColor) as React.CSSProperties}>
      <div className="fj-tablet">
        {/* Header */}
        <div className="fj-tablet-header">
          <div className="fj-tablet-header-text">
            <h1>Agence Intérimaire</h1>
            <p>Choisissez un emploi disponible</p>
          </div>
          <button className="fj-tablet-close" onClick={handleClose}>
            <X size={18} />
          </button>
        </div>

        {/* Job list */}
        <div className="fj-tablet-list">
          {metiers.length === 0 ? (
            <div className="fj-tablet-loading">
              <Loader2 size={20} className="fj-spin" />
              <span>Chargement...</span>
            </div>
          ) : (
            metiers.map(m => (
              <div
                key={m.id}
                className={`fj-tablet-card ${selectedId === m.id ? 'fj-selected' : ''}`}
                onClick={() => handleSelect(m)}
              >
                <div className="fj-tablet-card-image">
                  <img src={m.image || DEFAULT_IMAGES[m.id] || DEFAULT_IMAGES.entrepot} alt={m.nom} />
                </div>
                <div className="fj-tablet-card-info">
                  <h3>{m.nom}</h3>
                  <p>{m.description}</p>
                  <div className="fj-tablet-card-meta">
                    <span className="fj-tablet-card-tag">
                      Rentabilité : {m.rentabilite}%
                    </span>
                  </div>
                </div>
                <div className="fj-tablet-card-arrow">
                  <ChevronRight size={18} />
                </div>
              </div>
            ))
          )}
        </div>

        {/* Footer */}
        <div className="fj-tablet-footer">
          <span>La rémunération dépend de votre productivité et du bonus accumulé</span>
        </div>
      </div>
    </div>
  );
};

export default FreejobTablet;
