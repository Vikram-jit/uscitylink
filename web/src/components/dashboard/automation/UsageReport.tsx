'use client';

import * as React from 'react';
import {
  Alert,
  Box,
  Card,
  CardContent,
  CardHeader,
  Chip,
  CircularProgress,
  Divider,
  Grid,
  LinearProgress,
  MenuItem,
  Slider,
  Stack,
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableRow,
  TextField,
  Typography,
} from '@mui/material';
import { useTheme } from '@mui/material/styles';
import type { ApexOptions } from 'apexcharts';

import { Chart } from '@/components/core/chart';
import { useGetUsageReportQuery } from '@/redux/AutomationApiSlice';
import type { UsageReport as Report } from '@/redux/models/AutomationModel';

import { humanizeKey } from './utils';

const usd = (v: number, digits = 2) =>
  v === 0 ? '$0' : v < 0.01 && digits < 4 ? `$${v.toFixed(4)}` : `$${v.toLocaleString('en-US', { minimumFractionDigits: digits, maximumFractionDigits: digits })}`;
const cents = (v: number) => `${(v * 100).toFixed(v < 0.001 ? 3 : 2)}¢`;
const int = (v: number) => Math.round(v).toLocaleString('en-US');
const compact = (v: number) => new Intl.NumberFormat('en-US', { notation: 'compact', maximumFractionDigits: 1 }).format(v);
const shortDate = (d: string) => new Date(`${d}T00:00:00Z`).toLocaleDateString('en-US', { month: 'short', day: 'numeric', timeZone: 'UTC' });

const SOURCE_LABELS: Record<string, string> = {
  message: 'Driver documents (full read)',
  precheck: 'Quick check (every upload)',
  reread: 'Second read (keywords changed type)',
  sample: 'Training samples',
  test: 'Flow tests',
  demo: 'Demo data',
};

function Kpi({ label, value, hint }: { label: string; value: React.ReactNode; hint?: string }): React.JSX.Element {
  return (
    <Card sx={{ height: '100%' }}>
      <CardContent>
        <Typography color="text.secondary" variant="overline">
          {label}
        </Typography>
        <Typography variant="h4">{value}</Typography>
        {hint ? (
          <Typography color="text.secondary" variant="body2">
            {hint}
          </Typography>
        ) : null}
      </CardContent>
    </Card>
  );
}

function useBase(): ApexOptions {
  const theme = useTheme();
  return {
    chart: { background: 'transparent', toolbar: { show: false } },
    theme: { mode: theme.palette.mode },
    grid: { borderColor: theme.palette.divider, strokeDashArray: 2, xaxis: { lines: { show: false } } },
    dataLabels: { enabled: false },
    legend: { position: 'bottom' },
  };
}

