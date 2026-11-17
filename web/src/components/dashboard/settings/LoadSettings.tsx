'use client';

import * as React from 'react';
import { Alert, Box, Card, CardContent, CardHeader, Divider, Stack, Switch, Typography } from '@mui/material';
import { toast } from 'react-toastify';

import { LoadFeatureKey, useGetLoadFeaturesQuery, useUpdateLoadFeaturesMutation } from '@/redux/TripApiSlice';
import { useAutomationAccess } from '@/components/dashboard/automation/AdminGuard';

// Which switches only matter when another one is on (shown as such; the server checks the same)
const NEEDS: Partial<Record<LoadFeatureKey, LoadFeatureKey>> = {
  driver_buttons: 'driver_loads',
  driver_upcoming: 'driver_loads',
};

const GROUPS: { title: string; keys: LoadFeatureKey[] }[] = [
  { title: 'Driver app', keys: ['driver_loads', 'driver_buttons', 'driver_upcoming'] },
  { title: 'Driver chat', keys: ['driver_chat_lines', 'driver_chat_words', 'driver_paperwork'] },
  { title: 'Dispatch', keys: ['auto_send_next', 'loads_from_chat'] },
];

/**
 * Settings → Loads: switch each part of the load work on or off (server/src/services/trips/loadFeatures.ts).
 * Admins change them; everyone else sees them. A change reaches the driver and staff apps at once.
 */
export function LoadSettings(): React.JSX.Element {
  const { data, isLoading } = useGetLoadFeaturesQuery();
  const [save, { isLoading: saving }] = useUpdateLoadFeaturesMutation();
  const { isAdmin } = useAutomationAccess();
  const features = data?.data?.features;
  const list = data?.data?.list || [];

  const flip = async (key: LoadFeatureKey, on: boolean) => {
    try {
      await save({ [key]: on }).unwrap();
      const title = list.find((f) => f.key === key)?.title || key;
      toast.success(`${title}: ${on ? 'on' : 'off'}`);
    } catch (err: any) {
      toast.error(err?.data?.message || 'Could not save the load settings');
    }
  };

  return (
    <Card data-testid="loadSettings">
      <CardHeader title="Loads" subheader="Turn each part of the load work on or off — drivers' apps and the dashboards follow at once" />
      <Divider />
      <CardContent>
        {!isAdmin && (
          <Alert severity="info" sx={{ mb: 2 }}>
            Only an admin can change these.
          </Alert>
        )}
        {isLoading || !features ? (
          <Typography color="text.secondary">Loading…</Typography>
        ) : (
          <Stack spacing={3}>
            {GROUPS.map((g) => (
              <Box key={g.title}>
                <Typography variant="overline" color="text.secondary">
                  {g.title}
                </Typography>
                <Stack divider={<Divider flexItem />} sx={{ border: 1, borderColor: 'divider', borderRadius: 2 }}>
                  {g.keys.map((key) => {
                    const info = list.find((f) => f.key === key);
                    if (!info) return null;
                    const parent = NEEDS[key];
                    const blocked = !!parent && !features[parent];
                    return (
                      <Stack key={key} direction="row" spacing={2} alignItems="center" sx={{ px: 2, py: 1.5, opacity: blocked ? 0.55 : 1 }}>
                        <Box sx={{ flex: 1, minWidth: 0 }}>
                          <Typography variant="body1" fontWeight={600}>
                            {info.title}
                          </Typography>
                          <Typography variant="body2" color="text.secondary">
                            {info.help}
                            {blocked ? ` (Needs "${list.find((f) => f.key === parent)?.title}" on.)` : ''}
                          </Typography>
                        </Box>
                        <Switch
                          checked={features[key]}
                          disabled={!isAdmin || saving}
                          onChange={(e) => void flip(key, e.target.checked)}
                          inputProps={{ 'aria-label': info.title }}
                          data-testid={`loadFeature-${key}`}
                        />
                      </Stack>
                    );
                  })}
                </Stack>
              </Box>
            ))}
          </Stack>
        )}
      </CardContent>
    </Card>
  );
}
