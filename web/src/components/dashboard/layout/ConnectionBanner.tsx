'use client';

import * as React from 'react';
import { Box, Button, Collapse, Stack, Typography } from '@mui/material';
import { ArrowClockwise, CheckCircle, WifiSlash } from '@phosphor-icons/react';
import { useRouter } from 'next/navigation';

import { useSocket } from '@/lib/socketProvider';
import { paths } from '@/paths';

// Shown at the top of every dashboard page while the live connection is down: incoming calls,
// new messages and "on call" marks can't reach this dispatcher until it's back, so they must know.
// Waits a few seconds before showing (page load, brief network blips) and says "Back online" when
// the connection returns.

const SHOW_AFTER_MS = 3000;
const OFFER_RELOAD_AFTER_MS = 30000;

export function ConnectionBanner(): React.JSX.Element {
  const { isConnected, connectionError, authFailed, reconnectNow } = useSocket();
  const router = useRouter();
  const [downSince, setDownSince] = React.useState<number | null>(null);
  const [now, setNow] = React.useState(Date.now());
  const [browserOnline, setBrowserOnline] = React.useState(true);
  const [backOnline, setBackOnline] = React.useState(false);
  const wasShown = React.useRef(false);

  React.useEffect(() => {
    const update = () => setBrowserOnline(navigator.onLine);
    update();
    window.addEventListener('online', update);
    window.addEventListener('offline', update);
    return () => {
      window.removeEventListener('online', update);
      window.removeEventListener('offline', update);
    };
  }, []);

  React.useEffect(() => {
    if (isConnected) {
      setDownSince(null);
      if (wasShown.current) {
        wasShown.current = false;
        setBackOnline(true);
        const t = setTimeout(() => setBackOnline(false), 3000);
        return () => clearTimeout(t);
      }
      return undefined;
    }
    setDownSince((since) => since ?? Date.now());
    const tick = setInterval(() => setNow(Date.now()), 1000);
    return () => clearInterval(tick);
  }, [isConnected]);

  // The browser regained network: don't wait for the next scheduled retry
  React.useEffect(() => {
    if (browserOnline && !isConnected) reconnectNow();
  }, [browserOnline, isConnected, reconnectNow]);

  const downFor = downSince ? now - downSince : 0;
  const show = !isConnected && downFor >= SHOW_AFTER_MS;
  if (show) wasShown.current = true;

  const message = authFailed
    ? 'Your session has expired. Calls and messages can’t reach you until you sign in again.'
    : !browserOnline
      ? 'No internet connection. Calls and messages can’t reach you until it’s back.'
      : connectionError && /server error/i.test(connectionError)
        ? 'The server is having trouble. Calls and messages can’t reach you — reconnecting…'
        : 'Disconnected from the server. Calls and messages can’t reach you — reconnecting…';

  return (
    <Box sx={{ position: 'sticky', top: 'var(--MainNav-height)', zIndex: 'calc(var(--MainNav-zIndex) - 1)' }}>
      <Collapse in={show}>
        <Stack
          alignItems="center"
          aria-live="assertive"
          direction="row"
          flexWrap="wrap"
          gap={1.5}
          role="alert"
          sx={{ px: { xs: 2, sm: 3 }, py: 1.25, bgcolor: 'error.main', color: 'error.contrastText' }}
        >
          <WifiSlash size={20} weight="bold" />
          <Typography sx={{ flex: '1 1 260px', fontWeight: 600 }} variant="body2">
            {message}
            {!authFailed && downFor >= 10000 ? (
              <Typography component="span" sx={{ fontWeight: 400, opacity: 0.85, ml: 1 }} variant="body2">
                Offline for {Math.round(downFor / 1000)}s
              </Typography>
            ) : null}
          </Typography>
          {authFailed ? (
            <Button color="inherit" onClick={() => router.push(paths.auth.signIn)} size="small" variant="outlined">
              Sign in
            </Button>
          ) : (
            <>
              <Button color="inherit" onClick={reconnectNow} size="small" startIcon={<ArrowClockwise />} variant="outlined">
                Retry now
              </Button>
              {downFor >= OFFER_RELOAD_AFTER_MS ? (
                <Button color="inherit" onClick={() => window.location.reload()} size="small" variant="outlined">
                  Reload page
                </Button>
              ) : null}
            </>
          )}
        </Stack>
      </Collapse>
      <Collapse in={backOnline && isConnected}>
        <Stack
          alignItems="center"
          direction="row"
          gap={1}
          role="status"
          sx={{ px: { xs: 2, sm: 3 }, py: 0.75, bgcolor: 'success.main', color: 'success.contrastText' }}
        >
          <CheckCircle size={18} weight="fill" />
          <Typography sx={{ fontWeight: 600 }} variant="body2">
            Back online
          </Typography>
        </Stack>
      </Collapse>
    </Box>
  );
}
