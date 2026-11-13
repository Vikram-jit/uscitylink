'use client';

import * as React from 'react';
import {
  Box,
  Button,
  Card,
  Chip,
  Collapse,
  IconButton,
  InputAdornment,
  LinearProgress,
  Stack,
  Tab,
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableRow,
  Tabs,
  TextField,
  Typography,
} from '@mui/material';
import { Download, ExpandLess, ExpandMore, Search } from '@mui/icons-material';

import { MilesRow, useGetMilesReportQuery } from '@/redux/TripApiSlice';

import { LoadDrawer } from './LoadDrawer';

// Miles by driver (pay) and by truck (maintenance) for a date range, from the legs each one drove —
// a load handed over mid-way counts for each driver / truck only for their own part. A team leg
// counts for both drivers. Each row opens the legs behind it; CSV for payroll.

const day = (d: Date) => d.toISOString().slice(0, 10);
const when = (iso?: string | null) =>
  iso ? new Intl.DateTimeFormat('en-US', { month: '2-digit', day: '2-digit', hour: '2-digit', minute: '2-digit' }).format(new Date(iso)) : '—';

function csv(rows: MilesRow[], by: 'driver' | 'truck') {
  const head = [by === 'driver' ? 'Driver' : 'Truck', 'Invoice #', 'Trip #', by === 'driver' ? 'Truck' : 'Driver(s)', 'From', 'To', 'Started', 'Ended', 'Hours', 'Miles', 'Miles source'];
  const esc = (v: any) => `"${String(v ?? '').replace(/"/g, '""')}"`;
  const lines = [head.map(esc).join(',')];
  for (const r of rows) {
    for (const i of r.items) {
      lines.push(
        [r.name, i.invoiceNo, i.tripNo, by === 'driver' ? i.truck : i.drivers.join(' + '), i.from, i.to, i.startedAt, i.endedAt, i.hours, i.miles, i.milesSource || '']
          .map(esc)
          .join(',')
      );
    }
  }
  const blob = new Blob([lines.join('\n')], { type: 'text/csv' });
  const a = document.createElement('a');
  a.href = URL.createObjectURL(blob);
  a.download = `miles-by-${by}.csv`;
  a.click();
  URL.revokeObjectURL(a.href);
}

