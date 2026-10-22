'use client';

import * as React from 'react';
import {
  Box,
  Card,
  CardHeader,
  Chip,
  Dialog,
  DialogContent,
  DialogTitle,
  Divider,
  IconButton,
  InputAdornment,
  Link,
  Stack,
  Table,
  TableBody,
  TableCell,
  TableHead,
  TablePagination,
  TableRow,
  TextField,
  Tooltip,
  Typography,
} from '@mui/material';
import { AndroidLogo, AppleLogo, MagnifyingGlass, Question, X } from '@phosphor-icons/react';
import dayjs from 'dayjs';
import relativeTime from 'dayjs/plugin/relativeTime';

import { useGetInstallsQuery, useGetInstallUsersQuery, type AppVersionStatus, type InstallUsersArgs } from '@/redux/AppVersionApiSlice';

dayjs.extend(relativeTime);

const STATUS_COLOR: Record<AppVersionStatus, 'success' | 'warning' | 'default'> = { active: 'success', pending: 'warning', deprecated: 'default' };

export function PlatformIcon({ platform, size = 16 }: { platform: string | null; size?: number }): React.JSX.Element {
  if (platform === 'android') return <AndroidLogo size={size} />;
  if (platform === 'ios') return <AppleLogo size={size} />;
  return <Question size={size} />;
}

const platformLabel = (p: string | null) => (p === 'android' ? 'Android' : p === 'ios' ? 'iOS' : 'Platform unknown');
const ago = (d: string | null) => (d ? dayjs(d).fromNow() : '—');

export type UsersTarget = InstallUsersArgs & { title: string };

// Logins on one version (from user_profiles), searchable and paged
export function InstallUsersDialog({ target, onClose }: { target: UsersTarget; onClose: () => void }): React.JSX.Element {
  const [search, setSearch] = React.useState('');
  const [query, setQuery] = React.useState('');
  const [page, setPage] = React.useState(0);
  const [pageSize, setPageSize] = React.useState(25);

  React.useEffect(() => {
    const t = setTimeout(() => {
      setQuery(search.trim());
      setPage(0);
    }, 350);
    return () => clearTimeout(t);
  }, [search]);

  const { title, ...args } = target;
  const { data, isFetching } = useGetInstallUsersQuery({ ...args, search: query, page: page + 1, pageSize });
  const users = data?.data?.users || [];

  return (
    <Dialog fullWidth maxWidth="lg" onClose={onClose} open>
      <DialogTitle sx={{ pr: 6 }}>
        {title}
        <Typography color="text.secondary" variant="body2">
          {data ? `${data.data.total.toLocaleString('en-US')} login${data.data.total === 1 ? '' : 's'}` : 'Loading…'} · from what each
          app last reported
        </Typography>
        <IconButton onClick={onClose} sx={{ position: 'absolute', right: 12, top: 12 }}>
          <X />
        </IconButton>
      </DialogTitle>
      <DialogContent dividers sx={{ p: 0 }}>
        <Box sx={{ p: 2 }}>
          <TextField
            InputProps={{
              startAdornment: (
                <InputAdornment position="start">
                  <MagnifyingGlass />
                </InputAdornment>
              ),
            }}
            fullWidth
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Search name, phone, email or driver number"
            size="small"
            value={search}
          />
        </Box>
        <Box sx={{ overflowX: 'auto', opacity: isFetching ? 0.6 : 1 }}>
          <Table size="small" sx={{ minWidth: 820 }}>
            <TableHead>
              <TableRow>
                <TableCell>Name</TableCell>
                <TableCell>Role</TableCell>
                <TableCell>Phone / email</TableCell>
                <TableCell>Driver #</TableCell>
                <TableCell>Platform</TableCell>
                <TableCell>Version</TableCell>
                <TableCell>Last login</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {users.map((u) => (
                <TableRow hover key={u.id}>
                  <TableCell>
                    <Stack alignItems="center" direction="row" spacing={1}>
                      <Box
                        sx={{ width: 8, height: 8, borderRadius: '50%', flexShrink: 0, bgcolor: u.isOnline ? 'success.main' : 'action.disabled' }}
                        title={u.isOnline ? 'Online' : 'Offline'}
                      />
                      <span>{u.username || '—'}</span>
                    </Stack>
                  </TableCell>
                  <TableCell sx={{ textTransform: 'capitalize' }}>{u.role?.name || '—'}</TableCell>
                  <TableCell>
                    <Typography variant="body2">{u.user?.phone_number || '—'}</Typography>
                    {u.user?.email ? (
                      <Typography color="text.secondary" variant="caption">
                        {u.user.email}
                      </Typography>
                    ) : null}
                  </TableCell>
                  <TableCell>{u.user?.driver_number || '—'}</TableCell>
                  <TableCell>
                    <Stack alignItems="center" direction="row" spacing={0.75}>
                      <PlatformIcon platform={u.platform} />
                      <span>{u.platform ? platformLabel(u.platform) : '—'}</span>
                    </Stack>
                  </TableCell>
                  <TableCell sx={{ fontFamily: 'monospace' }}>
                    {u.version ? `${u.version}+${u.buildNumber}` : '—'}
                    {u.appUpdate === '0' ? <Chip color="warning" label="needs update" size="small" sx={{ ml: 1 }} /> : null}
                  </TableCell>
                  <TableCell sx={{ whiteSpace: 'nowrap' }}>
                    <Tooltip title={u.last_login ? dayjs(u.last_login).format('MMM D, YYYY h:mm A') : ''}>
                      <span>{ago(u.last_login)}</span>
                    </Tooltip>
                  </TableCell>
                </TableRow>
              ))}
              {!users.length ? (
                <TableRow>
                  <TableCell colSpan={7}>
                    <Typography color="text.secondary" sx={{ py: 3, textAlign: 'center' }}>
                      {isFetching ? 'Loading…' : 'No users found.'}
                    </Typography>
                  </TableCell>
                </TableRow>
              ) : null}
            </TableBody>
          </Table>
        </Box>
        <TablePagination
          component="div"
          count={data?.data?.total || 0}
          onPageChange={(_e, p) => setPage(p)}
          onRowsPerPageChange={(e) => {
            setPageSize(Number(e.target.value));
            setPage(0);
          }}
          page={page}
          rowsPerPage={pageSize}
          rowsPerPageOptions={[25, 50, 100]}
        />
      </DialogContent>
    </Dialog>
  );
}

