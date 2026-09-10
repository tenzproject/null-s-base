const resourceName = 'null-crimenet';

export function postNUI(event: string, data?: Record<string, unknown>): Promise<unknown> {
  return fetch(`https://${resourceName}/${event}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data || {}),
  }).then(r => r.json()).catch(() => null);
}

export function useNuiEvent<T = unknown>(action: string, handler: (data: T) => void) {
  const listener = (event: MessageEvent) => {
    const { action: a, data } = event.data || {};
    if (a === action) handler(data as T);
  };
  window.addEventListener('message', listener);
  return () => window.removeEventListener('message', listener);
}

export const isDev = !window.hasOwnProperty('invokeNative');
