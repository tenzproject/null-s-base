import React, { useState, useEffect, useCallback, useRef } from 'react';
import { soundManager } from '@core/SoundManager';
import InputDialog from '@modules/interactions/InputDialog';
import ConfirmDialog from '@modules/interactions/ConfirmDialog';
import Interaction3D from '@modules/interactions/Interaction3D';
import DoorPrompt from '@modules/doorlock/DoorPrompt';
import DoorlockManager from '@modules/doorlock/DoorlockManager';
import DoorCodePad from '@modules/doorlock/DoorCodePad';
import InfoDialog from '@modules/interactions/InfoDialog';
import AnnouncementDialog from '@modules/interactions/AnnouncementDialog';
import Menu from '@modules/menu/Menu';
import { MenuState } from '@modules/menu/types';
import ItemGridPanelComponent, { GridItem } from '@modules/menu/ItemGridPanelComponent';
import HUDEditor from '@modules/hud-editor/HUDEditor';
import { getDefaultModuleStates } from '@modules/hud-editor/HUDModulesConfig';
import StatusBars from '@modules/hud/StatusBars';

const GetParentResourceName = () => {
  return 'null-core';
};
import Speedometer from '@modules/hud/Speedometer';
import AmmoHud from '@modules/hud/AmmoHud';
import ProgressBar from '@modules/hud/ProgressBar';
import PlayerInfo from '@modules/hud/PlayerInfo';
import PlayerInfoModern from '@modules/hud/PlayerInfoModern';
import PlayerInfoModernMinimal from '@modules/hud/PlayerInfoModernMinimal';
import HelpNotification from '@modules/hud/HelpNotification';
import Indicator from '@modules/hud/Indicator';
import InventoryNotifications from '@modules/hud/InventoryNotifications';
import NotificationSystem from '@modules/notifications/NotificationSystem';
import Chat from '@modules/chat/Chat';
import ContextMenu from '@modules/context-menu/ContextMenu';
import { ContextMenuData } from '@modules/context-menu/types';
import Boutique from '@modules/tablet/boutique/Boutique';
import IllegalTablet from '@modules/tablet/illegal/IllegalTablet';
import IllegalDevice from '@modules/tablet/illegal-device/IllegalDevice';
import AnimationsMenu from '@modules/animations/AnimationsMenu';
import WeaponCustomMenu from '@modules/weapon-custom/WeaponCustomMenu';
import ShopUI from '@modules/tablet/shop/ShopUI';
import PoliceTablet from '@modules/tablet/police/PoliceTablet';
import RulesTablet from '@modules/tablet/rules/RulesTablet';
import Tutorial from '@modules/tutorial/Tutorial';
import Inventory from '@modules/inventory/Inventory';
import Shop from '@/modules/ped-shop/Shop';
import UtilsShopView from '@/modules/ped-shop/UtilsShopView';
import DevPanel from '@modules/devpanel/DevPanel';
import WaveBgPlayground from '@modules/wave-bg-playground/WaveBgPlayground';
import DriveSchool from '@/modules/tablet/driveschool/DriveSchool';
import CharacterCreator from '@modules/character-creator/CharacterCreator';
import ShowcaseLayer from '@modules/showcase/ShowcaseLayer';
import Objectives from '@modules/objectives/Objectives';
import Garage from '@/modules/tablet/garage/Garage';
import Bank from '@/modules/tablet/bank/Bank';
import ATM from '@/modules/atm/ATM';
import CatalogTablet from '@modules/tablet/catalog/CatalogTablet';
import Dealership from '@modules/tablet/dealership/Dealership';
import Realtor from '@modules/tablet/realtor/Realtor';
import Burglary from '@modules/burglary/Burglary';
import DebugMenu from '@modules/debug/DebugMenu';
import SocietyTablet from '@modules/tablet/society/SocietyTablet';
import PawnShop from '@modules/tablet/pawnshop/PawnShop';
import IDCard from '@modules/idcard/IDCard';
import ImageMaker from '@modules/image-maker/ImageMaker';
import PauseMenu from '@modules/pause-menu/PauseMenu';
import Radio from '@modules/radio/Radio';
import PropInteract from '@modules/prop-interact/PropInteract';
import CraftTablet from '@modules/tablet/restaurant/CraftTablet';
import SupplierTablet from '@modules/tablet/restaurant/SupplierTablet';
import FreejobTablet from '@modules/freejob/FreejobTablet';
import FreejobHUD from '@modules/freejob/FreejobHUD';
import FreejobMarker from '@modules/freejob/FreejobMarker';
import FreejobInfo from '@modules/freejob/FreejobInfo';
import TaxiHUD from '@modules/tablet/taxi/TaxiHUD';
import TaxiBoard from '@modules/tablet/taxi/TaxiBoard';
import MeOverlay from '@modules/me/MeOverlay';
import '@modules/menu/index.css';

interface ServerConfig {
  serverName: string;
  serverColor: string;
  serverLuaColor: string;
  serverIcon: string;
  serverDiscord: string;
  serverBackground: string;
}

