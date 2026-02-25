'use client';

import React from 'react';
import { useGetMessagesBroadcastQuery } from '@/redux/MessageApiSlice';
import CampaignIcon from '@mui/icons-material/Campaign';
import { Avatar, Box, Card, CardContent, CircularProgress, Divider, Paper, Stack, Typography } from '@mui/material';
import moment from 'moment';

import LinkifyText from '@/components/LinkifyText';
import MediaComponent from '@/components/messages/MediaComment';

export default function MessageList() {
  const { data, isLoading } = useGetMessagesBroadcastQuery({});

  if (isLoading) {
    return (
      <Box textAlign="center" mt={5}>
        <CircularProgress />
      </Box>
    );
  }

  const messages = data?.data || [];

  return (
    <Box maxWidth={900} mx="auto" mt={4}>
      <Typography variant="h5" fontWeight={600} mb={3}>
        Broadcast History
      </Typography>

      {messages.length === 0 ? (
        <Typography color="text.secondary">No broadcast messages found.</Typography>
      ) : (
        <Stack spacing={2}>
          {messages.map((message: any) => (
            <Card
              key={message.id}
              elevation={2}
              sx={{
                borderRadius: 3,
                transition: '0.2s',
                '&:hover': { boxShadow: 6 },
              }}
            >
              <CardContent >
                <Stack direction="row" spacing={2}>
                  <Avatar sx={{ bgcolor: 'primary.main' }}>
                    <CampaignIcon />
                  </Avatar>

                  <Box flex={1}>
                    {/* Header */}
                    <Stack direction="row" justifyContent="space-between" alignItems="center">
                      <Typography fontWeight={600}>{message?.sender?.username || 'Staff'}</Typography>

                      <Typography variant="caption" color="text.secondary">
                        {moment(message.messageTimestampUtc).format('DD MMM YYYY, hh:mm A')}
                      </Typography>
                    </Stack>

                    <Divider sx={{ my: 1 }} />
  {message.url && (
        <Paper
         
        >
                    {/* Message Body */}
                    { message.url_upload_type == 'not-upload' || message.url_upload_type == 'local' ? (
                      <MediaComponent
                        messageDirection={message.messageDirection}
                        type={'server'}
                        thumbnail={`http://52.9.12.189:4300/${message.url}`}
                        url={`http://52.9.12.189:4300/${message.url}`}
                        name={message.url ? message.url : ' '}
                      />
                    ) : (
                      <MediaComponent
                        messageDirection={message.messageDirection}
                        type={message.url_upload_type}
                        thumbnail={`https://ciity-sms.s3.us-west-1.amazonaws.com/${message.thumbnail}`}
                        url={`https://ciity-sms.s3.us-west-1.amazonaws.com/${message.url}`}
                        name={message.url ? message.url : ' '}
                      />
                    )}</Paper> )}
                    {message.body && <LinkifyText text={message.body} />}
                  </Box>
                </Stack>
              </CardContent>
            </Card>
          ))}
        </Stack>
      )}
    </Box>
  );
}
