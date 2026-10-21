'use client';

import * as React from 'react';
import {
  Alert,
  Box,
  Button,
  Card,
  CardHeader,
  Chip,
  CircularProgress,
  Collapse,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  Divider,
  Grid,
  Link,
  Pagination,
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
import moment from 'moment';
import { toast } from 'react-toastify';

import {
  useCreateRuleSetVersionMutation,
  useGetRuleSetsQuery,
  useGetScaleChecksQuery,
  useGetTripsQuery,
  useLazyGetScaleReportQuery,
  useReviewRuleSetMutation,
} from '@/redux/AutomationApiSlice';
import type { DriverTrip, ScaleCheck, WeightRuleSet } from '@/redux/models/AutomationModel';

import { ROAD_LABELS, TripDialog } from './TripDialog';

import { ApprovalChip, SCALE_STATUS, ScaleCheckCard } from './ScaleCheckCard';
import MenuItem from '@mui/material/MenuItem';
import FormControlLabel from '@mui/material/FormControlLabel';
import Switch from '@mui/material/Switch';

const FILTERS = [
  { key: 'pending', label: 'Waiting for dispatch', query: { approval: 'pending' } },
  { key: 'all', label: 'All tickets', query: {} },
];

const lb = (n?: number | null) => (n === null || n === undefined ? '—' : Math.round(n).toLocaleString('en-US'));

// Spec §9 JSON report for audits and the client's systems
function ReportButton({ id }: { id: string }): React.JSX.Element {
  const [load, { isFetching }] = useLazyGetScaleReportQuery();
  const download = async () => {
    const res = await load({ id }).unwrap();
    const blob = new Blob([JSON.stringify(res.data, null, 2)], { type: 'application/json' });
    const a = document.createElement('a');
    a.href = URL.createObjectURL(blob);
    a.download = `scale-check-${id}.json`;
    a.click();
    URL.revokeObjectURL(a.href);
  };
  return (
    <Button disabled={isFetching} onClick={() => void download()} size="small" sx={{ mt: 1 }}>
      Download report (JSON)
    </Button>
  );
}

function CheckRow({ check }: { check: ScaleCheck }): React.JSX.Element {
  const [open, setOpen] = React.useState(false);
  const w = check.measured_weights || {};
  const status = SCALE_STATUS[check.status] || SCALE_STATUS.OCR_UNCERTAIN;
  return (
    <>
      <TableRow hover onClick={() => setOpen((o) => !o)} sx={{ cursor: 'pointer', '& td': { borderBottom: open ? 'none' : undefined } }}>
        <TableCell>{moment(check.createdAt).format('MMM D, h:mm A')}</TableCell>
        <TableCell>
          <Typography variant="body2">{check.driver_name || '—'}</Typography>
          {check.truck ? (
            <Typography color="text.secondary" variant="caption">
              Truck {check.truck}
            </Typography>
          ) : null}
        </TableCell>
        <TableCell sx={{ fontVariantNumeric: 'tabular-nums', whiteSpace: 'nowrap' }}>
          {lb(w.steer)} / {lb(w.drive)} / {lb(w.trailer)} / <b>{lb(w.gross)}</b>
        </TableCell>
        <TableCell>
          <Stack direction="row" flexWrap="wrap" gap={0.5}>
            <Chip color={status.color} label={status.label} size="small" />
            {check.previous_check_id ? <Chip label="Reweigh" size="small" variant="outlined" /> : null}
          </Stack>
        </TableCell>
        <TableCell>
          <ApprovalChip check={check} />
        </TableCell>
      </TableRow>
      <TableRow>
        <TableCell colSpan={5} sx={{ py: 0 }}>
          <Collapse in={open} unmountOnExit>
            <Box sx={{ pb: 2 }}>
              <ScaleCheckCard check={check} />
              <ReportButton id={check.id} />
              {check.driver_message ? (
                <Typography color="text.secondary" sx={{ mt: 1, whiteSpace: 'pre-wrap', fontSize: 12, maxWidth: 520 }}>
                  <b>Sent to driver:</b>
                  {'\n'}
                  {check.driver_message}
                </Typography>
              ) : null}
            </Box>
          </Collapse>
        </TableCell>
      </TableRow>
    </>
  );
}

const ROADS = [
  ['interstate', 'Interstate'],
  ['state_highway', 'State highway'],
  ['local', 'Local road'],
  ['all', 'All roads'],
];

function RuleSetDialog({ base, onClose }: { base: WeightRuleSet | null; onClose: () => void }): React.JSX.Element {
  const [create, { isLoading }] = useCreateRuleSetVersionMutation();
  const [form, setForm] = React.useState<any>({
    jurisdiction: base?.jurisdiction || '',
    road_class: base?.road_class || 'interstate',
    name: base?.name || '',
    single_axle_lb: base?.single_axle_lb ?? '',
    tandem_lb: base?.tandem_lb ?? '',
    gross_lb: base?.gross_lb ?? '',
    steer_target_lb: base?.steer_target_lb ?? 12000,
    sum_tolerance_lb: base?.sum_tolerance_lb ?? 100,
    min_confidence: base?.min_confidence ?? 0.8,
    kpra_max_ft: base?.kpra_max_ft ?? '',
    bridge_formula: base?.bridge_formula ?? true,
    review_months: base?.review_months ?? 12,
    citation: base?.citation || '',
    source_url: base?.source_url || '',
    notes: '',
  });
  const set = (key: string, value: any) => setForm((f: any) => ({ ...f, [key]: value }));
  const num = (key: string, label: string, helper?: string) => (
    <Grid item sm={6} xs={12}>
      <TextField fullWidth helperText={helper} label={label} onChange={(e) => set(key, e.target.value)} size="small" type="number" value={form[key]} />
    </Grid>
  );
  const save = async () => {
    try {
      const res = await create({ ...(base ? { baseId: base.id } : {}), ...form, kpra_max_ft: form.kpra_max_ft === '' ? null : form.kpra_max_ft }).unwrap();
      toast.success(res.message || 'Saved');
      onClose();
    } catch (err: any) {
      toast.error(err?.data?.message || 'Could not save');
    }
  };
  return (
    <Dialog fullWidth maxWidth="sm" onClose={onClose} open>
      <DialogTitle>{base ? `New version of ${base.jurisdiction} rules (v${base.version} → v${base.version + 1})` : 'Add state rules'}</DialogTitle>
      <DialogContent>
        <Stack spacing={2} sx={{ mt: 1 }}>
          <Alert severity="info">
            Take every value from the current statute or the state DOT, not from the federal defaults. Saving creates an unreviewed
            version; an admin marks it reviewed once checked.
          </Alert>
          {!base ? (
            <Grid container spacing={2}>
              <Grid item sm={4} xs={12}>
                <TextField fullWidth label="State code" onChange={(e) => set('jurisdiction', e.target.value.toUpperCase())} size="small" value={form.jurisdiction} />
              </Grid>
              <Grid item sm={4} xs={12}>
                <TextField fullWidth label="Road type" onChange={(e) => set('road_class', e.target.value)} select size="small" value={form.road_class}>
                  {ROADS.map(([k, v]) => (
                    <MenuItem key={k} value={k}>
                      {v}
                    </MenuItem>
                  ))}
                </TextField>
              </Grid>
              <Grid item sm={4} xs={12}>
                <TextField fullWidth label="Name" onChange={(e) => set('name', e.target.value)} size="small" value={form.name} />
              </Grid>
            </Grid>
          ) : null}
          <Grid container spacing={2}>
            {num('single_axle_lb', 'Single axle limit (lb)')}
            {num('tandem_lb', 'Tandem limit (lb)')}
            {num('gross_lb', 'Gross limit (lb)')}
            {num('kpra_max_ft', 'KPRA limit (ft)', 'Leave empty if this state has none')}
            {num('steer_target_lb', 'Steer target (lb)', 'Company planning target, not a legal limit')}
            {num('review_months', 'Re-review every (months)')}
            {num('sum_tolerance_lb', 'Sum tolerance (lb)', 'Max difference between axle sum and gross')}
            {num('min_confidence', 'Minimum read confidence', '0–1; below this the ticket needs review')}
          </Grid>
          <FormControlLabel control={<Switch checked={!!form.bridge_formula} onChange={(e) => set('bridge_formula', e.target.checked)} />} label="Apply the Federal Bridge Formula" />
          <TextField label="Legal citation" onChange={(e) => set('citation', e.target.value)} size="small" value={form.citation} />
          <TextField label="Source URL" onChange={(e) => set('source_url', e.target.value)} size="small" value={form.source_url} />
          <TextField label="Why is this changing? (audit note)" minRows={2} multiline onChange={(e) => set('notes', e.target.value)} required value={form.notes} />
        </Stack>
      </DialogContent>
      <DialogActions>
        <Button onClick={onClose}>Cancel</Button>
        <Button disabled={!form.notes.trim() || isLoading} onClick={() => void save()} variant="contained">
          {base ? `Save as v${base.version + 1}` : 'Save rules'}
        </Button>
      </DialogActions>
    </Dialog>
  );
}

function Trips(): React.JSX.Element {
  const { data } = useGetTripsQuery();
  const [editing, setEditing] = React.useState<DriverTrip | null>(null);
  const trips = data?.data || [];
  return (
    <Card>
      <CardHeader subheader="Routes dispatch has entered. Set or edit a route from the scale check card in chat." title="Active routes" />
      <Divider />
      {trips.length ? (
        <Table size="small">
          <TableHead>
            <TableRow>
              <TableCell>Driver</TableCell>
              <TableCell>Equipment</TableCell>
              <TableCell>Route</TableCell>
              <TableCell>Permits</TableCell>
              <TableCell />
            </TableRow>
          </TableHead>
          <TableBody>
            {trips.map((t) => (
              <TableRow hover key={t.id}>
                <TableCell>{t.driver_name || '—'}</TableCell>
                <TableCell>
                  {t.truck || '—'} / {t.trailer || '—'}
                </TableCell>
                <TableCell>{t.segments.map((s) => `${s.state} ${ROAD_LABELS[s.road_class] || s.road_class}`).join(' → ')}</TableCell>
                <TableCell>{t.permits.length ? t.permits.map((p) => `${p.state} ${p.number} (to ${p.expires_at})`).join(', ') : '—'}</TableCell>
                <TableCell align="right">
                  <Button onClick={() => setEditing(t)} size="small">
                    Edit
                  </Button>
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      ) : (
        <Typography color="text.secondary" sx={{ p: 3, textAlign: 'center' }}>
          No routes entered yet.
        </Typography>
      )}
      {editing?.driver_id ? <TripDialog driverId={editing.driver_id} driverName={editing.driver_name} onClose={() => setEditing(null)} /> : null}
    </Card>
  );
}

function RuleSets(): React.JSX.Element {
  const { data } = useGetRuleSetsQuery();
  const [review] = useReviewRuleSetMutation();
  const [editing, setEditing] = React.useState<WeightRuleSet | null | undefined>(undefined);
  const rows = data?.data || [];
  return (
    <Card>
      <CardHeader
        action={
          <Button onClick={() => setEditing(null)} variant="outlined">
            Add state rules
          </Button>
        }
        subheader="Versioned legal limits. Each route segment uses federal (on Interstate) plus that state's rules; a state with no reviewed rules sends the ticket to route review."
        title="Weight rules"
      />
      <Divider />
      <Box sx={{ overflowX: 'auto' }}>
        <Table size="small">
          <TableHead>
            <TableRow>
              <TableCell>Rules</TableCell>
              <TableCell>Single / tandem / gross</TableCell>
              <TableCell>KPRA / bridge</TableCell>
              <TableCell>Review</TableCell>
              <TableCell>Source</TableCell>
              <TableCell />
            </TableRow>
          </TableHead>
          <TableBody>
            {rows.map((r) => (
              <TableRow key={r.id} sx={{ opacity: r.active ? 1 : 0.55 }}>
                <TableCell>
                  <Typography variant="body2">
                    {r.jurisdiction} v{r.version} {r.active ? <Chip color="success" label="Active" size="small" sx={{ ml: 0.5 }} /> : null}
                  </Typography>
                  <Typography color="text.secondary" variant="caption">
                    {r.name}
                    {r.effective_date ? ` · from ${r.effective_date}` : ''}
                  </Typography>
                  {r.notes ? (
                    <Typography color="text.secondary" sx={{ display: 'block' }} variant="caption">
                      Note: {r.notes}
                    </Typography>
                  ) : null}
                </TableCell>
                <TableCell sx={{ fontVariantNumeric: 'tabular-nums' }}>
                  {lb(r.single_axle_lb)} / {lb(r.tandem_lb)} / {lb(r.gross_lb)}
                </TableCell>
                <TableCell>
                  {r.kpra_max_ft ? `${r.kpra_max_ft} ft` : 'no KPRA rule'} · {r.bridge_formula ? 'bridge formula' : 'no bridge'}
                </TableCell>
                <TableCell>
                  {r.verified ? (
                    <Chip color="success" label={`Reviewed by ${r.reviewed_by_name || 'admin'}`} size="small" variant="outlined" />
                  ) : (
                    <Chip color="warning" label={r.reviewed_at ? 'Review overdue' : 'Not reviewed'} size="small" />
                  )}
                  {r.review_due ? (
                    <Typography color="text.secondary" sx={{ display: 'block' }} variant="caption">
                      due {moment(r.review_due).format('MMM D, YYYY')}
                    </Typography>
                  ) : null}
                </TableCell>
                <TableCell sx={{ maxWidth: 280 }}>
                  <Typography variant="caption">{r.citation}</Typography>
                  {r.source_url ? (
                    <Link href={r.source_url} rel="noreferrer" sx={{ display: 'block', fontSize: 12 }} target="_blank">
                      Official source
                    </Link>
                  ) : null}
                </TableCell>
                <TableCell align="right">
                  {r.active ? (
                    <Stack direction="row" justifyContent="flex-end" spacing={0.5}>
                      <Button
                        onClick={async () => {
                          const res = await review({ id: r.id }).unwrap();
                          toast.success(res.message || 'Marked reviewed');
                        }}
                        size="small"
                      >
                        {r.verified ? 'Re-review' : 'Mark reviewed'}
                      </Button>
                      <Button onClick={() => setEditing(r)} size="small">
                        New version
                      </Button>
                    </Stack>
                  ) : null}
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </Box>
      {editing !== undefined ? <RuleSetDialog base={editing} onClose={() => setEditing(undefined)} /> : null}
    </Card>
  );
}

export function ScaleChecks(): React.JSX.Element {
  const [filter, setFilter] = React.useState(FILTERS[0].key);
  const [page, setPage] = React.useState(1);
  const active = FILTERS.find((f) => f.key === filter)!;
  const { data, isFetching } = useGetScaleChecksQuery({ page, ...active.query });
  const checks = data?.data?.checks || [];
  const total = data?.data?.pagination.total || 0;
  const pageSize = data?.data?.pagination.pageSize || 25;

  return (
    <Stack spacing={3}>
      <Alert severity="info">
        The scale agent checks every CAT ticket against the rules for the driver&apos;s route, the equipment profiles (bridge formula,
        KPRA, ratings) and the weight rules below. The best outcome is <b>Preliminary pass</b>; a dispatcher must release every load.
      </Alert>
      <Card>
        <Tabs onChange={(_e, v) => { setFilter(v); setPage(1); }} sx={{ px: 2 }} value={filter}>
          {FILTERS.map((f) => (
            <Tab
              key={f.key}
              label={f.key === 'pending' && data?.data?.pending ? `${f.label} (${data.data.pending})` : f.label}
              value={f.key}
            />
          ))}
        </Tabs>
        <Divider />
        {isFetching && !checks.length ? (
          <Box sx={{ display: 'flex', justifyContent: 'center', py: 6 }}>
            <CircularProgress />
          </Box>
        ) : checks.length ? (
          <Box sx={{ overflowX: 'auto' }}>
            <Table size="small">
              <TableHead>
                <TableRow>
                  <TableCell>Received</TableCell>
                  <TableCell>Driver</TableCell>
                  <TableCell>Steer / drive / trailer / gross (lb)</TableCell>
                  <TableCell>Result</TableCell>
                  <TableCell>Dispatch</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {checks.map((c) => (
                  <CheckRow check={c} key={c.id} />
                ))}
              </TableBody>
            </Table>
          </Box>
        ) : (
          <Typography color="text.secondary" sx={{ p: 4, textAlign: 'center' }}>
            {filter === 'pending' ? 'Nothing is waiting for dispatch.' : 'No scale tickets checked yet.'}
          </Typography>
        )}
        {total > pageSize ? (
          <Stack alignItems="center" sx={{ py: 2 }}>
            <Pagination count={Math.ceil(total / pageSize)} onChange={(_e, p) => setPage(p)} page={page} />
          </Stack>
        ) : null}
      </Card>
      <Trips />
      <RuleSets />
    </Stack>
  );
}
