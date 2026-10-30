'use client';

import * as React from 'react';
import {
  Alert,
  Box,
  Card,
  Chip,
  Divider,
  FormControlLabel,
  IconButton,
  Stack,
  Switch,
  Tab,
  Table,
  TableBody,
  TableCell,
  TableHead,
  TablePagination,
  TableRow,
  Tabs,
  Tooltip,
  Typography,
} from '@mui/material';
import { ArrowsClockwise, Phone, PhoneIncoming, PhoneOutgoing, PhoneX, ShareNetwork } from '@phosphor-icons/react';
import dayjs from 'dayjs';
import { toast } from 'react-toastify';

import { useCall } from '@/calls/CallProvider';
import { CallDetailDrawer } from './CallDetailDrawer';
import { useAutomationAccess } from '@/components/dashboard/automation/AdminGuard';
import { CallRecord, useGetCallConfigQuery, useGetCallsQuery, useUpdateCallSettingsMutation } from '@/redux/CallApiSlice';

const STATUS: Record<string, { label: string; color: 'success' | 'error' | 'warning' | 'default' }> = {
  completed: { label: 'Answered', color: 'success' },
  missed: { label: 'Missed', color: 'error' },
  cancelled: { label: 'Missed', color: 'error' },
  declined: { label: 'Declined', color: 'warning' },
  busy: { label: 'Busy', color: 'warning' },
  failed: { label: 'Failed', color: 'error' },
  ringing: { label: 'Ringing', color: 'default' },
  ongoing: { label: 'On call', color: 'success' },
};

const FILTERS: Record<string, string | undefined> = {
  all: undefined,
  missed: 'missed,cancelled,declined,busy',
  answered: 'completed',
};

const duration = (s: number) => (s ? `${Math.floor(s / 60)}:${String(s % 60).padStart(2, '0')}` : '—');

function Quality({ call }: { call: CallRecord }): React.JSX.Element | null {
  const entries = Object.values(call.quality || {}) as any[];
  if (!entries.length) return null;
  const relay = entries.some((q) => q.relay);
  const loss = Math.max(...entries.map((q) => Number(q.packetLossPct) || 0));
  const rtt = Math.max(...entries.map((q) => Number(q.rttMs) || 0));
  const poor = loss > 5 || rtt > 400;
  return (
    <Tooltip title={`Round trip ${rtt || '—'} ms · packet loss ${loss}%${relay ? ' · relayed through TURN' : ' · direct'}`}>
      <Chip
        color={poor ? 'warning' : 'default'}
        icon={relay ? <ShareNetwork size={14} /> : undefined}
        label={poor ? 'Poor' : 'Good'}
        size="small"
        variant="outlined"
      />
    </Tooltip>
  );
}

