"use client";
import React from "react";
import Dialog from "@mui/material/Dialog";
import DialogContent from "@mui/material/DialogContent";
import CircularProgress from "@mui/material/CircularProgress";
import AppBar from "@mui/material/AppBar";
import Toolbar from "@mui/material/Toolbar";
import IconButton from "@mui/material/IconButton";
import Typography from "@mui/material/Typography";
import CloseIcon from "@mui/icons-material/Close";
import Slide from "@mui/material/Slide";
import { TransitionProps } from "@mui/material/transitions";
import { useDispatch, useSelector } from "react-redux";
import { RootState } from "@/redux/slices";
import { closeChat } from "@/redux/slices/chatSlice";
import SingleChatUi from "./messages/SingleChatUi";
import { useSocket } from "@/lib/socketProvider";

const Transition = React.forwardRef(function Transition(
  props: TransitionProps & { children: React.ReactElement },
  ref: React.Ref<unknown>
) {
  return <Slide direction="up" ref={ref} {...props} />;
});

const MessageDialog: React.FC = () => {
  const open = useSelector((state: RootState) => state.chat?.open);
  const id = useSelector((state: RootState) => state.chat?.id);
  const dispatch = useDispatch();
  const {socket}  = useSocket();

  const handleClose = () => {
    if (socket) {
      socket.emit("staff_open_chat", "");
    }
    dispatch(closeChat());
  };

  return (
    <Dialog
      open={open}
      fullScreen
      onClose={handleClose}
      TransitionComponent={Transition}
    >
      <AppBar position="relative" color="primary" sx={{ position: "sticky" }}>
        <Toolbar>
          <IconButton edge="start" color="inherit" onClick={handleClose} aria-label="close">
            <CloseIcon />
          </IconButton>
          <Typography variant="h6" sx={{ ml: 2, flex: 1 }}>
            Chat
          </Typography>
        </Toolbar>
      </AppBar>

      <DialogContent sx={{ p: 0 }}>
        {id ? (
          <SingleChatUi id={id} />
        ) : (
          <div style={{ padding: 40, textAlign: "center" }}>
            <CircularProgress />
            <Typography variant="body2" mt={2}>
              Loading chat...
            </Typography>
          </div>
        )}
      </DialogContent>
    </Dialog>
  );
};

export default MessageDialog;
