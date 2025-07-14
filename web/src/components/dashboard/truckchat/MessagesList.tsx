'use client';

import React, { useEffect, useRef } from 'react';
import { MessageModel } from '@/redux/models/MessageModel';
import { Box, CircularProgress, Divider, List, Stack, Typography } from '@mui/material';
import moment from 'moment';
import InfiniteScroll from 'react-infinite-scroll-component';

import AvatarWithStatus from '@/components/messages/AvatarWithStatus';
import ChatBubble from '@/components/messages/ChatBubble';
import DocumentDialog from '@/components/DocumentDialog';

interface MessagesListProps {
  messages: MessageModel[];
  isLoading?: boolean;
  error?: string;
   hasMoreMessage: boolean;
  loadMoreGroupMessages: () => void;
  messageLoader?: boolean;
}

export const MessagesList: React.FC<MessagesListProps> = ({ messages, isLoading, error ,hasMoreMessage,messageLoader,loadMoreGroupMessages}) => {
  const messagesEndRef = useRef<HTMLDivElement>(null);
  const scrollContainerRef = useRef<HTMLDivElement>(null);
  const [currentIndex, setCurrentIndex] = React.useState<number | null>(null);

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);
  useEffect(() => {
    if (scrollContainerRef.current && !hasMoreMessage) {
      scrollContainerRef.current.scrollTop = scrollContainerRef.current.scrollHeight;
    }
  }, []);


   const moveNext = () => {
    if (currentIndex != null) {
      // 1. If we’re already at the last possible index, nothing to do
      if (currentIndex >= messages.length - 1) {
        console.log('No more messages with media.');
        return;
      }

      // 2. Scan forward for the next message that has a non‐empty URL
      for (let i = currentIndex + 1; i < messages.length; i++) {
        const url = messages[i]?.url?.trim();
        if (url) {
          setCurrentIndex(i);
          console.log('Moved to:', messages[i]);
          return;
        }
      }

      console.log('No more messages with media.');
    }
  };

  // Move to the previous message with a URL
  const movePrevious = () => {
    if (currentIndex) {
      // If we're already at 0, nothing to do
      if (currentIndex <= 0) {
        console.log('Reached the beginning. No previous messages with media.');
        return;
      }

      // Walk backwards until we find a message.url
      for (let i = currentIndex - 1; i >= 0; i--) {
        if (messages[i].url?.trim()) {
          setCurrentIndex(i);
          console.log('Moved to:', messages[i]);
          return;
        }
      }

      console.log('Reached the beginning. No previous messages with media.');
    }
  };

  if (isLoading) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center', p: 4 }}>
        <CircularProgress />
      </Box>
    );
  }

  if (error) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center', p: 4 }}>
        <Typography color="error">{error}</Typography>
      </Box>
    );
  }


  return (
      <Box
      id="scrollable-messages-group-container"
      ref={scrollContainerRef}
      sx={{
        flex: 1,
        overflowY: 'auto',
        p: 2,
        display: 'flex',
        flexDirection: 'column-reverse', // Critical for inverse scroll
        height: '100%'
      }}
    >
      <List sx={{ width: '100%' }}>
        <InfiniteScroll
          style={{
            display: 'flex',
            flexDirection: 'column-reverse',
            gap: '10px',
            padding: '20px',
          }}
          // onScroll={handleScroll}
          dataLength={messages.length}
          next={loadMoreGroupMessages}
          hasMore={hasMoreMessage}
          loader={<h4>Loading...</h4>} // Loader will be shown at the top when scrolling up
          scrollThreshold={0.95}
          scrollableTarget="scrollable-messages-group-container"
          inverse={true} // Load older messages on scroll up
        >
             {/* <div ref={messagesEndRef} /> */}
          {messages.map((message, index) => {
            const currentDate = moment.utc(message.messageTimestampUtc).format('MM-DD-YYYY');
            const previousDate =
              index > 0 ? moment.utc(messages?.[index - 1].messageTimestampUtc).format('MM-DD-YYYY') : null;
            const isDifferentDay = previousDate && currentDate !== previousDate;
            const isToday = currentDate === moment.utc().format('MM-DD-YYYY');
            const isYou = message.messageDirection === 'S';

            return (
              <React.Fragment key={message.id}>
                <Stack direction="row" spacing={2} sx={{ flexDirection: isYou ? 'row-reverse' : 'row' }}>
                  {message.messageDirection !== 'S' && (
                    <AvatarWithStatus online={message?.sender?.isOnline} src={'a'} />
                  )}
                  <ChatBubble
                    isVisibleThreeDot={false}
                    onClick={() => {
                      setCurrentIndex(index);
                    }}
                    truckNumbers=""
                    variant={isYou ? 'sent' : 'received'}
                    {...message}
                    attachment={false}
                    sender={message?.sender}
                  />
                </Stack>
                {isDifferentDay && <Divider>{isToday ? 'Today' : previousDate}</Divider>}
              </React.Fragment>
            );
          })}
         
        </InfiniteScroll>
      </List>
       {currentIndex != null && messages[currentIndex]?.url && (
              <DocumentDialog
                uploadType={messages[currentIndex].url_upload_type}
                open={currentIndex != null ? true : false}
                onClose={() => {
                  setCurrentIndex(null);
                }}
                documentKey={messages[currentIndex]?.url?.split('/')?.[1]}
                moveNext={movePrevious}
                movePrev={moveNext}
                currentIndex={currentIndex}
              />
            )}
    </Box>
  );
};
