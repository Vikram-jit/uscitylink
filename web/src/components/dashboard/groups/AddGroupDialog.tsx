'use client';

import * as React from 'react';
import { useCreateGroupMutation } from '@/redux/GroupApiSlice';
import { Box, CircularProgress } from '@mui/material';
import Button from '@mui/material/Button';
import Dialog from '@mui/material/Dialog';
import DialogActions from '@mui/material/DialogActions';
import DialogContent from '@mui/material/DialogContent';
import DialogTitle from '@mui/material/DialogTitle';
import TextField from '@mui/material/TextField';
import { Plus as PlusIcon } from '@phosphor-icons/react/dist/ssr/Plus';
import { toast } from 'react-toastify';

export default function AddGroupDialog() {
  const [open, setOpen] = React.useState<boolean>(false);
  function handleClose() {
    setOpen(false);
  }

  const [createGroup, { isLoading }] = useCreateGroupMutation();

  return (
    <>
      <Button
        onClick={() => setOpen(true)}
        startIcon={<PlusIcon fontSize="var(--icon-fontSize-md)" />}
        variant="contained"
      >
        Add Group
      </Button>

      {open && (
        <Dialog
          open={open}
          fullWidth
          onClose={handleClose}
          PaperProps={{
            component: 'form',
            onSubmit: async (event: React.FormEvent<HTMLFormElement>) => {
              event.preventDefault();
              const formData = new FormData(event.currentTarget);
              const formJson = Object.fromEntries((formData as any).entries());
              const name = formJson.name;
              const description = formJson.description;
              await createGroup({ name, channelId: '9361a441-b99d-4ff6-83b5-e59314dff472', description });
              toast.success('Created New Group Successfully.');
              handleClose?.();
            },
          }}
        >
          <DialogTitle>Create New Group</DialogTitle>
          <DialogContent>
            <TextField
              autoFocus
              required
              margin="dense"
              id="name"
              name="name"
              label="Enter group name"
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
            <Button sx={{ color: 'red' }} onClick={handleClose}>
              Cancel
            </Button>
            <Button
              variant="contained"
              disabled={isLoading}
              type="submit"
              startIcon={
                isLoading ? (
                  <CircularProgress size={14} sx={{ color: '#fff' }} />
                ) : (
                  <PlusIcon fontSize="var(--icon-fontSize-md)" />
                )
              }
            >
              Create
            </Button>
          </DialogActions>
        </Dialog>
      )}
    </>
  );
}
