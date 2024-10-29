'use client';

import * as React from 'react';
import Button from '@mui/material/Button';
import Dialog from '@mui/material/Dialog';
import DialogActions from '@mui/material/DialogActions';
import DialogContent from '@mui/material/DialogContent';
import DialogTitle from '@mui/material/DialogTitle';
import TextField from '@mui/material/TextField';
import { Plus as PlusIcon } from '@phosphor-icons/react/dist/ssr/Plus';
import { Box, CircularProgress } from '@mui/material';
import { useAddChannelMutation } from '@/redux/ChannelApiSlice';
import { toast } from 'react-toastify';

export default function AddChanelDialog() {
  const [open, setOpen] = React.useState<boolean>(false);
  function handleClose() {
    setOpen(false);
  }

  const [addChannel,{isLoading}] = useAddChannelMutation()

  return (
    <>
      <Button
        onClick={() => setOpen(true)}
        startIcon={<PlusIcon fontSize="var(--icon-fontSize-md)" />}
        variant="contained"
      >
        Add Channel
      </Button>

      {open && (
        <Dialog
          open={open}
          fullWidth
          onClose={handleClose}
          PaperProps={{
            component: 'form',
            onSubmit: async(event: React.FormEvent<HTMLFormElement>) => {
              event.preventDefault();
              const formData = new FormData(event.currentTarget);
              const formJson = Object.fromEntries((formData as any).entries());
              const name = formJson.name;
              const description = formJson.description;
              await addChannel({name,description})
              toast.success("Created New Channel Successfully.")
              handleClose?.()
            },
          }}
        >
          <DialogTitle>Create New Channel</DialogTitle>
          <DialogContent>
            <TextField
              autoFocus
              required
              margin="dense"
              id="name"
              name="name"
              label="Enter channel name"
              type="text"
              fullWidth
              variant="standard"
            />
            <Box marginTop={2}></Box>
            <TextField
              autoFocus
              multiline
              margin="dense"
              id="name"
              name="description"
              label="Enter description name"
              type="text"
              fullWidth
              variant="standard"
              rows={2}
            />
          </DialogContent>
          <DialogActions>
            <Button sx={{color:"red"}} onClick={handleClose}>Cancel</Button>
            <Button variant="contained" disabled={isLoading}  type="submit"  startIcon={isLoading ? <CircularProgress size={14} sx={{color:"#fff"}}/> : <PlusIcon fontSize="var(--icon-fontSize-md)" />}>Create</Button>
          </DialogActions>
        </Dialog>
      )}
    </>
  );
}
