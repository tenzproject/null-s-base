import React from 'react';

const Res = () => 'null-core';
const post = (event: string, body: any = {}) =>
  fetch(`https://${Res()}/${event}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  }).catch(() => null);

interface ActionsViewProps {
  isBoss?: boolean;
}

interface ActionDef {
  id: string;
  label: string;
  description: string;
  callback: string;
}

const ActionsView: React.FC<ActionsViewProps> = ({ isBoss }) => {
  const actions: ActionDef[] = [
    {
      id: 'fouiller',
      label: 'Fouiller',
      description: 'Fouille le joueur le plus proche (mains levées).',
      callback: 'illegalDevice:actions:fouiller',
    },
    ...(isBoss ? [{
      id: 'facture',
      label: 'Facturer',
      description: 'Envoie une facture au joueur le plus proche.',
      callback: 'illegalDevice:actions:facture',
    }] : []),
    {
      id: 'putInVehicle',
      label: 'Embarquer',
      description: 'Mets le joueur le plus proche dans ton véhicule (mains levées).',
      callback: 'illegalDevice:actions:putInVehicle',
    },
    {
      id: 'outVehicle',
      label: 'Sortir du véhicule',
      description: 'Fais descendre le joueur le plus proche.',
      callback: 'illegalDevice:actions:outVehicle',
    },
  ];

  return (
    <div className="idev-crew-section idev-actions">
      <div className="idev-actions-intro">
        <h3>Actions rapides</h3>
        <p>Cible le joueur le plus proche. La tablette se ferme automatiquement.</p>
      </div>

      <div className="idev-actions-list">
        {actions.map(a => (
          <button
            key={a.id}
            className="idev-actions-item"
            onClick={() => post(a.callback)}
          >
            <div className="idev-actions-item-body">
              <span className="idev-actions-item-label">{a.label}</span>
              <span className="idev-actions-item-desc">{a.description}</span>
            </div>
            <span className="idev-actions-item-arrow">›</span>
          </button>
        ))}
      </div>
    </div>
  );
};

export default ActionsView;
