export type DevPanelPage = 'executor' | 'triggers' | 'functions' | 'actions' | 'resources' | 'ipl';

export interface QuickAction {
  id: string;
  label: string;
  command?: string;
  event?: string;
  serverEvent?: string;
  clientEvent?: string;
  icon: string;
}

export interface DevPanelConfig {
  quickActions: QuickAction[];
}

export interface ExecutionResult {
  success: boolean;
  output: string;
  side: string;
  timestamp?: number;
}

export interface ResourceInfo {
  name: string;
  state: string;
}

export interface ScannedEvent {
  name: string;
  side: string;
  isPattern?: boolean;
}

export interface TriggerArg {
  id: string;
  type: 'string' | 'number' | 'boolean' | 'table';
  value: string;
}

export interface Bob74IplEntry {
  id: string;
  name: string;
  category: string;
  coords: string;
  loaded: boolean;
  hasOptions?: boolean;
}

export interface Bob74IplChoice {
  value: string | number;
  label: string;
}

export interface Bob74IplOption {
  key: string;
  label: string;
  type: 'select' | 'toggle' | 'color';
  choices?: Bob74IplChoice[];
  hasColor?: boolean;
  colorChoices?: Bob74IplChoice[];
}
