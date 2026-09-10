import React, { useState, useEffect, useCallback, useRef } from 'react';
import { ChevronLeft, ChevronRight, RotateCcw, Check } from 'lucide-react';
import {
  FATHER_NAMES, MOTHER_NAMES, HERITAGE_IMAGES,
  GTA_HAIR_COLORS, EYE_COLORS, FACE_SLIDERS, MaxValues, CreatorCategory
} from '../character-creator/types';
import { cacheImg } from '@shared/cacheVersion';
import './ShopCreator.css';

interface ShopCreatorProps {
  primaryColor: string;
  playerSex: 'male' | 'female';
  onBack: () => void;
}

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

const CATEGORIES: { key: CreatorCategory; label: string; desc: string }[] = [
  { key: 'identity', label: 'Identite', desc: 'Sexe & infos' },
  { key: 'heritage', label: 'Heritage', desc: 'Parents & teint' },
  { key: 'hair', label: 'Cheveux', desc: 'Coupe & couleur' },
  { key: 'face', label: 'Visage', desc: 'Traits & formes' },
  { key: 'appearance', label: 'Apparence', desc: 'Maquillage & peau' },
  { key: 'outfits', label: 'Tenues', desc: 'Looks complets' },
];

const CAMERA_VIEWS = [
  { key: 'default', label: 'Corps' },
  { key: 'head', label: 'Tete' },
  { key: 'body', label: 'Torse' },
  { key: 'legs', label: 'Jambes' },
];

