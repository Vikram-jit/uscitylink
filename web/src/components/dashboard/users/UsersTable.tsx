'use client';

import * as React from 'react';
import { UserModel } from '@/redux/models/UserModel';
import { Edit, RemoveRedEye } from '@mui/icons-material';
import { IconButton, Tooltip } from '@mui/material';
import Avatar from '@mui/material/Avatar';
import Box from '@mui/material/Box';
import Card from '@mui/material/Card';
import Divider from '@mui/material/Divider';
import Stack from '@mui/material/Stack';
import Table from '@mui/material/Table';
import TableBody from '@mui/material/TableBody';
import TableCell from '@mui/material/TableCell';
import TableHead from '@mui/material/TableHead';
import TableRow from '@mui/material/TableRow';
import Typography from '@mui/material/Typography';
import { Circle } from '@phosphor-icons/react';

function noop(): void {
  // do nothing
}

interface UsersTableProps {
  count?: number;
  page?: number;
  rows?: UserModel[];
  rowsPerPage?: number;
}

export function UsersTable({ count = 0, rows = [], page = 0, rowsPerPage = 0 }: UsersTableProps): React.JSX.Element {
  return (
    <Card>
      <Box sx={{ overflowX: 'auto' }}>
        <Table sx={{ minWidth: '800px' }}>
          <TableHead>
            <TableRow>
              <TableCell>Name</TableCell>
              <TableCell>Email</TableCell>
              <TableCell>Phone Number</TableCell>
              <TableCell>Role</TableCell>
              <TableCell>Status</TableCell>
              <TableCell>Is Online</TableCell>
              <TableCell>Action</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {rows.map((row) => {
              return (
                <TableRow hover key={row.id}>
                  <TableCell>
                    <Stack sx={{ alignItems: 'center' }} direction="row" spacing={2}>
                      <Avatar alt={row.username} />
                      <Typography variant="subtitle2">{row.username}</Typography>
                    </Stack>
                  </TableCell>
                  <TableCell>{row.user?.email}</TableCell>
                  <TableCell>{row.user?.phone_number || '-'}</TableCell>
                  <TableCell>{row.role?.name || '-'}</TableCell>
                  <TableCell>{row.status}</TableCell>
                  <TableCell>
                    {row.isOnline ? <Circle color="green" weight="fill" /> : <Circle color="red" weight="fill" />}
                  </TableCell>
                  <TableCell>
                    <Tooltip title="Edit Information">
                      <IconButton>
                        <Edit />
                      </IconButton>
                    </Tooltip>
                    <Tooltip title="View">
                      <IconButton>
                        <RemoveRedEye />
                      </IconButton>
                    </Tooltip>
                  </TableCell>
                  {/* <TableCell>{dayjs(row.createdAt).format('MMM D, YYYY')}</TableCell> */}
                </TableRow>
              );
            })}
          </TableBody>
        </Table>
      </Box>
      <Divider />
      {/* <TablePagination
        component="div"
        count={count}
        onPageChange={noop}
        onRowsPerPageChange={noop}
        page={page}
        rowsPerPage={rowsPerPage}
        rowsPerPageOptions={[5, 10, 25]}
      /> */}
    </Card>
  );
}
