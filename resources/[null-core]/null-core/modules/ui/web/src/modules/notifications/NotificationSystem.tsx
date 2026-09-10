import React, { useState, useEffect, useCallback, useRef } from 'react';
import Notification from './Notification';
import { NotificationData } from './types';
import { hudPositionManager } from '../../utils/hudPositionManager';
import { applyAnchorPosition } from '../../utils/anchorPositioning';
import { soundManager } from '@core/SoundManager';

interface NotificationSystemProps {
  primaryColor: string;
  serverColor?: string;
  serverLuaColor?: string;
  hudEditorOpen?: boolean;
  serverLogo?: string;
}

interface NotificationContainer {
  notifications: (NotificationData & { offset: number })[];
  queue: number;
  canAdd: boolean;
}

const NotificationSystem: React.FC<NotificationSystemProps> = ({ primaryColor, serverColor, serverLuaColor, hudEditorOpen = false, serverLogo }) => {
  const [container, setContainer] = useState<NotificationContainer>({
    notifications: [],
    queue: 0,
    canAdd: true
  });
  const [stackCounts, setStackCounts] = useState<Map<string, number>>(new Map());
  const [actualPosition, setActualPosition] = useState<{ x: number; y: number; anchor: string } | null>(null);
  const [interfaceOpen, setInterfaceOpen] = useState(false);
  const notificationRefs = useRef<Map<string, HTMLDivElement>>(new Map());
  const maxQueue = 5;

  // Composants éphémères qui ne doivent PAS forcer le mode "interface ouverte"
  // (overlays minimes, menus 3D, pause GTA…).
  const TRANSIENT_COMPONENTS = new Set([
    'context-menu',
    'prop-interact',
    'pauseMenu',
  ]);

  useEffect(() => {
    const updatePosition = () => {
      const savedPos = hudPositionManager.getPosition('notifications');
      if (savedPos) {
        setActualPosition(savedPos);
      }
    };

    hudPositionManager.onReady(updatePosition);

    // Listen for layout changes
    const handleLayoutChange = () => {
      updatePosition();
    };

    window.addEventListener('hudLayoutChanged', handleLayoutChange);
    return () => window.removeEventListener('hudLayoutChanged', handleLayoutChange);
  }, []);

  const addNotification = useCallback((data: NotificationData) => {
    setContainer(prev => {
      // Check for duplicate
      if (data.duplicate) {
        const existingNotif = prev.notifications.find(n => n.message === data.message);
        if (existingNotif) {
          // Stack the notification
          setStackCounts(prevCounts => {
            const newCounts = new Map(prevCounts);
            const currentCount = newCounts.get(existingNotif.id) || 1;
            newCounts.set(existingNotif.id, currentCount + 1);
            return newCounts;
          });
          return prev;
        }
      }

      // Add new notification if queue allows
      if (prev.canAdd || data.pin_id) {
        const newQueue = data.pin_id ? prev.queue : prev.queue + 1;
        const newCanAdd = newQueue >= maxQueue ? false : true;

        return {
          notifications: [...prev.notifications, { ...data, offset: 0 }],
          queue: newQueue,
          canAdd: newCanAdd
        };
      }

      return prev;
    });
  }, [maxQueue]);

  const removeNotification = useCallback((id: string) => {
    setContainer(prev => {
      const notification = prev.notifications.find(n => n.id === id);
      if (!notification) return prev;

      const newQueue = notification.pin_id ? prev.queue : prev.queue - 1;
      const newCanAdd = newQueue === 0 ? true : prev.canAdd;

      // Remove stack count
      setStackCounts(prevCounts => {
        const newCounts = new Map(prevCounts);
        newCounts.delete(id);
        return newCounts;
      });

      // Notify Lua that notification was removed
      const resourceName = (window as any).GetParentResourceName?.();
      if (resourceName) {
        fetch(`https://${resourceName}/nui_removed`, {
          method: 'POST',
          body: JSON.stringify({ id })
        }).catch(() => {});
      }

      return {
        notifications: prev.notifications.filter(n => n.id !== id),
        queue: newQueue,
        canAdd: newCanAdd
      };
    });
  }, []);

  const unpinNotification = useCallback((pin_id: string) => {
    const notification = container.notifications.find(n => n.pin_id === pin_id);
    if (notification) {
      removeNotification(notification.id);
    }
  }, [container.notifications, removeNotification]);

  const updatePinned = useCallback((pin_id: string, options: Partial<NotificationData>) => {
    setContainer(prev => {
      const index = prev.notifications.findIndex(n => n.pin_id === pin_id);
      if (index === -1) return prev;

      const updatedNotification = {
        ...prev.notifications[index],
        ...options
      };

      return {
        ...prev,
        notifications: [
          ...prev.notifications.slice(0, index),
          updatedNotification,
          ...prev.notifications.slice(index + 1)
        ]
      };
    });
  }, []);

  useEffect(() => {
    const handleMessage = (event: MessageEvent) => {
      const data = event.data;

      if (data?.type === 'null:interfaceState') {
        // On considère qu'une interface "majeure" est ouverte uniquement si
        // au moins un composant non-transient est actif.
        const components: string[] = Array.isArray(data.components) ? data.components : [];
        const isMajor = components.some(c => !TRANSIENT_COMPONENTS.has(c));
        setInterfaceOpen(!!data.active && isMajor);
        return;
      }

      if (data.type === 'unpin' && data.pin_id) {
        unpinNotification(data.pin_id);
      } else if (data.type === 'update_pinned' && data.pin_id && data.options) {
        updatePinned(data.pin_id, data.options);
      } else if (data.id && data.message) {
        // Add notification
        const notifData: NotificationData = {
          id: data.id,
          type: data.type || 'standard',
          message: data.message,
          title: data.title,
          subject: data.subject,
          icon: data.icon || (data.type === 'advanced' || data.type === 'accept' ? serverLogo : undefined),
          couleurProgress: data.couleurProgress || primaryColor,
          timeout: data.timeout || 8000,
          progress: data.progress !== undefined ? data.progress : true,
          theme: data.theme || 'default',
          exitAnim: data.exitAnim || 'fadeOut',
          pin_id: data.pin_id,
          duplicate: data.duplicate || false
        };

        addNotification(notifData);
        soundManager.play('notification');
      }
    };

    window.addEventListener('message', handleMessage);
    return () => window.removeEventListener('message', handleMessage);
  }, [addNotification, unpinNotification, updatePinned]);

  if (hudEditorOpen || container.notifications.length === 0) return null;

  if (!actualPosition) return null;

  // Quand une interface majeure est ouverte, on force un ancrage top-center fixe
  // (configuré ici, NON modifiable par le HUD editor).
  const effectiveAnchor = interfaceOpen ? 'top-center' : actualPosition.anchor;
  const isBottom = effectiveAnchor.includes('bottom');
  const isCenter = effectiveAnchor.includes('center');
  const isRight  = effectiveAnchor.includes('right');
  const gap = interfaceOpen ? 8 : 10;

  // Calculate cumulative heights for stacking
  let cumulativeHeight = 0;
  const heights: number[] = [];

  container.notifications.forEach((notif) => {
    heights.push(cumulativeHeight);
    const ref = notificationRefs.current.get(notif.id);
    if (ref) {
      cumulativeHeight += ref.offsetHeight + gap;
    } else {
      cumulativeHeight += 80 + gap; // Estimate for first render
    }
  });

  // Container position : soit l'ancrage utilisateur (HUD editor), soit override
  // top-center quand une interface est ouverte. Transition CSS douce sur la
  // position via top/left/transform ; on ne change pas le DOM, juste les styles.
  const baseStyle: React.CSSProperties = interfaceOpen
    ? {
        position: 'fixed',
        top: '32px',
        left: '50%',
        transform: 'translateX(-50%)',
      }
    : applyAnchorPosition({
        position: { x: actualPosition.x, y: actualPosition.y },
        anchor: actualPosition.anchor as any,
      });

  return (
    <div
      className="fixed z-[10000]"
      style={{
        ...baseStyle,
        transition: 'top 450ms cubic-bezier(0.22, 1, 0.36, 1), left 450ms cubic-bezier(0.22, 1, 0.36, 1), bottom 450ms cubic-bezier(0.22, 1, 0.36, 1), right 450ms cubic-bezier(0.22, 1, 0.36, 1), transform 450ms cubic-bezier(0.22, 1, 0.36, 1)',
      }}
    >
      {container.notifications.map((notif, index) => {
        const height = heights[index] || 0;

        // Alignement horizontal interne
        let horizontalStyle: React.CSSProperties = {};
        if (isCenter) {
          horizontalStyle = { left: '50%', transform: 'translateX(-50%)' };
        } else if (isRight) {
          horizontalStyle = { right: 0 };
        } else {
          horizontalStyle = { left: 0 };
        }

        return (
          <div
            key={notif.id}
            ref={(el) => {
              if (el) {
                notificationRefs.current.set(notif.id, el);
              } else {
                notificationRefs.current.delete(notif.id);
              }
            }}
            style={{
              position: 'absolute',
              [isBottom ? 'bottom' : 'top']: `${height}px`,
              ...horizontalStyle,
              transition: 'all 400ms cubic-bezier(0.22, 1, 0.36, 1)',
            }}
          >
            <Notification
              data={notif}
              primaryColor={primaryColor}
              serverColor={serverColor}
              serverLuaColor={serverLuaColor}
              onRemove={removeNotification}
              stackCount={stackCounts.get(notif.id)}
              isBottom={isBottom}
              compactMode={interfaceOpen}
            />
          </div>
        );
      })}
    </div>
  );
};

export default NotificationSystem;
