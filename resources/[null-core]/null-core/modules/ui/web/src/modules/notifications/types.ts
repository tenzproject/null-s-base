export type NotificationType = 'standard' | 'advanced' | 'accept';

export type NotificationTheme = 'default' | 'success' | 'info' | 'warning' | 'error';

export interface NotificationData {
  id: string;
  type: NotificationType;
  message: string;
  title?: string;
  subject?: string;
  icon?: string;
  couleurProgress?: string;
  timeout?: number;
  progress?: boolean;
  theme?: NotificationTheme;
  exitAnim?: string;
  pin_id?: string;
  duplicate?: boolean;
}
