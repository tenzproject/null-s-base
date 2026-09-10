import React, { useState, useEffect, useCallback, useMemo } from 'react';
import { cacheImg } from '@shared/cacheVersion';
import { MarketData, MarketItem } from '../types';

const Res = () => 'null-core';
const post = <T = any>(event: string, body: any = {}): Promise<T> =>
  fetch(`https://${Res()}/${event}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  }).then(r => r.json()).catch(() => ({} as any));

interface MarketAppData {
  blackmarket?: MarketData | null;
  permissions?: { perms_vente?: Record<string, boolean> };
  playerGrade?: number;
  kitArme?: number | boolean;
}

interface MarketAppProps {
  onBack: () => void;
}

const MarketApp: React.FC<MarketAppProps> = ({ onBack }) => {
  const [data, setData] = useState<MarketAppData | null>(null);
  const [loading, setLoading] = useState(true);

  const refresh = useCallback(async () => {
    const r = await post<MarketAppData>('illegalDevice:market:getData');
    setData(r || null);
    setLoading(false);
  }, []);

  useEffect(() => { refresh(); }, [refresh]);

  const bm = data?.blackmarket;
  const canBuy = useMemo(
    () => !!data?.permissions?.perms_vente?.[String(data?.playerGrade ?? -1)],
    [data]
  );

  const buy = useCallback(async (type: 'weapon' | 'item', id: string, quantity: number) => {
    const event = type === 'weapon' ? 'illegalDevice:market:buyWeapon' : 'illegalDevice:market:buyItem';
    const r = await post<MarketAppData>(event, type === 'weapon'
      ? { weaponId: id, quantity }
      : { itemId: id, quantity });
    if (r) setData(r);
  }, []);

  return (
    <div className="idev-app-view idev-market">
      <div className="idev-app-bar">
        <button className="idev-back" onClick={onBack}>‹ Organisation</button>
        <div className="idev-app-title">
          <span>Marché noir</span>
          <small>Paiement en argent sale</small>
        </div>
        <div style={{ width: 80 }} />
      </div>

      {loading && <div className="idev-empty">Connexion au réseau…</div>}

      {!loading && (!bm || !bm.unlocked) && (
        <div className="idev-market-locked">
          <div className="idev-market-lock-glyph">
            <span />
            <span />
          </div>
          <h3>Accès restreint</h3>
          <p>
            {!data?.kitArme || (data.kitArme !== 1 && data.kitArme !== true)
              ? "Ton organisation n'a pas le kit d'armes."
              : "Monte en niveau pour débloquer le réseau."}
          </p>
        </div>
      )}

      {!loading && bm && bm.unlocked && (
        <div className="idev-market-body">
          <div className="idev-market-bar">
            <span className="idev-market-bar-note">Stock livré directement dans le coffre.</span>
            {(bm.discount ?? 0) > 0 && (
              <span className="idev-market-discount">−{bm.discount}%</span>
            )}
          </div>

          {!canBuy && (
            <div className="idev-banner idev-banner-warn">
              Tu n'as pas la permission d'acheter. Vois ça avec ton chef.
            </div>
          )}

          {bm.weapons && bm.weapons.length > 0 && (
            <div className="idev-market-group">
              <div className="idev-market-group-head">Armes</div>
              <div className="idev-market-grid">
                {bm.weapons.map(w => (
                  <MarketCard
                    key={w.id}
                    item={w}
                    type="weapon"
                    canBuy={canBuy}
                    discount={bm.discount ?? 0}
                    onBuy={(qty) => buy('weapon', w.id, qty)}
                  />
                ))}
              </div>
            </div>
          )}

          {bm.items && bm.items.length > 0 && (
            <div className="idev-market-group">
              <div className="idev-market-group-head">Équipements</div>
              <div className="idev-market-grid">
                {bm.items.map(it => (
                  <MarketCard
                    key={it.id}
                    item={it}
                    type="item"
                    canBuy={canBuy}
                    discount={bm.discount ?? 0}
                    onBuy={(qty) => buy('item', it.id, qty)}
                  />
                ))}
              </div>
            </div>
          )}

          {(!bm.weapons || bm.weapons.length === 0) && (!bm.items || bm.items.length === 0) && (
            <div className="idev-empty">Aucun stock disponible pour le moment.</div>
          )}
        </div>
      )}
    </div>
  );
};

interface MarketCardProps {
  item: MarketItem;
  type: 'weapon' | 'item';
  canBuy: boolean;
  discount: number;
  onBuy: (quantity: number) => Promise<void>;
}

const MarketCard: React.FC<MarketCardProps> = ({ item, type, canBuy, discount, onBuy }) => {
  const [qty, setQty] = useState(1);
  const [buying, setBuying] = useState(false);
  const total = item.price * qty;
  const iconUrl = cacheImg(`items/${type === 'weapon' ? item.name.toLowerCase() : item.name}.webp`);

  const handleBuy = async () => {
    if (!canBuy || buying) return;
    setBuying(true);
    try { await onBuy(qty); } finally { setTimeout(() => setBuying(false), 1500); }
  };

  return (
    <div className="idev-market-card">
      <div className="idev-market-card-thumb">
        <img
          src={iconUrl}
          alt={item.label}
          onError={(e) => { (e.target as HTMLImageElement).style.opacity = '0'; }}
        />
      </div>
      <div className="idev-market-card-main">
        <span className="idev-market-card-label">{item.label}</span>
        <div className="idev-market-card-price">
          {discount > 0 && <s>${item.basePrice.toLocaleString()}</s>}
          <strong>${item.price.toLocaleString()}</strong>
        </div>
      </div>
      <div className="idev-market-card-buy">
        <div className="idev-market-stepper">
          <button onClick={() => setQty(q => Math.max(1, q - 1))} disabled={qty <= 1}>−</button>
          <span>{qty}</span>
          <button onClick={() => setQty(q => Math.min(10, q + 1))} disabled={qty >= 10}>+</button>
        </div>
        <button
          className="idev-market-cta"
          disabled={!canBuy || buying}
          onClick={handleBuy}
        >
          {buying ? 'Envoi…' : `$${total.toLocaleString()}`}
        </button>
      </div>
    </div>
  );
};

export default MarketApp;
