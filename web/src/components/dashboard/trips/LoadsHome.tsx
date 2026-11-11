'use client';

import * as React from 'react';
import { Stack, Tab, Tabs } from '@mui/material';
import { Inventory2, LocalShipping, Straighten } from '@mui/icons-material';

import { EquipmentBoard } from './EquipmentBoard';
import { LoadsBoard } from './LoadsBoard';
import { MilesBoard } from './MilesBoard';

// Loads and the equipment board side by side (top-bar Loads dialog and the Loads page).
export function LoadsHome(): React.JSX.Element {
  const [view, setView] = React.useState<'loads' | 'equipment' | 'miles'>('loads');
  return (
    <Stack spacing={2}>
      <Tabs value={view} onChange={(_, v) => setView(v)}>
        <Tab value="loads" icon={<LocalShipping fontSize="small" />} iconPosition="start" label="Loads" />
        <Tab value="equipment" icon={<Inventory2 fontSize="small" />} iconPosition="start" label="Trucks · Trailers · Drivers" data-testid="equipmentTab" />
        <Tab value="miles" icon={<Straighten fontSize="small" />} iconPosition="start" label="Miles" data-testid="milesTab" />
      </Tabs>
      {view === 'loads' ? <LoadsBoard /> : view === 'equipment' ? <EquipmentBoard /> : <MilesBoard />}
    </Stack>
  );
}
