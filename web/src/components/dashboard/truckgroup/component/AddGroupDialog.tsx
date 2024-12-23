'use client';

import * as React from 'react';
import { useCreateGroupMutation, useGetTrucksQuery } from '@/redux/GroupApiSlice';
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
  open: boolean;
  setOpen: React.Dispatch<React.SetStateAction<boolean>>;
  type: string;
}

export default function AddGroupDialog({ open, setOpen, type }: AddGroupDialog) {
  const handleClose = () => {
    setOpen(false);
  };
  const dispatch = useDispatch();
  const [createGroup] = useCreateGroupMutation();
  const [message, setApiResponse] = useErrorHandler();

  const { data: truckList, isLoading } = useGetTrucksQuery();

  const [state, setState] = React.useState({
    name: '',
    description: '',
    type: type,
  });
  const [selectedUsers, setSelectedUsers] = React.useState<UserModel[]>([]);

  const handleChange = (event: any, value: any) => {
    setSelectedUsers(value);
  };
  const { data, isFetching } = useGetUsersQuery({ role: 'driver',page:-1 });
  async function onSubmit() {
    try {
      dispatch(showLoader());
      const selectedMember = selectedUsers.map((user) => user.id);

      const data = {
        ...state,
        ...(selectedMember.length > 0 && { members: selectedMember.join(',') }),
      };

      const res = await createGroup(data);
     
      if (res.data?.status) {
        dispatch(hideLoader());
        toast.success('Add Group Successfully.');
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
        <DialogTitle>{type == 'group' ? 'Add Group' : 'Add Truck Group'}</DialogTitle>
        <DialogContent>
          <Grid container>
            <Grid item xs={12} mt={1}>
              {type == 'truck' ? (
                <Autocomplete
                  id="checkboxes-tags-demo"
                  options={truckList?.data || []}
                  disableCloseOnSelect
                  onChange={(e, v:any) => {
                    setState({ ...state, name: v?.number || '' });
                  }}
                  getOptionLabel={(option) => option.number}
                  renderOption={(props: any, option, { selected }) => {
                    const { key, ...optionProps } = props;
                    return (
                      <li key={key + Math.random() * 100000000} {...optionProps}>
                        <Checkbox icon={icon} checkedIcon={checkedIcon} style={{ marginRight: 8 }} checked={selected} />
                        {option.number}
                      </li>
                    );
                  }}
                  fullWidth
                  renderInput={(params) => <TextField {...params} placeholder="Select Truck " />}
                />
              ) : (
                <TextField
                  value={state.name}
                  fullWidth
                  placeholder="Enter Group name"
                  onChange={(e) => setState({ ...state, name: e.target.value })}
                />
              )}
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
                options={data?.data?.users || []}
                disableCloseOnSelect
                onChange={handleChange}
                getOptionLabel={(option) => `${option.username} (${option.user.driver_number})`}
                renderOption={(props: any, option, { selected }) => {
                  const { key, ...optionProps } = props;
                  return (
                    <li key={key} {...optionProps}>
                      <Checkbox icon={icon} checkedIcon={checkedIcon} style={{ marginRight: 8 }} checked={selected} />
                      {`${option.username} (${option.user.driver_number})`}
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
