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
  DialogContentText,
  DialogTitle,
  Divider,
  IconButton,
  Link,
  MenuItem,
  Stack,
  Tab,
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableRow,
  Tabs,
  TextField,
  Tooltip,
  Typography,
} from '@mui/material';
import { AndroidLogo, AppleLogo, PencilSimple, Plus, Trash } from '@phosphor-icons/react';
import dayjs from 'dayjs';
import { toast } from 'react-toastify';

import {
  useDeleteAppVersionMutation,
  useGetAppVersionsQuery,
  useSaveAppVersionMutation,
  type AppPlatform,
  type AppVersion,
  type AppVersionInput,
  type AppVersionStatus,
} from '@/redux/AppVersionApiSlice';

import { Installs, InstallUsersDialog, type UsersTarget } from './Installs';

const STATUS: Record<AppVersionStatus, { label: string; color: 'success' | 'warning' | 'default'; help: string }> = {
  active: { label: 'Active', color: 'success', help: 'Live in the store — users on this build are up to date' },
  pending: { label: 'Pending', color: 'warning', help: 'Submitted / in review — not accepted yet' },
  deprecated: { label: 'Deprecated', color: 'default', help: 'Old build — users on it are asked to update' },
};

const PLATFORM: Record<AppPlatform, { label: string; icon: React.ReactNode }> = {
  android: { label: 'Android', icon: <AndroidLogo size={18} /> },
  ios: { label: 'iOS', icon: <AppleLogo size={18} /> },
};

function splitPubspec(value: string): { version: string; buildNumber: number } | null {
  const m = value.trim().match(/^(\d+(?:\.\d+){1,3})\+(\d+)$/);
  return m ? { version: m[1], buildNumber: Number(m[2]) } : null;
}

const fullVersion = (v: Pick<AppVersion, 'version' | 'buildNumber'>) => `${v.version}+${v.buildNumber}`;

// Would this change leave a platform without any active build? Then every user of it is told to update.
function leavesNoActive(rows: AppVersion[], target: AppVersion, nextStatus?: AppVersionStatus): boolean {
  if (target.status !== 'active' || nextStatus === 'active') return false;
  return !rows.some((r) => r.id !== target.id && r.platform === target.platform && r.status === 'active');
}

function EditDialog({ row, onClose }: { row: AppVersion | null; onClose: () => void }): React.JSX.Element {
  const [save, { isLoading }] = useSaveAppVersionMutation();
  const [form, setForm] = React.useState<Partial<AppVersionInput>>(
    row
      ? { id: row.id, version: row.version, buildNumber: row.buildNumber, platform: row.platform, status: row.status, releaseNotes: row.releaseNotes }
      : { platform: 'android', status: 'pending', version: '', releaseNotes: '' }
  );
  const set = (patch: Partial<AppVersionInput>) => setForm((f) => ({ ...f, ...patch }));

  // The pubspec form "1.3.21+24" may be typed or pasted into the version box. It is split only on
  // blur / save: splitting while typing would cut "1.3.21+2" before the 4 arrives.
  const split = splitPubspec(form.version || '');
  const effective = split || { version: (form.version || '').trim(), buildNumber: form.buildNumber };
  const normalize = () => split && set(split);

  const valid =
    /^\d+(\.\d+){1,3}$/.test(effective.version) && Number.isInteger(Number(effective.buildNumber)) && Number(effective.buildNumber) > 0;

  const submit = async () => {
    try {
      const res = await save({ ...form, ...effective, buildNumber: Number(effective.buildNumber) }).unwrap();
      toast.success(res.message || 'Saved');
      onClose();
    } catch (err: any) {
      toast.error(err?.data?.message || 'Could not save');
    }
  };

  return (
    <Dialog fullWidth maxWidth="sm" onClose={onClose} open>
      <DialogTitle>{row ? `Edit ${PLATFORM[row.platform].label} ${fullVersion(row)}` : 'Add app version'}</DialogTitle>
      <DialogContent>
        <Stack spacing={2.5} sx={{ mt: 1 }}>
          <TextField label="Platform" onChange={(e) => set({ platform: e.target.value as AppPlatform })} select size="small" value={form.platform}>
            {(Object.keys(PLATFORM) as AppPlatform[]).map((p) => (
              <MenuItem key={p} value={p}>
                {PLATFORM[p].label}
              </MenuItem>
            ))}
          </TextField>
          <Stack direction={{ xs: 'column', sm: 'row' }} spacing={2}>
            <TextField
              fullWidth
              helperText="pubspec.yaml version, e.g. 1.3.21 — or enter 1.3.21+24 to fill both"
              label="Version"
              onBlur={normalize}
              onChange={(e) => set({ version: e.target.value })}
              size="small"
              value={form.version ?? ''}
            />
            <TextField
              helperText="The number after +"
              label="Build number"
              onChange={(e) => set({ buildNumber: e.target.value === '' ? undefined : Number(e.target.value) })}
              size="small"
              sx={{ minWidth: 160 }}
              type="number"
              value={effective.buildNumber ?? ''}
            />
          </Stack>
          <TextField
            helperText={STATUS[form.status || 'pending'].help}
            label="Status"
            onChange={(e) => set({ status: e.target.value as AppVersionStatus })}
            select
            size="small"
            value={form.status}
          >
            {(Object.keys(STATUS) as AppVersionStatus[]).map((s) => (
              <MenuItem key={s} value={s}>
                {STATUS[s].label}
              </MenuItem>
            ))}
          </TextField>
          <TextField
            label="Release notes"
            minRows={3}
            multiline
            onChange={(e) => set({ releaseNotes: e.target.value })}
            placeholder="What changed in this build"
            size="small"
            value={form.releaseNotes ?? ''}
          />
        </Stack>
      </DialogContent>
      <DialogActions>
        <Button onClick={onClose}>Cancel</Button>
        <Button disabled={!valid || isLoading} onClick={() => void submit()} variant="contained">
          Save
        </Button>
      </DialogActions>
    </Dialog>
  );
}

