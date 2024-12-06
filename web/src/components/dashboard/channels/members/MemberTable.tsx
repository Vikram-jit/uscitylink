'use client';

import * as React from 'react';
import { ChannelModel, pagination, UserChannel } from '@/redux/models/ChannelModel';
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
import { IconButton, TablePagination, Tooltip } from '@mui/material';
import { Delete } from '@mui/icons-material';

function noop(): void {
  // do nothing
}

interface MemberTableProps {
  count?: number;
  page?: number;
  rows?: UserChannel[];
  rowsPerPage?: number;
  pagination:pagination|undefined
  setPage:React.Dispatch<React.SetStateAction<number>>
}

export function MemberTable({
  count = 0,
  rows = [],
  page = 0,
  setPage,
  pagination
}: MemberTableProps): React.JSX.Element {

  return (
    <Card>
      <Box sx={{ overflowX: 'auto' }}>
        <Table >
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
     {pagination &&  <TablePagination
        component="div"
        count={pagination.total}
        onPageChange={(e,page)=>{
          setPage(page+1)
        }}
        onRowsPerPageChange={noop}
        page={page-1}
        rowsPerPage={pagination.pageSize}

      />}
    </Card>
  );
}
