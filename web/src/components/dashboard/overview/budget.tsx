import * as React from 'react';
import type { SxProps } from '@mui/material/styles';
import { Wrench as StatIcon } from '@phosphor-icons/react/dist/ssr/Wrench';

import { StatCard } from './stat-card';

export interface BudgetProps {
  diff?: number;
  trend: 'up' | 'down';
  sx?: SxProps;
  value: string;
}

export function Budget({ diff, trend, sx, value }: BudgetProps): React.JSX.Element {
  return <StatCard icon={StatIcon} label="Channels" sx={sx} tone="light" value={value}  />;
}
