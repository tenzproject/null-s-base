import React, { useCallback, useEffect, useMemo, useState } from 'react';
import {
  Activity,
  AlertTriangle,
  Check,
  ChevronRight,
  Clock3,
  Coins,
  ExternalLink,
  Flag,
  Globe2,
  HeartPulse,
  Image,
  LayoutDashboard,
  Link2,
  Palette,
  RefreshCw,
  Save,
  ServerCog,
  Shield,
  Store,
  Users,
  WalletCards,
  X,
} from 'lucide-react';
import './PanelAdmin.css';

type PanelSection = 'dashboard' | 'config';

interface ServerConfig {
  serverName: string;
  serverColor: string;
  jsColor: string;
  serverCHAR: string;
  discordAPI: string;
  boutiqueLink: string;
  serverDiscord: string;
  serverDiscord2: string;
  r: string;
  g: string;
  b: string;
  hexcolor: string;
  backgroundBanner: string;
}

interface DashboardMetrics {
  uniquePlayers: number;
  connectedPlayers: number;
  policeOnline: number;
  emsOnline: number;
  pendingReports: number;
  activeReports: number;
  totalReports: number;
  playersLast24h: number;
  money: { cash: number; bank: number; illegal: number };
  updatedAt?: number;
}

interface PanelAdminProps {
  visible: boolean;
  onClose: () => void;
  primaryColor?: string;
  serverConfig?: { serverName: string; serverIcon: string; serverBackground: string };
}

const EMPTY_METRICS: DashboardMetrics = {
  uniquePlayers: 0,
  connectedPlayers: 0,
  policeOnline: 0,
  emsOnline: 0,
  pendingReports: 0,
  activeReports: 0,
  totalReports: 0,
  playersLast24h: 0,
  money: { cash: 0, bank: 0, illegal: 0 },
};

const EMPTY_CONFIG: ServerConfig = {
  serverName: '',
  serverColor: '~g~',
  jsColor: '^2',
  serverCHAR: '',
  discordAPI: '',
  boutiqueLink: '',
  serverDiscord: '',
  serverDiscord2: '',
  r: '190',
  g: '238',
  b: '17',
  hexcolor: '#BEEE11',
  backgroundBanner: '',
};

