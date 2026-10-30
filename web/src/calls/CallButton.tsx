'use client';

import * as React from 'react';
import { IconButton, Tooltip } from '@mui/material';
import { Phone } from '@phosphor-icons/react';

import { useGetCallConfigQuery } from '@/redux/CallApiSlice';

import { useCall } from './CallProvider';

/** "Call" in the driver chat header. Hidden when an admin has switched calling off. */
export function CallButton({ driver }: { driver?: { id: string; username?: string | null } | null }): React.JSX.Element | null {
  const call = useCall();
  const { data } = useGetCallConfigQuery();
  if (!driver?.id || data?.data?.enabled === false) return null;

  const busy = call.phase !== 'idle' && call.phase !== 'ended';
  const onThisCall = busy && call.peer?.id === driver.id;
  return (
    <Tooltip title={onThisCall ? 'On a call with this driver' : busy ? 'Finish the current call first' : 'Voice call'}>
      <span>
        <IconButton
          aria-label={`Call ${driver.username || 'driver'}`}
          color={onThisCall ? 'success' : 'default'}
          disabled={busy}
          onClick={() => void call.startCall({ id: driver.id, name: driver.username || 'Driver' })}
          size="small"
        >
          <Phone size={20} weight={onThisCall ? 'fill' : 'regular'} />
        </IconButton>
      </span>
    </Tooltip>
  );
}
