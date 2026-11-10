'use client';

import * as React from 'react';
import { IconButton, Tooltip } from '@mui/material';
import { LocalShipping } from '@mui/icons-material';

import { useGetUserByIdQuery } from '@/redux/UserApiSlice';

import { LoadFormDialog } from './LoadFormDialog';

/** In a driver's chat: send this driver a load (it becomes a trip, see Loads). */
export function SendLoadButton({ driverId }: { driverId: string }): React.JSX.Element {
  const [open, setOpen] = React.useState(false);
  const { data } = useGetUserByIdQuery({ id: driverId }, { skip: !open || !driverId });
  const name = data?.data?.username || 'this driver';
  const driver = React.useMemo(() => ({ id: driverId, name }), [driverId, name]);
  return (
    <>
      <Tooltip title="Send load">
        <span>
          <IconButton disabled={!driverId} onClick={() => setOpen(true)}>
            <LocalShipping />
          </IconButton>
        </span>
      </Tooltip>
      <LoadFormDialog open={open} onClose={() => setOpen(false)} driver={driver} />
    </>
  );
}
