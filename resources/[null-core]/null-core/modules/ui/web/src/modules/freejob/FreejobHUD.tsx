import React, { useState, useEffect } from 'react';
import { generateAccentVars } from '@/utils/accentColors';
import { Axe, Waves, Forklift, Briefcase, CheckCircle, TrendingUp, DollarSign } from 'lucide-react';
import { FreejobHUDProps, FreejobHUDData } from './types';
import './Freejob.css';

const ICON_MAP: Record<string, React.ReactNode> = {
  axe: <Axe size={16} />,
  pool: <Waves size={16} />,
  forklift: <Forklift size={16} />,
};

const FreejobHUD: React.FC<FreejobHUDProps> = ({ visible, primaryColor, serverIcon }) => {
  const [data, setData] = useState<FreejobHUDData | null>(null);
  const [progressActive, setProgressActive] = useState(false);
  const [progressDuration, setProgressDuration] = useState(0);
  const [hiding, setHiding] = useState(false);

  useEffect(() => {
    const handler = (event: MessageEvent) => {
      const msg = event.data || {};
      if (msg.action === 'freejobHUD:open' && msg.data) {
        setData(msg.data);
      } else if (msg.action === 'freejobHUD:update' && msg.data && data) {
        setData(prev => prev ? { ...prev, ...msg.data } : null);
      } else if (msg.action === 'freejobHUD:progress' && msg.data) {
        setProgressDuration(msg.data.duration || 3000);
        setProgressActive(true);
        setTimeout(() => setProgressActive(false), msg.data.duration || 3000);
      } else if (msg.action === 'freejobHUD:close') {
        setHiding(true);
        setTimeout(() => {
          setData(null);
          setHiding(false);
        }, 300);
      }
    };
    window.addEventListener('message', handler);
    return () => window.removeEventListener('message', handler);
  }, [data]);

  if (!data && !hiding) return null;
  if (!visible && !hiding) return null;

  return (
    <div className={`fjhud ${hiding ? 'fjhud-hiding' : ''}`} style={generateAccentVars('--fj-accent', primaryColor || '#3b82f6') as React.CSSProperties}>
      <div className="fjhud-header">
        <div className="fjhud-icon">
          {serverIcon ? (
            <img src={serverIcon} alt="" style={{ width: 30, height: 30, objectFit: 'contain' }} />
          ) : (
            ICON_MAP[data?.jobIcon || ''] || <Briefcase size={16} />
          )}
        </div>
        <span className="fjhud-title">{data?.jobName || 'Emploi'}</span>
      </div>

      <div className="fjhud-stats">
        <div className="fjhud-stat">
          <span className="fjhud-stat-label">Tâches</span>
          <span className="fjhud-stat-value">{data?.tasks || 0}</span>
        </div>
        <div className="fjhud-stat">
          <span className="fjhud-stat-label">Bonus</span>
          <span className="fjhud-stat-value">{data?.bonus || 0}%</span>
        </div>
        <div className="fjhud-stat fjhud-stat-reward">
          <span className="fjhud-stat-label">Salaire</span>
          <span className="fjhud-stat-value">${data?.reward || 0}</span>
        </div>
      </div>

      {progressActive && (
        <div className="fjhud-progress">
          <div
            className="fjhud-progress-bar"
            style={{ animationDuration: `${progressDuration}ms` }}
          />
        </div>
      )}
    </div>
  );
};

export default FreejobHUD;
