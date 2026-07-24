'use client';

import React, { useState, useEffect, useRef } from 'react';
import {
  Box,
  Button,
  Chip,
  CircularProgress,
  Dialog,
  DialogContent,
  DialogTitle,
  Divider,
  IconButton,
  MenuItem,
  Pagination,
  Paper,
  Stack,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  TextField,
  Typography,
} from '@mui/material';
import CloseIcon from '@mui/icons-material/Close';
import { toast } from 'react-toastify';
// import moment from 'moment';
import { useGetSystemMessagesQuery, useGetSystemUnreadMessagesQuery, useMarkSystemMessageCompleteMutation, useMarkAllSystemMessagesReadMutation } from '@/redux/MessageApiSlice';
import { useGetUsersQuery } from '@/redux/UserApiSlice';
import MediaComponent from '@/components/messages/MediaComment';
import moment from 'moment-timezone';

export default function SystemMessageList() {
  const [page, setPage] = useState(1);
  const [search, setSearch] = useState('');
  const [completedBy, setCompletedBy] = useState('');
  const [startDate, setStartDate] = useState('');
  const [endDate, setEndDate] = useState('');
  const [dialogOpen, setDialogOpen] = useState(false);
  const [markingId, setMarkingId] = useState<string | null>(null);
  const [markingAll, setMarkingAll] = useState(false);
  const timerRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  const { data: staffData } = useGetUsersQuery({ role: 'staff', page: -1, search: '' });
  const staffUsers = staffData?.data?.users || [];

  const { data, isLoading, refetch } = useGetSystemMessagesQuery({ page, pageSize: 10, search, completedBy, startDate, endDate });
  const { data: unreadData, refetch: refetchUnread } = useGetSystemUnreadMessagesQuery();
  const [markComplete] = useMarkSystemMessageCompleteMutation();
  const [markAllRead] = useMarkAllSystemMessagesReadMutation();

  const messages = data?.data?.messages || [];
  const totalPages = data?.data?.pagination?.totalPages || 1;
  const unreadMessages = unreadData?.data?.messages || [];

  useEffect(() => {
    timerRef.current = setTimeout(() => {
      if (unreadMessages.length > 0) {
        setDialogOpen(true);
      }
    }, 2000);

    return () => {
      if (timerRef.current) clearTimeout(timerRef.current);
    };
  }, [unreadMessages.length]);

  const handleMarkComplete = async (id: string) => {
    setMarkingId(id);
    try {
      const res: any = await markComplete({ id });

      if (res?.error) {
        toast.error(res.error?.data?.message || 'Failed to mark message as completed.');
        return;
      }

      await refetchUnread();
      await refetch();
      if (unreadMessages.length <= 1) {
        setDialogOpen(false);
      }
    } finally {
      setMarkingId(null);
    }
  };

  const handleMarkAllRead = async () => {
    setMarkingAll(true);
    try {
      await markAllRead();
      await refetchUnread();
      await refetch();
    } finally {
      setMarkingAll(false);
    }
  };

  return (
    <Box maxWidth={1200} mx="auto" mt={4}>
      <Typography variant="h5" fontWeight={600} mb={3}>
        System Messages
      </Typography>

      <Paper sx={{ p: 2, mb: 3, borderRadius: 3 }}>
        <Stack spacing={2}>
          <Stack direction={{ xs: 'column', md: 'row' }} spacing={2}>
            <TextField
              label="Search messages..."
              fullWidth
              value={search}
              onChange={(e) => { setPage(1); setSearch(e.target.value); }}
            />
            <TextField
              select
              label="Completed By (Staff)"
              value={completedBy}
              onChange={(e) => { setPage(1); setCompletedBy(e.target.value); }}
              sx={{ minWidth: 220 }}
            >
              <MenuItem value="">All</MenuItem>
              {staffUsers.map((u: any) => (
                <MenuItem key={u.id} value={u.id}>
                  {u.username || u?.user?.email || u.id}
                </MenuItem>
              ))}
            </TextField>
          </Stack>
          <Stack direction={{ xs: 'column', md: 'row' }} spacing={2}>
            <TextField
              label="From Date"
              type="date"
              value={startDate}
              onChange={(e) => { setPage(1); setStartDate(e.target.value); }}
              InputLabelProps={{ shrink: true }}
              fullWidth
            />
            <TextField
              label="To Date"
              type="date"
              value={endDate}
              onChange={(e) => { setPage(1); setEndDate(e.target.value); }}
              InputLabelProps={{ shrink: true }}
              fullWidth
            />
            {(completedBy || startDate || endDate) && (
              <Button
                variant="outlined"
                color="inherit"
                onClick={() => { setCompletedBy(''); setStartDate(''); setEndDate(''); setPage(1); }}
                sx={{ whiteSpace: 'nowrap', alignSelf: 'center' }}
              >
                Clear Filters
              </Button>
            )}
          </Stack>
        </Stack>
      </Paper>

      <Paper sx={{ borderRadius: 3, overflow: 'hidden' }}>
        {isLoading ? (
          <Box textAlign="center" py={5}>
            <CircularProgress />
          </Box>
        ) : (
          <TableContainer>
            <Table stickyHeader>
              <TableHead>
                <TableRow>
                  <TableCell><b>#</b></TableCell>
                  <TableCell><b>Message</b></TableCell>
                  <TableCell><b>Media</b></TableCell>
                  <TableCell><b>Completed By</b></TableCell>
                  <TableCell><b>Timestamp</b></TableCell>
                  <TableCell><b>Action</b></TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {messages.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={6} align="center">
                      No system messages found.
                    </TableCell>
                  </TableRow>
                ) : (
                  messages.map((msg: any, index: number) => (
                    <TableRow key={msg.id} hover>
                      <TableCell>
                        <Typography variant="body2" color="text.secondary">
                          {(page - 1) * 10 + index + 1}
                        </Typography>
                      </TableCell>
                      <TableCell sx={{ maxWidth: 400 }}>
                        <Typography variant="body2"  sx={{ maxWidth: 400 }}>
                          {msg.body || '-'}
                        </Typography>
                      </TableCell>
                      <TableCell>
                        {msg.url ? (
                          <MediaComponent
                            url={`https://ciity-sms.s3.us-west-1.amazonaws.com/${msg.url}`}
                            name={msg.url}
                            width={50}
                            height={50}
                          />
                        ) : (
                          '-'
                        )}
                      </TableCell>
                      <TableCell>
                        {msg.isCompleted && msg.completedByUser ? (
                          <Typography variant="body2">{msg.completedByUser.username || '-'}</Typography>
                        ) : (
                          <Chip label="Pending" size="small" color="warning" />
                        )}
                      </TableCell>
                      <TableCell>
                       <Typography variant="caption">
  {moment
    .utc(msg.messageTimestampUtc)
    .tz('America/Los_Angeles')
    .format('DD MMM YYYY, hh:mm A')}
</Typography>
                      </TableCell>
                      <TableCell>
                        {msg.isCompleted ? (
                          <Typography variant="body2" color="text.secondary">
                            Completed by {msg.completedByUser?.username || 'someone'}
                          </Typography>
                        ) : (
                          <Button
                            variant="contained"
                            size="small"
                            color="success"
                            onClick={() => handleMarkComplete(msg.id)}
                            disabled={markingId === msg.id}
                            startIcon={markingId === msg.id ? <CircularProgress size={14} color="inherit" /> : undefined}
                            sx={{ whiteSpace: 'nowrap' }}
                          >
                            Mark Completed
                          </Button>
                        )}
                      </TableCell>
                    </TableRow>
                  ))
                )}
              </TableBody>
            </Table>
          </TableContainer>
        )}
      </Paper>

      <Box display="flex" justifyContent="flex-end" mt={3}>
        <Pagination
          count={totalPages}
          page={page}
          onChange={(_, value) => setPage(value)}
          color="primary"
        />
      </Box>

      <Dialog open={dialogOpen} maxWidth="sm" fullWidth onClose={() => setDialogOpen(false)}>
        <DialogTitle>
          <Stack direction="row" justifyContent="space-between" alignItems="flex-start">
            <Box>
              <Typography variant="h6" fontWeight={600}>
                Unread System Messages
              </Typography>
              <Typography variant="body2" color="text.secondary">
                Uncompleted messages must be marked one by one.
              </Typography>
            </Box>
            <Stack direction="row" spacing={1} alignItems="flex-start">
              {/* <Button
                variant="outlined"
                size="small"
                onClick={handleMarkAllRead}
                disabled={markingAll}
                startIcon={markingAll ? <CircularProgress size={14} color="inherit" /> : undefined}
                sx={{ whiteSpace: 'nowrap', flexShrink: 0 }}
              >
                Mark All Read
              </Button> */}
              <IconButton size="small" onClick={() => setDialogOpen(false)} aria-label="Close">
                <CloseIcon fontSize="small" />
              </IconButton>
            </Stack>
          </Stack>
        </DialogTitle>
        <DialogContent dividers>
          {unreadMessages.length === 0 ? (
            <Typography variant="body2" color="text.secondary" textAlign="center" py={2}>
              All messages completed.
            </Typography>
          ) : (
            <Stack spacing={2}>
              {unreadMessages.map((msg: any, index: number) => (
                <Box key={msg.id}>
                  <Stack direction="row" justifyContent="space-between" alignItems="flex-start" spacing={2}>
                    <Box flex={1}>
                      <Stack direction="row" spacing={1} alignItems="center" mb={0.5}>
                        <Typography variant="caption" color="text.secondary">
                          {moment(msg.messageTimestampUtc).format('DD MMM YYYY, hh:mm A')}
                        </Typography>
                        {msg.isCompleted && (
                          <Chip
                            label={`Completed by ${msg.completedByUser?.username || 'someone'}`}
                            size="small"
                            color="success"
                            variant="outlined"
                          />
                        )}
                      </Stack>
                      <Typography variant="body2">
                        {msg.body}
                      </Typography>
                    </Box>
                    <Button
                      variant="contained"
                      size="small"
                      color={msg.isCompleted ? 'primary' : 'success'}
                      onClick={() => handleMarkComplete(msg.id)}
                      disabled={markingId === msg.id}
                      startIcon={markingId === msg.id ? <CircularProgress size={14} color="inherit" /> : undefined}
                      sx={{ whiteSpace: 'nowrap', flexShrink: 0 }}
                    >
                      {msg.isCompleted ? 'Mark Read' : 'Mark Completed'}
                    </Button>
                  </Stack>
                  {index < unreadMessages.length - 1 && <Divider sx={{ mt: 2 }} />}
                </Box>
              ))}
            </Stack>
          )}
        </DialogContent>
      </Dialog>
    </Box>
  );
}
