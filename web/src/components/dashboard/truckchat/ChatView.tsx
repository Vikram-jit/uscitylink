'use client';

import React from 'react';
import { Box, Paper, Typography, useMediaQuery, useTheme } from '@mui/material';

import GroupDetail from '../truckgroup/component/GroupDetail';
import { ChatHeader } from './ChatHeader';
import { ChatSidebar } from './ChatSidebar';
import { MessageInput } from './MessageInput';
import { MessagesList } from './MessagesList';
import { ChatViewProps } from './types';
import { set } from 'react-hook-form';
import MediaPane from '@/components/messages/MediaPane';

export const ChatView: React.FC<ChatViewProps> = ({
  currentUser,
  messages,
  message,
  setMessage,
  onSelectChat,
  onSendMessage,
  isLoading,
  trucks,
  error,
  hasMoreMessage,
  loadMoreGroupMessages,
  messageLoader = false,
  handleReset,
  viewMedia,
currentChatId,
  setViewMedia,
  isBack = false,
  viewDetailGroup,
  setViewDetailGroup,
  setCurrentChatId,
  setGroups,
  handleFileChange,
  handleFileChangeVedio,
  handleVedioClick,
  loadMoreMessages,
  hasMore,
  selectedTemplate,
  setSelectedTemplate,
  search,
  setSearch,
  setSelectedGroup,
  setPage
}) => {
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down('md'));
  const [sidebarOpen, setSidebarOpen] = React.useState(!isMobile);

  return (
    <Box
      sx={{
        display: 'flex',
        height: '90vh',
        bgcolor: 'background.default',
      }}
    >
      {/* Sidebar - hidden on mobile when chat is open */}
      {(sidebarOpen || !currentUser) && (
        <ChatSidebar
        setPage={setPage}
          loadMoreMessages={loadMoreMessages}
          hasMore={hasMore}
          search={search}
          setSearch={setSearch}
          setSelectedGroup={setSelectedGroup}
          setGroups={setGroups as any}
          chats={trucks || []}
          currentUser={currentUser}
          currentChatId={currentUser?.group?.id}
          onSelectChat={(chatId) => {
            onSelectChat(chatId);
            if (isMobile) setSidebarOpen(false);
          }}
        />
      )}

      {/* Main chat area */}
      {currentUser && (
        <Box
          sx={{
            display: 'flex',
            flexDirection: 'column',
            flex: 1,
          }}
        >
          <ChatHeader
            handleReset={handleReset}
            group={currentUser}
            setViewDetailGroup={setViewDetailGroup}
            isBack={viewDetailGroup}
            setViewMedia={setViewMedia}
            viewMedia={viewMedia}
          />

          {viewDetailGroup ? (
            <GroupDetail
              type={'truck'}
              group={currentUser}
              setGroups={setGroups as any}
              setViewDetailGroup={setViewDetailGroup}
              setSelectedGroup={setCurrentChatId as any}
            />
          ) : (
           viewMedia ?  <MediaPane userId={currentChatId} source="group" channelId={currentChatId} /> : <MessagesList
              messages={messages || []}
              hasMoreMessage={hasMoreMessage}
              loadMoreGroupMessages={loadMoreGroupMessages}
              messageLoader={messageLoader}
              isLoading={isLoading}
              error={error}
            />
          )}

          {!viewDetailGroup && (
            <Paper elevation={3}>
              <MessageInput
                selectedTemplate={selectedTemplate}
                setSelectedTemplate={setSelectedTemplate}
                message={message}
                setMessage={setMessage}
                handleFileChangeVedio={handleFileChangeVedio}
                onSend={onSendMessage}
                // handleVedioClick={handleVedioClick}
                handleFileChange={handleFileChange}
                //   disabled={currentChat}
              />
            </Paper>
          )}
        </Box>
      )}

      {/* Empty state when no chat is selected */}
      {!currentUser && messages.length === 0 && (
        <Box
          sx={{
            flex: 1,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
          }}
        >
          <Typography variant="h6" color="text.secondary">
            No chats available
          </Typography>
        </Box>
      )}
    </Box>
  );
};
