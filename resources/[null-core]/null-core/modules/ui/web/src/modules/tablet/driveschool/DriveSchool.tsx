import React, { useState, useEffect, useCallback, useMemo } from 'react';
import { cacheImg } from '@/shared/cacheVersion';
import { generateAccentVars } from '@/utils/accentColors';
import {
  GraduationCap, X, Car, Bike, Truck, ChevronRight,
  BookOpen, Route, Check, XCircle, Home,
  Banknote, CreditCard, Lock, Award, ArrowLeft,
} from 'lucide-react';
import WaveBackground from '@/components/WaveBackground';
import './DriveSchool.css';

const GetParentResourceName = () => 'null-core';

const nuiCallback = async (event: string, data: Record<string, any> = {}) => {
  try {
    const resp = await fetch(`https://${GetParentResourceName()}/${event}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data),
    });
    return await resp.json();
  } catch (e) {
    return null;
  }
};

interface License {
  id: string;
  label: string;
  description: string;
  icon: string;
  pricing: { theory: number; practice: number };
  theory: boolean;
  practice: boolean;
}

interface Question {
  label: string;
  options: { label: string; correct: boolean }[];
}

interface PracticeHUD {
  step: number;
  totalSteps: number;
  errors: number;
  maxErrors: number;
  speedLimit: number | null;
}

interface PracticeResult {
  passed: boolean;
  errors: number;
  maxErrors: number;
  licenseId: string;
}

type Page = 'licenses' | 'detail' | 'theory' | 'theoryResult' | 'practiceResult';

const ICON_MAP: Record<string, React.FC<any>> = {
  bike: Bike,
  car: Car,
  truck: Truck,
};

const VEHICLE_TYPE_MAP: Record<string, string> = {
  bike: 'Moto & Scooter',
  car: 'Voiture, SUV, Citadine',
  truck: 'Poids lourd, Camion',
};
const THEORY_DESC_MAP: Record<string, string> = {
  bike: 'Maîtrisez le code de la route pour les deux-roues motorisés.',
  car: 'Validez vos connaissances du code de la route pour la conduite automobile.',
  truck: 'Épreuve théorique spécialisée pour les conducteurs de véhicules lourds.',
};
const PRACTICE_DESC_MAP: Record<string, string> = {
  bike: "Effectuez le parcours imposé sur votre moto sans dépasser le nombre d'erreurs autorisé.",
  car: "Parcourez l'itinéraire balisé en voiture et validez chaque checkpoint avec rigueur.",
  truck: "Manœuvrez un poids lourd sur le parcours défini avec les contraintes spécifiques.",
};

interface DriveSchoolBrand {
  name: string;
  tagline?: string;
  logo?: string;
  accentColor?: string;
  bgColor?: string;
  bgIsLight?: boolean;
}

const DEFAULT_BRAND: DriveSchoolBrand = {
  name: 'Auto-École',
  tagline: 'Permis de conduire officiels',
  logo: 'shopui/brands/driving-school.png',
  accentColor: '#dc2626',
  bgColor: '#f5f5f7',
  bgIsLight: true,
};

interface DriveSchoolProps {
  visible: boolean;
  onClose: () => void;
  primaryColor: string;
}

const DriveSchool: React.FC<DriveSchoolProps> = ({ visible, onClose, primaryColor }) => {
  const [brand, setBrand] = useState<DriveSchoolBrand>(DEFAULT_BRAND);
  const accentColor = brand.accentColor || primaryColor || '#40e0f0';
  const brandBg = brand.bgColor || '#1a2348';
  const brandLogo = brand.logo ? cacheImg(brand.logo) : null;
  const dsAccentVars = useMemo(() => generateAccentVars('--ds-accent', accentColor), [accentColor]);
  const dsBrandVars = useMemo(() => ({
    '--ds-brand-bg': brandBg,
  } as React.CSSProperties), [brandBg]);
  const [mounted, setMounted] = useState(false);
  const [page, setPage] = useState<Page>('licenses');
  const [licenses, setLicenses] = useState<License[]>([]);
  const [questions, setQuestions] = useState<Question[]>([]);
  const [minScore, setMinScore] = useState(5);
  const [maxErrors, setMaxErrors] = useState(3);
  const [cash, setCash] = useState(0);
  const [bank, setBank] = useState(0);
  const [selectedLicense, setSelectedLicense] = useState<License | null>(null);

  // Theory state
  const [theoryQuestions, setTheoryQuestions] = useState<Question[]>([]);
  const [currentQuestionIndex, setCurrentQuestionIndex] = useState(0);
  const [selectedOption, setSelectedOption] = useState<number | null>(null);
  const [correctCount, setCorrectCount] = useState(0);
  const [theoryLicenseId, setTheoryLicenseId] = useState('');

  // Practice HUD state
  const [practiceHUD, setPracticeHUD] = useState<PracticeHUD | null>(null);

  // Practice result
  const [practiceResult, setPracticeResult] = useState<PracticeResult | null>(null);

  // Payment selection
  const [showPaymentModal, setShowPaymentModal] = useState(false);
  const [paymentAction, setPaymentAction] = useState<'theory' | 'practice' | null>(null);
  const [paymentAmount, setPaymentAmount] = useState(0);

  useEffect(() => {
    if (visible) setMounted(true);
    if (!visible) {
      const t = setTimeout(() => { setMounted(false); setPage('licenses'); setSelectedLicense(null); setPracticeHUD(null); }, 300);
      return () => clearTimeout(t);
    }
  }, [visible]);

  const handleMessage = useCallback((event: MessageEvent) => {
    const { action, data } = event.data;
    if (!action) return;

    switch (action) {
      case 'driveSchool:open':
        if (data?.licenses) setLicenses(data.licenses);
        if (data?.questions) setQuestions(data.questions);
        if (data?.minScore) setMinScore(data.minScore);
        if (data?.maxErrors) setMaxErrors(data.maxErrors);
        if (data?.cash !== undefined) setCash(data.cash);
        if (data?.bank !== undefined) setBank(data.bank);
        if (data?.brand) setBrand({ ...DEFAULT_BRAND, ...data.brand });
        setPage('licenses');
        setSelectedLicense(null);
        setPracticeHUD(null);
        setPracticeResult(null);
        break;

      case 'driveSchool:close':
        setPracticeHUD(null);
        break;

      case 'driveSchool:updateLicenses':
        console.log('[DriveSchool React DEBUG] Received updateLicenses message');
        if (data?.licenses) {
          console.log('[DriveSchool React DEBUG] License count:', data.licenses.length);
          data.licenses.forEach((lic: License) => {
            console.log(`  - ${lic.id}: theory=${lic.theory}, practice=${lic.practice}`);
          });
          
          setLicenses(data.licenses);
          console.log('[DriveSchool React DEBUG] Licenses state updated');
          
          // Update selected license if it exists
          if (selectedLicense) {
            console.log('[DriveSchool React DEBUG] Selected license:', selectedLicense.id);
            const updated = data.licenses.find((l: License) => l.id === selectedLicense.id);
            if (updated) {
              console.log('[DriveSchool React DEBUG] Found updated license:', updated.id, 'theory:', updated.theory, 'practice:', updated.practice);
              setSelectedLicense(updated);
              console.log('[DriveSchool React DEBUG] Selected license updated');
              
              // If we're on theory result page and theory is now complete, go back to detail
              if (page === 'theoryResult' && updated.theory) {
                console.log('[DriveSchool React DEBUG] Theory complete! Redirecting to detail page in 1.5s...');
                setTimeout(() => setPage('detail'), 1500);
              }
            } else {
              console.warn('[DriveSchool React DEBUG] Could not find updated license for:', selectedLicense.id);
            }
          } else {
            console.log('[DriveSchool React DEBUG] No selected license to update');
          }
        } else {
          console.warn('[DriveSchool React DEBUG] No licenses data in message');
        }
        break;

      case 'driveSchool:practiceUpdate':
        setPracticeHUD({
          step: data?.step || 0,
          totalSteps: data?.totalSteps || 0,
          errors: data?.errors || 0,
          maxErrors: data?.maxErrors || 3,
          speedLimit: data?.speedLimit || null,
        });
        break;

      case 'driveSchool:practiceResult':
        setPracticeHUD(null);
        setPracticeResult({
          passed: data?.passed || false,
          errors: data?.errors || 0,
          maxErrors: data?.maxErrors || 3,
          licenseId: data?.licenseId || '',
        });
        setPage('practiceResult');
        break;
    }
  }, [selectedLicense]);

  useEffect(() => {
    window.addEventListener('message', handleMessage);
    return () => window.removeEventListener('message', handleMessage);
  }, [handleMessage]);

  const handleClose = useCallback(() => {
    nuiCallback('driveSchool:close');
    onClose();
  }, [onClose]);

  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape' && visible && page === 'licenses') {
        handleClose();
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [visible, page, handleClose]);

  // --- Theory logic ---
  const startTheory = (license: License) => {
    const price = license.pricing.theory;
    if (cash < price && bank < price) {
      return; // not enough money
    }
    // Show payment modal
    setPaymentAmount(price);
    setPaymentAction('theory');
    setShowPaymentModal(true);
  };

  const confirmTheoryPayment = (method: 'cash' | 'bank') => {
    const price = paymentAmount;
    const account = method === 'cash' ? 'money' : 'bank';

    nuiCallback('driveSchool:removeMoney', { account, amount: price });
    if (method === 'cash') setCash(prev => prev - price);
    else setBank(prev => prev - price);

    setShowPaymentModal(false);

    // Shuffle and pick questions
    const shuffled = [...questions].sort(() => Math.random() - 0.5);
    setTheoryQuestions(shuffled);
    setCurrentQuestionIndex(0);
    setSelectedOption(null);
    setCorrectCount(0);
    setTheoryLicenseId(selectedLicense!.id + 'dmv');
    setPage('theory');
  };

  const handleTheoryNext = () => {
    if (selectedOption === null) return;

    const q = theoryQuestions[currentQuestionIndex];
    let newCorrect = correctCount;
    if (q.options[selectedOption]?.correct) {
      newCorrect = correctCount + 1;
      setCorrectCount(newCorrect);
    }

    if (currentQuestionIndex + 1 >= theoryQuestions.length) {
      // Theory done
      const passed = newCorrect >= minScore;
      if (passed) {
        nuiCallback('driveSchool:theoryComplete', { license: theoryLicenseId });
      }
      setPage('theoryResult');
    } else {
      setCurrentQuestionIndex(prev => prev + 1);
      setSelectedOption(null);
    }
  };

  // --- Practice logic ---
  const startPractice = (license: License) => {
    const price = license.pricing.practice;
    if (cash < price && bank < price) {
      return; // not enough money
    }
    // Show payment modal
    setPaymentAmount(price);
    setPaymentAction('practice');
    setShowPaymentModal(true);
  };

  const confirmPracticePayment = (method: 'cash' | 'bank') => {
    const price = paymentAmount;
    const account = method === 'cash' ? 'money' : 'bank';

    nuiCallback('driveSchool:removeMoney', { account, amount: price });
    if (method === 'cash') setCash(prev => prev - price);
    else setBank(prev => prev - price);

    setShowPaymentModal(false);

    nuiCallback('driveSchool:startPractice', { licenseId: selectedLicense!.id });
  };

  const handlePaymentSelect = (method: 'cash' | 'bank') => {
    if (paymentAction === 'theory') {
      confirmTheoryPayment(method);
    } else if (paymentAction === 'practice') {
      confirmPracticePayment(method);
    }
  };

  const canAfford = (price: number) => cash >= price || bank >= price;

  // --- Render ---
  const getIcon = (iconName: string) => ICON_MAP[iconName] || Car;

  const goToLicense = (lic: License) => {
    setSelectedLicense(lic);
    setPage('detail');
  };

  const renderWelcome = () => {
    const obtained = licenses.filter(l => l.theory && l.practice).length;
    return (
      <div className="ds-welcome">
        <div className="ds-welcome-hero">
          {brandLogo ? (
            <img
              className="ds-welcome-logo"
              src={brandLogo}
              alt={brand.name}
              onError={(e) => { (e.target as HTMLImageElement).style.display = 'none'; }}
            />
          ) : (
            <div className="ds-welcome-icon"><GraduationCap size={48} /></div>
          )}
          <div className="ds-welcome-hero-text">
            <h2>Bienvenue chez {brand.name}</h2>
            <p>
              Choisissez un permis ci-dessous ou dans la barre latérale pour démarrer
              votre parcours : test théorique puis examen pratique.
            </p>
          </div>
        </div>

        <div className="ds-welcome-stats">
          <div className="ds-welcome-stat">
            <div className="ds-welcome-stat-value">{licenses.length}</div>
            <div className="ds-welcome-stat-label">Permis disponibles</div>
          </div>
          <div className="ds-welcome-stat">
            <div className="ds-welcome-stat-value">{obtained}</div>
            <div className="ds-welcome-stat-label">Permis obtenus</div>
          </div>
          <div className="ds-welcome-stat">
            <div className="ds-welcome-stat-value">{minScore}/{questions.length || '—'}</div>
            <div className="ds-welcome-stat-label">Score min. théorie</div>
          </div>
          <div className="ds-welcome-stat">
            <div className="ds-welcome-stat-value">{maxErrors}</div>
            <div className="ds-welcome-stat-label">Erreurs max pratique</div>
          </div>
        </div>

        <div className="ds-welcome-process">
          <div className="ds-welcome-process-item">
            <div className="ds-welcome-process-icon"><BookOpen size={16} /></div>
            <div>
              <div className="ds-welcome-process-title">Théorie</div>
              <div className="ds-welcome-process-desc">QCM sur le code de la route</div>
            </div>
          </div>
          <div className="ds-welcome-process-arrow"><ChevronRight size={14} /></div>
          <div className="ds-welcome-process-item">
            <div className="ds-welcome-process-icon"><Route size={16} /></div>
            <div>
              <div className="ds-welcome-process-title">Pratique</div>
              <div className="ds-welcome-process-desc">Parcours en conditions réelles</div>
            </div>
          </div>
          <div className="ds-welcome-process-arrow"><ChevronRight size={14} /></div>
          <div className="ds-welcome-process-item">
            <div className="ds-welcome-process-icon"><Award size={16} /></div>
            <div>
              <div className="ds-welcome-process-title">Permis</div>
              <div className="ds-welcome-process-desc">Délivré immédiatement</div>
            </div>
          </div>
        </div>

        <div className="ds-welcome-section">
          <div className="ds-welcome-section-head">
            <div className="ds-welcome-section-title">Permis disponibles</div>
            <div className="ds-welcome-section-meta">{licenses.length} permis · {questions.length} questions</div>
          </div>
          <div className="ds-welcome-licenses">
            {licenses.map(lic => {
              const Icon = getIcon(lic.icon);
              const fullyDone = lic.theory && lic.practice;
              const inProgress = lic.theory && !lic.practice;
              return (
                <button
                  key={lic.id}
                  className={`ds-welcome-license ${fullyDone ? 'done' : ''} ${inProgress ? 'in-progress' : ''}`}
                  onClick={() => goToLicense(lic)}
                >
                  <div className="ds-welcome-license-icon"><Icon size={22} /></div>
                  <div className="ds-welcome-license-info">
                    <div className="ds-welcome-license-name">{lic.label}</div>
                    <div className="ds-welcome-license-desc">{lic.description}</div>
                  </div>
                  <div className="ds-welcome-license-state">
                    {fullyDone ? (
                      <span className="ds-welcome-license-badge done"><Award size={12} /> Obtenu</span>
                    ) : inProgress ? (
                      <span className="ds-welcome-license-badge progress">Pratique</span>
                    ) : (
                      <span className="ds-welcome-license-badge new">Nouveau</span>
                    )}
                    <ChevronRight size={16} />
                  </div>
                </button>
              );
            })}
          </div>
        </div>
      </div>
    );
  };

  const renderDetail = () => {
    if (!selectedLicense) return null;
    const theoryDone = selectedLicense.theory;
    const practiceDone = selectedLicense.practice;
    const fullyDone = theoryDone && practiceDone;

    const theoryStatus = theoryDone ? 'done' : 'active';
    const practiceStatus = practiceDone ? 'done' : theoryDone ? 'active' : 'locked';

    const vehicleType = VEHICLE_TYPE_MAP[selectedLicense.icon] || 'Véhicule motorisé';
    const totalCost = selectedLicense.pricing.theory + selectedLicense.pricing.practice;
    const theoryDuration = Math.max(10, questions.length);

    const stages: Array<{
      key: 'theory' | 'practice';
      icon: React.ReactNode;
      title: string;
      subtitle: string;
      description: string;
      status: 'done' | 'active' | 'locked';
      price: number;
      disabled: boolean;
      onClick: () => void;
      details: { label: string; value: string }[];
    }> = [
      {
        key: 'theory',
        icon: <BookOpen size={28} />,
        title: 'Test théorique',
        subtitle: 'Code de la route',
        description: THEORY_DESC_MAP[selectedLicense.icon] || 'Validez vos connaissances du code de la route.',
        status: theoryStatus,
        price: selectedLicense.pricing.theory,
        disabled: theoryDone || !canAfford(selectedLicense.pricing.theory),
        onClick: () => !theoryDone && startTheory(selectedLicense),
        details: [
          { label: 'Questions', value: `${questions.length}` },
          { label: 'Score requis', value: `${minScore} / ${questions.length}` },
          { label: 'Durée estimée', value: `~${theoryDuration} min` },
          { label: 'Tentatives', value: 'Illimitées' },
        ],
      },
      {
        key: 'practice',
        icon: <Route size={28} />,
        title: 'Test pratique',
        subtitle: 'Examen de conduite',
        description: PRACTICE_DESC_MAP[selectedLicense.icon] || "Effectuez le parcours imposé sans dépasser le nombre d'erreurs autorisé.",
        status: practiceStatus,
        price: selectedLicense.pricing.practice,
        disabled: !theoryDone || practiceDone || !canAfford(selectedLicense.pricing.practice),
        onClick: () => theoryDone && !practiceDone && startPractice(selectedLicense),
        details: [
          { label: 'Erreurs max', value: `${maxErrors}` },
          { label: 'Pré-requis', value: theoryDone ? '✓ Théorie' : "Théorie d'abord" },
          { label: 'Véhicule', value: vehicleType.split(',')[0].trim() },
          { label: 'Durée estimée', value: '~20 min' },
        ],
      },
    ];

    return (
      <div className="ds-detail">
        <div className="ds-detail-header">
          <div className="ds-detail-header-info">
            <h2>{selectedLicense.label}</h2>
            <p>{selectedLicense.description}</p>
          </div>
          {fullyDone && (
            <div className="ds-detail-trophy" title="Permis obtenu">
              <Award size={16} />
              <span>Obtenu</span>
            </div>
          )}
        </div>

        <div className="ds-license-overview">
          <div className="ds-license-overview-item">
            <span className="ds-license-overview-label">Véhicules autorisés</span>
            <span className="ds-license-overview-value">{vehicleType}</span>
          </div>
          <div className="ds-license-overview-divider" />
          <div className="ds-license-overview-item">
            <span className="ds-license-overview-label">Coût total</span>
            <span className="ds-license-overview-value">${totalCost.toLocaleString()}</span>
          </div>
          <div className="ds-license-overview-divider" />
          <div className="ds-license-overview-item">
            <span className="ds-license-overview-label">Examens requis</span>
            <span className="ds-license-overview-value">2 étapes</span>
          </div>
          <div className="ds-license-overview-divider" />
          <div className="ds-license-overview-item">
            <span className="ds-license-overview-label">Statut</span>
            <span className={`ds-license-status-badge ${fullyDone ? 'done' : theoryDone ? 'progress' : 'pending'}`}>
              {fullyDone ? 'Obtenu' : theoryDone ? 'En cours' : 'Non commencé'}
            </span>
          </div>
        </div>

        <div className="ds-detail-progress">
          <div className={`ds-step ${theoryDone ? 'done' : 'active'}`}>
            <div className="ds-step-dot">{theoryDone ? <Check size={12} /> : '1'}</div>
            <span>Théorie</span>
          </div>
          <div className={`ds-step-line ${theoryDone ? 'done' : ''}`} />
          <div className={`ds-step ${practiceDone ? 'done' : theoryDone ? 'active' : ''}`}>
            <div className="ds-step-dot">{practiceDone ? <Check size={12} /> : '2'}</div>
            <span>Pratique</span>
          </div>
        </div>

        <div className="ds-detail-cards">
          {stages.map(s => (
            <div
              key={s.key}
              className={`ds-stage-card ${s.key} ds-stage-${s.status}`}
            >
              <div className="ds-stage-card-head">
                <div className="ds-stage-card-icon">{s.icon}</div>
                <div className="ds-stage-card-status">
                  {s.status === 'done' && (
                    <span className="ds-stage-badge done"><Check size={12} /> Validé</span>
                  )}
                  {s.status === 'active' && (
                    <span className="ds-stage-badge active">Disponible</span>
                  )}
                  {s.status === 'locked' && (
                    <span className="ds-stage-badge locked"><Lock size={12} /> Verrouillé</span>
                  )}
                </div>
              </div>

              <div className="ds-stage-card-title">
                <h3>{s.title}</h3>
                <p>{s.subtitle}</p>
              </div>

              <p className="ds-stage-description">{s.description}</p>

              <div className="ds-stage-card-stats">
                {s.details.map((d, i) => (
                  <div key={i} className="ds-stage-stat">
                    <div className="ds-stage-stat-label">{d.label}</div>
                    <div className="ds-stage-stat-value">{d.value}</div>
                  </div>
                ))}
              </div>

              <div className="ds-stage-card-foot">
                <div className="ds-stage-price-block">
                  <div className="ds-stage-price-label">Prix</div>
                  <div className="ds-stage-price-value">${s.price.toLocaleString()}</div>
                </div>
                <button
                  className="ds-stage-card-cta"
                  disabled={s.disabled}
                  onClick={s.onClick}
                >
                  {s.status === 'done' ? 'Complété' : s.status === 'locked' ? 'Verrouillé' : 'Commencer'}
                  {s.status === 'active' && <ChevronRight size={16} />}
                </button>
              </div>
            </div>
          ))}
        </div>
      </div>
    );
  };

  const renderTheory = () => {
    if (theoryQuestions.length === 0) return null;
    const q = theoryQuestions[currentQuestionIndex];
    const progress = ((currentQuestionIndex) / theoryQuestions.length) * 100;

    return (
      <div className="ds-theory">
        <div className="ds-theory-head">
          <button className="ds-back-btn" onClick={() => setPage('detail')}>
            <ArrowLeft size={14} /> Abandonner
          </button>
          <div className="ds-theory-counter">
            Question <strong>{currentQuestionIndex + 1}</strong> / {theoryQuestions.length}
          </div>
          <div className="ds-theory-score">{correctCount} pts</div>
        </div>
        <div className="ds-theory-progress-bar">
          <div className="ds-theory-progress-fill" style={{ width: `${progress}%` }} />
        </div>
        <div className="ds-theory-question">{q.label}</div>
        <div className="ds-theory-options">
          {q.options.map((opt, i) => (
            <button
              key={i}
              className={`ds-theory-option ${selectedOption === i ? 'selected' : ''}`}
              onClick={() => setSelectedOption(i)}
            >
              <div className="ds-theory-radio">
                <div className="ds-theory-radio-inner" />
              </div>
              <span>{opt.label}</span>
            </button>
          ))}
        </div>
        <button
          className="ds-theory-validate"
          disabled={selectedOption === null}
          onClick={handleTheoryNext}
        >
          {currentQuestionIndex + 1 >= theoryQuestions.length ? 'Terminer' : 'Question suivante'}
          <ChevronRight size={16} />
        </button>
      </div>
    );
  };

  const renderTheoryResult = () => {
    const passed = correctCount >= minScore;
    return (
      <div className="ds-result">
        <div className={`ds-result-icon ${passed ? 'success' : 'fail'}`}>
          {passed ? <Check size={40} /> : <XCircle size={40} />}
        </div>
        <div className="ds-result-title">
          {passed ? 'Félicitations !' : 'Échec'}
        </div>
        <div className="ds-result-score">{correctCount}/{theoryQuestions.length}</div>
        <div className="ds-result-subtitle">
          {passed
            ? 'Vous avez réussi le test théorique ! Revenez pour passer le test pratique.'
            : `Vous n'avez pas obtenu le score minimum de ${minScore} points. Réessayez !`}
        </div>
        <button className="ds-result-btn" onClick={() => setPage('detail')}>
          Retour
        </button>
      </div>
    );
  };

  const renderPracticeResult = () => {
    if (!practiceResult) return null;
    return (
      <div className="ds-result">
        <div className={`ds-result-icon ${practiceResult.passed ? 'success' : 'fail'}`}>
          {practiceResult.passed ? <Check size={40} /> : <XCircle size={40} />}
        </div>
        <div className="ds-result-title">
          {practiceResult.passed ? 'Permis obtenu !' : 'Échec du test pratique'}
        </div>
        <div className="ds-result-score">{practiceResult.errors} erreur{practiceResult.errors !== 1 ? 's' : ''}</div>
        <div className="ds-result-subtitle">
          {practiceResult.passed
            ? 'Félicitations, vous avez réussi le test pratique ! Vous êtes maintenant titulaire de votre permis.'
            : `Vous avez fait trop d'erreurs (max: ${practiceResult.maxErrors}). Ne vous découragez pas, réessayez !`}
        </div>
        <button className="ds-result-btn" onClick={() => { setPage('detail'); setPracticeResult(null); }}>
          Retour
        </button>
      </div>
    );
  };

  const renderPaymentModal = () => {
    if (!showPaymentModal) return null;
    
    const canPayCash = cash >= paymentAmount;
    const canPayBank = bank >= paymentAmount;
    
    return (
      <div className="ds-payment-overlay" onClick={() => setShowPaymentModal(false)}>
        <div className="ds-payment-modal" onClick={(e) => e.stopPropagation()}>
          <div className="ds-payment-header">
            <h3>Choisissez votre mode de paiement</h3>
            <p className="ds-payment-amount">${paymentAmount.toLocaleString()}</p>
          </div>
          <div className="ds-payment-options">
            <button
              className="ds-payment-btn ds-payment-cash"
              disabled={!canPayCash}
              onClick={() => canPayCash && handlePaymentSelect('cash')}
            >
              <Banknote size={24} />
              <div className="ds-payment-btn-info">
                <span className="ds-payment-btn-label">Espèces</span>
                <span className="ds-payment-btn-balance">${cash.toLocaleString()}</span>
              </div>
            </button>
            <button
              className="ds-payment-btn ds-payment-bank"
              disabled={!canPayBank}
              onClick={() => canPayBank && handlePaymentSelect('bank')}
            >
              <CreditCard size={24} />
              <div className="ds-payment-btn-info">
                <span className="ds-payment-btn-label">Carte bancaire</span>
                <span className="ds-payment-btn-balance">${bank.toLocaleString()}</span>
              </div>
            </button>
          </div>
          <button className="ds-payment-cancel" onClick={() => setShowPaymentModal(false)}>
            Annuler
          </button>
        </div>
      </div>
    );
  };

  if (!mounted && !visible) return null;

  return (
    <>
      {/* Payment modal */}
      {renderPaymentModal()}

      {/* Practice HUD overlay - shown during driving test even when main UI is closed */}
      {practiceHUD && (
        <>
          <div className="ds-practice-hud" style={dsAccentVars as React.CSSProperties}>
            <div className="ds-practice-hud-item">
              <span className="ds-practice-hud-label">Checkpoint</span>
              <span className="ds-practice-hud-value">{practiceHUD.step}/{practiceHUD.totalSteps}</span>
            </div>
            <div className="ds-practice-hud-divider" />
            <div className="ds-practice-hud-item">
              <span className="ds-practice-hud-label">Erreurs</span>
              <span className={`ds-practice-hud-value ${practiceHUD.errors > 0 ? 'ds-practice-hud-errors' : ''}`}>
                {practiceHUD.errors}/{practiceHUD.maxErrors}
              </span>
            </div>
            {practiceHUD.speedLimit && (
              <>
                <div className="ds-practice-hud-divider" />
                <div className="ds-practice-hud-item">
                  <span className="ds-practice-hud-label">Limite</span>
                  <span className="ds-practice-hud-value">{practiceHUD.speedLimit} km/h</span>
                </div>
              </>
            )}
          </div>
          
          {/* Route visualization - shows checkpoint progress */}
          <div className="ds-route-overlay" style={dsAccentVars as React.CSSProperties}>
            {Array.from({ length: practiceHUD.totalSteps }, (_, i) => {
              const checkpointNum = i + 1;
              const isCompleted = checkpointNum < practiceHUD.step;
              const isActive = checkpointNum === practiceHUD.step;
              
              return (
                <div
                  key={i}
                  className={`ds-route-checkpoint ${isCompleted ? 'completed' : ''} ${isActive ? 'active' : ''}`}
                  title={`Checkpoint ${checkpointNum}`}
                />
              );
            })}
          </div>
        </>
      )}

      {/* Main UI overlay - completely hidden during practice test */}
      {!practiceHUD && (
        <div
          className={`ds-overlay ${visible ? 'visible' : ''}`}
          style={{ ...dsAccentVars, ...dsBrandVars } as React.CSSProperties}
        >
          <div className="ds-container">
            <WaveBackground accentColor={accentColor} opacity={0.5} />
            {/* Sidebar */}
            <aside className="ds-sidebar">
              <div
                className={`ds-brand-hero ${brand.bgIsLight ? 'is-light' : ''}`}
                style={{ background: brand.bgIsLight ? brandBg : `linear-gradient(160deg, ${brandBg} 0%, ${brandBg}dd 60%, rgba(0,0,0,0.45) 100%)` }}
              >
                <div className="ds-brand-shine" />
                <div className="ds-brand-inner">
                  {brandLogo ? (
                    <img
                      className="ds-brand-logo"
                      src={brandLogo}
                      alt={brand.name}
                      onError={(e) => { (e.target as HTMLImageElement).style.display = 'none'; }}
                    />
                  ) : (
                    <div className="ds-brand-logo-fallback"><GraduationCap size={36} /></div>
                  )}
                  <div className="ds-brand-text">
                    <h1>{brand.name}</h1>
                    {brand.tagline && <p>{brand.tagline}</p>}
                  </div>
                </div>
              </div>

              <div className="ds-money-section">
                <div className="ds-money-item">
                  <Banknote size={14} />
                  <span>${cash.toLocaleString()}</span>
                </div>
                <div className="ds-money-item">
                  <CreditCard size={14} />
                  <span>${bank.toLocaleString()}</span>
                </div>
              </div>

              <nav className="ds-sidebar-nav">
                <button
                  className={`ds-sidebar-item ${!selectedLicense ? 'active' : ''}`}
                  onClick={() => { setSelectedLicense(null); setPage('licenses'); }}
                >
                  {!selectedLicense && <div className="ds-sidebar-indicator" />}
                  <Home size={16} />
                  <span>Accueil</span>
                  <ChevronRight size={14} className="ds-sidebar-arrow" />
                </button>
                {licenses.map(lic => {
                  const Icon = getIcon(lic.icon);
                  const active = selectedLicense?.id === lic.id;
                  const fullyDone = lic.theory && lic.practice;
                  return (
                    <button
                      key={lic.id}
                      className={`ds-sidebar-item ${active ? 'active' : ''}`}
                      onClick={() => goToLicense(lic)}
                    >
                      {active && <div className="ds-sidebar-indicator" />}
                      <Icon size={16} />
                      <span>{lic.label}</span>
                      {fullyDone ? (
                        <Award size={14} className="ds-sidebar-trophy" />
                      ) : (
                        <ChevronRight size={14} className="ds-sidebar-arrow" />
                      )}
                    </button>
                  );
                })}
              </nav>

              <div className="ds-sidebar-footer">
                <button className="ds-close-btn" onClick={handleClose}>
                  <X size={16} />
                  <span>Fermer</span>
                </button>
              </div>
            </aside>

            {/* Main content */}
            <main className="ds-content">
              {!selectedLicense && page === 'licenses' && renderWelcome()}
              {selectedLicense && page === 'detail' && renderDetail()}
              {page === 'theory' && renderTheory()}
              {page === 'theoryResult' && renderTheoryResult()}
              {page === 'practiceResult' && renderPracticeResult()}
            </main>
          </div>
        </div>
      )}
    </>
  );
};

export default DriveSchool;
