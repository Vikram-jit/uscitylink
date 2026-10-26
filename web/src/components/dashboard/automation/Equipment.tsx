'use client';

import * as React from 'react';
import {
  Alert,
  Box,
  Button,
  Card,
  CardHeader,
  Chip,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  Divider,
  Grid,
  IconButton,
  InputAdornment,
  Stack,
  Tab,
  Table,
  TableBody,
  TableCell,
  TableHead,
  TablePagination,
  TableRow,
  Tabs,
  TextField,
  Typography,
} from '@mui/material';
import { ArrowsClockwise, MagnifyingGlass, PencilSimple, Plus, Trash, UploadSimple } from '@phosphor-icons/react';
import { toast } from 'react-toastify';

import {
  useDeleteEquipmentMutation,
  useGetEquipmentQuery,
  useImportEquipmentMutation,
  useSaveEquipmentMutation,
  useSyncEquipmentFromYardMutation,
} from '@/redux/AutomationApiSlice';
import type { EquipmentProfile } from '@/redux/models/AutomationModel';

type Kind = 'tractor' | 'trailer';
type Field = { key: keyof EquipmentProfile; label: string; help?: string };

// New trailers start at the standard length (the server does the same for import and yard sync).
// It's a default, not a measurement, so it doesn't count when deciding whether a unit needs details.
const TRAILER_LENGTH_FT = 53;
const DEFAULTED: (keyof EquipmentProfile)[] = ['length_ft'];

const FIELDS: Record<Kind, { title: string; fields: Field[] }[]> = {
  tractor: [
    {
      title: 'Axle layout (for the bridge formula)',
      fields: [
        { key: 'steer_to_drive_center_ft', label: 'Steer axle → center of drive tandem (ft)' },
        { key: 'drive_spread_ft', label: 'Drive axle spread (ft)', help: 'Center to center of the two drive axles' },
        { key: 'kingpin_to_drive_center_ft', label: 'Fifth wheel ahead of drive center (ft)', help: 'Kingpin position; 0 = over the drive center' },
        { key: 'fifth_wheel_range_in', label: 'Fifth wheel slide range (in)' },
      ],
    },
    {
      title: 'Ratings (GAWR / tires)',
      fields: [
        { key: 'steer_rating_lb', label: 'Steer axle rating (lb)', help: 'Lowest of axle, tire and wheel ratings' },
        { key: 'drive_rating_lb', label: 'Drive tandem rating (lb)' },
        { key: 'gvwr_lb', label: 'GVWR (lb)' },
      ],
    },
  ],
  trailer: [
    {
      title: 'Axle layout',
      fields: [
        { key: 'axle_count', label: 'Rear axles' },
        { key: 'length_ft', label: 'Trailer length (ft)', help: 'Standard is 53 ft' },
        { key: 'kpra_ft', label: 'Kingpin → center of rearmost axle (ft)', help: 'At the current tandem position, not to the bumper' },
        { key: 'trailer_spread_ft', label: 'Trailer axle spread (ft)' },
      ],
    },
    {
      title: 'Sliding tandems',
      fields: [
        { key: 'hole_spacing_in', label: 'Hole spacing (in)' },
        { key: 'holes_forward_available', label: 'Holes available forward' },
        { key: 'holes_back_available', label: 'Holes available back' },
        { key: 'lb_per_hole', label: 'Measured lb per hole', help: 'Learned from reweighs; only enter a value you measured' },
      ],
    },
    { title: 'Ratings', fields: [{ key: 'trailer_rating_lb', label: 'Trailer tandem rating (lb)' }] },
  ],
};

const CSV_TEMPLATE = `kind,unit_number,steer_to_drive_center_ft,drive_spread_ft,kingpin_to_drive_center_ft,steer_rating_lb,drive_rating_lb,kpra_ft,trailer_spread_ft,axle_count,hole_spacing_in,holes_forward_available,holes_back_available,trailer_rating_lb
tractor,31765,18,4.33,1,12000,34000,,,,,,,
trailer,87565,,,,,,40,4.08,2,6,8,8,34000`;

