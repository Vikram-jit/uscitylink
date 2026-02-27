'use client';

import React, { useState } from 'react';
import {
  Avatar,
  Box,
  Chip,
  CircularProgress,
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
import CampaignIcon from '@mui/icons-material/Campaign';
import InsertDriveFileIcon from '@mui/icons-material/InsertDriveFile';
import moment from 'moment';
import { useGetMessagesBroadcastQuery } from '@/redux/MessageApiSlice';
import MediaComponent from '@/components/messages/MediaComment';

export default function MessageList() {
  const [page, setPage] = useState(1);
  const [search, setSearch] = useState('');
  const [status, setStatus] = useState('');

  const { data, isLoading } = useGetMessagesBroadcastQuery({
    page,
    pageSize: 10,
    search,
    status,
  });

  const messages = data?.data?.messages || [];
  const totalPages = data?.data?.pagination?.totalPages || 1;

  return (
    <Box maxWidth={1200} mx="auto" mt={4}>
      <Typography variant="h5" fontWeight={600} mb={3}>
        Broadcast List
      </Typography>

      {/* 🔎 Toolbar */}
      <Paper sx={{ p: 2, mb: 3, borderRadius: 3 }}>
        <Stack direction={{ xs: 'column', md: 'row' }} spacing={2}>
          <TextField
            label="Search Broadcast..."
            fullWidth
            value={search}
            onChange={(e) => {
              setPage(1);
              setSearch(e.target.value);
            }}
          />

          {/* <TextField
            select
            label="Status"
            value={status}
            onChange={(e) => {
              setPage(1);
              setStatus(e.target.value);
            }}
            sx={{ minWidth: 200 }}
          >
            <MenuItem value="">All</MenuItem>
            <MenuItem value="pending">Pending</MenuItem>
            <MenuItem value="processing">Processing</MenuItem>
            <MenuItem value="sent">Sent</MenuItem>
            <MenuItem value="failed">Failed</MenuItem>
          </TextField> */}
        </Stack>
      </Paper>

      {/* 📊 Table */}
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
                  <TableCell><b>Broadcast Id</b></TableCell>
                  <TableCell><b>Message</b></TableCell>
                  <TableCell><b>Media</b></TableCell>
                  <TableCell><b>Status</b></TableCell>
                  <TableCell><b>Total Messages</b></TableCell>
                  <TableCell><b>Sent Messages</b></TableCell>
                  <TableCell><b>Created At</b></TableCell>
                </TableRow>
              </TableHead>

              <TableBody>
                {messages.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={5} align="center">
                      No broadcast messages found.
                    </TableCell>
                  </TableRow>
                ) : (
                  messages.map((message) => (
                    <TableRow
                      key={message.id}
                      hover
                      sx={{
                        '&:hover': {
                          backgroundColor: 'rgba(0,0,0,0.03)',
                        },
                      }}
                    >
                      <TableCell>
                        <Stack direction="row" spacing={1} alignItems="center">
                          <Avatar
                            sx={{
                              bgcolor: 'primary.main',
                              width: 32,
                              height: 32,
                            }}
                          >
                            <CampaignIcon fontSize="small" />
                          </Avatar>
                          <Typography fontWeight={500}>
                            {message?.id?.slice(0, 8).toUpperCase() ?? '-'}
                          </Typography>
                        </Stack>
                      </TableCell>

                      <TableCell sx={{ maxWidth: 350 }}>
                        <Typography
                          variant="body2"
                          noWrap
                          sx={{ maxWidth: 350 }}
                        >
                          {message.body}
                        </Typography>
                      </TableCell>

                      <TableCell>
                         {message.url ? (
                          <MediaComponent
                            url={`https://ciity-sms.s3.us-west-1.amazonaws.com/${message.url}`}
                            name={message.url ?? ''}
                            width={50}
                            height={50}
                          />
                        ) : (
                         "-"
                        )   }
                      </TableCell>

                      <TableCell>
                        <Chip
                          label={message.totalMessages == message.sentMessages ? 'Sent' :  'Processing' }
                          size="small"
                          color={
                            message.totalMessages == message.sentMessages
                              ? 'success'
                              : 'warning'
                             
                          }
                        />
                      </TableCell>
                            <TableCell>
                        <Typography variant="body2">
                          {message.totalMessages}
                        </Typography>
                      </TableCell>
                      <TableCell>
                        <Typography variant="body2">
                          {message.sentMessages}
                        </Typography>
                      </TableCell>  
                      <TableCell>
                        <Typography variant="caption">
                          {moment(message.createdAt).format(
                            'DD MMM YYYY, hh:mm A'
                          )}
                        </Typography>
                      </TableCell>
                    </TableRow>
                  ))
                )}
              </TableBody>
            </Table>
          </TableContainer>
        )}
      </Paper>

      {/* 📄 Pagination */}
      <Box display="flex" justifyContent="flex-end" mt={3}>
        <Pagination
          count={totalPages}
          page={page}
          onChange={(_, value) => setPage(value)}
          color="primary"
        />
      </Box>
    </Box>
  );
}
