import React, { useState, useEffect, useRef, useCallback, useMemo } from 'react';

// ==========================================================================
//  LUA SYNTAX HIGHLIGHTING
// ==========================================================================
const LUA_KEYWORDS = [
  'and', 'break', 'do', 'else', 'elseif', 'end', 'false', 'for', 'function',
  'goto', 'if', 'in', 'local', 'nil', 'not', 'or', 'repeat', 'return',
  'then', 'true', 'until', 'while'
];

const LUA_BUILTINS = [
  'print', 'type', 'tostring', 'tonumber', 'pairs', 'ipairs', 'next',
  'select', 'unpack', 'require', 'pcall', 'xpcall', 'error', 'assert',
  'setmetatable', 'getmetatable', 'rawget', 'rawset', 'rawlen',
  'table', 'string', 'math', 'io', 'os', 'coroutine', 'debug',
  'Wait', 'Citizen', 'json'
];

const FIVEM_NATIVES_CLIENT = [
  'PlayerPedId', 'GetPlayerPed', 'GetEntityCoords', 'GetEntityHeading',
  'SetEntityCoords', 'SetEntityHeading', 'SetEntityVisible',
  'GetPlayerServerId', 'PlayerId', 'GetPlayerName',
  'IsControlPressed', 'IsControlJustPressed', 'IsControlJustReleased',
  'DisableControlAction', 'EnableControlAction',
  'GetVehiclePedIsIn', 'IsPedInAnyVehicle', 'IsPedOnFoot',
  'SetPedComponentVariation', 'SetPedPropIndex',
  'GetGameplayCamRot', 'GetGameplayCamCoord',
  'RequestModel', 'HasModelLoaded', 'SetModelAsNoLongerNeeded',
  'CreatePed', 'CreateVehicle', 'CreateObject',
  'DeleteEntity', 'DoesEntityExist', 'IsEntityDead',
  'SetEntityInvincible', 'FreezeEntityPosition',
  'TaskWarpPedIntoVehicle', 'TaskEnterVehicle',
  'GetDistanceBetweenCoords', 'GetHashKey',
  'DrawMarker', 'DrawText3D',
  'SetNuiFocus', 'SetNuiFocusKeepInput', 'SendNUIMessage',
  'RegisterNUICallback', 'RegisterCommand', 'RegisterKeyMapping',
  'AddEventHandler', 'RegisterNetEvent',
  'TriggerEvent', 'TriggerServerEvent',
  'GetFirstBlipInfoId', 'DoesBlipExist', 'GetBlipInfoIdCoord',
  'SetEntityCollision', 'SetEntityAlpha',
  'NetworkGetEntityFromNetworkId', 'NetworkGetNetworkIdFromEntity',
  'GetGroundZFor_3dCoord', 'RequestCollisionAtCoord',
  'GetClosestVehicle', 'GetClosestPed',
  'SetPedCanRagdoll', 'ClearPedTasks', 'ClearPedTasksImmediately',
  'ApplyForceToEntity', 'SetEntityVelocity',
  'DisplayRadar', 'DisplayHud',
  'GetScreenCoordFromWorldCoord', 'GetActiveScreenResolution',
  'Notify', 'ESX', 'exports'
];

const FIVEM_NATIVES_SERVER = [
  'GetPlayerIdentifiers', 'GetPlayerName', 'GetPlayerEndpoint',
  'GetPlayerPed', 'GetPlayerRoutingBucket', 'SetPlayerRoutingBucket',
  'GetEntityCoords', 'GetEntityModel',
  'DropPlayer', 'TempBanPlayer',
  'ExecuteCommand', 'GetRegisteredCommands',
  'GetNumResources', 'GetResourceByFindIndex', 'GetResourceState',
  'StartResource', 'StopResource',
  'GetNumPlayerIndices', 'GetPlayerFromIndex',
  'TriggerClientEvent', 'TriggerEvent',
  'RegisterNetEvent', 'AddEventHandler',
  'RegisterServerEvent', 'RegisterCommand',
  'PerformHttpRequest',
  'MySQL', 'ESX', 'exports',
  'GetCurrentResourceName', 'GetResourcePath',
  'GetConvar', 'SetConvar',
  'CreateThread', 'Wait', 'Citizen'
];