function EditDialog({ profile, kind, onClose }: { profile: Partial<EquipmentProfile> | null; kind: Kind; onClose: () => void }): React.JSX.Element {
  const [save, { isLoading }] = useSaveEquipmentMutation();
  const [form, setForm] = React.useState<Partial<EquipmentProfile>>(
    profile || { kind, ...(kind === 'trailer' ? { length_ft: TRAILER_LENGTH_FT } : {}) }
  );
  const submit = async () => {
    try {
      const res = await save({ ...form, kind }).unwrap();
      toast.success(res.message || 'Saved');
      onClose();
    } catch (err: any) {
      toast.error(err?.data?.message || 'Could not save');
    }
  };
  return (
    <Dialog fullWidth maxWidth="md" onClose={onClose} open>
      <DialogTitle>{profile?.id ? `Edit ${kind} ${profile.unit_number}` : `Add ${kind}`}</DialogTitle>
      <DialogContent>
        <Stack spacing={2.5} sx={{ mt: 1 }}>
          <TextField
            disabled={!!profile?.id}
            helperText="As printed on the scale ticket / truck number in the yard"
            label="Unit number"
            onChange={(e) => setForm((f) => ({ ...f, unit_number: e.target.value }))}
            size="small"
            sx={{ maxWidth: 280 }}
            value={form.unit_number || ''}
          />
          {FIELDS[kind].map((section) => (
            <Stack key={section.title} spacing={1}>
              <Typography variant="subtitle2">{section.title}</Typography>
              <Grid container spacing={2}>
                {section.fields.map((f) => (
                  <Grid item key={f.key} md={4} sm={6} xs={12}>
                    <TextField
                      fullWidth
                      helperText={f.help}
                      label={f.label}
                      onChange={(e) => setForm((prev) => ({ ...prev, [f.key]: e.target.value === '' ? null : Number(e.target.value) }))}
                      size="small"
                      type="number"
                      value={(form[f.key] as any) ?? ''}
                    />
                  </Grid>
                ))}
              </Grid>
            </Stack>
          ))}
          <TextField label="Notes" onChange={(e) => setForm((f) => ({ ...f, notes: e.target.value }))} size="small" value={form.notes || ''} />
        </Stack>
      </DialogContent>
      <DialogActions>
        <Button onClick={onClose}>Cancel</Button>
        <Button disabled={!form.unit_number || isLoading} onClick={() => void submit()} variant="contained">
          Save
        </Button>
      </DialogActions>
    </Dialog>
  );
}

function ImportDialog({ onClose }: { onClose: () => void }): React.JSX.Element {
  const [importCsv, { isLoading }] = useImportEquipmentMutation();
  const [csv, setCsv] = React.useState(CSV_TEMPLATE);
  const submit = async () => {
    try {
      const res = await importCsv({ csv }).unwrap();
      toast.success(res.message || 'Imported');
      onClose();
    } catch (err: any) {
      toast.error(err?.data?.message || 'Import failed');
    }
  };
  return (
    <Dialog fullWidth maxWidth="md" onClose={onClose} open>
      <DialogTitle>Import equipment (CSV)</DialogTitle>
      <DialogContent>
        <Stack spacing={1.5} sx={{ mt: 1 }}>
          <Alert severity="info">
            Paste rows from a spreadsheet. The first row must be the column names (the example shows them all). Existing units are
            updated; empty cells are left blank.
          </Alert>
          <TextField minRows={10} multiline onChange={(e) => setCsv(e.target.value)} sx={{ '& textarea': { fontFamily: 'monospace', fontSize: 12 } }} value={csv} />
        </Stack>
      </DialogContent>
      <DialogActions>
        <Button onClick={onClose}>Cancel</Button>
        <Button disabled={isLoading} onClick={() => void submit()} variant="contained">
          Import
        </Button>
      </DialogActions>
    </Dialog>
  );
}

// Added by "Sync from yard" (or by hand) with no measurements yet
const needsDetails = (p: EquipmentProfile): boolean =>
  FIELDS[p.kind as Kind].every((section) =>
    section.fields.every((f) => DEFAULTED.includes(f.key) || p[f.key] === null || p[f.key] === undefined)
  );

const show = (v?: number | null, suffix = '') => (v === null || v === undefined ? '—' : `${Number(v).toLocaleString('en-US')}${suffix}`);

