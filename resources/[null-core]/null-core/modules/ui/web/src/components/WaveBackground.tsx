import React, { useEffect, useMemo, useRef, useState } from 'react';
import { hashSize, renderWaveBgSVG, WaveBgParams } from '@modules/wave-bg-playground/waveGen';

interface WaveBackgroundProps {
  accentColor: string;
  bgColor?: string;
  // Override params if needed; defaults match the validated playground look.
  clusters?: number;
  linesPerCluster?: number;
  opacity?: number;
  strokeWidth?: number;
  fadeEdges?: number;
  jitter?: number;
  vignette?: boolean;
  // Optional explicit size; if omitted, the component observes its parent.
  width?: number;
  height?: number;
  className?: string;
  style?: React.CSSProperties;
}

const WaveBackground: React.FC<WaveBackgroundProps> = ({
  accentColor,
  bgColor = 'transparent',
  clusters = 2,
  linesPerCluster = 12,
  opacity = 0.3,
  strokeWidth = 2.6,
  fadeEdges = 1,
  jitter = 0.2,
  vignette = false,
  width,
  height,
  className,
  style,
}) => {
  const ref = useRef<HTMLDivElement>(null);
  const [size, setSize] = useState<{ w: number; h: number }>({
    w: width || 0,
    h: height || 0,
  });

  useEffect(() => {
    if (width && height) {
      setSize({ w: width, h: height });
      return;
    }
    if (!ref.current) return;
    const el = ref.current;
    const update = () => {
      const r = el.getBoundingClientRect();
      setSize({ w: Math.round(r.width), h: Math.round(r.height) });
    };
    update();
    const ro = new ResizeObserver(update);
    ro.observe(el);
    return () => ro.disconnect();
  }, [width, height]);

  const svg = useMemo(() => {
    if (size.w < 4 || size.h < 4) return '';
    const params: WaveBgParams = {
      width: size.w,
      height: size.h,
      bgColor,
      accentColor,
      clusters,
      linesPerCluster,
      opacity,
      strokeWidth,
      fadeEdges,
      jitter,
      autoDensity: true,
      seed: hashSize(size.w, size.h),
      vignette,
    };
    // Force the inline SVG to stretch to its wrapper instead of using fixed pixel dims.
    return renderWaveBgSVG(params).replace(
      /<svg([^>]*?)\swidth="\d+"\s+height="\d+"/,
      '<svg$1 width="100%" height="100%" preserveAspectRatio="none"'
    );
  }, [size.w, size.h, accentColor, bgColor, clusters, linesPerCluster, opacity, strokeWidth, fadeEdges, jitter, vignette]);

  return (
    <div
      ref={ref}
      className={className}
      style={{
        position: 'absolute',
        inset: 0,
        zIndex: -1,
        pointerEvents: 'none',
        overflow: 'hidden',
        ...style,
      }}
      dangerouslySetInnerHTML={{ __html: svg }}
    />
  );
};

export default WaveBackground;
