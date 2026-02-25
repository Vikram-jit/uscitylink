'use client';

import React, { useState } from 'react';
import { useGetChannelMembersQuery } from '@/redux/ChannelApiSlice';
import { useFileUploadMutation, useUploadMultipleFilesMutation, useVideoUploadMutation } from '@/redux/MessageApiSlice';
import { UserChannel } from '@/redux/models/ChannelModel';
import { hideLoader, showLoader } from '@/redux/slices/loaderSlice';
import AttachFileIcon from '@mui/icons-material/AttachFile';
import CheckBoxIcon from '@mui/icons-material/CheckBox';
import CheckBoxOutlineBlankIcon from '@mui/icons-material/CheckBoxOutlineBlank';
import SendIcon from '@mui/icons-material/Send';
import {
  Autocomplete,
  Box,
  Button,
  Card,
  CardContent,
  Checkbox,
  Chip,
  Divider,
  Stack,
  TextField,
  ToggleButton,
  ToggleButtonGroup,
  Typography,
} from '@mui/material';
import { useDispatch } from 'react-redux';
import { toast } from 'react-toastify';

import { useSocket } from '@/lib/socketProvider';

import TemplateDialog from '../template/TemplateDialog';
import ReactPlayer from 'react-player';
import MediaComponent from '@/components/messages/MediaComment';
import { apiSlice } from '@/redux/apiSlice';

const icon = <CheckBoxOutlineBlankIcon fontSize="small" />;
const checkedIcon = <CheckBoxIcon fontSize="small" />;