function Charts({ report }: { report: Report }): React.JSX.Element {
  const theme = useTheme();
  const base = useBase();
  const categories = report.daily.map((d) => shortDate(d.date));
  const palette = [
    theme.palette.primary.main,
    theme.palette.success.main,
    theme.palette.warning.main,
    theme.palette.info.main,
    theme.palette.error.main,
    theme.palette.secondary.main,
  ];
  const xaxis: ApexOptions['xaxis'] = {
    categories,
    tickAmount: Math.min(10, categories.length),
    labels: { rotate: 0, style: { colors: theme.palette.text.secondary } },
    axisBorder: { show: false },
    axisTicks: { show: false },
  };

  const costOptions: ApexOptions = {
    ...base,
    colors: [theme.palette.primary.main, theme.palette.warning.main],
    stroke: { width: [0, 3], curve: 'smooth' },
    xaxis,
    yaxis: [
      { title: { text: 'Cost (USD)' }, labels: { formatter: (v) => `$${v.toFixed(2)}` } },
      { opposite: true, title: { text: 'Calls' }, labels: { formatter: (v) => String(Math.round(v)) } },
    ],
    plotOptions: { bar: { columnWidth: '55%', borderRadius: 3 } },
    tooltip: { shared: true, y: { formatter: (v, o) => (o?.seriesIndex === 0 ? `$${v.toFixed(4)}` : String(Math.round(v))) } },
  };
  const costSeries = [
    { name: 'Cost', type: 'bar', data: report.daily.map((d) => Number(d.cost.toFixed(4))) },
    { name: 'AI calls', type: 'line', data: report.daily.map((d) => d.calls) },
  ];

  const tokenOptions: ApexOptions = {
    ...base,
    chart: { ...base.chart, stacked: true },
    colors: [theme.palette.primary.main, theme.palette.success.main, theme.palette.warning.main, theme.palette.error.main],
    xaxis,
    yaxis: { labels: { formatter: (v) => compact(v) }, title: { text: 'Tokens' } },
    plotOptions: { bar: { columnWidth: '55%' } },
    tooltip: { y: { formatter: (v) => `${int(v)} tokens` } },
  };
  const tokenSeries = [
    { name: 'Input (normal price)', data: report.daily.map((d) => d.input) },
    { name: 'Input from cache (cheap)', data: report.daily.map((d) => d.cacheRead) },
    { name: 'Cache write (1.25×)', data: report.daily.map((d) => d.cacheWrite) },
    { name: 'Output (most expensive)', data: report.daily.map((d) => d.output) },
  ];

  const typeRows = [...report.byDocType].sort((a, b) => b.cost - a.cost);
  const donutOptions: ApexOptions = {
    ...base,
    colors: palette,
    labels: typeRows.map((r) => humanizeKey(r.docType)),
    plotOptions: { pie: { donut: { size: '62%', labels: { show: true, total: { show: true, label: 'Total', formatter: () => usd(report.totals.cost) } } } } },
    stroke: { width: 0 },
    tooltip: { y: { formatter: (v) => usd(v, 4) } },
  };

  const costTokenSplit = [
    report.totals.input * report.config.rate.input,
    report.totals.cacheRead * report.config.rate.cacheRead,
    report.totals.cacheWrite * report.config.rate.cacheWrite,
    report.totals.output * report.config.rate.output,
  ].map((v) => Number((v / 1_000_000).toFixed(4)));
  const splitOptions: ApexOptions = {
    ...base,
    colors: [theme.palette.primary.main, theme.palette.success.main, theme.palette.warning.main, theme.palette.error.main],
    labels: ['Input', 'Cache read', 'Cache write', 'Output'],
    plotOptions: { pie: { donut: { size: '62%' } } },
    stroke: { width: 0 },
    tooltip: { y: { formatter: (v) => usd(v, 4) } },
  };

  return (
    <Grid container spacing={2}>
      <Grid item lg={7} xs={12}>
        <Card>
          <CardHeader subheader={`Last ${report.days} days · ${report.timezoneNote}`} title="Daily cost and AI calls" />
          <CardContent>
            <Chart height={320} options={costOptions} series={costSeries} type="line" width="100%" />
          </CardContent>
        </Card>
      </Grid>
      <Grid item lg={5} xs={12}>
        <Card sx={{ height: '100%' }}>
          <CardHeader subheader="Which document types cost the most" title="Cost by document type" />
          <CardContent>
            {typeRows.length ? (
              <Chart height={320} options={donutOptions} series={typeRows.map((r) => Number(r.cost.toFixed(4)))} type="donut" width="100%" />
            ) : (
              <Typography color="text.secondary">No data yet.</Typography>
            )}
          </CardContent>
        </Card>
      </Grid>
      <Grid item lg={7} xs={12}>
        <Card>
          <CardHeader subheader="Where the tokens go each day" title="Tokens per day" />
          <CardContent>
            <Chart height={320} options={tokenOptions} series={tokenSeries} type="bar" width="100%" />
          </CardContent>
        </Card>
      </Grid>
      <Grid item lg={5} xs={12}>
        <Card sx={{ height: '100%' }}>
          <CardHeader subheader="Output tokens cost the most per token" title="Where the money goes" />
          <CardContent>
            {report.totals.cost ? (
              <Chart height={320} options={splitOptions} series={costTokenSplit} type="donut" width="100%" />
            ) : (
              <Typography color="text.secondary">No data yet.</Typography>
            )}
          </CardContent>
        </Card>
      </Grid>
    </Grid>
  );
}

function BreakdownTable({
  title,
  rows,
  label,
}: {
  title: string;
  rows: { name: string; calls: number; tokens: number; cost: number; latency: number }[];
  label: string;
}): React.JSX.Element {
  const total = rows.reduce((a, r) => a + r.cost, 0) || 1;
  return (
    <Card>
      <CardHeader title={title} />
      <Box sx={{ overflowX: 'auto' }}>
        <Table size="small">
          <TableHead>
            <TableRow>
              <TableCell>{label}</TableCell>
              <TableCell align="right">Calls</TableCell>
              <TableCell align="right">Tokens</TableCell>
              <TableCell align="right">Cost</TableCell>
              <TableCell align="right">Per call</TableCell>
              <TableCell align="right">Share</TableCell>
              <TableCell align="right">Avg time</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {rows.map((r) => (
              <TableRow key={r.name}>
                <TableCell>{r.name}</TableCell>
                <TableCell align="right">{int(r.calls)}</TableCell>
                <TableCell align="right">{compact(r.tokens)}</TableCell>
                <TableCell align="right">{usd(r.cost, 4)}</TableCell>
                <TableCell align="right">{r.calls ? cents(r.cost / r.calls) : '—'}</TableCell>
                <TableCell align="right">{Math.round((r.cost / total) * 100)}%</TableCell>
                <TableCell align="right">{(r.latency / 1000).toFixed(1)}s</TableCell>
              </TableRow>
            ))}
            {!rows.length ? (
              <TableRow>
                <TableCell align="center" colSpan={7}>
                  No data yet.
                </TableCell>
              </TableRow>
            ) : null}
          </TableBody>
        </Table>
      </Box>
    </Card>
  );
}

