import { SduiComponent, SduiAction, SduiScreen } from '../types';
import { COMPONENT_TYPES } from '../components';

/**
 * Fluent builder for constructing SDUI screen responses.
 * Provides a chainable API to build complex screen layouts.
 */
export class ScreenBuilder {
  private screen: string;
  private version: number = 1;
  private components: SduiComponent[] = [];
  private actions: Record<string, SduiAction> = {};
  private pollingIntervalMs?: number;

  constructor(screen: string) {
    this.screen = screen;
  }

  setVersion(v: number): this {
    this.version = v;
    return this;
  }

  setPollingInterval(ms: number): this {
    this.pollingIntervalMs = ms;
    return this;
  }

  addComponent(component: SduiComponent): this {
    this.components.push(component);
    return this;
  }

  addAction(name: string, action: SduiAction): this {
    this.actions[name] = action;
    return this;
  }

  addAppBar(title: string, showBack?: boolean | SduiComponent[], actions?: SduiComponent[]): this {
    const isArray = Array.isArray(showBack);
    this.components.push({
      type: COMPONENT_TYPES.appBar,
      props: { title, showBack: isArray ? false : showBack },
      children: isArray ? showBack : actions,
    });
    return this;
  }

  addStatsRow(cards: { label: string; value: string; icon: string }[]): this {
    this.components.push({
      type: COMPONENT_TYPES.statsRow,
      children: cards.map((c) => ({
        type: COMPONENT_TYPES.statCard,
        props: c,
      })),
    });
    return this;
  }

  addSectionHeader(title: string, actionLabel?: string, actionKey?: string): this {
    this.components.push({
      type: COMPONENT_TYPES.sectionHeader,
      props: { title, actionLabel, actionKey },
    });
    return this;
  }

  addList(items: SduiComponent[]): this {
    this.components.push({
      type: COMPONENT_TYPES.list,
      children: items,
    });
    return this;
  }

  addEmptyState(message: string, icon?: string): this {
    this.components.push({
      type: COMPONENT_TYPES.emptyState,
      props: { message, icon },
    });
    return this;
  }

  addButton(label: string, actionKey: string, variant?: string): this {
    this.components.push({
      type: COMPONENT_TYPES.button,
      props: { label, actionKey, variant: variant ?? 'primary' },
    });
    return this;
  }

  addFab(icon: string, actionKey: string): this {
    this.components.push({
      type: COMPONENT_TYPES.fab,
      props: { icon, actionKey },
    });
    return this;
  }

  build(): SduiScreen {
    return {
      screen: this.screen,
      version: this.version,
      components: this.components,
      ...(Object.keys(this.actions).length > 0 && { actions: this.actions }),
      ...(this.pollingIntervalMs && { pollingIntervalMs: this.pollingIntervalMs }),
    };
  }
}
