import { useState, useEffect, useCallback } from 'react'
import { AppMode, CrimeNetData, GoFastData, MissionResponse, MissionResult, CrimeNetMessage, CrimeNetGroupMessage, MarketListing, GoFastContract } from './types'
import { postNUI, isDev } from './nui'
import FakeApp from './components/FakeApp'
import IntroAnimation from './components/IntroAnimation'
import CrimeNet from './components/CrimeNet'

function App() {
  const [mode, setMode] = useState<AppMode>('fake')
  const [cnData, setCnData] = useState<CrimeNetData | null>(null)
  const [goFastData, setGoFastData] = useState<GoFastData | null>(null)
  const [missionResponse, setMissionResponse] = useState<MissionResponse | null>(null)
  const [missionResult, setMissionResult] = useState<MissionResult | null>(null)
  const [betrayed, setBetrayed] = useState(false)

  useEffect(() => {
    if (isDev) {
      document.body.style.visibility = 'visible'
    }
  }, [])

  const handleMessage = useCallback((event: MessageEvent) => {
    const { action, data } = event.data || {}
    if (!action) return

    switch (action) {
      case 'crimenet:setMode':
        if (data?.mode === 'real') {
          setMode('intro')
        } else {
          setMode('fake')
        }
        break

      case 'crimenet:fullData':
        setCnData(data as CrimeNetData)
        break

      case 'crimenet:goFastData':
        setGoFastData(data as GoFastData)
        break

      case 'crimenet:missionResponse':
        setMissionResponse(data as MissionResponse)
        break

      case 'crimenet:missionResult':
        setMissionResult(data as MissionResult)
        break

      case 'crimenet:betrayed':
        setBetrayed(true)
        if (goFastData) {
          setGoFastData({ ...goFastData, blacklisted: true })
        }
        break

      case 'crimenet:newMessage': {
        const msg = data as { id: number; from_id: string; from_name: string; content: string }
        if (cnData) {
          const convIdx = cnData.conversations.findIndex(c => c.other_id === msg.from_id)
          const newConvs = [...cnData.conversations]
          if (convIdx >= 0) {
            newConvs[convIdx] = {
              ...newConvs[convIdx],
              last_message: msg.content,
              last_sent_at: new Date().toISOString(),
              is_mine: false,
              unread: newConvs[convIdx].unread + 1,
            }
          } else {
            newConvs.unshift({
              other_id: msg.from_id,
              name: msg.from_name,
              avatar_url: null,
              online: true,
              last_message: msg.content,
              last_sent_at: new Date().toISOString(),
              is_mine: false,
              unread: 1,
            })
          }
          setCnData({ ...cnData, conversations: newConvs })
        }
        break
      }

      case 'crimenet:newGroupMessage':
        // Could update group message list in real-time
        break

      case 'crimenet:contactShared':
        // Refresh data to get new contact
        postNUI('crimenet:refreshData').then((d) => {
          if (d) setCnData(d as CrimeNetData)
        })
        break
    }
  }, [cnData, goFastData])

  useEffect(() => {
    window.addEventListener('message', handleMessage)
    return () => window.removeEventListener('message', handleMessage)
  }, [handleMessage])

  useEffect(() => {
    if (!isDev) {
      postNUI('crimenet:appOpened')
    }
  }, [])

  // Dev mode: auto-switch to real mode + load mock data
  useEffect(() => {
    if (!isDev) return
    const timer = setTimeout(() => {
      window.dispatchEvent(new MessageEvent('message', {
        data: { action: 'crimenet:setMode', data: { mode: 'real' } }
      }))
      // Mock CrimeNet data for dev
      window.dispatchEvent(new MessageEvent('message', {
        data: { action: 'crimenet:fullData', data: getMockCrimeNetData() }
      }))
      window.dispatchEvent(new MessageEvent('message', {
        data: { action: 'crimenet:goFastData', data: getMockGoFastData() }
      }))
    }, 500)
    return () => clearTimeout(timer)
  }, [])

  const onIntroComplete = useCallback(() => {
    setMode('real')
  }, [])

  const onRequestMission = useCallback((type: 'solo' | 'crew', memberIds?: number[]) => {
    if (type === 'crew') {
      postNUI('crimenet:requestCrewMission', { members: memberIds })
    } else {
      postNUI('crimenet:requestMission')
    }
  }, [])

  const onRefreshData = useCallback(() => {
    postNUI('crimenet:refreshData').then((d) => {
      if (d) setCnData(d as CrimeNetData)
    })
  }, [])

  if (mode === 'fake') {
    return <FakeApp />
  }

  if (mode === 'intro') {
    return <IntroAnimation onComplete={onIntroComplete} />
  }

  return (
    <CrimeNet
      cnData={cnData}
      goFastData={goFastData}
      missionResponse={missionResponse}
      missionResult={missionResult}
      betrayed={betrayed}
      onRequestMission={onRequestMission}
      onRefreshData={onRefreshData}
      onClearMissionResponse={() => setMissionResponse(null)}
      onClearMissionResult={() => setMissionResult(null)}
    />
  )
}

