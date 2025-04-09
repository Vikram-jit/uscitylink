'use client';

import React from 'react';
import { MessageModel } from '@/redux/models/MessageModel';
import { StaffChatModel } from '@/redux/models/StaffChatModel';
import { Delete, Done, DoneAll, PushPin, Reply } from '@mui/icons-material';
import {
  Badge,
  Divider,
  IconButton,
  List,
  ListItem,
  ListItemButton,
  ListItemIcon,
  ListItemText,
  Paper,
  Popover,
  Typography,
} from '@mui/material';
import { Box, Stack, styled } from '@mui/system';
import { DotsThree } from '@phosphor-icons/react';

import { useSocket } from '@/lib/socketProvider';
import MediaComponent from '@/components/messages/MediaComment';
import moment from 'moment';

const MessageBubble = styled(Paper)(({ isOwn }: { isOwn: boolean }) => ({
  padding: '10px 15px',
  maxWidth: '65%',
  wordBreak: 'break-word',
  backgroundColor: isOwn ? '#635bff' : '#e4e4e4',
  color: isOwn ? '#fff' : '#111b21',
  alignSelf: isOwn ? 'flex-end' : 'flex-start',
  borderRadius: '7.5px',
  position: 'relative',
  boxShadow: '0 1px 0.5px rgba(11,20,26,.13)',
}));

