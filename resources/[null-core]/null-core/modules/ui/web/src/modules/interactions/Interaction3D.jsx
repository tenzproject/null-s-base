import React, { useState, useEffect, useMemo, useCallback, memo } from 'react';
import './styles/Interaction3D.css';

// Parse text data once and cache result
const parseTextData = (text) => {
  if (typeof text === 'string') {
    try {
      const parsed = JSON.parse(text);
      if (parsed?.lines) {
        return { textData: parsed, isMulti: true };
      }
    } catch (e) {}
  } else if (typeof text === 'object' && text?.lines) {
    return { textData: text, isMulti: true };
  }
  return { textData: text, isMulti: false };
};

// Memoized single interaction component
const InteractionItem = memo(({ id, data }) => {
  // Memoize parsed text data
  const { textData, isMulti } = useMemo(() => parseTextData(data.text), [data.text]);
  
  // Memoize distance check
  const isNear = useMemo(() => {
    const maxDistance = data.maxDistance || 1.5;
    return data.distance < maxDistance;
  }, [data.distance, data.maxDistance]);

  // Memoize container className
  const containerClass = useMemo(() => 
    `interaction-3d-container ${isNear ? 'near' : 'far'}`,
    [isNear]
  );

  // Memoize styles to prevent object recreation
  const containerStyle = useMemo(() => ({
    left: data.screenX + 'px',
    top: data.screenY + 'px',
    transform: 'translate(-50%, -50%)'
  }), [data.screenX, data.screenY]);

  // Memoize content className
  const contentClass = useMemo(() => 
    `interaction-3d-content ${isMulti ? 'multi' : ''}`,
    [isMulti]
  );

  if (isMulti) {
    return (
      <div
        className={containerClass}
        style={containerStyle}
      >
        <div className="interaction-3d-dot" />
        <div className={contentClass}>
          {textData.title && (
            <div className="interaction-3d-title">{textData.title}</div>
          )}
          <div className="interaction-3d-lines">
            {textData.lines?.map((line, index) => {
              if (line.hidden) return null;
              
              const isDisabled = !!line.disabled;
              const isLast = index === textData.lines.length - 1;
              const lineClass = `interaction-3d-line ${isLast ? 'last' : ''} ${isDisabled ? 'disabled' : ''}`;
              const rightClass = typeof line.right === 'boolean' 
                ? (line.right ? 'boolean-true' : 'boolean-false')
                : '';

              return (
                <div key={index} className={lineClass}>
                  <span className="line-left">{line.left || ''}</span>
                  <span className={`line-right ${rightClass}`}>
                    {typeof line.right === 'boolean' ? '' : (line.right || '')}
                  </span>
                  {line.key && !isDisabled && (
                    <span className="line-key">{line.key}</span>
                  )}
                  {isDisabled && line.disabledReason && (
                    <span className="line-disabled-reason">{line.disabledReason}</span>
                  )}
                </div>
              );
            })}
          </div>
        </div>
      </div>
    );
  }

  // Single line mode
  return (
    <div
      className={containerClass}
      style={containerStyle}
    >
      <div className="interaction-3d-dot" />
      <div className={contentClass}>
        {data.key && (
          <span className={`interaction-3d-key ${data.disabled ? 'disabled' : ''}`}>
            {data.key}
          </span>
        )}
        <span className={`interaction-3d-text ${data.disabled ? 'disabled' : ''}`}>
          {data.text}
        </span>
        {data.disabled && data.disabledReason && (
          <span className="interaction-3d-disabled-reason">{data.disabledReason}</span>
        )}
      </div>
    </div>
  );
});

InteractionItem.displayName = 'InteractionItem';

function Interaction3D({ serverConfig }) {
  const [interactions, setInteractions] = useState({});

  // Set CSS variable once
  useEffect(() => {
    if (serverConfig?.serverColor) {
      document.documentElement.style.setProperty('--server-color', serverConfig.serverColor);
    }
  }, [serverConfig?.serverColor]);

  // Optimized message handler with useCallback
  const handleMessage = useCallback((event) => {
    const data = event.data;
    const action = data.type || data.action;

    switch (action) {
      case 'UPDATE_3D_INTERACTION':
        if (!data?.id) return;
        
        if (!data.show) {
          setInteractions(prev => {
            if (!(data.id in prev)) return prev;
            const { [data.id]: _, ...rest } = prev;
            return rest;
          });
          return;
        }

        setInteractions(prev => {
          if (prev[data.id] === data) return prev;
          return { ...prev, [data.id]: data };
        });
        break;

      case 'REMOVE_3D_INTERACTION':
        if (data?.id) {
          setInteractions(prev => {
            if (!(data.id in prev)) return prev;
            const { [data.id]: _, ...rest } = prev;
            return rest;
          });
        }
        break;

      case 'CLEAR_3D_INTERACTIONS':
        setInteractions({});
        break;
    }
  }, []);

  useEffect(() => {
    window.addEventListener('message', handleMessage);
    return () => window.removeEventListener('message', handleMessage);
  }, [handleMessage]);

  // Memoize visible interactions array
  const visibleInteractions = useMemo(() => 
    Object.entries(interactions).filter(([, data]) => data.show),
    [interactions]
  );

  if (visibleInteractions.length === 0) return null;

  return (
    <>
      {visibleInteractions.map(([id, data]) => (
        <InteractionItem key={id} id={id} data={data} />
      ))}
    </>
  );
}

export default memo(Interaction3D);
