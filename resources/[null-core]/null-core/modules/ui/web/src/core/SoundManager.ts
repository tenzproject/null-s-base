/**
 * SoundManager - GTA V RageUI Style Sound System
 *
 * Procedural recreation of GTA V's characteristic RageUI sounds.
 * Uses Web Audio API — no external files needed.
 *
 * GTA V RageUI sound profiles:
 *  - navigate : short metallic tick (menu up/down)
 *  - hover    : very soft version of navigate
 *  - click    : deeper, fuller click (confirm/select)
 *  - back     : softer reversed click
 *  - open     : panel whoosh in
 *  - close    : panel whoosh out
 *  - success  : classic GTA two-tone ascending bip
 *  - error    : short buzzy low-frequency distortion
 *  - warning  : single mid buzz
 *  - notification : the iconic GTA phone ding
 *  - toggle   : mechanical switch click
 *  - slider   : subtle value-change tick
 *  - pickup   : inventory item pickup chirp
 *  - drop     : soft thud
 */

type SoundName =
  | 'hover'
  | 'click'
  | 'select'
  | 'back'
  | 'navigate'
  | 'open'
  | 'close'
  | 'success'
  | 'error'
  | 'warning'
  | 'notification'
  | 'toggle'
  | 'slider'
  | 'type'
  | 'drop'
  | 'pickup';

class SoundManager {
  private ctx: AudioContext | null = null;
  private masterGain: GainNode | null = null;
  private _volume: number = 0.22;
  private _enabled: boolean = true;

  private ensureContext(): AudioContext {
    if (!this.ctx) {
      this.ctx = new (window.AudioContext || (window as any).webkitAudioContext)();
      this.masterGain = this.ctx.createGain();
      this.masterGain.gain.value = this._volume;
      this.masterGain.connect(this.ctx.destination);
    }
    if (this.ctx.state === 'suspended') this.ctx.resume();
    return this.ctx;
  }

  setVolume(vol: number) {
    this._volume = Math.max(0, Math.min(1, vol));
    if (this.masterGain) this.masterGain.gain.value = this._volume;
  }
  getVolume(): number { return this._volume; }
  setEnabled(e: boolean) { this._enabled = e; }
  isEnabled(): boolean { return this._enabled; }

  play(name: SoundName) {
    if (!this._enabled) return;
    try {
      const ctx = this.ensureContext();
      const t = ctx.currentTime;
      switch (name) {
        case 'hover':        this.playHover(ctx, t);        break;
        case 'click':
        case 'select':       this.playClick(ctx, t);        break;
        case 'back':         this.playBack(ctx, t);         break;
        case 'navigate':     this.playNavigate(ctx, t);     break;
        case 'open':         this.playOpen(ctx, t);         break;
        case 'close':        this.playClose(ctx, t);        break;
        case 'success':      this.playSuccess(ctx, t);      break;
        case 'error':        this.playError(ctx, t);        break;
        case 'warning':      this.playWarning(ctx, t);      break;
        case 'notification': this.playNotification(ctx, t); break;
        case 'toggle':       this.playToggle(ctx, t);       break;
        case 'slider':       this.playSlider(ctx, t);       break;
        case 'type':         this.playType(ctx, t);         break;
        case 'drop':         this.playDrop(ctx, t);         break;
        case 'pickup':       this.playPickup(ctx, t);       break;
      }
    } catch (_) { /* never break the UI */ }
  }

  // ─── Internal helpers ──────────────────────────────────────────

  /**
   * GTA RageUI uses a distinctive "clicky" oscillator shape —
   * a mix of square-wave body with a sine fundamental.
   * We simulate this with layered oscillators + highpass + lowpass.
   */
  private rageClick(
    ctx: AudioContext, t: number,
    freq: number, duration: number, vol: number,
    squareVol = 0.3
  ) {
    const master = this.masterGain!;

    // ── Sine body (fundamental tone)
    const sine = ctx.createOscillator();
    const sineGain = ctx.createGain();
    sine.type = 'sine';
    sine.frequency.value = freq;
    sineGain.gain.setValueAtTime(0, t);
    sineGain.gain.linearRampToValueAtTime(vol, t + 0.003);
    sineGain.gain.exponentialRampToValueAtTime(0.0001, t + duration);
    sine.connect(sineGain);
    sineGain.connect(master);
    sine.start(t);
    sine.stop(t + duration + 0.01);

    // ── Square "bite" (adds the metallic crispness)
    if (squareVol > 0) {
      const sq = ctx.createOscillator();
      const sqGain = ctx.createGain();
      const sqHp = ctx.createBiquadFilter();
      sqHp.type = 'highpass';
      sqHp.frequency.value = freq * 1.5;
      sq.type = 'square';
      sq.frequency.value = freq;
      sqGain.gain.setValueAtTime(0, t);
      sqGain.gain.linearRampToValueAtTime(vol * squareVol, t + 0.002);
      sqGain.gain.exponentialRampToValueAtTime(0.0001, t + duration * 0.35);
      sq.connect(sqHp);
      sqHp.connect(sqGain);
      sqGain.connect(master);
      sq.start(t);
      sq.stop(t + duration * 0.5 + 0.01);
    }
  }

