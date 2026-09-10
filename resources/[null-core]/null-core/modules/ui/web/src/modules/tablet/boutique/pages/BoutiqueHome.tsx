import React from 'react';
import { DailyShopItem, BoutiquePage } from '../types';
import { Clock, Car, Swords, Package, Crown, Shield, Flame, Crosshair, ChevronRight } from 'lucide-react';

interface BoutiqueHomeProps {
  primaryColor: string;
  serverConfig: {
    serverName: string;
    serverColor: string;
    serverIcon: string;
    serverDiscord: string;
  };
  dailyItems: DailyShopItem[];
  nightMarketActive: boolean;
  nightMarketTimeLeft: number;
  onNavigate: (page: BoutiquePage) => void;
  onItemClick: (item: DailyShopItem) => void;
}

const CAT_IMG = 'nui://null-cache/images/boutique/categories';

const formatSeconds = (s: number) => {
  if (!s || s <= 0) return '—';
  const h = Math.floor(s / 3600);
  const m = Math.floor((s % 3600) / 60);
  if (h > 0) return `${h}h ${m}min`;
  return `${m}min`;
};

const BoutiqueHome: React.FC<BoutiqueHomeProps> = ({
  serverConfig,
  dailyItems,
  nightMarketActive,
  nightMarketTimeLeft,
  onNavigate,
}) => {
  const now = new Date();
  const midnight = new Date(now);
  midnight.setHours(24, 0, 0, 0);
  const diff = midnight.getTime() - now.getTime();
  const hoursLeft = Math.floor(diff / 3_600_000);
  const minutesLeft = Math.floor((diff % 3_600_000) / 60_000);

  const dailyPreview = dailyItems.slice(0, 3);
  const compactCount = 2 + (nightMarketActive ? 1 : 0);

  return (
    <div className="bq-home">
      {/*
      <div className="bq-home-intro">
        <span className="bq-home-eyebrow">Boutique</span>
        <h1 className="bq-home-title">
          {serverConfig.serverName || 'Null'}<span className="bq-home-title-accent">.</span>
        </h1>
        <p className="bq-home-subtitle">
          Véhicules, armes et privilèges. Soutiens le serveur, débloque des avantages.
        </p>
      </div>
      */}

      <div className={`bq-hero-grid bq-hero-grid--compact-${compactCount}`}>
        {/* Daily Shop — grande carte */}
        <button
          className="bq-card bq-card-daily"
          onClick={() => onNavigate('daily')}
        >
          <img src={`${CAT_IMG}/dailyshop.webp`} alt="" className="bq-card-img" />
          <div className="bq-card-shade" />
          <div className="bq-card-body">
            <div className="bq-card-head">
              <span className="bq-card-eyebrow">Renouvelé chaque jour</span>
              <div className="bq-card-timer">
                <Clock size={12} />
                <span>{hoursLeft}h {minutesLeft}min</span>
              </div>
            </div>
            <div className="bq-card-foot">
              <h2 className="bq-card-title">Boutique du jour</h2>
              <p className="bq-card-desc">
                {dailyPreview.length > 0
                  ? `${dailyPreview.length} offres en rotation, prix réduits`
                  : 'Offres fraîches chaque jour à minuit'}
              </p>
              {dailyPreview.length > 0 && (
                <div className="bq-card-thumbs">
                  {dailyPreview.map((it, i) => (
                    <div key={i} className="bq-card-thumb">
                      {it.image ? <img src={it.image} alt="" /> : <Package size={18} />}
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>
        </button>

        {/* Featured: Night Market si actif, sinon Battle Pass */}
        {nightMarketActive ? (
          <button
            className="bq-card bq-card-featured bq-card-nm"
            onClick={() => onNavigate('nightmarket')}
          >
            <img src={`${CAT_IMG}/armes.webp`} alt="" className="bq-card-img" />
            <div className="bq-card-shade bq-card-shade-red" />
            <div className="bq-card-body">
              <div className="bq-card-head">
                <span className="bq-card-live">
                  <span className="bq-card-live-dot" />
                  LIVE
                </span>
                <div className="bq-card-timer bq-card-timer-red">
                  <Flame size={12} />
                  <span>{formatSeconds(nightMarketTimeLeft)}</span>
                </div>
              </div>
              <div className="bq-card-foot">
                <h2 className="bq-card-title">Night Market</h2>
                <p className="bq-card-desc">Événement limité. Cartes à révéler.</p>
              </div>
            </div>
          </button>
        ) : (
          <button
            className="bq-card bq-card-featured bq-card-bp"
            onClick={() => onNavigate('battlepass')}
          >
            <img src={`${CAT_IMG}/battlepass.webp`} alt="" className="bq-card-img" />
            <div className="bq-card-shade" />
            <div className="bq-card-body">
              <div className="bq-card-head">
                <span className="bq-card-eyebrow">Saison en cours</span>
              </div>
              <div className="bq-card-foot">
                <div className="bq-card-title-row">
                  <h2 className="bq-card-title">Passe de Combat</h2>
                </div>
                <p className="bq-card-desc">Gagne de l'XP, débloque des récompenses.</p>
              </div>
            </div>
          </button>
        )}

        {/* Véhicules — large */}
        <button className="bq-card bq-card-vehicles" onClick={() => onNavigate('vehicles')}>
          <img src={`${CAT_IMG}/vehicules.webp`} alt="" className="bq-card-img" />
          <div className="bq-card-shade" />
          <div className="bq-card-body">
            <div className="bq-card-foot">
              <div className="bq-card-title-row">
                <h2 className="bq-card-title">Véhicules</h2>
              </div>
              <p className="bq-card-desc">Flotte exclusive, performances garanties.</p>
            </div>
          </div>
          <ChevronRight className="bq-card-arrow" size={18} />
        </button>

        {/* Armes — moitié gauche */}
        <button className="bq-card bq-card-weapons" onClick={() => onNavigate('weapons')}>
          <img src={`${CAT_IMG}/armes.webp`} alt="" className="bq-card-img" />
          <div className="bq-card-shade" />
          <div className="bq-card-body">
            <div className="bq-card-foot">
              <div className="bq-card-title-row">
                <h2 className="bq-card-title-sm">Armes</h2>
              </div>
              <p className="bq-card-desc-sm">Arsenal complet</p>
            </div>
          </div>
        </button>

        {/* Personnalisation — moitié droite de la ligne armes */}
        <button className="bq-card bq-card-custom-split" onClick={() => onNavigate('customization')}>
          <img src={`${CAT_IMG}/custom.webp`} alt="" className="bq-card-img" />
          <div className="bq-card-shade" />
          <div className="bq-card-body">
            <div className="bq-card-foot">
              <div className="bq-card-title-row">
                <h2 className="bq-card-title-sm">Personnalisation</h2>
              </div>
              <p className="bq-card-desc-sm">Accessoires &amp; skins</p>
            </div>
          </div>
        </button>

        {/* Battle Pass (si NM actif — compact) */}
        {nightMarketActive && (
          <button className="bq-card bq-card-compact" onClick={() => onNavigate('battlepass')}>
            <img src={`${CAT_IMG}/battlepass.webp`} alt="" className="bq-card-img" />
            <div className="bq-card-shade" />
            <div className="bq-card-body">
              <div className="bq-card-foot">
                <div className="bq-card-title-row">
                  <h2 className="bq-card-title-sm">Passe de Combat</h2>
                </div>
                <p className="bq-card-desc-sm">Saison active</p>
              </div>
            </div>
          </button>
        )}

        {/* VIP */}
        <button className="bq-card bq-card-compact" onClick={() => onNavigate('vip')}>
          <img src={`${CAT_IMG}/vip.webp`} alt="" className="bq-card-img" />
          <div className="bq-card-shade" />
          <div className="bq-card-body">
            <div className="bq-card-foot">
              <div className="bq-card-title-row">
                <h2 className="bq-card-title-sm">VIP</h2>
              </div>
              <p className="bq-card-desc-sm">Privilèges exclusifs</p>
            </div>
          </div>
        </button>

        {/* Packs */}
        <button className="bq-card bq-card-compact" onClick={() => onNavigate('packs')}>
          <img src={`${CAT_IMG}/packs.webp`} alt="" className="bq-card-img" />
          <div className="bq-card-shade" />
          <div className="bq-card-body">
            <div className="bq-card-foot">
              <div className="bq-card-title-row">
                <h2 className="bq-card-title-sm">Packs</h2>
              </div>
              <p className="bq-card-desc-sm">Bundles avantageux</p>
            </div>
          </div>
        </button>
      </div>
    </div>
  );
};

export default BoutiqueHome;
