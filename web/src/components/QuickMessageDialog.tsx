// QuickMessageDialog.tsx
import React, { useState } from 'react';
import { Dialog, DialogActions, DialogContent, DialogTitle, TextField, Button, Typography, Divider } from '@mui/material';
import { MessageModel } from '@/redux/models/MessageModel';
import { useQuickMessageMutation } from '@/redux/MessageApiSlice';
import { toast } from 'react-toastify';
import useErrorHandler from '@/hooks/use-error-handler';

interface QuickMessageDialogProps {
  open: boolean;
  message?:MessageModel
  userId?:string
  onClose: () => void;
  onSendMessage: (message: string) => void;
}

const QuickMessageDialog: React.FC<QuickMessageDialogProps> = ({ open, onClose, onSendMessage ,message}) => {
 const [body, setBody] = useState<string>('');

 const [quickMessage,{isLoading}] = useQuickMessageMutation()
    const [ ,setApiResponse] = useErrorHandler()
  const handleMessageChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    setBody(event.target.value);
  };

  const handleSendMessage = async() => {
        const res = await quickMessage({body,userProfileId:message?.userProfileId!})
        if(res.data?.status){
            toast.success(res?.data?.message)
            setBody(''); // Clear message input
            onClose(); // Close the dialog after sending
            return
        }
        setApiResponse(res.error as any)
  
  };

  const handleCancel = () => {
   setBody(''); // Clear message input if canceled
    onClose();
  };

  return (
    <Dialog fullWidth open={open} onClose={handleCancel}>
      <DialogTitle>{message ? <Typography> <Typography component={"span"} variant='h6' sx={{fontWeight:700}}>Reply to:</Typography> {message?.sender?.username} ({message?.sender?.user?.driver_number})</Typography>  :"Quick Message"}</DialogTitle>
      <Divider/>
      <DialogContent>
      {message && <Typography  sx={{fontWeight:700,}} variant='h6'>Recieved Message</Typography>}
        {message && <Typography style={{marginTop:2}}>{message.body}</Typography>}
        {/* {message && <Typography  sx={{fontWeight:700,marginTop:5}} variant='h6'>Message</Typography>} */}
        <TextField

          autoFocus
          margin="dense"
          label="Type your message"
          type="text"
          fullWidth
          variant="filled"
          value={body}
          onChange={handleMessageChange}
          multiline
          rows={4}
          sx={{borderRadius:0,marginTop:5}}
        />
      </DialogContent>
      <Divider></Divider>
      <DialogActions>
        <Button onClick={handleCancel} color="secondary">
          Cancel
        </Button>
        <Button onClick={handleSendMessage} color="primary">
          Send
        </Button>
      </DialogActions>
    </Dialog>
  );
};

export default QuickMessageDialog;
