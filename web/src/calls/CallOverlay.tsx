'use client';

import * as React from 'react';
import {
  Avatar,
  AvatarGroup,
  Box,
  Button,
  CircularProgress,
  Divider,
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
  ArrowsLeftRight,
  CameraRotate,
  CornersIn,
  CornersOut,
  VideoCamera,
  VideoCameraSlash,
  CaretDown,
  CaretUp,
  Check,
  Microphone,
  MicrophoneSlash,
  Phone,
  PhoneDisconnect,
  PhoneIncoming,
  Record,
  UserPlus,
  UsersThree,
  WifiSlash,
  X,
} from '@phosphor-icons/react';

import { useGetAvailableStaffQuery } from '@/redux/CallApiSlice';

import { CallPeer, callName, formatCallDuration, useCall } from './CallProvider';

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

// The call card floats above the dashboard (and its dialogs); its own menus must open above it,
// or they render underneath the card and clicking Add / the microphone arrow seems to do nothing.
const CALL_LAYER = 1400;
const MENU_LAYER = CALL_LAYER + 100;

const CARD = {
  position: 'fixed' as const,
  right: { xs: 12, sm: 24 },
  zIndex: CALL_LAYER,
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
          {call.transfer ? (
            <ArrowsLeftRight size={18} weight="bold" />
          ) : call.invitedBy ? (
            <UsersThree size={18} weight="bold" />
          ) : (
            <PhoneIncoming size={18} weight="bold" />
          )}
          <Typography variant="subtitle2">
            {call.transfer
              ? 'Transferred call'
              : call.invitedBy
                ? 'Request to join a call'
                : call.callType === 'video'
                  ? 'Incoming video call'
                  : 'Incoming voice call'}
          </Typography>
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
            {callName(call, call.peer)}
          </Typography>
          <Typography color="text.secondary" noWrap variant="body2">
            {call.transfer
              ? `is transferring a call to you${call.members.length ? ` · ${call.members.filter((m) => m.id !== call.invitedBy?.id).map((m) => m.name).join(', ')}` : ''}`
              : call.invitedBy
              ? `asks you to join${call.members.length ? ` · with ${call.members.map((m) => m.name).join(', ')}` : ''}`
              : `${call.peer?.role === 'driver' ? 'Driver' : 'Staff'}${call.channelName ? ` · ${call.channelName}` : ''}`}
          </Typography>
        </Box>
      </Stack>
      {call.recording ? (
        <Stack alignItems="center" direction="row" spacing={1} sx={{ mx: 2.5, mb: 1.5 }}>
          <RecordedBadge compact={false} />
          <Typography color="text.secondary" variant="caption">
            This call will be recorded
          </Typography>
        </Stack>
      ) : null}
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
        {call.callType === 'video' ? (
          <>
            <Button color="success" fullWidth onClick={() => void call.accept()} startIcon={<Phone weight="fill" />} variant="outlined">
              Voice
            </Button>
            <Button color="success" fullWidth onClick={() => void call.accept({ video: true })} startIcon={<VideoCamera weight="fill" />} variant="contained">
              Video
            </Button>
          </>
        ) : (
          <Button color="success" fullWidth onClick={() => void call.accept()} startIcon={<Phone weight="fill" />} variant="contained">
            Accept
          </Button>
        )}
      </Stack>
    </Paper>
  );
}

/** Red "Recorded" mark: the call is recorded and both people are told so. */
function RecordedBadge({ compact = false, video = false }: { compact?: boolean; video?: boolean }): React.JSX.Element {
  return (
    <Stack
      alignItems="center"
      aria-label={video ? 'This call is recorded with video' : 'This call is recorded'}
      direction="row"
      spacing={0.5}
      sx={{ color: 'error.main', flexShrink: 0 }}
    >
      <Box
        sx={{
          width: 8,
          height: 8,
          borderRadius: '50%',
          bgcolor: compact ? '#fff' : 'error.main',
          animation: 'recBlink 1.6s ease-in-out infinite',
          '@keyframes recBlink': { '50%': { opacity: 0.35 } },
        }}
      />
      {compact ? null : (
        <Typography sx={{ fontWeight: 600 }} variant="caption">
          {video ? 'Recording video' : 'Recorded'}
        </Typography>
      )}
    </Stack>
  );
}

