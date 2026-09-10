import { useEffect, useState } from 'react';

/**
 * Détection d'ouverture des devtools NUI.
 *
 * En CEF (FiveM) les devtools s'ouvrent dans une fenêtre séparée : les ruses
 * basées sur les dimensions de fenêtre ne fonctionnent pas. On combine :
 *  - le timing autour d'un `debugger` (pause si les devtools sont ouverts,
 *    quel que soit le panneau, y compris Elements) ;
 *  - une sonde `console` (getter déclenché par le rendu du panneau Console).
 *
 * Quand `active` est faux (dev / hors production), aucune détection n'est
 * lancée.
 */

const PAUSE_THRESHOLD = 100; // ms
const CHECK_INTERVAL = 700;

function debuggerOpen(): boolean {
  const start = performance.now();
  // eslint-disable-next-line no-debugger
  debugger;
  return performance.now() - start > PAUSE_THRESHOLD;
}

function makeConsoleProbe() {
  let triggered = false;
  const probe = document.createElement('div');
  Object.defineProperty(probe, 'id', {
    get() {
      triggered = true;
      return '';
    },
  });
  return () => {
    triggered = false;
    // Le getter `id` est lu par le panneau Console lorsqu'il rend l'élément.
    // eslint-disable-next-line no-console
    console.log(probe);
    return triggered;
  };
}

export function useDevtoolsBlocked(active: boolean): boolean {
  const [blocked, setBlocked] = useState(false);

  useEffect(() => {
    if (!active) {
      setBlocked(false);
      return;
    }
    const consoleCheck = makeConsoleProbe();
    const tick = () => {
      const open = debuggerOpen() || consoleCheck();
      setBlocked(open);
    };
    const id = window.setInterval(tick, CHECK_INTERVAL);
    tick();
    return () => window.clearInterval(id);
  }, [active]);

  return blocked;
}
