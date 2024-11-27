'use client';

import * as React from 'react';
import { useCreateGroupMutation, useGetTrucksQuery } from '@/redux/GroupApiSlice';
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
  open: boolean;
  setOpen: React.Dispatch<React.SetStateAction<boolean>>;
}

export default function AddGroupDialog({ open, setOpen }: AddGroupDialog) {
  const handleClose = () => {
    setOpen(false);
  };

  const [createGroup] = useCreateGroupMutation();

  const { data: truckList, isLoading } = useGetTrucksQuery();

  const [state, setState] = React.useState({
    name: '',
    description: '',
    type: 'truck',
  });
  const [selectedUsers, setSelectedUsers] = React.useState<UserModel[]>([]);

  const handleChange = (event: any, value: any) => {
    setSelectedUsers(value);
  };
  const { data, isFetching } = useGetUsersQuery({ role: 'driver' });

  async function onSubmit() {
    try {
      const selectedMember = selectedUsers.map((user) => user.id);

      const data = {
        ...state,
        ...(selectedMember.length > 0 && { members: selectedMember.join(',') }),
      };

      const res = await createGroup(data);
      if (res.data?.status) {
        toast.success('Add Group Successfully.');
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
        <DialogTitle>{'Add Truck Group'}</DialogTitle>
        <DialogContent>
          <Grid container>
            <Grid item xs={12} mt={1}>
              <Autocomplete
                id="checkboxes-tags-demo"
                options={truckList?.data || []}
                disableCloseOnSelect
                onChange={(e,v)=>{
                    setState({...state,name:v?.number||''})
                }}
                getOptionLabel={(option) => option.number}
                renderOption={(props: any, option, { selected }) => {
                  const { key, ...optionProps } = props;
                  return (
                    <li key={key} {...optionProps}>
                      <Checkbox icon={icon} checkedIcon={checkedIcon} style={{ marginRight: 8 }} checked={selected} />
                      {option.number}
                    </li>
                  );
                }}
                fullWidth
                renderInput={(params) => <TextField {...params} placeholder='Select Truck ' />}
              />
            </Grid>
            <Grid item xs={12} mt={1}>
              <TextField
                value={state.description}
                multiline
                rows={3}
                fullWidth
                placeholder="Enter Group Description"
                onChange={(e) => setState({ ...state, description: e.target.value })}
              />
            </Grid>
          </Grid>
          <Grid container mt={2}>
            <Grid item xs={12}>
              <Typography variant="subtitle1">Select Members</Typography>
            </Grid>
            <Grid item xs={12} mt={1}>
              <Autocomplete
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
