/**
 * SDUI Component type definitions.
 * Each component type maps to a Flutter widget via the client-side registry.
 * Adding a new component here = the Flutter app can render it without an update
 * (as long as the component type is registered in the Flutter SDUI registry).
 */

export const COMPONENT_TYPES = {
  // Layout
  scaffold: 'scaffold',
  column: 'column',
  row: 'row',
  container: 'container',
  scrollView: 'scrollView',
  padding: 'padding',
  card: 'card',
  divider: 'divider',
  spacer: 'spacer',
  expanded: 'expanded',

  // Navigation
  appBar: 'appBar',
  bottomNav: 'bottomNav',
  tabBar: 'tabBar',

  // Content
  text: 'text',
  image: 'image',
  icon: 'icon',
  badge: 'badge',
  avatar: 'avatar',

  // Dashboard
  statsRow: 'statsRow',
  statCard: 'statCard',
  sectionHeader: 'sectionHeader',

  // Lists
  list: 'list',
  listTile: 'listTile',
  orderTile: 'orderTile',
  menuItemTile: 'menuItemTile',
  menuItemCard: 'menuItemCard',

  // Interactive
  button: 'button',
  iconButton: 'iconButton',
  switchToggle: 'switchToggle',
  chip: 'chip',
  fab: 'fab',

  // Forms
  textField: 'textField',
  dropdown: 'dropdown',
  imageUpload: 'imageUpload',

  // Feedback
  emptyState: 'emptyState',
  loading: 'loading',
  errorDisplay: 'errorDisplay',
  snackbar: 'snackbar',
} as const;

export type ComponentType = typeof COMPONENT_TYPES[keyof typeof COMPONENT_TYPES];

export function getComponentTypesList(): { type: string; category: string }[] {
  const categories: Record<string, string[]> = {
    layout: ['scaffold', 'column', 'row', 'container', 'scrollView', 'padding', 'card', 'divider', 'spacer', 'expanded'],
    navigation: ['appBar', 'bottomNav', 'tabBar'],
    content: ['text', 'image', 'icon', 'badge', 'avatar'],
    dashboard: ['statsRow', 'statCard', 'sectionHeader'],
    lists: ['list', 'listTile', 'orderTile', 'menuItemTile', 'menuItemCard'],
    interactive: ['button', 'iconButton', 'switchToggle', 'chip', 'fab'],
    forms: ['textField', 'dropdown', 'imageUpload'],
    feedback: ['emptyState', 'loading', 'errorDisplay', 'snackbar'],
  };

  const result: { type: string; category: string }[] = [];
  for (const [category, types] of Object.entries(categories)) {
    for (const type of types) {
      result.push({ type, category });
    }
  }
  return result;
}
