import type { NavItemConfig } from '@/types/nav';

// Shared by the desktop and mobile sidebars: white surface, slate items, soft blue active state.
// Everything points at theme variables, so dark mode follows automatically.
export const navCssVars = {
  '--NavItem-color': 'var(--mui-palette-text-secondary)',
  '--NavItem-hover-background': 'var(--mui-palette-background-level2)',
  '--NavItem-hover-color': 'var(--mui-palette-text-primary)',
  '--NavItem-active-background': 'rgba(var(--mui-palette-primary-mainChannel) / 0.1)',
  '--NavItem-active-color': 'var(--mui-palette-primary-main)',
  '--NavItem-disabled-color': 'var(--mui-palette-text-disabled)',
  '--NavItem-icon-color': 'var(--mui-palette-neutral-400)',
  '--NavItem-icon-active-color': 'var(--mui-palette-primary-main)',
  '--NavItem-icon-disabled-color': 'var(--mui-palette-text-disabled)',
} as const;

export const navSurface = 'var(--mui-palette-background-paper)';

const SECTIONS: { label: string; keys: string[] }[] = [
  { label: 'Inbox', keys: ['overview', 'messages', 'truckchat', 'groups', 'staff chat', 'system_messages', 'boardcast_messages'] },
  { label: 'Fleet', keys: ['truckgroup', 'driver', 'channels', 'channel Members'] },
  { label: 'Admin', keys: ['templates', 'user', 'training', 'automation'] },
];

export interface NavSection {
  label: string;
  items: NavItemConfig[];
}

// Groups the flat menu into labelled sections; anything unknown lands in "More" so nothing disappears
export function groupNavItems(items: NavItemConfig[]): NavSection[] {
  const used = new Set<string>();
  const sections: NavSection[] = SECTIONS.map((section) => {
    const picked = section.keys
      .map((key) => items.find((item) => item.key === key))
      .filter((item): item is NavItemConfig => Boolean(item));
    picked.forEach((item) => used.add(item.key));
    return { label: section.label, items: picked };
  });
  const rest = items.filter((item) => !used.has(item.key));
  if (rest.length) sections.push({ label: 'More', items: rest });
  return sections.filter((section) => section.items.length);
}
