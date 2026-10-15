// One source of truth for every chat surface (Messages, Truck chat, Staff chat, Truck groups).
// Values are theme variables, so light and dark mode both work.
export const chat = {
  canvas: 'var(--mui-palette-background-level1)',
  staff: { bg: 'var(--mui-palette-primary-main)', fg: '#ffffff', border: '1px solid transparent' },
  driver: { bg: 'var(--mui-palette-background-paper)', fg: 'var(--mui-palette-text-primary)', border: '1px solid var(--mui-palette-divider)' },
  assistant: {
    bg: 'rgba(var(--mui-palette-warning-mainChannel) / 0.08)',
    fg: 'var(--mui-palette-text-primary)',
    border: '1px solid rgba(var(--mui-palette-warning-mainChannel) / 0.35)',
  },
  radius: '12px',
  shadow: '0 1px 2px rgba(15, 23, 42, 0.06)',
  // Conversation lists
  rowSelected: {
    backgroundColor: 'rgba(var(--mui-palette-primary-mainChannel) / 0.08)',
    color: 'var(--mui-palette-text-primary)',
    boxShadow: 'inset 3px 0 0 var(--mui-palette-primary-main)',
  },
  rowHover: { backgroundColor: 'var(--mui-palette-background-level2)', color: 'var(--mui-palette-text-primary)' },
} as const;
