import { useState, useMemo, useEffect, useRef, useCallback } from 'react'
import { CrimeNetData, NetworkNode } from '../types'

interface Props {
  cnData: CrimeNetData | null
}

interface PositionedNode extends NetworkNode {
  x: number
  y: number
}

interface PositionedEdge {
  x1: number; y1: number; x2: number; y2: number
  type: string
}

type FilterType = 'all' | 'online' | 'boss' | 'important' | 'gang'

export default function NetworkTab({ cnData }: Props) {
  const [selectedNode, setSelectedNode] = useState<string | null>(null)
  const [mounted, setMounted] = useState(false)
  const [filter, setFilter] = useState<FilterType>('all')
  const [showFilters, setShowFilters] = useState(false)

  // Pan & zoom state
  const [zoom, setZoom] = useState(1)
  const [pan, setPan] = useState({ x: 0, y: 0 })
  const isDragging = useRef(false)
  const dragStart = useRef({ x: 0, y: 0, panX: 0, panY: 0 })
  const containerRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    requestAnimationFrame(() => setMounted(true))
  }, [])

  // Pan handlers
  const onPointerDown = useCallback((e: React.PointerEvent) => {
    if ((e.target as HTMLElement).closest('.net-node-g')) return
    isDragging.current = true
    dragStart.current = { x: e.clientX, y: e.clientY, panX: pan.x, panY: pan.y }
    ;(e.target as HTMLElement).setPointerCapture?.(e.pointerId)
  }, [pan])

  const onPointerMove = useCallback((e: React.PointerEvent) => {
    if (!isDragging.current) return
    const dx = e.clientX - dragStart.current.x
    const dy = e.clientY - dragStart.current.y
    setPan({ x: dragStart.current.panX + dx / zoom, y: dragStart.current.panY + dy / zoom })
  }, [zoom])

  const onPointerUp = useCallback(() => {
    isDragging.current = false
  }, [])

  // Zoom via wheel
  const onWheel = useCallback((e: React.WheelEvent) => {
    e.stopPropagation()
    const delta = e.deltaY > 0 ? -0.15 : 0.15
    setZoom(z => Math.min(3, Math.max(0.4, z + delta)))
  }, [])

  const zoomIn = useCallback(() => setZoom(z => Math.min(3, z + 0.3)), [])
  const zoomOut = useCallback(() => setZoom(z => Math.max(0.4, z - 0.3)), [])
  const resetView = useCallback(() => { setZoom(1); setPan({ x: 0, y: 0 }) }, [])

  const { posNodes, posEdges } = useMemo(() => {
    if (!cnData?.network) return { posNodes: [] as PositionedNode[], posEdges: [] as PositionedEdge[] }

    const { nodes, edges, clusters } = cnData.network
    const CX = 400, CY = 300
    const nodeMap: Record<string, PositionedNode> = {}
    const posEdgeList: PositionedEdge[] = []

    // Place player at center
    const playerNode = nodes.find(n => n.type === 'player')
    if (playerNode) {
      nodeMap[playerNode.id] = { ...playerNode, x: CX, y: CY }
    }

    // Separate nodes: NPC chain vs regular contacts
    const npcChainNodes = nodes.filter(n => n.cluster === 'npc_chain' && n.type !== 'player')
    const regularNodes = nodes.filter(n => n.cluster !== 'npc_chain' && n.type !== 'player')

    const ring1Nodes = regularNodes.filter(n => n.ring === 1)
    const ring2Nodes = regularNodes.filter(n => n.ring === 2)

    // Group ring1 by cluster
    const clusterRing1: Record<string, NetworkNode[]> = {}
    const standaloneRing1: NetworkNode[] = []

    ring1Nodes.forEach(node => {
      if (node.cluster) {
        if (!clusterRing1[node.cluster]) clusterRing1[node.cluster] = []
        clusterRing1[node.cluster].push(node)
      } else {
        standaloneRing1.push(node)
      }
    })

    // Count branches: regular clusters (non-npc) + standalone + 1 for NPC chain
    const regularClusters = clusters.filter(c => c.id !== 'npc_chain')
    const hasNpcChain = npcChainNodes.length > 0
    const totalBranches = regularClusters.length + standaloneRing1.length + (hasNpcChain ? 1 : 0)

    if (totalBranches > 0) {
      const sectorSize = (Math.PI * 2 * 0.6) / totalBranches
      const gapSize = (Math.PI * 2 * 0.4) / totalBranches
      let branchIdx = 0
      const startAngle = -Math.PI / 2

      // === NPC CHAIN BRANCH (first branch, at top) ===
      if (hasNpcChain) {
        const branchAngle = startAngle + branchIdx * (sectorSize + gapSize) + sectorSize / 2
        const dirX = Math.cos(branchAngle)
        const dirY = Math.sin(branchAngle)

        // Sort NPC chain by ring (depth in chain)
        const sorted = [...npcChainNodes].sort((a, b) => a.ring - b.ring)
        sorted.forEach((node, i) => {
          const dist = 80 + i * 70
          nodeMap[node.id] = { ...node, x: CX + dirX * dist, y: CY + dirY * dist }
        })
        branchIdx++
      }

      // === REGULAR CLUSTERS (gangs) ===
      regularClusters.forEach((cluster) => {
        const branchAngle = startAngle + branchIdx * (sectorSize + gapSize) + sectorSize / 2
        branchIdx++

        const bridgeNodes = clusterRing1[cluster.id] || []
        const bossNode = ring2Nodes.find(n => n.id === cluster.boss)
        const otherMembers = ring2Nodes.filter(n => n.cluster === cluster.id && n.id !== cluster.boss)

        const dirX = Math.cos(branchAngle)
        const dirY = Math.sin(branchAngle)

        // Bridge member at ring 1
        bridgeNodes.forEach((node, i) => {
          const dist = 90 + i * 35
          nodeMap[node.id] = { ...node, x: CX + dirX * dist, y: CY + dirY * dist }
        })

        // Boss at ring 2
        if (bossNode) {
          const bossDist = 170
          nodeMap[bossNode.id] = { ...bossNode, x: CX + dirX * bossDist, y: CY + dirY * bossDist }

          // Members branch off perpendicularly from boss
          otherMembers.forEach((member, i) => {
            const perpAngle = branchAngle + Math.PI / 2
            const perpX = Math.cos(perpAngle)
            const perpY = Math.sin(perpAngle)
            const offset = ((i % 2 === 0 ? 1 : -1) * (Math.floor(i / 2) + 1) * 45)
            const memberDist = 240
            nodeMap[member.id] = {
              ...member,
              x: CX + dirX * memberDist + perpX * offset,
              y: CY + dirY * memberDist + perpY * offset
            }
          })
        }
      })

      // === STANDALONE CONTACTS ===
      standaloneRing1.forEach((node) => {
        const angle = startAngle + branchIdx * (sectorSize + gapSize) + sectorSize / 2
        branchIdx++
        const dist = 100
        nodeMap[node.id] = { ...node, x: CX + Math.cos(angle) * dist, y: CY + Math.sin(angle) * dist }
      })
    }

    // Build edges
    edges.forEach(edge => {
      const fromN = nodeMap[edge.from]
      const toN = nodeMap[edge.to]
      if (fromN && toN) {
        posEdgeList.push({ x1: fromN.x, y1: fromN.y, x2: toN.x, y2: toN.y, type: edge.type })
      }
    })

    return { posNodes: Object.values(nodeMap), posEdges: posEdgeList }
  }, [cnData?.network])

  // Filter nodes
  const isNodeVisible = useCallback((node: PositionedNode) => {
    if (node.type === 'player') return true
    if (node.is_npc) return true  // NPC chain always visible
    if (filter === 'all') return true
    if (filter === 'online') return !!node.online
    if (filter === 'boss') return node.type === 'boss'
    if (filter === 'important') return !!node.is_important
    if (filter === 'gang') return !!node.gangname
    return true
  }, [filter])

  const visibleNodes = useMemo(() => posNodes.filter(isNodeVisible), [posNodes, isNodeVisible])
  const visibleNodeIds = useMemo(() => new Set(visibleNodes.map(n => n.id)), [visibleNodes])
  const visibleEdges = useMemo(() => {
    const nodeIdSet = visibleNodeIds
    return posEdges.filter(e => {
      const fromNode = posNodes.find(n => Math.abs(n.x - e.x1) < 1 && Math.abs(n.y - e.y1) < 1)
      const toNode = posNodes.find(n => Math.abs(n.x - e.x2) < 1 && Math.abs(n.y - e.y2) < 1)
      return fromNode && toNode && nodeIdSet.has(fromNode.id) && nodeIdSet.has(toNode.id)
    })
  }, [posEdges, posNodes, visibleNodeIds])

  const selectedData = selectedNode ? posNodes.find(n => n.id === selectedNode) : null

  // Node colors — red for boss/important, grey for others
  const nodeStroke = (node: PositionedNode) => {
    if (node.type === 'player') return '#ccc'
    if (node.type === 'npc_contact') return node.locked ? '#444' : '#d97706'
    if (node.type === 'boss') return '#dc2626'
    if (node.is_important) return '#dc2626'
    if (node.online) return '#888'
    return '#555'
  }

  const FILTERS: { id: FilterType; label: string }[] = [
    { id: 'all', label: 'TOUS' },
    { id: 'online', label: 'EN LIGNE' },
    { id: 'boss', label: 'BOSS' },
    { id: 'important', label: 'IMPORTANTS' },
    { id: 'gang', label: 'GANGS' },
  ]

  const viewBox = `${400 - 400 / zoom - pan.x} ${300 - 300 / zoom - pan.y} ${800 / zoom} ${600 / zoom}`

  return (
    <div className={`net-tab ${mounted ? 'net-tab--mounted' : ''}`}>
      {/* Filters button */}
      <div className="net-toolbar">
        <button className="net-filter-toggle" onClick={() => setShowFilters(v => !v)}>
          <svg viewBox="0 0 24 24" width="14" height="14" fill="none" stroke="currentColor" strokeWidth="2">
            <polygon points="22 3 2 3 10 12.46 10 19 14 21 14 12.46 22 3" />
          </svg>
          <span>FILTRES</span>
        </button>
        <div className="net-zoom-controls">
          <button className="net-zoom-btn" onClick={zoomOut}>−</button>
          <button className="net-zoom-btn net-zoom-reset" onClick={resetView}>{Math.round(zoom * 100)}%</button>
          <button className="net-zoom-btn" onClick={zoomIn}>+</button>
        </div>
      </div>

      {showFilters && (
        <div className="net-filters">
          {FILTERS.map(f => (
            <button key={f.id} className={`net-filter-btn ${filter === f.id ? 'active' : ''}`} onClick={() => { setFilter(f.id); setShowFilters(false) }}>
              {f.label}
            </button>
          ))}
        </div>
      )}

      <div
        className="net-graph-container"
        ref={containerRef}
        onPointerDown={onPointerDown}
        onPointerMove={onPointerMove}
        onPointerUp={onPointerUp}
        onPointerLeave={onPointerUp}
        onWheel={onWheel}
        style={{ cursor: isDragging.current ? 'grabbing' : 'grab', touchAction: 'none' }}
      >
        <svg
          viewBox={viewBox}
          className="net-svg"
          onClick={(e) => {
            if ((e.target as SVGElement).tagName === 'svg' || (e.target as SVGElement).tagName === 'rect') setSelectedNode(null)
          }}
        >
          <defs>
            <pattern id="net-grid" width="20" height="20" patternUnits="userSpaceOnUse">
              <path d="M 20 0 L 0 0 0 20" fill="none" stroke="rgba(255,255,255,0.03)" strokeWidth="0.5" />
            </pattern>
            <filter id="net-glow">
              <feGaussianBlur stdDeviation="3" result="blur" />
              <feMerge><feMergeNode in="blur" /><feMergeNode in="SourceGraphic" /></feMerge>
            </filter>
          </defs>
          <rect x="-200" y="-200" width="1200" height="1000" fill="url(#net-grid)" />

          {/* Cluster backgrounds */}
          {cnData?.network.clusters.map(cluster => {
            const members = visibleNodes.filter(n => n.cluster === cluster.id)
            if (members.length < 2) return null
            const cx = members.reduce((s, n) => s + n.x, 0) / members.length
            const cy = members.reduce((s, n) => s + n.y, 0) / members.length
            const maxDist = Math.max(...members.map(n => Math.sqrt((n.x - cx) ** 2 + (n.y - cy) ** 2))) + 30
            return (
              <g key={cluster.id}>
                <circle cx={cx} cy={cy} r={maxDist} fill="rgba(255,255,255,0.02)" stroke="rgba(255,255,255,0.06)" strokeWidth="0.5" strokeDasharray="4 4" />
                <text x={cx} y={cy - maxDist + 10} textAnchor="middle" fill="rgba(255,255,255,0.15)" fontSize="7" fontWeight="700" letterSpacing="2">
                  {cluster.label.toUpperCase()}
                </text>
              </g>
            )
          })}

          {/* Edges */}
          {visibleEdges.map((edge, i) => {
            const isBoss = edge.type === 'gang_boss'
            const isMember = edge.type === 'gang_member'
            const isNpc = edge.type === 'npc_chain'
            const edgeColor = isNpc ? '#d97706' : '#666'
            const edgeGlow = isNpc ? '#d97706' : '#888'
            return (
              <g key={`e-${i}`} className={`net-edge ${mounted ? 'net-edge--visible' : ''}`} style={{ animationDelay: `${0.3 + i * 0.05}s` }}>
                <line x1={edge.x1} y1={edge.y1} x2={edge.x2} y2={edge.y2}
                  stroke={edgeColor} strokeWidth={isBoss ? 1.8 : isNpc ? 1.5 : 1.2}
                  opacity={isMember ? 0.25 : isNpc ? 0.35 : 0.4}
                  strokeDasharray={isMember ? '3 3' : isNpc ? '5 3' : 'none'}
                />
                <line x1={edge.x1} y1={edge.y1} x2={edge.x2} y2={edge.y2}
                  stroke={edgeGlow} strokeWidth="3" opacity="0.05" filter="url(#net-glow)"
                />
                <circle r="1.5" fill={edgeGlow} opacity="0.5">
                  <animateMotion dur={`${2.5 + i * 0.3}s`} repeatCount="indefinite"
                    path={`M${edge.x1},${edge.y1} L${edge.x2},${edge.y2}`} />
                </circle>
              </g>
            )
          })}

          {/* Nodes */}
          {visibleNodes.map((node, i) => {
            const isPlayer = node.type === 'player'
            const isBoss = node.type === 'boss'
            const isNpc = node.type === 'npc_contact'
            const isLocked = !!node.locked
            const isImp = node.is_important
            const isSelected = selectedNode === node.id
            const radius = isPlayer ? 26 : isBoss ? 22 : isNpc ? 18 : node.ring === 1 ? 20 : 16
            const stroke = nodeStroke(node)
            const initials = isPlayer ? 'YOU' : isLocked ? '??' : (node.name || '??').substring(0, 2).toUpperCase()

            return (
              <g key={node.id}
                className={`net-node-g net-node ${mounted ? 'net-node--visible' : ''} ${isSelected ? 'net-node--selected' : ''}`}
                style={{ animationDelay: `${0.5 + i * 0.06}s` }}
                onClick={(e) => { e.stopPropagation(); setSelectedNode(node.id === selectedNode ? null : node.id) }}
                cursor="pointer"
              >
                {/* Player pulse */}
                {isPlayer && (
                  <circle cx={node.x} cy={node.y} r={radius + 8} fill="none" stroke="#999" strokeWidth="1" opacity="0.3">
                    <animate attributeName="r" values={`${radius + 4};${radius + 14};${radius + 4}`} dur="3s" repeatCount="indefinite" />
                    <animate attributeName="opacity" values="0.3;0.05;0.3" dur="3s" repeatCount="indefinite" />
                  </circle>
                )}

                {/* Important glow */}
                {isImp && !isPlayer && !isNpc && (
                  <circle cx={node.x} cy={node.y} r={radius + 4} fill="none" stroke="#dc2626" strokeWidth="0.8" opacity="0.4">
                    <animate attributeName="opacity" values="0.4;0.1;0.4" dur="2s" repeatCount="indefinite" />
                  </circle>
                )}

                {/* NPC contact glow (amber, only for unlocked) */}
                {isNpc && !isLocked && (
                  <circle cx={node.x} cy={node.y} r={radius + 4} fill="none" stroke="#d97706" strokeWidth="0.8" opacity="0.3">
                    <animate attributeName="opacity" values="0.3;0.08;0.3" dur="2.5s" repeatCount="indefinite" />
                  </circle>
                )}

                {/* Selection ring */}
                {isSelected && (
                  <circle cx={node.x} cy={node.y} r={radius + 5} fill="none" stroke="#fff" strokeWidth="1.5" strokeDasharray="4 2">
                    <animateTransform attributeName="transform" type="rotate" from={`0 ${node.x} ${node.y}`} to={`360 ${node.x} ${node.y}`} dur="8s" repeatCount="indefinite" />
                  </circle>
                )}

                {/* Node circle */}
                <circle cx={node.x} cy={node.y} r={radius} fill={isLocked ? '#0a0a0a' : '#111'} stroke={stroke} strokeWidth={isPlayer ? 2.5 : isBoss ? 2 : 1.5} opacity={isLocked ? 0.5 : 1} />

                {/* Online dot */}
                {!isPlayer && node.online && (
                  <circle cx={node.x + radius - 3} cy={node.y - radius + 3} r="3" fill="#ccc" stroke="#111" strokeWidth="1" />
                )}

                {/* Boss crown */}
                {isBoss && (
                  <text x={node.x} y={node.y - radius - 4} textAnchor="middle" fontSize="10" fill="#dc2626">&#9813;</text>
                )}

                {/* Initials */}
                <text x={node.x} y={node.y + 1} textAnchor="middle" dominantBaseline="central"
                  fill={stroke} fontSize={isPlayer ? 10 : node.ring === 1 ? 9 : 8}
                  fontWeight="800" fontFamily="Inter, sans-serif" letterSpacing="1">
                  {initials}
                </text>

                {/* Name label */}
                <text x={node.x} y={node.y + radius + 12} textAnchor="middle"
                  fill="#777" fontSize="7" fontWeight="700" fontFamily="Inter, sans-serif" letterSpacing="1">
                  {isPlayer ? 'VOUS' : (node.name || '???')}
                </text>

                {/* Admin label */}
                {isImp && node.admin_label && !isPlayer && (
                  <text x={node.x} y={node.y + radius + 21} textAnchor="middle"
                    fill="#999" fontSize="6" fontWeight="600" fontFamily="Inter, sans-serif" letterSpacing="0.5" opacity="0.7">
                    {node.admin_label.toUpperCase()}
                  </text>
                )}
              </g>
            )
          })}
        </svg>
      </div>

      {/* Detail panel */}
      {selectedData && selectedData.type !== 'player' && (
        <div className="net-detail">
          <div className="net-detail-header">
            <div className="net-detail-avatar" style={{ borderColor: selectedData.type === 'npc_contact' ? (selectedData.locked ? '#444' : '#d97706') : (selectedData.type === 'boss' || selectedData.is_important) ? '#dc2626' : '#888' }}>
              {(selectedData.name || '??').substring(0, 2)}
            </div>
            <div className="net-detail-info">
              <div className="net-detail-name">{selectedData.name || 'Inconnu'}</div>
              <div className="net-detail-role">
                {selectedData.type === 'boss' ? 'BOSS' : selectedData.type === 'important' ? 'IMPORTANT' : selectedData.type === 'gang_member' ? 'MEMBRE' : selectedData.type === 'npc_contact' ? (selectedData.locked ? 'VERROUILLÉ' : 'NPC CONTACT') : 'CONTACT'}
                {selectedData.gangLabel && <span style={{ color: '#666', marginLeft: 6 }}>{selectedData.gangLabel}</span>}
              </div>
            </div>
            <div className={`net-detail-status ${selectedData.online ? 'net-detail-status--on' : ''}`}>
              {selectedData.online ? 'EN LIGNE' : 'HORS LIGNE'}
            </div>
          </div>
          {selectedData.description && (
            <div className="net-detail-desc">{selectedData.description}</div>
          )}
          {selectedData.admin_label && (
            <div className="net-detail-badge">
              {selectedData.admin_label}
            </div>
          )}
        </div>
      )}

      {/* Player info */}
      {selectedData && selectedData.type === 'player' && cnData && (
        <div className="net-detail">
          <div className="net-detail-header">
            <div className="net-detail-avatar net-detail-avatar--player">
              {cnData.profile.name.substring(0, 2)}
            </div>
            <div className="net-detail-info">
              <div className="net-detail-name">{cnData.profile.name}</div>
              <div className="net-detail-role">OPÉRATEUR</div>
            </div>
          </div>
          <div className="net-detail-stats">
            <div className="net-detail-stat">
              <span className="net-detail-stat-val">{cnData.contacts.length}</span>
              <span className="net-detail-stat-lbl">CONTACTS</span>
            </div>
            <div className="net-detail-stat">
              <span className="net-detail-stat-val">{cnData.contacts.filter(c => c.online).length}</span>
              <span className="net-detail-stat-lbl">EN LIGNE</span>
            </div>
            <div className="net-detail-stat">
              <span className="net-detail-stat-val">{cnData.groups.length}</span>
              <span className="net-detail-stat-lbl">GROUPES</span>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
