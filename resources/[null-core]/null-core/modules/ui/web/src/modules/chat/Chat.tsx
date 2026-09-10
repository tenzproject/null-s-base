import React, { useState, useEffect, useRef, useCallback } from 'react';
import { hudPositionManager } from '../../utils/hudPositionManager';
import { getAnchorTransform } from '../../utils/anchorPositioning';

function GetParentResourceName(): string {
  return 'null-core';
}

interface ChatMessage {
  args: string[];
  template?: string;
  templateId?: string;
  color?: number[];
  multiline?: boolean;
}

interface ChatSuggestion {
  name: string;
  help?: string;
  params?: Array<{ name: string; help?: string }>;
}

interface ChatProps {
  hudEditorOpen: boolean;
  primaryColor: string;
  previewMode?: boolean;
  previewPosition?: { x: number; y: number } | null;
}

const Chat: React.FC<ChatProps> = ({ hudEditorOpen, primaryColor, previewMode = false, previewPosition = null }) => {
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [inputVisible, setInputVisible] = useState(false);
  const [inputValue, setInputValue] = useState('');
  const [suggestions, setSuggestions] = useState<ChatSuggestion[]>([]);
  const [messageHistory, setMessageHistory] = useState<string[]>([]);
  const [historyIndex, setHistoryIndex] = useState(-1);
  const [showMessages, setShowMessages] = useState(false);
  const [shouldHide, setShouldHide] = useState(false);
  const [actualPosition, setActualPosition] = useState<{ x: number; y: number; anchor: string } | null>(null);
  
  const messagesRef = useRef<HTMLDivElement>(null);
  const inputRef = useRef<HTMLTextAreaElement>(null);
  const fadeTimeoutRef = useRef<number | null>(null);

  // Load position from HUD manager
  useEffect(() => {
    if (previewMode) return;

    const readPositionFromStorage = () => {
      try {
        const saved = localStorage.getItem('hudLayout');
        if (saved) {
          const layout = JSON.parse(saved);
          const chatModule = layout.find((m: any) => m.id === 'chat');
          if (chatModule) {
            setActualPosition({
              x: chatModule.position.x,
              y: chatModule.position.y,
              anchor: chatModule.anchor || 'top-right',
            });
          }
        }
      } catch (e) {}
    };

    // Initial load
    hudPositionManager.onReady(() => {
      const savedPos = hudPositionManager.getPosition('chat');
      if (savedPos) {
        setActualPosition(savedPos);
      }
    });

    // Sync when editor saves
    window.addEventListener('hudLayoutChanged', readPositionFromStorage);
    return () => window.removeEventListener('hudLayoutChanged', readPositionFromStorage);
  }, [previewMode]);

  // Auto-scroll to bottom when new messages arrive
  useEffect(() => {
    if (messagesRef.current) {
      messagesRef.current.scrollTop = messagesRef.current.scrollHeight;
    }
  }, [messages]);

  // Show messages temporarily when new message arrives
  useEffect(() => {
    if (messages.length > 0) {
      setShowMessages(true);
      
      if (fadeTimeoutRef.current) {
        clearTimeout(fadeTimeoutRef.current);
      }
      
      if (!inputVisible) {
        fadeTimeoutRef.current = setTimeout(() => {
          setShowMessages(false);
        }, 5000) as unknown as number;
      }
    }
  }, [messages, inputVisible]);

  // Focus input when visible - aggressive focus management (skip in preview mode)
  useEffect(() => {
    if (previewMode) return;
    if (inputVisible && inputRef.current) {
      const focusInput = () => {
        if (inputRef.current) {
          inputRef.current.focus();
        }
      };
      
      focusInput();
      setTimeout(focusInput, 50);
      setTimeout(focusInput, 100);
      setTimeout(focusInput, 200);
    }
  }, [inputVisible, previewMode]);

  // Mock data for preview mode
  useEffect(() => {
    if (previewMode) {
      setMessages([
        { args: ['Joueur1', 'Salut tout le monde !'] },
        { args: ['Admin', 'Bienvenue sur le serveur'], template: '<b style="color:#ff6b6b">{0}</b>: {1}' },
        { args: ['Joueur2', 'Merci !'] },
      ]);
      setInputVisible(true);
      setShowMessages(true);
    }
  }, [previewMode]);

  // Listen for NUI messages
  useEffect(() => {
    if (previewMode) return;
    
    const handleMessage = (event: MessageEvent) => {
      const { action, data } = event.data;

      switch (action) {
        case 'chatAddMessage':
          setMessages(prev => [...prev, data.message]);
          break;
        case 'chatOpen':
          setInputVisible(true);
          setShowMessages(true);
          if (fadeTimeoutRef.current) {
            clearTimeout(fadeTimeoutRef.current);
          }
          break;
        case 'chatClose':
          setInputVisible(false);
          setInputValue('');
          if (fadeTimeoutRef.current) {
            clearTimeout(fadeTimeoutRef.current);
          }
          fadeTimeoutRef.current = setTimeout(() => {
            setShowMessages(false);
          }, 5000) as unknown as number;
          break;
        case 'chatClear':
          setMessages([]);
          setMessageHistory([]);
          setHistoryIndex(-1);
          break;
        case 'chatAddSuggestion':
          setSuggestions(prev => {
            const exists = prev.find(s => s.name === data.suggestion.name);
            if (exists) {
              return prev.map(s => s.name === data.suggestion.name ? data.suggestion : s);
            }
            return [...prev, data.suggestion];
          });
          break;
        case 'chatRemoveSuggestion':
          setSuggestions(prev => prev.filter(s => s.name !== data.name));
          break;
        case 'chatClearSuggestions':
          setSuggestions([]);
          break;
        case 'chatScreenStateChange':
          if (data?.shouldHide !== undefined) {
            setShouldHide(data.shouldHide);
          }
          break;
      }
    };

    window.addEventListener('message', handleMessage);
    return () => window.removeEventListener('message', handleMessage);
  }, [previewMode]);

  const parseGTAColors = (text: string): JSX.Element[] => {
    const colorMap: Record<string, string> = {
      '^0': '#ffffff',
      '^1': '#ff4444',
      '^2': '#99cc00',
      '^3': '#ff0000',
      '^4': '#0099cc',
      '^5': '#33b5e5',
      '^6': '#aa66cc',
      '^7': '#cccccc',
      '^8': '#cc0000',
      '^9': '#cc0068',
    };

    if (!text || typeof text !== 'string') {
      return [<span key="0">{String(text || '')}</span>];
    }
    const regex = /(\^[0-9])/g;
    const parts = text.split(regex);
    const elements: JSX.Element[] = [];
    let currentColor = '#ffffff';

    parts.forEach((part, index) => {
      if (colorMap[part]) {
        currentColor = colorMap[part];
      } else if (part && !part.match(regex)) {
        elements.push(
          <span key={index} style={{ color: currentColor }}>
            {part}
          </span>
        );
      }
    });

    return elements;
  };

  const renderMessage = (msg: ChatMessage, index: number) => {
    let template = msg.template || '{0}';
    
    if (msg.args.length === 2 && !msg.template) {
      template = '<b>{0}</b>: {1}';
    }

    let rendered = template;
    msg.args.forEach((arg, i) => {
      rendered = rendered.replace(`{${i}}`, arg);
    });

    // Parse HTML tags
    const htmlParsed = rendered
      .replace(/<b>(.*?)<\/b>/g, '<strong>$1</strong>')
      .replace(/<pre>(.*?)<\/pre>/g, '<code>$1</code>');

    return (
      <div
        key={index}
        className="mb-0.5 text-[0.85rem] leading-[1.3] break-words text-white"
        style={{
          fontFamily: 'Outfit, sans-serif',
        }}
        dangerouslySetInnerHTML={{ __html: htmlParsed }}
      />
    );
  };

  const handleKeyDown = (e: React.KeyboardEvent<HTMLTextAreaElement>) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      handleSend();
    } else if (e.key === 'Escape') {
      e.preventDefault();
      handleClose(true);
    } else if (e.key === 'ArrowUp') {
      e.preventDefault();
      if (messageHistory.length > historyIndex + 1) {
        const newIndex = historyIndex + 1;
        setHistoryIndex(newIndex);
        setInputValue(messageHistory[newIndex]);
      }
    } else if (e.key === 'ArrowDown') {
      e.preventDefault();
      if (historyIndex > 0) {
        const newIndex = historyIndex - 1;
        setHistoryIndex(newIndex);
        setInputValue(messageHistory[newIndex]);
      } else if (historyIndex === 0) {
        setHistoryIndex(-1);
        setInputValue('');
      }
    } else if (e.key === 'PageUp') {
      e.preventDefault();
      if (messagesRef.current) {
        messagesRef.current.scrollTop -= 100;
      }
    } else if (e.key === 'PageDown') {
      e.preventDefault();
      if (messagesRef.current) {
        messagesRef.current.scrollTop += 100;
      }
    }
  };

  // Ferme l'input visuellement SANS notifier le Lua (pour ne pas appeler
  // chatResult deux fois — ce qui réinitialisait le focus NUI d'une commande
  // qui venait d'en ouvrir un, laissant le joueur bloqué).
  const closeVisual = () => {
    setInputVisible(false);
    setInputValue('');
    setHistoryIndex(-1);
    if (fadeTimeoutRef.current) {
      clearTimeout(fadeTimeoutRef.current);
    }
    fadeTimeoutRef.current = setTimeout(() => {
      setShowMessages(false);
    }, 5000) as unknown as number;
  };

  const handleSend = () => {
    if (inputValue.trim()) {
      // UN SEUL appel chatResult, avec le message (le Lua libère le focus).
      fetch(`https://${GetParentResourceName()}/chatResult`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ message: inputValue }),
      }).catch(() => {});

      setMessageHistory(prev => [inputValue, ...prev]);
      closeVisual();
    } else {
      // Envoi vide = annulation.
      handleClose(true);
    }
  };

  const handleClose = (canceled: boolean) => {
    // Annulation (ESC / envoi vide) : un seul chatResult pour libérer le focus.
    fetch(`https://${GetParentResourceName()}/chatResult`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ canceled: canceled }),
    }).catch(() => {});

    closeVisual();
  };

  const getFilteredSuggestions = (): ChatSuggestion[] => {
    if (!inputValue.startsWith('/')) return [];
    
    // Extract just the command part (before first space)
    if (!inputValue || typeof inputValue !== 'string') return [];
    const commandPart = inputValue.split(' ')[0].toLowerCase();
    return suggestions
      .filter(s => s.name.toLowerCase().startsWith(commandPart))
      .slice(0, 5);
  };

  if ((hudEditorOpen && !previewMode) || shouldHide) return null;

  const position = previewMode && previewPosition 
    ? { x: previewPosition.x, y: previewPosition.y, anchor: 'top-right' }
    : actualPosition || { x: 99, y: 3, anchor: 'top-right' };
  
  const positionStyle: React.CSSProperties = previewMode && previewPosition
    ? {
        left: '0px',
        top: '0px',
        transform: 'none',
      }
    : {
        left: `${position.x}%`,
        top: `${position.y}%`,
        transform: getAnchorTransform(position.anchor as any),
      };

  const filteredSuggestions = getFilteredSuggestions();

  return (
    <div
      className={`fixed z-[100] ${previewMode ? '' : 'w-[38%] max-w-[600px]'}`}
      style={{
        ...positionStyle,
        pointerEvents: previewMode ? 'none' : (inputVisible ? 'auto' : 'none'),
        ...(previewMode ? { position: 'relative', left: 0, top: 0, width: '38vw', maxWidth: '600px' } : {})
      }}
    >
      {/* Messages Container - No background, minimalist */}
      {(showMessages || inputVisible) && (
        <div
          ref={messagesRef}
          className="chat-scrollbar max-h-[22vh] overflow-y-auto overflow-x-hidden mb-2 pr-2 transition-opacity duration-300"
          style={{
            opacity: showMessages ? 1 : 0,
          }}
        >
          {messages.map((msg, index) => renderMessage(msg, index))}
        </div>
      )}

      {/* Input Container - With background */}
      {inputVisible && (
        <div>
          <div
            className="flex items-center bg-black/40 rounded-md px-2.5 py-1.5 shadow-lg"
            style={{
              border: `1px solid ${primaryColor}30`,
            }}
            onClick={() => {
              if (inputRef.current) {
                inputRef.current.focus();
              }
            }}
          >
            <span
              className="text-xl mr-2 font-bold"
              style={{
                color: primaryColor,
              }}
            >
              ➤
            </span>
            <textarea
              ref={inputRef}
              value={inputValue}
              onChange={(e) => setInputValue(e.target.value)}
              onKeyDown={handleKeyDown}
              placeholder="Message ou /commande..."
              className="flex-1 bg-transparent border-none outline-none text-white text-sm resize-none min-h-[24px] max-h-[120px] overflow-auto"
              style={{
                fontFamily: 'Outfit, sans-serif',
              }}
              rows={1}
              tabIndex={previewMode ? -1 : 0}
              disabled={previewMode}
            />
          </div>

          {/* Suggestions */}
          {filteredSuggestions.length > 0 && (
            <div
              className="mt-1 bg-black/70 rounded-md p-1.5"
              style={{
                border: `1px solid ${primaryColor}20`,
              }}
            >
              {filteredSuggestions.map((suggestion, index) => (
                <div
                  key={index}
                  className="px-2 py-1.5 rounded bg-white/5"
                  style={{
                    marginBottom: index < filteredSuggestions.length - 1 ? '4px' : 0,
                  }}
                >
                  <div className="text-[0.85rem] text-white" style={{ fontFamily: 'Outfit, sans-serif' }}>
                    <span className="font-bold" style={{ color: primaryColor }}>{suggestion.name}</span>
                    {suggestion.params && suggestion.params.map((param, i) => (
                      <span key={i} className="text-gray-400 ml-1">
                        [{param.name}]
                      </span>
                    ))}
                  </div>
                  {suggestion.help && (
                    <div className="text-xs text-gray-400 mt-0.5" style={{ fontFamily: 'Outfit, sans-serif' }}>
                      {suggestion.help}
                    </div>
                  )}
                </div>
              ))}
            </div>
          )}
        </div>
      )}

      <style>{`
        .chat-scrollbar::-webkit-scrollbar {
          width: 4px;
        }
        .chat-scrollbar::-webkit-scrollbar-track {
          background: transparent;
        }
        .chat-scrollbar::-webkit-scrollbar-thumb {
          background: ${primaryColor}40;
          border-radius: 2px;
        }
        .chat-scrollbar::-webkit-scrollbar-thumb:hover {
          background: ${primaryColor}60;
        }
      `}</style>
    </div>
  );
};

export default Chat;
