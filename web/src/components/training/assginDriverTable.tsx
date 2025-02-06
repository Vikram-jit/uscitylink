'use client';

import * as React from 'react';
import { pagination } from '@/redux/models/ChannelModel';
import { useDeleteTemplateMutation } from '@/redux/TemplateApiSlice';
import { assgin_drivers, Training } from '@/redux/TrainingApiSlice';
import { Delete, Edit } from '@mui/icons-material';
import { Button, Chip, IconButton, TablePagination, Tooltip } from '@mui/material';
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

import DeleteConfirmationDialog from '@/components/DeleteConfirmationDialog';
import MediaComponent from '@/components/messages/MediaComment';

interface AssginDriverTable {
  count?: number;
  page?: number;
  rows?: assgin_drivers[];
  setPage: React.Dispatch<React.SetStateAction<number>>;
  pagination: pagination | undefined;
}

export function AssginDriverTable({
  count = 0,
  rows = [],
  page = 0,
  setPage,
  pagination,
}: AssginDriverTable): React.JSX.Element {
  const [dialogOpen, setDialogOpen] = React.useState<boolean>(false);
  const [currentItem, setCurrentItem] = React.useState<string>('');
  const [deleteTemplate, { isLoading }] = useDeleteTemplateMutation();
  return (
    <Card>
      <Box sx={{ overflowX: 'auto' }}>
        <Table sx={{ minWidth: '800px' }}>
          <TableHead>
            <TableRow>
              <TableCell>Driver Name</TableCell>
              <TableCell>Driver number</TableCell>
              <TableCell>View Durations</TableCell>
              <TableCell>View Status</TableCell>
              <TableCell>Quiz Status</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {rows.map((row) => {
              return (
                <TableRow hover key={row.id}>
                  <TableCell>
                    <Stack sx={{ alignItems: 'center' }} direction="row" spacing={2}>
                      <Typography variant="subtitle2">{row.user_profiles?.username}</Typography>
                    </Stack>
                  </TableCell>

                  <TableCell>
                    <Typography variant="subtitle2">{row.user_profiles?.user.driver_number}</Typography>
                  </TableCell>
                  <TableCell>
                    <Typography variant="subtitle2">{row.view_duration || "0.00.00.00"}</Typography>
                  </TableCell>
                  <TableCell>
                    <Typography variant="subtitle2"><Chip color={row.view_duration != null ? row.isCompleteWatch ? "success" : "warning" : "default"} label={row.view_duration != null ? row.isCompleteWatch ? "completed" : "partially viewed" : "Not View Yet"}></Chip></Typography>
                  </TableCell>
                  <TableCell>
                  { row.quiz_status  ? <Typography variant="subtitle2"><Chip color={row.quiz_status == "passed" ? "success" : row.quiz_status == "failed" ? "error" :"default" } label={row.quiz_status == "passed" ? "certified" : row.quiz_status }/></Typography> : "-"}
                  </TableCell>
                 
                </TableRow>
              );
            })}
          </TableBody>
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
          page={page - 1}
          rowsPerPage={pagination.pageSize}
        />
      )}
      {dialogOpen && (
        <DeleteConfirmationDialog
          onClose={() => {
            setDialogOpen(false);
            setCurrentItem('');
          }}
          onConfirm={async () => {
            await deleteTemplate({ id: currentItem });
            setDialogOpen(false);
            setCurrentItem('');
          }}
          open={dialogOpen}
        />
      )}
    </Card>
  );
}