function getMockCrimeNetData(): CrimeNetData {
  return {
    profile: {
      identifier: 'dev:player1',
      name: 'Jean Dupont',
      pseudonym: null,
      crimenet_id: 'CN-DEV01',
      description: 'Runner confirmé du réseau sud.',
      avatar_url: null,
    },
    contacts: [
      {
        identifier: 'fake:el_patron:1234',
        name: 'El Patron',
        nickname: null,
        realName: 'El Patron',
        gangname: 'cartel',
        gangLabel: 'Cartel de Madrazo',
        is_boss: true,
        is_important: true,
        admin_label: 'Chef du Cartel',
        description: 'Le chef incontesté du cartel.',
        avatar_url: null,
        online: false,
        is_fake: true,
        added_at: '2024-01-15',
      },
      {
        identifier: 'fake:sicario:2345',
        name: 'Sicario',
        nickname: null,
        realName: 'Sicario',
        gangname: 'cartel',
        gangLabel: 'Cartel de Madrazo',
        is_boss: false,
        is_important: false,
        admin_label: null,
        description: 'Bras armé du cartel.',
        avatar_url: null,
        online: true,
        is_fake: true,
        added_at: '2024-02-10',
      },
      {
        identifier: 'fake:mule:3456',
        name: 'Mule',
        nickname: null,
        realName: 'Mule',
        gangname: 'cartel',
        gangLabel: 'Cartel de Madrazo',
        is_boss: false,
        is_important: false,
        admin_label: null,
        description: 'Transport de marchandise.',
        avatar_url: null,
        online: false,
        is_fake: true,
        added_at: '2024-03-05',
      },
      {
        identifier: 'fake:shadow:4567',
        name: 'Shadow',
        nickname: 'L\'ombre',
        realName: 'Shadow',
        gangname: null,
        gangLabel: null,
        is_boss: false,
        is_important: true,
        admin_label: 'Informateur',
        description: 'Informateur freelance. Pas de gang.',
        avatar_url: null,
        online: true,
        is_fake: true,
        added_at: '2024-01-20',
      },
      {
        identifier: 'fake:chimiste:5678',
        name: 'Le Chimiste',
        nickname: null,
        realName: 'Le Chimiste',
        gangname: 'labos',
        gangLabel: 'Les Labos',
        is_boss: true,
        is_important: true,
        admin_label: 'Chef du Labo',
        description: 'Cerveau chimique du réseau.',
        avatar_url: null,
        online: false,
        is_fake: true,
        added_at: '2024-04-01',
      },
      {
        identifier: 'fake:distributeur:6789',
        name: 'Distributeur',
        nickname: null,
        realName: 'Distributeur',
        gangname: 'labos',
        gangLabel: 'Les Labos',
        is_boss: false,
        is_important: false,
        admin_label: null,
        description: 'Distribution locale.',
        avatar_url: null,
        online: true,
        is_fake: true,
        added_at: '2024-04-15',
      },
      {
        identifier: 'fake:broker:7890',
        name: 'Broker',
        nickname: null,
        realName: 'Broker',
        gangname: null,
        gangLabel: null,
        is_boss: false,
        is_important: true,
        admin_label: 'Courtier',
        description: 'Intermédiaire entre réseaux.',
        avatar_url: null,
        online: false,
        is_fake: true,
        added_at: '2024-05-01',
      },
    ],
    conversations: [
      {
        other_id: 'fake:sicario:2345',
        name: 'Sicario',
        avatar_url: null,
        online: true,
        last_message: 'Le colis est prêt. Passe ce soir.',
        last_sent_at: '2024-06-01 18:30:00',
        is_mine: false,
        unread: 2,
      },
      {
        other_id: 'fake:shadow:4567',
        name: 'Shadow',
        avatar_url: null,
        online: true,
        last_message: 'J\'ai des infos sur la prochaine livraison.',
        last_sent_at: '2024-05-30 14:00:00',
        is_mine: false,
        unread: 0,
      },
    ],
    groups: [
      { id: 1, name: 'Opération Nuit Noire', creator: 'dev:player1', created_at: '2024-05-01', member_count: 4 },
    ],
    network: {
      nodes: [
        { id: 'dev:player1', type: 'player', ring: 0 },
        { id: 'fake:el_patron:1234', type: 'boss', name: 'El Patron', gangname: 'cartel', gangLabel: 'Cartel de Madrazo', is_important: true, admin_label: 'Chef du Cartel', online: false, is_fake: true, ring: 1, cluster: 'gang_cartel' },
        { id: 'fake:sicario:2345', type: 'gang_member', name: 'Sicario', gangname: 'cartel', gangLabel: 'Cartel de Madrazo', online: true, is_fake: true, ring: 2, cluster: 'gang_cartel' },
        { id: 'fake:mule:3456', type: 'gang_member', name: 'Mule', gangname: 'cartel', gangLabel: 'Cartel de Madrazo', online: false, is_fake: true, ring: 2, cluster: 'gang_cartel' },
        { id: 'fake:shadow:4567', type: 'important', name: 'Shadow', is_important: true, admin_label: 'Informateur', online: true, is_fake: true, ring: 1 },
        { id: 'fake:chimiste:5678', type: 'boss', name: 'Le Chimiste', gangname: 'labos', gangLabel: 'Les Labos', is_important: true, admin_label: 'Chef du Labo', online: false, is_fake: true, ring: 1, cluster: 'gang_labos' },
        { id: 'fake:distributeur:6789', type: 'gang_member', name: 'Distributeur', gangname: 'labos', gangLabel: 'Les Labos', online: true, is_fake: true, ring: 2, cluster: 'gang_labos' },
        { id: 'fake:broker:7890', type: 'important', name: 'Broker', is_important: true, admin_label: 'Courtier', online: false, is_fake: true, ring: 1 },
      ],
      edges: [
        { from: 'dev:player1', to: 'fake:el_patron:1234', type: 'gang_boss' },
        { from: 'fake:el_patron:1234', to: 'fake:sicario:2345', type: 'gang_member' },
        { from: 'fake:el_patron:1234', to: 'fake:mule:3456', type: 'gang_member' },
        { from: 'dev:player1', to: 'fake:shadow:4567', type: 'direct' },
        { from: 'dev:player1', to: 'fake:chimiste:5678', type: 'gang_boss' },
        { from: 'fake:chimiste:5678', to: 'fake:distributeur:6789', type: 'gang_member' },
        { from: 'dev:player1', to: 'fake:broker:7890', type: 'direct' },
      ],
      clusters: [
        { id: 'gang_cartel', label: 'Cartel de Madrazo', gangname: 'cartel', boss: 'fake:el_patron:1234', members: ['fake:el_patron:1234', 'fake:sicario:2345', 'fake:mule:3456'] },
        { id: 'gang_labos', label: 'Les Labos', gangname: 'labos', boss: 'fake:chimiste:5678', members: ['fake:chimiste:5678', 'fake:distributeur:6789'] },
      ],
    },
    marketplace: [
      { id: 1, seller_id: 'fake:sicario:2345', seller_name: 'Sicario', seller_online: true, category: 'vehicles', title: 'Sultan RS Custom', description: 'Full upgrade, turbo, blindage. Peinture noir mat.', price: 85000, photos: [], status: 'active', created_at: '2024-06-01', is_mine: false },
      { id: 2, seller_id: 'dev:player1', seller_name: 'Jean Dupont', seller_online: true, category: 'weapons', title: 'AP Pistol x2', description: 'Deux pistolets AP en bon état.', price: 12000, photos: [], status: 'active', created_at: '2024-06-02', is_mine: true },
      { id: 3, seller_id: 'fake:chimiste:5678', seller_name: 'Le Chimiste', seller_online: false, category: 'drugs', title: 'Lot Meth 50g', description: 'Meth pure, qualité labo.', price: 25000, photos: [], status: 'active', created_at: '2024-05-28', is_mine: false },
      { id: 4, seller_id: 'fake:broker:7890', seller_name: 'Broker', seller_online: false, category: 'items', title: 'Lockpick x10', description: 'Kit crochetage. Fiable.', price: 5000, photos: [], status: 'active', created_at: '2024-05-30', is_mine: false },
      { id: 5, seller_id: 'dev:player1', seller_name: 'Jean Dupont', seller_online: true, category: 'vehicles', title: 'Elegy Retro', description: 'Vendu tel quel.', price: 45000, photos: [], status: 'sold', created_at: '2024-05-20', is_mine: true },
    ] as MarketListing[],
  }
}

