import React, { useEffect, useRef, useState } from 'react';
import { generateAccentVars } from '@/utils/accentColors';
import { DollarSign, Route, User, Car, CheckCircle } from 'lucide-react';
import './Taxi.css';

interface RideStartPayload {
  role?: 'driver' | 'passenger';
  citizen?: string;
  driverName?: string;
}
interface RideUpdatePayload  { meters?: number; price?: number; }
interface RideEndPayload     { price?: number; paid?: number; }

interface TaxiRideHUDProps { primaryColor?: string; }

const TaxiRideHUD: React.FC<TaxiRideHUDProps> = ({ primaryColor }) => {
  const [active, setActive]   = useState(false);
  const [role,   setRole]     = useState<'driver' | 'passenger'>('passenger');
  const [info,   setInfo]     = useState<RideStartPayload>({});
  const [meters, setMeters]   = useState(0);
  const [price,  setPrice]    = useState(0);
  const [summary, setSummary] = useState<RideEndPayload | null>(null);
  const summaryTimer = useRef<number | null>(null);

  useEffect(() => {
    const handler = (event: MessageEvent) => {
      const msg = event.data || {};
      switch (msg.action) {
        case 'taxiRide:start':
          if (msg.data) {
            setActive(true);
            setSummary(null);
            setRole(msg.data.role === 'driver' ? 'driver' : 'passenger');
            setInfo(msg.data || {});
            setMeters(0);
            setPrice(0);
          }
          break;
        case 'taxiRide:update':
          if (msg.data) {
            setMeters(msg.data.meters || 0);
            setPrice(msg.data.price || 0);
          }
          break;
        case 'taxiRide:end':
          setActive(false);
          if (msg.data) {
            setSummary(msg.data);
            if (summaryTimer.current) window.clearTimeout(summaryTimer.current);
            summaryTimer.current = window.setTimeout(() => setSummary(null), 6000);
          }
          break;
      }
    };
    window.addEventListener('message', handler);
    return () => window.removeEventListener('message', handler);
  }, []);

  const accent = generateAccentVars('--taxiride-accent', primaryColor || '#f5b400') as React.CSSProperties;

  if (!active && !summary) return null;

  const km = (meters / 1000).toFixed(2);

  return (
    <div className="taxiride-root" style={accent}>
      {active && (
        <div className="taxiride-card">
          <div className="taxiride-head">
            <span className="taxiride-pill">
              {role === 'driver' ? <Car size={12} /> : <User size={12} />}
              <span>{role === 'driver' ? 'Course en cours' : 'Vous êtes en course'}</span>
            </span>
            <span className="taxiride-sub">
              {role === 'driver'
                ? (info.citizen ? `Client : ${info.citizen}` : 'Client à bord')
                : (info.driverName ? `Chauffeur : ${info.driverName}` : 'Trajet en cours')}
            </span>
          </div>

          <div className="taxiride-stats">
            <div className="taxiride-stat">
              <span className="taxiride-stat-icon"><Route size={12} /></span>
              <span className="taxiride-stat-label">Distance</span>
              <span className="taxiride-stat-value">{km} km</span>
            </div>
            <div className="taxiride-stat taxiride-stat-fare">
              <span className="taxiride-stat-icon"><DollarSign size={12} /></span>
              <span className="taxiride-stat-label">Tarif</span>
              <span className="taxiride-stat-value">${price}</span>
            </div>
          </div>

          <div className="taxiride-foot">
            {role === 'driver'
              ? "Le client descend pour clôturer la course."
              : "Le tarif s'arrête lorsque vous descendez du taxi."}
          </div>
        </div>
      )}

      {summary && !active && (
        <div className="taxiride-summary">
          <div className="taxiride-summary-head">
            <CheckCircle size={18} />
            <span>Course terminée</span>
          </div>
          <div className="taxiride-summary-row">
            <span>Tarif</span>
            <span>${summary.price ?? 0}</span>
          </div>
          {typeof summary.paid === 'number' && (
            <div className="taxiride-summary-row taxiride-summary-paid">
              <span>Payé</span>
              <span>${summary.paid}</span>
            </div>
          )}
        </div>
      )}
    </div>
  );
};

export default TaxiRideHUD;
