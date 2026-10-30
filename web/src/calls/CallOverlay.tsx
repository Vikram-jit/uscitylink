'use client';

import * as React from 'react';
import {
  Avatar,
  Box,
  Button,
  Fade,
  IconButton,
  ListItemIcon,
  ListItemText,
  Menu,
  MenuItem,
  Paper,
  Stack,
  Tooltip,
  Typography,
} from '@mui/material';
import {
  CaretDown,
  CaretUp,
  Check,
  Microphone,
  MicrophoneSlash,
  Phone,
  PhoneDisconnect,
  PhoneIncoming,
  WifiSlash,
} from '@phosphor-icons/react';

import { formatCallDuration, useCall } from './CallProvider';

const initials = (name?: string) =>
  (name || '?')
    .split(/\s+/)
    .filter(Boolean)
    .slice(0, 2)
    .map((p) => p[0]?.toUpperCase())
    .join('');

function useTimer(from: number | null, running: boolean) {
  const [now, setNow] = React.useState(Date.now());
  React.useEffect(() => {
    if (!running) return undefined;
    const t = setInterval(() => setNow(Date.now()), 1000);
    return () => clearInterval(t);
  }, [running]);
  return from ? Math.max(0, Math.floor((now - from) / 1000)) : 0;
}

const CARD = {
  position: 'fixed' as const,
  right: { xs: 12, sm: 24 },
  zIndex: 1400,
  width: { xs: 'calc(100vw - 24px)', sm: 340 },
  borderRadius: 3,
  overflow: 'hidden',
};

function IncomingCard(): React.JSX.Element {
  const call = useCall();
  return (
    <Paper elevation={12} role="alertdialog" aria-label="Incoming call" sx={{ ...CARD, top: { xs: 12, sm: 80 } }}>
      <Box sx={{ px: 2.5, py: 2, bgcolor: 'primary.main', color: 'primary.contrastText' }}>
        <Stack alignItems="center" direction="row" spacing={1}>
          <PhoneIncoming size={18} weight="bold" />
          <Typography variant="subtitle2">Incoming voice call</Typography>
        </Stack>
      </Box>
      <Stack alignItems="center" direction="row" spacing={2} sx={{ px: 2.5, py: 2 }}>
        <Box sx={{ position: 'relative' }}>
          <Avatar sx={{ width: 52, height: 52, bgcolor: 'primary.main', color: '#fff', fontWeight: 600 }}>{initials(call.peer?.name)}</Avatar>
          <Box
            sx={{
              position: 'absolute',
              inset: -6,
              borderRadius: '50%',
              border: 2,
              borderColor: 'success.main',
              animation: 'callPulse 1.4s ease-out infinite',
              '@keyframes callPulse': { from: { opacity: 0.8, transform: 'scale(0.9)' }, to: { opacity: 0, transform: 'scale(1.25)' } },
            }}
          />
        </Box>
        <Box sx={{ minWidth: 0 }}>
          <Typography noWrap variant="h6">
            {call.peer?.name}
          </Typography>
          <Typography color="text.secondary" noWrap variant="body2">
            {call.peer?.role === 'driver' ? 'Driver' : 'Staff'}
            {call.channelName ? ` · ${call.channelName}` : ''}
          </Typography>
        </Box>
      </Stack>
      {call.moreIncoming ? (
        <Box sx={{ mx: 2.5, mb: 1.5, px: 1.5, py: 0.75, borderRadius: 2, bgcolor: 'warning.light', color: 'warning.contrastText' }}>
          <Typography variant="caption" sx={{ fontWeight: 600 }}>
            +{call.moreIncoming} more {call.moreIncoming === 1 ? 'driver is' : 'drivers are'} calling — shown next
          </Typography>
        </Box>
      ) : null}
      <Stack direction="row" spacing={1.5} sx={{ px: 2.5, pb: 2.5 }}>
        <Button color="error" fullWidth onClick={call.decline} startIcon={<PhoneDisconnect />} variant="outlined">
          Decline
        </Button>
        <Button color="success" fullWidth onClick={() => void call.accept()} startIcon={<Phone weight="fill" />} variant="contained">
          Accept
        </Button>
      </Stack>
    </Paper>
  );
}