function Calculator({ report }: { report: Report }): React.JSX.Element {
  const [docsPerDay, setDocsPerDay] = React.useState(100);
  const [warmPct, setWarmPct] = React.useState(70);
  const est = report.estimate;

  return (
    <Card>
      <CardHeader
        subheader="Move the sliders to see what a month would cost on each model. Uses the token estimate above, so it works before you have real traffic."
        title="Cost calculator"
      />
      <CardContent>
        <Grid container spacing={4}>
          <Grid item md={6} xs={12}>
            <Typography gutterBottom variant="body2">
              Documents per day: <b>{docsPerDay}</b>
            </Typography>
            <Slider max={1000} min={5} onChange={(_e, v) => setDocsPerDay(v as number)} step={5} value={docsPerDay} />
          </Grid>
          <Grid item md={6} xs={12}>
            <Typography gutterBottom variant="body2">
              Calls that find the training examples already in cache (sent within {report.config.cacheMinutes} min of another): <b>{warmPct}%</b>
            </Typography>
            <Slider disabled={!est.cachingLikely} max={100} min={0} onChange={(_e, v) => setWarmPct(v as number)} step={5} value={warmPct} />
            {!est.cachingLikely ? (
              <Typography color="text.secondary" variant="caption">
                Prompt caching is not expected to apply yet: the fixed part of the prompt ({int(est.cachedPrefix)} tokens) is below the
                cache minimum. Add training examples and it will.
              </Typography>
            ) : null}
          </Grid>
        </Grid>
        <Box sx={{ overflowX: 'auto', mt: 2 }}>
          <Table size="small">
            <TableHead>
              <TableRow>
                <TableCell>Model</TableCell>
                <TableCell align="right">Per document (cache warm)</TableCell>
                <TableCell align="right">Per document (cache cold)</TableCell>
                <TableCell align="right">Per day</TableCell>
                <TableCell align="right">Per month (30 days)</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {est.byModel.map((m) => {
                const perDoc = est.cachingLikely ? (m.warm * warmPct + m.cold * (100 - warmPct)) / 100 : m.uncached;
                const active = m.model === report.config.model;
                return (
                  <TableRow key={m.model} selected={active}>
                    <TableCell>
                      {m.label} {active ? <Chip color="primary" label="in use" size="small" sx={{ ml: 1 }} /> : null}
                    </TableCell>
                    <TableCell align="right">{est.cachingLikely ? cents(m.warm) : '—'}</TableCell>
                    <TableCell align="right">{est.cachingLikely ? cents(m.cold) : cents(m.uncached)}</TableCell>
                    <TableCell align="right">{usd(perDoc * docsPerDay)}</TableCell>
                    <TableCell align="right">
                      <b>{usd(perDoc * docsPerDay * 30)}</b>
                    </TableCell>
                  </TableRow>
                );
              })}
            </TableBody>
          </Table>
        </Box>
      </CardContent>
    </Card>
  );
}