/** Group call: who is on it (muted ones marked) and who is still being asked to join. */
function Participants(): React.JSX.Element {
  const call = useCall();
  return (
    <Box sx={{ px: 2, pb: 1.5 }}>
      <Stack spacing={0.75}>
        {call.members.map((m) => (
          <Stack alignItems="center" direction="row" key={m.id} spacing={1}>
            <Avatar sx={{ width: 26, height: 26, fontSize: 12, bgcolor: m.role === 'driver' ? 'primary.main' : 'success.main' }}>
              {initials(m.name)}
            </Avatar>
            <Typography noWrap sx={{ flex: 1 }} variant="body2">
              {callName(call, m)}
              <Typography color="text.secondary" component="span" variant="caption">
                {m.role === 'driver' ? ' · Driver' : ''}
              </Typography>
            </Typography>
            {call.mutedIds.includes(m.id) ? <MicrophoneSlash aria-label="Muted" color="var(--mui-palette-warning-main)" size={16} /> : null}
          </Stack>
        ))}
        {call.pending.map((p) => (
          <Stack alignItems="center" direction="row" key={p.id} spacing={1} sx={{ opacity: 0.75 }}>
            <Avatar sx={{ width: 26, height: 26, fontSize: 12, bgcolor: 'grey.400' }}>{initials(p.name)}</Avatar>
            <Typography noWrap sx={{ flex: 1 }} variant="body2">
              {p.name}
              <Typography color="text.secondary" component="span" variant="caption">
                {' · ringing…'}
              </Typography>
            </Typography>
            <Tooltip title="Stop asking">
              <IconButton aria-label={`Stop asking ${p.name}`} onClick={() => call.cancelAdd(p.id)} size="small">
                <X size={14} />
              </IconButton>
            </Tooltip>
          </Stack>
        ))}
      </Stack>
    </Box>
  );
}

/** Staff who are online: ask one of them to join this call, or transfer the call to them. */
function AddPersonMenu({
  anchor,
  onClose,
  mode,
}: {
  anchor: HTMLElement | null;
  onClose: () => void;
  mode: 'add' | 'transfer';
}): React.JSX.Element {
  const call = useCall();
  const { data, isFetching } = useGetAvailableStaffQuery(undefined, { skip: !anchor });
  const onCall = new Set([...call.members, ...call.pending].map((p) => p.id));
  const staff = (data?.data || []).filter((s) => !onCall.has(s.id));
  return (
    <Menu
      anchorEl={anchor}
      onClose={onClose}
      open={!!anchor}
      PaperProps={{ sx: { maxHeight: 320, minWidth: 240 } }}
      sx={{ zIndex: MENU_LAYER }}
    >
      <Typography color="text.secondary" sx={{ px: 2, py: 0.5 }} variant="caption">
        {mode === 'transfer' ? 'Transfer the call to — you leave when they pick up' : 'Ask a staff member to join'}
      </Typography>
      <Divider />
      {isFetching ? (
        <Stack alignItems="center" sx={{ py: 2 }}>
          <CircularProgress size={18} />
        </Stack>
      ) : staff.length ? (
        staff.map((s) => (
          <MenuItem
            disabled={s.busy}
            key={s.id}
            onClick={() => {
              onClose();
              const person: CallPeer = { id: s.id, name: s.name, role: 'staff' };
              void (mode === 'transfer' ? call.transferTo(person) : call.addPerson(person));
            }}
          >
            <ListItemIcon>
              <Avatar sx={{ width: 24, height: 24, fontSize: 11 }}>{initials(s.name)}</Avatar>
            </ListItemIcon>
            <ListItemText primary={s.name} secondary={s.busy ? 'On a call' : 'Online'} />
          </MenuItem>
        ))
      ) : (
        <Typography color="text.secondary" sx={{ px: 2, py: 1.5 }} variant="body2">
          No other staff online right now
        </Typography>
      )}
    </Menu>
  );
}