  /** Noise burst — used for GTA's papery/hiss transients */
  private noiseBurst(ctx: AudioContext, t: number, duration: number, vol: number, hiFreq = 4000) {
    const bufSize = ctx.sampleRate * duration;
    const buf = ctx.createBuffer(1, bufSize, ctx.sampleRate);
    const data = buf.getChannelData(0);
    for (let i = 0; i < bufSize; i++) data[i] = Math.random() * 2 - 1;

    const src = ctx.createBufferSource();
    src.buffer = buf;

    const hp = ctx.createBiquadFilter();
    hp.type = 'bandpass';
    hp.frequency.value = hiFreq;
    hp.Q.value = 1.2;

    const g = ctx.createGain();
    g.gain.setValueAtTime(vol, t);
    g.gain.exponentialRampToValueAtTime(0.0001, t + duration);

    src.connect(hp);
    hp.connect(g);
    g.connect(this.masterGain!);
    src.start(t);
    src.stop(t + duration + 0.01);
  }

  /** Sweep tone for whooshes */
  private sweep(ctx: AudioContext, t: number, f0: number, f1: number, dur: number, vol: number) {
    const osc = ctx.createOscillator();
    const g = ctx.createGain();
    const lp = ctx.createBiquadFilter();
    lp.type = 'lowpass';
    lp.frequency.value = Math.max(f0, f1) * 1.8;
    osc.type = 'sine';
    osc.frequency.setValueAtTime(f0, t);
    osc.frequency.exponentialRampToValueAtTime(f1, t + dur * 0.75);
    g.gain.setValueAtTime(0, t);
    g.gain.linearRampToValueAtTime(vol, t + 0.008);
    g.gain.exponentialRampToValueAtTime(0.0001, t + dur);
    osc.connect(lp);
    lp.connect(g);
    g.connect(this.masterGain!);
    osc.start(t);
    osc.stop(t + dur + 0.01);
  }

  // ─── GTA V RageUI Sounds ───────────────────────────────────────

  /**
   * Hover → very subtle tick, barely audible
   * GTA: like a faint menu cursor movement
   */
  private playHover(ctx: AudioContext, t: number) {
    this.rageClick(ctx, t, 1200, 0.028, 0.055, 0.15);
    this.noiseBurst(ctx, t, 0.015, 0.018, 5000);
  }

  /**
   * Navigate → the characteristic RageUI menu tick
   * GTA: crisp, short, metallic — heard when scrolling menus
   */
  private playNavigate(ctx: AudioContext, t: number) {
    this.rageClick(ctx, t, 1400, 0.04, 0.10, 0.25);
    this.noiseBurst(ctx, t, 0.02, 0.03, 5500);
  }

  /**
   * Click/Select → heavier confirm click
   * GTA: deeper, fuller sound, like pressing Enter in a menu
   */
  private playClick(ctx: AudioContext, t: number) {
    this.rageClick(ctx, t, 900, 0.055, 0.12, 0.20);
    this.rageClick(ctx, t + 0.008, 1300, 0.03, 0.06, 0.10);
    this.noiseBurst(ctx, t, 0.025, 0.04, 4500);
  }

  /**
   * Back → softer cancel, slightly lower pitched
   * GTA: like click but reversed feel
   */
  private playBack(ctx: AudioContext, t: number) {
    this.rageClick(ctx, t, 700, 0.05, 0.09, 0.12);
    this.noiseBurst(ctx, t, 0.02, 0.025, 3500);
  }

  /**
   * Open → panel slide-in whoosh
   * GTA: subtle sweep upward as menu appears
   */
  private playOpen(ctx: AudioContext, t: number) {
    this.sweep(ctx, t, 300, 700, 0.10, 0.07);
    this.noiseBurst(ctx, t + 0.05, 0.04, 0.03, 6000);
    this.rageClick(ctx, t + 0.07, 1100, 0.03, 0.05, 0.10);
  }

  /**
   * Close → panel slide-out whoosh
   * GTA: sweep downward as menu disappears
   */
  private playClose(ctx: AudioContext, t: number) {
    this.sweep(ctx, t, 600, 280, 0.09, 0.06);
    this.noiseBurst(ctx, t, 0.03, 0.025, 4000);
  }

