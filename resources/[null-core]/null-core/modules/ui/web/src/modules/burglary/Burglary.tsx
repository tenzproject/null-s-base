import React, { useCallback, useEffect, useState } from 'react';
import LockpickGame from './LockpickGame';
import BurglaryLootPanel, { BurglaryItem } from './BurglaryLootPanel';
import StealMinigame from './StealMinigame';
import './Burglary.css';
import './BurglaryLootPanel.css';

const GetParentResourceName = () => 'null-core';

export type Difficulty = {
  pins: number;
  window: number;
  rotation: number;
  tries: number;
  lootTime: number;
  maxItems: number;
};

type Phase = 'idle' | 'minigame' | 'loot' | 'stealgame';

export interface MinigameScaling {
  step: number;
  spotReduce: number;
  durationReduce: number;
  minSpot: number;
  minDuration: number;
  attemptsReduce: number;
  minAttempts: number;
}

export interface MinigameConfig {
  enabled: boolean;
  duration: number;
  sweetSpotSize: number;
  maxAttempts: number;
  scaling?: MinigameScaling;
}

const Burglary: React.FC = () => {
  const [phase, setPhase] = useState<Phase>('idle');
  const [difficulty, setDifficulty] = useState<Difficulty | null>(null);
  const [interior, setInterior] = useState<string>('');
  const [propKey, setPropKey] = useState<string>('');

  const [lootItems, setLootItems] = useState<BurglaryItem[]>([]);
  const [taken, setTaken] = useState(0);
  const [max, setMax] = useState(0);
  const [timeLeft, setTimeLeft] = useState(0);
  const [pickedToast, setPickedToast] = useState<{ label: string; count: number } | null>(null);
  const [endReason, setEndReason] = useState<string | null>(null);

  // New: Real chest loot state
  const [isRealChest, setIsRealChest] = useState(false);
  const [maxQtyPerItem, setMaxQtyPerItem] = useState(10);
  const [attemptsPerItem, setAttemptsPerItem] = useState(1);
  const [itemStealCooldown, setItemStealCooldown] = useState(0);
  const [minigameConfig, setMinigameConfig] = useState<MinigameConfig | null>(null);
  const [pendingLootKey, setPendingLootKey] = useState<string | null>(null);
  const [pendingLootLabel, setPendingLootLabel] = useState<string>('');
  const [pendingQuantity, setPendingQuantity] = useState(1);
  const [currentAttempt, setCurrentAttempt] = useState(0); // mini-jeux réussis pour l'item en cours
  const [cooldownUntil, setCooldownUntil] = useState<number>(0); // Date.now() ms

  const callNui = useCallback(async (route: string, body: any = {}) => {
    try {
      const r = await fetch(`https://${GetParentResourceName()}/${route}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(body),
      });
      return r.json().catch(() => ({}));
    } catch {
      return {};
    }
  }, []);

  // --- NUI message bus -------------------------------------------------------
  useEffect(() => {
    const onMessage = (e: MessageEvent) => {
      const { action, data } = e.data || {};
      switch (action) {
        case 'burglary:openMinigame':
          setDifficulty(data.difficulty);
          setInterior(data.interior);
          setPropKey(data.propKey);
          setEndReason(null);
          setPhase('minigame');
          break;
        case 'burglary:openLoot':
          setLootItems(data.items || []);
          setTaken(0);
          setMax(data.maxItems || 0);
          setTimeLeft(data.timeLeft || 60);
          setEndReason(null);
          setIsRealChest(data.isRealChest || false);
          setMaxQtyPerItem(data.maxQtyPerItem || 10);
          setAttemptsPerItem(data.attemptsPerItem || 1);
          setItemStealCooldown(data.itemStealCooldown || 0);
          setCooldownUntil(0);
          if (data.minigameConfig) {
            setMinigameConfig(data.minigameConfig);
          }
          setPhase('loot');
          break;
        case 'burglary:lootUpdate':
          setLootItems(data.items || []);
          setTaken(data.taken || 0);
          setMax(data.max || 0);
          if (data.picked) {
            setPickedToast({ label: data.picked.label || data.picked.item, count: data.picked.count });
            setTimeout(() => setPickedToast(null), 1600);
          }
          break;
        case 'burglary:lootEnd':
          setEndReason(data?.reason || 'closed');
          setTimeout(() => setPhase('idle'), 1200);
          break;
        case 'burglary:close':
          setPhase('idle');
          break;
      }
    };
    window.addEventListener('message', onMessage);
    return () => window.removeEventListener('message', onMessage);
  }, []);

  // --- Minigame outcome ------------------------------------------------------
  const handleMinigameDone = useCallback((success: boolean) => {
    callNui('burglary:result', { success });
    if (!success) {
      setPhase('idle');
    }
    // On success the server will send burglary:openLoot
  }, [callNui]);

  // --- Loot interactions -----------------------------------------------------
  const handlePick = useCallback((lootKey: string, quantity: number = 1, label: string = '') => {
    // Cooldown entre items
    if (itemStealCooldown > 0 && Date.now() < cooldownUntil) return;
    // If real chest with minigame enabled, show minigame first
    if (isRealChest && minigameConfig && minigameConfig.enabled) {
      setPendingLootKey(lootKey);
      setPendingLootLabel(label || lootKey);
      setPendingQuantity(quantity);
      setCurrentAttempt(0);
      setPhase('stealgame');
    } else {
      callNui('burglary:loot', { lootKey, quantity, minigameSuccess: true });
      if (itemStealCooldown > 0) setCooldownUntil(Date.now() + itemStealCooldown);
    }
  }, [callNui, isRealChest, minigameConfig, itemStealCooldown, cooldownUntil]);

  const handleMinigameSuccess = useCallback(() => {
    const nextAttempt = currentAttempt + 1;
    if (nextAttempt < attemptsPerItem) {
      // Pas encore assez de mini-jeux réussis — relancer un autre
      setCurrentAttempt(nextAttempt);
      setPhase('loot');
      setTimeout(() => setPhase('stealgame'), 300);
    } else {
      // Série complète → vol validé
      if (pendingLootKey) {
        callNui('burglary:loot', {
          lootKey: pendingLootKey,
          quantity: pendingQuantity,
          minigameSuccess: true,
        });
        if (itemStealCooldown > 0) setCooldownUntil(Date.now() + itemStealCooldown);
      }
      setCurrentAttempt(0);
      setPendingLootKey(null);
      setPhase('loot');
    }
  }, [callNui, pendingLootKey, pendingQuantity, currentAttempt, attemptsPerItem, itemStealCooldown]);

  const handleMinigameFail = useCallback(() => {
    setCurrentAttempt(0);
    setPendingLootKey(null);
    setPhase('loot');
  }, []);

  const handleMinigameCancel = useCallback(() => {
    setPendingLootKey(null);
    setPhase('loot');
  }, []);

  const handleClose = useCallback(() => {
    callNui('burglary:close', {});
    setPhase('idle');
  }, [callNui]);

  // Compute scaled minigame difficulty based on requested quantity
  const scaledDifficulty = (cfg: MinigameConfig, qty: number) => {
    const s = cfg.scaling;
    if (!s || qty <= 1) return { duration: cfg.duration, sweetSpotSize: cfg.sweetSpotSize, maxAttempts: cfg.maxAttempts };
    const steps = Math.floor((qty - 1) / s.step);
    return {
      duration:     Math.max(s.minDuration, cfg.duration - steps * s.durationReduce),
      sweetSpotSize:Math.max(s.minSpot,     cfg.sweetSpotSize - steps * s.spotReduce),
      maxAttempts:  Math.max(s.minAttempts, cfg.maxAttempts - Math.floor(steps / 2) * s.attemptsReduce),
    };
  };

  const renderStealMinigame = () => {
    if (!minigameConfig) return null;
    const sd = scaledDifficulty(minigameConfig, pendingQuantity);
    return (
      <StealMinigame
        duration={sd.duration}
        sweetSpotSize={sd.sweetSpotSize}
        maxAttempts={sd.maxAttempts}
        quantity={pendingQuantity}
        currentAttempt={currentAttempt}
        totalAttempts={attemptsPerItem}
        itemLabel={pendingLootLabel}
        onSuccess={handleMinigameSuccess}
        onFail={handleMinigameFail}
        onCancel={handleMinigameCancel}
      />
    );
  };

  // --- Render ----------------------------------------------------------------
  if (phase === 'idle') return null;

  // Lockpick: overlay opaque centré
  if (phase === 'minigame') {
    return (
      <div className="burg-overlay">
        {difficulty && (
          <LockpickGame
            difficulty={difficulty}
            interior={interior}
            onDone={handleMinigameDone}
          />
        )}
      </div>
    );
  }

  // Loot panel + steal minigame: pas d'overlay opaque (joueur voit le monde)
  return (
    <>
      {(phase === 'loot' || phase === 'stealgame') && (
        <BurglaryLootPanel
          items={lootItems}
          taken={taken}
          max={max}
          maxQtyPerItem={maxQtyPerItem}
          initialTime={timeLeft}
          interior={interior}
          onPick={handlePick}
          onClose={handleClose}
          endReason={endReason}
          pickedToast={pickedToast}
          minigameConfig={minigameConfig}
          cooldownUntil={cooldownUntil}
          itemStealCooldown={itemStealCooldown}
        />
      )}

      {phase === 'stealgame' && minigameConfig && renderStealMinigame()}
    </>
  );
};

export default Burglary;
