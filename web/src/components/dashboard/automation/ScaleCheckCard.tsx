'use client';

import * as React from 'react';
import {
  Alert,
  Box,
  Button,
  Checkbox,
  Chip,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  FormControlLabel,
  MenuItem,
  Paper,
  Stack,
  TextField,
  Tooltip,
  Typography,
} from '@mui/material';
import { ArrowsClockwise, Info, MapTrifold, Scales, Wrench } from '@phosphor-icons/react';
import moment from 'moment';
import { toast } from 'react-toastify';

import { useDecideScaleCheckMutation, useRecheckScaleCheckMutation, useRecordScaleAdjustmentMutation } from '@/redux/AutomationApiSlice';
import type { ScaleAdjustment, ScaleCheck, ScaleGroup, ScaleStatus } from '@/redux/models/AutomationModel';

import { ROAD_LABELS, TripDialog } from './TripDialog';

const GROUPS: { key: ScaleGroup; label: string }[] = [
  { key: 'steer', label: 'Steer' },
  { key: 'drive', label: 'Drive' },
  { key: 'trailer', label: 'Trailer' },
  { key: 'gross', label: 'Gross' },
];

export const SCALE_STATUS: Record<ScaleStatus, { label: string; color: 'success' | 'warning' | 'error' | 'default' | 'info' }> = {
  PASS_PRELIMINARY: { label: 'Preliminary pass', color: 'success' },
  ROUTE_REVIEW_REQUIRED: { label: 'Route review', color: 'info' },
  BRIDGE_REVIEW: { label: 'Axle spacing review', color: 'info' },
  ADJUST_AND_REWEIGH: { label: 'Adjust & reweigh', color: 'warning' },
  OVER_GROSS: { label: 'Over gross', color: 'error' },
  OCR_UNCERTAIN: { label: 'Needs review', color: 'default' },
};

const MOVES: Record<ScaleAdjustment['action'], string> = {
  tandems_forward: 'Tandems forward (drives → trailer)',
  tandems_backward: 'Tandems backward (trailer → drives)',
  fifth_wheel_forward: 'Fifth wheel forward (drives → steer)',
  fifth_wheel_back: 'Fifth wheel back (steer → drives)',
  rework_cargo: 'No slide fix — rework the load',
};

const lb = (n?: number | null) => (n === null || n === undefined ? '—' : Math.round(n).toLocaleString('en-US'));

const moveText = (a: ScaleAdjustment) => {
  if (a.reason === 'kpra') return `Tandems forward to meet the KPRA limit${a.holes ? ` (~${a.holes} hole${a.holes === 1 ? '' : 's'})` : ''}`;
  return `${MOVES[a.action]}${a.holes ? ` · ~${a.holes} hole${a.holes === 1 ? '' : 's'}` : ''}${a.kpra_after_ft ? ` · KPRA after ${a.kpra_after_ft} ft` : ''}`;
};

export function ApprovalChip({ check }: { check: ScaleCheck }): React.JSX.Element | null {
  switch (check.approval_status) {
    case 'pending':
      return <Chip color="info" label="Waiting for dispatch" size="small" />;
    case 'approved':
      return (
        <Tooltip title={check.approval_note || ''}>
          <Chip
            color="success"
            label={`Released by ${check.approved_by_name || 'staff'} ${check.approved_at ? moment(check.approved_at).format('h:mm A') : ''}`}
            size="small"
            variant="outlined"
          />
        </Tooltip>
      );
    case 'rejected':
      return (
        <Tooltip title={check.approval_note || ''}>
          <Chip color="error" label={`Not released by ${check.approved_by_name || 'staff'}`} size="small" variant="outlined" />
        </Tooltip>
      );
    case 'superseded':
      return <Chip label="Replaced by reweigh" size="small" variant="outlined" />;
    default:
      return null;
  }
}

