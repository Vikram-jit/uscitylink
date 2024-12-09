'use client';

import * as React from 'react';
import { CircularProgress } from '@mui/material';
import Button from '@mui/material/Button';
import Dialog from '@mui/material/Dialog';
import DialogActions from '@mui/material/DialogActions';
import DialogContent from '@mui/material/DialogContent';
import DialogContentText from '@mui/material/DialogContentText';
import DialogTitle from '@mui/material/DialogTitle';
import Slide from '@mui/material/Slide';
import { TransitionProps } from '@mui/material/transitions';
import { useSyncDriverMutation, useSyncUserMutation } from '@/redux/UserApiSlice';
import { toast } from 'react-toastify';

const Transition = React.forwardRef(function Transition(
  props: TransitionProps & {
    children: React.ReactElement<any, any>;
  },
  ref: React.Ref<unknown>
) {
  return <Slide direction="up" ref={ref} {...props} />;
});

export default function SyncUserDialog({ role }: { role: string }) {
  const [open, setOpen] = React.useState(false);

  const [syncUser] = useSyncUserMutation()
  const [syncDriver] = useSyncDriverMutation()

  const handleClickOpen = async() => {
    setOpen(true);
    if(role=="staff"){
      const res = await syncUser({})
      if(res.data){
        toast.success("Users Sync Successfully.")
        setOpen(false)
      }else{
        toast.error("SERVER ERROR")
      }
    }else{
      const res = await syncDriver({})
      if(res.data){
        toast.success("Driver Sync Successfully.")
        setOpen(false)
      }else{
        toast.error("SERVER ERROR")
      }
    }
  };

  const handleClose = () => {
    setOpen(false);
  };

  return (
    <React.Fragment>
      <Button variant="outlined" size="small" onClick={handleClickOpen}>
        Sync {role}
      </Button>
      <Dialog
        open={open}
        TransitionComponent={Transition}
        keepMounted
        onClose={handleClose}
        aria-describedby="alert-dialog-slide-description"
      >
        <DialogContent>
          <CircularProgress />
        </DialogContent>

      </Dialog>
    </React.Fragment>
  );
}
