export interface FreejobTabletProps {
  visible: boolean;
  onClose: () => void;
  primaryColor?: string;
}

export interface FreejobMetier {
  id: string;
  nom: string;
  description: string;
  icon: string;
  rentabilite: number;
  zone: { x: number; y: number; z: number };
  image?: string;
}

export interface FreejobTabletData {
  metiers: FreejobMetier[];
}

export interface FreejobHUDProps {
  visible: boolean;
  primaryColor?: string;
  serverIcon?: string;
}

export interface FreejobHUDData {
  jobName: string;
  jobIcon: string;
  tasks: number;
  bonus: number;
  reward: number;
  rewardPerTask: number;
}

export interface FreejobMarkerData {
  id: string;
  x: number;
  y: number;
  z: number;
  label?: string;
}

export interface FreejobInfoProps {
  visible: boolean;
  onClose: () => void;
}

export interface FreejobInfoData {
  title: string;
  lines: { icon: string; key: string; text: string }[];
}
