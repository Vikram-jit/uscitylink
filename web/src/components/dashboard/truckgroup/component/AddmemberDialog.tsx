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
import useErrorHandler from '@/hooks/use-error-handler';
import { useDispatch } from 'react-redux';
import { hideLoader, showLoader } from '@/redux/slices/loaderSlice';
import moment from 'moment';


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
  const dispatch = useDispatch();
  const [addGroupMember] = useAddGroupMemberMutation();


  const [selectedUsers, setSelectedUsers] = React.useState<UserModel[]>([]);

  const handleChange = (event: any, value: any) => {
    setSelectedUsers(value);
  };
  const { data, isFetching } = useGetUsersQuery({ role: 'driver' ,page:-1});
  const [message,setApiResponse] = useErrorHandler()
  React.useEffect(() => {
    if (data?.data) {
      if(group){
        const defaultSelectedUsers = data.data?.users?.filter(user =>
          group?.members
            .filter(e => e.status === "active")
            .map(e => e.userProfileId)
            .includes(user.id)
        );
        setSelectedUsers(defaultSelectedUsers);
      }

    }
  }, [data,group]);

  async function onSubmit() {
    try {

      dispatch(showLoader())
      const selectedMember = selectedUsers.map((user) => user.id);

      if(selectedMember.length == 0){
        alert("Please select at least one member to add into group.");
        dispatch(hideLoader())
        return;
      }

      const data:any = {
       groupId,
        ...(selectedMember.length > 0 && { members: selectedMember.join(',') }),
      };

      const res = await addGroupMember(data);
      if (res.data?.status) {
        toast.success('Add Group Member Successfully.');
        dispatch(hideLoader())
        setOpen(false);
        return
      }
      setApiResponse(res.error as any)
      setOpen(false);
      dispatch(hideLoader())
      return
    } catch (error) {
      dispatch(hideLoader())
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
                options={data?.data?.users || []}
                disableCloseOnSelect
                onChange={handleChange}
                getOptionLabel={(option) => option.username}
                renderOption={(props: any, option, { selected }) => {
                  const { key, ...optionProps } = props;
                  return (
                    <li key={key + moment().utc} {...optionProps}>
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
