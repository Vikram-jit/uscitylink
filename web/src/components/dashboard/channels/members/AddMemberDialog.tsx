'use client';

import * as React from 'react';
import {  useAddMemberToChannelMutation} from '@/redux/ChannelApiSlice';
import CheckBoxIcon from '@mui/icons-material/CheckBox';
import CheckBoxOutlineBlankIcon from '@mui/icons-material/CheckBoxOutlineBlank';
import { Autocomplete, Box, CircularProgress } from '@mui/material';
import Button from '@mui/material/Button';
import Checkbox from '@mui/material/Checkbox';
import Dialog from '@mui/material/Dialog';
import DialogActions from '@mui/material/DialogActions';
import DialogContent from '@mui/material/DialogContent';
import DialogTitle from '@mui/material/DialogTitle';
import TextField from '@mui/material/TextField';
import { Plus as PlusIcon } from '@phosphor-icons/react/dist/ssr/Plus';
import { toast } from 'react-toastify';
import { useGetUserWithoutChannelQuery } from '@/redux/UserApiSlice';
import { UserModel } from '@/redux/models/UserModel';

const icon = <CheckBoxOutlineBlankIcon fontSize="small" />;
const checkedIcon = <CheckBoxIcon fontSize="small" />;

export default function AddChanelMemberDialog() {
  const [open, setOpen] = React.useState<boolean>(false);
  function handleClose() {
    setOpen(false);
  }
  const [selectedUsers, setSelectedUsers] = React.useState<UserModel[]>([]);

  const handleChange = (event:any, value:any) => {
    setSelectedUsers(value);
  };
  const [addMemberToChannel, { isLoading }] = useAddMemberToChannelMutation();

  const {data,isFetching} = useGetUserWithoutChannelQuery()

  return (
    <>
      <Button
        onClick={() => setOpen(true)}
        startIcon={<PlusIcon fontSize="var(--icon-fontSize-md)" />}
        variant="contained"
      >
        Add Member
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
              const ids = selectedUsers.map((e) => e.id)
              if(ids.length){
                await addMemberToChannel({ ids });
                toast.success('Created New Channel Successfully.');
                handleClose?.();
              }else{
                toast.error('SERVER ERROR.');
              }

            },
          }}
        >
          <DialogTitle>Add New Member</DialogTitle>
          <DialogContent>
            <Autocomplete
            sx={{marginTop:2}}
              multiple
              id="checkboxes-tags-demo"
              options={data?.data || []}
              disableCloseOnSelect
              onChange={handleChange}
              getOptionLabel={(option) => {return `${option.username}(${option.user.driver_number})`}}
              renderOption={(props:any, option, { selected }) => {
                const { key, ...optionProps } = props;
                return (
                  <li key={key} {...optionProps}>
                    <Checkbox icon={icon} checkedIcon={checkedIcon} style={{ marginRight: 8 }} checked={selected} />
                    {`${option.username}(${option.user.driver_number})` }
                  </li>
                );
              }}
              fullWidth
              renderInput={(params) => <TextField {...params} label="Select Users" placeholder="Select Users" />}
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
              Submit
            </Button>
          </DialogActions>
        </Dialog>
      )}
    </>
  );
}