export function CallHistory(): React.JSX.Element {
  const [filter, setFilter] = React.useState<keyof typeof FILTERS>('all');
  const [page, setPage] = React.useState(0);
  const [pageSize, setPageSize] = React.useState(20);
  const [openId, setOpenId] = React.useState<string | null>(null);
  const { data, isFetching, refetch } = useGetCallsQuery({ status: FILTERS[filter], page: page + 1, pageSize });
  const { data: config } = useGetCallConfigQuery();
  const [updateSettings, { isLoading: saving }] = useUpdateCallSettingsMutation();
  const { isAdmin } = useAutomationAccess();
  const call = useCall();
  const calls = data?.data?.calls || [];
  const enabled = config?.data?.enabled !== false;

  React.useEffect(() => setPage(0), [filter]);

  return (
    <Stack spacing={3}>
      {!enabled ? <Alert severity="warning">Calling is switched off. The call buttons are hidden for everyone.</Alert> : null}
      {enabled && config?.data && !config.data.relay ? (
        <Alert severity="info">
          No TURN server is configured, so some calls to drivers on mobile data may connect without audio. See
          server/docs/calls/README.md.
        </Alert>
      ) : null}
      <Card>
        <Stack alignItems="center" direction="row" flexWrap="wrap" gap={2} sx={{ px: 2, pt: 1 }}>
          <Tabs onChange={(_e, v) => setFilter(v)} value={filter}>
            <Tab label="All" value="all" />
            <Tab label="Missed" value="missed" />
            <Tab label="Answered" value="answered" />
          </Tabs>
          <Box sx={{ flex: 1 }} />
          {isAdmin ? (
            <FormControlLabel
              control={
                <Switch
                  checked={enabled}
                  disabled={saving}
                  onChange={async (e) => {
                    try {
                      const res = await updateSettings({ enabled: e.target.checked }).unwrap();
                      toast.success(res.message || 'Saved');
                    } catch (err: any) {
                      toast.error(err?.data?.message || 'Could not save');
                    }
                  }}
                />
              }
              label="Calling on"
            />
          ) : null}
          <Tooltip title="Refresh">
            <IconButton onClick={() => void refetch()}>
              <ArrowsClockwise />
            </IconButton>
          </Tooltip>
        </Stack>
        <Divider />
        <Box sx={{ overflowX: 'auto', opacity: isFetching ? 0.6 : 1 }}>
          <Table size="small" sx={{ minWidth: 1000 }}>
            <TableHead>
              <TableRow>
                <TableCell>Driver</TableCell>
                <TableCell>Direction</TableCell>
                <TableCell>Status</TableCell>
                <TableCell>Answered by</TableCell>
                <TableCell align="right">Rang</TableCell>
                <TableCell align="right">Wait</TableCell>
                <TableCell align="right">Duration</TableCell>
                <TableCell>When</TableCell>
                <TableCell>Quality</TableCell>
                <TableCell />
              </TableRow>
            </TableHead>
            <TableBody>
              {calls.map((c) => {
                const missed = ['missed', 'cancelled', 'declined', 'busy', 'failed'].includes(c.status);
                const out = c.direction === 'dispatch_to_driver';
                const Icon = missed ? PhoneX : out ? PhoneOutgoing : PhoneIncoming;
                const st = STATUS[c.status] || { label: c.status, color: 'default' as const };
                return (
                  <TableRow hover key={c.id} onClick={() => setOpenId(c.id)} sx={{ cursor: 'pointer' }}>
                    <TableCell sx={{ fontWeight: 600, whiteSpace: 'nowrap' }}>{c.driver_name || '—'}</TableCell>
                    <TableCell>
                      <Stack alignItems="center" direction="row" spacing={1} sx={{ whiteSpace: 'nowrap' }}>
                        <Icon color={missed ? 'var(--mui-palette-error-main)' : undefined} size={16} />
                        <span>{out ? `${c.initiator_name || 'Dispatch'} → driver` : 'Dispatch line'}</span>
                      </Stack>
                    </TableCell>
                    <TableCell>
                      <Chip color={st.color} label={st.label} size="small" variant={missed ? 'outlined' : 'filled'} />
                    </TableCell>
                    <TableCell sx={{ whiteSpace: 'nowrap' }}>{c.answered_by_name || '—'}</TableCell>
                    <TableCell align="right">{c.rang_count ?? '—'}</TableCell>
                    <TableCell align="right" sx={{ fontVariantNumeric: 'tabular-nums' }}>
                      <Tooltip title={c.queued_sec ? `Waited ${duration(c.queued_sec)} in line — every dispatcher was busy` : 'Time until answered'}>
                        <span style={{ color: c.queued_sec ? 'var(--mui-palette-warning-main)' : undefined }}>
                          {c.wait_sec === null || c.wait_sec === undefined ? '—' : c.wait_sec === 0 ? '0:00' : duration(c.wait_sec)}
                        </span>
                      </Tooltip>
                    </TableCell>
                    <TableCell align="right" sx={{ fontVariantNumeric: 'tabular-nums' }}>
                      {duration(c.duration_sec)}
                    </TableCell>
                    <TableCell sx={{ whiteSpace: 'nowrap' }}>
                      <Tooltip title={dayjs(c.started_at).format('MMM D, YYYY h:mm:ss A')}>
                        <span>{dayjs(c.started_at).format('MMM D, h:mm A')}</span>
                      </Tooltip>
                    </TableCell>
                    <TableCell>
                      <Quality call={c} />
                    </TableCell>
                    <TableCell align="right">
                      {enabled ? (
                        <Tooltip title="Call back">
                          <span>
                            <IconButton
                              disabled={call.phase !== 'idle' && call.phase !== 'ended'}
                              onClick={(e) => {
                                e.stopPropagation();
                                void call.startCall({ id: c.driver_id, name: c.driver_name || 'Driver' });
                              }}
                              size="small"
                            >
                              <Phone size={18} />
                            </IconButton>
                          </span>
                        </Tooltip>
                      ) : null}
                    </TableCell>
                  </TableRow>
                );
              })}
              {!calls.length ? (
                <TableRow>
                  <TableCell colSpan={10}>
                    <Typography color="text.secondary" sx={{ py: 4, textAlign: 'center' }}>
                      {isFetching ? 'Loading…' : 'No calls yet. Use the phone button in a driver chat to call.'}
                    </Typography>
                  </TableCell>
                </TableRow>
              ) : null}
            </TableBody>
          </Table>
        </Box>
        <TablePagination
          component="div"
          count={data?.data?.total || 0}
          onPageChange={(_e, p) => setPage(p)}
          onRowsPerPageChange={(e) => {
            setPageSize(Number(e.target.value));
            setPage(0);
          }}
          page={page}
          rowsPerPage={pageSize}
          rowsPerPageOptions={[20, 50, 100]}
        />
      </Card>
      <CallDetailDrawer callId={openId} onClose={() => setOpenId(null)} />
    </Stack>
  );
}
