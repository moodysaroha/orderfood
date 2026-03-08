import { SduiScreen } from './types';
import { ScreenBuilder } from './builders/screen.builder';

/**
 * Registry of screen builders. Each screen name maps to a builder function
 * that receives data context and returns an SDUI screen payload.
 */

export type ScreenBuilderFn = (context: Record<string, unknown>) => SduiScreen;

class SduiRegistry {
  private builders = new Map<string, ScreenBuilderFn>();

  register(screenName: string, builderFn: ScreenBuilderFn): void {
    this.builders.set(screenName, builderFn);
  }

  build(screenName: string, context: Record<string, unknown>): SduiScreen | null {
    const builderFn = this.builders.get(screenName);
    if (!builderFn) return null;
    return builderFn(context);
  }

  getRegisteredScreens(): string[] {
    return Array.from(this.builders.keys());
  }

  has(screenName: string): boolean {
    return this.builders.has(screenName);
  }
}

export const sduiRegistry = new SduiRegistry();

export { ScreenBuilder };
