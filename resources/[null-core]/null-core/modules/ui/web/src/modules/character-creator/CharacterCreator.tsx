import React, { useState, useEffect, useCallback, useRef, useMemo } from 'react';
import { generateAccentVars, hexToRgba } from '@/utils/accentColors';
import {
  User, Users, Scissors, ScanFace, Sparkles, Shirt,
  Camera, ChevronLeft, ChevronRight, RotateCcw, Check,
  X, Eye, Palette, MousePointer, Move
} from 'lucide-react';
import { cacheImg } from '@shared/cacheVersion';
import {
  CharacterCreatorProps, CreatorCategory, CreatorData, MaxValues,
  FATHER_NAMES, MOTHER_NAMES, HERITAGE_IMAGES,
  GTA_HAIR_COLORS, EYE_COLORS, FACE_SLIDERS, FaceSliderDef
} from './types';
import './CharacterCreator.css';

const GetParentResourceName = () => 'null-core';

const nuiCall = async (event: string, data: any = {}) => {
  try {
    const resp = await fetch(`https://${GetParentResourceName()}/${event}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data),
    });
    return await resp.json();
  } catch { return null; }
};

// Profanity and inappropriate name filter
const FORBIDDEN_WORDS = [
  'admin', 'modo', 'staff', 'god', 'dieu', 'jesus', 'allah', 'hitler',
  'fuck', 'shit', 'merde', 'connard', 'salope', 'pute', 'bite', 'chatte',
  'con', 'fdp', 'ntm', 'pd', 'enculé', 'enculer', 'nazi', 'terroriste',
  'test', 'azerty', 'qwerty', 'aaaa', 'bbbb', 'xxxx', 'zzzz',
  'nigger', 'nigga', 'retard', 'autist', 'cancer', 'sida', 'aids'
];

const containsForbiddenWord = (text: string): boolean => {
  const lower = text.toLowerCase().replace(/[^a-z0-9]/g, '');
  return FORBIDDEN_WORDS.some(word => lower.includes(word));
};

const isValidName = (name: string): boolean => {
  if (!name || name.trim().length === 0) return false;
  if (name.trim().length > 12) return false;
  if (!/^[a-zA-ZÀ-ÿ\s-]+$/.test(name)) return false;
  if (containsForbiddenWord(name)) return false;
  return true;
};

const calculateAge = (birthdate: string): number => {
  const birth = new Date(birthdate);
  const today = new Date();
  let age = today.getFullYear() - birth.getFullYear();
  const monthDiff = today.getMonth() - birth.getMonth();
  if (monthDiff < 0 || (monthDiff === 0 && today.getDate() < birth.getDate())) {
    age--;
  }
  return age;
};

const isValidBirthdate = (birthdate: string): boolean => {
  if (!birthdate) return false;
  const birth = new Date(birthdate);
  const minDate = new Date('1940-01-01');
  const today = new Date();
  if (birth < minDate || birth > today) return false;
  const age = calculateAge(birthdate);
  return age >= 16;
};

const CATEGORIES: { key: CreatorCategory; image: string; label: string; desc: string; icon: React.ReactNode }[] = [
  { key: 'identity', image: 'identity', label: 'Identité', desc: 'Sexe et état civil de votre personnage', icon: <User size={16} /> },
  { key: 'heritage', image: 'heritage', label: 'Héritage', desc: 'Choisissez vos parents et la ressemblance', icon: <Users size={16} /> },
  { key: 'hair', image: 'cheveux', label: 'Cheveux', desc: 'Coiffure, barbe, sourcils et couleurs', icon: <Scissors size={16} /> },
  { key: 'face', image: 'visage', label: 'Visage', desc: 'Ajustez les traits de votre visage', icon: <ScanFace size={16} /> },
  { key: 'appearance', image: 'appareance', label: 'Apparence', desc: 'Maquillage, pilosité et imperfections', icon: <Sparkles size={16} /> },
  { key: 'outfits', image: 'outfits', label: 'Tenues', desc: 'Sélectionnez une tenue de départ', icon: <Shirt size={16} /> },
];

const CAMERA_VIEWS = [
  { key: 'default', label: 'Corps' },
  { key: 'head', label: 'Tête' },
  { key: 'body', label: 'Torse' },
  { key: 'legs', label: 'Jambes' },
];

/* Catégories mises en avant (cards bento plus grandes) */
const FEATURED_CATEGORIES: CreatorCategory[] = ['identity', 'heritage'];
const STEP_ORDER: CreatorCategory[] = ['identity', 'heritage', 'hair', 'face', 'appearance', 'outfits'];

const CharacterCreator: React.FC<CharacterCreatorProps> = ({ visible, onClose, primaryColor, serverConfig }) => {
  const accent = primaryColor || '#BEEE11';
  const banner = serverConfig?.serverBackground || serverConfig?.serverIcon || '';
  const ccAccentVars = useMemo(() => generateAccentVars('--cc-accent', accent), [accent]);
  // Mêmes déclinaisons d'opacité que le ped-shop (--cc-brand-XX) pour
  // reproduire exactement le style des boutons/cards (CEF sans color-mix()).
  const ccBrandVars = useMemo(() => {
    const vars: Record<string, string> = { '--cc-brand-bg': accent };
    const isHex = accent.startsWith('#') && accent.length >= 7;
    const opacities = [10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60, 65, 70, 90];
    for (const o of opacities) {
      vars[`--cc-brand-${o}`] = isHex ? hexToRgba(accent, o) : accent;
    }
    return vars;
  }, [accent]);
  const [hiding, setHiding] = useState(false);
  const [mounted, setMounted] = useState(false);
  const [view, setView] = useState<'home' | 'category'>('home');
  const [activeCategory, setActiveCategory] = useState<CreatorCategory>('identity');
  const [activeCam, setActiveCam] = useState('default');

  // Identity
  const [firstName, setFirstName] = useState('');
  const [lastName, setLastName] = useState('');
  const [birthdate, setBirthdate] = useState('');
  const [gender, setGender] = useState<'m' | 'f'>('m');

  // Heritage
  const [selectedFather, setSelectedFather] = useState(0);
  const [selectedMother, setSelectedMother] = useState(0);
  const [faceMix, setFaceMix] = useState(50);
  const [skinMix, setSkinMix] = useState(50);

  // Hair
  const [hairStyle, setHairStyle] = useState(0);
  const [hairColor, setHairColor] = useState(0);
  const [hairHighlight, setHairHighlight] = useState(0);

  // Beard
  const [beardStyle, setBeardStyle] = useState(0);
  const [beardColor, setBeardColor] = useState(0);
  const [beardOpacity, setBeardOpacity] = useState(10);

  // Eyebrows
  const [eyebrowStyle, setEyebrowStyle] = useState(0);
  const [eyebrowColor, setEyebrowColor] = useState(0);
  const [eyebrowOpacity, setEyebrowOpacity] = useState(10);

  // Eyes
  const [eyeColor, setEyeColor] = useState(0);

  // Face
  const [faceValues, setFaceValues] = useState<Record<string, number>>(() => {
    const defaults: Record<string, number> = {};
    FACE_SLIDERS.forEach(s => { defaults[s.key] = s.defaultValue; });
    return defaults;
  });

  // Appearance
  const [lipstickStyle, setLipstickStyle] = useState(0);
  const [lipstickColor, setLipstickColor] = useState(0);
  const [lipstickOpacity, setLipstickOpacity] = useState(10);
  const [chestHairStyle, setChestHairStyle] = useState(0);
  const [chestHairColor, setChestHairColor] = useState(0);
  const [chestHairOpacity, setChestHairOpacity] = useState(10);
  const [blemishesStyle, setBlemishesStyle] = useState(0);
  const [blemishesOpacity, setBlemishesOpacity] = useState(10);

  // Outfits
  const [outfits, setOutfits] = useState<Record<string, any>>({});
  const [selectedOutfit, setSelectedOutfit] = useState<string | null>(null);

  // Max values from game
  const [maxValues, setMaxValues] = useState<MaxValues>({
    father: 44, mother: 45, hairstyle: 73, hairColor: 63,
    eyebrows: 33, beard: 28, eyeColor: 29, beardColor: 63,
    eyebrowColor: 63, lipstickStyle: 9, lipstickColor: 63,
    chestHair: 16, blemishes: 23
  });

  // Notification
  const [notification, setNotification] = useState<string | null>(null);
  const notifTimer = useRef<ReturnType<typeof setTimeout>>();

  // Rotation
  const isDraggingRef = useRef(false);
  const lastMouseXRef = useRef(0);
  const [rotationHintVisible, setRotationHintVisible] = useState(true);
  const hasRotatedRef = useRef(false);

  const showNotif = useCallback((msg: string) => {
    setNotification(msg);
    if (notifTimer.current) clearTimeout(notifTimer.current);
    notifTimer.current = setTimeout(() => setNotification(null), 3000);
  }, []);

  // Visibility
  useEffect(() => {
    if (visible && !hiding) {
      setMounted(true);
      setView('category');
      setActiveCategory('identity');
    } else if (!visible && !hiding) {
      setMounted(false);
    }
  }, [visible, hiding]);

  const handleClose = useCallback(() => {
    // Fermeture désactivée pour forcer la validation via "Valider le personnage".
    showNotif("Vous ne pouvez pas fermer le créateur. Validez votre personnage.");
  }, [onClose]);

  // Listen for NUI data messages
  useEffect(() => {
    const handler = (event: MessageEvent) => {
      const { action, data } = event.data || {};
      if (action === 'newCreator:setData') {
        if (data?.maxValues) setMaxValues(prev => ({ ...prev, ...data.maxValues }));
        if (data?.outfits) setOutfits(data.outfits);
        if (data?.gender) setGender(data.gender);
      }
    };
    window.addEventListener('message', handler);
    return () => window.removeEventListener('message', handler);
  }, []);

  // Category change → camera
  useEffect(() => {
    if (!visible) return;
    const camMap: Record<CreatorCategory, string> = {
      identity: 'default',
      heritage: 'head',
      hair: 'head',
      face: 'head',
      appearance: 'head',
      outfits: 'default',
    };
    const cam = camMap[activeCategory] || 'default';
    setActiveCam(cam);
    nuiCall('newCreator:cameraChange', { camera: cam });
  }, [activeCategory, visible]);

  // ---- Rotation via mouse drag on overlay ----
  const handleMouseDown = useCallback((e: React.MouseEvent) => {
    if ((e.target as HTMLElement).closest('.cc-container')) return;
    isDraggingRef.current = true;
    lastMouseXRef.current = e.clientX;
    if (!hasRotatedRef.current) {
      hasRotatedRef.current = true;
      setRotationHintVisible(false);
    }
  }, []);

  const handleMouseMove = useCallback((e: React.MouseEvent) => {
    if (!isDraggingRef.current) return;
    const delta = e.clientX - lastMouseXRef.current;
    lastMouseXRef.current = e.clientX;
    if (delta !== 0) nuiCall('newCreator:rotate', { delta: delta * 0.5 });
  }, []);

  const handleMouseUp = useCallback(() => {
    isDraggingRef.current = false;
  }, []);

  // ---- NUI Callbacks ----
  const changeGender = useCallback((g: 'm' | 'f') => {
    setGender(g);
    nuiCall('newCreator:charInfo', { sex: g === 'm' ? 0 : 1 });
  }, []);

  const changeFather = useCallback((idx: number) => {
    setSelectedFather(idx);
    nuiCall('newCreator:faceFather', idx);
  }, []);

  const changeMother = useCallback((idx: number) => {
    setSelectedMother(idx);
    nuiCall('newCreator:faceMother', idx);
  }, []);

  const changeFaceMix = useCallback((val: number) => {
    setFaceMix(val);
    nuiCall('newCreator:faceMix', val / 100);
  }, []);

  const changeSkinMix = useCallback((val: number) => {
    setSkinMix(val);
    nuiCall('newCreator:skinTone', val);
  }, []);

  const changeHairStyle = useCallback((val: number) => {
    setHairStyle(val);
    nuiCall('newCreator:hairstyle', val);
  }, []);

  const changeHairColor = useCallback((val: number) => {
    setHairColor(val);
    nuiCall('newCreator:hairColor', val);
  }, []);

  const changeHairHighlight = useCallback((val: number) => {
    setHairHighlight(val);
    nuiCall('newCreator:hairHighlight', val);
  }, []);

  const changeBeardStyle = useCallback((val: number) => {
    setBeardStyle(val);
    nuiCall('newCreator:beardStyle', val);
  }, []);

  const changeBeardColor = useCallback((val: number) => {
    setBeardColor(val);
    nuiCall('newCreator:beardColor', val);
  }, []);

  const changeBeardOpacity = useCallback((val: number) => {
    setBeardOpacity(val);
    nuiCall('newCreator:beardOpacity', val / 10);
  }, []);

  const changeEyebrowStyle = useCallback((val: number) => {
    setEyebrowStyle(val);
    nuiCall('newCreator:eyebrowStyle', val);
  }, []);

  const changeEyebrowColor = useCallback((val: number) => {
    setEyebrowColor(val);
    nuiCall('newCreator:eyebrowColor', val);
  }, []);

  const changeEyebrowOpacity = useCallback((val: number) => {
    setEyebrowOpacity(val);
    nuiCall('newCreator:eyebrowOpacity', val / 10);
  }, []);

  const changeEyeColor = useCallback((val: number) => {
    setEyeColor(val);
    nuiCall('newCreator:eyeColor', val);
  }, []);

  const changeFaceSlider = useCallback((key: string, val: number) => {
    setFaceValues(prev => ({ ...prev, [key]: val }));
    nuiCall('newCreator:' + key, val / 100);
  }, []);

  const changeLipstickStyle = useCallback((val: number) => {
    setLipstickStyle(val);
    nuiCall('newCreator:lipstickStyle', val);
  }, []);

  const changeLipstickColor = useCallback((val: number) => {
    setLipstickColor(val);
    nuiCall('newCreator:lipstickColor', val);
  }, []);

  const changeLipstickOpacity = useCallback((val: number) => {
    setLipstickOpacity(val);
    nuiCall('newCreator:lipstickOpacity', val / 10);
  }, []);

  const changeChestHairStyle = useCallback((val: number) => {
    setChestHairStyle(val);
    nuiCall('newCreator:chestHair', val);
  }, []);

  const changeChestHairColor = useCallback((val: number) => {
    setChestHairColor(val);
    nuiCall('newCreator:chestHairColor', val);
  }, []);

  const changeChestHairOpacity = useCallback((val: number) => {
    setChestHairOpacity(val);
    nuiCall('newCreator:chestHairOpacity', val / 10);
  }, []);

  const changeBlemishesStyle = useCallback((val: number) => {
    setBlemishesStyle(val);
    nuiCall('newCreator:blemishesStyle', val);
  }, []);

  const changeBlemishesOpacity = useCallback((val: number) => {
    setBlemishesOpacity(val);
    nuiCall('newCreator:blemishesOpacity', val / 10);
  }, []);

  const selectOutfit = useCallback((key: string) => {
    console.log('[React] Selecting outfit:', key, 'gender:', gender);
    setSelectedOutfit(key);
    nuiCall('newCreator:outfit', key).then(() => {
      console.log('[React] Outfit NUI call completed');
    }).catch((err: any) => {
      console.error('[React] Outfit NUI call failed:', err);
    });
  }, [gender]);

  const handleReset = useCallback(() => {
    nuiCall('newCreator:resetCreator', {});
    setSelectedFather(0); setSelectedMother(0);
    setFaceMix(50); setSkinMix(50);
    setHairStyle(0); setHairColor(0); setHairHighlight(0);
    setBeardStyle(0); setBeardColor(0); setBeardOpacity(10);
    setEyebrowStyle(0); setEyebrowColor(0); setEyebrowOpacity(10);
    setEyeColor(0); setSelectedOutfit(null);
    setLipstickStyle(0); setLipstickColor(0); setLipstickOpacity(10);
    setChestHairStyle(0); setChestHairColor(0); setChestHairOpacity(10);
    setBlemishesStyle(0); setBlemishesOpacity(10);
    setFaceValues(() => {
      const defaults: Record<string, number> = {};
      FACE_SLIDERS.forEach(s => { defaults[s.key] = s.defaultValue; });
      return defaults;
    });
    showNotif('Personnage réinitialisé');
  }, [showNotif]);

  const validateIdentity = useCallback(() => {
    const first = firstName.trim();
    const last = lastName.trim();
    const birth = birthdate.trim();

    if (!first || !last || !birth) {
      showNotif('Veuillez remplir tous les champs obligatoires');
      return null;
    }

    if (!isValidName(first)) {
      if (first.length > 12) {
        showNotif('Le prénom ne peut pas dépasser 12 caractères');
      } else if (containsForbiddenWord(first)) {
        showNotif('Le prénom contient des mots interdits');
      } else {
        showNotif('Le prénom contient des caractères invalides');
      }
      return null;
    }

    if (!isValidName(last)) {
      if (last.length > 12) {
        showNotif('Le nom ne peut pas dépasser 12 caractères');
      } else if (containsForbiddenWord(last)) {
        showNotif('Le nom contient des mots interdits');
      } else {
        showNotif('Le nom contient des caractères invalides');
      }
      return null;
    }

    if (!isValidBirthdate(birth)) {
      const age = calculateAge(birth);
      if (age < 16) {
        showNotif('Votre personnage doit avoir au moins 16 ans');
      } else {
        showNotif('Date de naissance invalide (1940 - aujourd\'hui)');
      }
      return null;
    }

    return { first, last, birth };
  }, [firstName, lastName, birthdate, showNotif]);

  const handleFinish = useCallback(() => {
    const identity = validateIdentity();
    if (!identity) return;

    nuiCall('newCreator:finishCreator', {
      firstname: identity.first,
      lastname: identity.last,
      birthdate: identity.birth,
    });
  }, [validateIdentity]);

  const handleCamChange = useCallback((cam: string) => {
    setActiveCam(cam);
    nuiCall('newCreator:cameraChange', { camera: cam });
  }, []);

  const currentStepIndex = STEP_ORDER.indexOf(activeCategory);
  const isFirstStep = currentStepIndex <= 0;
  const isLastStep = currentStepIndex === STEP_ORDER.length - 1;
  const stepNumber = Math.max(currentStepIndex, 0) + 1;

  const setStep = useCallback((key: CreatorCategory) => {
    setActiveCategory(key);
    setView('category');
  }, []);

  const goPreviousStep = useCallback(() => {
    if (isFirstStep) {
      showNotif('Vous êtes déjà à la première étape');
      return;
    }
    setStep(STEP_ORDER[currentStepIndex - 1]);
  }, [currentStepIndex, isFirstStep, setStep, showNotif]);

  const goNextStep = useCallback(() => {
    if (activeCategory === 'identity' && !validateIdentity()) return;
    if (isLastStep) {
      handleFinish();
      return;
    }
    setStep(STEP_ORDER[currentStepIndex + 1]);
  }, [activeCategory, currentStepIndex, handleFinish, isLastStep, setStep, validateIdentity]);

  // Escape : étape précédente, sinon notification
  useEffect(() => {
    if (!visible) return;
    const handleKey = (e: KeyboardEvent) => {
      if (e.key !== 'Escape') return;
      if (!isFirstStep) { goPreviousStep(); return; }
      showNotif('Vous ne pouvez pas fermer le créateur. Validez votre personnage.');
    };
    window.addEventListener('keydown', handleKey);
    return () => window.removeEventListener('keydown', handleKey);
  }, [visible, isFirstStep, goPreviousStep, showNotif]);

  // ---- Stepper component ----
  const Stepper = ({ value, max, onChange, label }: { value: number; max: number; onChange: (v: number) => void; label: string }) => (
    <div className="cc-slider-group">
      <div className="cc-slider-header">
        <span className="cc-slider-label">{label}</span>
        <span className="cc-slider-value">{value}/{max}</span>
      </div>
      <div className="cc-stepper">
        <button className="cc-stepper-btn" onClick={() => onChange(value <= 0 ? max : value - 1)}><ChevronLeft size={14} /></button>
        <div className="cc-stepper-display">{value}</div>
        <button className="cc-stepper-btn" onClick={() => onChange(value >= max ? 0 : value + 1)}><ChevronRight size={14} /></button>
      </div>
    </div>
  );

  // ---- Color Grid ----
  const ColorGrid = ({ colors, activeIndex, onSelect }: { colors: string[]; activeIndex: number; onSelect: (i: number) => void }) => (
    <div className={`cc-color-grid${colors.length === 30 ? ' cc-color-grid-compact' : ''}`}>
      {colors.map((color, i) => (
        <div
          key={i}
          className={`cc-color-item${activeIndex === i ? ' active' : ''}`}
          style={{ background: color }}
          onClick={() => onSelect(i)}
        />
      ))}
    </div>
  );

  // ---- Heritage image helper ----
  const getHeritageImg = (gender: 'Male' | 'Female', name: string): string => {
    const key = `${gender}-${name}`;
    const file = HERITAGE_IMAGES[key];
    return file ? cacheImg(`heritage/${file}`) : '';
  };

  if (!mounted && !hiding) return null;

  const overlayClass = [
    'cc-overlay',
    mounted && !hiding ? 'cc-visible' : '',
    mounted && !hiding ? 'cc-showing' : '',
    hiding ? 'cc-hiding' : '',
  ].filter(Boolean).join(' ');

  // ---- Render sections ----
  const renderIdentity = () => (
    <>
      <div className="cc-section">
        <div className="cc-section-title">Sexe</div>
        <div className="cc-gender-selector">
          <button className={`cc-gender-btn${gender === 'm' ? ' active' : ''}`} onClick={() => changeGender('m')}>
            <User size={18} /> Homme
          </button>
          <button className={`cc-gender-btn${gender === 'f' ? ' active' : ''}`} onClick={() => changeGender('f')}>
            <User size={18} /> Femme
          </button>
        </div>
      </div>
      <div className="cc-section">
        <div className="cc-section-title">Informations</div>
        <div className="cc-form-group">
          <span className="cc-form-label">Prénom</span>
          <input
            className="cc-form-input"
            type="text"
            placeholder="Entrez votre prénom..."
            value={firstName}
            onChange={e => setFirstName(e.target.value)}
            maxLength={12}
          />
        </div>
        <div className="cc-form-group">
          <span className="cc-form-label">Nom</span>
          <input
            className="cc-form-input"
            type="text"
            placeholder="Entrez votre nom..."
            value={lastName}
            onChange={e => setLastName(e.target.value)}
            maxLength={12}
          />
        </div>
        <div className="cc-form-group">
          <span className="cc-form-label">Date de naissance</span>
          <input
            className="cc-form-input"
            type="date"
            value={birthdate}
            onChange={e => setBirthdate(e.target.value)}
            min="1940-01-01"
            max={new Date().toISOString().split('T')[0]}
          />
        </div>
      </div>
    </>
  );

  const renderHeritage = () => (
    <>
      <div className="cc-section">
        <div className="cc-section-title">Père</div>
        <div className="cc-parent-grid">
          {FATHER_NAMES.map((name, i) => (
            <div
              key={i}
              className={`cc-parent-item${selectedFather === i ? ' active' : ''}`}
              onClick={() => changeFather(i)}
            >
              <img src={getHeritageImg('Male', name)} alt={name} onError={e => (e.currentTarget.style.display = 'none')} />
              <span className="cc-parent-name">{name}</span>
            </div>
          ))}
        </div>
      </div>
      <div className="cc-section">
        <div className="cc-section-title">Mère</div>
        <div className="cc-parent-grid">
          {MOTHER_NAMES.map((name, i) => (
            <div
              key={i}
              className={`cc-parent-item${selectedMother === i ? ' active' : ''}`}
              onClick={() => changeMother(i)}
            >
              <img src={getHeritageImg('Female', name)} alt={name} onError={e => (e.currentTarget.style.display = 'none')} />
              <span className="cc-parent-name">{name}</span>
            </div>
          ))}
        </div>
      </div>
      <div className="cc-divider" />
      <div className="cc-section">
        <div className="cc-slider-group">
          <div className="cc-slider-header">
            <span className="cc-slider-label">Ressemblance</span>
            <span className="cc-slider-value">{faceMix}%</span>
          </div>
          <input
            type="range" className="cc-slider" min={0} max={100} value={faceMix}
            onChange={e => changeFaceMix(Number(e.target.value))}
          />
        </div>
        <div className="cc-slider-group">
          <div className="cc-slider-header">
            <span className="cc-slider-label">Teint de peau</span>
            <span className="cc-slider-value">{skinMix}</span>
          </div>
          <input
            type="range" className="cc-slider" min={0} max={45} value={skinMix}
            onChange={e => changeSkinMix(Number(e.target.value))}
          />
        </div>
      </div>
    </>
  );

  const renderHair = () => (
    <>
      <div className="cc-section">
        <div className="cc-section-title">Coiffure</div>
        <Stepper value={hairStyle} max={maxValues.hairstyle} onChange={changeHairStyle} label="Style" />
      </div>
      <div className="cc-section">
        <div className="cc-section-title">Couleur des cheveux</div>
        <ColorGrid colors={GTA_HAIR_COLORS} activeIndex={hairColor} onSelect={changeHairColor} />
      </div>
      <div className="cc-section">
        <div className="cc-section-title">Reflets</div>
        <ColorGrid colors={GTA_HAIR_COLORS} activeIndex={hairHighlight} onSelect={changeHairHighlight} />
      </div>
      {gender === 'm' && (
        <>
          <div className="cc-divider" />
          <div className="cc-section">
            <div className="cc-section-title">Barbe</div>
            <Stepper value={beardStyle} max={maxValues.beard} onChange={changeBeardStyle} label="Style" />
            <div className="cc-slider-group">
              <div className="cc-slider-header">
                <span className="cc-slider-label">Opacité</span>
                <span className="cc-slider-value">{beardOpacity * 10}%</span>
              </div>
              <input
                type="range" className="cc-slider" min={0} max={10} value={beardOpacity}
                onChange={e => changeBeardOpacity(Number(e.target.value))}
              />
            </div>
          </div>
          <div className="cc-section">
            <div className="cc-section-title">Couleur de barbe</div>
            <ColorGrid colors={GTA_HAIR_COLORS} activeIndex={beardColor} onSelect={changeBeardColor} />
          </div>
        </>
      )}
      <div className="cc-divider" />
      <div className="cc-section">
        <div className="cc-section-title">Sourcils</div>
        <Stepper value={eyebrowStyle} max={maxValues.eyebrows} onChange={changeEyebrowStyle} label="Style" />
        <div className="cc-slider-group">
          <div className="cc-slider-header">
            <span className="cc-slider-label">Opacité</span>
            <span className="cc-slider-value">{eyebrowOpacity * 10}%</span>
          </div>
          <input
            type="range" className="cc-slider" min={0} max={10} value={eyebrowOpacity}
            onChange={e => changeEyebrowOpacity(Number(e.target.value))}
          />
        </div>
      </div>
      <div className="cc-section">
        <div className="cc-section-title">Couleur des sourcils</div>
        <ColorGrid colors={GTA_HAIR_COLORS} activeIndex={eyebrowColor} onSelect={changeEyebrowColor} />
      </div>
      <div className="cc-divider" />
      <div className="cc-section">
        <div className="cc-section-title">Couleur des yeux</div>
        <ColorGrid colors={EYE_COLORS} activeIndex={eyeColor} onSelect={changeEyeColor} />
      </div>
    </>
  );

  const renderFace = () => (
    <div className="cc-section">
      <div className="cc-section-title">Traits du visage</div>
      <div className="cc-face-sliders">
        {FACE_SLIDERS.map((slider: FaceSliderDef) => (
          <div key={slider.key} className="cc-slider-group">
            <div className="cc-slider-header">
              <span className="cc-slider-label">{slider.label}</span>
              <span className="cc-slider-value">{faceValues[slider.key] ?? 0}</span>
            </div>
            <input
              type="range" className="cc-slider"
              min={slider.min} max={slider.max} step={slider.step}
              value={faceValues[slider.key] ?? 0}
              onChange={e => changeFaceSlider(slider.key, Number(e.target.value))}
            />
          </div>
        ))}
      </div>
    </div>
  );

  const renderAppearance = () => (
    <>
      <div className="cc-section">
        <div className="cc-section-title">Rouge à lèvres</div>
        <Stepper value={lipstickStyle} max={maxValues.lipstickStyle} onChange={changeLipstickStyle} label="Style" />
        <div className="cc-slider-group">
          <div className="cc-slider-header">
            <span className="cc-slider-label">Opacité</span>
            <span className="cc-slider-value">{lipstickOpacity * 10}%</span>
          </div>
          <input
            type="range" className="cc-slider" min={0} max={10} value={lipstickOpacity}
            onChange={e => changeLipstickOpacity(Number(e.target.value))}
          />
        </div>
        <div className="cc-section-title" style={{ marginTop: 6 }}>Couleur</div>
        <ColorGrid colors={GTA_HAIR_COLORS} activeIndex={lipstickColor} onSelect={changeLipstickColor} />
      </div>
      {gender === 'm' && (
        <>
          <div className="cc-divider" />
          <div className="cc-section">
            <div className="cc-section-title">Pilosité corporelle</div>
            <Stepper value={chestHairStyle} max={maxValues.chestHair} onChange={changeChestHairStyle} label="Style" />
            <div className="cc-slider-group">
              <div className="cc-slider-header">
                <span className="cc-slider-label">Opacité</span>
                <span className="cc-slider-value">{chestHairOpacity * 10}%</span>
              </div>
              <input
                type="range" className="cc-slider" min={0} max={10} value={chestHairOpacity}
                onChange={e => changeChestHairOpacity(Number(e.target.value))}
              />
            </div>
            <div className="cc-section-title" style={{ marginTop: 6 }}>Couleur</div>
            <ColorGrid colors={GTA_HAIR_COLORS} activeIndex={chestHairColor} onSelect={changeChestHairColor} />
          </div>
        </>
      )}
      <div className="cc-divider" />
      <div className="cc-section">
        <div className="cc-section-title">Imperfections</div>
        <Stepper value={blemishesStyle} max={maxValues.blemishes} onChange={changeBlemishesStyle} label="Style" />
        <div className="cc-slider-group">
          <div className="cc-slider-header">
            <span className="cc-slider-label">Opacité</span>
            <span className="cc-slider-value">{blemishesOpacity * 10}%</span>
          </div>
          <input
            type="range" className="cc-slider" min={0} max={10} value={blemishesOpacity}
            onChange={e => changeBlemishesOpacity(Number(e.target.value))}
          />
        </div>
      </div>
    </>
  );

  const renderOutfits = () => {
    // Outfits from config - keys must match image names in null-cache
    const outfitList = [
      { key: 'casual', label: 'Décontracté' },
      { key: 'class', label: 'Classique' },
    ];

    return (
      <div className="cc-section">
        <div className="cc-section-title">Tenues prédéfinies</div>
        <div className="cc-outfits-grid">
          {outfitList.map(outfit => (
            <div
              key={outfit.key}
              className={`cc-outfit-item${selectedOutfit === outfit.key ? ' active' : ''}`}
              onClick={() => selectOutfit(outfit.key)}
            >
              <div className="cc-outfit-image">
                <img
                  src={cacheImg(`outfits/${gender === 'm' ? 'male' : 'female'}/${outfit.key}.png`)}
                  alt={outfit.label}
                  onError={e => {
                    (e.currentTarget.style.display = 'none');
                    (e.currentTarget.parentElement as HTMLElement)?.classList.add('cc-outfit-placeholder');
                  }}
                />
              </div>
              <span className="cc-outfit-label">{outfit.label}</span>
            </div>
          ))}
        </div>
      </div>
    );
  };

  const renderContent = () => {
    switch (activeCategory) {
      case 'identity': return renderIdentity();
      case 'heritage': return renderHeritage();
      case 'hair': return renderHair();
      case 'face': return renderFace();
      case 'appearance': return renderAppearance();
      case 'outfits': return renderOutfits();
      default: return null;
    }
  };

  const activeCat = CATEGORIES.find(c => c.key === activeCategory);
  const categoryLabel = activeCat?.label || '';
  const categoryDesc = activeCat?.desc || '';

  /* ---- Bannière serveur (style bento boutique) ---- */
  const renderBanner = () => (
    <div className="cc-banner">
      {banner && (
        <img
          className="cc-banner-img"
          src={banner}
          alt=""
          onError={(e) => { (e.target as HTMLImageElement).style.display = 'none'; }}
        />
      )}
      <div className="cc-banner-shade" />
      {/* Bouton de fermeture volontairement retiré pour empêcher la fermeture du créateur */}
      <div className="cc-banner-text">
        <span className="cc-banner-eyebrow">Création de personnage</span>
        <h1 className="cc-banner-title">{serverConfig?.serverName || 'Null'}</h1>
        <p className="cc-banner-desc">Façonnez votre identité</p>
      </div>
    </div>
  );

  /* ---- Vue catégorie ---- */
  const renderCategory = () => (
    <>
      <div className="cc-content-header">
        <div className="cc-content-header-left">
          <button className="cc-back-btn" onClick={goPreviousStep} title="Retour" disabled={isFirstStep}>
            <ChevronLeft size={16} />
            <span>Retour</span>
          </button>
          <div className="cc-content-header-info">
            <h2>{categoryLabel}</h2>
            <p>Étape {stepNumber}/{STEP_ORDER.length} · {categoryDesc}</p>
          </div>
        </div>
        <div className="cc-toolbar">
          <div className="cc-cam-buttons">
            {CAMERA_VIEWS.map(cam => (
              <button
                key={cam.key}
                className={`cc-cam-btn${activeCam === cam.key ? ' active' : ''}`}
                onClick={() => handleCamChange(cam.key)}
              >
                {cam.label}
              </button>
            ))}
          </div>
          <button className="cc-icon-btn cc-reset" title="Réinitialiser" onClick={handleReset}>
            <RotateCcw size={14} />
          </button>
        </div>
      </div>

      <div className="cc-step-track" aria-hidden>
        {STEP_ORDER.map((step, index) => {
          const cat = CATEGORIES.find(c => c.key === step);
          return (
            <button
              key={step}
              className={`cc-step-dot${index === currentStepIndex ? ' active' : ''}${index < currentStepIndex ? ' done' : ''}`}
              onClick={() => {
                if (step === 'identity' || activeCategory !== 'identity' || validateIdentity()) {
                  setStep(step);
                }
              }}
              title={cat?.label}
            />
          );
        })}
      </div>

      <div className="cc-content">
        <div className="cc-content-inner" key={activeCategory}>
          {renderContent()}
        </div>
      </div>

      <div className="cc-add-bar">
        <button className="cc-add-btn" onClick={goNextStep}>
          {isLastStep ? <Check size={16} /> : <ChevronRight size={16} />}
          {isLastStep ? 'Valider le personnage' : 'Suivant'}
        </button>
      </div>
    </>
  );

  return (
    <div
      className={overlayClass}
      style={{ ...ccAccentVars, ...ccBrandVars } as React.CSSProperties}
      onMouseDown={handleMouseDown}
      onMouseMove={handleMouseMove}
      onMouseUp={handleMouseUp}
      onMouseLeave={handleMouseUp}
    >
      {/* Vignette radiale sur les bords (le menu prend tout l'écran) */}
      <div className="cc-vignette" aria-hidden />

      <div className="cc-container">
        {renderBanner()}
        <div className="cc-brand-sep" aria-hidden />
        {renderCategory()}
      </div>

      {/* Rotation Hint */}
      <div className={`cc-rotation-hint${!rotationHintVisible ? ' cc-hint-hidden' : ''}`}>
        <Move size={16} />
        Cliquez et glissez pour tourner votre personnage
      </div>

      {/* Notification */}
      {notification && <div className="cc-notification">{notification}</div>}
    </div>
  );
};

export default CharacterCreator;