export function Equipment(): React.JSX.Element {
  const { data } = useGetEquipmentQuery();
  const [remove] = useDeleteEquipmentMutation();
  const [kind, setKind] = React.useState<Kind>('trailer');
  const [editing, setEditing] = React.useState<Partial<EquipmentProfile> | null | undefined>(undefined);
  const [importing, setImporting] = React.useState(false);
  const [sync, { isLoading: syncing }] = useSyncEquipmentFromYardMutation();
  const [search, setSearch] = React.useState('');
  const [onlyMissing, setOnlyMissing] = React.useState(false);
  const all = data?.data || [];
  // Unit numbers are numeric strings: 10065 before 100165
  const ofKind = all
    .filter((p) => p.kind === kind)
    .sort((a, b) => a.unit_number.localeCompare(b.unit_number, undefined, { numeric: true }));
  const missingCount = ofKind.filter(needsDetails).length;
  const [page, setPage] = React.useState(0);
  const [pageSize, setPageSize] = React.useState(10);
  // Unit numbers only; an exact match is listed first, then numbers starting with it, then the rest
  const q = search.trim();
  const rank = (u: string) => (u === q ? 0 : u.startsWith(q) ? 1 : 2);
  const filtered = ofKind
    .filter((p) => (!q || p.unit_number.includes(q)) && (!onlyMissing || needsDetails(p)))
    .sort((a, b) => (q ? rank(a.unit_number) - rank(b.unit_number) : 0));
  const lastPage = Math.max(0, Math.ceil(filtered.length / pageSize) - 1);
  const rows = filtered.slice(Math.min(page, lastPage) * pageSize, (Math.min(page, lastPage) + 1) * pageSize);
  React.useEffect(() => setPage(0), [kind, q, onlyMissing]);

  const runSync = async () => {
    try {
      const res = await sync().unwrap();
      toast.success(res.message || 'Synced');
      const removed = (res.data?.tractor?.removedByStaff || 0) + (res.data?.trailer?.removedByStaff || 0);
      if (removed) toast.info(`${removed} unit${removed === 1 ? ' was' : 's were'} removed here before, so not added back.`);
      if (res.data?.tractor?.added || res.data?.trailer?.added) setOnlyMissing(true);
    } catch (err: any) {
      toast.error(err?.data?.message || 'Sync failed');
    }
  };

  return (
    <Stack spacing={3}>
      <Alert severity="info">
        A CAT ticket only shows axle-group totals. Axle spacing, kingpin-to-rear-axle (KPRA), tandem holes and ratings let the scale
        agent check the bridge formula, trailer-length rules and equipment limits, and estimate how many holes to slide.
      </Alert>
      <Card>
        <CardHeader
          action={
            <Stack direction="row" flexWrap="wrap" gap={1} justifyContent="flex-end">
              <Button disabled={syncing} onClick={() => void runSync()} startIcon={<ArrowsClockwise />} variant="outlined">
                {syncing ? 'Syncing…' : 'Sync from yard'}
              </Button>
              <Button onClick={() => setImporting(true)} startIcon={<UploadSimple />}>
                Import CSV
              </Button>
              <Button onClick={() => setEditing(null)} startIcon={<Plus />} variant="contained">
                Add {kind}
              </Button>
            </Stack>
          }
          subheader="Sync from yard adds every active truck and trailer with empty measurements for you to fill in"
          title="Equipment profiles"
        />
        <Tabs onChange={(_e, v) => setKind(v)} sx={{ px: 2 }} value={kind}>
          <Tab label={`Trailers (${all.filter((p) => p.kind === 'trailer').length})`} value="trailer" />
          <Tab label={`Tractors (${all.filter((p) => p.kind === 'tractor').length})`} value="tractor" />
        </Tabs>
        <Divider />
        <Stack alignItems="center" direction="row" flexWrap="wrap" gap={1.5} sx={{ px: 2, py: 1.5 }}>
          <TextField
            InputProps={{
              startAdornment: (
                <InputAdornment position="start">
                  <MagnifyingGlass />
                </InputAdornment>
              ),
            }}
            inputProps={{ inputMode: 'numeric', pattern: '[0-9]*', 'aria-label': `${kind} number` }}
            onChange={(e) => setSearch(e.target.value.replace(/\D/g, ''))}
            placeholder={`Search ${kind} number`}
            size="small"
            sx={{ width: 260, maxWidth: '100%' }}
            value={search}
          />
          <Chip
            color={onlyMissing ? 'warning' : 'default'}
            label={`Needs details (${missingCount})`}
            onClick={() => setOnlyMissing((v) => !v)}
            variant={onlyMissing ? 'filled' : 'outlined'}
          />
        </Stack>
        <Divider />
        <Box sx={{ overflowX: 'auto' }}>
          <Table size="small">
            <TableHead>
              {kind === 'trailer' ? (
                <TableRow>
                  <TableCell>Trailer</TableCell>
                  <TableCell>KPRA</TableCell>
                  <TableCell>Axle spread</TableCell>
                  <TableCell>Holes fwd / back</TableCell>
                  <TableCell>Lb per hole</TableCell>
                  <TableCell>Rating</TableCell>
                  <TableCell />
                </TableRow>
              ) : (
                <TableRow>
                  <TableCell>Tractor</TableCell>
                  <TableCell>Steer → drive center</TableCell>
                  <TableCell>Drive spread</TableCell>
                  <TableCell>Fifth wheel</TableCell>
                  <TableCell>Steer / drive rating</TableCell>
                  <TableCell />
                </TableRow>
              )}
            </TableHead>
            <TableBody>
              {rows.map((p) => (
                <TableRow hover key={p.id}>
                  <TableCell>
                    <b>{p.unit_number}</b>
                    {needsDetails(p) ? <Chip color="warning" label="Needs details" size="small" sx={{ ml: 1 }} variant="outlined" /> : null}
                    {p.notes ? (
                      <Typography color="text.secondary" sx={{ display: 'block' }} variant="caption">
                        {p.notes}
                      </Typography>
                    ) : null}
                  </TableCell>
                  {kind === 'trailer' ? (
                    <>
                      <TableCell>{show(p.kpra_ft, ' ft')}</TableCell>
                      <TableCell>{show(p.trailer_spread_ft, ' ft')}</TableCell>
                      <TableCell>
                        {show(p.holes_forward_available)} / {show(p.holes_back_available)}
                        {p.hole_spacing_in ? ` · ${p.hole_spacing_in} in` : ''}
                      </TableCell>
                      <TableCell>
                        {p.lb_per_hole ? (
                          <Chip label={`${show(p.lb_per_hole)} lb · ${p.lb_per_hole_samples || 0} reweigh${p.lb_per_hole_samples === 1 ? '' : 's'}`} size="small" />
                        ) : (
                          <Typography color="text.secondary" variant="caption">
                            not measured yet
                          </Typography>
                        )}
                      </TableCell>
                      <TableCell>{show(p.trailer_rating_lb, ' lb')}</TableCell>
                    </>
                  ) : (
                    <>
                      <TableCell>{show(p.steer_to_drive_center_ft, ' ft')}</TableCell>
                      <TableCell>{show(p.drive_spread_ft, ' ft')}</TableCell>
                      <TableCell>{show(p.kingpin_to_drive_center_ft, ' ft')}</TableCell>
                      <TableCell>
                        {show(p.steer_rating_lb)} / {show(p.drive_rating_lb)}
                      </TableCell>
                    </>
                  )}
                  <TableCell align="right" sx={{ whiteSpace: 'nowrap' }}>
                    <IconButton onClick={() => setEditing(p)} size="small">
                      <PencilSimple />
                    </IconButton>
                    <IconButton
                      onClick={async () => {
                        await remove({ id: p.id });
                        toast.success(`Removed ${p.unit_number}`);
                      }}
                      size="small"
                    >
                      <Trash />
                    </IconButton>
                  </TableCell>
                </TableRow>
              ))}
              {!rows.length ? (
                <TableRow>
                  <TableCell colSpan={7}>
                    <Typography color="text.secondary" sx={{ py: 3, textAlign: 'center' }}>
                      {ofKind.length
                        ? 'No matches.'
                        : `No ${kind}s yet. Use Sync from yard, add them one by one or import a spreadsheet.`}
                    </Typography>
                  </TableCell>
                </TableRow>
              ) : null}
            </TableBody>
          </Table>
        </Box>
        <TablePagination
          component="div"
          count={filtered.length}
          labelRowsPerPage="Per page"
          onPageChange={(_e, p) => setPage(p)}
          onRowsPerPageChange={(e) => {
            setPageSize(Number(e.target.value));
            setPage(0);
          }}
          page={Math.min(page, lastPage)}
          rowsPerPage={pageSize}
          rowsPerPageOptions={[10, 25, 50]}
        />
      </Card>
      {editing !== undefined ? <EditDialog kind={kind} onClose={() => setEditing(undefined)} profile={editing} /> : null}
      {importing ? <ImportDialog onClose={() => setImporting(false)} /> : null}
    </Stack>
  );
}
