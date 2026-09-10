import React, { useState, useEffect, useCallback } from 'react';
import { IDCardProps, IDCardData } from './types';
import './IDCard.css';

const GetParentResourceName = () => 'null-core';

const LICENSE_LABELS: Record<string, string> = {
  drive: 'Voiture',
  drive_bike: 'Moto',
  drive_truck: 'Camion',
  weapon: 'Arme legere',
  weapon2: 'Arme lourde',
};

const CARD_TITLES: Record<string, string> = {
  identity_card: "CARTE D'IDENTITE",
  drive: 'PERMIS DE CONDUIRE',
  weapon: "PORT D'ARME",
};

const CARD_SUBTITLES: Record<string, string> = {
  identity_card: 'ETAT DE SAN ANDREAS',
  drive: 'ETAT DE SAN ANDREAS',
  weapon: 'ETAT DE SAN ANDREAS',
};

function formatDate(timestamp: number): string {
  if (!timestamp || timestamp <= 0) return '—';
  const d = new Date(timestamp * 1000);
  const day = String(d.getDate()).padStart(2, '0');
  const month = String(d.getMonth() + 1).padStart(2, '0');
  const year = d.getFullYear();
  return `${day}/${month}/${year}`;
}

const IDCard: React.FC<IDCardProps> = ({ visible, onClose }) => {
  const [cardData, setCardData] = useState<IDCardData | null>(null);
  const [hiding, setHiding] = useState(false);

  useEffect(() => {
    const handleMessage = (event: MessageEvent) => {
      const { action, data } = event.data;
      switch (action) {
        case 'idcard:show':
          if (data) {
            setCardData(data);
            setHiding(false);
          }
          break;
        case 'idcard:hide':
          handleClose();
          break;
      }
    };
    window.addEventListener('message', handleMessage);
    return () => window.removeEventListener('message', handleMessage);
  }, []);

  const handleClose = useCallback(() => {
    setHiding(true);
    setTimeout(() => {
      setHiding(false);
      setCardData(null);
      onClose();
      fetch(`https://${GetParentResourceName()}/idcard:close`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({}),
      });
    }, 400);
  }, [onClose]);

  if (!visible || !cardData) return null;

  const title = CARD_TITLES[cardData.type] || "CARTE D'IDENTITE";
  const subtitle = CARD_SUBTITLES[cardData.type] || 'ETAT DE SAN ANDREAS';
  const issuedDate = formatDate(cardData.creation);
  const fullName = `${cardData.lastname} ${cardData.firstname}`;

  const licenseEntries = Object.keys(cardData.licenses || {})
    .filter((k) => cardData.licenses[k] && LICENSE_LABELS[k])
    .map((k) => LICENSE_LABELS[k]);

  return (
    <div
      className={`idcard-overlay ${hiding ? 'idcard-hiding' : ''}`}
      // onClick={handleClose}
    >
      <div
        className={`idcard-card idcard-type-${cardData.type}`}
        onClick={(e) => e.stopPropagation()}
      >
        {/* Top band */}
        <div className="idcard-top-band">
          {/* <div className="idcard-flag">
            <div className="idcard-flag-stripe idcard-flag-green" />
            <div className="idcard-flag-stripe idcard-flag-white" />
            <div className="idcard-flag-stripe idcard-flag-orange" />
          </div> */}
          <div className="idcard-top-text">
            <span className="idcard-subtitle">{subtitle}</span>
            <span className="idcard-title">{title}</span>
          </div>
          <div className="idcard-emblem">
            <svg viewBox="0 0 24 24" fill="none" width="28" height="28">
              <path
                d="M12 2L3 7v5c0 5.55 3.84 10.74 9 12 5.16-1.26 9-6.45 9-12V7l-9-5z"
                fill="currentColor"
                opacity="0.15"
              />
              <path
                d="M12 2L3 7v5c0 5.55 3.84 10.74 9 12 5.16-1.26 9-6.45 9-12V7l-9-5z"
                stroke="currentColor"
                strokeWidth="1.5"
                fill="none"
              />
              <path
                d="M9 12l2 2 4-4"
                stroke="currentColor"
                strokeWidth="1.5"
                strokeLinecap="round"
                strokeLinejoin="round"
              />
            </svg>
          </div>
        </div>

        {/* Card body */}
        <div className="idcard-body">
          {/* Photo area */}
          <div className="idcard-photo">
            <svg viewBox="0 0 80 100" width="80" height="100">
              <rect
                width="80"
                height="100"
                rx="4"
                fill="var(--bg-secondary)"
              />
              <circle cx="40" cy="36" r="16" fill="var(--border-strong)" />
              <ellipse
                cx="40"
                cy="78"
                rx="24"
                ry="18"
                fill="var(--bg-tertiary)"
              />
            </svg>
          </div>

          {/* Info fields */}
          <div className="idcard-fields">
            <div className="idcard-field">
              <span className="idcard-field-label">Nom</span>
              <span className="idcard-field-value idcard-field-name">
                {cardData.lastname.toUpperCase()}
              </span>
            </div>
            <div className="idcard-field">
              <span className="idcard-field-label">Prenom</span>
              <span className="idcard-field-value">
                {cardData.firstname}
              </span>
            </div>
            <div className="idcard-field-row">
              <div className="idcard-field">
                <span className="idcard-field-label">Date de naissance</span>
                <span className="idcard-field-value">{cardData.birthday}</span>
              </div>
              <div className="idcard-field">
                <span className="idcard-field-label">Sexe</span>
                <span className="idcard-field-value">{cardData.sex}</span>
              </div>
            </div>
            <div className="idcard-field-row">
              <div className="idcard-field">
                <span className="idcard-field-label">Nationalite</span>
                <span className="idcard-field-value">
                  {cardData.nationality}
                </span>
              </div>
              <div className="idcard-field">
                <span className="idcard-field-label">Delivre le</span>
                <span className="idcard-field-value">{issuedDate}</span>
              </div>
            </div>

            {cardData.type !== 'identity_card' && licenseEntries.length > 0 && (
              <div className="idcard-field idcard-field-categories">
                <span className="idcard-field-label">Categories</span>
                <div className="idcard-categories">
                  {licenseEntries.map((label) => (
                    <span key={label} className="idcard-category-badge">
                      {label}
                    </span>
                  ))}
                </div>
              </div>
            )}
          </div>
        </div>

        {/* Bottom MRZ band */}
        <div className="idcard-mrz">
          <span>
            IDSAN{'<'}
            {cardData.lastname.toUpperCase().replace(/\s/g, '<')}
            {'<<'}
            {cardData.firstname.toUpperCase().replace(/\s/g, '<')}
            {'<<<<<<<<<<<<'}
          </span>
          <span>
            {cardData.birthday.replace(/\//g, '')}
            {'<'}
            {cardData.sex === 'Male' || cardData.sex === 'Mâle' ? 'M' : 'F'}
            {'<<<<<<<<<<<<<<<<<<<<'}
          </span>
        </div>

        {/* Security watermark */}
        <div className="idcard-watermark">
          {fullName}
        </div>
      </div>
    </div>
  );
};

export default IDCard;