/** One person's video (or their initials while their camera is off). */
function VideoTile({
  stream,
  on,
  name,
  muted,
  mirror = false,
}: {
  stream: MediaStream | null | undefined;
  on: boolean;
  name: string;
  muted?: boolean;
  mirror?: boolean;
}): React.JSX.Element {
  const ref = React.useRef<HTMLVideoElement | null>(null);
  React.useEffect(() => {
    if (ref.current && ref.current.srcObject !== (stream || null)) ref.current.srcObject = stream || null;
  }, [stream, on]);
  const showVideo = on && !!stream?.getVideoTracks().length;
  return (
    <Box sx={{ position: 'relative', bgcolor: '#0B1F3A', borderRadius: 2, overflow: 'hidden', aspectRatio: '16 / 9' }}>
      {/* Audio plays from the hidden <audio> per person, so the video element stays muted */}
      <video
        autoPlay
        muted
        playsInline
        ref={ref}
        style={{
          width: '100%',
          height: '100%',
          objectFit: 'cover',
          display: showVideo ? 'block' : 'none',
          transform: mirror ? 'scaleX(-1)' : undefined,
        }}
      />
      {!showVideo ? (
        <Stack alignItems="center" justifyContent="center" sx={{ position: 'absolute', inset: 0 }}>
          <Avatar sx={{ width: 48, height: 48, bgcolor: 'success.main', fontWeight: 600 }}>{initials(name)}</Avatar>
        </Stack>
      ) : null}
      <Stack
        alignItems="center"
        direction="row"
        spacing={0.5}
        sx={{ position: 'absolute', left: 6, bottom: 6, px: 0.75, py: 0.25, borderRadius: 1, bgcolor: 'rgba(0,0,0,0.55)', color: '#fff' }}
      >
        {muted ? <MicrophoneSlash size={12} /> : null}
        <Typography sx={{ fontSize: 11, fontWeight: 600 }} noWrap>
          {name}
        </Typography>
      </Stack>
    </Box>
  );
}

/** Shown while anyone's camera is on: everyone's video in a grid, my camera as a small self-view. */
function VideoPanel(): React.JSX.Element {
  const call = useCall();
  const ref = React.useRef<HTMLDivElement | null>(null);
  const [full, setFull] = React.useState(false);
  React.useEffect(() => {
    const onChange = () => setFull(document.fullscreenElement === ref.current);
    document.addEventListener('fullscreenchange', onChange);
    return () => document.removeEventListener('fullscreenchange', onChange);
  }, []);
  const n = call.members.length;
  const cols = n <= 1 ? 1 : n <= 4 ? 2 : 3;
  return (
    <Box ref={ref} sx={{ position: 'relative', px: full ? 0 : 1.5, bgcolor: full ? '#000' : undefined, display: full ? 'flex' : 'block', alignItems: 'center' }}>
      <Box sx={{ display: 'grid', gridTemplateColumns: `repeat(${cols}, 1fr)`, gap: 0.75, width: '100%' }}>
        {call.members.map((m) => (
          <VideoTile
            key={m.id}
            muted={call.mutedIds.includes(m.id)}
            name={call.videoCapable.length && !call.videoCapable.includes(m.id) ? `${m.name} (no video on their app)` : m.name}
            on={call.remoteCamera.includes(m.id)}
            stream={call.remoteStreams[m.id]}
          />
        ))}
      </Box>
      {call.cameraOn ? (
        <Box sx={{ position: 'absolute', right: full ? 16 : 20, bottom: full ? 16 : 8, width: full ? 220 : 110, boxShadow: 6, borderRadius: 2 }}>
          <VideoTile mirror name="You" on stream={call.localVideo} />
        </Box>
      ) : null}
      <Tooltip title={full ? 'Exit full screen' : 'Full screen'}>
        <IconButton
          aria-label={full ? 'Exit full screen' : 'Full screen'}
          onClick={() => (full ? void document.exitFullscreen() : void ref.current?.requestFullscreen())}
          size="small"
          sx={{ position: 'absolute', top: 6, right: full ? 12 : 18, bgcolor: 'rgba(0,0,0,0.45)', color: '#fff', '&:hover': { bgcolor: 'rgba(0,0,0,0.65)' } }}
        >
          {full ? <CornersIn size={16} /> : <CornersOut size={16} />}
        </IconButton>
      </Tooltip>
    </Box>
  );
}

