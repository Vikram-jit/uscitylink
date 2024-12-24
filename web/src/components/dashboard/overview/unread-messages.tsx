import React, { useState } from 'react';
import { MessageModel } from '@/redux/models/MessageModel';
import { Avatar, Tooltip, Typography } from '@mui/material';
import Box from '@mui/material/Box';
import Button from '@mui/material/Button';
import Card from '@mui/material/Card';
import CardActions from '@mui/material/CardActions';
import CardHeader from '@mui/material/CardHeader';
import Divider from '@mui/material/Divider';
import IconButton from '@mui/material/IconButton';
import List from '@mui/material/List';
import ListItem from '@mui/material/ListItem';
import ListItemAvatar from '@mui/material/ListItemAvatar';
import ListItemText from '@mui/material/ListItemText';
import type { SxProps } from '@mui/material/styles';
import dayjs from 'dayjs';

import AvatarWithStatus from '@/components/messages/AvatarWithStatus';
import QuickMessageDialog from '@/components/QuickMessageDialog';

export interface LatestProductsProps {
  messages?: MessageModel[];
  sx?: SxProps;
}

export function UnreadMessage({ messages = [], sx }: LatestProductsProps): React.JSX.Element {
  const [quickMessage, setQuickMessage] = useState<boolean>(false);
  const [message, setMessage] = useState<MessageModel>();
  return (
    <Card sx={sx}>
      <CardHeader title="Unread Messages" />
      <Divider />
      {quickMessage && (
        <QuickMessageDialog
          open={quickMessage}
          message={message}
          onSendMessage={() => {}}
          onClose={() => {
            setQuickMessage(false);
            setMessage(undefined)
          }}
        />
      )}
      {messages.length == 0 ? (
        <Typography textAlign={'center'}>No Message</Typography>
      ) : (
        <List>
          {messages.map((message, index) => (
            <Tooltip title={`Click here to reply ${message?.sender?.username} (${message?.sender?.user?.driver_number})`}>
            <ListItem
              divider={index < messages.length - 1}
              key={message.id}
              onClick={() => {
                setMessage(message);
                setQuickMessage(true);
              }}
            >
              <ListItemAvatar>
                <AvatarWithStatus online={message?.sender?.isOnline} title={message?.sender?.username} />
              </ListItemAvatar>
              <ListItemText
                primary={message.body}
                primaryTypographyProps={{ variant: 'subtitle1' }}
                secondary={`${dayjs(message.updatedAt).format('MMM D, YYYY')} by ${message.sender?.username}(${message.sender?.user?.driver_number})`}
                secondaryTypographyProps={{ variant: 'body2' }}
              />
            </ListItem>
            </Tooltip>
          ))}
        </List>
      )}
      <Divider />
    </Card>
  );
}
