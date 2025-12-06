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
import moment from 'moment';
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
  const handleClose = () => {
    setOpen(false);
  };
  const dispatch = useDispatch();
  const [addGroupMember] = useAddGroupMemberMutation();

  const [selectedUsers, setSelectedUsers] = React.useState<UserModel[]>([]);
  const [search, setSearch] = React.useState('');

  const handleChange = (event: any, value: any) => {
    setSelectedUsers(value);
  };
  const { data, isFetching } = useGetUsersQuery({ role: 'driver', page: -1 });
  const [message, setApiResponse] = useErrorHandler();
  
  React.useEffect(() => {
    if (data?.data) {
      if (group) {
        const defaultSelectedUsers = data.data?.users?.filter((user) =>
          group?.members
            .filter((e) => e.status === 'active')
            .map((e) => e.userProfileId)
            .includes(user.id)
        );
        setSelectedUsers(defaultSelectedUsers);
      }
    }
  }, [data, group]);

  async function onSubmit() {
    try {
      dispatch(showLoader());
      const selectedMember = selectedUsers.map((user) => user.id);

      if (selectedMember.length == 0) {
        alert('Please select at least one member to add into group.');
        dispatch(hideLoader());
        return;
      }

      const data: any = {
        groupId,
        ...(selectedMember.length > 0 && { members: selectedMember.join(',') }),
      };

      const res = await addGroupMember(data);
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

  // Clean up the uniqueUsers logic - simpler approach
  const uniqueUsers = React.useMemo<UserModel[]>(() => {
    if (!data?.data?.users) return [];
    
    // Simple deduplication by id
    const idMap = new Map<string, UserModel>();
    data.data.users.forEach(user => {
      if (user?.id) {
        idMap.set(String(user.id), user);
      }
    });
    
    return Array.from(idMap.values());
  }, [data]);

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
                options={uniqueUsers}
                disableCloseOnSelect
                onChange={handleChange}
                
                // ✅ Critical: Proper equality check
                isOptionEqualToValue={(option, value) => 
                  String(option?.id) === String(value?.id)
                }
                
                // ✅ Clean label
                getOptionLabel={(option) => 
                  `${option.username || ''} (${option.user?.driver_number || ''})`
                }
                
                // ✅ Remove custom filterOptions and let MUI handle it
                filterSelectedOptions
                
                renderOption={(props, option, { selected }) => (
                  <li {...props} key={String(option.id)}>
                    <Checkbox 
                      checked={selected} 
                      icon={icon} 
                      checkedIcon={checkedIcon} 
                    />
                    {`${option.username} (${option.user?.driver_number})`}
                  </li>
                )}
                
                renderInput={(params) => (
                  <TextField 
                    {...params} 
                    placeholder="Search members..." 
                  />
                )}
                fullWidth
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