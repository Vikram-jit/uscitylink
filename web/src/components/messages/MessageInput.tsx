import * as React from 'react';
import { useFileUploadMutation, useUploadMultipleFilesMutation, useVideoUploadMutation } from '@/redux/MessageApiSlice';
import { hideLoader, showLoader } from '@/redux/slices/loaderSlice';
import { AttachFile, Attachment } from '@mui/icons-material';
import SendRoundedIcon from '@mui/icons-material/SendRounded';
import {
  CircularProgress,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  Divider,
  IconButton,
  List,
  ListItem,
  ListItemButton,
  ListItemIcon,
  ListItemText,
  Popover,
} from '@mui/material';
import Box from '@mui/material/Box';
import Button from '@mui/material/Button';
import Stack from '@mui/material/Stack';
import TextField from '@mui/material/TextField';
import ImageGallery from 'react-image-gallery';
import ReactPlayer from 'react-player';
import { useDispatch } from 'react-redux';

import 'react-image-gallery/styles/css/image-gallery.css';

import { File, Video } from '@phosphor-icons/react';

import { useSocket } from '@/lib/socketProvider';

import MediaComponent from './MediaComment';

export type MessageInputProps = {
  textAreaValue: string;
  setTextAreaValue: (value: string) => void;
  onSubmit: () => void;
  userId: string;
  isTyping: boolean;
  selectedTemplate: { name: string; body: string; url?: string };
};

