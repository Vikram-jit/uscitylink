'use client';

import * as React from 'react';
import { Box, Stack, Tooltip, Typography } from '@mui/material';
import { ChevronRight, LocalParking, SwapHoriz } from '@mui/icons-material';

import { Trip } from '@/redux/TripApiSlice';

import { legsInOrder, STATUS } from './tripFormat';

// A load's legs in one line: who moves each part and where it changes hands —
//   [Raj · 23865 · Rolling] › 🅿 Yard › [assign driver · Scheduled]

const DOT: Record<string, string> = {
  default: 'text.disabled',
  primary: 'primary.main',
  secondary: 'secondary.main',
  success: 'success.main',
  warning: 'warning.main',
  error: 'error.main',
  info: 'info.main',
};

export function LegChain({ legs, names, dense }: { legs?: Trip[]; names: Record<string, string>; dense?: boolean }): React.JSX.Element {
  const list = legsInOrder(legs).filter((l) => l.status !== 'cancelled');
  return (
    <Stack direction="row" alignItems="center" flexWrap="wrap" useFlexGap sx={{ gap: 0.5 }} data-testid="legChain">
      {list.map((leg, i) => {
        const stops = [...(leg.stops || [])].sort((a, b) => a.seq - b.seq);
        const last = stops[stops.length - 1];
        const who = leg.driver_profile_id ? names[leg.driver_profile_id] || 'Driver' : null;
        const s = STATUS[leg.status];
        return (
          <React.Fragment key={leg.id}>
            {i > 0 && <ChevronRight fontSize="small" sx={{ color: 'text.disabled' }} />}
            <Tooltip title={`Leg ${leg.leg_no} · ${leg.trip_no || ''} · ${s.label}${leg.trailer_numbers ? ` · trailer ${leg.trailer_numbers}` : ''}`}>
              <Box
                sx={{
                  display: 'inline-flex',
                  alignItems: 'center',
                  gap: 0.75,
                  px: 1,
                  py: dense ? 0.25 : 0.5,
                  borderRadius: 1.5,
                  border: 1,
                  borderColor: who ? 'divider' : 'warning.main',
                  bgcolor: 'background.paper',
                }}
              >
                <Box sx={{ width: 8, height: 8, borderRadius: '50%', bgcolor: DOT[s.color] }} />
                <Typography variant="caption" fontWeight={600} sx={{ color: who ? 'text.primary' : 'warning.main' }}>
                  {who || 'Assign driver'}
                </Typography>
                {leg.truck_number && (
                  <Typography variant="caption" color="text.secondary">
                    {leg.truck_number}
                  </Typography>
                )}
              </Box>
            </Tooltip>
            {i < list.length - 1 && (last?.type === 'yard' || last?.type === 'switch') && (
              <>
                <ChevronRight fontSize="small" sx={{ color: 'text.disabled' }} />
                <Tooltip title={[last.name, [last.city, last.state].filter(Boolean).join(', ')].filter(Boolean).join(' · ')}>
                  <Stack direction="row" alignItems="center" spacing={0.25} sx={{ color: 'warning.dark' }}>
                    {last.type === 'yard' ? <LocalParking sx={{ fontSize: 16 }} /> : <SwapHoriz sx={{ fontSize: 16 }} />}
                    <Typography variant="caption" fontWeight={600}>
                      {last.type === 'yard' ? 'Yard' : 'Meet'}
                    </Typography>
                  </Stack>
                </Tooltip>
              </>
            )}
          </React.Fragment>
        );
      })}
    </Stack>
  );
}
