import React, { useState, useEffect, useRef, useMemo } from 'react';
import { generateAccentVars } from '@/utils/accentColors';
import { Check } from 'lucide-react';
import './Objectives.css';

interface ObjectiveStep {
  id: string;
  title: string;
  description?: string;
}

interface ObjectivesData {
  id: string;
  title: string;
  icon?: string;
  steps: ObjectiveStep[];
  currentStep: number;
  color?: string;
  skipCommand?: string;
}

interface ObjectivesProps {
  primaryColor: string;
}

const Objectives: React.FC<ObjectivesProps> = ({ primaryColor }) => {
  const [data, setData] = useState<ObjectivesData | null>(null);
  const objAccentColor = data?.color || primaryColor || '#44a5ff';
  const objAccentVars = useMemo(() => generateAccentVars('--obj-accent', objAccentColor), [objAccentColor]);
  const [phase, setPhase] = useState<'entering' | 'visible' | 'exiting' | 'hidden'>('hidden');
  const [stepAnim, setStepAnim] = useState<'in' | 'out' | 'idle'>('idle');
  const [completed, setCompleted] = useState(false);
  const hideTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const completeTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const prevStepRef = useRef<number>(-1);

  // NUI messages
  useEffect(() => {
    const handler = (event: MessageEvent) => {
      const { action, data: msgData } = event.data;

      switch (action) {
        case 'objectives:start': {
          if (hideTimerRef.current) { clearTimeout(hideTimerRef.current); hideTimerRef.current = null; }
          if (completeTimerRef.current) { clearTimeout(completeTimerRef.current); completeTimerRef.current = null; }
          setCompleted(false);
          setStepAnim('idle');
          prevStepRef.current = msgData.currentStep ?? 0;
          setData({
            id: msgData.id,
            title: msgData.title,
            icon: msgData.icon,
            steps: msgData.steps || [],
            currentStep: msgData.currentStep ?? 0,
            color: msgData.color,
            skipCommand: msgData.skipCommand,
          });
          setPhase('entering');
          requestAnimationFrame(() => {
            requestAnimationFrame(() => setPhase('visible'));
          });
          break;
        }

        case 'objectives:update': {
          setData(prev => {
            if (!prev) return prev;
            const newStep = msgData.currentStep ?? prev.currentStep;

            if (newStep !== prevStepRef.current) {
              setStepAnim('out');
              setTimeout(() => {
                setStepAnim('in');
                prevStepRef.current = newStep;
              }, 300);
            }

            return {
              ...prev,
              currentStep: newStep,
              steps: msgData.steps ?? prev.steps,
              title: msgData.title ?? prev.title,
              color: msgData.color ?? prev.color,
            };
          });
          break;
        }

        case 'objectives:complete': {
          setCompleted(true);
          completeTimerRef.current = setTimeout(() => {
            setPhase('exiting');
            hideTimerRef.current = setTimeout(() => {
              setPhase('hidden');
              setData(null);
              setCompleted(false);
            }, 500);
          }, msgData?.delay ?? 3000);
          break;
        }

        case 'objectives:stop': {
          setPhase('exiting');
          hideTimerRef.current = setTimeout(() => {
            setPhase('hidden');
            setData(null);
            setCompleted(false);
          }, 500);
          break;
        }
      }
    };

    window.addEventListener('message', handler);
    return () => {
      window.removeEventListener('message', handler);
      if (hideTimerRef.current) clearTimeout(hideTimerRef.current);
      if (completeTimerRef.current) clearTimeout(completeTimerRef.current);
    };
  }, []);

  if (phase === 'hidden' || !data) return null;

  const totalSteps = data.steps.length;
  const currentIdx = data.currentStep;
  const progressPct = totalSteps > 0 ? (currentIdx / totalSteps) * 100 : 0;
  const currentStepData = data.steps[currentIdx];

  return (
    <div
      className={`obj-container obj-${phase}`}
      style={objAccentVars as React.CSSProperties}
    >
      {/* Title */}
      <div className="obj-title">{data.title}</div>

      {/* Progress text */}
      <div className="obj-progress-text">
        Étape <span>{currentIdx + 1}</span> / {totalSteps}
      </div>

      {/* Progress bar */}
      <div className="obj-progress-bar">
        <div className="obj-progress-fill" style={{ width: `${completed ? 100 : progressPct}%` }} />
      </div>

      {/* Step or completed */}
      {completed ? (
        <div className="obj-completed">
          <div className="obj-completed-icon"><Check size={16} /></div>
          <div className="obj-completed-text">Objectifs terminés !</div>
          <div className="obj-completed-sub">{data.title}</div>
        </div>
      ) : currentStepData ? (
        <div className={`obj-step ${stepAnim === 'out' ? 'obj-step-exit' : ''}`}>
          <div className="obj-step-title">{currentStepData.title}</div>
          {currentStepData.description && (
            <div className="obj-step-desc">
              {currentStepData.description.split('\n').map((line, i, arr) => (
                <React.Fragment key={i}>{line}{i < arr.length - 1 && <br />}</React.Fragment>
              ))}
            </div>
          )}
        </div>
      ) : null}

      {/* Skip command */}
      {data.skipCommand && !completed && (
        <div className="obj-skip-info">
          <span className="obj-skip-label">Passer :</span>
          <code className="obj-skip-command">/{data.skipCommand}</code>
        </div>
      )}
    </div>
  );
};

export default Objectives;
