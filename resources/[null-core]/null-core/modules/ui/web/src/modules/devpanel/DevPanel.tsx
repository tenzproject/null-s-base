import React, { useState, useEffect, useCallback, useMemo } from 'react';
import { generateAccentVars } from '@/utils/accentColors';
import {
  X, Code, Zap, Play, Server, Monitor, ChevronRight,
  Terminal, Send, Search, RefreshCw, Trash2, Copy, Plus,
  Minus, ToggleLeft, ToggleRight, Package, Activity,
  Heart, Shirt, MapPin, Crosshair, Ghost, EyeOff,
  User, Clock, CheckCircle, XCircle, ArrowUp, ArrowDown,
  Boxes, Settings, Cpu, Database, Hash, Map, Move, ArrowRight, SlidersHorizontal
} from 'lucide-react';
import { DevPanelConfig, DevPanelPage, ExecutionResult, ResourceInfo, ScannedEvent, TriggerArg, QuickAction, Bob74IplEntry, Bob74IplOption } from './types';
import CodeExecutor from './CodeExecutor';
import './DevPanel.css';

const GetParentResourceName = () => 'null-core';

const nuiCallback = async (event: string, data: Record<string, any> = {}) => {
  try {
    await fetch(`https://${GetParentResourceName()}/${event}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data),
    });
  } catch (e) { }
};

const ICON_MAP: Record<string, React.ReactNode> = {
  refresh: <RefreshCw size={14} />,
  user: <User size={14} />,
  package: <Package size={14} />,
  shirt: <Shirt size={14} />,
  heart: <Heart size={14} />,
  activity: <Activity size={14} />,
  'map-pin': <MapPin size={14} />,
  crosshair: <Crosshair size={14} />,
  ghost: <Ghost size={14} />,
  'eye-off': <EyeOff size={14} />,
};

interface DevPanelProps {
  visible: boolean;
  onClose: () => void;
  primaryColor: string;
}

const DevPanel: React.FC<DevPanelProps> = ({ visible, onClose, primaryColor }) => {
  const [currentPage, setCurrentPage] = useState<DevPanelPage>('executor');
  const [hiding, setHiding] = useState(false);
  const [config, setConfig] = useState<DevPanelConfig | null>(null);
  const [results, setResults] = useState<ExecutionResult[]>([]);
  const [resources, setResources] = useState<ResourceInfo[]>([]);
  const [scannedEvents, setScannedEvents] = useState<ScannedEvent[]>([]);
  const [pageTransition, setPageTransition] = useState(false);

  // Trigger state
  const [triggerName, setTriggerName] = useState('');
  const [triggerSide, setTriggerSide] = useState<'client' | 'server' | 'clientFromServer'>('client');
  const [triggerArgs, setTriggerArgs] = useState<TriggerArg[]>([]);
  const [eventFilter, setEventFilter] = useState('');

  // Resources filter
  const [resourceFilter, setResourceFilter] = useState('');
  const [resourceStateFilter, setResourceStateFilter] = useState<'all' | 'started' | 'stopped'>('all');

  // IPL state
  const [iplName, setIplName] = useState('');
  const [loadedIpls, setLoadedIpls] = useState<string[]>([]);
  const [bob74List, setBob74List] = useState<Bob74IplEntry[]>([]);
  const [bob74Filter, setBob74Filter] = useState('');
  const [bob74Category, setBob74Category] = useState<string>('all');
  const [bob74Refreshing, setBob74Refreshing] = useState(false);
  const [bob74OptionsId, setBob74OptionsId] = useState<string | null>(null);
  const [bob74Options, setBob74Options] = useState<Bob74IplOption[]>([]);
  const [bob74OptionsName, setBob74OptionsName] = useState('');
  const [bob74OptionsLoading, setBob74OptionsLoading] = useState(false);
  const [bob74ToggleState, setBob74ToggleState] = useState<Record<string, boolean>>({});

  const accentColor = '#10b981';
  const devAccentVars = useMemo(() => generateAccentVars('--dev-accent', accentColor), [accentColor]);

  // Message handler
  useEffect(() => {
    const handleMessage = (event: MessageEvent) => {
      const { action, data } = event.data;

      if (action === 'devPanel:open' && data) {
        setConfig(data);
      }

      if (action === 'devPanel:close') {
        // handled by visible prop
      }

      if (action === 'devPanel:result' && data) {
        setResults(prev => [...prev, { ...data, timestamp: Date.now() }]);
      }

      if (action === 'devPanel:resourceList' && data) {
        setResources(data);
      }

      if (action === 'devPanel:eventList' && data) {
        setScannedEvents(data);
      }

      if (action === 'devPanel:copyToClipboard' && data?.text) {
        nuiCallback("copyToClipboard", { text: data.text })
      }
    };

    window.addEventListener('message', handleMessage);
    return () => window.removeEventListener('message', handleMessage);
  }, []);

  const handleClose = useCallback(() => {
    setHiding(true);
    setTimeout(() => {
      setHiding(false);
      onClose();
      nuiCallback('devPanel:close');
    }, 280);
  }, [onClose]);

  const changePage = useCallback((page: DevPanelPage) => {
    if (page === currentPage) return;
    setPageTransition(true);
    setTimeout(() => {
      setCurrentPage(page);
      setPageTransition(false);
    }, 120);
  }, [currentPage]);

  // Trigger event
  const executeTrigger = useCallback(() => {
    if (!triggerName.trim()) return;

    const parsedArgs = triggerArgs.map(arg => {
      switch (arg.type) {
        case 'number': return Number(arg.value) || 0;
        case 'boolean': return arg.value.toLowerCase() === 'true';
        case 'table':
          try { return JSON.parse(arg.value); }
          catch { return arg.value; }
        default: return arg.value;
      }
    });

    if (triggerSide === 'client') {
      nuiCallback('devPanel:triggerClient', { eventName: triggerName, args: parsedArgs });
    } else if (triggerSide === 'server') {
      nuiCallback('devPanel:triggerServer', { eventName: triggerName, args: parsedArgs });
    } else {
      nuiCallback('devPanel:triggerClientFromServer', { eventName: triggerName, args: parsedArgs });
    }
  }, [triggerName, triggerSide, triggerArgs]);

  // Add trigger arg
  const addTriggerArg = useCallback(() => {
    setTriggerArgs(prev => [...prev, { id: Date.now().toString(), type: 'string', value: '' }]);
  }, []);

  // Remove trigger arg
  const removeTriggerArg = useCallback((id: string) => {
    setTriggerArgs(prev => prev.filter(a => a.id !== id));
  }, []);

  // Update trigger arg
  const updateTriggerArg = useCallback((id: string, field: 'type' | 'value', val: string) => {
    setTriggerArgs(prev => prev.map(a => a.id === id ? { ...a, [field]: val } : a));
  }, []);

  // Quick action
  const executeQuickAction = useCallback((action: QuickAction) => {
    nuiCallback('devPanel:quickAction', { action });
  }, []);

  // Scan events
  const scanEvents = useCallback(() => {
    nuiCallback('devPanel:scanEvents', { filter: eventFilter });
  }, [eventFilter]);

  // Refresh resources
  const refreshResources = useCallback(() => {
    nuiCallback('devPanel:getResources');
  }, []);

  // Refresh bob74_ipl list
  const refreshBob74 = useCallback(() => {
    setBob74Refreshing(true);
    fetch(`https://${GetParentResourceName()}/devPanel:bob74:getList`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({}),
    }).then(r => r.json()).then((data: any) => {
      if (data?.list) setBob74List(data.list);
      setBob74Refreshing(false);
    }).catch(() => setBob74Refreshing(false));
  }, []);

  // Restart resource
  const restartResource = useCallback((name: string) => {
    nuiCallback('devPanel:restartResource', { resource: name });
    setTimeout(refreshResources, 2000);
  }, [refreshResources]);

  // Keyboard shortcuts
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (!visible) return;
      if (e.key === 'Escape') {
        handleClose();
        e.preventDefault();
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [visible, handleClose]);

  if (!visible && !hiding) return null;

  const filteredResources = resources.filter(r => {
    const nameMatch = !resourceFilter || r.name.toLowerCase().includes(resourceFilter.toLowerCase());
    const stateMatch = resourceStateFilter === 'all' || r.state === resourceStateFilter;
    return nameMatch && stateMatch;
  });

  const pages: { key: DevPanelPage; label: string; icon: React.ReactNode }[] = [
    { key: 'executor', label: 'Exécuteur Lua', icon: <Code size={16} /> },
    { key: 'triggers', label: 'Triggers', icon: <Zap size={16} /> },
    { key: 'actions', label: 'Actions rapides', icon: <Play size={16} /> },
    { key: 'resources', label: 'Resources', icon: <Boxes size={16} /> },
    { key: 'ipl', label: 'IPL', icon: <Map size={16} /> },
  ];

  return (
    <div className={`dev-overlay ${hiding ? 'dev-hiding' : ''}`}>
      <div className="dev-container" style={devAccentVars as React.CSSProperties}>
        {/* Sidebar */}
        <div className="dev-sidebar">
          <div className="dev-sidebar-header">
            <div className="dev-sidebar-icon" style={{ background: `${accentColor}20`, color: accentColor }}>
              <Terminal size={18} />
            </div>
            <div className="dev-sidebar-title">
              <h1>Dev Panel</h1>
              <p>Null Development</p>
            </div>
          </div>

          <nav className="dev-sidebar-nav">
            {pages.map(page => (
              <button
                key={page.key}
                className={`dev-sidebar-item ${currentPage === page.key ? 'active' : ''}`}
                onClick={() => changePage(page.key)}
                style={currentPage === page.key ? {
                  background: `${accentColor}12`,
                  borderColor: `${accentColor}30`,
                  color: accentColor
                } : {}}
              >
                {page.icon}
                {page.label}
                <ChevronRight size={14} className="dev-sidebar-arrow" />
              </button>
            ))}
          </nav>

          {/* Result count */}
          <div className="dev-sidebar-stats">
            <div className="dev-stat-item">
              <Terminal size={12} />
              <span>{results.length} résultats</span>
            </div>
            <div className="dev-stat-item">
              <Boxes size={12} />
              <span>{resources.length} resources</span>
            </div>
          </div>

          <div className="dev-sidebar-footer">
            <button className="dev-close-btn" onClick={handleClose}>
              <X size={16} />
              Fermer (ESC)
            </button>
          </div>
        </div>

        {/* Content */}
        <div className={`dev-content ${pageTransition ? 'dev-page-transition' : ''}`}>

          {/* ============================================================
              EXECUTOR TAB
              ============================================================ */}
          {currentPage === 'executor' && (
            <CodeExecutor results={results} setResults={setResults} />
          )}

          {/* ============================================================
              TRIGGERS TAB
              ============================================================ */}
          {currentPage === 'triggers' && (
            <div className="dev-triggers">
              <div className="dev-section-header">
                <div className="dev-section-header-icon" style={{ background: '#8b5cf620', color: '#8b5cf6' }}>
                  <Zap size={20} />
                </div>
                <div>
                  <h2>Triggers & Events</h2>
                  <p>Déclencher et scanner des événements</p>
                </div>
              </div>

              {/* Trigger executor */}
              <div className="dev-trigger-form">
                <h3>Déclencher un événement</h3>

                <div className="dev-toggle-row">
                  <button
                    className={`dev-toggle-btn ${triggerSide === 'client' ? 'active' : ''}`}
                    onClick={() => setTriggerSide('client')}
                    style={triggerSide === 'client' ? { background: `${accentColor}20`, borderColor: accentColor, color: accentColor } : {}}
                  >
                    <Monitor size={14} /> TriggerEvent (Client)
                  </button>
                  <button
                    className={`dev-toggle-btn ${triggerSide === 'server' ? 'active' : ''}`}
                    onClick={() => setTriggerSide('server')}
                    style={triggerSide === 'server' ? { background: '#f59e0b20', borderColor: '#f59e0b', color: '#f59e0b' } : {}}
                  >
                    <Server size={14} /> TriggerServerEvent
                  </button>
                  <button
                    className={`dev-toggle-btn ${triggerSide === 'clientFromServer' ? 'active' : ''}`}
                    onClick={() => setTriggerSide('clientFromServer')}
                    style={triggerSide === 'clientFromServer' ? { background: '#ec489920', borderColor: '#ec4899', color: '#ec4899' } : {}}
                  >
                    <Send size={14} /> TriggerClientEvent
                  </button>
                </div>

                <div className="dev-trigger-input-row">
                  <input
                    type="text"
                    className="dev-input"
                    placeholder="Nom de l'événement (ex: esx:playerLoaded)"
                    value={triggerName}
                    onChange={e => setTriggerName(e.target.value)}
                  />
                </div>

                {/* Arguments */}
                <div className="dev-trigger-args">
                  <div className="dev-trigger-args-header">
                    <h4>Arguments ({triggerArgs.length})</h4>
                    <button className="dev-btn-small" onClick={addTriggerArg}>
                      <Plus size={12} /> Ajouter
                    </button>
                  </div>

                  {triggerArgs.map((arg, i) => (
                    <div key={arg.id} className="dev-trigger-arg">
                      <span className="dev-trigger-arg-num">#{i + 1}</span>
                      <select
                        className="dev-select"
                        value={arg.type}
                        onChange={e => updateTriggerArg(arg.id, 'type', e.target.value)}
                      >
                        <option value="string">String</option>
                        <option value="number">Number</option>
                        <option value="boolean">Boolean</option>
                        <option value="table">Table (JSON)</option>
                      </select>
                      {arg.type === 'boolean' ? (
                        <button
                          className={`dev-bool-toggle ${arg.value === 'true' ? 'true' : 'false'}`}
                          onClick={() => updateTriggerArg(arg.id, 'value', arg.value === 'true' ? 'false' : 'true')}
                        >
                          {arg.value === 'true' ? <ToggleRight size={16} /> : <ToggleLeft size={16} />}
                          {arg.value === 'true' ? 'true' : 'false'}
                        </button>
                      ) : (
                        <input
                          type="text"
                          className="dev-input"
                          placeholder={arg.type === 'table' ? '{"key": "value"}' : arg.type === 'number' ? '0' : 'valeur...'}
                          value={arg.value}
                          onChange={e => updateTriggerArg(arg.id, 'value', e.target.value)}
                        />
                      )}
                      <button className="dev-btn-danger" onClick={() => removeTriggerArg(arg.id)}>
                        <Minus size={12} />
                      </button>
                    </div>
                  ))}
                </div>

                <button
                  className="dev-execute-btn full"
                  onClick={executeTrigger}
                  style={{ background: triggerSide === 'server' ? '#f59e0b' : triggerSide === 'clientFromServer' ? '#ec4899' : accentColor }}
                >
                  <Send size={14} /> Déclencher
                </button>
              </div>

              {/* Event scanner */}
              <div className="dev-scanner">
                <h3>Scanner d'événements</h3>
                <div className="dev-scanner-row">
                  <div className="dev-search-input">
                    <Search size={14} />
                    <input
                      type="text"
                      placeholder="Filtrer les événements (ex: null, esx, inventory...)"
                      value={eventFilter}
                      onChange={e => setEventFilter(e.target.value)}
                    />
                  </div>
                  <button className="dev-btn-small accent" onClick={scanEvents} style={{ background: accentColor }}>
                    <Search size={12} /> Scanner
                  </button>
                </div>

                {scannedEvents.length > 0 && (
                  <div className="dev-scanner-results">
                    {scannedEvents.map((evt, i) => (
                      <div key={i} className="dev-scanner-item" onClick={() => { setTriggerName(evt.name); }}>
                        <Hash size={12} />
                        <span className="dev-scanner-name">{evt.name}</span>
                        <span className={`dev-console-badge ${evt.side}`}>{evt.side.toUpperCase()}</span>
                        {evt.isPattern && <span className="dev-scanner-pattern">pattern</span>}
                      </div>
                    ))}
                  </div>
                )}
              </div>

              {/* Console */}
              <div className="dev-console">
                <div className="dev-console-header">
                  <Terminal size={14} />
                  <span>Console</span>
                  <button className="dev-console-clear" onClick={() => setResults([])}>
                    <Trash2 size={12} /> Effacer
                  </button>
                </div>
                <div className="dev-console-output">
                  {results.length === 0 && (
                    <div className="dev-console-empty">En attente d'exécution...</div>
                  )}
                  {results.map((r, i) => (
                    <div key={i} className={`dev-console-line ${r.success ? 'success' : 'error'}`}>
                      <span className={`dev-console-badge ${r.side}`}>
                        {r.side === 'client' ? 'CLIENT' : r.side === 'server' ? 'SERVER' : 'ACTION'}
                      </span>
                      <span className="dev-console-time">
                        {r.timestamp ? new Date(r.timestamp).toLocaleTimeString() : ''}
                      </span>
                      {r.success ? <CheckCircle size={12} className="dev-console-icon success" /> : <XCircle size={12} className="dev-console-icon error" />}
                      <pre className="dev-console-text">{r.output}</pre>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          )}

          {/* ============================================================
              QUICK ACTIONS TAB
              ============================================================ */}
          {currentPage === 'actions' && (
            <div className="dev-actions">
              <div className="dev-section-header">
                <div className="dev-section-header-icon" style={{ background: '#f59e0b20', color: '#f59e0b' }}>
                  <Play size={20} />
                </div>
                <div>
                  <h2>Actions rapides</h2>
                  <p>Raccourcis pour les actions fréquentes</p>
                </div>
              </div>

              <div className="dev-actions-grid">
                {(config?.quickActions || []).map(action => (
                  <button
                    key={action.id}
                    className="dev-action-card"
                    onClick={() => executeQuickAction(action)}
                  >
                    <div className="dev-action-icon" style={{ background: `${accentColor}15`, color: accentColor }}>
                      {ICON_MAP[action.icon] || <Play size={14} />}
                    </div>
                    <div className="dev-action-info">
                      <span className="dev-action-label">{action.label}</span>
                      <span className="dev-action-type">
                        {action.command ? 'Commande' : action.serverEvent ? 'Server Event' : action.clientEvent ? 'Client Event' : 'Event'}
                      </span>
                    </div>
                    <ChevronRight size={14} className="dev-action-arrow" />
                  </button>
                ))}
              </div>

              {/* Custom command executor */}
              <div className="dev-custom-command">
                <h3>Commande personnalisée</h3>
                <div className="dev-command-row">
                  <input
                    type="text"
                    className="dev-input"
                    placeholder="restart null-core"
                    onKeyDown={e => {
                      if (e.key === 'Enter') {
                        nuiCallback('devPanel:executeCommand', { command: (e.target as HTMLInputElement).value });
                        (e.target as HTMLInputElement).value = '';
                      }
                    }}
                  />
                  <span className="dev-command-hint">Appuyez sur Entrée</span>
                </div>
              </div>

              {/* Console */}
              <div className="dev-console">
                <div className="dev-console-header">
                  <Terminal size={14} />
                  <span>Console</span>
                  <button className="dev-console-clear" onClick={() => setResults([])}>
                    <Trash2 size={12} /> Effacer
                  </button>
                </div>
                <div className="dev-console-output">
                  {results.length === 0 && (
                    <div className="dev-console-empty">En attente d'exécution...</div>
                  )}
                  {results.map((r, i) => (
                    <div key={i} className={`dev-console-line ${r.success ? 'success' : 'error'}`}>
                      <span className={`dev-console-badge ${r.side}`}>
                        {r.side === 'client' ? 'CLIENT' : r.side === 'server' ? 'SERVER' : 'ACTION'}
                      </span>
                      {r.success ? <CheckCircle size={12} className="dev-console-icon success" /> : <XCircle size={12} className="dev-console-icon error" />}
                      <pre className="dev-console-text">{r.output}</pre>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          )}

          {/* ============================================================
              IPL TAB
              ============================================================ */}
          {currentPage === 'ipl' && (
            <div className="dev-ipl">
              <div className="dev-section-header">
                <div className="dev-section-header-icon" style={{ background: '#06b6d420', color: '#06b6d4' }}>
                  <Map size={20} />
                </div>
                <div>
                  <h2>Gestion des IPL</h2>
                  <p>bob74_ipl + natives manuelles</p>
                </div>
                <button className="dev-btn-small accent" onClick={refreshBob74} style={{ background: accentColor, marginLeft: 'auto' }}>
                  <RefreshCw size={12} className={bob74Refreshing ? 'dev-spin' : ''} /> Actualiser
                </button>
              </div>

              {/* Manual IPL */}
              <div className="dev-ipl-form">
                <h3 style={{ fontSize: '13px', fontWeight: 600, color: 'white', margin: '0 0 10px 0' }}>IPL manuel</h3>
                <div className="dev-ipl-input-row">
                  <input
                    type="text"
                    className="dev-input"
                    placeholder="ex: ex_dt1_02_office_01a"
                    value={iplName}
                    onChange={e => setIplName(e.target.value)}
                    onKeyDown={e => {
                      if (e.key === 'Enter' && iplName.trim()) {
                        nuiCallback('devPanel:loadIpl', { ipl: iplName.trim() });
                        if (!loadedIpls.includes(iplName.trim())) {
                          setLoadedIpls(prev => [...prev, iplName.trim()]);
                        }
                      }
                    }}
                  />
                  <button
                    className="dev-btn-small accent"
                    onClick={() => {
                      if (!iplName.trim()) return;
                      nuiCallback('devPanel:loadIpl', { ipl: iplName.trim() });
                      if (!loadedIpls.includes(iplName.trim())) {
                        setLoadedIpls(prev => [...prev, iplName.trim()]);
                      }
                    }}
                    style={{ background: accentColor }}
                  >
                    <Plus size={12} /> Charger
                  </button>
                  <button
                    className="dev-btn-small danger"
                    onClick={() => {
                      if (!iplName.trim()) return;
                      nuiCallback('devPanel:unloadIpl', { ipl: iplName.trim() });
                      setLoadedIpls(prev => prev.filter(n => n !== iplName.trim()));
                    }}
                    style={{ background: '#ef4444' }}
                  >
                    <Minus size={12} /> Décharger
                  </button>
                </div>
                {loadedIpls.length > 0 && (
                  <div className="dev-ipl-items" style={{ marginTop: '10px' }}>
                    {loadedIpls.map((name, i) => (
                      <div key={i} className="dev-ipl-item">
                        <span className="dev-ipl-name">{name}</span>
                        <button
                          className="dev-ipl-remove"
                          onClick={() => {
                            nuiCallback('devPanel:unloadIpl', { ipl: name });
                            setLoadedIpls(prev => prev.filter(n => n !== name));
                          }}
                        >
                          <X size={12} />
                        </button>
                      </div>
                    ))}
                  </div>
                )}
              </div>

              {/* Bob74 IPL Browser */}
              <div className="dev-ipl-browser">
                <h3 style={{ fontSize: '13px', fontWeight: 600, color: 'white', margin: '0 0 12px 0' }}>bob74_ipl — Intérieurs</h3>

                <div className="dev-ipl-browser-filters">
                  <div className="dev-search-input">
                    <Search size={14} />
                    <input
                      type="text"
                      placeholder="Rechercher un intérieur..."
                      value={bob74Filter}
                      onChange={e => setBob74Filter(e.target.value)}
                    />
                  </div>
                  <div className="dev-toggle-row compact">
                    {(['all', 'GTA V', 'GTA Online', 'High Life', 'Heists', 'Executives', 'Finance', 'Bikers', 'Import/Export', 'Gunrunning', 'Smuggler', 'Doomsday', 'After Hours', 'Casino', 'Tuners', 'The Contract', 'Criminal Enterprise', 'Agents', 'Money Fronts', 'Safehouse Hills'] as const).map(cat => (
                      <button
                        key={cat}
                        className={`dev-toggle-btn small ${bob74Category === cat ? 'active' : ''}`}
                        onClick={() => setBob74Category(cat)}
                        style={bob74Category === cat ? { background: `${accentColor}20`, borderColor: accentColor, color: accentColor } : {}}
                      >
                        {cat === 'all' ? 'Tous' : cat}
                      </button>
                    ))}
                  </div>
                </div>

                <div className="dev-ipl-browser-list">
                  {bob74List.length === 0 ? (
                    <div className="dev-ipl-browser-empty">
                      Cliquez sur &quot;Actualiser&quot; pour charger la liste des intérieurs bob74_ipl
                    </div>
                  ) : (
                    Object.entries(
                      bob74List
                        .filter(e => {
                          const nameMatch = !bob74Filter || e.name.toLowerCase().includes(bob74Filter.toLowerCase());
                          const catMatch = bob74Category === 'all' || e.category === bob74Category;
                          return nameMatch && catMatch;
                        })
                        .reduce((acc, e) => {
                          if (!acc[e.category]) acc[e.category] = [];
                          acc[e.category].push(e);
                          return acc;
                        }, {} as Record<string, Bob74IplEntry[]>)
                    )
                      .sort(([a], [b]) => a.localeCompare(b))
                      .map(([category, entries]) => (
                        <div key={category} className="dev-ipl-category">
                          <div className="dev-ipl-category-header">
                            <ArrowRight size={12} />
                            <span>{category}</span>
                            <span className="dev-ipl-category-count">{entries.length}</span>
                          </div>
                          <div className="dev-ipl-category-items">
                            {entries.map(entry => (
                              <div key={entry.id} className={`dev-ipl-browser-item ${entry.loaded ? 'loaded' : ''}`}>
                                <div className="dev-ipl-browser-info">
                                  <span className="dev-ipl-browser-name">{entry.name}</span>
                                  <span className="dev-ipl-browser-coords">{entry.coords}</span>
                                  {entry.loaded && <span className="dev-ipl-browser-badge">CHARGÉ</span>}
                                </div>
                                <div className="dev-ipl-browser-actions">
                                  <button
                                    className="dev-ipl-action-btn tp"
                                    onClick={() => nuiCallback('devPanel:bob74:teleport', { id: entry.id })}
                                    title="Téléporter"
                                  >
                                    <Move size={12} />
                                  </button>
                                  <button
                                    className="dev-ipl-action-btn load"
                                    onClick={() => nuiCallback('devPanel:bob74:load', { id: entry.id })}
                                    title="Charger"
                                  >
                                    <Plus size={12} />
                                  </button>
                                  <button
                                    className="dev-ipl-action-btn unload"
                                    onClick={() => nuiCallback('devPanel:bob74:unload', { id: entry.id })}
                                    title="Décharger"
                                  >
                                    <Minus size={12} />
                                  </button>
                                  <button
                                    className="dev-ipl-action-btn opts"
                                    onClick={() => {
                                      setBob74OptionsId(entry.id);
                                      setBob74OptionsName(entry.name);
                                      setBob74Options([]);
                                      setBob74ToggleState({});
                                      setBob74OptionsLoading(true);
                                      fetch(`https://${GetParentResourceName()}/devPanel:bob74:getOptions`, {
                                        method: 'POST',
                                        headers: { 'Content-Type': 'application/json' },
                                        body: JSON.stringify({ id: entry.id }),
                                      })
                                        .then(r => r.json())
                                        .then((data: any) => {
                                          setBob74Options(data?.options ?? []);
                                          setBob74OptionsLoading(false);
                                        })
                                        .catch(() => {
                                          setBob74Options([]);
                                          setBob74OptionsLoading(false);
                                        });
                                    }}
                                    title="Options"
                                  >
                                    <SlidersHorizontal size={12} />
                                  </button>
                                </div>
                              </div>
                            ))}
                          </div>
                        </div>
                      ))
                  )}
                </div>
              </div>

              {/* Options Panel */}
              {bob74OptionsId && (
                <div className="dev-ipl-options">
                  <div className="dev-ipl-options-header">
                    <span>{bob74OptionsName} — Options</span>
                    <button className="dev-ipl-options-close" onClick={() => { setBob74OptionsId(null); setBob74Options([]); setBob74OptionsLoading(false); setBob74ToggleState({}); }}>
                      <X size={14} />
                    </button>
                  </div>
                  <div className="dev-ipl-options-body">
                    {bob74OptionsLoading ? (
                      <div className="dev-ipl-options-empty">Chargement des options...</div>
                    ) : bob74Options.length === 0 ? (
                      <div className="dev-ipl-options-empty">Aucune option disponible</div>
                    ) : (
                      bob74Options.map(opt => (
                        <div key={opt.key} className="dev-ipl-option-row">
                          <span className="dev-ipl-option-label">{opt.label}</span>
                          {opt.type === 'select' && opt.choices && (
                            <div className="dev-ipl-option-controls">
                              <select
                                className="dev-ipl-select"
                                onChange={e => {
                                  const val = e.target.value;
                                  const extra = opt.hasColor ? (opt.colorChoices?.[0]?.value as number ?? 0) : undefined;
                                  nuiCallback('devPanel:bob74:setOption', { id: bob74OptionsId, key: opt.key, value: val, extra });
                                }}
                              >
                                <option value="">Choisir...</option>
                                {opt.choices.map(c => (
                                  <option key={String(c.value)} value={String(c.value)}>{c.label}</option>
                                ))}
                              </select>
                              {opt.hasColor && opt.colorChoices && (
                                <select
                                  className="dev-ipl-select small"
                                  onChange={e => {
                                    // Color applied on next variant change, or standalone
                                    const colorVal = Number(e.target.value);
                                    nuiCallback('devPanel:bob74:setOption', { id: bob74OptionsId, key: opt.key, value: opt.choices?.[0]?.value ?? '', extra: colorVal });
                                  }}
                                >
                                  <option value="">Couleur...</option>
                                  {opt.colorChoices.map(c => (
                                    <option key={String(c.value)} value={String(c.value)}>{c.label}</option>
                                  ))}
                                </select>
                              )}
                            </div>
                          )}
                          {opt.type === 'toggle' && (
                            <button
                              className="dev-ipl-toggle-btn"
                              onClick={() => {
                                const next = !bob74ToggleState[opt.key];
                                setBob74ToggleState(prev => ({ ...prev, [opt.key]: next }));
                                nuiCallback('devPanel:bob74:setOption', { id: bob74OptionsId, key: opt.key, value: next });
                              }}
                            >
                              {bob74ToggleState[opt.key] ? <ToggleRight size={14} /> : <ToggleLeft size={14} />}
                              {bob74ToggleState[opt.key] ? 'Actif' : 'Inactif'}
                            </button>
                          )}
                          {opt.type === 'color' && opt.choices && (
                            <div className="dev-ipl-option-controls">
                              <select
                                className="dev-ipl-select"
                                onChange={e => nuiCallback('devPanel:bob74:setOption', { id: bob74OptionsId, key: opt.key, value: Number(e.target.value) })}
                              >
                                <option value="">Choisir...</option>
                                {opt.choices.map(c => (
                                  <option key={String(c.value)} value={String(c.value)}>{c.label}</option>
                                ))}
                              </select>
                            </div>
                          )}
                        </div>
                      ))
                    )}
                  </div>
                </div>
              )}

              {/* Console */}
              <div className="dev-console">
                <div className="dev-console-header">
                  <Terminal size={14} />
                  <span>Console</span>
                  <button className="dev-console-clear" onClick={() => setResults([])}>
                    <Trash2 size={12} /> Effacer
                  </button>
                </div>
                <div className="dev-console-output">
                  {results.length === 0 && (
                    <div className="dev-console-empty">En attente d&apos;exécution...</div>
                  )}
                  {results.map((r, i) => (
                    <div key={i} className={`dev-console-line ${r.success ? 'success' : 'error'}`}>
                      <span className={`dev-console-badge ${r.side}`}>
                        {r.side === 'client' ? 'CLIENT' : r.side === 'server' ? 'SERVER' : 'ACTION'}
                      </span>
                      {r.success ? <CheckCircle size={12} className="dev-console-icon success" /> : <XCircle size={12} className="dev-console-icon error" />}
                      <pre className="dev-console-text">{r.output}</pre>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          )}

          {/* ============================================================
              RESOURCES TAB
              ============================================================ */}
          {currentPage === 'resources' && (
            <div className="dev-resources">
              <div className="dev-section-header">
                <div className="dev-section-header-icon" style={{ background: '#3b82f620', color: '#3b82f6' }}>
                  <Boxes size={20} />
                </div>
                <div>
                  <h2>Resources</h2>
                  <p>Gérer et redémarrer les resources du serveur</p>
                </div>
                <button className="dev-btn-small accent" onClick={refreshResources} style={{ background: accentColor, marginLeft: 'auto' }}>
                  <RefreshCw size={12} /> Actualiser
                </button>
              </div>

              {/* Filters */}
              <div className="dev-resources-filters">
                <div className="dev-search-input">
                  <Search size={14} />
                  <input
                    type="text"
                    placeholder="Rechercher une resource..."
                    value={resourceFilter}
                    onChange={e => setResourceFilter(e.target.value)}
                  />
                </div>
                <div className="dev-toggle-row compact">
                  <button
                    className={`dev-toggle-btn small ${resourceStateFilter === 'all' ? 'active' : ''}`}
                    onClick={() => setResourceStateFilter('all')}
                    style={resourceStateFilter === 'all' ? { background: `${accentColor}20`, borderColor: accentColor, color: accentColor } : {}}
                  >
                    Toutes
                  </button>
                  <button
                    className={`dev-toggle-btn small ${resourceStateFilter === 'started' ? 'active' : ''}`}
                    onClick={() => setResourceStateFilter('started')}
                    style={resourceStateFilter === 'started' ? { background: '#10b98120', borderColor: '#10b981', color: '#10b981' } : {}}
                  >
                    Démarrées
                  </button>
                  <button
                    className={`dev-toggle-btn small ${resourceStateFilter === 'stopped' ? 'active' : ''}`}
                    onClick={() => setResourceStateFilter('stopped')}
                    style={resourceStateFilter === 'stopped' ? { background: '#ef444420', borderColor: '#ef4444', color: '#ef4444' } : {}}
                  >
                    Arrêtées
                  </button>
                </div>
              </div>

              {/* Resource list */}
              <div className="dev-resources-list">
                {filteredResources.length === 0 ? (
                  <div className="dev-resources-empty">
                    {resources.length === 0 ? 'Cliquez sur "Actualiser" pour charger' : 'Aucune resource trouvée'}
                  </div>
                ) : (
                  filteredResources.map(r => (
                    <div key={r.name} className={`dev-resource-item ${r.state}`}>
                      <div className={`dev-resource-status ${r.state}`} />
                      <span className="dev-resource-name">{r.name}</span>
                      <span className={`dev-resource-state ${r.state}`}>{r.state}</span>
                      {r.state === 'started' && (
                        <button
                          className="dev-resource-restart"
                          onClick={() => restartResource(r.name)}
                          title="Restart"
                        >
                          <RefreshCw size={12} />
                        </button>
                      )}
                    </div>
                  ))
                )}
              </div>

              {filteredResources.length > 0 && (
                <div className="dev-resources-count">
                  {filteredResources.length} resource{filteredResources.length > 1 ? 's' : ''}
                  {resourceFilter && ` (filtrées)`}
                </div>
              )}
            </div>
          )}

        </div>
      </div>
    </div>
  );
};

export default DevPanel;