// What is actually installed: every version + build the logins last reported
export function Installs({ onOpen }: { onOpen: (t: UsersTarget) => void }): React.JSX.Element {
  const { data, isLoading } = useGetInstallsQuery();
  const installs = data?.data?.installs || [];
  const notReported = data?.data?.notReported || 0;

  return (
    <Card>
      <CardHeader
        subheader="From each user's last app check-in (user_profiles). Click a number to see who."
        title="Installed versions"
      />
      <Divider />
      <Box sx={{ overflowX: 'auto' }}>
        <Table size="small" sx={{ minWidth: 720 }}>
          <TableHead>
            <TableRow>
              <TableCell>Version</TableCell>
              <TableCell>Platforms</TableCell>
              <TableCell align="right">Users</TableCell>
              <TableCell align="right">Online now</TableCell>
              <TableCell>Last login</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {installs.map((i) => {
              const v = `${i.version}+${i.buildNumber}`;
              return (
                <TableRow hover key={v}>
                  <TableCell sx={{ fontFamily: 'monospace', fontWeight: 600 }}>{v}</TableCell>
                  <TableCell>
                    <Stack direction="row" flexWrap="wrap" gap={0.75}>
                      {i.platforms.map((p) => (
                        <Tooltip
                          key={p.platform || 'unknown'}
                          title={p.status ? `${platformLabel(p.platform)} · ${p.status}` : `${platformLabel(p.platform)} · not added as an app version`}
                        >
                          <Chip
                            color={p.status ? STATUS_COLOR[p.status] : 'default'}
                            icon={<PlatformIcon platform={p.platform} />}
                            label={p.users.toLocaleString('en-US')}
                            onClick={() =>
                              onOpen({ title: `${platformLabel(p.platform)} · ${v}`, version: i.version, buildNumber: i.buildNumber, platform: p.platform || 'unknown' })
                            }
                            size="small"
                            variant={p.status === 'active' ? 'filled' : 'outlined'}
                          />
                        </Tooltip>
                      ))}
                    </Stack>
                  </TableCell>
                  <TableCell align="right">
                    <Link component="button" onClick={() => onOpen({ title: `All users on ${v}`, version: i.version, buildNumber: i.buildNumber })} underline="hover">
                      {i.users.toLocaleString('en-US')}
                    </Link>
                  </TableCell>
                  <TableCell align="right">{i.online || '—'}</TableCell>
                  <TableCell sx={{ whiteSpace: 'nowrap' }}>{ago(i.lastSeen)}</TableCell>
                </TableRow>
              );
            })}
            {notReported ? (
              <TableRow hover>
                <TableCell colSpan={2}>
                  <Typography color="text.secondary" variant="body2">
                    No version reported (never opened a build that sends it, or web-only logins)
                  </Typography>
                </TableCell>
                <TableCell align="right">
                  <Link component="button" onClick={() => onOpen({ title: 'Logins with no version reported' })} underline="hover">
                    {notReported.toLocaleString('en-US')}
                  </Link>
                </TableCell>
                <TableCell colSpan={2} />
              </TableRow>
            ) : null}
            {!installs.length && !notReported ? (
              <TableRow>
                <TableCell colSpan={5}>
                  <Typography color="text.secondary" sx={{ py: 3, textAlign: 'center' }}>
                    {isLoading ? 'Loading…' : 'No installs reported yet.'}
                  </Typography>
                </TableCell>
              </TableRow>
            ) : null}
          </TableBody>
        </Table>
      </Box>
    </Card>
  );
}
