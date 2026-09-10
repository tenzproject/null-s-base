import React, { useState, useEffect, useRef, useCallback } from 'react';
import './ProgressBar.css';
import { hudPositionManager } from '../../utils/hudPositionManager';
import { applyAnchorPosition } from '../../utils/anchorPositioning';
import { HUD_MODULES } from '../hud-editor/HUDModulesConfig';

interface ProgressBarProps {
  serverConfig: {
    serverName: string;
    serverColor: string;
    serverIcon: string;
  };
  previewMode?: boolean;
  previewPosition?: { x: number; y: number };
  hudEditorOpen?: boolean;
  globalConfig?: {
    primaryColor: string;
    theme: 'dark' | 'light';
    style: 'modern' | 'compact';
  };
}

interface ProgressData {
  text: string;
  time: number;
  callback?: string;
}

const ProgressBar: React.FC<ProgressBarProps> = ({
  serverConfig,
  previewMode = false,
  previewPosition,
  hudEditorOpen = false,
  globalConfig
}) => {
  const [visible, setVisible] = useState(previewMode);
  const [progressData, setProgressData] = useState<ProgressData | null>(null);
  const [percentage, setPercentage] = useState(0);
  const [actualPosition, setActualPosition] = useState<any>(null);
  const animationRef = useRef<number | null>(null);
  const startTimeRef = useRef<number>(0);
  const callbackRef = useRef<string | undefined>(undefined);

  const primaryColor = globalConfig?.primaryColor || serverConfig.serverColor || '#646464';

  // Load saved position
  useEffect(() => {
    if (previewMode) return;

    hudPositionManager.onReady(() => {
      const savedPos = hudPositionManager.getPosition('progress_bar');
      if (savedPos) {
        setActualPosition(savedPos);
      }
    });

    const handleLayoutChange = () => {
      const savedPos = hudPositionManager.getPosition('progress_bar');
      if (savedPos) {
        setActualPosition(savedPos);
      }
    };

    window.addEventListener('hudLayoutChanged', handleLayoutChange);
    return () => window.removeEventListener('hudLayoutChanged', handleLayoutChange);
  }, [previewMode]);

  // Animation loop
  const animateProgress = useCallback((startTime: number, maxTime: number, isPreview: boolean = false) => {
    const now = Date.now();
    const elapsed = now - startTime;
    const perc = Math.min(Math.round((elapsed / maxTime) * 100), 100);

    setPercentage(perc);

    if (perc < 100) {
      animationRef.current = requestAnimationFrame(() => animateProgress(startTime, maxTime, isPreview));
    } else {
      // Progress complete
      if (isPreview) {
        // Preview mode: restart loop after delay
        setTimeout(() => {
          setPercentage(0);
          const newStart = Date.now();
          startTimeRef.current = newStart;
          animateProgress(newStart, maxTime, true);
        }, 500);
      } else {
        setTimeout(() => {
          setVisible(false);
          setProgressData(null);
          setPercentage(0);

          // Execute callback if provided
          if (callbackRef.current) {
            fetch(`https://${GetParentResourceName()}/${callbackRef.current}`, {
              method: 'POST',
              headers: { 'Content-Type': 'application/json' },
              body: JSON.stringify({ completed: true })
            });
          }
          callbackRef.current = undefined;
        }, 200);
      }
    }
  }, []);

  // Handle NUI messages
  useEffect(() => {
    if (previewMode) {
      setProgressData({ text: 'CHARGEMENT EN COURS', time: 5000 });
      setVisible(true);
      setPercentage(0);
      const start = Date.now();
      startTimeRef.current = start;
      animateProgress(start, 5000, true);
      return () => {
        if (animationRef.current) {
          cancelAnimationFrame(animationRef.current);
        }
      };
    }

    const handleMessage = (event: MessageEvent) => {
      const data = event.data;

      if (data.action === 'showProgressBar' || data.type === 'ui') {
        if (data.display === true || data.show === true) {
          const time = data.time || 5000;
          const text = data.text || 'CHARGEMENT EN COURS';
          const callback = data.callback;

          // Cancel previous animation if any
          if (animationRef.current) {
            cancelAnimationFrame(animationRef.current);
          }

          callbackRef.current = callback;
          setProgressData({ text, time, callback });
          setPercentage(0);
          setVisible(true);

          // Use setTimeout to ensure state is updated before animation starts
          setTimeout(() => {
            const start = Date.now();
            startTimeRef.current = start;
            animateProgress(start, time, false);
          }, 50);
        } else {
          // Force hide
          if (animationRef.current) {
            cancelAnimationFrame(animationRef.current);
          }
          callbackRef.current = undefined;
          setVisible(false);
          setProgressData(null);
          setPercentage(0);
        }
      } else if (data.action === 'hideProgressBar') {
        if (animationRef.current) {
          cancelAnimationFrame(animationRef.current);
        }
        callbackRef.current = undefined;
        setVisible(false);
        setProgressData(null);
        setPercentage(0);
      }
    };

    window.addEventListener('message', handleMessage);
    return () => {
      window.removeEventListener('message', handleMessage);
      if (animationRef.current) {
        cancelAnimationFrame(animationRef.current);
      }
    };
  }, [previewMode, animateProgress]);

  function GetParentResourceName(): string {
    return 'null-core';
  }

  if (!visible && !previewMode) return null;

  const displayText = progressData?.text || 'CHARGEMENT EN COURS';
  const defaultConfig = HUD_MODULES.find(m => m.id === 'progress_bar');

  return (
    <div
      style={{
        display: (hudEditorOpen && !previewMode) ? 'none' : undefined,
        ...(previewMode ? {
          position: 'relative' as const,
          left: 0,
          top: 0,
          transform: 'none'
        } : actualPosition?.anchor ? applyAnchorPosition({
          anchor: actualPosition.anchor,
          position: { x: actualPosition.x, y: actualPosition.y }
        }) : defaultConfig ? applyAnchorPosition({
          anchor: defaultConfig.anchor,
          position: defaultConfig.defaultPosition
        }) : {}),
        zIndex: 1000,
      }}
    >
      <div
        className={`progress-bar-container ${visible ? 'visible' : 'hiding'}`}
        style={{
          ['--server-color' as any]: primaryColor,
        }}
      >
      <div className="progress-bar-panel">
        <div className="progress-bar-header">
          <span className="progress-bar-text">{displayText}</span>
          <span className="progress-bar-percent">{percentage}%</span>
        </div>
        <div className="progress-bar-track">
          <div
            className="progress-bar-fill"
            style={{
              width: `${percentage}%`,
              backgroundColor: primaryColor,
            }}
          />
        </div>
      </div>
      </div>
    </div>
  );
};

export default ProgressBar;
