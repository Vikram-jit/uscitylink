'use client';

import * as React from 'react';
import { IconButton, Tooltip } from '@mui/material';
import { LocalShipping } from '@mui/icons-material';

import { useGetTruckAssignmentsQuery } from '@/redux/TripApiSlice';
import { useGetUserByIdQuery } from '@/redux/UserApiSlice';

import { LoadFormDialog } from './LoadFormDialog';

/** The driver (and team mate) on a truck — a truck chat's group is named by its truck number. */
export function useTruckDrivers(truck?: string | null) {
  const name = (truck || '').trim();
  const { data, isFetching } = useGetTruckAssignmentsQuery(name, { skip: !name });
  const exact = (data?.data || []).find((a) => a.truck.trim().toLowerCase() === name.toLowerCase()) || null;
  return { drivers: exact?.drivers || [], loading: isFetching };
}

/**
 * Send this driver a load (it becomes a trip, see Loads). In a driver's chat: that driver (their truck
 * and team mate fill in). In a truck's chat: the truck's driver, the truck and the team mate.
 */
export function SendLoadButton({ driverId, truck }: { driverId?: string | null; truck?: string | null }): React.JSX.Element {
  const [open, setOpen] = React.useState(false);
  const { drivers } = useTruckDrivers(driverId ? null : truck);
  const id = driverId || drivers[0]?.id || '';
  const { data } = useGetUserByIdQuery({ id }, { skip: !open || !driverId });
  const name = driverId ? data?.data?.username || 'this driver' : drivers[0]?.name || '';
  const driver = React.useMemo(() => (id ? { id, name } : null), [id, name]);
  const can = !!driverId || !!truck;
  return (
    <>
      <Tooltip title={truck && !driverId ? `Send load · Truck ${truck}` : 'Send load'}>
        <span>
          <IconButton disabled={!can} onClick={() => setOpen(true)} data-testid="sendLoadButton">
            <LocalShipping />
          </IconButton>
        </span>
      </Tooltip>
      <LoadFormDialog open={open} onClose={() => setOpen(false)} driver={driver} truck={driverId ? null : truck} />
    </>
  );
}
