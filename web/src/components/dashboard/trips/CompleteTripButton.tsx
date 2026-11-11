'use client';

import * as React from 'react';
import { Button, Dialog, DialogActions, DialogContent, DialogTitle, TextField, Typography } from '@mui/material';
import { toast } from 'react-toastify';

import { Trip, useTripActionMutation } from '@/redux/TripApiSlice';

import { tripLabel } from './tripFormat';

// Dispatch's "Mark completed". A trip can't be completed without its invoice #: when the load was saved
// without one, this asks for it first (the server refuses too).

export function CompleteTripButton({
  trip,
  size,
  requireInvoice = true,
}: {
  trip: Trip;
  size?: 'small' | 'medium';
  /** The load's last leg needs the invoice #; a leg to the yard / meet point doesn't */
  requireInvoice?: boolean;
}): React.JSX.Element {
  const [tripAction, { isLoading }] = useTripActionMutation();
  const [asking, setAsking] = React.useState(false);
  const [invoice, setInvoice] = React.useState('');

  const complete = async (invoiceNo?: string) => {
    try {
      await tripAction({ id: trip.id, action: 'complete', ...(invoiceNo ? { invoiceNo } : {}) }).unwrap();
      setAsking(false);
      toast.success(`Trip ${tripLabel(trip)} completed — off the driver's app`);
    } catch (err: any) {
      toast.error(err?.data?.message || 'Could not complete');
    }
  };

  const start = () => {
    if (trip.invoice_no?.trim() || !requireInvoice) void complete();
    else {
      setInvoice('');
      setAsking(true);
    }
  };

  return (
    <>
      <Button size={size} variant="contained" color="success" disabled={isLoading} onClick={start} data-testid="markCompleted">
        Mark completed
      </Button>
      <Dialog open={asking} onClose={() => setAsking(false)} maxWidth="xs" fullWidth onClick={(e) => e.stopPropagation()}>
        <DialogTitle>Invoice # required</DialogTitle>
        <DialogContent>
          <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
            Trip {tripLabel(trip)} has no invoice number. Add it to mark the trip completed.
          </Typography>
          <TextField
            autoFocus
            fullWidth
            required
            size="small"
            label="Invoice #"
            placeholder="INV-10452"
            value={invoice}
            onChange={(e) => setInvoice(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === 'Enter' && invoice.trim()) void complete(invoice.trim());
            }}
            inputProps={{ maxLength: 64, 'data-testid': 'completeInvoiceInput' }}
          />
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setAsking(false)}>Cancel</Button>
          <Button variant="contained" color="success" disabled={!invoice.trim() || isLoading} onClick={() => void complete(invoice.trim())}>
            Save & mark completed
          </Button>
        </DialogActions>
      </Dialog>
    </>
  );
}
