export interface SduiComponent {
  type: string;
  props?: Record<string, unknown>;
  children?: SduiComponent[];
}

export interface SduiAction {
  type: 'navigate' | 'api_call' | 'refresh' | 'toggle';
  route?: string;
  method?: string;
  url?: string;
  body?: Record<string, unknown>;
  confirmMessage?: string;
}

export interface SduiScreen {
  screen: string;
  version: number;
  components: SduiComponent[];
  actions?: Record<string, SduiAction>;
  pollingIntervalMs?: number;
}
