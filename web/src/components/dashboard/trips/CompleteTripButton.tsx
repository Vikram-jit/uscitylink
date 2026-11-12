'use client';

import * as React from 'react';
import {
  Box,
  Button,
  Chip,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  Stack,
  TextField,
  Typography,
} from '@mui/material';
import { CheckCircle } from '@mui/icons-material';
import { toast } from 'react-toastify';

import { Trip, useTripActionMutation } from '@/redux/TripApiSlice';

import { tripLabel } from './tripFormat';

// Dispatch's "Mark completed". A load can't be completed without its invoice # (asked here when an
// older load has none). When more than one leg of the load is delivered, a dialog lists them: mark
// them one by one, or all at once.

const DELIVERED = ['ended', 'paperwork'];

const place = (s?: { name: string | null; city: string | null; state: string | null }) =>
  s ? [s.city, s.state].filter(Boolean).join(', ') || s.name || '—' : '—';

export function CompleteTripButton({
  trip,
  size,
  requireInvoice = true,
  legs,
  names = {},
}: {
  trip: Trip;
  size?: 'small' | 'medium';
  /** The load's last leg needs the invoice #; a leg to the yard / meet point doesn't */
  requireInvoice?: boolean;
  /** Every leg of the load: with more than one delivered, they're listed to complete together */
  legs?: Trip[];
  /** Driver names by profile id */
  names?: Record<string, string>;
}): React.JSX.Element {
  const [tripAction, { isLoading }] = useTripActionMutation();
  const [asking, setAsking] = React.useState(false);
  const [listing, setListing] = React.useState(false);
  const [invoice, setInvoice] = React.useState('');
  const [busyId, setBusyId] = React.useState<number | 'all' | null>(null);

  const live = (legs || []).filter((l) => l.status !== 'cancelled').sort((a, b) => a.leg_no - b.leg_no);
  const lastLegId = live[live.length - 1]?.id;
  const delivered = live.filter((l) => DELIVERED.includes(l.status));
  const hasInvoice = !!(trip.invoice_no?.trim() || live.some((l) => l.invoice_no?.trim()));
  /** The load's last leg is among the ones to complete and there's no invoice # yet */
  const needsInvoice = (ids: number[]) => !hasInvoice && ids.includes(lastLegId ?? trip.id) && (legs ? true : requireInvoice);

  const completeOne = async (leg: Trip, invoiceNo?: string) => {
    await tripAction({ id: leg.id, action: 'complete', ...(invoiceNo ? { invoiceNo } : {}) }).unwrap();
  };

  const complete = async (invoiceNo?: string) => {
    try {
      await completeOne(trip, invoiceNo);
      setAsking(false);
      toast.success(`Trip ${tripLabel(trip)} completed — off the driver's app`);
    } catch (err: any) {
      toast.error(err?.data?.message || 'Could not complete');
    }
  };

  /** From the list: one leg, or all of them (earlier legs first; the invoice goes with the last) */
  const completeLegs = async (toDo: Trip[], key: number | 'all') => {
    if (needsInvoice(toDo.map((l) => l.id)) && !invoice.trim()) {
      toast.error('Add the invoice # — the last leg needs it');
      return;
    }
    setBusyId(key);
    const done: string[] = [];
    try {
      for (const leg of [...toDo].sort((a, b) => a.leg_no - b.leg_no)) {
        await completeOne(leg, leg.id === lastLegId && invoice.trim() ? invoice.trim() : undefined);
        done.push(tripLabel(leg));
      }
      toast.success(`${done.join(', ')} completed`);
      if (key === 'all' || delivered.length - done.length <= 0) setListing(false);
    } catch (err: any) {
      toast.error(`${done.length ? `${done.join(', ')} completed. ` : ''}${err?.data?.message || 'Could not complete'}`);
    } finally {
      setBusyId(null);
    }
  };

  const start = () => {
    setInvoice('');
    if (delivered.length > 1) return setListing(true);
    if (hasInvoice || !requireInvoice) void complete();
    else setAsking(true);
  };

  const invoiceField = (
    <TextField
      fullWidth
      required
      size="small"
      label="Invoice #"
      placeholder="INV-10452"
      value={invoice}
      onChange={(e) => setInvoice(e.target.value)}
      inputProps={{ maxLength: 64, 'data-testid': 'completeInvoiceInput' }}
    />
  );

  return (
    <>
      <Button
        size={size}
        variant="contained"
        color="success"
        disabled={isLoading}
        onClick={(e) => {
          e.stopPropagation();
          start();
        }}
        data-testid="markCompleted"
      >
        {delivered.length > 1 ? `Mark completed (${delivered.length})` : 'Mark completed'}
      </Button>

      {/* One leg, no invoice # yet */}
      <Dialog open={asking} onClose={() => setAsking(false)} maxWidth="xs" fullWidth onClick={(e) => e.stopPropagation()}>
        <DialogTitle>Invoice # required</DialogTitle>
        <DialogContent>
          <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
            Trip {tripLabel(trip)} has no invoice number. Add it to mark the trip completed.
          </Typography>
          {invoiceField}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setAsking(false)}>Cancel</Button>
          <Button variant="contained" color="success" disabled={!invoice.trim() || isLoading} onClick={() => void complete(invoice.trim())}>
            Save & mark completed
          </Button>
        </DialogActions>
      </Dialog>

      {/* Several legs delivered: one by one, or all */}
      <Dialog open={listing} onClose={() => setListing(false)} maxWidth="sm" fullWidth onClick={(e) => e.stopPropagation()}>
        <DialogTitle>Mark completed — {delivered.length} legs delivered</DialogTitle>
        <DialogContent dividers>
          <Stack spacing={1.25} data-testid="completeLegsList">
            {delivered.map((leg) => {
              const stops = [...(leg.stops || [])].sort((a, b) => a.seq - b.seq);
              const who = leg.driver_profile_id ? names[leg.driver_profile_id] || 'Driver' : 'No driver';
              return (
                <Stack
                  key={leg.id}
                  direction="row"
                  spacing={1.5}
                  alignItems="center"
                  sx={{ p: 1.25, border: 1, borderColor: 'divider', borderRadius: 2 }}
                  data-testid={`completeLeg-${leg.leg_no}`}
                >
                  <Box sx={{ flexGrow: 1, minWidth: 0 }}>
                    <Stack direction="row" spacing={1} alignItems="center">
                      <Typography variant="subtitle2">
                        Leg {leg.leg_no} · #{leg.trip_no}
                      </Typography>
                      {leg.id === lastLegId && <Chip size="small" variant="outlined" label="Last leg" />}
                    </Stack>
                    <Typography variant="body2" noWrap>
                      {who}
                      {leg.truck_number ? ` · truck ${leg.truck_number}` : ''}
                    </Typography>
                    <Typography variant="caption" color="text.secondary" noWrap component="div">
                      {place(stops[0])} → {place(stops[stops.length - 1])}
                      {leg.total_mileage ? ` · ${Number(leg.total_mileage).toLocaleString()} mi` : ''}
                    </Typography>
                  </Box>
                  <Button
                    size="small"
                    variant="outlined"
                    color="success"
                    startIcon={<CheckCircle fontSize="small" />}
                    disabled={busyId !== null}
                    onClick={() => void completeLegs([leg], leg.id)}
                    data-testid={`completeOne-${leg.leg_no}`}
                  >
                    {busyId === leg.id ? 'Saving…' : 'Mark completed'}
                  </Button>
                </Stack>
              );
            })}
            {needsInvoice(delivered.map((l) => l.id)) && (
              <Box>
                <Typography variant="caption" color="text.secondary" component="div" sx={{ mb: 1 }}>
                  The last leg needs the load&apos;s invoice #:
                </Typography>
                {invoiceField}
              </Box>
            )}
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setListing(false)}>Close</Button>
          <Button variant="contained" color="success" disabled={busyId !== null} onClick={() => void completeLegs(delivered, 'all')} data-testid="completeAll">
            {busyId === 'all' ? 'Saving…' : `Mark all ${delivered.length} completed`}
          </Button>
        </DialogActions>
      </Dialog>
    </>
  );
}
