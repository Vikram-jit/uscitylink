"use client"
import * as React from 'react';
import Button from '@mui/material/Button';
import Dialog from '@mui/material/Dialog';
import ListItemText from '@mui/material/ListItemText';
import ListItemButton from '@mui/material/ListItemButton';
import List from '@mui/material/List';
import Divider from '@mui/material/Divider';
import AppBar from '@mui/material/AppBar';
import Toolbar from '@mui/material/Toolbar';
import IconButton from '@mui/material/IconButton';
import Typography from '@mui/material/Typography';
import CloseIcon from '@mui/icons-material/Close';
import Slide from '@mui/material/Slide';
import { TransitionProps } from '@mui/material/transitions';
import Viewer from './dashboard/documentviewer/viewer';
import { DialogContent } from '@mui/material';

const Transition = React.forwardRef(function Transition(
  props: TransitionProps & {
    children: React.ReactElement<unknown>;
  },
  ref: React.Ref<unknown>,
) {
  return <Slide direction="up" ref={ref} {...props} />;
});

interface DocumentDialog{
  open:boolean
  setOpen:React.Dispatch<React.SetStateAction<boolean>>
  documentKey:string
}
export default function DocumentDialog({open,setOpen,documentKey}:DocumentDialog) {

  const handleClose = () => {
    setOpen(false);
  };

  return (
    <React.Fragment>

      <Dialog
         maxWidth="md"
         fullScreen
        open={open}
        onClose={handleClose}
        TransitionComponent={Transition}
        
      >
        <AppBar sx={{ position: 'sticky' }}>
          <Toolbar>
            <IconButton
              edge="start"
              color="inherit"
              onClick={handleClose}
              aria-label="close"
            >
              <CloseIcon />
            </IconButton>
            <Typography sx={{ ml: 2, flex: 1 }} variant="h6" component="div">
              Document View
            </Typography>

          </Toolbar>
        </AppBar>
        <DialogContent>
          <Viewer documentKey={documentKey}/>
          </DialogContent>
      </Dialog>
    </React.Fragment>
  );
}