function TokenAnatomy({ report }: { report: Report }): React.JSX.Element {
  const est = report.estimate;
  const total = est.parts.reduce((a, p) => a + p.tokens, 0) || 1;
  const rate = report.config.rate;
  return (
    <Card>
      <CardHeader
        subheader="Estimated tokens for ONE document with your current setup. Real numbers appear in the charts once documents are processed."
        title="Where the tokens go for one document"
      />
      <Box sx={{ overflowX: 'auto' }}>
        <Table size="small">
          <TableHead>
            <TableRow>
              <TableCell>Part of the request</TableCell>
              <TableCell align="right">Tokens</TableCell>
              <TableCell align="right">Share</TableCell>
              <TableCell>Billed as</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {est.parts.map((p) => (
              <TableRow key={p.name}>
                <TableCell>{p.name}</TableCell>
                <TableCell align="right">{int(p.tokens)}</TableCell>
                <TableCell align="right">
                  <Stack alignItems="center" direction="row" justifyContent="flex-end" spacing={1}>
                    <LinearProgress sx={{ width: 80 }} value={(p.tokens / total) * 100} variant="determinate" />
                    <span>{Math.round((p.tokens / total) * 100)}%</span>
                  </Stack>
                </TableCell>
                <TableCell>
                  {p.output
                    ? `Output · $${rate.output}/M`
                    : p.cached && est.cachingLikely
                      ? `Cache: write $${rate.cacheWrite}/M, then read $${rate.cacheRead}/M`
                      : `Input · $${rate.input}/M`}
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </Box>
      <Divider />
      <CardContent>
        <Stack spacing={1}>
          <Typography variant="body2">
            <b>Training examples are the biggest lever.</b> Each example photo adds roughly 2,000 tokens to every document. Cached, that costs
            about {cents((2150 * rate.cacheRead) / 1_000_000)} per example per call; if the cache has expired (no document for {report.config.cacheMinutes}
            minutes) it costs about {cents((2150 * rate.cacheWrite) / 1_000_000)} per example. You currently use {est.activeExamples} (limits:{' '}
            {report.config.maxExamplesPerType} per type, {report.config.maxExamplesTotal} total, set with <code>AI_MAX_EXAMPLES_PER_TYPE</code> /{' '}
            <code>AI_MAX_EXAMPLES_TOTAL</code>).
          </Typography>
          <Typography variant="body2">
            <b>Output is the most expensive token</b> ({rate.output / rate.input}× the input price). The list of words the AI reports for keyword
            matching is part of that output.
          </Typography>
        </Stack>
      </CardContent>
    </Card>
  );
}

function RateCard({ report }: { report: Report }): React.JSX.Element {
  return (
    <Card>
      <CardHeader
        subheader="USD per million tokens. List prices cached on 2026-10-06 — confirm at anthropic.com/pricing. Change the model with AI_MODEL in server/.env."
        title="Price list"
      />
      <Box sx={{ overflowX: 'auto' }}>
        <Table size="small">
          <TableHead>
            <TableRow>
              <TableCell>Model</TableCell>
              <TableCell align="right">Input</TableCell>
              <TableCell align="right">Cache write</TableCell>
              <TableCell align="right">Cache read</TableCell>
              <TableCell align="right">Output</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {report.rateCard.map((r) => (
              <TableRow key={r.model} selected={r.model === report.config.model}>
                <TableCell>
                  {r.label} <code>{r.model}</code>
                </TableCell>
                <TableCell align="right">${r.input}</TableCell>
                <TableCell align="right">${r.cacheWrite}</TableCell>
                <TableCell align="right">${r.cacheRead}</TableCell>
                <TableCell align="right">${r.output}</TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </Box>
    </Card>
  );
}

export function UsageReport(): React.JSX.Element {
  const [days, setDays] = React.useState(30);
  const { data, isFetching, isError } = useGetUsageReportQuery({ days });
  const report = data?.data;

  if (isError) return <Alert severity="error">Could not load usage.</Alert>;
  if (!report) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center', py: 6 }}>
        <CircularProgress />
      </Box>
    );
  }

  const { totals, documents, spend, config } = report;
  const totalTokens = totals.input + totals.cacheRead + totals.cacheWrite + totals.output;
  const hasData = totals.calls > 0;

  return (
    <Stack spacing={3}>
      <Stack alignItems="center" direction="row" spacing={2}>
        <Typography color="text.secondary" sx={{ flex: 1 }} variant="body2">
          Every AI call is logged with its tokens and cost. Costs are calculated from the price list below at the time of the call; your Anthropic
          invoice is the source of truth.
        </Typography>
        {isFetching ? <CircularProgress size={20} /> : null}
        <TextField label="Period" onChange={(e) => setDays(Number(e.target.value))} select size="small" value={days}>
          <MenuItem value={7}>Last 7 days</MenuItem>
          <MenuItem value={30}>Last 30 days</MenuItem>
          <MenuItem value={90}>Last 90 days</MenuItem>
        </TextField>
      </Stack>

      {!config.hasApiKey || !config.automationEnabled ? (
        <Alert severity="warning">
          {!config.hasApiKey ? 'ANTHROPIC_API_KEY is not set' : 'AUTOMATION_ENABLED is not "true"'} on the server, so no documents are being
          analyzed and nothing is being billed.
        </Alert>
      ) : null}
      {report.demoRows > 0 ? (
        <Alert severity="info">
          This includes {int(report.demoRows)} DEMO rows so the charts have something to show. Remove them with{' '}
          <code>npx ts-node scripts/seed-demo-usage.ts --clear</code>.
        </Alert>
      ) : null}
      {!config.modelKnown ? (
        <Alert severity="warning">
          Model <code>{config.model}</code> is not in the price list; costs are estimated with {config.rate.label} prices.
        </Alert>
      ) : null}

      <Grid container spacing={2}>
        <Grid item lg={3} sm={6} xs={12}>
          <Kpi hint={`${int(totals.calls)} AI calls`} label={`Cost · last ${days} days`} value={usd(totals.cost)} />
        </Grid>
        <Grid item lg={3} sm={6} xs={12}>
          <Kpi
            hint={documents.read ? `${documents.avgCallsPerDocument} calls per document` : 'once documents are read'}
            label="Average cost per document"
            value={documents.read ? cents(documents.avgCostPerDocument) : '—'}
          />
        </Grid>
        <Grid item lg={3} sm={6} xs={12}>
          <Kpi hint={`${compact(totals.input + totals.cacheRead + totals.cacheWrite)} in · ${compact(totals.output)} out`} label="Tokens" value={compact(totalTokens)} />
        </Grid>
        <Grid item lg={3} sm={6} xs={12}>
          <Kpi
            hint={`${spend.activeDays} active day${spend.activeDays === 1 ? '' : 's'} so far`}
            label="Projected per month"
            value={hasData ? usd(spend.projectedMonthly) : '—'}
          />
        </Grid>
        <Grid item lg={3} sm={6} xs={12}>
          <Kpi hint={`${int(documents.failed)} failed · ${int(documents.skipped)} skipped`} label="Documents read" value={int(documents.read)} />
        </Grid>
        <Grid item lg={3} sm={6} xs={12}>
          <Kpi
            hint={totals.cacheHitRate ? 'of input tokens came from cache' : 'no cache hits yet'}
            label="Cache hit rate"
            value={`${Math.round(totals.cacheHitRate * 100)}%`}
          />
        </Grid>
        <Grid item lg={3} sm={6} xs={12}>
          <Kpi hint={`slowest 5%: ${(totals.p95LatencyMs / 1000).toFixed(1)}s`} label="Average read time" value={`${(totals.avgLatencyMs / 1000).toFixed(1)}s`} />
        </Grid>
        <Grid item lg={3} sm={6} xs={12}>
          <Kpi
            hint={documents.read ? `${((documents.corrections / documents.read) * 100).toFixed(1)}% of documents` : undefined}
            label="Staff corrections"
            value={int(documents.corrections)}
          />
        </Grid>
      </Grid>

      {spend.monthlyBudget ? (
        <Card>
          <CardContent>
            <Stack spacing={1}>
              <Typography variant="subtitle2">
                Monthly budget: {usd(spend.monthToDate)} of {usd(spend.monthlyBudget)} used this month
              </Typography>
              <LinearProgress
                color={(spend.budgetUsedPct ?? 0) > 90 ? 'error' : (spend.budgetUsedPct ?? 0) > 70 ? 'warning' : 'primary'}
                value={Math.min(100, spend.budgetUsedPct ?? 0)}
                variant="determinate"
              />
              <Typography color="text.secondary" variant="caption">
                Set with AI_MONTHLY_BUDGET_USD in server/.env. This is a gauge only; it does not stop processing.
              </Typography>
            </Stack>
          </CardContent>
        </Card>
      ) : null}

      <Charts report={report} />

      <Grid container spacing={2}>
        <Grid item lg={6} xs={12}>
          <BreakdownTable
            label="Document type"
            rows={report.byDocType.map((r) => ({ name: humanizeKey(r.docType), calls: r.calls, tokens: r.input + r.cacheRead + r.cacheWrite + r.output, cost: r.cost, latency: r.avgLatencyMs }))}
            title="By document type"
          />
        </Grid>
        <Grid item lg={6} xs={12}>
          <BreakdownTable
            label="What triggered it"
            rows={report.bySource.map((r) => ({ name: SOURCE_LABELS[r.source] || r.source, calls: r.calls, tokens: r.input + r.cacheRead + r.cacheWrite + r.output, cost: r.cost, latency: r.avgLatencyMs }))}
            title="By source"
          />
        </Grid>
        <Grid item xs={12}>
          <BreakdownTable
            label="Model"
            rows={report.byModel.map((r) => ({ name: r.model, calls: r.calls, tokens: r.input + r.cacheRead + r.cacheWrite + r.output, cost: r.cost, latency: r.avgLatencyMs }))}
            title="By model"
          />
        </Grid>
      </Grid>

      <TokenAnatomy report={report} />
      <Calculator report={report} />
      <RateCard report={report} />
    </Stack>
  );
}
