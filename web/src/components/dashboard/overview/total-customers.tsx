import * as React from 'react';
import type { SxProps } from '@mui/material/styles';
import { Chat as StatIcon } from '@phosphor-icons/react/dist/ssr/Chat';

import { StatCard } from './stat-card';

export interface TotalCustomersProps {
  diff?: number;
  trend: 'up' | 'down';
  sx?: SxProps;
  value: string;
}

export function TotalCustomers({ diff, trend, sx, value }: TotalCustomersProps): React.JSX.Element {
  return <StatCard icon={StatIcon} label="Total messages" sx={sx} tone="light" value={value}  />;
}
