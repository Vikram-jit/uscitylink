import * as React from 'react';
import type { SxProps } from '@mui/material/styles';
import { Envelope as StatIcon } from '@phosphor-icons/react/dist/ssr/Envelope';

import { StatCard } from './stat-card';

export interface TasksProgressProps {
  sx?: SxProps;
  value: number;
}

export function TasksProgress({ value, sx }: TasksProgressProps): React.JSX.Element {
  return <StatCard icon={StatIcon} label="Unread messages" sx={sx} tone="light" value={value} caption={value > 0 ? 'Needs reply' : 'All caught up'} captionColor={value > 0 ? 'warning' : 'success'} />;
}
