"use client"
import React from 'react';
import { Paper, Typography, styled } from '@mui/material';
import { Message } from './types';
import { MessageModel } from '@/redux/models/MessageModel';

interface ChatMessageProps {
  message: MessageModel;
  isCurrentUser: boolean;
  showTime?: boolean;
}

const MessageBubble = styled(Paper, {
  shouldForwardProp: (prop) => prop !== 'isCurrentUser',
})<{ isCurrentUser: boolean }>(({ theme, isCurrentUser }) => ({
  maxWidth: '70%',
  padding: theme.spacing(1, 2),
  marginLeft: isCurrentUser ? 'auto' : theme.spacing(1),
  marginRight: isCurrentUser ? theme.spacing(1) : 'auto',
  backgroundColor: isCurrentUser 
    ? theme.palette.primary.main 
    : theme.palette.grey[200],
  color: isCurrentUser 
    ? theme.palette.primary.contrastText 
    : theme.palette.text.primary,
  borderRadius: isCurrentUser
    ? '18px 18px 0 18px'
    : '18px 18px 18px 0',
  wordBreak: 'break-word',
}));

export const ChatMessage: React.FC<ChatMessageProps> = ({ 
  message, 
  isCurrentUser,
  showTime = true 
}) => {
  return (
    <div style={{ 
      display: 'flex', 
      flexDirection: 'column',
      alignItems: isCurrentUser ? 'flex-end' : 'flex-start',
      marginBottom: 16,
      width: '100%'
    }}>
      <MessageBubble elevation={0} isCurrentUser={isCurrentUser}>
        <Typography variant="body1">{message.body}</Typography>
      </MessageBubble>
      {showTime && (
        <Typography 
          variant="caption" 
          color="text.secondary"
          sx={{ mt: 0.5 }}
        >
          {message.messageTimestampUtc}
          {isCurrentUser && message.status && (
            <span style={{ marginLeft: 8 }}>
              {message.status === 'read' ? '✓✓' : message.status === 'delivered' ? '✓' : ''}
            </span>
          )}
        </Typography>
      )}
    </div>
  );
};