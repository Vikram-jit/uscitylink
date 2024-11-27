'use client';

import React, { useState } from 'react';
import { SingleGroupModel } from '@/redux/models/GroupModel';
import {  Delete } from '@mui/icons-material';
import {
  Button,

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

import AddMemberDialog from './AddmemberDialog';
import { useRemoveGroupMemberMutation } from '@/redux/GroupApiSlice';
import { toast } from 'react-toastify';

interface GroupDetailInterface {
  group: SingleGroupModel;
}

export default function GroupDetail({ group }: GroupDetailInterface) {
  const [addMemberDialog, setAddMemberDialog] = useState<boolean>(false);
  const [removeGroupMember,{isLoading}] = useRemoveGroupMemberMutation()
  return (
    <Grid container p={2}>
      {addMemberDialog && (
        <AddMemberDialog open={addMemberDialog} setOpen={setAddMemberDialog} groupId={group.group.id} group={group}/>
      )}
      <Grid item xs={12}>
        <Typography variant="h5">Group Details</Typography>
      </Grid>
      <Grid item xs={12} md={6}>
        <Box sx={{ p: 2, marginTop: 2 }}>
          <TextField
            fullWidth
            placeholder="Group name"
            variant="outlined"
            size="small"
            label="Name"
            value={group?.group.name}
          />
        </Box>
        <Box sx={{ p: 2 }}>
          <TextField
            fullWidth
            value={group?.group.description}
            placeholder="Group Description"
            variant="outlined"
            size="small"
            label="Description"
          />
        </Box>
        <Box sx={{ p: 2 }}>
          <Button variant="contained" sx={{ float: 'right' }}>
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
        <Button variant="outlined" sx={{ borderColor: 'red', color: 'red', width: '200px', marginTop: 5,"&:hover":{
          background:"red",borderColor:"red",color:'white'
        } }}>
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
                    <TableCell>-</TableCell>
                    <TableCell>-</TableCell>
                    <TableCell>
                      <IconButton disabled={isLoading} onClick={async()=>{
                       const res= await removeGroupMember({groupId:e.id})
                        if(res.data){
                          toast.success("Removed Member from group.")
                        }else{
                          toast.error("SERVER ERROR")
                        }
                      }}>
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
