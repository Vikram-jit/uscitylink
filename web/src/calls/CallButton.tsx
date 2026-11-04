'use client';

import * as React from 'react';
import { IconButton, Tooltip } from '@mui/material';
import { Phone, VideoCamera } from '@phosphor-icons/react';

import { useGetCallConfigQuery } from '@/redux/CallApiSlice';

import { useCall } from './CallProvider';

/** "Call" / "Video call" in the driver chat header. Hidden when an admin has switched calling off. */
export function CallButton({
  driver,
  video = false,
}: {
  driver?: { id: string; username?: string | null } | null;
  /** Start with the camera on (either side can turn cameras on/off during any call). */
  video?: boolean;
}): React.JSX.Element | null {
  const call = useCall();
  const { data } = useGetCallConfigQuery();
  if (!driver?.id || data?.data?.enabled === false) return null;

  const busy = call.phase !== 'idle' && call.phase !== 'ended';
  const onThisCall = busy && call.peer?.id === driver.id;
  return (
    <Tooltip title={onThisCall ? 'On a call with this driver' : busy ? 'Finish the current call first' : video ? 'Video call' : 'Voice call'}>
      <span>
        <IconButton
          aria-label={`${video ? 'Video call' : 'Call'} ${driver.username || 'driver'}`}
          color={onThisCall ? 'success' : 'default'}
          disabled={busy}
          onClick={() => void call.startCall({ id: driver.id, name: driver.username || 'Driver' }, { video })}
          size="small"
        >
          {video ? (
            <VideoCamera size={20} weight={onThisCall ? 'fill' : 'regular'} />
          ) : (
            <Phone size={20} weight={onThisCall ? 'fill' : 'regular'} />
          )}
        </IconButton>
      </span>
    </Tooltip>
  );
}
