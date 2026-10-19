'use client';

import * as React from 'react';
import {
  Alert,
  Box,
  Button,
  Card,
  CardContent,
  CardHeader,
  Chip,
  CircularProgress,
  Divider,
  FormControlLabel,
  Radio,
  Stack,
  Switch,
  Typography,
} from '@mui/material';
import moment from 'moment';
import { toast } from 'react-toastify';

import { useGetAutomationSettingsQuery, useUpdateAutomationSettingsMutation } from '@/redux/AutomationApiSlice';
import type { AutomationSettings } from '@/redux/models/AutomationModel';

// Plain-language guidance shown next to each model
const MODEL_NOTES: Record<string, { summary: string; tag?: { label: string; color: 'primary' | 'success' | 'default' } }> = {
  'claude-opus-5-5': {
    summary: 'Most accurate on handwriting, rotated and blurry photos.',
    tag: { label: 'Most accurate', color: 'primary' },
  },
  'claude-sonnet-5-5': {
    summary: 'Strong accuracy at about half the cost. A good choice for high volume.',
    tag: { label: 'Best value', color: 'success' },
  },
  'claude-haiku-5-5': {
    summary: 'Cheapest and fastest. Best for clean, printed paperwork; test on your own samples first.',
    tag: { label: 'Lowest cost', color: 'default' },
  },
  'claude-opus-5': { summary: 'Previous Opus generation. Only needed to match older results.' },
  'claude-fable-5-1': { summary: 'Most capable model at the highest cost. Rarely needed for reading documents.' },
};

const cents = (v: number) => `${(v * 100).toFixed(v < 0.01 ? 2 : 1)}¢`;
const usd = (v: number) => `$${v.toLocaleString('en-US', { maximumFractionDigits: v < 10 ? 2 : 0 })}`;

export function AutomationSettingsPanel(): React.JSX.Element {
  const { data, isLoading, refetch } = useGetAutomationSettingsQuery();
  const [updateSettings, { isLoading: saving }] = useUpdateAutomationSettingsMutation();
  const [selected, setSelected] = React.useState<string>('');

  const settings = data?.data;
  React.useEffect(() => {
    if (settings?.ai.model) setSelected(settings.ai.model);
  }, [settings?.ai.model]);

  if (isLoading || !settings) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center', py: 6 }}>
        <CircularProgress />
      </Box>
    );
  }

  const current = settings.ai.model;
  const changed = selected && selected !== current;

  const save = async () => {
    try {
      await updateSettings({ model: selected }).unwrap();
      toast.success('AI model updated. New documents will use it within 30 seconds.');
      refetch();
    } catch (err: any) {
      toast.error(err?.data?.message || 'Could not update the model');
    }
  };

  return (
    <Stack spacing={3}>
      <PrecheckCard settings={settings} onSaved={refetch} />
      <Card>
        <CardHeader
          subheader="The model that does the full read (document type, fields, keywords) after the quick check passes. Changes apply to the next document — no restart needed."
          title="AI model for the full read"
          action={
            <Button disabled={!changed || saving} onClick={() => void save()} variant="contained">
              {saving ? 'Saving…' : 'Save'}
            </Button>
          }
        />
        <Divider />
        <Stack divider={<Divider />}>
          {settings.models.map((m) => {
            const note = MODEL_NOTES[m.model];
            const isSelected = selected === m.model;
            return (
              <Box
                key={m.model}
                onClick={() => setSelected(m.model)}
                sx={{
                  alignItems: 'flex-start',
                  backgroundColor: isSelected ? 'rgba(var(--mui-palette-primary-mainChannel) / 0.06)' : undefined,
                  boxShadow: isSelected ? 'inset 3px 0 0 var(--mui-palette-primary-main)' : undefined,
                  cursor: 'pointer',
                  display: 'flex',
                  gap: 1.5,
                  px: 3,
                  py: 2,
                  transition: 'background-color 0.15s ease',
                  '&:hover': { backgroundColor: isSelected ? undefined : 'var(--mui-palette-background-level1)' },
                }}
              >
                <Radio checked={isSelected} size="small" sx={{ mt: -0.5, ml: -1 }} />
                <Box sx={{ flex: 1, minWidth: 0 }}>
                  <Stack alignItems="center" direction="row" flexWrap="wrap" gap={1}>
                    <Typography variant="subtitle1">{m.label}</Typography>
                    {note?.tag ? <Chip color={note.tag.color} label={note.tag.label} size="small" /> : null}
                    {m.model === current ? <Chip color="success" label="In use" size="small" variant="outlined" /> : null}
                  </Stack>
                  <Typography color="text.secondary" variant="body2">
                    {note?.summary}
                  </Typography>
                  <Typography color="text.disabled" sx={{ fontFamily: 'monospace', fontSize: 12, mt: 0.5 }}>
                    {m.model} · ${m.input} in / ${m.output} out per 1M tokens
                  </Typography>
                </Box>
                <Box sx={{ textAlign: 'right', flexShrink: 0 }}>
                  <Typography sx={{ fontSize: 18, fontWeight: 700 }}>{cents(m.estimatedPerDocument)}</Typography>
                  <Typography color="text.secondary" variant="caption">
                    per document
                  </Typography>
                  <Typography color="text.secondary" sx={{ display: 'block' }} variant="caption">
                    {usd(m.estimatedPerDocument * 1000)} per 1,000
                  </Typography>
                </Box>
              </Box>
            );
          })}
        </Stack>
        <Divider />
        <CardContent>
          <Stack spacing={1}>
            {settings.ai.isDefault ? (
              <Typography color="text.secondary" variant="body2">
                No model chosen here yet, so the server default <code>{settings.ai.envDefault}</code> (AI_MODEL in server/.env) is used.
              </Typography>
            ) : (
              <Typography color="text.secondary" variant="body2">
                Last changed {settings.ai.updatedAt ? moment(settings.ai.updatedAt).fromNow() : ''}.
              </Typography>
            )}
            <Typography color="text.secondary" variant="body2">
              Per-document costs are estimates based on your current document types and training examples; real costs appear
              under Usage &amp; cost.
            </Typography>
          </Stack>
        </CardContent>
      </Card>
      {changed ? (
        <Alert severity="info">
          Tip: after switching, open any flow and use <b>Test</b> with a few real photos to check what the new model reads. You can
          switch back here at any time.
        </Alert>
      ) : null}
    </Stack>
  );
}