type Pending =
  | { kind: 'status'; row: AppVersion; status: AppVersionStatus }
  | { kind: 'delete'; row: AppVersion };

export function AppVersions(): React.JSX.Element {
  const { data, isLoading } = useGetAppVersionsQuery();
  const [save] = useSaveAppVersionMutation();
  const [remove] = useDeleteAppVersionMutation();
  const [platform, setPlatform] = React.useState<'all' | AppPlatform>('all');
  const [editing, setEditing] = React.useState<AppVersion | null | undefined>(undefined);
  const [confirm, setConfirm] = React.useState<Pending | null>(null);
  const [usersOf, setUsersOf] = React.useState<UsersTarget | null>(null);

  const all = data?.data?.versions || [];
  const rows = platform === 'all' ? all : all.filter((r) => r.platform === platform);

  const applyStatus = async (row: AppVersion, status: AppVersionStatus) => {
    try {
      await save({ id: row.id, status }).unwrap();
      toast.success(`${PLATFORM[row.platform].label} ${fullVersion(row)} is now ${STATUS[status].label.toLowerCase()}`);
    } catch (err: any) {
      toast.error(err?.data?.message || 'Could not update');
    }
  };

  const changeStatus = (row: AppVersion, status: AppVersionStatus) => {
    if (status === row.status) return;
    if (leavesNoActive(all, row, status)) setConfirm({ kind: 'status', row, status });
    else void applyStatus(row, status);
  };

  const runConfirm = async () => {
    if (!confirm) return;
    if (confirm.kind === 'status') await applyStatus(confirm.row, confirm.status);
    else {
      try {
        await remove({ id: confirm.row.id }).unwrap();
        toast.success(`Deleted ${PLATFORM[confirm.row.platform].label} ${fullVersion(confirm.row)}`);
      } catch (err: any) {
        toast.error(err?.data?.message || 'Could not delete');
      }
    }
    setConfirm(null);
  };

  return (
    <Stack spacing={3}>
      <Alert severity="info">
        The app sends its version, build number and platform when it opens. A user is up to date only if that exact build is{' '}
        <b>Active</b> here, so keep the build currently in the store active and add the new one as Active when it goes live. Older builds
        can stay active during the rollout, then mark them Deprecated.
      </Alert>

      <Stack direction={{ xs: 'column', md: 'row' }} spacing={2}>
        {(Object.keys(PLATFORM) as AppPlatform[]).map((p) => {
          const live = all.filter((r) => r.platform === p && r.status === 'active');
          return (
            <Card key={p} sx={{ flex: 1, p: 2 }}>
              <Stack alignItems="center" direction="row" spacing={1} sx={{ mb: 1 }}>
                {PLATFORM[p].icon}
                <Typography variant="subtitle1">{PLATFORM[p].label} — live builds</Typography>
              </Stack>
              {live.length ? (
                <Stack direction="row" flexWrap="wrap" gap={1}>
                  {live.map((r) => (
                    <Chip color="success" key={r.id} label={fullVersion(r)} size="small" variant="outlined" />
                  ))}
                </Stack>
              ) : (
                <Typography color="warning.main" variant="body2">
                  No active build — every {PLATFORM[p].label} user is told to update.
                </Typography>
              )}
            </Card>
          );
        })}
        <Card sx={{ flex: 1, p: 2 }}>
          <Typography variant="subtitle1">Logins needing an update</Typography>
          <Typography variant="h4">{data?.data?.updatePending ?? '—'}</Typography>
          <Typography color="text.secondary" variant="caption">
            Last opened on a build that isn&apos;t active
          </Typography>
        </Card>
      </Stack>

      <Card>
        <CardHeader
          action={
            <Button onClick={() => setEditing(null)} startIcon={<Plus />} variant="contained">
              Add version
            </Button>
          }
          title="App versions"
        />
        <Tabs onChange={(_e, v) => setPlatform(v)} sx={{ px: 2 }} value={platform}>
          <Tab label={`All (${all.length})`} value="all" />
          <Tab label="Android" value="android" />
          <Tab label="iOS" value="ios" />
        </Tabs>
        <Divider />
        <Box sx={{ overflowX: 'auto' }}>
          <Table size="small" sx={{ minWidth: 760 }}>
            <TableHead>
              <TableRow>
                <TableCell>Platform</TableCell>
                <TableCell>Version</TableCell>
                <TableCell>Status</TableCell>
                <TableCell align="right">Users</TableCell>
                <TableCell>Release notes</TableCell>
                <TableCell>Added</TableCell>
                <TableCell />
              </TableRow>
            </TableHead>
            <TableBody>
              {rows.map((r) => (
                <TableRow hover key={r.id}>
                  <TableCell>
                    <Stack alignItems="center" direction="row" spacing={1}>
                      {PLATFORM[r.platform]?.icon}
                      <span>{PLATFORM[r.platform]?.label || r.platform || '—'}</span>
                    </Stack>
                  </TableCell>
                  <TableCell sx={{ fontFamily: 'monospace', fontWeight: 600 }}>{fullVersion(r)}</TableCell>
                  <TableCell>
                    <TextField
                      onChange={(e) => changeStatus(r, e.target.value as AppVersionStatus)}
                      select
                      size="small"
                      sx={{ minWidth: 140 }}
                      value={r.status}
                      SelectProps={{
                        renderValue: (v) => <Chip color={STATUS[v as AppVersionStatus].color} label={STATUS[v as AppVersionStatus].label} size="small" />,
                      }}
                    >
                      {(Object.keys(STATUS) as AppVersionStatus[]).map((s) => (
                        <MenuItem key={s} value={s}>
                          {STATUS[s].label}
                        </MenuItem>
                      ))}
                    </TextField>
                  </TableCell>
                  <TableCell align="right">
                    <Tooltip title="Logins on this build (same platform, or platform not recorded) — click to see who">
                      <Link
                        component="button"
                        onClick={() =>
                          setUsersOf({
                            title: `${PLATFORM[r.platform]?.label || r.platform} · ${fullVersion(r)}`,
                            version: r.version,
                            buildNumber: String(r.buildNumber),
                            platform: r.platform,
                            withUnknown: true,
                          })
                        }
                        underline="hover"
                      >
                        {r.users.toLocaleString('en-US')}
                      </Link>
                    </Tooltip>
                  </TableCell>
                  <TableCell sx={{ maxWidth: 280 }}>
                    <Typography color={r.releaseNotes ? 'text.primary' : 'text.secondary'} noWrap title={r.releaseNotes || ''} variant="body2">
                      {r.releaseNotes || '—'}
                    </Typography>
                  </TableCell>
                  <TableCell sx={{ whiteSpace: 'nowrap' }}>{dayjs(r.createdAt).format('MMM D, YYYY')}</TableCell>
                  <TableCell align="right" sx={{ whiteSpace: 'nowrap' }}>
                    <IconButton onClick={() => setEditing(r)} size="small">
                      <PencilSimple />
                    </IconButton>
                    <Tooltip title={r.status === 'active' ? 'Deprecate it before deleting' : 'Delete'}>
                      <span>
                        <IconButton disabled={r.status === 'active'} onClick={() => setConfirm({ kind: 'delete', row: r })} size="small">
                          <Trash />
                        </IconButton>
                      </span>
                    </Tooltip>
                  </TableCell>
                </TableRow>
              ))}
              {!rows.length ? (
                <TableRow>
                  <TableCell colSpan={7}>
                    <Typography color="text.secondary" sx={{ py: 3, textAlign: 'center' }}>
                      {isLoading ? 'Loading…' : 'No versions yet.'}
                    </Typography>
                  </TableCell>
                </TableRow>
              ) : null}
            </TableBody>
          </Table>
        </Box>
      </Card>

      <Installs onOpen={setUsersOf} />

      {usersOf ? <InstallUsersDialog onClose={() => setUsersOf(null)} target={usersOf} /> : null}
      {editing !== undefined ? <EditDialog onClose={() => setEditing(undefined)} row={editing} /> : null}

      <Dialog onClose={() => setConfirm(null)} open={!!confirm}>
        {confirm ? (
          <>
            <DialogTitle>
              {confirm.kind === 'delete'
                ? `Delete ${PLATFORM[confirm.row.platform].label} ${fullVersion(confirm.row)}?`
                : `Mark ${PLATFORM[confirm.row.platform].label} ${fullVersion(confirm.row)} ${STATUS[confirm.status].label.toLowerCase()}?`}
            </DialogTitle>
            <DialogContent>
              <DialogContentText>
                {confirm.kind === 'delete'
                  ? 'This removes the record. Users on this build are already treated as out of date.'
                  : `This is the only active ${PLATFORM[confirm.row.platform].label} build. After this, every ${PLATFORM[confirm.row.platform].label} user will be told to update. Add the new build as Active first if it is live.`}
              </DialogContentText>
            </DialogContent>
            <DialogActions>
              <Button onClick={() => setConfirm(null)}>Cancel</Button>
              <Button color={confirm.kind === 'delete' ? 'error' : 'warning'} onClick={() => void runConfirm()} variant="contained">
                {confirm.kind === 'delete' ? 'Delete' : 'Continue'}
              </Button>
            </DialogActions>
          </>
        ) : null}
      </Dialog>
    </Stack>
  );
}
