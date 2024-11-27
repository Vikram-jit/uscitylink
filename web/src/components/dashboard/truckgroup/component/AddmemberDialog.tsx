'use client';

import * as React from 'react';
import { UserModel } from '@/redux/models/UserModel';
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
import { toast } from 'react-toastify';
import { useAddGroupMemberMutation } from '@/redux/GroupApiSlice';
import { SingleGroupModel } from '@/redux/models/GroupModel';


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
  groupId:string
  open: boolean;
  setOpen: React.Dispatch<React.SetStateAction<boolean>>;
  group?:SingleGroupModel    | undefined
}

export default function AddMemberDialog({ open, setOpen,groupId,group }: AddGroupDialog) {
  const handleClose = () => {
    setOpen(false);
  };

  const [addGroupMember] = useAddGroupMemberMutation();


  const [selectedUsers, setSelectedUsers] = React.useState<UserModel[]>([]);

  const handleChange = (event: any, value: any) => {
    setSelectedUsers(value);
  };
  const { data, isFetching } = useGetUsersQuery({ role: 'driver' });

  React.useEffect(() => {
    if (data?.data) {
      if(group){
        const defaultSelectedUsers = data.data.filter(user => group?.members.map((e)=>e.userProfileId).includes(user.id));
        setSelectedUsers(defaultSelectedUsers);
      }

    }
  }, [data,group]);

  async function onSubmit() {
    try {
      const selectedMember = selectedUsers.map((user) => user.id);

      if(selectedMember.length == 0){
        alert("Please select at least one member to add into group.");
        return;
      }

      const data:any = {
       groupId,
        ...(selectedMember.length > 0 && { members: selectedMember.join(',') }),
      };

      const res = await addGroupMember(data);
      if (res.data?.status) {
        toast.success('Add Group Member Successfully.');
        setOpen(false);
      }
    } catch (error) {
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
        <DialogTitle>{'Select Members'}</DialogTitle>
        <DialogContent>

          <Grid container mt={2}>

            <Grid item xs={12} mt={1}>
              <Autocomplete
              value={selectedUsers}
                multiple
                id="checkboxes-tags-demo"
                options={data?.data || []}
                disableCloseOnSelect
                onChange={handleChange}
                getOptionLabel={(option) => option.username}
                renderOption={(props: any, option, { selected }) => {
                  const { key, ...optionProps } = props;
                  return (
                    <li key={key} {...optionProps}>
                      <Checkbox icon={icon} checkedIcon={checkedIcon} style={{ marginRight: 8 }} checked={selected} />
                      {option.username}
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
