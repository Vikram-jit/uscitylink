'use client';

import * as React from 'react';
import { ChannelModel, UserChannel } from '@/redux/models/ChannelModel';
import Box from '@mui/material/Box';
import Card from '@mui/material/Card';
import Divider from '@mui/material/Divider';
import Table from '@mui/material/Table';
import TableBody from '@mui/material/TableBody';
import TableCell from '@mui/material/TableCell';
import TableHead from '@mui/material/TableHead';
import TableRow from '@mui/material/TableRow';
import dayjs from 'dayjs';
import { Circle } from '@phosphor-icons/react';
import { IconButton, Tooltip } from '@mui/material';
import { Delete } from '@mui/icons-material';

function noop(): void {
  // do nothing
}

interface MemberTableProps {
  count?: number;
  page?: number;
  rows?: UserChannel[];
  rowsPerPage?: number;
}

export function MemberTable({
  count = 0,
  rows = [],
  page = 0,
  rowsPerPage = 0,
}: MemberTableProps): React.JSX.Element {
  return (
    <Card>
      <Box sx={{ overflowX: 'auto' }}>
        <Table sx={{ minWidth: '800px' }}>
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
                  <TableCell>{row.UserProfile?.user?.email || "-"}</TableCell>
                  <TableCell>{row.UserProfile?.user?.phone_number || '-'}</TableCell>

                  <TableCell>{row.UserProfile?.user?.status}</TableCell>
                  <TableCell>
                    {row.UserProfile?.isOnline ? <Circle color="green" weight="fill" /> : <Circle color="red" weight="fill" />}
                  </TableCell>
                  <TableCell>
                    <Tooltip title="Edit Information">
                      <IconButton>
                        <Delete />
                      </IconButton>
                    </Tooltip>

                  </TableCell>
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
