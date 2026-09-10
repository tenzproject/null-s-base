import React, { useState } from 'react';
import {
  Bug, Landmark, ShoppingCart, Package, Car, Palette, User, Briefcase,
  Tablet, BookOpen, GraduationCap, Swords, X, ChevronRight, Sparkles,
} from 'lucide-react';
import './DebugMenu.css';

interface DebugMenuProps {
  visible: boolean;
  onClose: () => void;
}

interface ModuleButton {
  id: string;
  label: string;
  icon: React.ReactNode;
  color: string;
  action: () => void;
}

const DebugMenu: React.FC<DebugMenuProps> = ({ visible, onClose }) => {
  const [category, setCategory] = useState<'ui' | 'tablet' | 'all'>('all');

  const openModule = (moduleName: string, mockData?: any) => {
    window.postMessage({
      action: `${moduleName}:open`,
      data: mockData || generateMockData(moduleName),
    }, '*');
  };

  const generateMockData = (moduleName: string): any => {
    switch (moduleName) {
      case 'bank':
        return {
          iban: 'FR76 1234 5678 9012 3456',
          cardNumber: '4532 1234 5678 9012',
          playerName: 'John Doe',
          cash: 5420,
          bank: 125340,
          history: [
            {
              id: '1',
              amount: 5000,
              title: 'Salaire',
              description: 'Paiement mensuel',
              category: 'salary',
              date: '13.03.2026 - 10:00:00',
              timestamp: Date.now() - 3600000,
            },
            {
              id: '2',
              amount: -150,
              title: 'Achat',
              description: 'Superette',
              category: 'purchase',
              date: '13.03.2026 - 09:30:00',
              timestamp: Date.now() - 5400000,
            },
            {
              id: '3',
              amount: -2000,
              title: 'Retrait',
              description: 'Retrait en espèces',
              category: 'withdraw',
              date: '12.03.2026 - 18:00:00',
              timestamp: Date.now() - 86400000,
            },
          ],
          credits: [
            {
              id: 'loan1',
              originalAmount: 50000,
              interest: 2500,
              totalDue: 52500,
              installments: 12,
              perInstallment: 4375,
              paid: 17500,
              paidInstallments: 4,
              paidOff: false,
              createdAt: Date.now() - 7776000000,
              createdDate: '13.12.2025 - 14:00:00',
            },
          ],
          pendingTransfers: [
            {
              id: 'pt1',
              amount: 1000,
              description: 'Cadeau',
              fromIban: 'FR12 9876 5432 1098 7654',
              date: '13.03.2026 - 09:00:00',
              timestamp: Date.now() - 7200000,
            },
          ],
          creditConfig: {
            maxAmount: 500000,
            minAmount: 1000,
            interestRate: 0.05,
            installments: [4, 8, 12],
            maxActiveLoans: 1,
          },
          categories: {
            deposit: { label: 'Dépôt', icon: 'deposit' },
            withdraw: { label: 'Retrait', icon: 'withdraw' },
            transfer: { label: 'Virement', icon: 'transfer' },
            purchase: { label: 'Achat', icon: 'purchase' },
            salary: { label: 'Salaire', icon: 'salary' },
            fine: { label: 'Amende', icon: 'fine' },
            loan: { label: 'Crédit', icon: 'loan' },
            repayment: { label: 'Remboursement', icon: 'repayment' },
            other: { label: 'Autre', icon: 'other' },
          },
        };

      case 'garage':
        return {
          mode: 'garage',
          garageType: 'car',
          garageId: '1',
          garageName: 'Parking Central',
          vehicles: [
            {
              plate: 'ABC 123',
              model: 'adder',
              modelLabel: 'Truffade Adder',
              type: 'car',
              ownerCategory: 'personal',
              state: true,
              boutique: true,
              spawned: false,
              distance: 0,
              vehicle: { plate: 'ABC 123', owner: 'char1:123' },
            },
            {
              plate: 'XYZ 789',
              model: 't20',
              modelLabel: 'Progen T20',
              type: 'car',
              ownerCategory: 'personal',
              state: true,
              boutique: false,
              spawned: false,
              distance: 0,
              vehicle: { plate: 'XYZ 789', owner: 'char1:123' },
            },
          ],
          hasJob: true,
          hasOrg: false,
          jobLabel: 'Police',
          orgLabel: '',
          impoundPrice: 0,
          repairPrice: 0,
        };

      case 'shop':
        return {
          mode: 'clothes',
          sex: 'm',
          skins: {},
          categories: [
            { id: 'tshirt_1', label: 'T-Shirt', items: Array.from({ length: 20 }, (_, i) => ({ item: i, price: 50 })) },
            { id: 'torso_1', label: 'Torse', items: Array.from({ length: 30 }, (_, i) => ({ item: i, price: 100 })) },
            { id: 'arms', label: 'Bras', items: Array.from({ length: 15 }, (_, i) => ({ item: i, price: 25 })) },
          ],
        };

      case 'newInventory':
        return {
          leftInventory: [
            { name: 'bread', label: 'Pain', count: 5, weight: 0.5, canUse: true },
            { name: 'water', label: 'Eau', count: 3, weight: 0.3, canUse: true },
            { name: 'phone', label: 'Téléphone', count: 1, weight: 0.2, canUse: true },
          ],
          leftWeight: 3.1,
          maxLeftWeight: 50,
          leftTitle: 'Inventaire',
        };

      case 'boutique':
        return {
          playerMoney: 15000,
          playerCoins: 250,
          dailyShop: [
            { id: 1, name: 'Adder', type: 'vehicle', price: 5000, image: 'adder.webp' },
            { id: 2, name: 'AK-47', type: 'weapon', price: 2000, image: null },
          ],
        };

      case 'illegalTablet':
        return {
          gangName: 'Les Ballas',
          gangcolor: '#9c27b0',
          level: 15,
          xp: 7500,
          xpToNext: 10000,
          members: 8,
          maxMembers: 10,
        };

      case 'newCreator':
        return {
          gender: 'm',
          maxValues: {
            face: { father: 45, mother: 45 },
            skin: { tone: 11 },
            hair: { style: 73, color: 63, highlight: 63 },
          },
          outfits: [
            { key: 'casual', label: 'Décontracté' },
            { key: 'sport', label: 'Sport' },
          ],
        };

      case 'driveSchool':
        return {
          licenses: [
            { type: 'drive', label: 'Permis B', owned: false, price: 5000 },
            { type: 'truck', label: 'Permis C', owned: false, price: 10000 },
          ],
        };

      default:
        return {};
    }
  };

  const uiModules: ModuleButton[] = [
    {
      id: 'bank',
      label: 'Banque',
      icon: <Landmark size={18} />,
      color: '#3b82f6',
      action: () => openModule('bank'),
    },
    {
      id: 'garage',
      label: 'Garage',
      icon: <Car size={18} />,
      color: '#8b5cf6',
      action: () => openModule('garage'),
    },
    {
      id: 'shop',
      label: 'Magasin',
      icon: <ShoppingCart size={18} />,
      color: '#ec4899',
      action: () => openModule('shop'),
    },
    {
      id: 'inventory',
      label: 'Inventaire',
      icon: <Package size={18} />,
      color: '#f59e0b',
      action: () => openModule('newInventory'),
    },
    {
      id: 'creator',
      label: 'Créateur',
      icon: <User size={18} />,
      color: '#10b981',
      action: () => openModule('newCreator'),
    },
    {
      id: 'driveschool',
      label: 'Auto-école',
      icon: <GraduationCap size={18} />,
      color: '#06b6d4',
      action: () => openModule('driveSchool'),
    },
  ];

  const tabletModules: ModuleButton[] = [
    {
      id: 'boutique',
      label: 'Boutique',
      icon: <Sparkles size={18} />,
      color: '#f59e0b',
      action: () => openModule('boutique'),
    },
    {
      id: 'illegal',
      label: 'Tablette Illégale',
      icon: <Swords size={18} />,
      color: '#ef4444',
      action: () => openModule('illegalTablet'),
    },
    {
      id: 'rules',
      label: 'Règlement',
      icon: <BookOpen size={18} />,
      color: '#6366f1',
      action: () => openModule('reglement'),
    },
  ];

  const allModules = [...uiModules, ...tabletModules];
  const displayedModules = category === 'all' ? allModules : category === 'ui' ? uiModules : tabletModules;

  if (!visible) return null;

  return (
    <div className="debug-menu-overlay">
      <div className="debug-menu">
        <div className="debug-menu-header">
          <div className="debug-menu-title">
            <Bug size={20} />
            <span>Debug Menu</span>
          </div>
          <button className="debug-menu-close" onClick={onClose}>
            <X size={18} />
          </button>
        </div>

        <div className="debug-menu-tabs">
          <button
            className={`debug-menu-tab ${category === 'all' ? 'active' : ''}`}
            onClick={() => setCategory('all')}
          >
            Tout
          </button>
          <button
            className={`debug-menu-tab ${category === 'ui' ? 'active' : ''}`}
            onClick={() => setCategory('ui')}
          >
            UI Modules
          </button>
          <button
            className={`debug-menu-tab ${category === 'tablet' ? 'active' : ''}`}
            onClick={() => setCategory('tablet')}
          >
            Tablettes
          </button>
        </div>

        <div className="debug-menu-grid">
          {displayedModules.map((mod) => (
            <button
              key={mod.id}
              className="debug-module-btn"
              onClick={mod.action}
              style={{
                borderColor: mod.color + '40',
                background: `linear-gradient(135deg, ${mod.color}15, ${mod.color}08)`,
              }}
            >
              <div className="debug-module-icon" style={{ color: mod.color }}>
                {mod.icon}
              </div>
              <div className="debug-module-label">{mod.label}</div>
              <ChevronRight size={14} className="debug-module-arrow" style={{ color: mod.color }} />
            </button>
          ))}
        </div>

        <div className="debug-menu-footer">
          <kbd>F8</kbd> pour fermer • Mode développement
        </div>
      </div>
    </div>
  );
};

export default DebugMenu;
