import type { Shadows } from '@mui/material/styles/shadows';

// Restrained elevation: hairline shadows for surfaces, a real shadow only for floating layers
const sm = '0 1px 2px rgba(15, 23, 42, 0.05)';
const md = '0 1px 3px rgba(15, 23, 42, 0.08), 0 1px 2px rgba(15, 23, 42, 0.04)';
const lg = '0 4px 12px -2px rgba(15, 23, 42, 0.08), 0 2px 4px -2px rgba(15, 23, 42, 0.05)';
const xl = '0 12px 32px -8px rgba(15, 23, 42, 0.18), 0 4px 8px -4px rgba(15, 23, 42, 0.06)';

export const shadows = [
  'none',
  sm,
  md,
  md,
  lg,
  lg,
  lg,
  lg,
  xl,
  xl,
  xl,
  xl,
  xl,
  xl,
  xl,
  xl,
  xl,
  xl,
  xl,
  xl,
  xl,
  xl,
  xl,
  xl,
  xl,
] satisfies Shadows;
