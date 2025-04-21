'use client';

import { on } from 'events';

import * as React from 'react';
import { ArrowBackIos, ArrowForwardIos } from '@mui/icons-material';
import CloseIcon from '@mui/icons-material/Close';
import { Box, DialogActions, DialogContent } from '@mui/material';
import AppBar from '@mui/material/AppBar';
import Button from '@mui/material/Button';
import Dialog from '@mui/material/Dialog';
import Divider from '@mui/material/Divider';
import IconButton from '@mui/material/IconButton';
import List from '@mui/material/List';
import ListItemButton from '@mui/material/ListItemButton';
import ListItemText from '@mui/material/ListItemText';
import Slide from '@mui/material/Slide';
import Toolbar from '@mui/material/Toolbar';
import { TransitionProps } from '@mui/material/transitions';
import Typography from '@mui/material/Typography';

import Viewer from './dashboard/documentviewer/viewer';

const Transition = React.forwardRef(function Transition(
  props: TransitionProps & {
    children: React.ReactElement<unknown>;
  },
  ref: React.Ref<unknown>
) {
  return <Slide direction="up" ref={ref} {...props} />;
});

interface DocumentDialog {
  open: boolean;
  setOpen?: React.Dispatch<React.SetStateAction<boolean>>;
  documentKey: string;
  onClose?: () => void;
  moveNext?: () => void;
  movePrev?: () => void;
  currentIndex?: number;
}
export default function DocumentDialog({
  open,
  setOpen,
  documentKey,
  onClose,
  moveNext,
  movePrev,
  currentIndex,
}: DocumentDialog) {
  const handleClose = () => {
    setOpen?.(false);
    onClose?.();
  };

  return (
    <React.Fragment>
      <Dialog maxWidth="md" fullScreen open={open} onClose={handleClose} TransitionComponent={Transition}>
        <AppBar sx={{ position: 'sticky' }}>
          <Toolbar>
            <IconButton edge="start" color="inherit" onClick={handleClose} aria-label="close">
              <CloseIcon />
            </IconButton>
            <Typography sx={{ ml: 2, flex: 1 }} variant="h6" component="div">
              Document View
            </Typography>
          </Toolbar>
        </AppBar>
        <DialogContent>
          <Viewer documentKey={documentKey} />
        </DialogContent>

        {currentIndex &&
        <DialogActions>
          <IconButton onClick={movePrev} disabled={currentIndex === 0} sx={{ mr: 2 }}>
            <ArrowBackIos />
          </IconButton>

          <IconButton onClick={moveNext} sx={{ ml: 2 }}>
            <ArrowForwardIos />
          </IconButton>
        </DialogActions>}
      </Dialog>
    </React.Fragment>
  );
}
