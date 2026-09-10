import { useState, useEffect, useSyncExternalStore } from 'react';

// ---------------------------------------------------------------------------
// Cache version store – updated via NUI message from client Lua
// ---------------------------------------------------------------------------

let _version = 0;
const _listeners = new Set<() => void>();

function subscribe(cb: () => void) {
  _listeners.add(cb);
  return () => { _listeners.delete(cb); };
}

function getSnapshot() {
  return _version;
}

function setCacheVersion(v: number) {
  if (v === _version) return;
  _version = v;
  _listeners.forEach(l => l());
}

// Listen for NUI messages from client Lua
window.addEventListener('message', (e) => {
  if (e.data?.action === 'cacheVersion' && typeof e.data.version === 'number') {
    setCacheVersion(e.data.version);
  }
});

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------

/**
 * Build a versioned image URL from null-cache.
 * Usage: cacheImg('items/bread.webp') → 'nui://null-cache/images/items/bread.webp?v=1711234567890'
 *
 * Absolute URLs (http(s)://, data:, blob:, nui://) are returned as-is so that
 * user-provided remote assets (e.g. a restaurant logo URL) are not mangled.
 */
export function cacheImg(path: string): string {
  if (!path) return path;
  if (/^(https?:|data:|blob:|nui:)/i.test(path)) {
    return path;
  }
  return `nui://null-cache/images/${path}${_version ? `?v=${_version}` : ''}`;
}

/**
 * React hook – triggers re-render when cache version changes.
 * Use in components that need live image refresh (e.g. ImageMaker).
 */
export function useCacheVersion(): number {
  return useSyncExternalStore(subscribe, getSnapshot);
}
