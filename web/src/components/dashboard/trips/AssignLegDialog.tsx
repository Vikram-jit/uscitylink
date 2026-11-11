'use client';

import * as React from 'react';
import { Alert, Button, Dialog, DialogActions, DialogContent, DialogTitle, Stack, Typography } from '@mui/material';
import { toast } from 'react-toastify';

import { Trip, useAssignLoadLegMutation } from '@/redux/TripApiSlice';

import { legBody, LegEditor, LegState, newLeg } from './LegEditor';

// Put a driver / truck / trailer on a leg — usually a load waiting in the yard or at a meet point.
// "Assign & send" sends it to the driver's chat right away when the leg before is delivered.

interface Props {
  open: boolean;
  onClose: () => void;
  loadId: number;
  leg: Trip | null;
  /** The leg before is delivered (or this is the first leg): it can go out now */
  canSend: boolean;
  driverName?: string | null;
  /** Picked on the equipment board: this truck / trailer / driver goes on the leg */
  prefill?: Partial<LegState> | null;
}

export function AssignLegDialog({ open, onClose, loadId, leg, canSend, driverName, prefill }: Props): React.JSX.Element {
  const [state, setState] = React.useState<LegState>(newLeg([]));
  const [assign, { isLoading }] = useAssignLoadLegMutation();

  React.useEffect(() => {
    if (!open || !leg) return;
    setState(
      newLeg([], {
        driver: leg.driver_profile_id ? { id: leg.driver_profile_id, name: driverName || 'Current driver' } : null,
        truck: leg.truck_number || '',
        trailers: leg.trailer_numbers ? leg.trailer_numbers.split(/,\s*/).filter(Boolean) : [],
        loaded: !!leg.loaded_trailer,
        ...(prefill || {}),
      })
    );
    // once per opening
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [open, leg?.id]);

  const save = async (send: boolean) => {
    if (!leg) return;
    if (!state.driver && !state.truck.trim()) {
      toast.error('Choose a driver or a truck');
      return;
    }
    const body = legBody(state);
    try {
      const res = await assign({
        id: loadId,
        legId: leg.id,
        driverProfileId: body.driverProfileId,
        truckNumber: body.truckNumber,
        teamDriverProfileId: body.teamDriverProfileId,
        trailerNumbers: body.trailerNumbers,
        send,
      }).unwrap();
      toast.success(res.message || 'Leg assigned');
      onClose();
    } catch (err: any) {
      toast.error(err?.data?.message || 'Could not assign the leg');
    }
  };

  return (
    <Dialog open={open} onClose={onClose} fullWidth maxWidth="md" onClick={(e) => e.stopPropagation()}>
      <DialogTitle>
        Assign leg {leg?.leg_no} · #{leg?.trip_no}
      </DialogTitle>
      <DialogContent dividers>
        <Stack spacing={2}>
          <Typography variant="body2" color="text.secondary">
            Pick who takes this leg. Free trucks, trailers in the yard and free drivers are marked; anything already on a load is flagged.
          </Typography>
          {!canSend && <Alert severity="info">The leg before isn&apos;t delivered yet — you can assign now; it&apos;s offered to the driver when the leg before is dropped.</Alert>}
          <LegEditor leg={state} onChange={(p) => setState((s) => ({ ...s, ...p }))} assignLater loadId={loadId} peopleOnly />
        </Stack>
      </DialogContent>
      <DialogActions>
        <Button onClick={onClose}>Cancel</Button>
        <Button variant={canSend ? 'outlined' : 'contained'} disabled={isLoading} onClick={() => void save(false)}>
          Assign
        </Button>
        {canSend && (
          <Button variant="contained" disabled={isLoading} onClick={() => void save(true)} data-testid="assignAndSend">
            Assign & send
          </Button>
        )}
      </DialogActions>
    </Dialog>
  );
}
