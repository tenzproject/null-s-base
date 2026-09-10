import React, { useState, useEffect, useCallback, useRef } from 'react';
import {
  Code, Play, Server, Monitor, Package,
  Terminal, Trash2, Copy, Plus, X,
  CheckCircle, XCircle
} from 'lucide-react';
import { ExecutionResult } from './types';
import LuaEditor from './LuaEditor';

const nuiCallback = async (event: string, data: Record<string, any> = {}) => {
  try {
    await fetch(`https://null-core/${event}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data),
    });
  } catch (e) {}
};

const ACCENT_COLOR = '#10b981';

const EXEC_RESOURCES = [
  { id: 'null-core', label: 'null-core', color: '#10b981' },
  { id: 'null-loader', label: 'null-loader', color: '#f59e0b', serverOnly: true },
  { id: 'null-stream', label: 'null-stream', color: '#3b82f6' },
  { id: 'null-ui', label: 'null-ui', color: '#8b5cf6' },
  { id: 'null-dealwp', label: 'null-dealwp', color: '#ec4899' },
];

interface CodeExecutorProps {
  results: ExecutionResult[];
  setResults: React.Dispatch<React.SetStateAction<ExecutionResult[]>>;
}

const CodeExecutor: React.FC<CodeExecutorProps> = ({ results, setResults }) => {
  const [execCode, setExecCode] = useState('');
  const [execSide, setExecSide] = useState<'client' | 'server'>('client');
  const [execResource, setExecResource] = useState('null-core');

  // Saved snippets
  const [savedSnippets, setSavedSnippets] = useState<{ name: string; code: string; side: 'client' | 'server' }[]>(() => {
    try {
      const saved = localStorage.getItem('devpanel_snippets');
      return saved ? JSON.parse(saved) : [];
    } catch { return []; }
  });
  const [snippetName, setSnippetName] = useState('');

  const resultsEndRef = useRef<HTMLDivElement>(null);

  // Auto-scroll results
  useEffect(() => {
    resultsEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [results]);

  // Save snippets to localStorage
  useEffect(() => {
    localStorage.setItem('devpanel_snippets', JSON.stringify(savedSnippets));
  }, [savedSnippets]);

  // Execute code
  const executeCode = useCallback(() => {
    if (!execCode.trim()) return;
    const res = EXEC_RESOURCES.find(r => r.id === execResource);
    const side = (res?.serverOnly && execSide === 'client') ? 'server' : execSide;
    if (side === 'client') {
      nuiCallback('devPanel:executeClient', { code: execCode, resource: execResource });
    } else {
      nuiCallback('devPanel:executeServer', { code: execCode, resource: execResource });
    }
  }, [execCode, execSide, execResource]);

  // Save snippet
  const saveSnippet = useCallback(() => {
    if (!snippetName.trim() || !execCode.trim()) return;
    setSavedSnippets(prev => [...prev, { name: snippetName, code: execCode, side: execSide }]);
    setSnippetName('');
  }, [snippetName, execCode, execSide]);

  // Load snippet
  const loadSnippet = useCallback((snippet: { name: string; code: string; side: 'client' | 'server' }) => {
    setExecCode(snippet.code);
    setExecSide(snippet.side);
  }, []);

  // Delete snippet
  const deleteSnippet = useCallback((index: number) => {
    setSavedSnippets(prev => prev.filter((_, i) => i !== index));
  }, []);

  const currentRes = EXEC_RESOURCES.find(r => r.id === execResource);
  const resColor = currentRes?.color || ACCENT_COLOR;

  return (
    <div className="dev-executor">
      <div className="dev-section-header">
        <div className="dev-section-header-icon" style={{ background: `${ACCENT_COLOR}20`, color: ACCENT_COLOR }}>
          <Code size={20} />
        </div>
        <div>
          <h2>Exécuteur Lua</h2>
          <p>Exécuter du code Lua côté client ou serveur</p>
        </div>
      </div>

      {/* Side toggle + Resource selector */}
      <div className="dev-toggle-row">
        <button
          className={`dev-toggle-btn ${execSide === 'client' ? 'active' : ''}`}
          onClick={() => setExecSide('client')}
          style={execSide === 'client' ? { background: `${ACCENT_COLOR}20`, borderColor: ACCENT_COLOR, color: ACCENT_COLOR } : {}}
        >
          <Monitor size={14} /> Client
        </button>
        <button
          className={`dev-toggle-btn ${execSide === 'server' ? 'active' : ''}`}
          onClick={() => setExecSide('server')}
          style={execSide === 'server' ? { background: '#f59e0b20', borderColor: '#f59e0b', color: '#f59e0b' } : {}}
        >
          <Server size={14} /> Server
        </button>
        <div className="dev-resource-selector">
          <Package size={12} style={{ color: 'var(--text-secondary)' }} />
          {EXEC_RESOURCES.map(r => (
            <button
              key={r.id}
              className={`dev-resource-btn ${execResource === r.id ? 'active' : ''}`}
              onClick={() => setExecResource(r.id)}
              style={execResource === r.id ? { background: `${r.color}18`, borderColor: r.color, color: r.color } : {}}
              title={r.serverOnly ? `${r.label} (server only)` : r.label}
            >
              {r.label.replace('null-', '')}
              {r.serverOnly && <Server size={9} />}
            </button>
          ))}
        </div>
      </div>
      {currentRes?.serverOnly && execSide === 'client' && (
        <div className="dev-resource-warning">
          <Server size={12} /> {execResource} est server-only — l'exécution sera forcée côté serveur
        </div>
      )}

      {/* Code editor */}
      <div className="dev-editor-wrapper">
        <div className="dev-editor-header">
          <div className="dev-editor-header-left">
            <span className="dev-editor-lang">Lua</span>
            <span className="dev-editor-side-badge" style={{ background: execSide === 'server' ? '#f59e0b20' : `${ACCENT_COLOR}20`, color: execSide === 'server' ? '#f59e0b' : ACCENT_COLOR }}>
              {execSide === 'server' ? <Server size={10} /> : <Monitor size={10} />}
              {execSide}
            </span>
            <span className="dev-editor-resource-badge" style={{ background: `${resColor}15`, color: resColor }}>
              <Package size={9} />
              {execResource}
            </span>
            <span className="dev-editor-linecount">{execCode.split('\n').length} lignes</span>
          </div>
          <div className="dev-editor-actions">
            <input
              type="text"
              className="dev-snippet-input"
              placeholder="Nom du snippet..."
              value={snippetName}
              onChange={e => setSnippetName(e.target.value)}
            />
            <button className="dev-editor-btn" onClick={saveSnippet} title="Sauvegarder">
              <Plus size={12} /> Sauver
            </button>
            <button className="dev-editor-btn" onClick={() => setExecCode('')} title="Effacer">
              <Trash2 size={12} />
            </button>
          </div>
        </div>
        <LuaEditor
          value={execCode}
          onChange={setExecCode}
          side={execSide}
          placeholder={execSide === 'client'
            ? "-- Code Lua client\nprint('Hello from client!')\nprint(GetEntityCoords(PlayerPedId()))"
            : "-- Code Lua server\nprint('Hello from server!')\nprint(GetNumPlayerIndices())"}
          onExecute={executeCode}
        />
        <div className="dev-editor-footer">
          <span className="dev-editor-hint">Tab = indentation | Ctrl+Enter = exécuter | Autocomplétion FiveM natives</span>
          <button
            className="dev-execute-btn"
            onClick={executeCode}
            style={{ background: execSide === 'server' ? '#f59e0b' : ACCENT_COLOR }}
          >
            <Play size={14} /> Exécuter ({execSide})
          </button>
        </div>
      </div>

      {/* Saved snippets */}
      {savedSnippets.length > 0 && (
        <div className="dev-snippets">
          <h3>Snippets sauvegardés</h3>
          <div className="dev-snippets-list">
            {savedSnippets.map((snippet, i) => (
              <div key={i} className="dev-snippet-item">
                <div className="dev-snippet-info" onClick={() => loadSnippet(snippet)}>
                  <Code size={12} />
                  <span className="dev-snippet-name">{snippet.name}</span>
                  <span className={`dev-snippet-side ${snippet.side}`}>{snippet.side}</span>
                </div>
                <button className="dev-snippet-delete" onClick={() => deleteSnippet(i)}>
                  <X size={12} />
                </button>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Results console */}
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
              <button className="dev-console-copy" onClick={() => navigator.clipboard.writeText(r.output)}>
                <Copy size={10} />
              </button>
            </div>
          ))}
          <div ref={resultsEndRef} />
        </div>
      </div>
    </div>
  );
};

export default CodeExecutor;