  /**
   * Success → the classic GTA two-bip confirmation
   * GTA: C5 → E5, bright and clean — "mission passed" feel
   */
  private playSuccess(ctx: AudioContext, t: number) {
    // First bip
    this.rageClick(ctx, t, 523, 0.12, 0.09, 0.08);
    // Second bip — higher
    this.rageClick(ctx, t + 0.11, 659, 0.16, 0.09, 0.08);
  }

  /**
   * Error → the classic RageUI buzz
   * GTA: short, low, distorted square buzz — "wamp"
   */
  private playError(ctx: AudioContext, t: number) {
    const osc = ctx.createOscillator();
    const dist = ctx.createWaveShaper();
    const g = ctx.createGain();
    const lp = ctx.createBiquadFilter();

    // Distortion curve (clipping)
    const curve = new Float32Array(256);
    for (let i = 0; i < 256; i++) {
      const x = (i * 2) / 256 - 1;
      curve[i] = (3 + 40) * x / (Math.PI + 40 * Math.abs(x));
    }
    dist.curve = curve;

    lp.type = 'lowpass';
    lp.frequency.value = 400;

    osc.type = 'square';
    osc.frequency.setValueAtTime(160, t);
    osc.frequency.linearRampToValueAtTime(120, t + 0.12);

    g.gain.setValueAtTime(0, t);
    g.gain.linearRampToValueAtTime(0.12, t + 0.005);
    g.gain.setValueAtTime(0.12, t + 0.06);
    g.gain.exponentialRampToValueAtTime(0.0001, t + 0.14);

    osc.connect(dist);
    dist.connect(lp);
    lp.connect(g);
    g.connect(this.masterGain!);
    osc.start(t);
    osc.stop(t + 0.15);
  }

  /**
   * Warning → mid-range buzz pulse
   */
  private playWarning(ctx: AudioContext, t: number) {
    this.rageClick(ctx, t, 380, 0.11, 0.08, 0.30);
    this.noiseBurst(ctx, t + 0.01, 0.06, 0.04, 2000);
  }

  /**
   * Notification → GTA phone "ding" — iconic single clean bip
   * GTA: clear bell-like tone
   */
  private playNotification(ctx: AudioContext, t: number) {
    // Bell-like: sine + octave harmonic fade in
    const bell = (freq: number, delay: number) => {
      const osc = ctx.createOscillator();
      const g = ctx.createGain();
      osc.type = 'sine';
      osc.frequency.value = freq;
      g.gain.setValueAtTime(0, t + delay);
      g.gain.linearRampToValueAtTime(0.10, t + delay + 0.005);
      g.gain.exponentialRampToValueAtTime(0.0001, t + delay + 0.35);
      osc.connect(g);
      g.connect(this.masterGain!);
      osc.start(t + delay);
      osc.stop(t + delay + 0.36);
    };
    bell(880, 0);
    bell(1760, 0.005); // octave — gives the "shimmer"
    // Second note
    bell(1174, 0.14);
    bell(2349, 0.145);
  }

  /**
   * Toggle → mechanical switch — checkbox on/off
   */
  private playToggle(ctx: AudioContext, t: number) {
    this.rageClick(ctx, t, 1100, 0.04, 0.09, 0.35);
    this.noiseBurst(ctx, t, 0.018, 0.03, 5000);
  }

  /**
   * Slider → subtle value change tick
   */
  private playSlider(ctx: AudioContext, t: number) {
    this.rageClick(ctx, t, 1600, 0.022, 0.06, 0.12);
  }

  /**
   * Type → micro keyboard tap
   */
  private playType(ctx: AudioContext, t: number) {
    const f = 1000 + Math.random() * 300;
    this.rageClick(ctx, t, f, 0.018, 0.04, 0.20);
    this.noiseBurst(ctx, t, 0.012, 0.015, 4000);
  }

  /**
   * Pickup → item pickup chirp (inventory)
   * GTA: quick ascending chirp
   */
  private playPickup(ctx: AudioContext, t: number) {
    this.sweep(ctx, t, 600, 1200, 0.06, 0.07);
    this.noiseBurst(ctx, t + 0.02, 0.02, 0.03, 5000);
  }

  /**
   * Drop → soft item thud
   */
  private playDrop(ctx: AudioContext, t: number) {
    this.sweep(ctx, t, 350, 150, 0.08, 0.08);
    this.noiseBurst(ctx, t, 0.03, 0.04, 2500);
  }
}

export const soundManager = new SoundManager();
export type { SoundName };
