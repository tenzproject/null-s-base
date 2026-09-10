import React, { useState, useEffect, useCallback, useRef } from 'react';
import { soundManager } from '@core/SoundManager';
import './Radio.css';

interface RadioProps {
  visible: boolean;
  onClose: () => void;
  primaryColor: string;
}

const GetParentResourceName = () =>
  (window as any).GetParentResourceName ? (window as any).GetParentResourceName() : 'null-core';

const nuiCallback = (name: string, data: any = {}) =>
  fetch(`https://${GetParentResourceName()}/${name}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data),
  }).then(r => r.json()).catch(() => ({}));

const Radio: React.FC<RadioProps> = ({ visible, onClose }) => {
  const [hiding, setHiding]         = useState(false);
  const [mounted, setMounted]       = useState(false);
  const [enabled, setEnabled]       = useState(false);
  const [frequency, setFrequency]   = useState<number | null>(null);
  const [volume, setVolume]         = useState(80);
  const [micClicks, setMicClicks]   = useState(true);
  const [freqInput, setFreqInput]   = useState('');
  const [freqError, setFreqError]   = useState('');
  const [connecting, setConnecting] = useState(false);
  const [txActive, setTxActive]     = useState(false);   // transmit indicator flash
  const freqInputRef = useRef<HTMLInputElement>(null);
  const txTimerRef   = useRef<ReturnType<typeof setTimeout> | null>(null);

  /* ---- mount / unmount animation ---- */
  useEffect(() => {
    if (visible && !hiding) {
      setMounted(true);
      setTimeout(() => { window.focus(); document.body.focus(); }, 30);
    }
    if (!visible) setMounted(false);
  }, [visible, hiding]);

  /* ---- NUI messages ---- */
  useEffect(() => {
    const h = (e: MessageEvent) => {
      const { action, data } = e.data;
      if (action === 'radio:setState' && data) {
        if (data.enabled   !== undefined) setEnabled(data.enabled);
        if (data.frequency !== undefined) setFrequency(data.frequency);
        if (data.volume    !== undefined) setVolume(data.volume);
        if (data.micClicks !== undefined) setMicClicks(data.micClicks);
      }
      if (action === 'radio:connectResult') {
        setConnecting(false);
        if (data?.success) {
          setFrequency(data.frequency);
          setEnabled(true);
          setFreqInput('');
          setFreqError('');
          soundManager.play('success');
          flashTx();
        } else {
          setFreqError(data?.error || 'Fréquence invalide');
        }
      }
    };
    window.addEventListener('message', h);
    return () => window.removeEventListener('message', h);
  }, []);

  /* ---- ESC to close ---- */
  useEffect(() => {
    if (!visible || hiding) return;
    const h = (e: KeyboardEvent) => { if (e.key === 'Escape') handleClose(); };
    window.addEventListener('keydown', h);
    return () => window.removeEventListener('keydown', h);
  }, [visible, hiding]);

  const flashTx = () => {
    setTxActive(true);
    if (txTimerRef.current) clearTimeout(txTimerRef.current);
    txTimerRef.current = setTimeout(() => setTxActive(false), 800);
  };

  const handleClose = useCallback(() => {
    if (hiding) return;
    setHiding(true);
    setMounted(false);
    soundManager.play('close');
    setTimeout(() => { setHiding(false); onClose(); nuiCallback('radio:close'); }, 300);
  }, [onClose, hiding]);

  const handlePower = useCallback(() => {
    const next = !enabled;
    setEnabled(next);
    nuiCallback('radio:toggle', { enabled: next });
    soundManager.play('click');
    if (!next) { setFrequency(null); }
  }, [enabled]);

  const handleConnect = useCallback(() => {
    const freq = parseInt(freqInput);
    if (!freq || freq <= 0 || freq > 999) { setFreqError('1 – 999'); return; }
    setConnecting(true);
    setFreqError('');
    nuiCallback('radio:connect', { frequency: freq });
  }, [freqInput]);

  const handleDisconnect = useCallback(() => {
    setFrequency(null);
    nuiCallback('radio:disconnect');
    soundManager.play('click');
  }, []);

  const handleVolume = useCallback((e: React.ChangeEvent<HTMLInputElement>) => {
    const v = parseInt(e.target.value);
    setVolume(v);
    nuiCallback('radio:setVolume', { volume: v / 100 });
  }, []);

  const handleMicClicks = useCallback(() => {
    const next = !micClicks;
    setMicClicks(next);
    nuiCallback('radio:toggleMicClicks', { enabled: next });
    soundManager.play('click');
  }, [micClicks]);

  if (!visible && !hiding) return null;

  const wrapClass = hiding ? 'rw-hiding' : mounted ? 'rw-visible' : 'rw-hidden';

  /* ---- knob rotation helper ---- */
  const volDeg = Math.round((volume / 100) * 270 - 135); // -135° → +135°

  return (
    <div className={`rw-wrap ${wrapClass}`}>
      <div className="rw-body">

        {/* ── ANTENNA ── */}
        <div className="rw-antenna" />

        {/* ── TOP STRIP: brand + LED ── */}
        <div className="rw-top-strip">
          <span className="rw-brand">MOTOROLA</span>
          <div className={`rw-led ${enabled ? (txActive ? 'rw-led-tx' : 'rw-led-rx') : ''}`} />
        </div>

        {/* ── LCD DISPLAY ── */}
        <div className="rw-lcd">
          <div className="rw-lcd-inner">
            {enabled ? (
              frequency
                ? <><span className="rw-lcd-label">CH</span><span className="rw-lcd-freq">{String(frequency).padStart(3, '0')}</span><span className="rw-lcd-unit">MHz</span></>
                : <span className="rw-lcd-scan">-- . -- MHz</span>
            ) : (
              <span className="rw-lcd-off">· · ·</span>
            )}
          </div>
          {enabled && frequency && <div className="rw-lcd-bars"><span /><span /><span /><span /></div>}
        </div>

        {/* ── SIDE BUTTONS ── */}
        <div className="rw-side-btns">
          <button
            className={`rw-side-btn rw-ptt ${enabled && frequency ? 'rw-ptt-ready' : ''}`}
            title="Push to Talk"
            onMouseDown={() => { if (enabled && frequency) { flashTx(); soundManager.play('click'); } }}
          >PTT</button>
        </div>

        {/* ── VOLUME KNOB ── */}
        <div className="rw-knob-row">
          <div className="rw-knob-label">VOL</div>
          <div
            className="rw-knob"
            style={{ '--knob-deg': `${volDeg}deg` } as React.CSSProperties}
            title={`Volume: ${volume}%`}
          >
            <div className="rw-knob-mark" />
          </div>
          <input
            type="range"
            className="rw-vol-slider"
            min={0} max={100}
            value={volume}
            onChange={handleVolume}
            title={`${volume}%`}
          />
        </div>

        {/* ── MAIN BUTTONS GRID ── */}
        <div className="rw-btns">
          {/* Power */}
          <button
            className={`rw-btn rw-btn-power ${enabled ? 'rw-btn-on' : ''}`}
            onClick={handlePower}
            title={enabled ? 'Éteindre' : 'Allumer'}
          >
            <span className="rw-btn-icon">⏻</span>
            <span className="rw-btn-label">{enabled ? 'OFF' : 'ON'}</span>
          </button>

          {/* Mic clicks toggle */}
          <button
            className={`rw-btn ${micClicks ? 'rw-btn-active' : ''}`}
            onClick={handleMicClicks}
            title="Bruitages radio"
          >
            <span className="rw-btn-icon">🔔</span>
            <span className="rw-btn-label">BIPS</span>
          </button>

          {/* Close */}
          <button className="rw-btn rw-btn-close" onClick={handleClose} title="Fermer">
            <span className="rw-btn-icon">✕</span>
            <span className="rw-btn-label">MENU</span>
          </button>
        </div>

        {/* ── FREQUENCY INPUT ── */}
        {enabled && (
          <div className="rw-freq-zone">
            {frequency ? (
              <div className="rw-freq-active">
                <span className="rw-freq-active-label">Canal {frequency} MHz</span>
                <button className="rw-freq-clr" onClick={handleDisconnect} title="Déconnecter">CLR</button>
              </div>
            ) : (
              <div className="rw-freq-input-row">
                <input
                  ref={freqInputRef}
                  type="number"
                  className="rw-freq-input"
                  placeholder="_ _ _"
                  value={freqInput}
                  onChange={e => { setFreqInput(e.target.value); setFreqError(''); }}
                  onKeyDown={e => { if (e.key === 'Enter') handleConnect(); }}
                  onFocus={() => nuiCallback('radio:inputFocus')}
                  onBlur={() => nuiCallback('radio:inputBlur')}
                  min={1} max={999}
                />
                <button
                  className="rw-freq-ok"
                  onClick={handleConnect}
                  disabled={connecting}
                >
                  {connecting ? '…' : 'OK'}
                </button>
              </div>
            )}
            {freqError && <div className="rw-freq-err">{freqError}</div>}
          </div>
        )}

        {/* ── SPEAKER GRILLE ── */}
        <div className="rw-speaker">
          {Array.from({ length: 24 }).map((_, i) => <div key={i} className="rw-speaker-dot" />)}
        </div>

        {/* ── BOTTOM LABEL ── */}
        <div className="rw-bottom-label">GP380 · UHF</div>

      </div>
    </div>
  );
};

export default Radio;