function AdjustmentDialog({ check, onClose }: { check: ScaleCheck; onClose: () => void }): React.JSX.Element {
  const [record, { isLoading }] = useRecordScaleAdjustmentMutation();
  const suggested = (check.feasible_adjustments || []).find((a) => a.action !== 'rework_cargo');
  const [action, setAction] = React.useState<string>(suggested?.action || 'tandems_forward');
  const [holes, setHoles] = React.useState<string>(suggested?.holes ? String(suggested.holes) : '');
  const [parked, setParked] = React.useState(false);
  const submit = async () => {
    try {
      const res = await record({
        id: check.id,
        messageId: check.message_id,
        action,
        holes: holes === '' ? null : Number(holes),
        parked_confirmed: parked,
      }).unwrap();
      toast.success(res.message || 'Recorded');
      onClose();
    } catch (err: any) {
      toast.error(err?.data?.message || 'Could not record the adjustment');
    }
  };
  return (
    <Dialog fullWidth maxWidth="xs" onClose={onClose} open>
      <DialogTitle>What did the driver adjust?</DialogTitle>
      <DialogContent>
        <Stack spacing={2} sx={{ mt: 1 }}>
          <TextField label="Adjustment" onChange={(e) => setAction(e.target.value)} select size="small" value={action}>
            {Object.entries(MOVES).map(([k, v]) => (
              <MenuItem key={k} value={k}>
                {v}
              </MenuItem>
            ))}
          </TextField>
          {action.startsWith('tandems') ? (
            <TextField
              helperText="Used to learn this trailer's weight shift per hole"
              label="Holes moved"
              onChange={(e) => setHoles(e.target.value)}
              size="small"
              type="number"
              value={holes}
            />
          ) : null}
          <FormControlLabel
            control={<Checkbox checked={parked} onChange={(e) => setParked(e.target.checked)} />}
            label="Driver confirmed they were parked and the vehicle was secured"
          />
          <Typography color="text.secondary" variant="body2">
            The next ticket from this driver is compared with this adjustment.
          </Typography>
        </Stack>
      </DialogContent>
      <DialogActions>
        <Button onClick={onClose}>Cancel</Button>
        <Button disabled={!parked || isLoading} onClick={() => void submit()} variant="contained">
          Record
        </Button>
      </DialogActions>
    </Dialog>
  );
}

