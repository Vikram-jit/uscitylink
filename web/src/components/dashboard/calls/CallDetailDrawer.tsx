'use client';

import * as React from 'react';
import { Alert, Box, Button, Chip, CircularProgress, Divider, Drawer, IconButton, Skeleton, Stack, Tooltip, Typography } from '@mui/material';
import { Clock, DownloadSimple, PhoneDisconnect, PhoneIncoming, PhoneOutgoing, Play, Queue, Record, ShareNetwork, UsersThree, X } from '@phosphor-icons/react';
import dayjs from 'dayjs';

import { CallDetail, CallParticipantLog, useGetCallQuery, useLazyGetCallRecordingQuery } from '@/redux/CallApiSlice';

const dur = (s?: number | null) => (s === null || s === undefined ? '—' : `${Math.floor(s / 60)}:${String(s % 60).padStart(2, '0')}`);

const REASON: Record<string, string> = {
  caller_hung_up: 'Caller hung up',
  callee_hung_up: 'Answerer hung up',
  caller_cancelled: 'Caller hung up before it was answered',
  no_answer: 'Nobody answered in time',
  declined: 'Declined',
  connection_lost: 'Connection lost',
  queue_timeout: 'Waited too long in line — every dispatcher stayed busy',
  no_dispatcher_online: 'No dispatcher was online',
  busy: 'Driver was on another call',
  unavailable: 'Nobody to ring',
};

const STATUS_LABEL: Record<string, string> = {
  completed: 'Answered',
  missed: 'Missed',
  cancelled: 'Missed (caller hung up)',
  declined: 'Declined',
  busy: 'Busy',
  failed: 'Failed',
  ringing: 'Ringing',
  ongoing: 'On call',
};

const OUTCOME: Record<string, { label: string; color: 'success' | 'warning' | 'error' | 'default' }> = {
  answered: { label: 'Answered', color: 'success' },
  declined: { label: 'Declined', color: 'warning' },
  missed: { label: 'Didn’t answer', color: 'error' },
  left: { label: 'Answered by someone else', color: 'default' },
  invited: { label: 'Rang', color: 'default' },
  joined: { label: 'Joined', color: 'success' },
  cancelled: { label: 'Request taken back', color: 'default' },
};

function Row({ label, value }: { label: string; value: React.ReactNode }): React.JSX.Element {
  return (
    <Stack direction="row" justifyContent="space-between" spacing={2} sx={{ py: 0.75 }}>
      <Typography color="text.secondary" variant="body2">
        {label}
      </Typography>
      <Typography sx={{ fontWeight: 500, textAlign: 'right', fontVariantNumeric: 'tabular-nums' }} variant="body2">
        {value}
      </Typography>
    </Stack>
  );
}

const fileSize = (b?: number | null) => (!b ? '—' : b > 1024 * 1024 ? `${(b / 1024 / 1024).toFixed(1)} MB` : `${Math.round(b / 1024)} KB`);

/** The call's recording: play it here or download it. Links are fetched on demand and expire after 15 min. */
function RecordingSection({ call }: { call: CallDetail }): React.JSX.Element | null {
  const [load, { data, isFetching, error }] = useLazyGetCallRecordingQuery();
  const r = call.recording;
  if (!r) {
    return call.status === 'completed' ? (
      <Typography color="text.secondary" variant="body2">
        This call wasn&apos;t recorded.
      </Typography>
    ) : null;
  }
  if (r.status === 'recording' || r.status === 'processing') {
    return (
      <Stack alignItems="center" direction="row" spacing={1}>
        <CircularProgress size={14} />
        <Typography color="text.secondary" variant="body2">
          {r.status === 'recording' ? 'Recording…' : 'Saving the recording…'}
        </Typography>
      </Stack>
    );
  }
  if (r.status === 'failed') {
    return <Alert severity="error">The recording failed{r.error ? `: ${r.error}` : ''}</Alert>;
  }
  const link = data?.data;
  return (
    <Stack spacing={1}>
      {r.error ? <Alert severity="warning">{r.error} — only the other voice is in the recording.</Alert> : null}
      {link?.video_url ? (
        // eslint-disable-next-line jsx-a11y/media-has-caption -- call video, no captions exist
        <video autoPlay controls playsInline src={link.video_url} style={{ width: '100%', borderRadius: 8, background: '#0B1F3A' }} />
      ) : link ? (
        // eslint-disable-next-line jsx-a11y/media-has-caption -- phone-call audio, no captions exist
        <audio autoPlay controls src={link.url} style={{ width: '100%' }} />
      ) : (
        <Button
          disabled={isFetching}
          onClick={() => void load(call.id)}
          startIcon={isFetching ? <CircularProgress size={14} /> : <Play weight="fill" />}
          variant="outlined"
        >
          {r.has_video ? 'Play video recording' : 'Play recording'}
        </Button>
      )}
      {error ? <Alert severity="error">{(error as any)?.data?.message || 'Could not open the recording'}</Alert> : null}
      <Row label="Length" value={dur(r.duration_sec)} />
      <Row label="Size" value={fileSize(r.size_bytes)} />
      {r.sha256 ? (
        <Row
          label="SHA-256"
          value={
            <Tooltip title={`${r.sha256} — fingerprint of the stored file: if anything in the recording changed, this would change`}>
              <span style={{ fontFamily: 'monospace' }}>{r.sha256.slice(0, 16)}…</span>
            </Tooltip>
          }
        />
      ) : null}
      {link ? (
        <Stack direction="row" spacing={1}>
          <Button component="a" download href={link.url} size="small" startIcon={<DownloadSimple />} target="_blank">
            {link.video_url ? 'Download audio' : 'Download'}
          </Button>
          {link.video_url ? (
            <Button component="a" download href={link.video_url} size="small" startIcon={<DownloadSimple />} target="_blank">
              Download video
            </Button>
          ) : null}
        </Stack>
      ) : null}
    </Stack>
  );
}

