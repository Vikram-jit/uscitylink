'use client';

import * as React from 'react';
import { Switch, Tooltip } from '@mui/material';
import { toast } from 'react-toastify';

import { useSetDriverCallingMutation } from '@/redux/CallApiSlice';

/**
 * Drivers table: calling on / off for one driver. Off by default. A driver sees the call buttons in the
 * app and may call dispatch only while it is on; staff can always call any driver, whatever this says.
 * Shown at once, put back if the server says no.
 */
export function CallingSwitch({ profileId, enabled, name }: { profileId: string; enabled: boolean; name?: string }): React.JSX.Element {
  const [on, setOn] = React.useState(enabled);
  const [save, { isLoading }] = useSetDriverCallingMutation();
  // The list was refreshed (another staff member changed it): follow it
  React.useEffect(() => setOn(enabled), [enabled]);

  const change = async (next: boolean) => {
    setOn(next);
    try {
      const res = await save({ profileId, enabled: next }).unwrap();
      toast.success(`${name || 'Driver'} ${next ? 'can now call dispatch' : "can't call dispatch any more"}${next && !res.data.effective ? ' (calling is turned off for everyone in Settings)' : ''}`);
    } catch (err: any) {
      setOn(!next);
      toast.error(err?.data?.message || 'Could not change calling for this driver');
    }
  };

  return (
    <Tooltip title="Lets this driver call dispatch from the app. Staff can always call drivers.">
      <span>
        <Switch size="small" checked={on} disabled={isLoading} onChange={(_, v) => void change(v)} inputProps={{ 'aria-label': `Calling for ${name || 'driver'}`, 'data-testid': `callingSwitch_${profileId}` } as any} />
      </span>
    </Tooltip>
  );
}
