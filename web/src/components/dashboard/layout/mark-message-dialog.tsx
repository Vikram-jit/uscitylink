// components/EmailVerificationDialog.tsx

"use client";

import React, { SetStateAction, useState } from "react";
import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  TextField,
  Typography,
  Box,
  IconButton,
  Slide,
} from "@mui/material";
import EmailIcon from "@mui/icons-material/Email";
import VerifiedIcon from "@mui/icons-material/Verified";
import CloseIcon from "@mui/icons-material/Close";
import { TransitionProps } from "@mui/material/transitions";

const Transition = React.forwardRef(function Transition(
  props: TransitionProps & { children: React.ReactElement },
  ref: React.Ref<unknown>
) {
  return <Slide direction="up" ref={ref} {...props} />;
});

interface MarkMessageDialogProps {
  
  open: boolean;
  onClose: () => void;

  onSendOtp: () => void;
  
  loader:boolean
 
}

const MarkMessageDialog: React.FC<MarkMessageDialogProps> = ({
   
  open,
  onClose,
  
  onSendOtp,
 
  loader,
 
}) => {

 

  const handleSendOtp = () => {
    onSendOtp();
    // setOtpSent(true);
  };



  return (
    <Dialog
      open={open}
      TransitionComponent={Transition}
      keepMounted
      onClose={onClose}
      maxWidth="xs"
      fullWidth
      PaperProps={{
        sx: { borderRadius: 4, p: 2 },
      }}
    >
      <DialogTitle sx={{ display: "flex", alignItems: "center", gap: 1 }}>
        <EmailIcon color="primary" />
        <Typography variant="h6" component="div" flexGrow={1}>
        Mark all messages as read
        </Typography>
        <IconButton edge="end" onClick={onClose}>
          <CloseIcon />
        </IconButton>
      </DialogTitle>

      <DialogContent dividers>
        

        
          <Typography variant="body2" color="text.secondary" mb={2}>
            Click the button below to mark all messages as read.
          </Typography>
      </DialogContent>

      <DialogActions sx={{ justifyContent: "space-between", px: 3, pb: 2 }}>
        
          <Button variant="contained" onClick={handleSendOtp} disabled={loader}>
            Marked
          </Button>
       
      </DialogActions>
    </Dialog>
  );
};

export default MarkMessageDialog;
