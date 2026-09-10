export interface IDCardData {
  type: 'identity_card' | 'drive' | 'weapon' | string;
  firstname: string;
  lastname: string;
  birthday: string;
  sex: string;
  creation: number;
  licenses: Record<string, boolean>;
  nationality: string;
}

export interface IDCardProps {
  visible: boolean;
  onClose: () => void;
}
