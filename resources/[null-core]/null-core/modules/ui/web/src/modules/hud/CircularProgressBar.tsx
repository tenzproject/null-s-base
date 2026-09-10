import React from 'react';

interface CircularProgressBarProps {
  value: number;
  max: number;
  radius: number;
  strokeWidth: number;
  color: string;
  backgroundColor?: string;
  startAngle?: number; // in degrees, 0 = top, 90 = right, 180 = bottom, 270 = left
  endAngle?: number; // in degrees
  clockwise?: boolean;
  className?: string;
  style?: React.CSSProperties;
  showShadow?: boolean;
  viewBoxSize?: number; // Optional custom viewBox size
  centerX?: number; // Optional custom center X
  centerY?: number; // Optional custom center Y
}

const CircularProgressBar: React.FC<CircularProgressBarProps> = ({
  value,
  max,
  radius,
  strokeWidth,
  color,
  backgroundColor = 'rgba(0, 0, 0, 0.4)',
  startAngle = -90, // Start at top by default
  endAngle,
  clockwise = true,
  className = '',
  style = {},
  showShadow = true,
  viewBoxSize,
  centerX,
  centerY,
}) => {
  // Calculate percentage
  const percentage = Math.min(100, Math.max(0, (value / max) * 100));
  
  // Calculate arc angle
  const arcAngle = endAngle !== undefined ? endAngle - startAngle : 360;
  
  // Calculate circumference for the arc
  const circumference = 2 * Math.PI * radius;
  const arcLength = (Math.abs(arcAngle) / 360) * circumference;
  
  // Calculate progress offset (starts full, empties as it fills)
  const progressOffset = clockwise 
    ? arcLength - (percentage / 100) * arcLength
    : arcLength - (percentage / 100) * arcLength;
  
  // SVG viewBox size (add padding for stroke)
  const calculatedViewBoxSize = viewBoxSize || (radius + strokeWidth) * 2;
  const center = centerX !== undefined && centerY !== undefined 
    ? { x: centerX, y: centerY }
    : { x: calculatedViewBoxSize / 2, y: calculatedViewBoxSize / 2 };
  
  return (
    <svg
      viewBox={`0 0 ${calculatedViewBoxSize} ${calculatedViewBoxSize}`}
      className={className}
      style={style}
    >
      {showShadow && (
        <defs>
          <filter id={`shadow-${radius}-${strokeWidth}`}>
            <feDropShadow dx="0" dy="0" stdDeviation="8" floodColor="rgba(255, 255, 255, 0.1)" />
          </filter>
        </defs>
      )}
      
      {/* Background arc */}
      <circle
        cx={center.x}
        cy={center.y}
        r={radius}
        fill="none"
        stroke={backgroundColor}
        strokeWidth={strokeWidth}
        strokeDasharray={`${arcLength} ${circumference}`}
        strokeDashoffset={0}
        style={{
          transformOrigin: `${center.x}px ${center.y}px`,
          transform: `rotate(${startAngle}deg)`,
        }}
      />
      
      {/* Progress arc */}
      <circle
        cx={center.x}
        cy={center.y}
        r={radius}
        fill="none"
        stroke={color}
        strokeWidth={strokeWidth}
        strokeDasharray={`${arcLength} ${circumference}`}
        strokeDashoffset={progressOffset}
        filter={showShadow ? `url(#shadow-${radius}-${strokeWidth})` : undefined}
        style={{
          transformOrigin: `${center.x}px ${center.y}px`,
          transform: `rotate(${startAngle}deg)`,
          transition: 'stroke-dashoffset 0.3s ease',
        }}
      />
    </svg>
  );
};

export default CircularProgressBar;
