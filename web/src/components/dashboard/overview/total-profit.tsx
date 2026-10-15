import * as React from 'react';
import type { SxProps } from '@mui/material/styles';
import { UsersThree as StatIcon } from '@phosphor-icons/react/dist/ssr/UsersThree';

import { StatCard } from './stat-card';

export interface TotalProfitProps {
  sx?: SxProps;
  value: string;
}

export function TotalProfit({ value, sx }: TotalProfitProps): React.JSX.Element {
  return <StatCard icon={StatIcon} label="Groups" sx={sx} tone="light" value={value}  />;
}