function ActiveBar(): React.JSX.Element {
  const call = useCall();
  const [minimized, setMinimized] = React.useState(false);
  const [micMenu, setMicMenu] = React.useState<HTMLElement | null>(null);
  const seconds = useTimer(call.answeredAt, call.phase === 'active');

  const status =
    call.phase === 'ended'
      ? call.endedText || 'Call ended'
      : call.phase === 'outgoing'
        ? 'Calling…'
        : call.phase === 'connecting'
          ? 'Connecting…'
          : call.reconnecting
            ? 'Reconnecting…'
            : formatCallDuration(seconds);

  const ended = call.phase === 'ended';

  if (minimized && !ended) {
    return (
      <Paper
        elevation={10}
        onClick={() => setMinimized(false)}
        sx={{ ...CARD, width: 'auto', bottom: 24, px: 2, py: 1, cursor: 'pointer', bgcolor: 'success.main', color: 'success.contrastText' }}
      >
        <Stack alignItems="center" direction="row" spacing={1}>
          <Phone size={16} weight="fill" />
          <Typography variant="subtitle2">{call.peer?.name}</Typography>
          <Typography sx={{ fontVariantNumeric: 'tabular-nums' }} variant="body2">
            {status}
          </Typography>
          <CaretUp size={14} />
        </Stack>
      </Paper>
    );
  }

  return (
    <Paper elevation={12} aria-label="Call controls" sx={{ ...CARD, bottom: 24 }}>
      <Stack alignItems="center" direction="row" spacing={1.5} sx={{ px: 2, pt: 2, pb: 1.5 }}>
        <Avatar sx={{ width: 44, height: 44, bgcolor: ended ? 'grey.400' : 'success.main', color: '#fff', fontWeight: 600 }}>{initials(call.peer?.name)}</Avatar>
        <Box sx={{ flex: 1, minWidth: 0 }}>
          <Typography noWrap variant="subtitle1">
            {call.peer?.name}
          </Typography>
          <Stack alignItems="center" direction="row" spacing={0.75}>
            {call.reconnecting && !ended ? <WifiSlash color="var(--mui-palette-warning-main)" size={14} /> : null}
            <Typography
              color={call.reconnecting && !ended ? 'warning.main' : 'text.secondary'}
              sx={{ fontVariantNumeric: 'tabular-nums' }}
              variant="body2"
            >
              {status}
              {call.remoteMuted && !ended ? ' · they muted' : ''}
            </Typography>
          </Stack>
        </Box>
        {!ended ? (
          <Tooltip title="Minimise">
            <IconButton onClick={() => setMinimized(true)} size="small">
              <CaretDown />
            </IconButton>
          </Tooltip>
        ) : null}
      </Stack>
      {!ended ? (
        <Stack alignItems="center" direction="row" justifyContent="center" spacing={2} sx={{ px: 2, pb: 2 }}>
          <Tooltip title={call.muted ? 'Unmute' : 'Mute'}>
            <IconButton
              aria-pressed={call.muted}
              onClick={call.toggleMute}
              sx={{ bgcolor: call.muted ? 'warning.main' : 'action.hover', color: call.muted ? 'warning.contrastText' : 'text.primary', width: 48, height: 48, '&:hover': { bgcolor: call.muted ? 'warning.dark' : 'action.selected' } }}
            >
              {call.muted ? <MicrophoneSlash size={22} /> : <Microphone size={22} />}
            </IconButton>
          </Tooltip>
          <Tooltip title="Microphone">
            <span>
              <IconButton
                disabled={call.microphones.length < 2}
                onClick={(e) => setMicMenu(e.currentTarget)}
                sx={{ bgcolor: 'action.hover', width: 36, height: 36 }}
              >
                <CaretUp size={16} />
              </IconButton>
            </span>
          </Tooltip>
          <Tooltip title={call.phase === 'outgoing' ? 'Cancel' : 'Hang up'}>
            <IconButton
              onClick={call.hangup}
              sx={{ bgcolor: 'error.main', color: 'error.contrastText', width: 56, height: 48, borderRadius: 6, '&:hover': { bgcolor: 'error.dark' } }}
            >
              <PhoneDisconnect size={22} weight="fill" />
            </IconButton>
          </Tooltip>
        </Stack>
      ) : null}
      <Menu anchorEl={micMenu} onClose={() => setMicMenu(null)} open={!!micMenu}>
        {call.microphones.map((m, i) => (
          <MenuItem
            key={m.deviceId || i}
            onClick={() => {
              setMicMenu(null);
              void call.selectMicrophone(m.deviceId);
            }}
          >
            <ListItemIcon>{(call.micId || 'default') === m.deviceId ? <Check /> : null}</ListItemIcon>
            <ListItemText>{m.label || `Microphone ${i + 1}`}</ListItemText>
          </MenuItem>
        ))}
      </Menu>
    </Paper>
  );
}

/** Mounted once in the dashboard layout: the incoming card and the floating call bar. */
export function CallOverlay(): React.JSX.Element | null {
  const call = useCall();
  if (call.phase === 'idle') return null;
  return <Fade in>{call.phase === 'incoming' ? <div><IncomingCard /></div> : <div><ActiveBar /></div>}</Fade>;
}