// Quick check: only document types used by LIVE flows are read in full; a cheap model screens uploads first
function PrecheckCard({ settings, onSaved }: { settings: AutomationSettings; onSaved: () => void }): React.JSX.Element {
  const [updateSettings, { isLoading: saving }] = useUpdateAutomationSettingsMutation();
  const pre = settings.precheck;
  const [enabled, setEnabled] = React.useState(pre.enabled);

  React.useEffect(() => {
    setEnabled(pre.enabled);
  }, [pre.enabled]);

  const typeName = (key: string) => pre.docTypes.find((d) => d.key === key)?.name || key;
  const fullModel = settings.models.find((m) => m.model === settings.ai.model);
  const checkModel = settings.models.find((m) => m.model === pre.model);
  const readTypes = pre.live.docTypes.filter((k) => pre.docTypes.some((d) => d.key === k));

  const save = async () => {
    try {
      await updateSettings({ precheckEnabled: enabled }).unwrap();
      toast.success('Saved. New uploads will use it within 30 seconds.');
      onSaved();
    } catch (err: any) {
      toast.error(err?.data?.message || 'Could not save');
    }
  };

  return (
    <Card>
      <CardHeader
        title="Read only for live flows"
        subheader={`Every upload is first screened by ${checkModel?.label || pre.model} on a small copy of the photo. Only document types used by a Live flow go on to the full read with ${fullModel?.label || settings.ai.model}.`}
        action={
          <Button disabled={enabled === pre.enabled || saving} onClick={() => void save()} variant="contained">
            {saving ? 'Saving…' : 'Save'}
          </Button>
        }
      />
      <Divider />
      <CardContent>
        <Stack spacing={2}>
          <FormControlLabel
            control={<Switch checked={enabled} onChange={(e) => setEnabled(e.target.checked)} />}
            label={enabled ? 'On — only document types used by live flows are read' : 'Off — every upload is read in full'}
          />
          <Box sx={{ opacity: enabled ? 1 : 0.5 }}>
            <Typography sx={{ mb: 1 }} variant="subtitle2">
              Read in full right now
            </Typography>
            {readTypes.length ? (
              <Stack spacing={1}>
                {readTypes.map((key) => (
                  <Stack alignItems="center" direction="row" flexWrap="wrap" gap={1} key={key}>
                    <Chip color="primary" label={typeName(key)} size="small" />
                    <Typography color="text.secondary" variant="body2">
                      used by {pre.live.flows.filter((f) => f.docTypes.includes(key)).map((f) => f.name).join(', ')}
                    </Typography>
                  </Stack>
                ))}
              </Stack>
            ) : (
              <Alert severity="warning">
                No live flow uses a document type, so uploads are not sent to the AI at all. Turn a flow on (and Shadow mode off) under
                Flows to start reading documents.
              </Alert>
            )}
            {pre.live.anyTypeFlows.length ? (
              <Typography color="text.secondary" sx={{ mt: 1 }} variant="body2">
                {pre.live.anyTypeFlows.map((f) => f.name).join(', ')} {pre.live.anyTypeFlows.length === 1 ? 'has' : 'have'} no document
                type condition, so {pre.live.anyTypeFlows.length === 1 ? 'it runs' : 'they run'} only on documents read for the flows above.
              </Typography>
            ) : null}
          </Box>
          <Typography color="text.secondary" variant="body2">
            Quick check ≈ {cents(pre.estimatedPerCheck)} per upload ({usd(pre.estimatedPerCheck * 1000)} per 1,000). Shadow-mode
            flows do not count as live. If the quick check is unsure or unavailable, the upload is read in full so nothing is missed.
          </Typography>
        </Stack>
      </CardContent>
    </Card>
  );
}
