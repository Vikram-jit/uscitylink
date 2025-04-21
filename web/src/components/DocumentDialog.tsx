'use client';

import { on } from 'events';

import * as React from 'react';
import { ArrowBackIos, ArrowForwardIos } from '@mui/icons-material';
import CloseIcon from '@mui/icons-material/Close';
import { Box, CircularProgress, DialogActions, DialogContent } from '@mui/material';
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
    const [isLoading, setIsLoading] = React.useState(true); 
    const [oldCurrebIndex,setOldCurrentIndex] = React.useState<number | null>(null)// Track loading state
    React.useEffect (() => {
      if (currentIndex){
         if(currentIndex != oldCurrebIndex){
          setOldCurrentIndex(currentIndex);    
          setIsLoading(true) 
         }
        if(oldCurrebIndex != null){
          setOldCurrentIndex(currentIndex);   
        }
      }}, [currentIndex])

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
          <Viewer documentKey={documentKey} setLoading={setIsLoading}/>
          {isLoading  && (
            <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: '100%' }}>
              <CircularProgress />
            </Box>
          )}
        </DialogContent>

        {currentIndex != null &&
        <DialogActions  sx={{ justifyContent: 'center', padding: 2 }}>
          <IconButton onClick={()=>{

            movePrev?.();
            if(oldCurrebIndex != null){
              if(oldCurrebIndex != currentIndex){
                setIsLoading(true)
              }
            }
            
          }} sx={{ mr: 2 }} >
            <ArrowBackIos sx={{fontSize:42}}  />
          </IconButton>

          <IconButton onClick={()=>{
            
            moveNext?.(); 
            if(oldCurrebIndex != null){
              if(oldCurrebIndex != currentIndex){
                setIsLoading(true)
              }
            }
          }} sx={{ ml: 2 }}>
            <ArrowForwardIos sx={{fontSize:42}}  />
            
          </IconButton>
        </DialogActions>}
      </Dialog>
    </React.Fragment>
  );
}
