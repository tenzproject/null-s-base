export type AppMode = 'fake' | 'real' | 'intro';

// ============================================================================
// CRIMENET SOCIAL (v2)
// ============================================================================

export interface CrimeNetProfile {
  identifier: string;
  name: string;
  pseudonym: string | null;
  crimenet_id: string;
  description: string;
  avatar_url: string | null;
}

export interface CrimeNetContact {
  identifier: string;
  name: string;
  nickname: string | null;
  realName: string | null;
  gangname: string | null;
  gangLabel: string | null;
  is_boss: boolean;
  is_important: boolean;
  admin_label: string | null;
  description: string;
  avatar_url: string | null;
  online: boolean;
  is_fake: boolean;
  added_at: string;
}

export interface CrimeNetConversation {
  other_id: string;
  name: string;
  avatar_url: string | null;
  online: boolean;
  last_message: string;
  last_sent_at: string;
  is_mine: boolean;
  unread: number;
}

export interface CrimeNetMessage {
  id: number;
  from_id: string;
  to_id: string;
  content: string;
  sent_at: string;
  read_at: string | null;
}

export interface CrimeNetGroup {
  id: number;
  name: string;
  creator: string;
  created_at: string;
  member_count: number;
}

export interface CrimeNetGroupMessage {
  id: number;
  from_id: string;
  content: string;
  sent_at: string;
}

export interface NetworkNode {
  id: string;
  type: 'player' | 'contact' | 'boss' | 'important' | 'gang_member' | 'npc_contact';
  name?: string;
  gangname?: string;
  gangLabel?: string;
  is_important?: boolean;
  admin_label?: string;
  description?: string;
  avatar_url?: string | null;
  online?: boolean;
  is_fake?: boolean;
  is_npc?: boolean;
  locked?: boolean;
  ring: number;
  cluster?: string;
}

export interface NetworkEdge {
  from: string;
  to: string;
  type: 'direct' | 'gang_boss' | 'gang_member' | 'npc_chain' | 'gang_boss_via_member' | 'gang_bridge';
}

export interface NetworkCluster {
  id: string;
  label: string;
  gangname: string;
  boss: string;
  members: string[];
}

export interface NetworkData {
  nodes: NetworkNode[];
  edges: NetworkEdge[];
  clusters: NetworkCluster[];
}

export interface CrimeNetData {
  profile: CrimeNetProfile;
  contacts: CrimeNetContact[];
  conversations: CrimeNetConversation[];
  groups: CrimeNetGroup[];
  network: NetworkData;
  marketplace?: MarketListing[];
}

export interface SearchResult {
  identifier: string;
  name: string;
  serverId: number | null;
  is_fake?: boolean;
}

// ============================================================================
// GOFAST (kept from v1)
// ============================================================================

export interface ReputationTier {
  name: string;
  label: string;
  index: number;
  minXP: number;
  description: string;
}

export interface CrewTier {
  name: string;
  label: string;
  index: number;
}

export interface ActiveMission {
  id: string;
  tierName: string;
  state: string;
  isCrew: boolean;
  vehicle: string;
  cargo: string;
  difficulty: number;
  pickup?: { label: string };
  delivery?: { label: string };
  startTime?: number;
}

export interface JobListing {
  id: number;
  type: string;
  label: string;
  reward: number;
  status: 'available' | 'in_progress' | 'unavailable' | 'completed';
  difficulty: number;
  zone?: string;
}

export interface GoFastData {
  isIllegal: boolean;
  gangname?: string;
  gangLabel?: string;
  xp: number;
  tier: ReputationTier;
  crewTier?: CrewTier;
  totalMissions: number;
  totalFailed: number;
  blacklisted: boolean;
  contacts: any[];
  soloCooldown: number;
  crewCooldown: number;
  activeMission: ActiveMission | null;
  tiers: ReputationTier[];
  crewMinPlayers: number;
  jobs?: JobListing[];
  contracts?: GoFastContract[];
}

export interface CrewMember {
  serverId: number;
  name: string;
  identifier: string;
  grade: string;
}

export interface MissionResponse {
  success?: boolean;
  error?: string;
  remaining?: number;
  online?: number;
  required?: number;
  mission?: ActiveMission;
}

export interface MissionResult {
  success: boolean;
  payment?: number;
  xpGain?: number;
  xpLost?: number;
  speedBonus?: boolean;
}

// ============================================================================
// MARKETPLACE (Marché Noir)
// ============================================================================

export type MarketCategory = 'vehicles' | 'weapons' | 'items' | 'drugs';

export interface MarketListing {
  id: number;
  seller_id: string;
  seller_name: string;
  seller_online: boolean;
  category: MarketCategory;
  title: string;
  description: string;
  price: number;
  photos: string[];
  status: 'active' | 'sold' | 'expired';
  created_at: string;
  is_mine: boolean;
}

// ============================================================================
// CONTRACTS (Jobs v2)
// ============================================================================

export interface GoFastContract {
  id: string;
  type: 'solo' | 'crew';
  label: string;
  description: string;
  vehicleModel: string;
  vehicleLabel: string;
  cargoEstimate: string;
  revenue: number;
  xpReward: number;
  minXP: number;
  difficulty: number;
  crewMin?: number;
  crewMax?: number;
  deadline: number; // minutes to complete
  fixedTime?: string | null; // e.g. "22:00" or null
  fixedTimeTs?: number | null; // unix timestamp for fixed-time start
  status: 'available' | 'locked' | 'accepted' | 'expired';
  acceptedBy?: string;
  expiresAt?: string;
}