const FIVEM_EVENTS = [
  'esx:playerLoaded', 'esx:onPlayerDeath', 'esx:setJob',
  'esx:playerDropped', 'esx:getSharedObject',
  'playerConnecting', 'playerDropped',
  'onResourceStart', 'onResourceStop',
  'gameEventTriggered', 'baseevents:onPlayerDied',
  'baseevents:onPlayerKilled', 'baseevents:enteringVehicle',
  'baseevents:enteringAborted', 'baseevents:enteredVehicle',
  'baseevents:leftVehicle',
];

// ==========================================================================
//  AUTOCOMPLETE SNIPPETS
// ==========================================================================
interface Snippet {
  label: string;
  insert: string;
  detail: string;
  kind: 'native' | 'keyword' | 'builtin' | 'event' | 'snippet';
}

function buildSnippets(side: 'client' | 'server'): Snippet[] {
  const snippets: Snippet[] = [];

  // Keywords
  LUA_KEYWORDS.forEach(kw => {
    snippets.push({ label: kw, insert: kw, detail: 'Keyword', kind: 'keyword' });
  });

  // Builtins
  LUA_BUILTINS.forEach(fn => {
    snippets.push({ label: fn, insert: fn, detail: 'Lua builtin', kind: 'builtin' });
  });

  // FiveM natives
  const natives = side === 'client' ? FIVEM_NATIVES_CLIENT : FIVEM_NATIVES_SERVER;
  natives.forEach(fn => {
    snippets.push({ label: fn, insert: fn + '()', detail: 'FiveM native', kind: 'native' });
  });

  // Events
  FIVEM_EVENTS.forEach(evt => {
    snippets.push({ label: evt, insert: `"${evt}"`, detail: 'FiveM event', kind: 'event' });
  });

  // Code snippets
  const codeSnippets: Snippet[] = [
    { label: 'CreateThread', insert: 'Citizen.CreateThread(function()\n\t\nend)', detail: 'Thread snippet', kind: 'snippet' },
    { label: 'RegisterCommand', insert: 'RegisterCommand("cmd", function(source, args, raw)\n\t\nend, false)', detail: 'Command snippet', kind: 'snippet' },
    { label: 'RegisterNUICallback', insert: 'RegisterNUICallback("name", function(data, cb)\n\t\n\tcb({})\nend)', detail: 'NUI callback', kind: 'snippet' },
    { label: 'AddEventHandler', insert: 'AddEventHandler("eventName", function()\n\t\nend)', detail: 'Event handler', kind: 'snippet' },
    { label: 'RegisterNetEvent', insert: 'RegisterNetEvent("eventName", function()\n\t\nend)', detail: 'Net event', kind: 'snippet' },
    { label: 'TriggerServerCallback', insert: 'ESX.TriggerServerCallback("name", function(result)\n\t\nend)', detail: 'ESX callback', kind: 'snippet' },
    { label: 'RegisterServerCallback', insert: 'ESX.RegisterServerCallback("name", function(source, cb)\n\t\n\tcb(result)\nend)', detail: 'ESX server callback', kind: 'snippet' },
    { label: 'forloop', insert: 'for i = 1, 10 do\n\t\nend', detail: 'For loop', kind: 'snippet' },
    { label: 'forpairs', insert: 'for k, v in pairs(tbl) do\n\t\nend', detail: 'Pairs loop', kind: 'snippet' },
    { label: 'foripairs', insert: 'for i, v in ipairs(tbl) do\n\t\nend', detail: 'IPairs loop', kind: 'snippet' },
    { label: 'ifthen', insert: 'if condition then\n\t\nend', detail: 'If block', kind: 'snippet' },
    { label: 'localfn', insert: 'local function name()\n\t\nend', detail: 'Local function', kind: 'snippet' },
    { label: 'SendNUIMessage', insert: 'SendNUIMessage({ action = "name", data = {} })', detail: 'Send NUI msg', kind: 'snippet' },
    { label: 'vector3', insert: 'vector3(0.0, 0.0, 0.0)', detail: 'Vector3', kind: 'snippet' },
    { label: 'vector4', insert: 'vector4(0.0, 0.0, 0.0, 0.0)', detail: 'Vector4', kind: 'snippet' },
  ];

  snippets.push(...codeSnippets);
  return snippets;
}