export default function MessageInput(props: MessageInputProps) {
  const [anchorEl, setAnchorEl] = React.useState<HTMLButtonElement | null>(null);

  const attachmenPopOver = (event: React.MouseEvent<HTMLButtonElement>) => {
    setAnchorEl(event.currentTarget);
  };

  const handleClose = () => {
    setAnchorEl(null);
  };
  const open = Boolean(anchorEl);

  const [fileUpload, { isLoading }] = useFileUploadMutation();
  const [uploadMultipleFiles, { isLoading: multipleLoader }] = useUploadMultipleFilesMutation();
  const [videoUpload, { isLoading: videoLoader }] = useVideoUploadMutation();
  const { socket } = useSocket();
  const { textAreaValue, setTextAreaValue, onSubmit } = props;
  const [caption, setCaption] = React.useState('');
  const dispatch = useDispatch();
  const [isTyping, setIsTyping] = React.useState<boolean>(false);
  const [typingStartTime, setTypingStartTime] = React.useState<number>(0);
  const [userTyping, setUserTyping] = React.useState<boolean>(false);
  const [userTypingMessage, setUserTypingMessage] = React.useState<string>('');
  const [url, setUrl] = React.useState<string>('');

  const handleClick = () => {
    if (textAreaValue.trim() !== '') {
      onSubmit();
      setTextAreaValue('');
      setUrl('');
    }
  };
  const [file, setFile] = React.useState<any>(null);
  const [files, setFiles] = React.useState<any>([]);
  const [previewDialogOpen, setPreviewDialogOpen] = React.useState(false);

  React.useEffect(() => {
    if (socket) {
      socket.on('typingUser', (data: any) => {
        if (data.userId == props.userId) {
          if (data?.isTyping) {
            setUserTyping(data?.isTyping);
            setUserTypingMessage(data?.message);
          } else {
            setUserTyping(data?.isTyping);
            setUserTypingMessage('');
          }
        }
      });
    }
  }, [socket, props.userId]);

  // Handle the file input change event
  const handleFileChange = (event: any) => {
    //console.log(event.target.files)
    const selectedFile = event.target.files[0];
    if (selectedFile) {
      //setFile(selectedFile);
      const selectedFiles = Array.from(event.target.files);
      setFiles(selectedFiles);
      setPreviewDialogOpen(true);
    }
  };

  const handleFileChangeVedio = (event: any) => {
    //console.log(event.target.files)
    const selectedFile = event.target.files[0];
    if (selectedFile) {
      setFile(selectedFile);
      //   const selectedFiles = Array.from(event.target.files);
      //  setFiles(selectedFiles);
      setPreviewDialogOpen(true);
    }
  };
  React.useEffect(() => {
    // Cleanup function to revoke object URLs
    return () => {
      files.forEach((file: any) => URL.revokeObjectURL(file.preview));
    };
  }, [files]);

  React.useEffect(() => {
    if (props.selectedTemplate) {
      props.setTextAreaValue(props.selectedTemplate?.body);
      setUrl(props.selectedTemplate.url ?? '');
    }
  }, [props.selectedTemplate]);

  const handleIconClick = () => {
    document?.getElementById('file-input')?.click();
  };
  const handleVedioClick = () => {
    document?.getElementById('file-input-vedio')?.click();
  };

  const handleCancel = () => {
    setPreviewDialogOpen(false);
    setFile(null);
    setFiles([]);
  };

  const renderFilePreview = () => {
    const extension = file.name?.split('.')[file.name?.split('.').length - 1];

    const videoExtensions = ['mp4', 'mkv', 'avi', 'mov', 'flv', 'webm', 'mpeg', 'mpg', 'wmv'];
    if (file && file.type.startsWith('image/')) {
      // Display image preview for images
      return (
        <img
          src={URL.createObjectURL(file)}
          alt="Preview"
          style={{ maxWidth: '100%', maxHeight: 300, objectFit: 'contain' }}
        />
      );
    } else if (file && file.type === 'application/pdf') {
      // Display placeholder for PDF files
      return <div>PDF Preview (placeholder)</div>;
    } else if (videoExtensions.includes(extension)) {
      return <ReactPlayer height={200} width={500} url={URL.createObjectURL(file)} controls={true} />;
    } else {
      return <div>File Preview Not Available</div>;
    }
  };

 

  async function sendMessage() {
    try {
      const extension = file.name?.split('.')[file.name?.split('.').length - 1];

      const videoExtensions = ['mp4', 'mkv', 'avi', 'mov', 'flv', 'webm', 'mpeg', 'mpg', 'wmv'];

      dispatch(showLoader());
      let formData = new FormData();
      formData.append('file', file);
      formData.append('userId', props.userId);
      formData.append('source', 'message');
      formData.append('type', file.type.startsWith('image/') ? 'media' : 'doc');
      const res = videoExtensions.includes(extension)
        ? await videoUpload({ formData, userId: props.userId, groupId: null }).unwrap()
        : await fileUpload(formData).unwrap();
      if (res.status) {
        socket.emit('send_message_to_user', {
          body: caption,
          userId: props.userId,
          direction: 'S',
          url: res?.data?.key,
          thumbnail: res?.data?.thumbnail,
        });
        setFile(null);
        setCaption('');
        setPreviewDialogOpen(false);
        dispatch(hideLoader());
      }
      dispatch(hideLoader());
      console.log(res);
    } catch (error) {
      dispatch(hideLoader());
      console.log(error);
    }
  }

  async function sendFiles() {
    try {
      dispatch(showLoader());

      let formData = new FormData();

      formData.append('body', caption);
      formData.append('type', '');
      formData.append('channelId', '');
      //  formData.append("files",files)

      for (const file of files) {
        formData.append('files', file, file.name);
      }

      const res = await uploadMultipleFiles({
        formData: formData,
        userId: props.userId,
        groupId: '',
        location: 'message',
        source: 'message',
        uploadBy: 'staff',
      }).unwrap();
      if (res?.status) {
        setFiles([]);
        setCaption('');
        setPreviewDialogOpen(false);
        dispatch(hideLoader());
      }
      dispatch(hideLoader());
      console.log(res);
    } catch (error) {
      dispatch(hideLoader());
      console.log(error);
    }
  }

  const handleKeyDown = () => {
    if (!isTyping) {
      setIsTyping(true); // Mark the user as typing
      sendTypingStatus(true); // Notify the server that the user is typing
    }
    setTypingStartTime(Date.now()); // Record the time the user started typing
  };

  // Function to check if the user has stopped typing
  const checkIfTypingStopped = () => {
    if (isTyping && Date.now() - typingStartTime > 1500) {
      setIsTyping(false);
      sendTypingStatus(false);
    }
  };

  React.useEffect(() => {
    const interval = setInterval(() => {
      checkIfTypingStopped();
    }, 500); // Check every 500ms

    return () => {
      clearInterval(interval);
    };
  }, [isTyping, typingStartTime]);

  const sendTypingStatus = (isTyping: Boolean) => {
    socket.emit('typing', { isTyping: isTyping, userId: props.userId });
  };

  return (
    <Box sx={{ px: 2, pb: 3 }}>
      {userTyping && (
        <div style={{ display: 'flex', justifyContent: 'start', marginBottom: '5px', marginRight: '10px' }}>
          {userTypingMessage ?? 'Typing...'}
        </div>
      )}
      <TextField
        fullWidth
        placeholder="Type something here…"
        aria-label="Message"
        multiline
        maxRows={10}
        value={textAreaValue}
        onChange={(event) => {
          setTextAreaValue(event.target.value);
        }}
        InputProps={{
          endAdornment: (
            <Stack
              direction="row"
              sx={{
                justifyContent: 'space-between',
                alignItems: 'center',
                flexGrow: 1,
                py: 1,
                pr: 1,
              }}
            >
              <input id="file-input" type="file" multiple style={{ display: 'none' }} onChange={handleFileChange} />

              <input
                id="file-input-vedio"
                type="file"
                accept="video/*"
                style={{ display: 'none' }}
                onChange={handleFileChangeVedio}
              />

              <IconButton onClick={attachmenPopOver}>
                <AttachFile />
              </IconButton>
              <Popover
                id={`attachment-popover`}
                open={open}
                anchorEl={anchorEl}
                onClose={handleClose}
                anchorOrigin={{
                  vertical: 'bottom',
                  horizontal: 'left',
                }}
              >
                <List disablePadding>
                  <ListItem disablePadding>
                    <ListItemButton onClick={handleIconClick}>
                      <ListItemIcon>
                        <File />
                      </ListItemIcon>
                      <ListItemText primary="Media/Docs" />
                    </ListItemButton>
                  </ListItem>
                  <Divider />
                  <ListItem disablePadding>
                    <ListItemButton onClick={handleVedioClick}>
                      <ListItemIcon>
                        <Video />
                      </ListItemIcon>
                      <ListItemText primary={'Video'} />
                    </ListItemButton>
                  </ListItem>
                  <Divider />
                </List>
              </Popover>
              <Button
                disabled={isLoading}
                size="small"
                color="primary"
                onClick={handleClick}
                endIcon={<SendRoundedIcon />}
              >
                Send
              </Button>
            </Stack>
          ),
        }}
        onKeyDown={(event) => {
          if (event.key === 'Enter' && (event.metaKey || event.ctrlKey)) {
            handleClick();
          }
          handleKeyDown();
        }}
        sx={{
          '& .MuiOutlinedInput-root': {
            minHeight: 50,
          },
        }}
      />
      {url && (
        <MediaComponent
          url={`https://ciity-sms.s3.us-west-1.amazonaws.com/${url}`}
          name={url ?? ''}
          width={100}
          height={100}
        />
      )}
      {previewDialogOpen && (
        <Dialog fullWidth open={previewDialogOpen} onClose={handleCancel}>
          <DialogTitle>Selected Files</DialogTitle>
          <DialogContent>
            <div style={{ display: 'flex', flexDirection: 'column', alignContent: 'center' }}>
              {files.length > 0 ? <MediaGallery mediaFiles={files} /> : renderFilePreview()}

              <TextField
                fullWidth
                placeholder="Enter caption..."
                multiline
                value={caption}
                onChange={(event) => setCaption(event.target.value)}
                sx={{ marginTop: 2 }}
              />
            </div>
          </DialogContent>
          <DialogActions>
            <Button onClick={handleCancel} color="secondary">
              Cancel
            </Button>
            <Button disabled={isLoading} onClick={files.length ? sendFiles : sendMessage} color="primary">
              Send {isLoading && <CircularProgress />}
            </Button>
          </DialogActions>
        </Dialog>
      )}
    </Box>
  );
}

const MediaGallery = ({ mediaFiles }: any) => {
  const galleryItems = mediaFiles.map((file: any) => {
    const objectUrl = URL.createObjectURL(file);
    const extension = file.name.split('.').pop().toLowerCase();
    const isVideo = ['mp4', 'mkv', 'avi', 'mov', 'flv', 'webm', 'mpeg', 'mpg', 'wmv'].includes(extension);
    const isPDF = extension === 'pdf';

    return {
      original: objectUrl,
      thumbnail: objectUrl,
      renderItem: () =>
        isVideo ? (
          <video controls style={{ width: '100%', height: '75vh' }}>
            <source src={objectUrl} type={file.type} />
            Your browser does not support the video tag.
          </video>
        ) : isPDF ? (
          <iframe src={objectUrl} title={file.name} style={{ width: '100%', height: '75vh' }} />
        ) : (
          <img src={objectUrl} alt={file.name} style={{ height: '75vh' }} />
        ),
    };
  });

  return <ImageGallery items={galleryItems} showThumbnails={false} />;
};
