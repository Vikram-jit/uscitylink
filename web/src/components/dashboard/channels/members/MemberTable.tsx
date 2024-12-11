'use client';

import * as React from 'react';
import { useChangeChannelMemberStatusMutation, useRemoveChannelMemberMutation } from '@/redux/ChannelApiSlice';
import { pagination, UserChannel } from '@/redux/models/ChannelModel';
import { Delete, Settings } from '@mui/icons-material';
import { Badge, Chip, IconButton, Menu, MenuItem, TablePagination, Tooltip } from '@mui/material';
import Box from '@mui/material/Box';
import Card from '@mui/material/Card';
import Divider from '@mui/material/Divider';
import Table from '@mui/material/Table';
import TableBody from '@mui/material/TableBody';
import TableCell from '@mui/material/TableCell';
import TableHead from '@mui/material/TableHead';
import TableRow from '@mui/material/TableRow';
import { Circle } from '@phosphor-icons/react';
import { toast } from 'react-toastify';
import DeleteConfirmationDialog from '@/components/DeleteConfirmationDialog';

function noop(): void {
  // do nothing
}

interface MemberTableProps {
  count?: number;
  page?: number;
  rows?: UserChannel[];
  rowsPerPage?: number;
  pagination: pagination | undefined;
  setPage: React.Dispatch<React.SetStateAction<number>>;
}

export function MemberTable({
  count = 0,
  rows = [],
  page = 0,
  setPage,
  pagination,
}: MemberTableProps): React.JSX.Element {
  const [anchorEl, setAnchorEl] = React.useState<null | HTMLElement>(null);
  const [selectedMemberId, setSelectedMemberId] = React.useState<string | null>(null);
  const [open,setOpen] = React.useState<boolean>(false)
  const [removeChannelMember, { isLoading: deleteLoader }] = useRemoveChannelMemberMutation();
  const [changeChannelMemberStatus, { isLoading: updateMemberLoader }] = useChangeChannelMemberStatusMutation();

  const handleMenuOpen = (event: React.MouseEvent<HTMLElement>, memberId: string) => {
    setAnchorEl(event.currentTarget);
    setSelectedMemberId(memberId);
  };

  const handleMenuClose = () => {
    setAnchorEl(null);
  };

  return (
    <Card>
    {open &&  <DeleteConfirmationDialog onClose={()=>{
      setSelectedMemberId(null)
      setOpen(false)
    }} onConfirm={async()=>{

const res = await removeChannelMember({
  id: selectedMemberId!,
});
if (res.data) {
  setSelectedMemberId(null)
  setOpen(false)
  toast.success('Delete Member Successfully.');
} else {
  toast.error('SERVER ERROR');
}

}} open={open}/>}
      <Box sx={{ overflowX: 'auto' }}>
        <Table>
          <TableHead>
            <TableRow>
              <TableCell>Name</TableCell>
              <TableCell>Email</TableCell>
              <TableCell>Phone Number</TableCell>

              <TableCell>Status</TableCell>
              <TableCell>Is Online</TableCell>
              <TableCell>Action</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {rows.map((row) => {
              return (
                <TableRow hover key={row.id}>
                  <TableCell>{row.UserProfile?.username}</TableCell>
                  <TableCell>{row.UserProfile?.user?.email || '-'}</TableCell>
                  <TableCell>{row.UserProfile?.user?.phone_number || '-'}</TableCell>

                  <TableCell>
                    <Chip label={row?.status} color={row?.status == 'active' ? 'success' : 'error'}></Chip>
                  </TableCell>
                  <TableCell>
                    {row.UserProfile?.isOnline ? (
                      <Circle color="green" weight="fill" />
                    ) : (
                      <Circle color="red" weight="fill" />
                    )}
                  </TableCell>
                  <TableCell>
                    <IconButton onClick={(event) => handleMenuOpen(event, row.id)}>
                      <Settings />
                    </IconButton>
                    <Tooltip title="Edit Information">
                      <IconButton
                        onClick={()=>{
                          setSelectedMemberId(row.id)
                          setOpen(true)
                        }}
                      >
                        <Delete />
                      </IconButton>
                    </Tooltip>
                  </TableCell>
                </TableRow>
              );
            })}
          </TableBody>
          <Menu anchorEl={anchorEl} open={Boolean(anchorEl)} onClose={handleMenuClose}>
            <MenuItem
              sx={{
                border: '1px solid',
              }}
              disabled={updateMemberLoader}
              onClick={async () => {
                const res = await changeChannelMemberStatus({
                  id: selectedMemberId!,
                  status: rows.find((m) => m.id === selectedMemberId)?.status === 'active' ? 'inactive' : 'active',
                });
                if (res.data) {
                  toast.success('Updated Status Successfully.');
                } else {
                  toast.error('SERVER ERROR');
                }
              }}
            >
              {selectedMemberId
                ? rows.find((m) => m.id === selectedMemberId)?.status === 'active'
                  ? 'Deactivate'
                  : 'Activate'
                : 'Toggle Status'}
            </MenuItem>
          </Menu>
        </Table>
      </Box>
      <Divider />
      {pagination && (
        <TablePagination
          component="div"
          count={pagination.total}
          onPageChange={(e, page) => {
            setPage(page + 1);
          }}
          onRowsPerPageChange={noop}
          page={page - 1}
          rowsPerPage={pagination.pageSize}
        />
      )}
    </Card>
  );
}
