import React, { useState, useEffect } from 'react';
import StatusBar, { StatusBarId, StatusBarStyle } from './StatusBar';

interface StatusBarsProps {
  serverConfig: {
    serverName: string;
    serverColor: string;
    serverIcon: string;
    serverDiscord: string;
  };
  previewMode?: boolean;
  previewPosition?: { x: number; y: number };
  hudEditorOpen?: boolean;
  statusColors?: {
    mic?: string;
    health?: string;
    armor?: string;
    hunger?: string;
    thirst?: string;
    stamina?: string;
    oxygen?: string;
    /** Style visuel global appliqué à toutes les barres (1, 2, 3, 5, 6, 7 ou 8). */
    barStyle?: StatusBarStyle;
  };
  globalConfig?: {
    primaryColor: string;
    theme: 'dark' | 'light';
    style: 'modern' | 'compact';
  };
}

interface StatusData {
  health: number;
  armor: number;
  hunger: number;
  thirst: number;
  stamina: number;
  oxygen: number;
  isTalking: boolean;
  talkRange: number;
  isUnderwater: boolean;
}

const StatusBars: React.FC<StatusBarsProps> = ({ 
  serverConfig, 
  previewMode = false, 
  previewPosition,
  hudEditorOpen = false,
  statusColors,
  globalConfig
}) => {
  const [visible, setVisible] = useState(previewMode);
  const [statusData, setStatusData] = useState<StatusData>({
    health: 100,
    armor: 50,
    hunger: 100,
    thirst: 100,
    stamina: 100,
    oxygen: 100,
    isTalking: false,
    talkRange: 0,
    isUnderwater: false,
  });

  const primaryColor = globalConfig?.primaryColor || serverConfig.serverColor;
  const colors = {
    mic: statusColors?.mic || primaryColor,
    health: statusColors?.health || primaryColor,
    armor: statusColors?.armor || primaryColor,
    hunger: statusColors?.hunger || primaryColor,
    thirst: statusColors?.thirst || primaryColor,
    stamina: statusColors?.stamina || primaryColor,
    oxygen: statusColors?.oxygen || primaryColor,
  };

  useEffect(() => {
    if (previewMode) return;

    const handleMessage = (event: MessageEvent) => {
      const data = event.data;

      switch (data.type || data.action) {
        case 'playerStatus':
          setStatusData(prev => ({
            ...prev,
            health: Math.max(0, Math.min(100, data.heal || 0)),
            armor: Math.max(0, Math.min(100, data.armour || 0)),
            hunger: Math.max(0, Math.min(100, data.hunger || 100)),
            thirst: Math.max(0, Math.min(100, data.thirst || 100)),
            stamina: Math.max(0, Math.min(100, 100 - (data.stamina || 0))),
            oxygen: Math.max(0, Math.min(100, data.oxygen || 100)),
            isUnderwater: data.weather || false,
          }));
          break;

        case 'mic':
          if (data.range !== undefined) {
            setStatusData(prev => ({
              ...prev,
              talkRange: data.range || 0,
            }));
          }
          if (data.state !== undefined) {
            setStatusData(prev => ({
              ...prev,
              isTalking: data.state || false,
            }));
          }
          break;

        case 'show':
          setVisible(true);
          break;

        case 'pause':
          setVisible(false);
          break;
      }
    };

    window.addEventListener('message', handleMessage);
    return () => window.removeEventListener('message', handleMessage);
  }, [previewMode]);


  if ((!visible && !previewMode) || (hudEditorOpen && !previewMode)) return null;

  const bars: Array<{ id: StatusBarId; value: number; icon: string; color: string }> = [
    { id: 'mic', value: statusData.talkRange === 1 ? 33 : statusData.talkRange === 2 ? 66 : statusData.talkRange === 3 ? 100 : 0, icon: statusData.isTalking ? 'fa-solid fa-microphone-lines' : 'fa-solid fa-microphone-lines-slash', color: colors.mic },
    { id: 'health', value: statusData.health, icon: 'fa-solid fa-heart', color: colors.health },
    { id: 'armor', value: statusData.armor, icon: 'fa-solid fa-shield', color: colors.armor },
    { id: 'hunger', value: statusData.hunger, icon: 'fa-solid fa-burger', color: colors.hunger },
    { id: 'thirst', value: statusData.thirst, icon: 'fa-solid fa-droplet', color: colors.thirst },
    { id: 'stamina', value: statusData.stamina, icon: 'fa-solid fa-person-running', color: colors.stamina },
  ]; 

  // Add oxygen only if underwater
  if (statusData.isUnderwater || previewMode) {
    bars.push({ id: 'oxygen', value: statusData.oxygen, icon: 'fa-solid fa-lungs', color: colors.oxygen });
  }

  // Style global appliqué à toutes les barres (configuré via le HUD Editor)
  const barStyle: StatusBarStyle = (statusColors?.barStyle as StatusBarStyle) || 1;

  return (
    <>
      {bars.map((bar) => (
        <StatusBar
          key={bar.id}
          barId={bar.id}
          value={bar.value}
          icon={bar.icon}
          color={bar.color}
          style={barStyle}
          previewMode={previewMode}
          previewPosition={previewPosition}
          hudEditorOpen={hudEditorOpen}
          visible={visible}
        />
      ))}
    </>
  );
};

export default StatusBars;