// ==========================================================================
//  SYNTAX HIGHLIGHTER (token-based, no regex-over-HTML)
// ==========================================================================
const LUA_KEYWORD_SET = new Set(LUA_KEYWORDS);
const LUA_BUILTIN_SET = new Set(LUA_BUILTINS);
const ALL_NATIVES_SET = new Set([...FIVEM_NATIVES_CLIENT, ...FIVEM_NATIVES_SERVER]);

function esc(s: string): string {
  return s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
}

function highlightLua(code: string): string {
  const len = code.length;
  let i = 0;
  const out: string[] = [];

  while (i < len) {
    // Multi-line comment --[[ ... ]]
    if (code[i] === '-' && code[i + 1] === '-' && code[i + 2] === '[' && code[i + 3] === '[') {
      const end = code.indexOf(']]', i + 4);
      const slice = end === -1 ? code.substring(i) : code.substring(i, end + 2);
      out.push(`<span class="hightlight lua-comment">${esc(slice)}</span>`);
      i += slice.length;
      continue;
    }

    // Single-line comment --
    if (code[i] === '-' && code[i + 1] === '-') {
      const nl = code.indexOf('\n', i);
      const slice = nl === -1 ? code.substring(i) : code.substring(i, nl);
      out.push(`<span class="hightlight lua-comment">${esc(slice)}</span>`);
      i += slice.length;
      continue;
    }

    // Strings (double or single quote)
    if (code[i] === '"' || code[i] === "'") {
      const q = code[i];
      let j = i + 1;
      while (j < len && code[j] !== q) {
        if (code[j] === '\\') j++; // skip escaped char
        j++;
      }
      if (j < len) j++; // include closing quote
      const slice = code.substring(i, j);
      out.push(`<span class="hightlight lua-string">${esc(slice)}</span>`);
      i = j;
      continue;
    }

    // Multi-line strings [[ ... ]]
    if (code[i] === '[' && code[i + 1] === '[') {
      const end = code.indexOf(']]', i + 2);
      const slice = end === -1 ? code.substring(i) : code.substring(i, end + 2);
      out.push(`<span class="hightlight lua-string">${esc(slice)}</span>`);
      i += slice.length;
      continue;
    }

    // Numbers
    if (/[0-9]/.test(code[i]) || (code[i] === '.' && i + 1 < len && /[0-9]/.test(code[i + 1]))) {
      let j = i;
      // Hex
      if (code[j] === '0' && (code[j + 1] === 'x' || code[j + 1] === 'X')) {
        j += 2;
        while (j < len && /[0-9a-fA-F]/.test(code[j])) j++;
      } else {
        while (j < len && /[0-9]/.test(code[j])) j++;
        if (j < len && code[j] === '.') {
          j++;
          while (j < len && /[0-9]/.test(code[j])) j++;
        }
      }
      const slice = code.substring(i, j);
      out.push(`<span class="hightlight lua-number">${esc(slice)}</span>`);
      i = j;
      continue;
    }

    // Words (identifiers, keywords, builtins, natives)
    if (/[a-zA-Z_]/.test(code[i])) {
      let j = i;
      while (j < len && /[a-zA-Z0-9_]/.test(code[j])) j++;
      const word = code.substring(i, j);

      // Check what follows (for function call detection)
      let k = j;
      while (k < len && code[k] === ' ') k++;
      const isCall = k < len && code[k] === '(';

      if (LUA_KEYWORD_SET.has(word)) {
        out.push(`<span class="hightlight lua-keyword">${esc(word)}</span>`);
      } else if (ALL_NATIVES_SET.has(word)) {
        out.push(`<span class="hightlight lua-native">${esc(word)}</span>`);
      } else if (LUA_BUILTIN_SET.has(word)) {
        out.push(`<span class="hightlight lua-builtin">${esc(word)}</span>`);
      } else if (isCall) {
        out.push(`<span class="hightlight lua-function">${esc(word)}</span>`);
      } else {
        out.push(esc(word));
      }
      i = j;
      continue;
    }

    // Operators
    if ('+-*/%^#=<>~'.includes(code[i]) || (code[i] === '.' && code[i + 1] === '.')) {
      if (code[i] === '.' && code[i + 1] === '.' && code[i + 2] === '.') {
        out.push(`<span class="hightlight lua-operator">${esc('...')}</span>`);
        i += 3;
      } else if (code[i] === '.' && code[i + 1] === '.') {
        out.push(`<span class="hightlight lua-operator">${esc('..')}</span>`);
        i += 2;
      } else {
        out.push(`<span class="hightlight lua-operator">${esc(code[i])}</span>`);
        i++;
      }
      continue;
    }

    // Everything else (whitespace, punctuation, etc.)
    out.push(esc(code[i]));
    i++;
  }

  return out.join('');
}

