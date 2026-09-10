import React, { useState, useEffect } from 'react';
import { hudPositionManager } from '../../utils/hudPositionManager';
import { getAnchorTransform } from '../../utils/anchorPositioning';
import CircularProgressBar from './CircularProgressBar';

interface SpeedometerProps {
  serverConfig: {
    serverName: string;
    serverColor: string;
    serverIcon: string;
    serverDiscord: string;
  };
  previewMode?: boolean;
  previewPosition?: { x: number; y: number };
  hudEditorOpen?: boolean;
  speedometerColors?: any;
  globalConfig?: {
    primaryColor: string;
    theme: 'dark' | 'light';
    style: 'modern' | 'compact';
  };
}

interface VehicleData {
  speed: number;
  rpm: number;
  gear: number;
  fuel: number;
  damage: number;
  engine: boolean;
  door: boolean;
  light: boolean;
  belt: boolean;
  handbrake: boolean;
}

const Speedometer: React.FC<SpeedometerProps> = ({ serverConfig, previewMode = false, previewPosition, hudEditorOpen = false, speedometerColors, globalConfig }) => {
  const [visible, setVisible] = useState(false);
  const [actualPosition, setActualPosition] = useState<{ x: number; y: number; anchor: string } | null>(null);

  const primaryColor = globalConfig?.primaryColor || serverConfig.serverColor;
  const colors = {
    speed: speedometerColors?.speed || primaryColor,
    fuel: speedometerColors?.fuel || primaryColor,
  };
  const [vehicleData, setVehicleData] = useState<VehicleData>({
    speed: 0,
    rpm: 0,
    gear: 1,
    fuel: 100,
    damage: 100,
    engine: false,
    door: false,
    light: false,
    belt: false,
    handbrake: false,
  });

  useEffect(() => {
    if (previewMode) {
      setVisible(true);
      setVehicleData({
        speed: 178,
        rpm: 0.65,
        gear: 3,
        fuel: 61,
        damage: 90,
        engine: true,
        door: false,
        light: true,
        belt: true,
        handbrake: false,
      });
      return;
    }

    hudPositionManager.onReady(() => {
      const savedPos = hudPositionManager.getPosition('speedometer');
      if (savedPos) {
        setActualPosition(savedPos);
      }
    });

    const handleMessage = (event: MessageEvent) => {
      const data = event.data;

      switch (data.type || data.action) {
        case 'inCar':
          setVisible(true);
          break;

        case 'outCar':
          setVisible(false);
          break;

        case 'carStatus':
          setVehicleData({
            speed: data.speed || 0,
            rpm: data.rpm || 0,
            gear: data.gear || 1,
            fuel: data.fuel || 100,
            damage: Math.floor((data.ehealt || 1000) / 10),
            engine: data.engine || false,
            door: data.door || false,
            light: data.light || false,
            belt: data.belt || false,
            handbrake: data.hbreake || false,
          });
          break;
      }
    };

    window.addEventListener('message', handleMessage);
    return () => window.removeEventListener('message', handleMessage);
  }, [previewMode]);

  // No more complex calculations needed!

  const gearColor = vehicleData.damage > 60 ? '#ffffff' : vehicleData.damage > 30 ? '#fbbf24' : '#ef4444';
  const damageColor = vehicleData.damage > 60 ? '#ffffff' : vehicleData.damage > 30 ? '#fbbf24' : '#ef4444';

  const positionStyle = previewMode && previewPosition
    ? {
        left: `0px`,
        top: `0px`,
        transform: 'none',
      }
    : actualPosition
    ? {
        left: `${actualPosition.x}%`,
        top: `${actualPosition.y}%`,
        transform: getAnchorTransform(actualPosition.anchor as any),
      }
    : {};

  if ((!visible && !previewMode) || (hudEditorOpen && !previewMode)) return null;

  return (
    <div
      className={previewMode ? "relative" : "fixed pointer-events-none"}
      style={{
        ...positionStyle,
        zIndex: 100,
        width: '32vh',
        height: '22vh',
      }}
      data-theme={globalConfig?.theme}
      data-style={globalConfig?.style}
    >
      <div className="relative flex items-center justify-center" style={{ width: '100%', height: '100%' }}>
        {/* Speed bar: 260° arc from bottom-left */}
        <CircularProgressBar
          value={vehicleData.speed}
          max={240}
          radius={120}
          strokeWidth={6}
          color={colors.speed}
          startAngle={125.5}
          endAngle={125.5 + 180}
          clockwise={false}
          viewBoxSize={270}
          centerX={135}
          centerY={135}
          className="absolute"
          style={{ width: '100%', height: '100%' }}
        />

        {/* RPM bar: 60° arc on top (symmetric around -90°) */}
        <CircularProgressBar
          value={vehicleData.rpm * 10000}
          max={8000}
          radius={100}
          strokeWidth={6}
          color={colors.speed}
          startAngle={-120}
          endAngle={-60}
          clockwise={false}
          viewBoxSize={270}
          centerX={135}
          centerY={135}
          className="absolute"
          style={{ width: '100%', height: '100%' }}
        />

        {/* Gear */}
        <div
          className="absolute flex items-center justify-center"
          style={{
            top: '3.75vh',
            width: '5vh',
            height: '2vh',
          }}
        >
          <span
            className="font-medium"
            style={{
              fontSize: '2vh',
              color: gearColor,
            }}
          >
            {vehicleData.gear}
          </span>
        </div>

        {/* Speed */}
        <div
          className="absolute flex flex-col items-center justify-center"
          style={{
            top: '8vh',
            width: '10vh',
            height: '5vh',
          }}
        >
          <span
            className="font-medium"
            style={{
              fontSize: '4.75vh',
              color: 'var(--text-primary, #ffffff)',
            }}
          >
            {vehicleData.speed}
          </span>
          <span
            className="font-medium uppercase"
            style={{
              fontSize: '1.25vh',
              color: 'var(--text-primary, #ffffff)',
            }}
          >
            km/h
          </span>
        </div>

        {/* Vehicle indicators row 1 */}
        <div
          className="absolute flex items-center justify-center gap-[1vh]"
          style={{
            bottom: '4.75vh',
            width: '10vh',
            height: '1.9vh',
          }}
        >
          <svg
            viewBox="0 0 5120 5120"
            style={{
              width: '15%',
              fill: vehicleData.belt ? 'var(--text-primary, #ffffff)' : 'var(--text-tertiary, var(--text-tertiary))',
              transition: 'fill 0.3s ease',
              transform: 'scaleY(-1)',
            }}
          >
            <path d="M2460 5109 c-198 -23 -378 -115 -521 -266 -301 -319 -303 -818 -5 -1150 l46 -51 -54 -41 c-225 -169 -453 -501 -599 -872 -88 -221 -175 -556 -208 -790 l-12 -86 -56 -23 c-325 -134 -738 -390 -962 -598 -88 -81 -107 -166 -59 -262 36 -70 104 -110 188 -110 61 0 95 18 217 115 125 100 234 177 350 247 86 52 265 148 277 148 3 0 8 -91 12 -203 11 -332 45 -591 113 -877 40 -170 65 -218 131 -257 l47 -28 410 0 c401 0 411 0 450 22 50 27 80 58 100 105 13 32 15 99 15 442 l0 405 33 25 c58 44 106 60 187 60 81 0 129 -16 187 -60 l33 -25 0 -405 c0 -343 2 -410 15 -442 20 -47 50 -78 100 -105 39 -22 49 -22 450 -22 l410 0 47 28 c66 39 91 87 131 257 68 286 102 545 113 877 l7 202 78 -39 c175 -88 397 -232 562 -363 111 -88 149 -107 209 -107 145 0 243 128 204 263 -19 65 -66 113 -236 239 -253 188 -478 317 -801 461 l-55 24 -13 89 c-52 361 -172 751 -323 1047 l-61 119 516 516 c544 545 556 560 557 648 0 64 -45 143 -103 178 -58 35 -140 40 -197 12 -19 -10 -259 -241 -532 -514 l-497 -496 -73 70 c-40 39 -90 83 -110 98 l-38 28 46 51 c219 244 282 588 163 887 -96 239 -300 426 -544 499 -60 18 -228 43 -260 40 -5 -1 -44 -5 -85 -10z" />
          </svg>

          <svg
            viewBox="0 0 5120 5120"
            style={{
              width: '21%',
              fill: vehicleData.handbrake ? '#ef4444' : 'var(--text-tertiary)',
              transition: 'fill 0.3s ease',
              transform: 'scaleY(-1)',
            }}
          >
            <path d="M2395 4509 c-511 -42 -998 -295 -1333 -694 -436 -519 -571 -1229 -356 -1873 220 -660 777 -1155 1459 -1297 781 -162 1588 172 2028 840 233 355 348 794 317 1212 -74 972 -835 1738 -1802 1813 -138 11 -171 11 -313 -1z" />
          </svg>
        </div>

        {/* Vehicle indicators row 2 */}
        <div
          className="absolute flex items-center justify-center gap-[1vh]"
          style={{
            bottom: '2.25vh',
            width: '12vh',
            height: '2vh',
          }}
        >
          <svg
            viewBox="0 0 5120 5120"
            style={{
              width: '20%',
              fill: vehicleData.engine ? 'var(--text-tertiary)' : '#ef4444',
              transition: 'fill 0.3s ease',
              transform: 'scaleY(-1)',
            }}
          >
            <path d="M2093 4104 c-71 -35 -96 -137 -50 -205 39 -59 73 -69 230 -69 l137 0 0 -159 0 -160 -197 -3 -198 -3 -321 -227 -322 -228 -292 0 c-425 0 -404 20 -408 -377 l-3 -273 -184 0 -183 0 -4 174 c-3 158 -5 177 -24 202 -37 50 -72 69 -124 69 -52 0 -87 -19 -124 -69 -21 -27 -21 -38 -21 -519 l0 -492 23 -36 c56 -91 188 -91 244 0 21 33 23 50 26 209 l4 172 184 0 184 0 0 -262 c0 -238 2 -267 20 -305 36 -80 49 -83 333 -83 l247 0 0 -167 c0 -192 12 -236 72 -273 33 -20 46 -20 1518 -20 1455 0 1486 0 1517 20 69 42 68 29 71 588 l3 502 184 0 183 0 4 -172 c3 -159 5 -176 26 -209 56 -91 188 -91 244 0 l23 36 0 492 c0 481 0 492 -21 519 -37 50 -72 69 -124 69 -52 0 -87 -19 -124 -69 -19 -25 -21 -44 -24 -202 l-4 -174 -183 0 -184 0 -3 273 c-3 306 -5 315 -78 356 -36 20 -52 21 -330 21 l-292 0 -322 228 -321 227 -197 3 -198 3 0 160 0 159 146 0 c114 0 153 4 180 16 101 48 110 188 15 251 l-34 23 -446 0 c-388 0 -450 -3 -478 -16z" />
          </svg>

          <svg
            viewBox="0 0 5120 5120"
            style={{
              width: '15%',
              fill: vehicleData.door ? 'var(--text-secondary, #fbbf24)' : 'var(--text-tertiary, var(--text-tertiary))',
              transition: 'fill 0.3s ease',
              transform: 'scaleY(-1)',
            }}
          >
            <path d="M1432 4827 l-292 -292 0 -450 0 -450 -437 -437 -438 -438 105 -105 105 -105 332 332 333 333 0 -475 0 -475 -437 -437 -438 -438 105 -105 105 -105 332 332 333 333 0 -780 0 -780 143 -143 142 -142 1160 0 1160 0 143 143 142 142 0 755 0 755 308 -308 307 -307 105 105 105 105 -413 413 -412 412 0 475 0 475 308 -308 307 -307 105 105 105 105 -413 413 -412 412 0 475 0 475 -293 293 -292 292 -860 0 -860 0 -293 -293z" />
          </svg>

          <svg
            viewBox="0 0 5120 5120"
            style={{
              width: '20%',
              fill: vehicleData.light ? 'var(--text-primary, #ffffff)' : 'var(--text-tertiary, var(--text-tertiary))',
              transition: 'fill 0.3s ease',
              transform: 'scaleY(-1)',
            }}
          >
            <path d="M2785 3783 c-176 -64 -312 -231 -400 -494 -73 -216 -105 -438 -105 -729 0 -605 170 -1060 448 -1197 l76 -38 156 0 c123 0 179 5 270 24 305 63 565 199 769 402 352 351 446 847 241 1276 -65 136 -136 237 -241 342 -265 265 -625 416 -1019 427 -122 4 -153 2 -195 -13z" />
          </svg>
        </div>

        {/* Fuel indicator with circular progress */}
        <div
          className="absolute flex items-center justify-center"
          style={{
            right: '4vh',
            top: '11.5vh',
            width: '4vh',
            height: '4vh',
          }}
        >
          <CircularProgressBar
            value={vehicleData.fuel}
            max={100}
            radius={18}
            strokeWidth={4}
            color={colors.fuel}
            startAngle={90}
            clockwise={false}
            className="absolute"
            style={{ width: '100%', height: '100%' }}
          />
          <svg
            viewBox="0 0 512 512"
            style={{
              width: '40%',
              fill: vehicleData.fuel > 20 ? '#ffffff' : '#ef4444',
              transition: 'fill 0.3s ease',
              zIndex: 1,
            }}
          >
            <path d="M32 64C32 46.3 46.3 32 64 32H256c17.7 0 32 14.3 32 32s-14.3 32-32 32H64C46.3 96 32 81.7 32 64zM64 128H256c17.7 0 32 14.3 32 32s-14.3 32-32 32H64c-17.7 0-32-14.3-32-32s14.3-32 32-32zm0 64H256c17.7 0 32 14.3 32 32s-14.3 32-32 32H64c-17.7 0-32-14.3-32-32s14.3-32 32-32zm0 64H256c17.7 0 32 14.3 32 32s-14.3 32-32 32H64c-17.7 0-32-14.3-32-32s14.3-32 32-32zM288 368c0 44.2 35.8 80 80 80h61.5c10.4 0 18-9.8 15.5-19.9l-13.8-55.2c15.8-14.9 28.7-32.8 37.5-52.9H480c17.7 0 32-14.3 32-32V160c0-17.7-14.3-32-32-32H448c-17.7 0-32 14.3-32 32v48c-8.8-16-18.9-30.9-30.2-44.6c-28.5-34.7-68.8-59.4-114.8-59.4c-53 0-96 43-96 96V368z" />
          </svg>
        </div>

        {/* Damage indicator with circular progress */}
        <div
          className="absolute flex items-center justify-center"
          style={{
            top: '15vh',
            right: '7vh',
            width: '4vh',
            height: '4vh',
          }}
        >
          <CircularProgressBar
            value={vehicleData.damage}
            max={100}
            radius={18}
            strokeWidth={4}
            color={damageColor}
            startAngle={90}
            clockwise={false}
            className="absolute"
            style={{ width: '100%', height: '100%' }}
          />
          <i
            className="fa-solid fa-wrench"
            style={{
              fontSize: '1.5vh',
              color: damageColor,
              transform: 'rotate(260deg)',
              transition: 'color 0.3s ease',
              zIndex: 1,
            }}
          />
        </div>
      </div>
    </div>
  );
};

export default Speedometer;
