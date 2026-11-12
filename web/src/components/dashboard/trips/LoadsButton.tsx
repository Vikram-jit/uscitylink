'use client';

import * as React from 'react';
import { AppBar, Badge, Box, Button, Dialog, IconButton, Slide, Toolbar, Typography } from '@mui/material';
import type { TransitionProps } from '@mui/material/transitions';
import { Close, LocalShipping } from '@mui/icons-material';

import { toast } from 'react-toastify';

import { useAutomationAccess } from '@/components/dashboard/automation/AdminGuard';
import { useSocketEvent } from '@/hooks/use-socket-event';
import { useListLoadBoardQuery } from '@/redux/TripApiSlice';

import { LoadsHome } from './LoadsHome';
import { TypedLoadQuestion } from './TypedLoadQuestion';

// Top bar: Loads from any page, full screen over it — no leaving the chat you're in. The badge counts
// loads that need dispatch: a driver waiting for a confirm, or a load waiting for its next leg.

const SlideUp = React.forwardRef(function SlideUp(props: TransitionProps & { children: React.ReactElement }, ref: React.Ref<unknown>) {
  return <Slide direction="up" ref={ref} {...props} />;
});

export function LoadsButton(): React.JSX.Element | null {
  const { isStaff } = useAutomationAccess();
  const [open, setOpen] = React.useState(false);
  const waiting = useListLoadBoardQuery({ status: 'waiting,transfer', limit: 1 }, { skip: !isStaff });
  const refresh = React.useCallback(() => {
    if (isStaff) void waiting.refetch();
  }, [isStaff, waiting]);
  useSocketEvent('trip:offer', refresh, isStaff);
  useSocketEvent('trip:updated', refresh, isStaff);
  useSocketEvent('load:updated', refresh, isStaff);
  // Driver hasn't tapped Got it / pickup time passed (also in System Messages)
  useSocketEvent<[any]>(
    'trip:reminder',
    (d) => {
      if (d?.text) toast.warning(d.text, { autoClose: 20000, onClick: () => setOpen(true) });
    },
    isStaff
  );

  if (!isStaff) return null;
  const count = waiting.data?.data?.total || 0;

  return (
    <>
      <Badge color="warning" badgeContent={count} overlap="rectangular">
        <Button variant="contained" size="small" startIcon={<LocalShipping />} onClick={() => setOpen(true)}>
          Loads
        </Button>
      </Badge>
      <TypedLoadQuestion enabled={isStaff} />
      <Dialog fullScreen open={open} onClose={() => setOpen(false)} TransitionComponent={SlideUp}>
        <AppBar position="sticky" color="default" elevation={1}>
          <Toolbar>
            <LocalShipping sx={{ mr: 1.5 }} />
            <Typography variant="h6" sx={{ flexGrow: 1 }}>
              Loads
            </Typography>
            <IconButton edge="end" aria-label="Close loads" onClick={() => setOpen(false)}>
              <Close />
            </IconButton>
          </Toolbar>
        </AppBar>
        <Box sx={{ p: { xs: 1, md: 3 }, bgcolor: 'background.default', flexGrow: 1 }}>{open && <LoadsHome />}</Box>
      </Dialog>
    </>
  );
}
