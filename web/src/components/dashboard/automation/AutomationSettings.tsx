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
  Radio,
  Stack,
  Typography,
} from '@mui/material';
import moment from 'moment';
import { toast } from 'react-toastify';

import { useGetAutomationSettingsQuery, useUpdateAutomationSettingsMutation } from '@/redux/AutomationApiSlice';

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
      <Card>
        <CardHeader
          subheader="The model that reads driver photos and PDFs (document type, fields, keywords). Changes apply to the next document — no restart needed."
          title="AI model"
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
