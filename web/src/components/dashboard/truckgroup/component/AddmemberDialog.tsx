'use client';

import * as React from 'react';
import { useAddGroupMemberMutation } from '@/redux/GroupApiSlice';
import { SingleGroupModel } from '@/redux/models/GroupModel';
import { UserModel } from '@/redux/models/UserModel';
import { hideLoader, showLoader } from '@/redux/slices/loaderSlice';
import { useGetUsersQuery } from '@/redux/UserApiSlice';
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

interface AddGroupDialog {
  groupId: string;
  open: boolean;
  setOpen: React.Dispatch<React.SetStateAction<boolean>>;
  group?: SingleGroupModel | undefined;
}

export default function AddMemberDialog({ open, setOpen, groupId, group }: AddGroupDialog) {
  const [isMounted, setIsMounted] = React.useState(false);
  
  React.useEffect(() => {
    setIsMounted(true);
  }, []);

  const handleClose = () => {
    setOpen(false);
  };
  const dispatch = useDispatch();
  const [addGroupMember] = useAddGroupMemberMutation();

  const [selectedUsers, setSelectedUsers] = React.useState<UserModel[]>([]);
  
  // Initialize with empty array to avoid hydration issues
  const [availableUsers, setAvailableUsers] = React.useState<UserModel[]>([]);

  const handleChange = (event: any, value: any) => {
    setSelectedUsers(value || []);
  };
  
  const { data, isFetching } = useGetUsersQuery({ 
    role: 'driver', 
    page: -1 
  }, {
    skip: !open, // Only fetch when dialog is open
  });
  
  const [message, setApiResponse] = useErrorHandler();
  
  // Process data only on client side
  React.useEffect(() => {
    if (isMounted && data?.data?.users) {
      // Deduplicate users by id
      const idMap = new Map<string, UserModel>();
      data.data.users.forEach(user => {
        if (user?.id) {
          const id = String(user.id);
          if (!idMap.has(id)) {
            idMap.set(id, user);
          }
        }
      });
      
      const uniqueUsers = Array.from(idMap.values());
      setAvailableUsers(uniqueUsers);
      
      // Set default selected users if group is provided
      if (group && uniqueUsers.length > 0) {
        const defaultSelectedUsers = uniqueUsers.filter((user) =>
          group?.members
            .filter((e) => e.status === 'active')
            .some((e) => String(e.userProfileId) === String(user.id))
        );
        setSelectedUsers(defaultSelectedUsers);
      }
    }
  }, [isMounted, data, group]);

  async function onSubmit() {
    try {
      dispatch(showLoader());
      const selectedMember = selectedUsers.map((user) => user.id);

      if (selectedMember.length == 0) {
        alert('Please select at least one member to add into group.');
        dispatch(hideLoader());
        return;
      }

      const payload: any = {
        groupId,
        ...(selectedMember.length > 0 && { members: selectedMember.join(',') }),
      };

      const res = await addGroupMember(payload);
      if (res.data?.status) {
        toast.success('Add Group Member Successfully.');
        dispatch(hideLoader());
        setOpen(false);
        return;
      }
      setApiResponse(res.error as any);
      setOpen(false);
      dispatch(hideLoader());
      return;
    } catch (error) {
      dispatch(hideLoader());
      console.log(error);
    }
  }

  // Don't render Autocomplete until component is mounted and data is ready
  if (!isMounted) {
    return null; // Or return a skeleton
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
        <DialogTitle>{'Select Members'}</DialogTitle>
        <DialogContent>
          <Grid container mt={2}>
            <Grid item xs={12} mt={1}>
              <Autocomplete
                multiple
                value={selectedUsers}
                options={availableUsers}
                disableCloseOnSelect
                loading={isFetching}
                onChange={handleChange}
                
                // Critical: Stable equality check
                isOptionEqualToValue={(option, value) => {
                  if (!option?.id || !value?.id) return false;
                  return String(option.id) === String(value.id);
                }}
                
                getOptionLabel={(option) => {
                  if (!option) return '';
                  return `${option.username || ''} (${option.user?.driver_number || ''})`;
                }}
                
                // Use built-in filtering
                filterSelectedOptions
                
                renderOption={(props, option, { selected }) => {
                  if (!option?.id) return null;
                  return (
                    <li {...props} key={`option-${String(option.id)}`}>
                      <Checkbox 
                        checked={selected} 
                        icon={icon} 
                        checkedIcon={checkedIcon} 
                      />
                      {`${option.username} (${option.user?.driver_number})`}
                    </li>
                  );
                }}
                
                renderInput={(params) => (
                  <TextField 
                    {...params} 
                    placeholder="Search members..." 
                    label="Members"
                    variant="outlined"
                  />
                )}
                fullWidth
              />
            </Grid>
          </Grid>
        </DialogContent>
        <DialogActions>
          <Button onClick={handleClose}>Cancel</Button>
          <Button 
            variant="contained" 
            onClick={onSubmit}
            disabled={isFetching || selectedUsers.length === 0}
          >
            {isFetching ? 'Loading...' : 'Submit'}
          </Button>
        </DialogActions>
      </Dialog>
    </React.Fragment>
  );
}