function ActiveBar(): React.JSX.Element {
  const call = useCall();
  const [minimized, setMinimized] = React.useState(false);
  const [micMenu, setMicMenu] = React.useState<HTMLElement | null>(null);
  const [addMenu, setAddMenu] = React.useState<HTMLElement | null>(null);
  const [transferMenu, setTransferMenu] = React.useState<HTMLElement | null>(null);
  const [cameraMenu, setCameraMenu] = React.useState<HTMLElement | null>(null);
  const group = call.members.length > 1 || call.pending.length > 0;
  // Video panel: anyone's camera on, or a video call (staff without a camera still see the driver)
  const video = call.cameraOn || call.remoteCamera.length > 0 || (call.callType === 'video' && call.phase !== 'outgoing');
  const title = call.members.length > 1 ? `Group call · ${call.members.length + 1} people` : callName(call, call.peer);
  const canAdd = call.phase === 'active' && call.members.length + call.pending.length + 1 < call.maxParticipants;
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
          {call.members.length > 1 ? <UsersThree size={16} weight="fill" /> : <Phone size={16} weight="fill" />}
          <Typography variant="subtitle2">{title}</Typography>
          <Typography sx={{ fontVariantNumeric: 'tabular-nums' }} variant="body2">
            {status}
          </Typography>
          {call.recording && call.phase === 'active' ? <RecordedBadge compact video={call.recordVideo} /> : null}
          <CaretUp size={14} />
        </Stack>
      </Paper>
    );
  }

  return (
    <Paper elevation={12} aria-label="Call controls" sx={{ ...CARD, bottom: 24, ...(video && !ended ? { width: { xs: 'calc(100vw - 24px)', sm: 560 } } : {}) }}>
      <Stack alignItems="center" direction="row" spacing={1.5} sx={{ px: 2, pt: 2, pb: 1.5 }}>
        {call.members.length > 1 ? (
          <AvatarGroup max={3} sx={{ '& .MuiAvatar-root': { width: 32, height: 32, fontSize: 13 } }}>
            {call.members.map((m) => (
              <Avatar key={m.id} sx={{ bgcolor: ended ? 'grey.400' : 'success.main' }}>
                {initials(m.name)}
              </Avatar>
            ))}
          </AvatarGroup>
        ) : (
          <Avatar sx={{ width: 44, height: 44, bgcolor: ended ? 'grey.400' : 'success.main', color: '#fff', fontWeight: 600 }}>{initials(call.peer?.name)}</Avatar>
        )}
        <Box sx={{ flex: 1, minWidth: 0 }}>
          <Typography noWrap variant="subtitle1">
            {title}
          </Typography>
          <Stack alignItems="center" direction="row" spacing={0.75}>
            {call.reconnecting && !ended ? <WifiSlash color="var(--mui-palette-warning-main)" size={14} /> : null}
            <Typography
              color={call.reconnecting && !ended ? 'warning.main' : 'text.secondary'}
              sx={{ fontVariantNumeric: 'tabular-nums' }}
              variant="body2"
            >
              {status}
              {call.remoteMuted && !ended && !group ? ' · they muted' : ''}
            </Typography>
            {call.recording && call.phase === 'active' ? <RecordedBadge video={call.recordVideo} /> : null}
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
      {video && !ended ? <VideoPanel /> : null}
      {group && !ended && !video ? <Participants /> : null}
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
          {call.phase === 'active' || call.phase === 'connecting' ? (
            <Tooltip title={call.cameraOn ? 'Turn camera off' : 'Turn camera on'}>
              <IconButton
                aria-label={call.cameraOn ? 'Turn camera off' : 'Turn camera on'}
                aria-pressed={call.cameraOn}
                onClick={() => void call.toggleCamera()}
                sx={{
                  bgcolor: call.cameraOn ? 'primary.main' : 'action.hover',
                  color: call.cameraOn ? 'primary.contrastText' : 'text.primary',
                  width: 48,
                  height: 48,
                  '&:hover': { bgcolor: call.cameraOn ? 'primary.dark' : 'action.selected' },
                }}
              >
                {call.cameraOn ? <VideoCamera size={22} weight="fill" /> : <VideoCameraSlash size={22} />}
              </IconButton>
            </Tooltip>
          ) : null}
          {call.phase === 'active' && call.recording && !call.recordVideo ? (
            <Tooltip title="Record video too, for the rest of this call (audio is already recorded)">
              <IconButton
                aria-label="Record video"
                onClick={() => void call.startVideoRecording()}
                sx={{ bgcolor: 'action.hover', color: 'error.main', width: 48, height: 48 }}
              >
                <Record size={22} weight="fill" />
              </IconButton>
            </Tooltip>
          ) : null}
          {call.cameraOn && call.cameras.length > 1 ? (
            <Tooltip title="Switch camera">
              <IconButton aria-label="Switch camera" onClick={(e) => setCameraMenu(e.currentTarget)} sx={{ bgcolor: 'action.hover', width: 36, height: 36 }}>
                <CameraRotate size={18} />
              </IconButton>
            </Tooltip>
          ) : null}
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
          {call.peer?.role === 'driver' || call.members.length > 1 || call.invitedBy ? (
            <Tooltip title={canAdd ? 'Add someone to the call' : `A call can have at most ${call.maxParticipants} people`}>
              <span>
                <IconButton
                  aria-label="Add someone to the call"
                  disabled={!canAdd}
                  onClick={(e) => setAddMenu(e.currentTarget)}
                  sx={{ bgcolor: 'action.hover', width: 48, height: 48 }}
                >
                  <UserPlus size={22} />
                </IconButton>
              </span>
            </Tooltip>
          ) : null}
          {call.phase === 'active' && (call.peer?.role === 'driver' || call.members.some((m) => m.role === 'driver')) ? (
            <Tooltip title="Transfer the call to another dispatcher">
              <IconButton
                aria-label="Transfer the call"
                onClick={(e) => setTransferMenu(e.currentTarget)}
                sx={{ bgcolor: 'action.hover', width: 48, height: 48 }}
              >
                <ArrowsLeftRight size={22} />
              </IconButton>
            </Tooltip>
          ) : null}
          <Tooltip title={call.phase === 'outgoing' ? 'Cancel' : group ? 'Leave the call' : 'Hang up'}>
            <IconButton
              onClick={call.hangup}
              sx={{ bgcolor: 'error.main', color: 'error.contrastText', width: 56, height: 48, borderRadius: 6, '&:hover': { bgcolor: 'error.dark' } }}
            >
              <PhoneDisconnect size={22} weight="fill" />
            </IconButton>
          </Tooltip>
        </Stack>
      ) : null}
      <AddPersonMenu anchor={addMenu} mode="add" onClose={() => setAddMenu(null)} />
      <AddPersonMenu anchor={transferMenu} mode="transfer" onClose={() => setTransferMenu(null)} />
      <Menu anchorEl={cameraMenu} onClose={() => setCameraMenu(null)} open={!!cameraMenu} sx={{ zIndex: MENU_LAYER }}>
        {call.cameras.map((c, i) => (
          <MenuItem
            key={c.deviceId || i}
            onClick={() => {
              setCameraMenu(null);
              void call.switchCamera(c.deviceId);
            }}
          >
            <ListItemText>{c.label || `Camera ${i + 1}`}</ListItemText>
          </MenuItem>
        ))}
      </Menu>
      <Menu anchorEl={micMenu} onClose={() => setMicMenu(null)} open={!!micMenu} sx={{ zIndex: MENU_LAYER }}>
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