const MessageForm: React.FC = ({}) => {
  const [templateDialog, setTemplateDialog] = React.useState<boolean>(false);
  const [selectedTemplate, setSelectedTemplate] = React.useState<{ name: string; body: string; url?: string }>({
    name: '',
    body: '',
  });
    const [url, setUrl] = React.useState<string>('');
  
  const [selectedUsers, setSelectedUsers] = useState<UserChannel[]>([]);
  const [mode, setMode] = useState<'all' | 'specific'>('specific');
  const [message, setMessage] = useState('');
  const [media, setMedia] = useState<File | null>(null);
  const { data, isLoading } = useGetChannelMembersQuery({
    paginate: false,
    page: 1,
    pageSize: 10,
    search: '',
    type: 'user',
    unreadMessage: '0',
  });
  const { socket } = useSocket();
  const dispatch = useDispatch();

  const handleModeChange = (_: React.MouseEvent<HTMLElement>, newMode: 'all' | 'specific') => {
    if (!newMode) return;
    setMode(newMode);
    if (newMode === 'all') {
      setSelectedUsers(data?.data?.user_channels || []);
    } else {
      setSelectedUsers([]);
    }
  };
  const [fileUpload, {}] = useFileUploadMutation();
  const [uploadMultipleFiles, { isLoading: multipleLoader }] = useUploadMultipleFilesMutation();
  const [videoUpload, { isLoading: videoLoader }] = useVideoUploadMutation();
  const renderFilePreview = () => {
    const extension = media?.name?.split('.')[media.name?.split('.').length - 1];

    const videoExtensions = ['mp4', 'mkv', 'avi', 'mov', 'flv', 'webm', 'mpeg', 'mpg', 'wmv'];
    if (media && media.type.startsWith('image/')) {
      // Display image preview for images
      return (
        <img
          src={URL.createObjectURL(media)}
          alt="Preview"
          style={{ maxWidth: '100%', maxHeight: 200, objectFit: 'contain' }}
        />
      );
    } else if (media && media.type === 'application/pdf') {
      // Display placeholder for PDF files
      return <div>PDF Preview (placeholder)</div>;
    }else {
      return <div>File Preview Not Available</div>;
    }
  };

   React.useEffect(() => {
      if (selectedTemplate.name) {
        setMessage(selectedTemplate.body);
        setUrl(selectedTemplate.url ?? '');
      }
    }, [selectedTemplate]);
  
  const handleSend = async () => {
   
    if (media) {
      const extension = media.name?.split('.')[media.name?.split('.').length - 1];

      const videoExtensions = ['mp4', 'mkv', 'avi', 'mov', 'flv', 'webm', 'mpeg', 'mpg', 'wmv'];
      dispatch(showLoader());
      let formData = new FormData();
      formData.append('file', media);
      formData.append('isMultiple', true.toString());
      formData.append('userId', JSON.stringify(selectedUsers.map((user) => user.UserProfile.id)));
      formData.append('source', 'message');
      formData.append('type', media.type.startsWith('image/') ? 'media' : 'doc');
      try {
        const res = await fileUpload({ formData }).unwrap();
        if (res) {
          dispatch(hideLoader());
          socket.emit('broadcast_to_user', {
            body: message,
            userId: selectedUsers.map((user) => user.UserProfile.id),
            direction: 'S',
            url: res?.data?.key,
            thumbnail: res?.data?.thumbnail,
            url_upload_type: 'server',
          });
          setMessage('');
          setMedia(null);
          toast.success('Message sent successfully!');
          setSelectedUsers([]);
          dispatch(apiSlice.util.invalidateTags(['messages','media'])); // Invalidate messages and media cache to refetch updated data
        }
      } catch (error) {
        dispatch(hideLoader());
        console.error('File upload failed:', error);
        toast.error('Failed to upload media. Please try again.');
      }

      return;
    }
    socket.emit('broadcast_to_user', {
      body: message,
      userId: selectedUsers.map((user) => user.UserProfile.id),
      direction: 'S',
      ...(url ? { url, url_upload_type: 'server' } : {}),
    });
    setMessage('');
    toast.success('Message sent successfully!');
    setSelectedUsers([]);
    setUrl('');
    setSelectedTemplate({ name: '', body: '' ,url:''});
     dispatch(apiSlice.util.invalidateTags(['messages','media'])); // Invalidate messages and media cache to refetch updated data
  };

  return (
    <Card elevation={3} style={{ marginTop: 15, borderRadius: 6 }}>
      {templateDialog && (
        <TemplateDialog open={templateDialog} setOpen={setTemplateDialog} setSelectedTemplate={setSelectedTemplate} />
      )}

      <CardContent>
        <Stack spacing={3}>
          {/* Toggle */}
          <ToggleButtonGroup value={mode} exclusive onChange={handleModeChange} fullWidth>
            <ToggleButton value="specific">Specific Drivers</ToggleButton>
            <ToggleButton value="all">All Drivers</ToggleButton>
          </ToggleButtonGroup>

          {/* Driver Select */}
          {mode === 'specific' && (
            <Autocomplete
              multiple
              value={selectedUsers}
              options={data?.data?.user_channels || []}
              disableCloseOnSelect
              loading={isLoading}
              onChange={(_, value) => setSelectedUsers(value)}
              isOptionEqualToValue={(option, value) => String(option.id) === String(value.id)}
              getOptionLabel={(option) =>
                `${option.UserProfile.username} (${option.UserProfile.user.driver_number || ''})`
              }
              filterSelectedOptions
              renderOption={(props, option, { selected }) => (
                <li {...props} key={option.id}>
                  <Checkbox icon={icon} checkedIcon={checkedIcon} checked={selected} />
                  {option.UserProfile.username} ({option.UserProfile.user.driver_number || ''})
                </li>
              )}
              renderTags={(value, getTagProps) =>
                value.map((option, index) => (
                  <Chip
                    {...getTagProps({ index })}
                    key={option.id}
                    label={`${option.UserProfile.username} (${option.UserProfile.user.driver_number || ''})`}
                  />
                ))
              }
              renderInput={(params) => <TextField {...params} label="Select Drivers" placeholder="Search drivers..." />}
              fullWidth
            />
          )}

          <Divider />

          {/* Message */}
          <TextField
            multiline
            minRows={4}
            label="Message"
            value={message}
            onChange={(e) => setMessage(e.target.value)}
            fullWidth
          />

          {/* Attachment */}
          <Box display="flex" alignItems="center" gap={2}>
            <Button variant="outlined" component="label" startIcon={<AttachFileIcon />}>
              Attach Media
              <input hidden type="file" onChange={(e) => setMedia(e.target.files ? e.target.files[0] : null)} />
            </Button>
            <Button
              variant="outlined"
              component="label"
              startIcon={<AttachFileIcon />}
              onClick={() => setTemplateDialog(true)}
            >
              Attach Template
            </Button>
            {media && (
              <Typography variant="body2" color="text.secondary">
                {media.name}
              </Typography>
            )}
          </Box>
          {media && renderFilePreview()}
           {url && (
                  <MediaComponent
                    url={`https://ciity-sms.s3.us-west-1.amazonaws.com/${url}`}
                    name={url ?? ''}
                    width={100}
                    height={100}
                  />
                )}
          {/* Send Button */}
          <Box textAlign="right">
            <Button
              variant="contained"
              endIcon={<SendIcon />}
              onClick={handleSend}
              disabled={(mode === 'specific' && selectedUsers.length === 0) || message.trim() === ''}
            >
              Send Message
            </Button>
          </Box>
        </Stack>
      </CardContent>
    </Card>
  );
};

export default MessageForm;
