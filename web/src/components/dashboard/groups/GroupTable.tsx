'use client';

import * as React from 'react';
import { ChannelModel } from '@/redux/models/ChannelModel';
import Box from '@mui/material/Box';
import Card from '@mui/material/Card';
import Divider from '@mui/material/Divider';
import Table from '@mui/material/Table';
import TableBody from '@mui/material/TableBody';
import TableCell from '@mui/material/TableCell';
import TableHead from '@mui/material/TableHead';
import TableRow from '@mui/material/TableRow';
import dayjs from 'dayjs';
import { IconButton, Tooltip } from '@mui/material';
import { Edit, RemoveRedEye } from '@mui/icons-material';



interface GroupTableProps {
  count?: number;
  page?: number;
  rows?: ChannelModel[];
  rowsPerPage?: number;
}

export function GroupTable({

  rows = [],

}: GroupTableProps): React.JSX.Element {
  return (
    <Card>
      <Box sx={{ overflowX: 'auto' }}>
        <Table sx={{ minWidth: '800px' }}>
          <TableHead>
            <TableRow>
              <TableCell>Name</TableCell>
              <TableCell>Description</TableCell>
              <TableCell>Members</TableCell>
              <TableCell>Created At</TableCell>
              <TableCell>Action</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {rows.map((row) => {
              return (
                <TableRow hover key={row.id}>
                  <TableCell>{row.name}</TableCell>
                  <TableCell>{row.description || "-"}</TableCell>
                  <TableCell>{0}</TableCell>

                  <TableCell>{dayjs(row.createdAt).format('MMM D, YYYY')}</TableCell>
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
