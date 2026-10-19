'use client';

import * as React from 'react';
import {
  Box,
  Card,
  Chip,
  CircularProgress,
  Collapse,
  FormControlLabel,
  Grid,
  IconButton,
  MenuItem,
  Stack,
  Switch,
  Table,
  TableBody,
  TableCell,
  TableHead,
  TablePagination,
  TableRow,
  TextField,
  Typography,
} from '@mui/material';
import { CaretDown, CaretRight } from '@phosphor-icons/react';
import moment from 'moment';

import { useGetFlowRunsQuery, useGetFlowsQuery } from '@/redux/AutomationApiSlice';
import type { FlowRun } from '@/redux/models/AutomationModel';

import { ActionResultsView, TraceView } from './TraceView';
import { humanizeKey } from './utils';

function RunRow({ run }: { run: FlowRun }): React.JSX.Element {
  const [open, setOpen] = React.useState(false);
  const ctx = run.context_snapshot || {};

  return (
    <>
      <TableRow hover onClick={() => setOpen(!open)} sx={{ cursor: 'pointer' }}>
        <TableCell padding="checkbox">
          <IconButton size="small">{open ? <CaretDown /> : <CaretRight />}</IconButton>
        </TableCell>
        <TableCell>{moment(run.createdAt).format('MMM D, h:mm a')}</TableCell>
        <TableCell>{run.flow?.name || run.flow_id}</TableCell>
        <TableCell>
          {ctx.driver?.name || '—'}
          {ctx.driver?.truck ? (
            <Typography color="text.secondary" variant="body2">
              Truck {ctx.driver.truck}
            </Typography>
          ) : null}
        </TableCell>
        <TableCell>{humanizeKey(run.doc_type_key)}</TableCell>
        <TableCell>
          <Stack direction="row" spacing={0.5}>
            {run.skipped_reason ? (
              <Chip label={`Skipped: ${run.skipped_reason}`} size="small" />
            ) : (
              <Chip color={run.matched ? 'success' : 'default'} label={run.matched ? 'Matched' : 'No match'} size="small" />
            )}
            {run.condition_trace?.branch?.kind === 'else_if' ? (
              <Chip color="warning" label={run.condition_trace.branch.name || 'Else if'} size="small" variant="outlined" />
            ) : run.condition_trace?.branch?.kind === 'else' ? (
              <Chip label="Else" size="small" variant="outlined" />
            ) : null}
            {run.shadow ? <Chip color="info" label="Shadow" size="small" variant="outlined" /> : null}
            {run.error ? <Chip color="error" label="Error" size="small" /> : null}
          </Stack>
        </TableCell>
      </TableRow>
      <TableRow>
        <TableCell colSpan={6} sx={{ py: 0, borderBottom: open ? undefined : 'none' }}>
          <Collapse in={open} unmountOnExit>
            <Grid container spacing={3} sx={{ py: 2 }}>
              <Grid item md={6} xs={12}>
                <Typography gutterBottom variant="subtitle2">
                  Conditions
                </Typography>
                <TraceView node={run.condition_trace} />
                {run.condition_trace?.branch_trace ? (
                  <>
                    <Typography color="text.secondary" sx={{ display: 'block', mt: 1 }} variant="caption">
                      ELSE IF &quot;{run.condition_trace.branch?.name}&quot;
                    </Typography>
                    <TraceView node={run.condition_trace.branch_trace} />
                  </>
                ) : null}
              </Grid>
              <Grid item md={6} xs={12}>
                <Typography gutterBottom variant="subtitle2">
                  Actions
                </Typography>
                <ActionResultsView results={run.action_results} />
                {run.error ? (
                  <Typography color="error" sx={{ mt: 1 }} variant="body2">
                    {run.error}
                  </Typography>
                ) : null}
                <Typography color="text.secondary" sx={{ mt: 2 }} variant="caption">
                  Message {run.message_id}
                </Typography>
              </Grid>
            </Grid>
          </Collapse>
        </TableCell>
      </TableRow>
    </>
  );
}

export function RunLog(): React.JSX.Element {
  const [page, setPage] = React.useState(1);
  const [flowId, setFlowId] = React.useState('');
  const [matched, setMatched] = React.useState('');
  const [errorsOnly, setErrorsOnly] = React.useState(false);
  const { data: flows } = useGetFlowsQuery();
  const { data, isFetching } = useGetFlowRunsQuery({ page, flowId, matched, errorsOnly });

  return (
    <Stack spacing={2}>
      <Stack direction={{ xs: 'column', md: 'row' }} spacing={2}>
        <TextField label="Flow" onChange={(e) => { setFlowId(e.target.value); setPage(1); }} select size="small" sx={{ minWidth: 260 }} value={flowId}>
          <MenuItem value="">All flows</MenuItem>
          {flows?.data?.map((f) => (
            <MenuItem key={f.id} value={f.id}>
              {f.name}
            </MenuItem>
          ))}
        </TextField>
        <TextField label="Result" onChange={(e) => { setMatched(e.target.value); setPage(1); }} select size="small" sx={{ minWidth: 180 }} value={matched}>
          <MenuItem value="">All</MenuItem>
          <MenuItem value="true">Matched</MenuItem>
          <MenuItem value="false">Not matched</MenuItem>
        </TextField>
        <FormControlLabel control={<Switch checked={errorsOnly} onChange={(e) => { setErrorsOnly(e.target.checked); setPage(1); }} />} label="Errors only" />
      </Stack>
      <Card>
        <Box sx={{ overflowX: 'auto' }}>
          <Table sx={{ minWidth: 900 }}>
            <TableHead>
              <TableRow>
                <TableCell />
                <TableCell>When</TableCell>
                <TableCell>Flow</TableCell>
                <TableCell>Driver</TableCell>
                <TableCell>Document</TableCell>
                <TableCell>Result</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {isFetching ? (
                <TableRow>
                  <TableCell align="center" colSpan={6}>
                    <CircularProgress size={24} />
                  </TableCell>
                </TableRow>
              ) : (
                data?.data?.runs.map((run) => <RunRow key={run.id} run={run} />)
              )}
              {!isFetching && !data?.data?.runs.length ? (
                <TableRow>
                  <TableCell align="center" colSpan={6}>
                    No runs yet.
                  </TableCell>
                </TableRow>
              ) : null}
            </TableBody>
          </Table>
        </Box>
        {data?.data?.pagination ? (
          <TablePagination
            component="div"
            count={data.data.pagination.total}
            onPageChange={(_e, p) => setPage(p + 1)}
            page={page - 1}
            rowsPerPage={data.data.pagination.pageSize}
            rowsPerPageOptions={[]}
          />
        ) : null}
      </Card>
    </Stack>
  );
}