const fetchNui = async (endpoint: string, body: unknown = {}) => {
  const response = await fetch(`https://null-core/${endpoint}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(body),
  });
  return response.json();
};

const notifyParentBridge = (action: 'panelAdmin:open' | 'panelAdmin:close') => {
  if (window.parent !== window) window.parent.postMessage({ action }, '*');
};

const formatMoney = (value: number) => `${new Intl.NumberFormat('fr-FR').format(Math.round(value || 0))}$`;
const formatNumber = (value: number) => new Intl.NumberFormat('fr-FR').format(Math.round(value || 0));

const normalizeHex = (value: string) => {
  const normalized = value.trim().toUpperCase();
  return /^#[0-9A-F]{6}$/.test(normalized) ? normalized : '#BEEE11';
};

const PanelAdmin: React.FC<PanelAdminProps> = ({ visible, onClose, primaryColor, serverConfig }) => {
  const [section, setSection] = useState<PanelSection>('dashboard');
  const [metrics, setMetrics] = useState<DashboardMetrics>(EMPTY_METRICS);
  const [config, setConfig] = useState<ServerConfig>(EMPTY_CONFIG);
  const [draft, setDraft] = useState<ServerConfig>(EMPTY_CONFIG);
  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);
  const [canEditConfig, setCanEditConfig] = useState(true);
  const [error, setError] = useState('');
  const [saved, setSaved] = useState(false);

  const accentStyle = useMemo(() => ({ '--panel-accent': primaryColor || 'var(--accent)' } as React.CSSProperties), [primaryColor]);

  const closePanel = useCallback(() => {
    fetchNui('paneladmin:close').catch(() => undefined);
    notifyParentBridge('panelAdmin:close');
    onClose();
  }, [onClose]);

  const loadData = useCallback(async (silent = false) => {
    if (!silent) setLoading(true);
    try {
      const response = await fetchNui('paneladmin:getData');
      if (!response?.ok) {
        setError(response?.error || 'Accès refusé.');
        return;
      }
      setMetrics({ ...EMPTY_METRICS, ...(response.metrics || {}), money: { ...EMPTY_METRICS.money, ...(response.metrics?.money || {}) } });
      if (response.config) {
        setConfig(response.config);
        setDraft(current => (saving ? current : response.config));
      }
      // L'édition du Panel Admin est volontairement ouverte sans permission.
      setCanEditConfig(true);
      setError('');
    } catch {
      setError('Le panneau ne peut pas joindre le serveur.');
    } finally {
      if (!silent) setLoading(false);
    }
  }, [saving]);

  useEffect(() => {
    if (!visible) return undefined;
    // Réactive les clics de l'iframe parent dès que le panel est monté.
    notifyParentBridge('panelAdmin:open');
    loadData();
    const interval = window.setInterval(() => loadData(true), 5000);
    return () => {
      window.clearInterval(interval);
      notifyParentBridge('panelAdmin:close');
    };
  }, [visible, loadData]);

  useEffect(() => {
    if (!visible) return undefined;
    const handleEscape = (event: KeyboardEvent) => {
      if (event.key === 'Escape') {
        event.preventDefault();
        event.stopPropagation();
        closePanel();
      }
    };
    window.addEventListener('keydown', handleEscape);
    return () => window.removeEventListener('keydown', handleEscape);
  }, [visible, closePanel]);

  useEffect(() => {
    const handleMessage = (event: MessageEvent) => {
      if (event.data?.action !== 'panelAdmin:configUpdated' || !event.data.data) return;
      const next = { ...EMPTY_CONFIG, ...event.data.data };
      setConfig(next);
      setDraft(next);
    };
    window.addEventListener('message', handleMessage);
    return () => window.removeEventListener('message', handleMessage);
  }, []);

  if (!visible) return null;

  const updateDraft = (key: keyof ServerConfig, value: string) => {
    setSaved(false);
    setDraft(current => ({ ...current, [key]: value }));
  };

  const updateHex = (value: string) => {
    const hex = normalizeHex(value);
    const red = parseInt(hex.slice(1, 3), 16).toString();
    const green = parseInt(hex.slice(3, 5), 16).toString();
    const blue = parseInt(hex.slice(5, 7), 16).toString();
    setSaved(false);
    setDraft(current => ({ ...current, hexcolor: value.toUpperCase(), r: red, g: green, b: blue }));
  };

  const saveConfig = async () => {
    setSaving(true);
    setSaved(false);
    try {
      await fetchNui('paneladmin:updateConfig', draft);
      setConfig(draft);
      setSaved(true);
      window.setTimeout(() => setSaved(false), 2600);
    } catch {
      setError('Impossible d’appliquer la configuration.');
    } finally {
      setSaving(false);
    }
  };

  const statCards = [
    { label: 'Joueurs uniques', value: formatNumber(metrics.uniquePlayers), hint: 'Comptes connus', icon: Users, tone: 'blue' },
    { label: 'Connectés maintenant', value: formatNumber(metrics.connectedPlayers), hint: 'Sessions actives', icon: Activity, tone: 'green' },
    { label: 'Police en ville', value: formatNumber(metrics.policeOnline), hint: 'Unités disponibles', icon: Shield, tone: 'blue' },
    { label: 'EMS en ville', value: formatNumber(metrics.emsOnline), hint: 'Soignants disponibles', icon: HeartPulse, tone: 'red' },
    { label: 'Reports en attente', value: formatNumber(metrics.pendingReports), hint: `${formatNumber(metrics.activeReports)} reports actifs`, icon: Flag, tone: 'orange' },
    { label: 'Reports depuis le début', value: formatNumber(metrics.totalReports), hint: 'Historique global', icon: Globe2, tone: 'purple' },
    { label: 'Joueurs sur 24 h', value: formatNumber(metrics.playersLast24h), hint: 'Dernière connexion', icon: Clock3, tone: 'cyan' },
  ];

  return (
    <div className="paneladmin-overlay" style={accentStyle} onKeyDownCapture={event => {
      if (event.key === 'Escape') {
        event.preventDefault();
        event.stopPropagation();
        closePanel();
      }
    }}>
      <section className="paneladmin-shell" role="dialog" aria-modal="true" aria-label="Panel admin">
        <aside className="paneladmin-sidebar">
          <div className="paneladmin-brand">
            <div className="paneladmin-brand-mark"><ServerCog size={20} /></div>
            <div>
              <strong>Panel Admin</strong>
              <span>Centre de contrôle</span>
            </div>
          </div>

          <div className="paneladmin-nav-label">Administration</div>
          <nav className="paneladmin-nav">
            <button className={section === 'dashboard' ? 'is-active' : ''} onClick={() => setSection('dashboard')}>
              <LayoutDashboard size={17} /> <span>Dashboard</span><ChevronRight size={15} />
            </button>
            <button className={section === 'config' ? 'is-active' : ''} onClick={() => setSection('config')}>
              <ServerCog size={17} /> <span>Configuration serveur</span><ChevronRight size={15} />
            </button>
          </nav>

          <div className="paneladmin-sidebar-foot">
            <div className="paneladmin-live"><i /> Système en ligne</div>
            <button className="paneladmin-close" onClick={closePanel}><X size={16} /> Fermer</button>
          </div>
        </aside>

        <main className="paneladmin-main">
          <header className="paneladmin-header">
            <div>
              <div className="paneladmin-kicker">NULL'S BASE / ADMINISTRATION</div>
              <h1>{section === 'dashboard' ? 'Vue d’ensemble' : 'Configuration serveur'}</h1>
              <p>{section === 'dashboard' ? 'Surveillez l’activité et l’économie de la ville en temps réel.' : 'Modifiez l’identité et les liens globaux du serveur.'}</p>
            </div>
            <div className="paneladmin-header-actions">
              {section === 'dashboard' && <button className="paneladmin-icon-button" onClick={() => loadData()} title="Actualiser"><RefreshCw size={17} className={loading ? 'is-spinning' : ''} /></button>}
              {section === 'config' && <button className="paneladmin-save" onClick={saveConfig} disabled={!canEditConfig || saving}><Save size={16} /> {saving ? 'Application…' : saved ? 'Appliqué' : 'Appliquer'}</button>}
              <button className="paneladmin-icon-button" onClick={closePanel} title="Fermer"><X size={17} /></button>
            </div>
          </header>

          {error && <div className="paneladmin-alert"><AlertTriangle size={16} /> {error}</div>}

          {section === 'dashboard' ? (
            <div className="paneladmin-content paneladmin-dashboard">
              <div className="paneladmin-server-strip">
                <div className="paneladmin-server-dot" />
                <div><span>Serveur actif</span><strong>{config.serverName || serverConfig?.serverName || 'Null\'s Base'}</strong></div>
                <div className="paneladmin-updated">Actualisation automatique · 5 s</div>
              </div>

              <div className="paneladmin-section-heading"><div><span className="paneladmin-kicker">ACTIVITÉ</span><h2>État de la ville</h2></div><span className="paneladmin-status"><i /> EN DIRECT</span></div>
              <div className="paneladmin-stat-grid">
                {statCards.map(({ label, value, hint, icon: Icon, tone }) => <div className={`paneladmin-stat tone-${tone}`} key={label}><div className="paneladmin-stat-top"><div className="paneladmin-stat-icon"><Icon size={18} /></div><span>{hint}</span></div><strong>{value}</strong><label>{label}</label></div>)}
              </div>

              <div className="paneladmin-section-heading"><div><span className="paneladmin-kicker">ÉCONOMIE</span><h2>Argent en circulation</h2></div></div>
              <div className="paneladmin-money-grid">
                <div className="paneladmin-money-card"><div className="paneladmin-money-icon cash"><WalletCards size={18} /></div><div><span>Cash</span><strong>{formatMoney(metrics.money.cash)}</strong></div></div>
                <div className="paneladmin-money-card"><div className="paneladmin-money-icon bank"><Coins size={18} /></div><div><span>Banque</span><strong>{formatMoney(metrics.money.bank)}</strong></div></div>
                <div className="paneladmin-money-card"><div className="paneladmin-money-icon illegal"><AlertTriangle size={18} /></div><div><span>Argent illégal</span><strong>{formatMoney(metrics.money.illegal)}</strong></div></div>
              </div>

              <div className="paneladmin-footnote"><Activity size={14} /> Données calculées côté serveur · mise à jour {metrics.updatedAt ? new Date(metrics.updatedAt * 1000).toLocaleTimeString('fr-FR') : 'en attente'}</div>
            </div>
          ) : (
            <div className="paneladmin-content paneladmin-config">
              {!canEditConfig && <div className="paneladmin-permission"><AlertTriangle size={17} /><div><strong>Lecture seule</strong><span>Votre grade ne permet pas de modifier les variables serveur.</span></div></div>}

              <ConfigGroup icon={<Globe2 size={17} />} title="Identité du serveur" description="Nom et codes de couleur utilisés par le core.">
                <div className="paneladmin-fields two"><Field label="Nom du serveur" value={draft.serverName} onChange={value => updateDraft('serverName', value)} disabled={!canEditConfig} /></div>
                <div className="paneladmin-fields three"><Field label="Couleur GTA" value={draft.serverColor} onChange={value => updateDraft('serverColor', value)} disabled={!canEditConfig} hint="serverColor" /><Field label="Couleur JS" value={draft.jsColor} onChange={value => updateDraft('jsColor', value)} disabled={!canEditConfig} hint="jsColor" /><Field label="Logo du serveur" value={draft.serverCHAR} onChange={value => updateDraft('serverCHAR', value)} disabled={!canEditConfig} hint="URL" /></div>
              </ConfigGroup>

              <ConfigGroup icon={<Link2 size={17} />} title="Liens publics" description="Les deux liens Discord sont regroupés ici pour une édition rapide.">
                <div className="paneladmin-fields two"><Field label="Lien du Discord" value={draft.serverDiscord} onChange={value => updateDraft('serverDiscord', value)} disabled={!canEditConfig} icon={<ExternalLink size={14} />} /><Field label="Lien du Discord secondaire" value={draft.serverDiscord2} onChange={value => updateDraft('serverDiscord2', value)} disabled={!canEditConfig} icon={<ExternalLink size={14} />} /></div>
                <div className="paneladmin-fields two"><Field label="Lien de la boutique" value={draft.boutiqueLink} onChange={value => updateDraft('boutiqueLink', value)} disabled={!canEditConfig} icon={<Store size={14} />} /><Field label="API Discord / identifiant" value={draft.discordAPI} onChange={value => updateDraft('discordAPI', value)} disabled={!canEditConfig} icon={<Link2 size={14} />} /></div>
              </ConfigGroup>

              <ConfigGroup icon={<Palette size={17} />} title="Couleur globale" description="La couleur hexadécimale pilote l’accent de toute la lib en temps réel.">
                <div className="paneladmin-color-row"><input type="color" value={normalizeHex(draft.hexcolor)} onChange={event => updateHex(event.target.value)} disabled={!canEditConfig} /><Field label="Couleur hex" value={draft.hexcolor} onChange={updateHex} disabled={!canEditConfig} hint="hexcolor" /><Field label="R" value={draft.r} onChange={value => updateDraft('r', value)} disabled={!canEditConfig} /><Field label="G" value={draft.g} onChange={value => updateDraft('g', value)} disabled={!canEditConfig} /><Field label="B" value={draft.b} onChange={value => updateDraft('b', value)} disabled={!canEditConfig} /></div>
              </ConfigGroup>

              <ConfigGroup icon={<Image size={17} />} title="Bannière globale" description="Cette image est envoyée à toute la session dès l’application de la configuration.">
                <Field label="URL de la bannière" value={draft.backgroundBanner} onChange={value => updateDraft('backgroundBanner', value)} disabled={!canEditConfig} icon={<Image size={14} />} />
              </ConfigGroup>

              <div className="paneladmin-config-note"><Check size={15} /> Les modifications sont appliquées avec <code>setr</code>, propagées immédiatement et sauvegardées dans <code>cache/paneladmin-config.json</code> pour être restaurées après redémarrage.</div>
            </div>
          )}
        </main>
      </section>
    </div>
  );
};

const ConfigGroup: React.FC<{ icon: React.ReactNode; title: string; description: string; children: React.ReactNode }> = ({ icon, title, description, children }) => (
  <section className="paneladmin-config-group"><div className="paneladmin-group-title"><div className="paneladmin-group-icon">{icon}</div><div><h2>{title}</h2><p>{description}</p></div></div>{children}</section>
);

const Field: React.FC<{ label: string; value: string; onChange: (value: string) => void; disabled?: boolean; hint?: string; icon?: React.ReactNode }> = ({ label, value, onChange, disabled, hint, icon }) => (
  <label className="paneladmin-field"><span>{icon}{label}{hint && <em>{hint}</em>}</span><input type="text" autoComplete="off" value={value ?? ''} onChange={event => onChange(event.target.value)} onMouseDown={event => event.stopPropagation()} onClick={event => event.stopPropagation()} disabled={disabled} /></label>
);

export default PanelAdmin;