interface MessageView {
  selectedContact: StaffChatModel;
  msg: MessageModel;
  setSelectedMessageToReply: React.Dispatch<React.SetStateAction<MessageModel | null>>;
}
export default function MessageView({ selectedContact, msg,setSelectedMessageToReply }: MessageView) {
  const { socket } = useSocket();

  const [anchorEl, setAnchorEl] = React.useState<HTMLButtonElement | null>(null);

  const handleClick = (event: React.MouseEvent<HTMLButtonElement>) => {
    setAnchorEl(event.currentTarget);
  };

  const handleClose = () => {
    setAnchorEl(null);
  };
  const openThree = Boolean(anchorEl);

  return (
    <>
      {selectedContact.id == msg.senderId ? (
        <Box sx={{ display: 'flex', justifyContent: 'flex-start' }}>
          <Typography variant="caption">{msg?.sender?.username}</Typography>
          <Badge
            color={msg?.sender.isOnline ? 'success' : 'default'}
            variant={msg?.sender.isOnline ? 'dot' : 'standard'}
            anchorOrigin={{ vertical: 'bottom', horizontal: 'left' }}
            overlap="circular"
          />
          <IconButton onClick={handleClick} sx={{ padding: 0 }}>
            <DotsThree />
          </IconButton>
        </Box>
      ) : (
        <Box sx={{ display: 'flex', justifyContent: 'flex-end' }}>
          <Typography variant="caption">{msg?.sender?.username}</Typography>
          <IconButton onClick={handleClick} sx={{ padding: 0 }}>
            <DotsThree />
          </IconButton>

          {msg.deliveryStatus === 'sent' && (
            <Done
              sx={{
                fontSize: 14,
              }}
            />
          )}
          {msg.deliveryStatus == 'seen' && (
            <DoneAll
              sx={{
                fontSize: 14,
                color: 'blue',
              }}
            />
          )}
        </Box>
      )}

      <MessageBubble key={msg.id} isOwn={selectedContact.id != msg.senderId}>
        {selectedContact.isCreatedBy
          ? msg.staffPin == '1' && (
              <Box
                sx={{
                  position: 'absolute',
                  top: -8,
                  ...(selectedContact.id == msg.senderId && { right: -5, transform: 'rotate(60deg)' }),
                  ...(selectedContact.id != msg.senderId && { left: -5, transform: 'rotate(300deg)' }),
                }}
              >
                <PushPin sx={{ color: selectedContact.id != msg.senderId ? 'green' : 'orange' }} />
              </Box>
            )
          : msg.driverPin == '1' && (
              <Box
                sx={{
                  position: 'absolute',
                  top: -8,
                  ...(selectedContact.id == msg.senderId && { right: -5, transform: 'rotate(60deg)' }),
                  ...(selectedContact.id != msg.senderId && { left: -5, transform: 'rotate(300deg)' }),
                }}
              >
                <PushPin sx={{ color: selectedContact.id == msg.senderId ? 'green' : 'orange' }} />
              </Box>
            )}
        {msg.url && (
          <Paper
            variant="outlined"
            sx={{
              px: 1.75,
              py: 1.25,
            }}
          >
            <MediaComponent
              type={msg.url_upload_type}
              messageDirection={msg.messageDirection || 'S'}
              url={`https://ciity-sms.s3.us-west-1.amazonaws.com/${msg.url}`}
              name={msg.url ? msg.url : ' '}
              thumbnail={`https://ciity-sms.s3.us-west-1.amazonaws.com/${msg.thumbnail}`}
              dateTime={msg.createdAt}
            />
          </Paper>
        )}
        {msg.r_message && (
              <Box>
                <Stack direction="row" spacing={2} sx={{ justifyContent: 'space-between', mb: 0.25 }}>
                  <Typography variant="body2">
                    {msg.r_message.messageDirection === 'S'
                      ? msg.r_message.sender?.username
                        ? `${msg.r_message.sender?.username}(staff)`
                        : '(staff)'
                      : `${msg.r_message.sender?.username}(${msg.r_message?.sender?.user?.driver_number})`}
                  </Typography>
                  <Typography variant="caption">
                    {moment(msg.r_message.messageTimestampUtc).format('YYYY-MM-DD HH:mm A')}
                  </Typography>
                </Stack>
                {msg.r_message.url ? (
                  <Paper
                    variant="outlined"
                    sx={{
                      px: 1.75,
                      py: 1.25,
                      bgcolor: 'background.paper',

                      borderLeft: '4px solid #ffbf00',
                      mb: 2,
                    }}
                  >
                    <MediaComponent
                      thumbnail={`https://ciity-sms.s3.us-west-1.amazonaws.com/${msg.r_message.thumbnail}`}
                      url={`https://ciity-sms.s3.us-west-1.amazonaws.com/${msg.r_message.url}`}
                      name={msg.r_message.url ? msg.r_message.url : ' '}
                    />
                    {msg.r_message.body && <Typography sx={{ fontSize: 16 }}>{msg.r_message.body}</Typography>}
                  </Paper>
                ) : (
                  <Box sx={{ position: 'relative', mb: 2 }}>
                    <Paper
                      sx={{
                        p: 1.25,

                        bgcolor: 'background.paper',

                        borderLeft: '4px solid #ffbf00',
                      }}
                    >
                      <Typography sx={{ fontSize: 16,whiteSpace: 'pre-wrap'  }}>{msg.r_message.body}</Typography>
                    </Paper>
                  </Box>
                )}
              </Box>
            )}
        <p style={{ whiteSpace: 'pre-wrap' }}>{msg.body}</p>
      </MessageBubble>
      <Popover
        id={`${msg.id}-popover`}
        open={openThree}
        anchorEl={anchorEl}
        onClose={handleClose}
        anchorOrigin={{
          vertical: 'bottom',
          horizontal: 'left',
        }}
      >
        <List disablePadding>
          <ListItem disablePadding>
            <ListItemButton
              onClick={() => {
                setSelectedMessageToReply(msg);
                setAnchorEl(null)
              }}
            >
              <ListItemIcon>
                <Reply />
              </ListItemIcon>
              <ListItemText primary="Reply" />
            </ListItemButton>
          </ListItem>
          <Divider />
          <ListItem disablePadding>
            <ListItemButton
              onClick={() => {
                socket.emit('pin_message', {
                  messageId: msg.id,
                  value: selectedContact.isCreatedBy
                    ? msg.staffPin == '0'
                      ? '1'
                      : '0'
                    : msg.driverPin == '0'
                      ? '1'
                      : '0',
                  type: selectedContact.isCreatedBy ? 'staff' : 'driver',
                });
              }}
            >
              <ListItemIcon>
                <PushPin />
              </ListItemIcon>
              <ListItemText
                primary={
                  selectedContact.isCreatedBy
                    ? msg.staffPin == '1'
                      ? 'UnPin Message'
                      : 'Pin Message'
                    : msg.driverPin == '1'
                      ? 'UnPin Message'
                      : 'Pin Message'
                }
              />
            </ListItemButton>
          </ListItem>
          <Divider />
          {msg.deliveryStatus == 'sent' && selectedContact.id != msg.senderId && (
            <ListItem disablePadding>
              <ListItemButton
                onClick={() => {
                  socket.emit('delete_message', { messageId: msg.id });
                }}
              >
                <ListItemIcon>
                  <Delete color="error" />
                </ListItemIcon>
                <ListItemText primary="Delete" sx={{ color: 'red' }} />
              </ListItemButton>
            </ListItem>
          )}
        </List>
      </Popover>
    </>
  );
}