function App() {
  // Interactions state
  const [inputVisible, setInputVisible] = useState(false);
  const [inputData, setInputData] = useState<any>(null);

  const [confirmVisible, setConfirmVisible] = useState(false);
  const [confirmData, setConfirmData] = useState<any>(null);

  const [hudVisible, setHudVisible] = useState(true);

  const [hudEditorVisible, setHudEditorVisible] = useState(false);
  const [boutiqueVisible, setBoutiqueVisible] = useState(false);
  const [boutiqueInitialData, setBoutiqueInitialData] = useState<any>(null);
  const [illegalTabletVisible, setIllegalTabletVisible] = useState(false);
  const [illegalDeviceVisible, setIllegalDeviceVisible] = useState(false);
  const [animationsVisible, setAnimationsVisible] = useState(false);
  const [weaponCustomVisible, setWeaponCustomVisible] = useState(false);
  const [shopuiVisible, setShopuiVisible] = useState(false);
  const [policeTabletVisible, setPoliceTabletVisible] = useState(false);
  const [rulesTabletVisible, setRulesTabletVisible] = useState(false);
  const [tutorialVisible, setTutorialVisible] = useState(false);
  const [inventoryVisible, setInventoryVisible] = useState(false);
  const [shopVisible, setShopVisible] = useState(false);
  const [devPanelVisible, setDevPanelVisible] = useState(false);
  const [wavePlaygroundVisible, setWavePlaygroundVisible] = useState(false);
  const [driveSchoolVisible, setDriveSchoolVisible] = useState(false);
  const [characterCreatorVisible, setCharacterCreatorVisible] = useState(false);
  const [garageVisible, setGarageVisible] = useState(false);
  const [bankVisible, setBankVisible] = useState(false);
  const [atmVisible, setAtmVisible] = useState(false);
  const [catalogVisible, setCatalogVisible] = useState(false);
  const [dealershipVisible, setDealershipVisible] = useState(false);
  const [realtorVisible, setRealtorVisible] = useState(false);
  const [debugMenuVisible, setDebugMenuVisible] = useState(false);
  const [societyTabletVisible, setSocietyTabletVisible] = useState(false);
  const [pawnshopVisible, setPawnshopVisible] = useState(false);
  const [idcardVisible, setIdcardVisible] = useState(false);
  const [imageMakerVisible, setImageMakerVisible] = useState(false);
  const [pauseMenuVisible, setPauseMenuVisible] = useState(false);
  const [radioVisible, setRadioVisible] = useState(false);
  const [propInteractVisible, setPropInteractVisible] = useState(false);
  const [craftTabletVisible, setCraftTabletVisible] = useState(false);
  const [supplierTabletVisible, setSupplierTabletVisible] = useState(false);
  const [freejobTabletVisible, setFreejobTabletVisible] = useState(false);
  const [freejobHUDVisible, setFreejobHUDVisible] = useState(false);
  const [freejobInfoVisible, setFreejobInfoVisible] = useState(false);
  const [taxiBoardVisible, setTaxiBoardVisible] = useState(false);
  const [itemGridVisible, setItemGridVisible] = useState(false);
  const [itemGridData, setItemGridData] = useState<{ items: GridItem[]; title: string; mode: 'item' | 'weapon' | 'vehicle' }>({ items: [], title: '', mode: 'item' });
  const isDev = window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1';
  const [statusBarColors, setStatusBarColors] = useState<any>({});
  const [speedometerColors, setSpeedometerColors] = useState<any>({});
  // Variant selection for speedometer / ammo HUD — default to "hologram" (3D).
  const [speedVariant, setSpeedVariant] = useState<'hologram' | '2d'>('hologram');
  const [ammoVariant, setAmmoVariant] = useState<'hologram' | '2d'>('hologram');
  const [ammoEnabled, setAmmoEnabled] = useState<boolean>(true);
  const [playerInfoVariant, setPlayerInfoVariant] = useState<'modern' | 'compact' | 'minimal'>('modern');

  const [serverConfig, setServerConfig] = useState<ServerConfig>({
    serverName: 'Server Name',
    serverColor: '#646464',
    serverLuaColor: '~s~',
    serverIcon: '',
    serverDiscord: '',
    serverBackground: ''
  });

  // Global HUD config (theme, style, primary color)
  const [globalConfig, setGlobalConfig] = useState({
    primaryColor: '#646464',
    theme: 'dark' as 'dark' | 'light',
    style: 'modern' as 'modern' | 'compact'
  });

  // Menu state
  const [menuState, setMenuState] = useState<MenuState>({
    visible: false,
    title: '',
    subtitle: '',
    items: [],
    selectedIndex: 0,
    position: { x: 0.170, y: 0.030 },
    previewImage: undefined,
    maxVisibleItems: 10
  });
  const [menuHiding, setMenuHiding] = useState(false);
  const [cursorEnabled, setCursorEnabled] = useState(false);
  const menuCloseTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  // Context Menu state
  const [contextMenuVisible, setContextMenuVisible] = useState(false);
  const [contextMenuData, setContextMenuData] = useState<ContextMenuData | null>(null);

  // Load colors, variants and global config from localStorage on mount, and
  // refresh when the HUD layout changes (HUDEditor dispatches 'hudLayoutChanged').
  useEffect(() => {
    const readLayout = () => {
      const savedLayout = localStorage.getItem('hudLayout');
      if (!savedLayout) return;
      try {
        const layout = JSON.parse(savedLayout);
        const statusBarsModule = layout.find((m: any) => m.id === 'status_bars');
        if (statusBarsModule?.colors) setStatusBarColors(statusBarsModule.colors);

        const speedometerModule = layout.find((m: any) => m.id === 'speedometer');
        if (speedometerModule?.colors) setSpeedometerColors(speedometerModule.colors);
        const sv = speedometerModule?.colors?.variant;
        setSpeedVariant(sv === '2d' ? '2d' : 'hologram');

        const ammoModule = layout.find((m: any) => m.id === 'ammo');
        const av = ammoModule?.colors?.variant;
        setAmmoVariant(av === '2d' ? '2d' : 'hologram');
        if (typeof ammoModule?.enabled === 'boolean') setAmmoEnabled(ammoModule.enabled);

        const playerInfoModule = layout.find((m: any) => m.id === 'player_info');
        const piv = playerInfoModule?.colors?.variant;
        setPlayerInfoVariant(piv === 'compact' ? 'compact' : (piv === 'minimal' ? 'minimal' : 'modern'));
      } catch (error) {
        console.error('[App] Error loading layout from localStorage:', error);
      }
    };
    readLayout();
    window.addEventListener('hudLayoutChanged', readLayout);
    return () => window.removeEventListener('hudLayoutChanged', readLayout);
  }, []);

  useEffect(() => {
    // Keep legacy behaviour: also load global config from localStorage on mount.

    // Load global config including custom primaryColor if player has set one
    const savedGlobalConfig = localStorage.getItem('hudGlobalConfig');
    if (savedGlobalConfig) {
      try {
        const parsed = JSON.parse(savedGlobalConfig);
        setGlobalConfig(prev => ({
          ...prev,
          theme: parsed.theme || prev.theme,
          style: parsed.style || prev.style,
          primaryColor: parsed.primaryColor || prev.primaryColor // Load custom color if exists
        }));
      } catch (error) {
        console.error('[App] Error loading global config:', error);
      }
    }
  }, []);

  const handleMessage = useCallback((event: MessageEvent) => {
    // const data = event.data;
    // const action = data.action || data.type;

    const action = event.data.action || event.data.type;
    const { data } = event.data

    switch (action) {
      // Config 
      case 'setConfig':
        // Si serverColor est fourni, mettre à jour la config serveur
        if (data?.serverColor || data?.data?.serverColor) {
          const newServerColor = data?.serverColor || data?.data?.serverColor || '#42a5f5';

          setServerConfig({
            serverName: data?.serverName || data?.data?.serverName || 'Null',
            serverColor: newServerColor,
            serverLuaColor: data?.serverLuaColor || data?.data?.serverLuaColor || '~b~',
            serverIcon: data?.serverIcon || data?.data?.serverIcon || '',
            serverDiscord: data?.serverDiscord || data?.data?.serverDiscord || '',
            serverBackground: data?.serverBackground || data?.data?.serverBackground || ''
          });

          // Ne mettre à jour primaryColor que si le joueur n'a pas de couleur personnalisée
          // (une couleur différente de la couleur par défaut #646464)
          const savedConfig = localStorage.getItem('hudGlobalConfig');
          let hasCustomColor = false;

          if (savedConfig) {
            try {
              const parsed = JSON.parse(savedConfig);
              const savedColor = parsed.primaryColor;
              // Considérer comme personnalisé seulement si différent de la couleur par défaut
              hasCustomColor = savedColor && savedColor !== '#646464';
            } catch (e) {
              console.error('[App] Error parsing savedConfig:', e);
            }
          }

          if (!hasCustomColor) {
            setGlobalConfig(prev => ({
              ...prev,
              primaryColor: newServerColor
            }));
          }
        }

        // Handle menu default position from config
        if (data?.defaultPosition) {
          setMenuState(prev => ({
            ...prev,
            position: data.defaultPosition
          }));
        }
        break;

      // Input Dialog
      case 'openInput':
        const inputDialogData = {
          title: event.data.title,
          fields: event.data.fields,
          options: event.data.options || null,
          size: event.data.size || null
        };
        setInputData(inputDialogData);
        setInputVisible(true);
        soundManager.play('open');
        break;

      case 'closeInput':
        setInputVisible(false);
        setInputData(null);
        soundManager.play('close');
        break;

      // Confirm Dialog
      case 'openConfirm':
        const confirmDialogData = {
          title: event.data.title,
          message: event.data.message,
          type: event.data.type,
          yesLabel: event.data.yesLabel,
          noLabel: event.data.noLabel
        };
        setConfirmData(confirmDialogData);
        setConfirmVisible(true);
        soundManager.play('open');
        break;

      case 'closeConfirm':
        setConfirmVisible(false);
        setConfirmData(null);
        soundManager.play('close');
        break;

      // Menu (RageUI)
      case 'openMenu':
        // Annuler tout timer de fermeture en cours pour éviter la race condition
        if (menuCloseTimerRef.current) {
          clearTimeout(menuCloseTimerRef.current);
          menuCloseTimerRef.current = null;
        }
        setMenuHiding(false);
        setMenuState(prev => ({
          ...prev,
          visible: true,
          title: data?.title || data.title || '',
          subtitle: data?.subtitle || data.subtitle || '',
          position: data?.position || data.position || prev.position,
          maxVisibleItems: data?.maxVisibleItems || data.maxVisibleItems || 10,
          items: [],
          selectedIndex: 0,
          previewImage: undefined,
          transition: data?.transition || null
        }));
        soundManager.play('open');
        break;

      case 'closeMenu':
        setMenuHiding(true);
        setCursorEnabled(false);
        soundManager.play('close');
        // Utiliser un ref pour pouvoir annuler le timer si openMenu arrive entre-temps
        if (menuCloseTimerRef.current) {
          clearTimeout(menuCloseTimerRef.current);
        }
        menuCloseTimerRef.current = setTimeout(() => {
          menuCloseTimerRef.current = null;
          setMenuState(prev => ({ ...prev, visible: false, items: [], previewImage: undefined }));
          setMenuHiding(false);
        }, 100);
        break;

      case 'setCursor':
        setCursorEnabled(data?.enabled || data.enabled || false);
        break;

      // Context Menu
      case 'openContextMenu':
        setContextMenuData({
          title: data?.title || data.title,
          items: data?.items || data.items || [],
          position: data?.position || data.position || { x: 0, y: 0 },
          entityType: data?.entityType || data.entityType
        });
        setContextMenuVisible(true);
        soundManager.play('open');
        break;

      case 'updateContextMenu':
        // Mettre à jour les données du context-menu sans le fermer
        setContextMenuData({
          title: data?.title || data.title,
          items: data?.items || data.items || [],
          position: data?.position || data.position || contextMenuData?.position || { x: 0, y: 0 },
          entityType: data?.entityType || data.entityType
        });
        break;

      case 'closeContextMenu':
        soundManager.play('close');

        // Notifier le Lua pour désactiver le NUI Focus
        fetch(`https://${GetParentResourceName()}/contextMenuClosed`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({})
        })
          .then(resp => {
            return resp.text();
          })
          .catch(err => {
            console.error('[App] Error sending contextMenuClosed:', err);
          });

        setContextMenuVisible(false);
        setTimeout(() => {
          setContextMenuData(null);
        }, 150);
        break;

      case 'menu:closeAll':
        if (contextMenuVisible) {
          setContextMenuVisible(false);
          setTimeout(() => {
            setContextMenuData(null);
          }, 150);
        }
        break;

      case 'setPreview':
        setMenuState(prev => ({ ...prev, previewImage: data?.image || data.image }));
        break;

      case 'setItems':
        setMenuState(prev => {
          const items = data?.items || data.items || [];
          const isSelectable = (item?: MenuState['items'][number]) =>
            item && item.type !== 'separator' && item.type !== 'info' && item.type !== 'infopanel';
          let selectedIndex = data?.index !== undefined ? data.index :
            data.index !== undefined ? data.index : prev.selectedIndex;

          if (!isSelectable(items[selectedIndex])) {
            const firstSelectable = items.findIndex(isSelectable);
            selectedIndex = firstSelectable !== -1 ? firstSelectable : 0;
          }

          return {
            ...prev,
            items,
            selectedIndex
          };
        });
        break;

      case 'updateTitle':
        setMenuState(prev => ({ ...prev, title: data?.title || data.title }));
        break;

      case 'updateSubtitle':
        setMenuState(prev => ({ ...prev, subtitle: data?.subtitle || data.subtitle }));
        break;

      case 'navigate':
        setMenuState(prev => {
          let newIndex = prev.selectedIndex
          const enabledItems = prev.items.map((item, i) => ({ item, i })).filter(x => x.item.type !== 'separator' && x.item.type !== 'info' && x.item.type !== 'infopanel')
          const currentEnabledIndex = enabledItems.findIndex(x => x.i === prev.selectedIndex)
          if (data.direction === 'up') {
            let nextEnabledIndex = currentEnabledIndex - 1
            if (nextEnabledIndex < 0) nextEnabledIndex = enabledItems.length - 1
            newIndex = enabledItems[nextEnabledIndex]?.i ?? prev.selectedIndex
            soundManager.play('navigate');
          } else if (data.direction === 'down') {
            let nextEnabledIndex = currentEnabledIndex + 1
            if (nextEnabledIndex >= enabledItems.length) nextEnabledIndex = 0
            newIndex = enabledItems[nextEnabledIndex]?.i ?? prev.selectedIndex
            soundManager.play('navigate');
          } else if (data.direction === 'left' || data.direction === 'right') {
            const item = prev.items[prev.selectedIndex]
            if (item) {
              const newItems = [...prev.items]
              if (item.type === 'list' && item.items) {
                let val = (item.value as number) || 1
                if (data.direction === 'left') {
                  val = val <= 1 ? item.items.length : val - 1
                } else {
                  val = val >= item.items.length ? 1 : val + 1
                }
                newItems[prev.selectedIndex] = { ...item, value: val }
                fetch(`https://${GetParentResourceName()}/itemChanged`, {
                  method: 'POST',
                  body: JSON.stringify({ index: prev.selectedIndex, value: val })
                })
                soundManager.play('slider');
              } else if (item.type === 'slider') {
                let val = (item.value as number) || 1
                if (data.direction === 'left') {
                  val = Math.max(item.min || 1, val - 1)
                } else {
                  val = Math.min(item.max || 100, val + 1)
                }
                newItems[prev.selectedIndex] = { ...item, value: val }
                fetch(`https://${GetParentResourceName()}/itemChanged`, {
                  method: 'POST',
                  body: JSON.stringify({ index: prev.selectedIndex, value: val })
                })
                soundManager.play('slider');
              } else if (item.type === 'percentagepanel') {
                let val = (item.value as number) || 0
                if (data.direction === 'left') {
                  val = Math.max(0, val - 1)
                } else {
                  val = Math.min(100, val + 1)
                }
                newItems[prev.selectedIndex] = { ...item, value: val }
                fetch(`https://${GetParentResourceName()}/itemChanged`, {
                  method: 'POST',
                  body: JSON.stringify({ index: prev.selectedIndex, value: val })
                })
                soundManager.play('slider');
              }
              return { ...prev, items: newItems }
            }
          }
          fetch(`https://${GetParentResourceName()}/indexChanged`, {
            method: 'POST',
            body: JSON.stringify({ index: newIndex })
          })
          return { ...prev, selectedIndex: newIndex }
        })
        break

      case 'select':
        setMenuState(prev => {
          const item = prev.items[prev.selectedIndex]
          if (item && item.enabled !== false) {
            if (item.type === 'checkbox') {
              const newItems = [...prev.items]
              newItems[prev.selectedIndex] = { ...item, checked: !item.checked }
              fetch(`https://${GetParentResourceName()}/itemSelected`, {
                method: 'POST',
                body: JSON.stringify({ index: prev.selectedIndex, value: !item.checked })
              })
              soundManager.play('toggle');
              return { ...prev, items: newItems }
            } else if (item.type === 'collapsible') {
              const newItems = [...prev.items]
              newItems[prev.selectedIndex] = { ...item, collapsed: !item.collapsed }
              fetch(`https://${GetParentResourceName()}/itemSelected`, {
                method: 'POST',
                body: JSON.stringify({ index: prev.selectedIndex, value: item.value })
              })
              soundManager.play('click');
              return { ...prev, items: newItems }
            } else {
              fetch(`https://${GetParentResourceName()}/itemSelected`, {
                method: 'POST',
                body: JSON.stringify({ index: prev.selectedIndex, value: item.value })
              })
              soundManager.play('click');
            }
          }
          return prev
        })
        break

      case 'boutique:open':
        setBoutiqueInitialData(event.data);
        setBoutiqueVisible(true);
        soundManager.play('open');
        break;

      case 'boutique:close':
        setBoutiqueVisible(false);
        setBoutiqueInitialData(null);
        soundManager.play('close');
        break;

      case 'illegalTablet:open':
        setIllegalTabletVisible(true);
        soundManager.play('open');
        break;

      case 'illegalTablet:close':
        setIllegalTabletVisible(false);
        soundManager.play('close');
        break;

      case 'illegalDevice:open':
        setIllegalDeviceVisible(true);
        soundManager.play('open');
        break;

      case 'illegalDevice:close':
        setIllegalDeviceVisible(false);
        soundManager.play('close');
        break;

      case 'animations:open':
        setAnimationsVisible(true);
        soundManager.play('open');
        break;

      case 'animations:close':
        setAnimationsVisible(false);
        soundManager.play('close');
        break;

      case 'weaponCustom:open':
        setWeaponCustomVisible(true);
        soundManager.play('open');
        break;

      case 'weaponCustom:close':
        setWeaponCustomVisible(false);
        soundManager.play('close');
        break;

      case 'shopui:open':
        setShopuiVisible(true);
        soundManager.play('open');
        break;

      case 'shopui:close':
        setShopuiVisible(false);
        soundManager.play('close');
        break;

      case 'policeTablet:open':
        setPoliceTabletVisible(true);
        soundManager.play('open');
        break;

      case 'policeTablet:close':
        setPoliceTabletVisible(false);
        soundManager.play('close');
        break;

      case 'pawnshop:open':
        setPawnshopVisible(true);
        soundManager.play('open');
        break;

      case 'pawnshop:close':
        setPawnshopVisible(false);
        soundManager.play('close');
        break;

      case 'craftTablet:open':
        setCraftTabletVisible(true);
        soundManager.play('open');
        break;

      case 'craftTablet:close':
        setCraftTabletVisible(false);
        soundManager.play('close');
        break;

      case 'supplierTablet:open':
        setSupplierTabletVisible(true);
        soundManager.play('open');
        break;

      case 'supplierTablet:close':
        setSupplierTabletVisible(false);
        soundManager.play('close');
        break;

      case 'freejobTablet:open':
        setFreejobTabletVisible(true);
        soundManager.play('open');
        break;

      case 'freejobTablet:close':
        setFreejobTabletVisible(false);
        soundManager.play('close');
        break;

      case 'freejobHUD:open':
        setFreejobHUDVisible(true);
        break;

      case 'freejobHUD:close':
        setFreejobHUDVisible(false);
        break;

      case 'freejobInfo:open':
        setFreejobInfoVisible(true);
        break;

      case 'freejobInfo:close':
        setFreejobInfoVisible(false);
        break;

      case 'taxiBoard:open':
        setTaxiBoardVisible(true);
        soundManager.play('open');
        break;

      case 'taxiBoard:close':
        setTaxiBoardVisible(false);
        soundManager.play('close');
        break;

      case 'idcard:show':
        setIdcardVisible(true);
        break;

      case 'idcard:hide':
        setIdcardVisible(false);
        break;

      case 'imagemaker:open':
        setImageMakerVisible(true);
        soundManager.play('open');
        break;

      case 'imagemaker:close':
        setImageMakerVisible(false);
        soundManager.play('close');
        break;

      case 'pauseMenu:open':
        setPauseMenuVisible(true);
        break;

      case 'pauseMenu:close':
        setPauseMenuVisible(false);
        break;

      case 'radio:open':
        setRadioVisible(true);
        soundManager.play('open');
        break;

      case 'radio:close':
        setRadioVisible(false);
        soundManager.play('close');
        break;

      case 'propInteract:open':
        setPropInteractVisible(true);
        break;

      case 'propInteract:close':
        setPropInteractVisible(false);
        break;

      case 'openItemGrid':
        setItemGridData({
          items: data?.items || data.items || [],
          title: data?.title || data.title || 'Sélectionner',
          mode: data?.mode || data.mode || 'item',
        });
        setItemGridVisible(true);
        break;

      case 'closeItemGrid':
        setItemGridVisible(false);
        break;

      case 'reglement:open':
        setRulesTabletVisible(true);
        soundManager.play('open');
        break;

      case 'reglement:close':
        setRulesTabletVisible(false);
        soundManager.play('close');
        break;

      case 'tutorial:open':
        setTutorialVisible(true);
        soundManager.play('open');
        break;

      case 'tutorial:close':
        setTutorialVisible(false);
        soundManager.play('close');
        break;

      case 'newInventory:open':
        setInventoryVisible(true);
        soundManager.play('open');
        break;

      case 'newInventory:close':
        setInventoryVisible(false);
        soundManager.play('close');
        break;

      case 'shop:open':
        setShopVisible(true);
        soundManager.play('open');
        break;

      case 'shop:close':
        setShopVisible(false);
        soundManager.play('close');
        break;

      case 'devPanel:open':
        setDevPanelVisible(true);
        soundManager.play('open');
        break;

      case 'devPanel:close':
        setDevPanelVisible(false);
        soundManager.play('close');
        break;

      case 'wavePlayground:open':
        setWavePlaygroundVisible(true);
        soundManager.play('open');
        break;

      case 'wavePlayground:close':
        setWavePlaygroundVisible(false);
        soundManager.play('close');
        break;

      case 'driveSchool:open':
        setDriveSchoolVisible(true);
        soundManager.play('open');
        break;

      case 'driveSchool:close':
        setDriveSchoolVisible(false);
        soundManager.play('close');
        break;

      case 'newCreator:open':
        setCharacterCreatorVisible(true);
        soundManager.play('open');
        break;

      case 'newCreator:close':
        setCharacterCreatorVisible(false);
        soundManager.play('close');
        break;

      case 'garage:open':
        setGarageVisible(true);
        soundManager.play('open');
        break;

      case 'garage:close':
        setGarageVisible(false);
        soundManager.play('close');
        break;

      case 'bank:open':
        setBankVisible(true);
        soundManager.play('open');
        break;

      case 'bank:close':
        setBankVisible(false);
        soundManager.play('close');
        break;

      case 'atm:open':
        setAtmVisible(true);
        soundManager.play('open');
        break;

      case 'atm:close':
        setAtmVisible(false);
        soundManager.play('close');
        break;

      case 'catalog:open':
        setCatalogVisible(true);
        soundManager.play('open');
        break;

      case 'catalog:close':
        setCatalogVisible(false);
        soundManager.play('close');
        break;

      case 'societyTablet:open':
        setSocietyTabletVisible(true);
        soundManager.play('open');
        break;

      case 'societyTablet:close':
        setSocietyTabletVisible(false);
        soundManager.play('close');
        break;

      case 'dealership:open':
        setDealershipVisible(true);
        soundManager.play('open');
        break;

      case 'dealership:close':
        setDealershipVisible(false);
        soundManager.play('close');
        break;

      case 'realtor:open':
        setRealtorVisible(true);
        soundManager.play('open');
        break;

      case 'realtor:close':
        setRealtorVisible(false);
        soundManager.play('close');
        break;

      case 'openHUDEditor':
        setHudEditorVisible(true);
        soundManager.play('open');
        console.log("openHUDEditor : setHudEditorVisible(true)");
        break;

      case 'closeHUDEditor':
        console.log("closeHUDEditor : setHudEditorVisible(false)");
        setHudEditorVisible(false);
        soundManager.play('close');
        break;

      case 'setStatusBarColors':
        // Update status bar colors immediately when changed in config modal
        if (data && data.colors) {
          setStatusBarColors(data.colors);
        }
        break;

      case 'setSpeedometerColors':
        // Update speedometer colors immediately when changed in config modal
        if (data && data.colors) {
          setSpeedometerColors(data.colors);
        }
        break;

      case 'hud-hide':
        if (data && data.state !== undefined) {
          setHudVisible(!data.state);
        }
        break;

      case 'updateGlobalConfig':
        if (data) {
          setGlobalConfig(data);
          localStorage.setItem('hudGlobalConfig', JSON.stringify(data));
        }
        break;

      case 'loadDefaultLayout': {
        // First connection: no saved layout exists, generate defaults and save to localStorage
        const defaultStates = getDefaultModuleStates();
        const defaultLayout = Array.from(defaultStates.values()).map(state => ({
          id: state.id,
          position: state.position,
          size: state.size,
          anchor: state.anchor,
        }));
        localStorage.setItem('hudLayout', JSON.stringify(defaultLayout));
        window.dispatchEvent(new Event('hudLayoutChanged'));
        // Also push to HUDPositionManager via saveHUDLayoutToStorage
        window.postMessage({ action: 'saveHUDLayoutToStorage', layout: defaultLayout }, '*');
        break;
      }

      case 'saveHUDLayoutToStorage':
        // Load colors from saved layout
        if (data && data.layout && Array.isArray(data.layout)) {
          const statusBarsModule = data.layout.find((m: any) => m.id === 'status_bars');
          if (statusBarsModule?.colors) {
            setStatusBarColors(statusBarsModule.colors);
          }
          const speedometerModule = data.layout.find((m: any) => m.id === 'speedometer');
          if (speedometerModule?.colors) {
            setSpeedometerColors(speedometerModule.colors);
          }
          const playerInfoModule = data.layout.find((m: any) => m.id === 'player_info');
          if (playerInfoModule?.colors?.variant) {
            setPlayerInfoVariant(playerInfoModule.colors.variant === 'compact' ? 'compact' : (playerInfoModule.colors.variant === 'minimal' ? 'minimal' : 'modern'));
          }
          localStorage.setItem('hudLayout', JSON.stringify(data.layout));
        }
        break;

    }
  }, []);

  useEffect(() => {
    window.addEventListener('message', handleMessage);
    return () => window.removeEventListener('message', handleMessage);
  }, [handleMessage]);

  // F8 Debug Menu (dev mode only)
  useEffect(() => {
    if (!isDev) return;
    const handler = (e: KeyboardEvent) => {
      if (e.key === 'F8') {
        e.preventDefault();
        setDebugMenuVisible(prev => !prev);
      }
    };
    window.addEventListener('keydown', handler);
    return () => window.removeEventListener('keydown', handler);
  }, [isDev]);

  return (
    <div className="null-ui-container" data-theme={globalConfig.theme} data-style={globalConfig.style}>
      {/* Interactions Module */}
      <InputDialog
        visible={inputVisible}
        data={inputData}
        onClose={() => setInputVisible(false)}
        serverConfig={serverConfig}
        primaryColor={globalConfig.primaryColor}
        hudEditorOpen={hudEditorVisible}
      />

      <ConfirmDialog
        visible={confirmVisible}
        data={confirmData}
        onClose={() => setConfirmVisible(false)}
        serverConfig={serverConfig}
        primaryColor={globalConfig.primaryColor}
        hudEditorOpen={hudEditorVisible}
      />

      <Interaction3D
        serverConfig={serverConfig}
      />

      <DoorPrompt primaryColor={globalConfig.primaryColor} />

      <DoorlockManager primaryColor={globalConfig.primaryColor} />

      <DoorCodePad primaryColor={globalConfig.primaryColor} />

      {/* Multiple InfoDialog instances for different categories */}
      <InfoDialog
        key="info_dialog"
        serverConfig={serverConfig}
        primaryColor={globalConfig.primaryColor}
        serverLuaColor={serverConfig.serverLuaColor}
        isStaff={false}
        hudEditorOpen={hudEditorVisible}
        globalConfig={globalConfig}
      />

      <InfoDialog
        key="info_dialog_staff"
        serverConfig={serverConfig}
        primaryColor={globalConfig.primaryColor}
        serverLuaColor={serverConfig.serverLuaColor}
        isStaff={true}
        hudEditorOpen={hudEditorVisible}
        globalConfig={globalConfig}
      />

      <AnnouncementDialog
        serverConfig={serverConfig}
        primaryColor={globalConfig.primaryColor}
        hudEditorOpen={hudEditorVisible}
      />

      {/* HUD Modules */}
      {hudVisible && (
        <>
          <StatusBars
            serverConfig={serverConfig}
            hudEditorOpen={hudEditorVisible}
            statusColors={statusBarColors}
            globalConfig={globalConfig}
          />
          {speedVariant === '2d' && (
            <Speedometer
              serverConfig={serverConfig}
              hudEditorOpen={hudEditorVisible}
              speedometerColors={speedometerColors}
              globalConfig={globalConfig}
            />
          )}
          {ammoVariant === '2d' && ammoEnabled && (
            <AmmoHud
              hudEditorOpen={hudEditorVisible}
              primaryColor={globalConfig.primaryColor}
            />
          )}
          <ProgressBar
            serverConfig={serverConfig}
            hudEditorOpen={hudEditorVisible}
            globalConfig={globalConfig}
          />
          {playerInfoVariant === 'minimal' ? (
            <PlayerInfoModernMinimal
              serverConfig={serverConfig}
              primaryColor={globalConfig.primaryColor}
              hudEditorOpen={hudEditorVisible}
              globalConfig={globalConfig}
            />
          ) : playerInfoVariant === 'modern' ? (
            <PlayerInfoModern
              serverConfig={serverConfig}
              primaryColor={globalConfig.primaryColor}
              hudEditorOpen={hudEditorVisible}
              globalConfig={globalConfig}
            />
          ) : (
            <PlayerInfo
              serverConfig={serverConfig}
              primaryColor={globalConfig.primaryColor}
              hudEditorOpen={hudEditorVisible}
              globalConfig={globalConfig}
            />
          )}
          <HelpNotification
            hudEditorOpen={hudEditorVisible}
            primaryColor={globalConfig.primaryColor}
          />
          <Indicator primaryColor={globalConfig.primaryColor} />
          <InventoryNotifications
            hudEditorOpen={hudEditorVisible}
          />
        </>
      )}

      {/* Objectives (always rendered, persists through HUD hide/show) */}
      <Objectives
        primaryColor={globalConfig.primaryColor}
      />

      {/* /me 3D overlay rendered in NUI instead of GTA text natives */}
      <MeOverlay />

      {/* Menu Module (RageUI) */}
      {(menuState.visible || menuHiding) && (
        <Menu
          title={menuState.title}
          subtitle={menuState.subtitle}
          items={menuState.items}
          selectedIndex={menuState.selectedIndex}
          position={menuState.position}
          previewImage={menuState.previewImage}
          maxVisibleItems={menuState.maxVisibleItems}
          primaryColor={globalConfig.primaryColor}
          serverLuaColor={serverConfig.serverLuaColor}
          hudEditorOpen={hudEditorVisible}
          isHiding={menuHiding}
          transition={menuState.transition}
        />
      )}

      {/* Notification System */}
      <NotificationSystem
        primaryColor={globalConfig.primaryColor}
        serverColor={serverConfig.serverColor}
        serverLuaColor={serverConfig.serverLuaColor}
        hudEditorOpen={hudEditorVisible}
        serverLogo={serverConfig.serverIcon}
      />

      {/* Chat System */}
      <Chat
        hudEditorOpen={hudEditorVisible}
        primaryColor={globalConfig.primaryColor}
      />

      {/* Context Menu */}
      {contextMenuVisible && contextMenuData && (
        <ContextMenu
          visible={contextMenuVisible}
          data={contextMenuData}
          primaryColor={globalConfig.primaryColor}
          onClose={(keepNuiFocus) => {

            // Notifier le Lua pour désactiver le NUI Focus via postMessage au parent
            // Car l'iframe ne peut pas faire de fetch direct vers les callbacks Lua
            window.parent.postMessage({
              action: 'closeContextMenu',
              keepNuiFocus: keepNuiFocus
            }, '*');

            setContextMenuVisible(false);
            setTimeout(() => {
              setContextMenuData(null);
            }, 150);
          }}
        />
      )}

      {/* Animations Menu */}
      <AnimationsMenu
        visible={animationsVisible}
        onClose={() => setAnimationsVisible(false)}
        primaryColor={globalConfig.primaryColor}
      />

      {/* Weapon Customization Menu */}
      <WeaponCustomMenu
        visible={weaponCustomVisible}
        onClose={() => setWeaponCustomVisible(false)}
        primaryColor={globalConfig.primaryColor}
      />

      {/* Boutique */}
      <Boutique
        visible={boutiqueVisible}
        onClose={() => setBoutiqueVisible(false)}
        primaryColor={globalConfig.primaryColor}
        initialData={boutiqueInitialData}
        serverConfig={serverConfig}
      />

      {/* Shop UI */}
      <ShopUI
        visible={shopuiVisible}
        onClose={() => setShopuiVisible(false)}
        primaryColor={globalConfig.primaryColor}
      />

      {/* Police Tablet */}
      <PoliceTablet
        visible={policeTabletVisible}
        onClose={() => setPoliceTabletVisible(false)}
        primaryColor={globalConfig.primaryColor}
      />

      {/* Illegal Tablet */}
      <IllegalTablet
        visible={illegalTabletVisible}
        onClose={() => setIllegalTabletVisible(false)}
        primaryColor={globalConfig.primaryColor}
      />

      {/* Illegal Device (handheld tablet item) */}
      <IllegalDevice
        visible={illegalDeviceVisible}
        onClose={() => setIllegalDeviceVisible(false)}
        primaryColor={globalConfig.primaryColor}
      />

      {/* Rules Tablet */}
      <RulesTablet
        visible={rulesTabletVisible}
        onClose={() => setRulesTabletVisible(false)}
        primaryColor={globalConfig.primaryColor}
        serverConfig={serverConfig}
      />

      {/* Tutorial */}
      <Tutorial
        visible={tutorialVisible}
        onClose={() => setTutorialVisible(false)}
        primaryColor={globalConfig.primaryColor}
        serverConfig={serverConfig}
      />

      {/* New Inventory */}
      <Inventory
        visible={inventoryVisible}
        onClose={() => setInventoryVisible(false)}
        primaryColor={globalConfig.primaryColor}
        serverIcon={serverConfig.serverIcon}
        serverName={serverConfig.serverName}
      />

      {/* Shop (Clothing & Accessories) */}
      <Shop
        visible={shopVisible}
        onClose={() => setShopVisible(false)}
        primaryColor={globalConfig.primaryColor}
      />

      {/* Utils Shop (Barber / Makeup / Tattoo) — même state shopVisible que Shop,
          chacun ignore les modes qui ne lui correspondent pas via le payload. */}
      <UtilsShopView
        visible={shopVisible}
        onClose={() => setShopVisible(false)}
        primaryColor={globalConfig.primaryColor}
      />

      {/* Dev Panel */}
      <DevPanel
        visible={devPanelVisible}
        onClose={() => setDevPanelVisible(false)}
        primaryColor={globalConfig.primaryColor}
      />

      {/* Wave BG Playground */}
      <WaveBgPlayground
        visible={wavePlaygroundVisible}
        onClose={() => {
          setWavePlaygroundVisible(false);
          fetch(`https://null-core/wavePlayground:close`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: '{}' }).catch(() => { });
        }}
        primaryColor={globalConfig.primaryColor}
      />

      {/* Drive School */}
      <DriveSchool
        visible={driveSchoolVisible}
        onClose={() => setDriveSchoolVisible(false)}
        primaryColor={globalConfig.primaryColor}
      />

      {/* Character Creator */}
      <CharacterCreator
        visible={characterCreatorVisible}
        onClose={() => setCharacterCreatorVisible(false)}
        primaryColor={globalConfig.primaryColor}
        serverConfig={serverConfig}
      />

      {/* Showcase (base de test) */}
      <ShowcaseLayer
        primaryColor={globalConfig.primaryColor}
        serverConfig={serverConfig}
      />

      {/* Garage */}
      <Garage
        visible={garageVisible}
        onClose={() => setGarageVisible(false)}
        primaryColor={globalConfig.primaryColor}
        serverConfig={serverConfig}
      />

      {/* Bank */}
      <Bank
        visible={bankVisible}
        onClose={() => setBankVisible(false)}
        primaryColor={globalConfig.primaryColor}
      />

      {/* ATM */}
      <ATM
        visible={atmVisible}
        onClose={() => setAtmVisible(false)}
        primaryColor={globalConfig.primaryColor}
      />

      {/* Catalog Tablet */}
      <CatalogTablet
        visible={catalogVisible}
        onClose={() => setCatalogVisible(false)}
        primaryColor={globalConfig.primaryColor}
      />

      {/* Dealership */}
      <Dealership
        visible={dealershipVisible}
        onClose={() => setDealershipVisible(false)}
        primaryColor={globalConfig.primaryColor}
      />

      {/* Realtor */}
      <Realtor
        visible={realtorVisible}
        onClose={() => setRealtorVisible(false)}
        primaryColor={globalConfig.primaryColor}
      />

      {/* Burglary (lockpick + loot) — listens to its own NUI messages, no props */}
      <Burglary />

      {/* Society Tablet */}
      <SocietyTablet
        visible={societyTabletVisible}
        onClose={() => setSocietyTabletVisible(false)}
        primaryColor={globalConfig.primaryColor}
      />

      {/* Pawn Shop */}
      <PawnShop
        visible={pawnshopVisible}
        onClose={() => setPawnshopVisible(false)}
        primaryColor={globalConfig.primaryColor}
      />

      {/* Restaurant Craft Tablet */}
      <CraftTablet
        visible={craftTabletVisible}
        onClose={() => setCraftTabletVisible(false)}
        primaryColor={globalConfig.primaryColor}
      />

      {/* Restaurant Supplier Tablet */}
      <SupplierTablet
        visible={supplierTabletVisible}
        onClose={() => setSupplierTabletVisible(false)}
        primaryColor={globalConfig.primaryColor}
      />

      {/* Freejob Tablet (agence intérimaire) */}
      <FreejobTablet
        visible={freejobTabletVisible}
        onClose={() => setFreejobTabletVisible(false)}
        primaryColor={globalConfig.primaryColor}
      />

      {/* Freejob HUD (task tracker) */}
      <FreejobHUD visible={freejobHUDVisible} primaryColor={globalConfig.primaryColor} serverIcon={serverConfig.serverIcon} />

      {/* Freejob Markers (prop indicators) */}
      <FreejobMarker />

      {/* Freejob Info (entrepôt keybinds panel) */}
      <FreejobInfo
        visible={freejobInfoVisible}
        onClose={() => setFreejobInfoVisible(false)}
      />

      {/* Taxi — HUD in-vehicle (fare meter, mood, distance) */}
      <TaxiHUD primaryColor={globalConfig.primaryColor} />

      {/* Taxi — Driver Board (mission selection, stats, ranks) */}
      <TaxiBoard
        visible={taxiBoardVisible}
        onClose={() => setTaxiBoardVisible(false)}
        primaryColor={globalConfig.primaryColor}
      />

      {/* ID Card / License Display */}
      <IDCard
        visible={idcardVisible}
        onClose={() => setIdcardVisible(false)}
      />

      {/* Image Maker */}
      <ImageMaker
        visible={imageMakerVisible}
        serverColor={serverConfig.serverColor}
      />

      {/* Radio UI */}
      <Radio
        visible={radioVisible}
        onClose={() => setRadioVisible(false)}
        primaryColor={globalConfig.primaryColor}
      />

      {/* Item Grid Panel (admin menu overlay) */}
      <ItemGridPanelComponent
        visible={itemGridVisible}
        items={itemGridData.items}
        title={itemGridData.title}
        mode={itemGridData.mode}
        primaryColor={globalConfig.primaryColor}
      />

      {/* Prop Interact */}
      <PropInteract
        visible={propInteractVisible}
        onClose={() => setPropInteractVisible(false)}
        primaryColor={globalConfig.primaryColor}
      />

      {/* Pause Menu */}
      <PauseMenu
        visible={pauseMenuVisible}
        onClose={() => setPauseMenuVisible(false)}
        primaryColor={globalConfig.primaryColor}
        serverConfig={serverConfig}
      />

      {/* Debug Menu (dev mode only) */}
      {isDev && (
        <DebugMenu
          visible={debugMenuVisible}
          onClose={() => setDebugMenuVisible(false)}
        />
      )}

      {/* HUD Editor */}
      <HUDEditor
        visible={hudEditorVisible}
        onClose={() => setHudEditorVisible(false)}
        primaryColor={globalConfig.primaryColor}
        serverColor={serverConfig.serverColor}
        statusColors={statusBarColors}
        speedometerColors={speedometerColors}
        serverConfig={serverConfig}
      />
    </div>
  );
}

export default App;
