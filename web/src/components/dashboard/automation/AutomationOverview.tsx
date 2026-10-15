'use client';

import * as React from 'react';
import RouterLink from 'next/link';
import {
  Box,
  Button,
  Card,
  CardContent,
  CardHeader,
  Grid,
  MenuItem,
  Stack,
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableRow,
  TextField,
  Typography,
} from '@mui/material';

import { paths } from '@/paths';
import { useGetAutomationStatsQuery, useGetFlowsQuery } from '@/redux/AutomationApiSlice';

import { humanizeKey } from './utils';

function Stat({ label, value, href }: { label: string; value: React.ReactNode; href?: string }): React.JSX.Element {
  return (
    <Card sx={{ height: '100%' }}>
      <CardContent>
        <Typography color="text.secondary" variant="overline">
          {label}
        </Typography>
        <Typography variant="h4">{value}</Typography>
        {href ? (
          <Button component={RouterLink} href={href} size="small" sx={{ mt: 1, px: 0 }}>
            View
          </Button>
        ) : null}
      </CardContent>
    </Card>
  );
}

export function AutomationOverview(): React.JSX.Element {
  const [days, setDays] = React.useState(7);
  const { data } = useGetAutomationStatsQuery({ days });
  const { data: flows } = useGetFlowsQuery();
  const stats = data?.data;

  const rows = React.useMemo(() => {
    const byKey: Record<string, { done: number; failed: number; skipped: number; confidence: number[] }> = {};
    (stats?.byType || []).forEach((r) => {
      const key = r.doc_type_key || (r.status === 'done' ? 'other' : r.status);
      byKey[key] = byKey[key] || { done: 0, failed: 0, skipped: 0, confidence: [] };
      const count = Number(r.count);
      if (r.status === 'done') {
        byKey[key].done += count;
        if (r.avgConfidence !== null) byKey[key].confidence.push(Number(r.avgConfidence));
      } else if (r.status === 'failed') byKey[key].failed += count;
      else if (r.status === 'skipped') byKey[key].skipped += count;
    });
    return Object.entries(byKey).sort((a, b) => b[1].done - a[1].done);
  }, [stats]);

  const analyzed = rows.reduce((sum, [, r]) => sum + r.done, 0);
  const failed = rows.reduce((sum, [, r]) => sum + r.failed, 0);
  const liveFlows = flows?.data?.filter((f) => f.active && !f.shadow_mode).length ?? 0;
  const shadowFlows = flows?.data?.filter((f) => f.active && f.shadow_mode).length ?? 0;

  return (
    <Stack spacing={3}>
      <Stack alignItems="center" direction="row">
        <Box sx={{ flex: 1 }} />
        <TextField label="Period" onChange={(e) => setDays(Number(e.target.value))} select size="small" value={days}>
          <MenuItem value={1}>Today</MenuItem>
          <MenuItem value={7}>Last 7 days</MenuItem>
          <MenuItem value={30}>Last 30 days</MenuItem>
        </TextField>
      </Stack>
      <Grid container spacing={2}>
        <Grid item md={3} sm={6} xs={12}>
          <Stat label="Documents read" value={analyzed} />
        </Grid>
        <Grid item md={3} sm={6} xs={12}>
          <Stat href={paths.automation.runs} label="Flow matches" value={stats?.matchedRuns ?? 0} />
        </Grid>
        <Grid item md={3} sm={6} xs={12}>
          <Stat href={paths.automation.review} label="Corrections / failed" value={`${stats?.corrections ?? 0} / ${failed}`} />
        </Grid>
        <Grid item md={3} sm={6} xs={12}>
          <Stat href={paths.automation.flows} label="Flows live / shadow" value={`${liveFlows} / ${shadowFlows}`} />
        </Grid>
      </Grid>
      <Card>
        <CardHeader title="By document type" />
        <Box sx={{ overflowX: 'auto' }}>
          <Table>
            <TableHead>
              <TableRow>
                <TableCell>Type</TableCell>
                <TableCell align="right">Read</TableCell>
                <TableCell align="right">Avg confidence</TableCell>
                <TableCell align="right">Failed</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {rows.map(([key, r]) => (
                <TableRow key={key}>
                  <TableCell>{humanizeKey(key)}</TableCell>
                  <TableCell align="right">{r.done}</TableCell>
                  <TableCell align="right">
                    {r.confidence.length
                      ? `${Math.round((r.confidence.reduce((a, b) => a + b, 0) / r.confidence.length) * 100)}%`
                      : '—'}
                  </TableCell>
                  <TableCell align="right">{r.failed}</TableCell>
                </TableRow>
              ))}
              {!rows.length ? (
                <TableRow>
                  <TableCell align="center" colSpan={4}>
                    No documents read in this period.
                  </TableCell>
                </TableRow>
              ) : null}
            </TableBody>
          </Table>
        </Box>
      </Card>
    </Stack>
  );
}