export function MilesBoard(): React.JSX.Element {
  const [by, setBy] = React.useState<'driver' | 'truck'>('driver');
  const [from, setFrom] = React.useState(day(new Date(Date.now() - 6 * 86400000)));
  const [to, setTo] = React.useState(day(new Date()));
  const [q, setQ] = React.useState('');
  const [open, setOpen] = React.useState<string | null>(null);
  const [openLoad, setOpenLoad] = React.useState<number | null>(null);
  const { data, isFetching } = useGetMilesReportQuery({
    by,
    from: new Date(`${from}T00:00:00`).toISOString(),
    to: new Date(`${to}T23:59:59`).toISOString(),
    q: q.trim() || undefined,
  });
  const rows = data?.data?.rows || [];
  const totals = data?.data?.totals;

  return (
    <Card data-testid="milesBoard">
      <Stack direction={{ xs: 'column', md: 'row' }} spacing={2} sx={{ p: 2 }} alignItems={{ md: 'center' }}>
        <Tabs value={by} onChange={(_, v) => setBy(v)}>
          <Tab value="driver" label="By driver (pay)" />
          <Tab value="truck" label="By truck (maintenance)" />
        </Tabs>
        <Box sx={{ flexGrow: 1 }} />
        <TextField size="small" type="date" label="From" InputLabelProps={{ shrink: true }} value={from} onChange={(e) => setFrom(e.target.value)} />
        <TextField size="small" type="date" label="To" InputLabelProps={{ shrink: true }} value={to} onChange={(e) => setTo(e.target.value)} />
        <TextField
          size="small"
          placeholder={by === 'driver' ? 'Driver or truck' : 'Truck or driver'}
          value={q}
          onChange={(e) => setQ(e.target.value)}
          InputProps={{
            startAdornment: (
              <InputAdornment position="start">
                <Search fontSize="small" />
              </InputAdornment>
            ),
          }}
        />
        <Button variant="outlined" startIcon={<Download />} disabled={!rows.length} onClick={() => csv(rows, by)}>
          Download CSV
        </Button>
      </Stack>
      {totals && (
        <Stack direction="row" spacing={1} sx={{ px: 2, pb: 1.5 }}>
          <Chip label={`${totals.miles.toLocaleString()} mi`} color="primary" />
          <Chip variant="outlined" label={`${totals.legs} leg${totals.legs === 1 ? '' : 's'} delivered`} />
          {totals.missing > 0 && <Chip color="warning" variant="outlined" label={`${totals.missing} without miles — enter them on the load`} />}
        </Stack>
      )}
      {isFetching && <LinearProgress />}
      <Table size="small">
        <TableHead>
          <TableRow>
            <TableCell width={40} />
            <TableCell>{by === 'driver' ? 'Driver' : 'Truck'}</TableCell>
            <TableCell align="right">Miles</TableCell>
            <TableCell align="right">Loads</TableCell>
            <TableCell align="right">Hours on loads</TableCell>
            <TableCell>{by === 'driver' ? 'Trucks' : 'Drivers'}</TableCell>
          </TableRow>
        </TableHead>
        <TableBody>
          {rows.map((r) => (
            <React.Fragment key={r.key}>
              <TableRow hover sx={{ cursor: 'pointer' }} onClick={() => setOpen(open === r.key ? null : r.key)} data-testid="milesRow">
                <TableCell>
                  <IconButton size="small">{open === r.key ? <ExpandLess fontSize="small" /> : <ExpandMore fontSize="small" />}</IconButton>
                </TableCell>
                <TableCell>
                  <Typography variant="body2" fontWeight={700}>
                    {r.name}
                  </Typography>
                </TableCell>
                <TableCell align="right">
                  <Typography variant="body2" fontWeight={700}>
                    {r.miles.toLocaleString()}
                  </Typography>
                  {r.missing > 0 && (
                    <Typography variant="caption" color="warning.main">
                      {r.missing} missing
                    </Typography>
                  )}
                </TableCell>
                <TableCell align="right">
                  {r.loads}
                  {r.legs !== r.loads ? ` (${r.legs} legs)` : ''}
                </TableCell>
                <TableCell align="right">{r.hours.toLocaleString()}</TableCell>
                <TableCell>
                  <Typography variant="caption" color="text.secondary">
                    {r.others.join(', ') || '—'}
                  </Typography>
                </TableCell>
              </TableRow>
              <TableRow>
                <TableCell colSpan={6} sx={{ p: 0, borderBottom: open === r.key ? undefined : 'none' }}>
                  <Collapse in={open === r.key} unmountOnExit>
                    <Table size="small" sx={{ bgcolor: 'action.hover', '& td, & th': { fontSize: 12 } }}>
                      <TableHead>
                        <TableRow>
                          <TableCell>Invoice · trip</TableCell>
                          <TableCell>{by === 'driver' ? 'Truck' : 'Driver(s)'}</TableCell>
                          <TableCell>From → to</TableCell>
                          <TableCell>Started → ended</TableCell>
                          <TableCell align="right">Miles</TableCell>
                        </TableRow>
                      </TableHead>
                      <TableBody>
                        {r.items.map((i) => (
                          <TableRow key={i.legId} hover sx={{ cursor: i.loadId ? 'pointer' : 'default' }} onClick={() => i.loadId && setOpenLoad(i.loadId)}>
                            <TableCell>
                              <b>{i.invoiceNo || 'No invoice #'}</b> · #{i.tripNo}
                            </TableCell>
                            <TableCell>{by === 'driver' ? i.truck || '—' : i.drivers.join(' + ')}</TableCell>
                            <TableCell>
                              {i.from} → {i.to}
                            </TableCell>
                            <TableCell>
                              {when(i.startedAt)} → {when(i.endedAt)}
                              {i.hours !== null ? ` · ${i.hours} h` : ''}
                            </TableCell>
                            <TableCell align="right">
                              {i.miles !== null ? i.miles.toLocaleString() : <Typography variant="caption" color="warning.main">missing</Typography>}
                              {i.milesSource === 'manual' ? ' (typed)' : i.milesSource === 'gps' ? ' (GPS times)' : ''}
                            </TableCell>
                          </TableRow>
                        ))}
                      </TableBody>
                    </Table>
                  </Collapse>
                </TableCell>
              </TableRow>
            </React.Fragment>
          ))}
          {!rows.length && !isFetching && (
            <TableRow>
              <TableCell colSpan={6} align="center" sx={{ py: 6, color: 'text.secondary' }}>
                No delivered legs in these dates
              </TableCell>
            </TableRow>
          )}
        </TableBody>
      </Table>
      <LoadDrawer loadId={openLoad} onClose={() => setOpenLoad(null)} />
    </Card>
  );
}
