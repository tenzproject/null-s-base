import React, { useRef, useLayoutEffect, useState } from 'react';
import ReactDOM from 'react-dom';

interface SmartTooltipProps {
  /** Whether to show the tooltip */
  visible: boolean;
  /** CSS class on the outer wrapper */
  className?: string;
  /** Inline styles */
  style?: React.CSSProperties;
  /** Tooltip content */
  children: React.ReactNode;
  /** Preferred placement relative to parent (default: 'top') */
  placement?: 'top' | 'bottom';
}

/**
 * A tooltip that renders via Portal to document.body so it is never clipped
 * by overflow:hidden ancestors. A hidden anchor span stays in the DOM tree
 * to track the parent item slot's position, while the visible tooltip is
 * portaled to body with fixed positioning.
 */
const SmartTooltip: React.FC<SmartTooltipProps> = ({
  visible,
  className = '',
  style,
  children,
  placement = 'top',
}) => {
  const anchorRef = useRef<HTMLSpanElement>(null);
  const tooltipRef = useRef<HTMLDivElement>(null);
  const [pos, setPos] = useState<{ top: number; left: number }>({ top: 0, left: 0 });
  const [ready, setReady] = useState(false);

  useLayoutEffect(() => {
    if (!visible) { setReady(false); return; }
    const anchor = anchorRef.current;
    if (!anchor) return;

    // The anchor is inside the item slot — find the slot element
    const parentSlot = anchor.closest('.ni-item-slot') as HTMLElement | null;
    if (!parentSlot) return;

    // Use rAF so the portaled tooltip has been measured
    const frame = requestAnimationFrame(() => {
      const tt = tooltipRef.current;
      if (!tt || !parentSlot) return;

      const parentRect = parentSlot.getBoundingClientRect();
      const ttRect = tt.getBoundingClientRect();
      const vw = window.innerWidth;
      const vh = window.innerHeight;
      const gap = 8;
      const margin = 8;

      let top: number;
      if (placement === 'top') {
        top = parentRect.top - ttRect.height - gap;
        if (top < margin) top = parentRect.bottom + gap;
      } else {
        top = parentRect.bottom + gap;
        if (top + ttRect.height > vh - margin) top = parentRect.top - ttRect.height - gap;
      }

      let left = parentRect.left + parentRect.width / 2 - ttRect.width / 2;
      if (left < margin) left = margin;
      if (left + ttRect.width > vw - margin) left = vw - margin - ttRect.width;

      setPos({ top, left });
      setReady(true);
    });

    return () => cancelAnimationFrame(frame);
  }, [visible, placement]);

  // Always render the invisible anchor in the DOM tree (inside the item slot)
  // so we can find the parent's position even when the tooltip is portaled.
  return (
    <>
      <span ref={anchorRef} style={{ display: 'none' }} />
      {visible && ReactDOM.createPortal(
        <div
          ref={tooltipRef}
          className={`ni-smart-tooltip ${className}`}
          style={{
            position: 'fixed',
            top: pos.top,
            left: pos.left,
            zIndex: 99999,
            pointerEvents: 'none',
            opacity: ready ? 1 : 0,
            transition: 'opacity 0.12s ease',
            ...style,
          }}
        >
          {children}
        </div>,
        document.body,
      )}
    </>
  );
};

export default SmartTooltip;
