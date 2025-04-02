'use client';

import * as React from 'react';
import { useCreateGroupMutation, useGetTrucksQuery } from '@/redux/GroupApiSlice';
import { UserModel } from '@/redux/models/UserModel';
import { hideLoader, showLoader } from '@/redux/slices/loaderSlice';
import { useAddStaffMemberMutation, useGetStaffUsersQuery } from '@/redux/StaffChatApiSlice';
import CheckBoxIcon from '@mui/icons-material/CheckBox';
import CheckBoxOutlineBlankIcon from '@mui/icons-material/CheckBoxOutlineBlank';
import { Checkbox, Grid, TextField, Typography } from '@mui/material';
import Autocomplete from '@mui/material/Autocomplete';
import Button from '@mui/material/Button';
import Dialog from '@mui/material/Dialog';
import DialogActions from '@mui/material/DialogActions';
import DialogContent from '@mui/material/DialogContent';
import DialogTitle from '@mui/material/DialogTitle';
import Slide from '@mui/material/Slide';
import { TransitionProps } from '@mui/material/transitions';
import { useDispatch } from 'react-redux';
import { toast } from 'react-toastify';

import useErrorHandler from '@/hooks/use-error-handler';

const icon = <CheckBoxOutlineBlankIcon fontSize="small" />;
const checkedIcon = <CheckBoxIcon fontSize="small" />;

const Transition = React.forwardRef(function Transition(
  props: TransitionProps & {
    children: React.ReactElement<any, any>;
  },
  ref: React.Ref<unknown>
) {
  return <Slide direction="up" ref={ref} {...props} />;
});

interface AddMemberDialog {
  open: boolean;
  setOpen: React.Dispatch<React.SetStateAction<boolean>>;
}

export default function AddMemberDialog({ open, setOpen }: AddMemberDialog) {
  const handleClose = () => {
    setOpen(false);
  };
  const dispatch = useDispatch();
  const [message, setApiResponse] = useErrorHandler();

  const [addStaffMember] = useAddStaffMemberMutation();

  const [selectedUsers, setSelectedUsers] = React.useState<UserModel | null>(null);

  const handleChange = (event: any, value: any) => {
    setSelectedUsers(value);
  };
  const { data, isFetching } = useGetStaffUsersQuery();
  async function onSubmit() {
    try {
      if (selectedUsers == null) {
        alert('select user to add');
        return;
      }
      dispatch(showLoader());

      const res = await addStaffMember({ type: 'active', userProfileId: selectedUsers?.id! });

      if (res.data?.status) {
        dispatch(hideLoader());
        toast.success(res.data.message);
        setOpen(false);
        return;
      }
      dispatch(hideLoader());
      setApiResponse(res.error as any);
      return;
    } catch (error) {
      dispatch(hideLoader());
      console.log(error);
    }
  }

  return (
    <React.Fragment>
      <Dialog
        fullWidth
        open={open}
        TransitionComponent={Transition}
        keepMounted
        onClose={handleClose}
        aria-describedby="alert-dialog-slide-description"
      >
        <DialogTitle>{'Select Member'}</DialogTitle>
        <DialogContent>
          <Grid container>
            <Grid item xs={12} mt={1}>
              <Autocomplete
                id="checkboxes-tags-demo"
                options={data?.data || []}
                disableCloseOnSelect
                onChange={handleChange}
                getOptionLabel={(option) => `${option.username}`}
                renderOption={(props: any, option, { selected }) => {
                  const { key, ...optionProps } = props;
                  return (
                    <li key={key} {...optionProps}>
                      <Checkbox icon={icon} checkedIcon={checkedIcon} style={{ marginRight: 8 }} checked={selected} />
                      {`${option.username}`}
                    </li>
                  );
                }}
                fullWidth
                renderInput={(params) => <TextField {...params} />}
              />
            </Grid>
          </Grid>
        </DialogContent>
        <DialogActions>
          <Button onClick={handleClose}>Cancel</Button>
          <Button variant="contained" onClick={onSubmit}>
            Submit
          </Button>
        </DialogActions>
      </Dialog>
    </React.Fragment>
  );
}