// ==========================================================================
//  EDITOR COMPONENT
// ==========================================================================
interface LuaEditorProps {
  value: string;
  onChange: (value: string) => void;
  side: 'client' | 'server';
  placeholder?: string;
  onExecute?: () => void;
}

const LuaEditor: React.FC<LuaEditorProps> = ({ value, onChange, side, placeholder, onExecute }) => {
  const textareaRef = useRef<HTMLTextAreaElement>(null);
  const highlightRef = useRef<HTMLDivElement>(null);
  const lineNumbersRef = useRef<HTMLDivElement>(null);
  const editorWrapperRef = useRef<HTMLDivElement>(null);

  const [autocompleteOpen, setAutocompleteOpen] = useState(false);
  const [autocompleteItems, setAutocompleteItems] = useState<Snippet[]>([]);
  const [autocompleteIndex, setAutocompleteIndex] = useState(0);
  const [autocompletePos, setAutocompletePos] = useState({ top: 0, left: 0 });
  const [currentWord, setCurrentWord] = useState('');

  const snippets = useMemo(() => buildSnippets(side), [side]);

  const lines = value.split('\n');
  const lineCount = lines.length;

  // Sync scroll between textarea and highlight overlay
  const syncScroll = useCallback(() => {
    if (textareaRef.current && highlightRef.current && lineNumbersRef.current) {
      highlightRef.current.scrollTop = textareaRef.current.scrollTop;
      highlightRef.current.scrollLeft = textareaRef.current.scrollLeft;
      lineNumbersRef.current.scrollTop = textareaRef.current.scrollTop;
    }
  }, []);

  // Get the current word being typed (for autocomplete)
  const getCurrentWord = useCallback((): { word: string; startPos: number } => {
    const textarea = textareaRef.current;
    if (!textarea) return { word: '', startPos: 0 };

    const cursorPos = textarea.selectionStart;
    const textBefore = value.substring(0, cursorPos);

    // Find word boundary
    const match = textBefore.match(/[a-zA-Z_:]\w*$/);
    if (!match) return { word: '', startPos: cursorPos };

    return {
      word: match[0],
      startPos: cursorPos - match[0].length
    };
  }, [value]);

  // Update autocomplete
  const updateAutocomplete = useCallback(() => {
    const { word } = getCurrentWord();
    setCurrentWord(word);

    if (word.length < 2) {
      setAutocompleteOpen(false);
      return;
    }

    const lowerWord = word.toLowerCase();
    const matches = snippets.filter(s =>
      s.label.toLowerCase().includes(lowerWord)
    ).slice(0, 10);

    if (matches.length === 0) {
      setAutocompleteOpen(false);
      return;
    }

    // Calculate popup position
    const textarea = textareaRef.current;
    if (textarea) {
      const cursorPos = textarea.selectionStart;
      const textBefore = value.substring(0, cursorPos);
      const linesAbove = textBefore.split('\n');
      const currentLine = linesAbove.length - 1;
      const currentCol = linesAbove[linesAbove.length - 1].length;

      const lineHeight = 22;
      const charWidth = 8.4;
      const top = (currentLine + 1) * lineHeight - textarea.scrollTop + 4;
      const left = currentCol * charWidth + 52 - textarea.scrollLeft;

      setAutocompletePos({ top: Math.min(top, 260), left: Math.min(left, 400) });
    }

    setAutocompleteItems(matches);
    setAutocompleteIndex(0);
    setAutocompleteOpen(true);
  }, [getCurrentWord, snippets, value]);

  // Insert autocomplete selection
  const insertAutocomplete = useCallback((snippet: Snippet) => {
    const textarea = textareaRef.current;
    if (!textarea) return;

    const { startPos } = getCurrentWord();
    const cursorPos = textarea.selectionStart;

    const before = value.substring(0, startPos);
    const after = value.substring(cursorPos);
    const newValue = before + snippet.insert + after;

    onChange(newValue);
    setAutocompleteOpen(false);

    // Set cursor position after insert
    setTimeout(() => {
      if (textareaRef.current) {
        const newPos = startPos + snippet.insert.length;
        // If snippet contains (), place cursor inside
        const parenPos = snippet.insert.indexOf('(');
        if (parenPos !== -1 && snippet.insert.endsWith(')')) {
          textareaRef.current.selectionStart = startPos + parenPos + 1;
          textareaRef.current.selectionEnd = startPos + parenPos + 1;
        } else {
          textareaRef.current.selectionStart = newPos;
          textareaRef.current.selectionEnd = newPos;
        }
        textareaRef.current.focus();
      }
    }, 0);
  }, [getCurrentWord, value, onChange]);

  // Handle key events
  const handleKeyDown = useCallback((e: React.KeyboardEvent<HTMLTextAreaElement>) => {
    const textarea = textareaRef.current;
    if (!textarea) return;

    // Autocomplete navigation
    if (autocompleteOpen) {
      if (e.key === 'ArrowDown') {
        e.preventDefault();
        setAutocompleteIndex(prev => Math.min(prev + 1, autocompleteItems.length - 1));
        return;
      }
      if (e.key === 'ArrowUp') {
        e.preventDefault();
        setAutocompleteIndex(prev => Math.max(prev - 1, 0));
        return;
      }
      if (e.key === 'Tab' || e.key === 'Enter') {
        if (autocompleteItems[autocompleteIndex]) {
          e.preventDefault();
          insertAutocomplete(autocompleteItems[autocompleteIndex]);
          return;
        }
      }
      if (e.key === 'Escape') {
        e.preventDefault();
        setAutocompleteOpen(false);
        return;
      }
    }

    // Tab indentation
    if (e.key === 'Tab') {
      e.preventDefault();
      const start = textarea.selectionStart;
      const end = textarea.selectionEnd;

      if (start === end) {
        // Single cursor - insert tab
        const before = value.substring(0, start);
        const after = value.substring(end);
        const newValue = before + '\t' + after;
        onChange(newValue);
        setTimeout(() => {
          textarea.selectionStart = start + 1;
          textarea.selectionEnd = start + 1;
        }, 0);
      } else {
        // Selection - indent/dedent lines
        const lineStart = value.lastIndexOf('\n', start - 1) + 1;
        const lineEnd = value.indexOf('\n', end);
        const selectedText = value.substring(lineStart, lineEnd === -1 ? value.length : lineEnd);

        if (e.shiftKey) {
          // Dedent
          const dedented = selectedText.replace(/^(\t| {1,4})/gm, '');
          const newValue = value.substring(0, lineStart) + dedented + value.substring(lineEnd === -1 ? value.length : lineEnd);
          onChange(newValue);
        } else {
          // Indent
          const indented = selectedText.replace(/^/gm, '\t');
          const newValue = value.substring(0, lineStart) + indented + value.substring(lineEnd === -1 ? value.length : lineEnd);
          onChange(newValue);
        }
      }
      return;
    }

    // Auto-close brackets and quotes
    const pairs: Record<string, string> = { '(': ')', '{': '}', '[': ']', '"': '"', "'": "'" };
    if (pairs[e.key]) {
      const start = textarea.selectionStart;
      const end = textarea.selectionEnd;

      if (start !== end) {
        // Wrap selection
        e.preventDefault();
        const selected = value.substring(start, end);
        const newValue = value.substring(0, start) + e.key + selected + pairs[e.key] + value.substring(end);
        onChange(newValue);
        setTimeout(() => {
          textarea.selectionStart = start + 1;
          textarea.selectionEnd = end + 1;
        }, 0);
        return;
      }
    }

    // Auto-indent on Enter
    if (e.key === 'Enter' && !autocompleteOpen) {
      const cursorPos = textarea.selectionStart;
      const textBefore = value.substring(0, cursorPos);
      const currentLine = textBefore.split('\n').pop() || '';
      const indentMatch = currentLine.match(/^(\s*)/);
      const currentIndent = indentMatch ? indentMatch[1] : '';

      // Check if line ends with block opener
      const trimmed = currentLine.trimEnd();
      const needsExtraIndent = /\b(then|do|else|function)\s*$/.test(trimmed) || trimmed.endsWith('{');

      if (currentIndent || needsExtraIndent) {
        e.preventDefault();
        const newIndent = needsExtraIndent ? currentIndent + '\t' : currentIndent;
        const newValue = value.substring(0, cursorPos) + '\n' + newIndent + value.substring(textarea.selectionEnd);
        onChange(newValue);
        setTimeout(() => {
          const newPos = cursorPos + 1 + newIndent.length;
          textarea.selectionStart = newPos;
          textarea.selectionEnd = newPos;
        }, 0);
      }
    }

    // Ctrl+Enter to execute
    if (e.key === 'Enter' && (e.ctrlKey || e.metaKey)) {
      e.preventDefault();
      onExecute?.();
    }
  }, [autocompleteOpen, autocompleteItems, autocompleteIndex, insertAutocomplete, value, onChange, onExecute]);

  // Handle input change
  const handleChange = useCallback((e: React.ChangeEvent<HTMLTextAreaElement>) => {
    onChange(e.target.value);
  }, [onChange]);

  // Trigger autocomplete on value change
  useEffect(() => {
    updateAutocomplete();
  }, [value, updateAutocomplete]);

  // Close autocomplete on click outside
  useEffect(() => {
    const handleClick = (e: MouseEvent) => {
      const wrapper = editorWrapperRef.current;
      if (wrapper && !wrapper.contains(e.target as Node)) {
        setAutocompleteOpen(false);
      }
    };
    document.addEventListener('mousedown', handleClick);
    return () => document.removeEventListener('mousedown', handleClick);
  }, []);

  // Highlighted code
  const highlighted = useMemo(() => highlightLua(value || ''), [value]);

  // Kind icons/colors for autocomplete
  const kindColor: Record<string, string> = {
    native: '#60a5fa',
    keyword: '#c084fc',
    builtin: '#f59e0b',
    event: '#10b981',
    snippet: '#f472b6',
  };

  const kindLabel: Record<string, string> = {
    native: 'N',
    keyword: 'K',
    builtin: 'B',
    event: 'E',
    snippet: 'S',
  };

  return (
    <div className="lua-editor-container" ref={editorWrapperRef}>
      {/* Line numbers */}
      <div className="lua-line-numbers" ref={lineNumbersRef}>
        {Array.from({ length: Math.max(lineCount, 1) }, (_, i) => (
          <div key={i} className="lua-line-num">{i + 1}</div>
        ))}
      </div>

      {/* Syntax highlight overlay */}
      <div
        className="lua-highlight-overlay"
        ref={highlightRef}
        dangerouslySetInnerHTML={{ __html: highlighted + '\n' }}
      />

      {/* Actual textarea (transparent text, visible caret) */}
      <textarea
        ref={textareaRef}
        className="lua-textarea"
        value={value}
        onChange={handleChange}
        onKeyDown={handleKeyDown}
        onScroll={syncScroll}
        placeholder={placeholder}
        spellCheck={false}
        autoCapitalize="off"
        autoCorrect="off"
        autoComplete="off"
      />

      {/* Autocomplete popup */}
      {autocompleteOpen && autocompleteItems.length > 0 && (
        <div
          className="lua-autocomplete"
          style={{ top: autocompletePos.top, left: autocompletePos.left }}
        >
          {autocompleteItems.map((item, i) => (
            <div
              key={item.label + i}
              className={`lua-ac-item ${i === autocompleteIndex ? 'active' : ''}`}
              onMouseDown={e => { e.preventDefault(); insertAutocomplete(item); }}
              onMouseEnter={() => setAutocompleteIndex(i)}
            >
              <span className="lua-ac-kind" style={{ background: `${kindColor[item.kind]}25`, color: kindColor[item.kind] }}>
                {kindLabel[item.kind]}
              </span> 
              <span className="lua-ac-label">
                {/* Highlight matching part */}
                {(() => {
                  const idx = item.label.toLowerCase().indexOf(currentWord.toLowerCase());
                  if (idx === -1) return item.label;
                  return (
                    <>
                      {item.label.substring(0, idx)}
                      <span className="lua-ac-match">{item.label.substring(idx, idx + currentWord.length)}</span>
                      {item.label.substring(idx + currentWord.length)}
                    </>
                  );
                })()}
              </span>
              <span className="lua-ac-detail">{item.detail}</span>
            </div>
          ))}
        </div>
      )}
    </div>
  );
};

export default LuaEditor;
