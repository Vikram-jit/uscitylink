'use client';

import React, { SetStateAction, useEffect, useState } from 'react';
import {
  useGetTrucksQuery,
  useRemoveGroupMemberMutation,
  useRemoveGroupMutation,
  useUpdateGroupMutation,
} from '@/redux/GroupApiSlice';
import { SingleGroupModel } from '@/redux/models/GroupModel';
import { TruckModel } from '@/redux/models/TruckModel';
import { Delete } from '@mui/icons-material';
import CheckBoxIcon from '@mui/icons-material/CheckBox';
import CheckBoxOutlineBlankIcon from '@mui/icons-material/CheckBoxOutlineBlank';
import {
  Autocomplete,
  Button,
  Checkbox,
  Grid,
  IconButton,
  Paper,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  TextField,
  Typography,
} from '@mui/material';
import { Box } from '@mui/system';
import { toast } from 'react-toastify';

import AddMemberDialog from './AddmemberDialog';

interface GroupDetailInterface {
  group: SingleGroupModel;
  setViewDetailGroup: React.Dispatch<SetStateAction<boolean>>;
  setSelectedGroup: React.Dispatch<SetStateAction<string>>;
}
const icon = <CheckBoxOutlineBlankIcon fontSize="small" />;
const checkedIcon = <CheckBoxIcon fontSize="small" />;

export default function GroupDetail({ group, setViewDetailGroup, setSelectedGroup }: GroupDetailInterface) {
  const [addMemberDialog, setAddMemberDialog] = useState<boolean>(false);
  const [removeGroupMember, { isLoading }] = useRemoveGroupMemberMutation();
  const [removeGroup, { isLoading: deleteLoader }] = useRemoveGroupMutation();
  const [updateGroup, { isLoading: updateLoader }] = useUpdateGroupMutation();
  const { data: truckList, isLoading: truckListLoader } = useGetTrucksQuery();
  const [state, setState] = useState({
    name: '',
    description: '',
  });
  const [selectedTruck, setSelectedTruck] = useState<TruckModel|null>(null);

  useEffect(() => {
    if (group) {
      setState({
        name: group.group.name,
        description: group.group.description,
      });

    }
  }, [group, updateLoader, truckList]);
  useEffect(() => {

      if (truckList) {
        const defaultSelectedTruck = truckList?.data?.filter((truck) => truck.number == group.group.name);

        if (defaultSelectedTruck.length > 0) {
          setSelectedTruck(defaultSelectedTruck[0]);
        }
      }

  }, [ truckList,selectedTruck,group]);

  return (
    <Grid container p={2}>
      {addMemberDialog && (
        <AddMemberDialog open={addMemberDialog} setOpen={setAddMemberDialog} groupId={group.group.id} group={group} />
      )}
      <Grid item xs={12}>
        <Typography variant="h5">Group Details</Typography>
      </Grid>
      <Grid item xs={12} md={6}>
        <Box sx={{ p: 2, marginTop: 2 }}>
          <Autocomplete
            id="checkboxes-tags-demo"
            options={truckList?.data || []}

            onChange={(e, v) => {
              setState({ ...state, name: v?.number || '' });
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
            renderInput={(params) => <TextField {...params} placeholder="Select Truck " />}
            defaultValue={truckList?.data?.[0]}
            value={selectedTruck}
          />
        </Box>
        <Box sx={{ p: 2 }}>
          <TextField
            fullWidth
            value={state.description}
            placeholder="Group Description"
            variant="outlined"
            size="small"
            label="Description"
            onChange={(e) => setState({ ...state, description: e.target.value })}
          />
        </Box>
        <Box sx={{ p: 2 }}>
          <Button
            variant="contained"
            sx={{ float: 'right' }}
            disabled={updateLoader}
            onClick={async () => {
              const res = await updateGroup({ groupId: group.group.id, ...state });
              if (res.data) {
                toast.success('Updated Group Successfully.');
              } else {
                toast.error('SERVER ERROR');
              }
            }}
          >
            update
          </Button>
        </Box>
      </Grid>
      <Grid
        item
        xs={12}
        md={6}
        display={'flex'}
        justifyContent={'center'}
        alignContent={'center'}
        alignItems={'center'}
        flexDirection={'column'}
      >
        <Typography variant="h4" color={'GrayText'}>
          Total Members
        </Typography>
        <Typography variant="h3">{group.members.length}</Typography>
        <Button
          variant="outlined"
          sx={{
            borderColor: 'red',
            color: 'red',
            width: '200px',
            marginTop: 5,
            '&:hover': {
              background: 'red',
              borderColor: 'red',
              color: 'white',
            },
          }}
          disabled={deleteLoader}
          onClick={async () => {
            const res = await removeGroup({ groupId: group.group.id });
            if (res.data) {
              setViewDetailGroup(false);
              setSelectedGroup('');
              toast.success('Deleted Group Successfully.');
            } else {
              toast.error('SERVER ERROR');
            }
          }}
        >
          Remove Group
        </Button>
      </Grid>
      <Grid item xs={12} marginTop={2}>
        <Box display={'flex'} justifyContent={'space-between'}>
          <Typography variant="h5">Group Members</Typography>
          <Button
            onClick={() => {
              setAddMemberDialog(true);
            }}
            size="small"
          >
            ADD MEMBER
          </Button>
        </Box>
        <TableContainer component={Paper} sx={{ marginTop: 2 }}>
          <Table>
            <TableHead>
              <TableRow>
                <TableCell>Name</TableCell>
                <TableCell>E-mail</TableCell>
                <TableCell>Phone Number</TableCell>
                <TableCell>Action</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {group?.members?.map((e) => {
                return (
                  <TableRow key={e.id}>
                    <TableCell>{e.UserProfile.username}</TableCell>
                    <TableCell>{e.UserProfile.user.email}</TableCell>
                    <TableCell>{e.UserProfile.user.phone_number}</TableCell>
                    <TableCell>
                      <IconButton
                        disabled={isLoading}
                        onClick={async () => {
                          const res = await removeGroupMember({ groupId: e.id });
                          if (res.data) {
                            toast.success('Removed Member from group.');
                          } else {
                            toast.error('SERVER ERROR');
                          }
                        }}
                      >
                        <Delete
                          sx={{
                            color: 'red',
                          }}
                        />
                      </IconButton>
                    </TableCell>
                  </TableRow>
                );
              })}
            </TableBody>
          </Table>
        </TableContainer>
      </Grid>
    </Grid>
  );
}