function getMockGoFastData(): GoFastData {
  return {
    isIllegal: true,
    gangname: 'ballas',
    gangLabel: 'Ballas',
    xp: 450,
    tier: { name: 'runner', label: 'RUNNER', index: 2, minXP: 200, description: 'Transporteur confirmé du réseau' },
    crewTier: { name: 'crew_t2', label: 'Crew Confirmé', index: 2 },
    totalMissions: 23,
    totalFailed: 2,
    blacklisted: false,
    contacts: [],
    soloCooldown: 0,
    crewCooldown: 125,
    activeMission: null,
    tiers: [
      { name: 'prospect', label: 'PROSPECT', index: 1, minXP: 0, description: 'Nouveau dans le réseau' },
      { name: 'runner', label: 'RUNNER', index: 2, minXP: 200, description: 'Transporteur confirmé' },
      { name: 'smuggler', label: 'SMUGGLER', index: 3, minXP: 800, description: 'Contrebandier expérimenté' },
      { name: 'kingpin', label: 'KINGPIN', index: 4, minXP: 2000, description: 'Maître du réseau' },
    ],
    crewMinPlayers: 2,
    jobs: [],
    contracts: [
      { id: 'ctr_1', type: 'solo', label: 'Transport Express Nord', description: 'Livraison rapide secteur nord. Pas de détour.', vehicleModel: 'sultan', vehicleLabel: 'Sultan', cargoEstimate: '~15kg cocaïne', revenue: 8500, xpReward: 45, minXP: 0, difficulty: 3, deadline: 20, fixedTime: null, fixedTimeTs: null, status: 'available' },
      { id: 'ctr_2', type: 'solo', label: 'Course Paleto Bay', description: 'Récupérer et livrer au nord.', vehicleModel: 'elegy', vehicleLabel: 'Elegy', cargoEstimate: '~8kg herbe', revenue: 5200, xpReward: 30, minXP: 100, difficulty: 2, deadline: 25, fixedTime: null, fixedTimeTs: null, status: 'available' },
      { id: 'ctr_3', type: 'crew', label: 'Convoi Armé Sandy', description: 'Transport lourd avec escorte. Zone chaude.', vehicleModel: 'mule', vehicleLabel: 'Mule', cargoEstimate: '~50kg mixte', revenue: 22000, xpReward: 120, minXP: 300, difficulty: 7, crewMin: 3, crewMax: 6, deadline: 30, fixedTime: null, fixedTimeTs: null, status: 'available' },
      { id: 'ctr_4', type: 'solo', label: 'Livraison VIP Downtown', description: 'Client exigeant. Discrétion absolue.', vehicleModel: 'schafter', vehicleLabel: 'Schafter V12', cargoEstimate: '~5kg premium', revenue: 12000, xpReward: 65, minXP: 500, difficulty: 5, deadline: 15, fixedTime: null, fixedTimeTs: null, status: 'available' },
      { id: 'ctr_5', type: 'crew', label: 'Opération Minuit', description: 'Contrat à heure fixe. Ne pas rater le départ.', vehicleModel: 'baller', vehicleLabel: 'Baller', cargoEstimate: '~35kg armes', revenue: 35000, xpReward: 200, minXP: 800, difficulty: 9, crewMin: 4, crewMax: 6, deadline: 45, fixedTime: '22:00', fixedTimeTs: null, status: 'available' },
      { id: 'ctr_6', type: 'solo', label: 'Drop Rapide Aéroport', description: 'Dépose à l\'aéroport. Vite fait.', vehicleModel: 'blista', vehicleLabel: 'Blista', cargoEstimate: '~3kg divers', revenue: 3200, xpReward: 15, minXP: 0, difficulty: 1, deadline: 10, fixedTime: null, fixedTimeTs: null, status: 'available' },
    ] as GoFastContract[],
  }
}

export default App
