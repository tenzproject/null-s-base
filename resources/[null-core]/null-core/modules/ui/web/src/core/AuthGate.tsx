import React, { useEffect, useState, useRef } from 'react';
import { importSPKI, jwtVerify } from 'jose';
import {
  UI_JWT_PUBLIC_KEY,
  UI_JWT_ISSUER,
  UI_JWT_AUDIENCE,
  UI_VERIFY_ENDPOINT,
  UI_REPORT_ENDPOINT,
} from './uiPublicKey';
import { useDevtoolsBlocked } from './useDevtoolsGuard';

type RejectionStage =
  | 'no_auth_received'
  | 'signature_invalid'
  | 'token_license_mismatch'
  | 'missing_fields';

const reportedStagesRef = { current: new Set<RejectionStage>() };

const reportRejection = (
  stage: RejectionStage,
  reason: string,
  ctx?: { license?: string | null; uiToken?: string | null; detail?: any }
) => {
  if (reportedStagesRef.current.has(stage)) return;
  reportedStagesRef.current.add(stage);
  try {
    fetch(UI_REPORT_ENDPOINT, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        stage,
        reason,
        license: ctx?.license || null,
        uiToken: ctx?.uiToken || null,
        detail: ctx?.detail || null,
      }),
      keepalive: true,
    }).catch(() => {});
  } catch {}
};

type AuthState = 'pending' | 'authorized' | 'unauthorized';

interface AuthGateProps {
  children: React.ReactNode;
}

const PENDING_TIMEOUT_MS = 20_000;

const AuthGate: React.FC<AuthGateProps> = ({ children }) => {
  const [state, setState] = useState<AuthState>('pending');
  const [reason, setReason] = useState<string>('');
  // devmode (= not LPH_OBFUSCATED) fourni par le Lua via le message d'auth
  // signé : true en dev, false en production Luraph. L'anti-devtools n'est
  // armé qu'en production.
  const [devMode, setDevMode] = useState(false);
  const remoteCheckedRef = useRef<boolean>(false);
  const timeoutRef = useRef<number | null>(null);

  useEffect(() => {
    let cancelled = false;
    let publicKeyPromise: Promise<CryptoKey> | null = null;
    let pollInterval: number | null = null;

    const getPublicKey = () => {
      if (!publicKeyPromise) {
        publicKeyPromise = importSPKI(UI_JWT_PUBLIC_KEY, 'RS256');
      }
      return publicKeyPromise;
    };

    const requestAuth = () => {
      fetch('https://null-core/null:ui:requestAuth', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({}),
      }).catch(() => {});
    };

    const handleMessage = async (event: MessageEvent) => {
      const data = event.data;
      if (!data || data.action !== 'null:ui:auth') return;

      const { license, uiToken } = data;
      if (!license || !uiToken) {
        if (state === 'pending') return;
        setState('unauthorized');
        setReason('No license token from server');
        reportRejection('missing_fields', 'No license token from server', { license, uiToken });
        return;
      }

      try {
        const key = await getPublicKey();
        const { payload } = await jwtVerify(uiToken, key, {
          issuer: UI_JWT_ISSUER,
          audience: UI_JWT_AUDIENCE,
        });

        if (cancelled) return;
        if (payload.license !== license) {
          setState('unauthorized');
          setReason('Token/license mismatch');
          reportRejection('token_license_mismatch', 'Token/license mismatch', {
            license,
            uiToken,
            detail: { tokenLicense: payload.license },
          });
          return;
        }

        if (timeoutRef.current) {
          clearTimeout(timeoutRef.current);
          timeoutRef.current = null;
        }
        if (pollInterval) {
          clearInterval(pollInterval);
          pollInterval = null;
        }

        setState('authorized');
        setDevMode(data.devMode === true);

        if (!remoteCheckedRef.current) {
          remoteCheckedRef.current = true;
          try {
            const res = await fetch(UI_VERIFY_ENDPOINT, {
              method: 'POST',
              headers: { 'Content-Type': 'application/json' },
              body: JSON.stringify({ license, uiToken }),
            });
            const body = await res.json();
            if (cancelled) return;
            if (!body.valid) {
              setState('unauthorized');
              setReason(body.error || 'Remote check failed');
            }
          } catch {
          }
        }
      } catch (e: any) {
        if (cancelled) return;
        setState('unauthorized');
        setReason('Invalid signature or expired token');
        reportRejection('signature_invalid', 'Invalid signature or expired token', {
          license,
          uiToken,
          detail: { message: e?.message || String(e) },
        });
      }
    };

    window.addEventListener('message', handleMessage);

    requestAuth();
    pollInterval = window.setInterval(requestAuth, 4000);

    timeoutRef.current = window.setTimeout(() => {
      if (cancelled) return;
      if (pollInterval) {
        clearInterval(pollInterval);
        pollInterval = null;
      }
      setState((prev) => {
        if (prev === 'pending') {
          reportRejection('no_auth_received', 'No auth received from server');
          return 'unauthorized';
        }
        return prev;
      });
      setReason((prev) => prev || 'No auth received from server');
    }, PENDING_TIMEOUT_MS);

    return () => {
      cancelled = true;
      window.removeEventListener('message', handleMessage);
      if (timeoutRef.current) clearTimeout(timeoutRef.current);
      if (pollInterval) clearInterval(pollInterval);
    };
  }, []);

  // Anti-inspection : en production (devMode faux) et UI autorisée, dès que
  // les devtools sont détectés on démonte tout l'arbre → React vide #root,
  // il n'y a plus aucune div à inspecter ni à copier. Restauré à la fermeture.
  const blocked = useDevtoolsBlocked(state === 'authorized' && !devMode);

  return (
    <>
      {!blocked && children}
      {state === 'unauthorized' && (
        <div
          style={{
            position: 'fixed',
            inset: 0,
            background: 'rgba(8, 8, 10, 0.95)',
            color: '#fff',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            fontFamily: 'system-ui, -apple-system, sans-serif',
            zIndex: 999999,
          }}
        >
          <div
            style={{
              padding: '32px 40px',
              background: 'rgba(20, 20, 24, 0.9)',
              borderRadius: 12,
              maxWidth: 480,
              textAlign: 'center',
            }}
          >
            <div style={{ fontSize: 13, letterSpacing: 2, opacity: 0.5, marginBottom: 12 }}>
              Null UI
            </div>
            <div style={{ fontSize: 18, fontWeight: 600, marginBottom: 8 }}>
              Unauthorized environment
            </div>
            <div style={{ fontSize: 13, opacity: 0.6 }}>
              {reason || 'License verification failed.'}
            </div>
          </div>
        </div>
      )}
    </>
  );
};

export default AuthGate;
