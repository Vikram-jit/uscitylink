'use client';

import * as React from 'react';
import RouterLink from 'next/link';
import {
  Box,
  Button,
  Card,
  Chip,
  CircularProgress,
  IconButton,
  Stack,
  Switch,
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableRow,
  Tooltip,
  Typography,
} from '@mui/material';
import { PencilSimple, Plus, Trash } from '@phosphor-icons/react';
import { toast } from 'react-toastify';

import { paths } from '@/paths';
import { useDeleteFlowMutation, useGetFlowsQuery, useToggleFlowMutation } from '@/redux/AutomationApiSlice';
import type { Flow } from '@/redux/models/AutomationModel';
import DeleteConfirmationDialog from '@/components/DeleteConfirmationDialog';

import { ACTION_LABELS } from './utils';

const statusChip = (flow: Flow) => {
  if (!flow.active) return <Chip label="Off" size="small" />;
  if (flow.shadow_mode) return <Chip color="info" label="Shadow" size="small" />;
  return <Chip color="success" label="Live" size="small" />;
};

export function FlowList(): React.JSX.Element {
  const { data, isLoading } = useGetFlowsQuery();
  const [toggleFlow] = useToggleFlowMutation();
  const [deleteFlow] = useDeleteFlowMutation();
  const [deleting, setDeleting] = React.useState<string | null>(null);

  const toggle = async (id: string, body: { active?: boolean; shadow_mode?: boolean }) => {
    try {
      await toggleFlow({ id, ...body }).unwrap();
    } catch (err: any) {
      toast.error(err?.data?.message || 'Could not update flow');
    }
  };

  return (
    <Stack spacing={2}>
      <Stack alignItems="center" direction="row">
        <Typography color="text.secondary" sx={{ flex: 1 }} variant="body2">
          Flows run in priority order on every document a driver sends. Shadow mode logs what would happen without
          messaging anyone.
        </Typography>
        <Button component={RouterLink} href={`${paths.automation.flows}/new`} startIcon={<Plus />} variant="contained">
          New flow
        </Button>
      </Stack>

      <Card>
        <Box sx={{ overflowX: 'auto' }}>
          <Table sx={{ minWidth: 900 }}>
            <TableHead>
              <TableRow>
                <TableCell>Priority</TableCell>
                <TableCell>Flow</TableCell>
                <TableCell>Actions</TableCell>
                <TableCell>Last 7 days</TableCell>
                <TableCell>Status</TableCell>
                <TableCell>Active</TableCell>
                <TableCell>Shadow</TableCell>
                <TableCell />
              </TableRow>
            </TableHead>
            <TableBody>
              {isLoading ? (
                <TableRow>
                  <TableCell align="center" colSpan={8}>
                    <CircularProgress size={24} />
                  </TableCell>
                </TableRow>
              ) : null}
              {data?.data?.map((flow) => (
                <TableRow hover key={flow.id}>
                  <TableCell>{flow.priority}</TableCell>
                  <TableCell>
                    <Typography component={RouterLink} href={`${paths.automation.flows}/${flow.id}`} sx={{ color: 'inherit', textDecoration: 'none' }} variant="subtitle2">
                      {flow.name}
                    </Typography>
                    {flow.description ? (
                      <Typography color="text.secondary" variant="body2">
                        {flow.description}
                      </Typography>
                    ) : null}
                  </TableCell>
                  <TableCell>
                    <Stack direction="row" flexWrap="wrap" gap={0.5}>
                      {flow.actions.map((a, i) => (
                        // eslint-disable-next-line react/no-array-index-key -- actions have no ids
                        <Chip key={i} label={ACTION_LABELS[a.type] || a.type} size="small" variant="outlined" />
                      ))}
                    </Stack>
                  </TableCell>
                  <TableCell>
                    {flow.last7Days?.matched ?? 0} matched / {flow.last7Days?.total ?? 0} checked
                  </TableCell>
                  <TableCell>{statusChip(flow)}</TableCell>
                  <TableCell>
                    <Switch checked={flow.active} onChange={(e) => void toggle(flow.id, { active: e.target.checked })} />
                  </TableCell>
                  <TableCell>
                    <Switch
                      checked={flow.shadow_mode}
                      onChange={(e) => void toggle(flow.id, { shadow_mode: e.target.checked })}
                    />
                  </TableCell>
                  <TableCell align="right">
                    <Tooltip title="Edit">
                      <IconButton component={RouterLink} href={`${paths.automation.flows}/${flow.id}`}>
                        <PencilSimple size={18} />
                      </IconButton>
                    </Tooltip>
                    <Tooltip title="Delete">
                      <IconButton onClick={() => setDeleting(flow.id)}>
                        <Trash size={18} />
                      </IconButton>
                    </Tooltip>
                  </TableCell>
                </TableRow>
              ))}
              {!isLoading && !data?.data?.length ? (
                <TableRow>
                  <TableCell align="center" colSpan={8}>
                    No flows yet.
                  </TableCell>
                </TableRow>
              ) : null}
            </TableBody>
          </Table>
        </Box>
      </Card>

      {deleting ? (
        <DeleteConfirmationDialog
          onClose={() => setDeleting(null)}
          onConfirm={async () => {
            await deleteFlow({ id: deleting });
            setDeleting(null);
          }}
          open
        />
      ) : null}
    </Stack>
  );
}