// The scale agent's result under a scale ticket in chat; dispatch releases or rejects it here
export function ScaleCheckCard({ check }: { check: ScaleCheck }): React.JSX.Element {
  const [decide, { isLoading }] = useDecideScaleCheckMutation();
  const [recheck, { isLoading: rechecking }] = useRecheckScaleCheckMutation();
  const [dialog, setDialog] = React.useState<'reject' | 'release' | 'adjust' | 'route' | null>(null);
  const [note, setNote] = React.useState('');
  const status = SCALE_STATUS[check.status] || SCALE_STATUS.OCR_UNCERTAIN;
  const weights = check.measured_weights || {};
  const rules = check.controlling_rules;
  const moves = (check.feasible_adjustments || []).map(moveText);
  const bridgeOver = (check.bridge_results || []).filter((g) => g.over_lb > 0);
  const needsNote = check.status !== 'PASS_PRELIMINARY';

  const submit = async (decision: 'approve' | 'reject') => {
    try {
      const res = await decide({ id: check.id, messageId: check.message_id, decision, note: note.trim() || undefined }).unwrap();
      toast.success(res.message || 'Saved');
      setDialog(null);
      setNote('');
    } catch (err: any) {
      toast.error(err?.data?.message || 'Could not save the decision');
    }
  };

  const routeText = rules?.route_known
    ? rules.segments.map((s) => `${s.state} ${ROAD_LABELS[s.road_class as keyof typeof ROAD_LABELS] || s.road_class}${s.permit ? ' (permit)' : ''}`).join(' → ')
    : 'Not entered';

  return (
    <Paper sx={{ mt: 0.75, p: 1.25, maxWidth: 460, borderRadius: 2 }} variant="outlined">
      <Stack spacing={1}>
        <Stack alignItems="center" direction="row" flexWrap="wrap" gap={0.75}>
          <Scales size={18} />
          <Typography sx={{ fontWeight: 600 }} variant="body2">
            Scale check
          </Typography>
          <Chip color={status.color} label={status.label} size="small" />
          <ApprovalChip check={check} />
          {check.previous_check_id ? <Chip label="Reweigh" size="small" variant="outlined" /> : null}
        </Stack>

        <Box
          component="table"
          sx={{ borderCollapse: 'collapse', fontSize: 13, '& td': { py: 0.25, pr: 1.5 }, '& td:first-of-type': { color: 'text.secondary' } }}
        >
          <tbody>
            {GROUPS.map(({ key, label }) => {
              const over = check.group_overages_lb?.[key];
              const room = check.headroom_lb?.[key];
              return (
                <tr key={key}>
                  <td>{label}</td>
                  <td style={{ fontVariantNumeric: 'tabular-nums', fontWeight: 600 }}>{lb(weights[key])} lb</td>
                  <td>
                    {over ? (
                      <Typography color="error" component="span" sx={{ fontSize: 12, fontWeight: 600 }}>
                        +{lb(over)} over
                      </Typography>
                    ) : room !== undefined ? (
                      <Typography color="text.secondary" component="span" sx={{ fontSize: 12 }}>
                        {lb(room)} room
                      </Typography>
                    ) : null}
                  </td>
                </tr>
              );
            })}
          </tbody>
        </Box>

        {/* Route, equipment, bridge and KPRA: what was verified */}
        <Stack spacing={0.25} sx={{ fontSize: 12, color: 'text.secondary' }}>
          <Stack alignItems="center" direction="row" gap={0.5}>
            <Typography sx={{ fontSize: 12 }}>
              Route: <b>{routeText}</b>
            </Typography>
            <Button onClick={() => setDialog('route')} size="small" startIcon={<MapTrifold size={14} />} sx={{ py: 0, minHeight: 0, fontSize: 12 }}>
              {rules?.route_known ? 'Edit' : 'Set route'}
            </Button>
          </Stack>
          {rules?.missing?.length ? <Typography color="warning.main" sx={{ fontSize: 12 }}>No rules on file for {rules.missing.join(', ')}</Typography> : null}
          {rules?.unverified?.length ? <Typography color="warning.main" sx={{ fontSize: 12 }}>Rules not reviewed: {rules.unverified.join(', ')}</Typography> : null}
          <Typography sx={{ fontSize: 12 }}>
            Tractor {check.tractor_unit || '—'} · Trailer {check.trailer_unit || '—'}
            {rules?.equipment_missing?.length ? ` · missing: ${rules.equipment_missing.slice(0, 3).join(', ')}` : ''}
          </Typography>
          <Typography sx={{ fontSize: 12 }}>
            Bridge formula:{' '}
            {check.bridge_results?.length
              ? bridgeOver.length
                ? <Box component="b" sx={{ color: 'error.main' }}>{bridgeOver.map((g) => `axles ${g.axles} +${lb(g.over_lb)}`).join(', ')}</Box>
                : <b>all {check.bridge_results.length} groups within</b>
              : 'not checked (axle spacing unknown)'}
            {' · '}KPRA:{' '}
            {check.kpra?.over_ft
              ? <Box component="b" sx={{ color: 'error.main' }}>{check.kpra.kpra_ft} ft, {check.kpra.over_ft} ft over {check.kpra.max_ft}</Box>
              : check.kpra?.max_ft
                ? check.kpra.kpra_ft !== null ? <b>{check.kpra.kpra_ft} / {check.kpra.max_ft} ft</b> : 'not verified'
                : check.kpra?.verified ? 'no limit on route' : 'not verified'}
          </Typography>
        </Stack>

        {moves.length ? (
          <Stack spacing={0.25}>
            <Typography color="text.secondary" variant="caption">
              Suggested (estimate — reweigh required)
            </Typography>
            {moves.map((m) => (
              <Typography key={m} sx={{ fontSize: 13 }}>
                • {m}
              </Typography>
            ))}
          </Stack>
        ) : null}

        {check.adjustment_made ? (
          <Typography sx={{ fontSize: 12 }}>
            Adjusted: <b>{MOVES[check.adjustment_made.action as ScaleAdjustment['action']] || check.adjustment_made.action}</b>
            {check.adjustment_made.holes ? `, ${check.adjustment_made.holes} hole(s)` : ''} · parked & secured confirmed
          </Typography>
        ) : null}
        {check.prediction ? (
          <Alert severity={check.prediction.mismatch ? 'warning' : 'success'} sx={{ py: 0, fontSize: 12 }}>
            Reweigh vs. adjustment: {check.prediction.note}
            {check.prediction.learned_lb_per_hole ? ` Learned ~${lb(check.prediction.learned_lb_per_hole)} lb/hole.` : ''}
          </Alert>
        ) : null}
        {check.status === 'OCR_UNCERTAIN' ? (
          <Typography color="text.secondary" sx={{ fontSize: 12 }}>
            Correct the weights on the document chip to re-check, or ask the driver for a clearer photo.
          </Typography>
        ) : null}

        <Stack alignItems="center" direction="row" flexWrap="wrap" gap={0.5}>
          <Tooltip
            title={
              <Stack spacing={0.25}>
                {(check.assumptions || []).map((a) => (
                  <Typography key={a} variant="caption">
                    • {a}
                  </Typography>
                ))}
                <Typography variant="caption">Rules: {check.rule_set_version}</Typography>
              </Stack>
            }
          >
            <Box sx={{ color: 'text.secondary', cursor: 'help', display: 'flex' }}>
              <Info size={16} />
            </Box>
          </Tooltip>
          <Button disabled={rechecking} onClick={() => void recheck({ id: check.id, messageId: check.message_id })} size="small" startIcon={<ArrowsClockwise size={14} />}>
            Re-check
          </Button>
          {check.status === 'ADJUST_AND_REWEIGH' && !check.adjustment_made ? (
            <Button onClick={() => setDialog('adjust')} size="small" startIcon={<Wrench size={14} />}>
              Record adjustment
            </Button>
          ) : null}
          <Box sx={{ flex: 1 }} />
          {check.approval_status === 'pending' ? (
            <>
              <Button color="inherit" disabled={isLoading} onClick={() => setDialog('reject')} size="small">
                Reject
              </Button>
              <Button
                color="success"
                disabled={isLoading}
                onClick={() => (needsNote ? setDialog('release') : void submit('approve'))}
                size="small"
                variant="contained"
              >
                Release
              </Button>
            </>
          ) : null}
        </Stack>
      </Stack>

      <Dialog fullWidth maxWidth="xs" onClose={() => setDialog(null)} open={dialog === 'reject' || dialog === 'release'}>
        <DialogTitle>{dialog === 'release' ? 'Release without full verification' : "Don't release this load"}</DialogTitle>
        <DialogContent>
          {dialog === 'release' ? (
            <Alert severity="warning" sx={{ mb: 1 }}>
              The weights are within limits, but {check.status === 'ROUTE_REVIEW_REQUIRED' ? 'the route or its state rules' : 'the axle spacing / trailer position'} could
              not be verified. Note what you checked; it is kept with your name.
            </Alert>
          ) : null}
          <TextField
            autoFocus
            fullWidth
            label={dialog === 'release' ? 'What did you check?' : 'Note for the driver'}
            minRows={3}
            multiline
            onChange={(e) => setNote(e.target.value)}
            placeholder={dialog === 'release' ? 'e.g. Route is I-10 only, confirmed with the driver.' : 'e.g. Trailer position needs checking — call dispatch before you move.'}
            sx={{ mt: 1 }}
            value={note}
          />
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDialog(null)}>Cancel</Button>
          <Button
            color={dialog === 'release' ? 'success' : 'error'}
            disabled={!note.trim() || isLoading}
            onClick={() => void submit(dialog === 'release' ? 'approve' : 'reject')}
            variant="contained"
          >
            {dialog === 'release' ? 'Release' : 'Send to driver'}
          </Button>
        </DialogActions>
      </Dialog>
      {dialog === 'adjust' ? <AdjustmentDialog check={check} onClose={() => setDialog(null)} /> : null}
      {dialog === 'route' && check.driver_id ? (
        <TripDialog
          defaults={{ truck: check.tractor_unit || undefined, trailer: check.trailer_unit || undefined }}
          driverId={check.driver_id}
          driverName={check.driver_name}
          onClose={() => setDialog(null)}
        />
      ) : null}
    </Paper>
  );
}