/** One call's full log: timeline, who it rang and what each dispatcher did, wait/talk times, quality. */
export function CallDetailDrawer({ callId, onClose }: { callId: string | null; onClose: () => void }): React.JSX.Element {
  const { data, isFetching } = useGetCallQuery(callId!, { skip: !callId });
  const c = data?.data;
  const rang = (c?.participants || []).filter((p) => p.role === 'callee');
  // Group call: people asked to join the answered call
  const added = (c?.participants || []).filter((p) => p.role === 'added');
  // Only devices that actually measured the connection (a call that never connected has none)
  const quality = (Object.values(c?.quality || {}) as any[]).filter((q) => q && (q.rttMs !== undefined || q.codec || q.localCandidate));

  return (
    <Drawer anchor="right" onClose={onClose} open={!!callId} PaperProps={{ sx: { width: { xs: '100%', sm: 440 } } }}>
      <Stack direction="row" alignItems="center" sx={{ px: 3, py: 2 }}>
        <Typography sx={{ flex: 1 }} variant="h6">
          Call details
        </Typography>
        <IconButton onClick={onClose}>
          <X />
        </IconButton>
      </Stack>
      <Divider />
      {!c || isFetching ? (
        <Stack spacing={1.5} sx={{ p: 3 }}>
          {[...Array(6)].map((_, i) => (
            <Skeleton height={24} key={i} />
          ))}
        </Stack>
      ) : (
        <Box sx={{ p: 3, overflowY: 'auto' }}>
          <Stack alignItems="center" direction="row" spacing={1.5} sx={{ mb: 2 }}>
            {c.direction === 'driver_to_dispatch' ? <PhoneIncoming size={22} /> : <PhoneOutgoing size={22} />}
            <Box>
              <Typography variant="subtitle1">{c.driver_name || 'Driver'}
                {c.driver_phone ? ` (${c.driver_phone})` : ''}
              </Typography>
              <Typography color="text.secondary" variant="body2">
                {c.direction === 'driver_to_dispatch' ? 'Called the dispatch line' : `${c.initiator_name || 'Dispatch'} called the driver`}
              </Typography>
            </Box>
          </Stack>

          <Row
            label="Status"
            value={
              <Chip
                color={c.status === 'completed' ? 'success' : ['missed', 'cancelled', 'failed'].includes(c.status) ? 'error' : 'warning'}
                label={STATUS_LABEL[c.status] || c.status}
                size="small"
              />
            }
          />
          <Row label="Answered by" value={c.answered_by_name || '—'} />
          <Row label="Started" value={dayjs(c.started_at).format('MMM D, YYYY h:mm:ss A')} />
          {c.queued_sec ? <Row label="Waited in line (all busy)" value={dur(c.queued_sec)} /> : null}
          <Row label="Time to answer" value={dur(c.wait_sec)} />
          <Row label="Talk time" value={dur(c.duration_sec)} />
          <Row label="Ended" value={c.ended_at ? dayjs(c.ended_at).format('h:mm:ss A') : '—'} />
          <Row label="How it ended" value={REASON[c.end_reason || ''] || c.end_reason || '—'} />

          {c.recording || c.status === 'completed' ? (
            <>
              <Divider sx={{ my: 2 }} />
              <Stack alignItems="center" direction="row" spacing={1} sx={{ mb: 1 }}>
                <Record color="var(--mui-palette-error-main)" size={18} weight="fill" />
                <Typography variant="subtitle2">Recording</Typography>
              </Stack>
              <RecordingSection call={c} />
            </>
          ) : null}

          <Divider sx={{ my: 2 }} />
          <Stack alignItems="center" direction="row" spacing={1} sx={{ mb: 1 }}>
            <Queue size={18} />
            <Typography variant="subtitle2">
              Rang {rang.length} {rang.length === 1 ? 'person' : 'people'}
            </Typography>
          </Stack>
          {rang.length ? (
            <Stack spacing={1}>
              {rang.map((p: CallParticipantLog) => {
                const o = OUTCOME[p.outcome] || { label: p.outcome, color: 'default' as const };
                return (
                  <Stack alignItems="center" direction="row" key={p.user_profile_id + p.invited_at} spacing={1.5}>
                    <Clock size={14} />
                    <Typography sx={{ minWidth: 70, fontVariantNumeric: 'tabular-nums' }} variant="caption">
                      {dayjs(p.invited_at).format('h:mm:ss A')}
                    </Typography>
                    <Typography sx={{ flex: 1 }} variant="body2">
                      {p.name || 'Unknown'}
                    </Typography>
                    <Chip color={o.color} label={o.label} size="small" variant={p.outcome === 'answered' ? 'filled' : 'outlined'} />
                  </Stack>
                );
              })}
            </Stack>
          ) : (
            <Typography color="text.secondary" variant="body2">
              {c.end_reason === 'no_dispatcher_online' ? 'No dispatcher was online to ring.' : 'Nobody was rung.'}
            </Typography>
          )}

          {added.length ? (
            <>
              <Divider sx={{ my: 2 }} />
              <Stack alignItems="center" direction="row" spacing={1} sx={{ mb: 1 }}>
                <UsersThree size={18} />
                <Typography variant="subtitle2">
                  {added.every((p) => p.join_type === 'transfer') ? 'Transferred' : 'Added to the call / transferred'}
                </Typography>
              </Stack>
              <Stack spacing={1}>
                {added.map((p: CallParticipantLog) => {
                  const o = OUTCOME[p.outcome] || { label: p.outcome, color: 'default' as const };
                  return (
                    <Stack alignItems="center" direction="row" key={p.user_profile_id + p.invited_at} spacing={1.5}>
                      <Clock size={14} />
                      <Typography sx={{ minWidth: 70, fontVariantNumeric: 'tabular-nums' }} variant="caption">
                        {dayjs(p.invited_at).format('h:mm:ss A')}
                      </Typography>
                      <Box sx={{ flex: 1, minWidth: 0 }}>
                        <Typography noWrap variant="body2">
                          {p.name || 'Unknown'}
                        </Typography>
                        <Typography color="text.secondary" noWrap variant="caption">
                          {p.join_type === 'transfer' ? 'Transferred by' : 'Added by'} {p.invited_by_name || 'staff'}
                          {p.joined_at ? ` · joined ${dayjs(p.joined_at).format('h:mm:ss A')}` : ''}
                          {p.joined_at && p.left_at ? ` · left ${dayjs(p.left_at).format('h:mm:ss A')}` : ''}
                        </Typography>
                      </Box>
                      <Chip color={o.color} label={o.label} size="small" variant={p.outcome === 'joined' ? 'filled' : 'outlined'} />
                    </Stack>
                  );
                })}
              </Stack>
            </>
          ) : null}

          {quality.length ? (
            <>
              <Divider sx={{ my: 2 }} />
              <Stack alignItems="center" direction="row" spacing={1} sx={{ mb: 1 }}>
                <ShareNetwork size={18} />
                <Typography variant="subtitle2">Connection</Typography>
              </Stack>
              {quality.map((q, i) => (
                <Box key={i} sx={{ mb: 1 }}>
                  <Row label="Device" value={q.platform || '—'} />
                  <Row label="Round trip" value={q.rttMs !== undefined ? `${q.rttMs} ms` : '—'} />
                  <Row label="Packet loss" value={q.packetLossPct !== undefined ? `${q.packetLossPct}%` : '—'} />
                  <Row label="Path" value={q.relay ? 'Relayed (TURN)' : q.localCandidate ? `Direct (${q.localCandidate})` : '—'} />
                  <Row label="Codec" value={q.codec || '—'} />
                </Box>
              ))}
            </>
          ) : null}

          {c.status === 'missed' && c.direction === 'driver_to_dispatch' ? (
            <Stack alignItems="center" direction="row" spacing={1} sx={{ mt: 2, color: 'error.main' }}>
              <PhoneDisconnect size={16} />
              <Typography variant="body2">The driver didn&apos;t reach anyone — call them back.</Typography>
            </Stack>
          ) : null}
        </Box>
      )}
    </Drawer>
  );
}