const ShopCreator: React.FC<ShopCreatorProps> = ({ primaryColor, playerSex, onBack }) => {
  const [activeCategory, setActiveCategory] = useState<CreatorCategory>('identity');
  const [activeCam, setActiveCam] = useState('default');
  const [gender, setGender] = useState<'m' | 'f'>(playerSex === 'female' ? 'f' : 'm');

  const [selectedFather, setSelectedFather] = useState(0);
  const [selectedMother, setSelectedMother] = useState(0);
  const [faceMix, setFaceMix] = useState(50);
  const [skinMix, setSkinMix] = useState(50);

  const [hairStyle, setHairStyle] = useState(0);
  const [hairColor, setHairColor] = useState(0);
  const [hairHighlight, setHairHighlight] = useState(0);
  const [beardStyle, setBeardStyle] = useState(0);
  const [beardColor, setBeardColor] = useState(0);
  const [beardOpacity, setBeardOpacity] = useState(10);
  const [eyebrowStyle, setEyebrowStyle] = useState(0);
  const [eyebrowColor, setEyebrowColor] = useState(0);
  const [eyebrowOpacity, setEyebrowOpacity] = useState(10);
  const [eyeColor, setEyeColor] = useState(0);
  const [faceValues, setFaceValues] = useState<Record<string, number>>(() => {
    const d: Record<string, number> = {};
    FACE_SLIDERS.forEach(s => { d[s.key] = s.defaultValue; });
    return d;
  });
  const [lipstickStyle, setLipstickStyle] = useState(0);
  const [lipstickColor, setLipstickColor] = useState(0);
  const [lipstickOpacity, setLipstickOpacity] = useState(10);
  const [chestHairStyle, setChestHairStyle] = useState(0);
  const [chestHairColor, setChestHairColor] = useState(0);
  const [chestHairOpacity, setChestHairOpacity] = useState(10);
  const [blemishesStyle, setBlemishesStyle] = useState(0);
  const [blemishesOpacity, setBlemishesOpacity] = useState(10);
  const [outfits, setOutfits] = useState<Record<string, any>>({});
  const [selectedOutfit, setSelectedOutfit] = useState<string | null>(null);
  const [maxValues, setMaxValues] = useState<MaxValues>({
    father: 44, mother: 45, hairstyle: 73, hairColor: 63,
    eyebrows: 33, beard: 28, eyeColor: 29, beardColor: 63,
    eyebrowColor: 63, lipstickStyle: 9, lipstickColor: 63,
    chestHair: 16, blemishes: 23
  });
  const [notification, setNotification] = useState<string | null>(null);
  const notifTimer = useRef<ReturnType<typeof setTimeout>>();

  const showNotif = useCallback((msg: string) => {
    setNotification(msg);
    if (notifTimer.current) clearTimeout(notifTimer.current);
    notifTimer.current = setTimeout(() => setNotification(null), 3000);
  }, []);

  useEffect(() => {
    const handler = (event: MessageEvent) => {
      const { action, data } = event.data || {};
      if (action === 'newCreator:setData') {
        if (data?.maxValues) setMaxValues((prev: MaxValues) => ({ ...prev, ...data.maxValues }));
        if (data?.outfits) setOutfits(data.outfits);
        if (data?.gender) setGender(data.gender);
      }
    };
    window.addEventListener('message', handler);
    return () => window.removeEventListener('message', handler);
  }, []);

  useEffect(() => {
    const camMap: Record<CreatorCategory, string> = {
      identity: 'default', heritage: 'head', hair: 'head',
      face: 'head', appearance: 'head', outfits: 'default',
    };
    const cam = camMap[activeCategory] || 'default';
    setActiveCam(cam);
    nuiCall('newCreator:cameraChange', { camera: cam });
  }, [activeCategory]);

  const changeGender = useCallback((g: 'm' | 'f') => {
    setGender(g);
    nuiCall('newCreator:charInfo', { sex: g === 'm' ? 0 : 1 });
  }, []);

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
      const d: Record<string, number> = {};
      FACE_SLIDERS.forEach(s => { d[s.key] = s.defaultValue; });
      return d;
    });
    showNotif('Reinitialise');
  }, [showNotif]);

  const handleSave = useCallback(() => {
    nuiCall('newCreator:finishCreator', {});
    showNotif('Sauvegarde');
  }, [showNotif]);

  const handleCamChange = useCallback((cam: string) => {
    setActiveCam(cam);
    nuiCall('newCreator:cameraChange', { camera: cam });
  }, []);

  const getHeritageImg = (g: 'Male' | 'Female', name: string) => {
    const key = `${g}-${name}`;
    const file = HERITAGE_IMAGES[key];
    return file ? cacheImg(`heritage/${file}`) : '';
  };

  const Stepper = ({ value, max, label, onChange }: { value: number; max: number; label: string; onChange: (v: number) => void }) => (
    <div className="sc-stepper-group">
      <div className="sc-stepper-label">
        <span>{label}</span>
        <span className="sc-stepper-val">{value}/{max}</span>
      </div>
      <div className="sc-stepper">
        <button onClick={() => onChange(value <= 0 ? max : value - 1)}><ChevronLeft size={13} /></button>
        <span>{value}</span>
        <button onClick={() => onChange(value >= max ? 0 : value + 1)}><ChevronRight size={13} /></button>
      </div>
    </div>
  );

  const ColorGrid = ({ colors, activeIndex, onSelect }: { colors: string[]; activeIndex: number; onSelect: (i: number) => void }) => (
    <div className={`sc-color-grid${colors.length === 30 ? ' sc-color-grid-compact' : ''}`}>
      {colors.map((color, i) => (
        <div
          key={i}
          className={`sc-color-swatch${activeIndex === i ? ' active' : ''}`}
          style={{ background: color }}
          onClick={() => onSelect(i)}
        />
      ))}
    </div>
  );

  const Slider = ({ label, value, min, max, onChange }: { label: string; value: number; min: number; max: number; onChange: (v: number) => void }) => (
    <div className="sc-slider-group">
      <div className="sc-slider-row">
        <span className="sc-slider-label">{label}</span>
        <span className="sc-slider-val">{value}</span>
      </div>
      <input type="range" className="sc-slider" min={min} max={max} value={value}
        onChange={e => onChange(Number(e.target.value))} />
    </div>
  );

  const renderIdentity = () => (
    <>
      <div className="sc-section">
        <div className="sc-section-title">Sexe</div>
        <div className="sc-gender-row">
          <button className={`sc-gender-btn${gender === 'm' ? ' active' : ''}`} onClick={() => changeGender('m')} style={gender === 'm' ? { borderColor: primaryColor } as any : undefined}>Homme</button>
          <button className={`sc-gender-btn${gender === 'f' ? ' active' : ''}`} onClick={() => changeGender('f')} style={gender === 'f' ? { borderColor: primaryColor } as any : undefined}>Femme</button>
        </div>
      </div>
    </>
  );

  const renderHeritage = () => (
    <>
      <div className="sc-section">
        <div className="sc-section-title">Pere</div>
        <div className="sc-parent-grid">
          {FATHER_NAMES.map((name, i) => (
            <div key={i} className={`sc-parent-item${selectedFather === i ? ' active' : ''}`}
              onClick={() => { setSelectedFather(i); nuiCall('newCreator:faceFather', i); }}
            >
              <img src={getHeritageImg('Male', name)} alt={name} onError={e => (e.currentTarget.style.display = 'none')} />
              <span>{name}</span>
            </div>
          ))}
        </div>
      </div>
      <div className="sc-section">
        <div className="sc-section-title">Mere</div>
        <div className="sc-parent-grid">
          {MOTHER_NAMES.map((name, i) => (
            <div key={i} className={`sc-parent-item${selectedMother === i ? ' active' : ''}`}
              onClick={() => { setSelectedMother(i); nuiCall('newCreator:faceMother', i); }}
            >
              <img src={getHeritageImg('Female', name)} alt={name} onError={e => (e.currentTarget.style.display = 'none')} />
              <span>{name}</span>
            </div>
          ))}
        </div>
      </div>
      <div className="sc-section">
        <Slider label="Ressemblance" value={faceMix} min={0} max={100}
          onChange={v => { setFaceMix(v); nuiCall('newCreator:faceMix', v / 100); }} />
        <Slider label="Teint de peau" value={skinMix} min={0} max={45}
          onChange={v => { setSkinMix(v); nuiCall('newCreator:skinTone', v); }} />
      </div>
    </>
  );

  const renderHair = () => (
    <>
      <div className="sc-section">
        <div className="sc-section-title">Coiffure</div>
        <Stepper label="Style" value={hairStyle} max={maxValues.hairstyle}
          onChange={v => { setHairStyle(v); nuiCall('newCreator:hairstyle', v); }} />
        <div className="sc-section-subtitle">Couleur principale</div>
        <ColorGrid colors={GTA_HAIR_COLORS} activeIndex={hairColor}
          onSelect={v => { setHairColor(v); nuiCall('newCreator:hairColor', v); }} />
        <div className="sc-section-subtitle">Reflet</div>
        <ColorGrid colors={GTA_HAIR_COLORS} activeIndex={hairHighlight}
          onSelect={v => { setHairHighlight(v); nuiCall('newCreator:hairHighlight', v); }} />
      </div>
      {gender === 'm' && (
        <div className="sc-section">
          <div className="sc-section-title">Barbe</div>
          <Stepper label="Style" value={beardStyle} max={maxValues.beard}
            onChange={v => { setBeardStyle(v); nuiCall('newCreator:beardStyle', v); }} />
          <ColorGrid colors={GTA_HAIR_COLORS} activeIndex={beardColor}
            onSelect={v => { setBeardColor(v); nuiCall('newCreator:beardColor', v); }} />
          <Slider label="Opacite" value={beardOpacity} min={0} max={10}
            onChange={v => { setBeardOpacity(v); nuiCall('newCreator:beardOpacity', v / 10); }} />
        </div>
      )}
      <div className="sc-section">
        <div className="sc-section-title">Sourcils</div>
        <Stepper label="Style" value={eyebrowStyle} max={maxValues.eyebrows}
          onChange={v => { setEyebrowStyle(v); nuiCall('newCreator:eyebrowStyle', v); }} />
        <ColorGrid colors={GTA_HAIR_COLORS} activeIndex={eyebrowColor}
          onSelect={v => { setEyebrowColor(v); nuiCall('newCreator:eyebrowColor', v); }} />
        <Slider label="Opacite" value={eyebrowOpacity} min={0} max={10}
          onChange={v => { setEyebrowOpacity(v); nuiCall('newCreator:eyebrowOpacity', v / 10); }} />
      </div>
      <div className="sc-section">
        <div className="sc-section-title">Yeux</div>
        <ColorGrid colors={EYE_COLORS} activeIndex={eyeColor}
          onSelect={v => { setEyeColor(v); nuiCall('newCreator:eyeColor', v); }} />
      </div>
    </>
  );

  const renderFace = () => (
    <div className="sc-section">
      <div className="sc-section-title">Traits du visage</div>
      {FACE_SLIDERS.map(slider => (
        <Slider key={slider.key} label={slider.label} value={faceValues[slider.key] ?? slider.defaultValue}
          min={slider.min} max={slider.max}
          onChange={v => { setFaceValues(prev => ({ ...prev, [slider.key]: v })); nuiCall(`newCreator:${slider.key}`, v / 100); }} />
      ))}
    </div>
  );

  const renderAppearance = () => (
    <>
      {gender === 'f' && (
        <div className="sc-section">
          <div className="sc-section-title">Rouge a levres</div>
          <Stepper label="Style" value={lipstickStyle} max={maxValues.lipstickStyle}
            onChange={v => { setLipstickStyle(v); nuiCall('newCreator:lipstickStyle', v); }} />
          <ColorGrid colors={GTA_HAIR_COLORS} activeIndex={lipstickColor}
            onSelect={v => { setLipstickColor(v); nuiCall('newCreator:lipstickColor', v); }} />
          <Slider label="Opacite" value={lipstickOpacity} min={0} max={10}
            onChange={v => { setLipstickOpacity(v); nuiCall('newCreator:lipstickOpacity', v / 10); }} />
        </div>
      )}
      {gender === 'm' && (
        <div className="sc-section">
          <div className="sc-section-title">Poils de poitrine</div>
          <Stepper label="Style" value={chestHairStyle} max={maxValues.chestHair}
            onChange={v => { setChestHairStyle(v); nuiCall('newCreator:chestHair', v); }} />
          <ColorGrid colors={GTA_HAIR_COLORS} activeIndex={chestHairColor}
            onSelect={v => { setChestHairColor(v); nuiCall('newCreator:chestHairColor', v); }} />
          <Slider label="Opacite" value={chestHairOpacity} min={0} max={10}
            onChange={v => { setChestHairOpacity(v); nuiCall('newCreator:chestHairOpacity', v / 10); }} />
        </div>
      )}
      <div className="sc-section">
        <div className="sc-section-title">Imperfections</div>
        <Stepper label="Style" value={blemishesStyle} max={maxValues.blemishes}
          onChange={v => { setBlemishesStyle(v); nuiCall('newCreator:blemishesStyle', v); }} />
        <Slider label="Opacite" value={blemishesOpacity} min={0} max={10}
          onChange={v => { setBlemishesOpacity(v); nuiCall('newCreator:blemishesOpacity', v / 10); }} />
      </div>
    </>
  );

  const renderOutfits = () => {
    const outfitKeys = Object.keys(outfits);
    const sexOutfits = outfitKeys.filter(k => k.startsWith(gender === 'm' ? 'male' : 'female'));
    return (
      <div className="sc-section">
        <div className="sc-section-title">Tenues disponibles</div>
        {sexOutfits.length === 0 ? (
          <div className="sc-empty-outfits">Aucune tenue disponible</div>
        ) : (
          <div className="sc-outfits-grid">
            {sexOutfits.map(key => (
              <div key={key}
                className={`sc-outfit-card${selectedOutfit === key ? ' active' : ''}`}
                onClick={() => { setSelectedOutfit(key); nuiCall('newCreator:outfit', key); }}
              >
                <img
                  src={cacheImg(`outfits/${gender === 'm' ? 'male' : 'female'}/${key}.webp`)}
                  alt={key}
                  onError={e => { (e.currentTarget as HTMLImageElement).style.opacity = '0'; }}
                />
                <span>{outfits[key]?.label || key}</span>
                {selectedOutfit === key && <div className="sc-outfit-check"><Check size={10} /></div>}
              </div>
            ))}
          </div>
        )}
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

  return (
    <div className="sc-wrap" style={{ '--sc-accent': primaryColor } as React.CSSProperties}>
      <div className="sc-cats-row">
        {CATEGORIES.map(cat => (
          <button
            key={cat.key}
            className={`sc-cat-card${activeCategory === cat.key ? ' active' : ''}`}
            onClick={() => setActiveCategory(cat.key)}
          >
            <span className="sc-cat-label">{cat.label}</span>
            <span className="sc-cat-desc">{cat.desc}</span>
            {activeCategory === cat.key && <div className="sc-cat-active-bar" style={{ backgroundColor: primaryColor }} />}
          </button>
        ))}
      </div>

      <div className="sc-body">
        <div className="sc-content">
          {renderContent()}
        </div>

        <div className="sc-sidebar">
          <div className="sc-cam-strip">
            {CAMERA_VIEWS.map(cam => (
              <button
                key={cam.key}
                className={`sc-cam-btn${activeCam === cam.key ? ' active' : ''}`}
                onClick={() => handleCamChange(cam.key)}
                style={activeCam === cam.key ? { color: primaryColor, borderColor: primaryColor } as any : undefined}
              >
                {cam.label}
              </button>
            ))}
          </div>

          <div className="sc-actions">
            <button className="sc-reset-btn" onClick={handleReset}>
              <RotateCcw size={13} />
              <span>Reset</span>
            </button>
            <button className="sc-save-btn" onClick={handleSave} style={{ backgroundColor: primaryColor } as any}>
              <Check size={13} />
              <span>Valider</span>
            </button>
          </div>
        </div>
      </div>

      {notification && (
        <div className="sc-notif">
          <Check size={12} />
          <span>{notification}</span>
        </div>
      )}
    </div>
  );
};

export default ShopCreator;
