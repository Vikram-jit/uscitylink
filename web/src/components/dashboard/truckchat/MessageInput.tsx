"use client";
import React, { useState } from 'react';
import { 
  TextField, 
  IconButton, 
  Box,
  InputAdornment,
  CircularProgress,
  Divider,
  List,
  ListItem,
  ListItemButton,
  ListItemIcon,
  ListItemText,
  Menu,
  MenuItem,
  Popover,
  styled
} from '@mui/material';
import { Send, InsertEmoticon, AttachFile, Mic, Add } from '@mui/icons-material';
import { File, PaperPlane, Video } from '@phosphor-icons/react';
import { FiSend } from 'react-icons/fi';
import TemplateDialog from '../template/TemplateDialog';

interface MessageInputProps {
  onSend: (message: string) => void;
  placeholder?: string;
  showEmojiButton?: boolean;
  showAttachmentButton?: boolean;
  showVoiceButton?: boolean;
  handleFileChange?: (event: React.ChangeEvent<HTMLInputElement>) => void;
  handleFileChangeVedio?: (event: React.ChangeEvent<HTMLInputElement>) => void;
  selectedTemplate?: { name: string; body: string; url?: string };
  setSelectedTemplate?: React.Dispatch<React.SetStateAction<{ name: string; body:   string; url?: string }>>;
  message: string;
  setMessage: React.Dispatch<React.SetStateAction<string>>;
}
const InputContainer = styled(Box)({
  padding: '10px 20px',
  backgroundColor: '#f0f2f5',
  display: 'flex',
  alignItems: 'center',
  gap: '10px',
});

export const MessageInput: React.FC<MessageInputProps> = ({ 
  onSend,
  handleFileChange,
    handleFileChangeVedio,
  placeholder = "Type a message",
  showEmojiButton = true,
  showAttachmentButton = true,
  showVoiceButton = true,
  setSelectedTemplate,
  selectedTemplate,
  message,
    setMessage
}) => {
 const handleVedioClick = () => {
    document?.getElementById('file-input-vedio')?.click();
  };
    const [templateDialog, setTemplateDialog] = React.useState<boolean>(false);
      const [anchorEl, setAnchorEl] = React.useState<null | HTMLElement>(null);
        const [open, setOpen] = useState<boolean>(false);
      
  
  const openTemplate = Boolean(anchorEl);

  const handleSend = () => {
    if (message.trim()) {
      onSend(message);
      setMessage('');
    }
  };


const handleClose = () => {
    setAnchorEl(null);
  };
    const handleIconClick = () => {
    document?.getElementById('file-input')?.click(); // Trigger the click event of the hidden file input
  };
  const handleClick = (event: React.MouseEvent<HTMLElement>) => {
      setAnchorEl(event.currentTarget);
    };
      const [anchorElPopOver, setAnchorElPopOver] = React.useState<HTMLButtonElement | null>(null);
    
      const attachmenPopOver = (event: React.MouseEvent<HTMLButtonElement>) => {
        setAnchorElPopOver(event.currentTarget);
      };
    
      const handleClosePopOver = () => {
        setAnchorElPopOver(null);
      };
  
const openPopOver = Boolean(anchorElPopOver);

  return (
     <InputContainer>
                    <IconButton
                      onClick={handleClick}
                      size="small"
                      sx={{ ml: 2 }}
                      aria-controls={open ? 'account-menu' : undefined}
                      aria-haspopup="true"
                      aria-expanded={open ? 'true' : undefined}
                    >
                      <Add />
                    </IconButton>
                    <Menu
                      anchorEl={anchorEl}
                      id="account-menu"
                      open={openTemplate}
                      onClose={handleClose}
                      onClick={handleClose}
                      slotProps={{
                        paper: {
                          elevation: 0,
                          sx: {
                            overflow: 'visible',
                            filter: 'drop-shadow(0px 2px 8px rgba(0,0,0,0.32))',
                            mt: 1.5,
                            '& .MuiAvatar-root': {
                              width: 32,
                              height: 32,
                              ml: -0.5,
                              mr: 1,
                            },
                            '&::before': {
                              content: '""',
                              display: 'block',
                              position: 'absolute',
                              top: 0,
                              right: 14,
                              width: 10,
                              height: 10,
                              bgcolor: 'background.paper',
                              transform: 'translateY(-50%) rotate(45deg)',
                              zIndex: 0,
                            },
                          },
                        },
                      }}
                      transformOrigin={{ horizontal: 'right', vertical: 'top' }}
                      anchorOrigin={{ horizontal: 'right', vertical: 'bottom' }}
                    >
                      <MenuItem onClick={() => setTemplateDialog(true)}>
                        <ListItemIcon>
                          <PaperPlane fontSize="small" />
                        </ListItemIcon>
                        Templates
                      </MenuItem>
                    </Menu>
                    {templateDialog && (
                      <TemplateDialog
                        open={templateDialog}
                        setOpen={setTemplateDialog}
                        setSelectedTemplate={setSelectedTemplate as any}
                      />
                    )}
                    <input
                      id="file-input-vedio"
                      type="file"
                      accept="video/*"
                      style={{ display: 'none' }}
                      onChange={handleFileChangeVedio}
                    />
                    <input
                      multiple
                      id="file-input"
                      type="file"
                      style={{ display: 'none' }} // Hide the input element
                      onChange={handleFileChange} // Handle file selection
                    />
                    <IconButton onClick={attachmenPopOver}>
                      <AttachFile />
                    </IconButton>
                    <Popover
                      id={`attachment-popover`}
                      open={openPopOver}
                      anchorEl={anchorElPopOver}
                      onClose={handleClosePopOver}
                      // anchorOrigin={{
                      //   vertical: 'bottom',
                      //   horizontal: 'left',
                      // }}
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
                    <TextField
                      fullWidth
                      placeholder="Type a message"
                      variant="outlined"
                      size="small"
                      value={message}
                      onChange={(e) => setMessage(e.target.value)}
                      multiline
                      maxRows={10}
                    />
                    <IconButton onClick={()=>{
                        onSend(message)
                    }} >
                     <FiSend />
                    </IconButton>
                  </InputContainer>
  );
};