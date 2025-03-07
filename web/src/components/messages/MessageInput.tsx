import * as React from 'react';
import { useFileUploadMutation, useVideoUploadMutation } from '@/redux/MessageApiSlice';
import { hideLoader, showLoader } from '@/redux/slices/loaderSlice';
import { AttachFile } from '@mui/icons-material';
import SendRoundedIcon from '@mui/icons-material/SendRounded';
import { CircularProgress, Dialog, DialogActions, DialogContent, DialogTitle, IconButton } from '@mui/material';
import Box from '@mui/material/Box';
import Button from '@mui/material/Button';
import Stack from '@mui/material/Stack';
import TextField from '@mui/material/TextField';
import ReactPlayer from 'react-player';
import { useDispatch } from 'react-redux';

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
  const [fileUpload, { isLoading }] = useFileUploadMutation();
  const [videoUpload, { isLoading:videoLoader }] = useVideoUploadMutation();
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
    const selectedFile = event.target.files[0];
    if (selectedFile) {
      setFile(selectedFile);
      setPreviewDialogOpen(true);
    }
  };

  React.useEffect(() => {
    if (props.selectedTemplate) {
      props.setTextAreaValue(props.selectedTemplate?.body);
      setUrl(props.selectedTemplate.url ?? '');
    }
  }, [props.selectedTemplate]);

  const handleIconClick = () => {
    document?.getElementById('file-input')?.click();
  };

  const handleCancel = () => {
    setPreviewDialogOpen(false);
    setFile(null);
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
      formData.append('source', "message");
      formData.append('type', file.type.startsWith('image/') ? 'media' : 'doc');
      const res = videoExtensions.includes(extension) ? await videoUpload({formData,userId:props.userId,groupId:null}).unwrap() : await fileUpload(formData).unwrap();
      if (res.status) {
        socket.emit('send_message_to_user', {
          body: caption,
          userId: props.userId,
          direction: 'S',
          url: res?.data?.key,
          thumbnail:res?.data?.thumbnail
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
              <input
                id="file-input"
                type="file"
                style={{ display: 'none' }} // Hide the input element
                onChange={handleFileChange} // Handle file selection
              />
              <IconButton onClick={handleIconClick}>
                <AttachFile />
              </IconButton>
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
        <Dialog open={previewDialogOpen} onClose={handleCancel} fullWidth>
          <DialogTitle>Selected File</DialogTitle>
          <DialogContent>
            <div style={{ display: 'flex', flexDirection: 'column', alignContent: 'center' }}>
              {/* Render file preview */}
              {renderFilePreview()}

              {/* Input for file description */}
              <TextField
                fullWidth
                placeholder="Enter file description..."
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
            <Button disabled={isLoading} onClick={sendMessage} color="primary">
              Send {isLoading && <CircularProgress />}
            </Button>
          </DialogActions>
        </Dialog>
      )}
    </Box>
  );
}
