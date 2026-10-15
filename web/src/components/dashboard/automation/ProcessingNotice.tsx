'use client';

import * as React from 'react';
import { Alert, Button, CircularProgress, LinearProgress, Stack, Typography } from '@mui/material';

// Counts seconds while `active` is true
export function useElapsedSeconds(active: boolean): number {
  const [seconds, setSeconds] = React.useState(0);
  React.useEffect(() => {
    if (!active) {
      setSeconds(0);
      return undefined;
    }
    const started = Date.now();
    const timer = setInterval(() => setSeconds(Math.floor((Date.now() - started) / 1000)), 500);
    return () => clearInterval(timer);
  }, [active]);
  return seconds;
}

const SLOW_AFTER = 25;

// Shown while the AI reads a document: elapsed time, what is normal, and a way out if it drags on
export function ProcessingNotice({
  active,
  label = 'Reading the document',
  onCancel,
}: {
  active: boolean;
  label?: string;
  onCancel?: () => void;
}): React.JSX.Element | null {
  const seconds = useElapsedSeconds(active);
  if (!active) return null;
  const slow = seconds >= SLOW_AFTER;

  return (
    <Alert icon={<CircularProgress size={20} />} severity={slow ? 'warning' : 'info'}>
      <Stack spacing={1}>
        <Typography variant="body2">
          <b>
            {label}… {seconds}s
          </b>{' '}
          {slow ? '— taking longer than usual.' : '— usually 5 to 15 seconds.'}
        </Typography>
        <LinearProgress variant={slow ? 'indeterminate' : 'determinate'} value={Math.min(100, (seconds / SLOW_AFTER) * 100)} />
        {slow && onCancel ? (
          <Stack direction="row" spacing={1}>
            <Typography variant="body2">The AI service may be busy.</Typography>
            <Button onClick={onCancel} size="small">
              Cancel and try again
            </Button>
          </Stack>
        ) : null}
      </Stack>
    </Alert>
  );
}
