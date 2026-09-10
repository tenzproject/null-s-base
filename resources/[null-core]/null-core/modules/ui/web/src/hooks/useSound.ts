/**
 * useSound - React hook for UI sound effects
 * 
 * Usage:
 *   const { playSound } = useSound();
 *   playSound('click');
 * 
 * Or directly import the singleton:
 *   import { soundManager } from '@core/SoundManager';
 *   soundManager.play('click');
 */

import { useCallback } from 'react';
import { soundManager, SoundName } from '@core/SoundManager';

export function useSound() {
  const playSound = useCallback((name: SoundName) => {
    soundManager.play(name);
  }, []);

  return { playSound, soundManager };
}
