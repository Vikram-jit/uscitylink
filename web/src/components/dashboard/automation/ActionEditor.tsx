'use client';

import * as React from 'react';
import {
  Autocomplete,
  Box,
  Button,
  Card,
  Chip,
  FormControlLabel,
  IconButton,
  MenuItem,
  Stack,
  Switch,
  TextField,
  Tooltip,
  Typography,
} from '@mui/material';
import { Plus, Trash } from '@phosphor-icons/react';

import type { ContextField, FlowAction } from '@/redux/models/AutomationModel';

import { ACTION_LABELS } from './utils';

const DEFAULTS: Record<FlowAction['type'], FlowAction> = {
  reply_driver: { type: 'reply_driver', template: '' },
  alert_staff: { type: 'alert_staff', title: '', template: '', severity: 'warning' },
  tag: { type: 'tag', tags: [] },
  webhook: { type: 'webhook', url: '', include_image_url: true },
};

function TemplateField({
  label,
  value,
  onChange,
  fields,
  multiline = true,
}: {
  label: string;
  value: string;
  onChange: (v: string) => void;
  fields: ContextField[];
  multiline?: boolean;
}): React.JSX.Element {
  const inputRef = React.useRef<HTMLInputElement | HTMLTextAreaElement | null>(null);
  const [showVars, setShowVars] = React.useState(false);

  const insert = (path: string) => {
    const token = `{{${path}}}`;
    const el = inputRef.current;
    const start = el?.selectionStart ?? value.length;
    const end = el?.selectionEnd ?? value.length;
    onChange(value.slice(0, start) + token + value.slice(end));
  };

  return (
    <Stack spacing={1}>
      <TextField
        fullWidth
        inputRef={inputRef}
        label={label}
        minRows={multiline ? 2 : undefined}
        multiline={multiline}
        onChange={(e) => onChange(e.target.value)}
        onFocus={() => setShowVars(true)}
        size="small"
        value={value}
      />
      {showVars ? (
        <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 0.5 }}>
          <Typography color="text.secondary" sx={{ mr: 0.5 }} variant="caption">
            Insert:
          </Typography>
          {fields
            .filter((f) => !f.path.startsWith('time.'))
            .map((f) => (
              <Chip key={f.path} label={f.label} onClick={() => insert(f.path)} size="small" variant="outlined" />
            ))}
        </Box>
      ) : null}
    </Stack>
  );
}

function ActionRow({
  action,
  fields,
  onChange,
  onRemove,
}: {
  action: FlowAction;
  fields: ContextField[];
  onChange: (a: FlowAction) => void;
  onRemove: () => void;
}): React.JSX.Element {
  return (
    <Card sx={{ p: 2 }} variant="outlined">
      <Stack spacing={2}>
        <Stack alignItems="center" direction="row" spacing={1}>
          <TextField
            label="Action"
            onChange={(e) => onChange(DEFAULTS[e.target.value as FlowAction['type']])}
            select
            size="small"
            sx={{ minWidth: 220 }}
            value={action.type}
          >
            {Object.keys(DEFAULTS).map((t) => (
              <MenuItem key={t} value={t}>
                {ACTION_LABELS[t]}
              </MenuItem>
            ))}
          </TextField>
          <Box sx={{ flex: 1 }} />
          <Tooltip title="Remove action">
            <IconButton onClick={onRemove}>
              <Trash size={18} />
            </IconButton>
          </Tooltip>
        </Stack>

        {action.type === 'reply_driver' ? (
          <TemplateField
            fields={fields}
            label="Message to driver"
            onChange={(template) => onChange({ ...action, template })}
            value={action.template}
          />
        ) : null}

        {action.type === 'alert_staff' ? (
          <>
            <Stack direction={{ xs: 'column', md: 'row' }} spacing={2}>
              <Box sx={{ flex: 1 }}>
                <TemplateField
                  fields={fields}
                  label="Alert title"
                  multiline={false}
                  onChange={(title) => onChange({ ...action, title })}
                  value={action.title || ''}
                />
              </Box>
              <TextField
                label="Severity"
                onChange={(e) => onChange({ ...action, severity: e.target.value as 'info' | 'warning' | 'critical' })}
                select
                size="small"
                sx={{ minWidth: 160 }}
                value={action.severity || 'warning'}
              >
                <MenuItem value="info">Info</MenuItem>
                <MenuItem value="warning">Warning</MenuItem>
                <MenuItem value="critical">Critical</MenuItem>
              </TextField>
            </Stack>
            <TemplateField
              fields={fields}
              label="Alert details"
              onChange={(template) => onChange({ ...action, template })}
              value={action.template}
            />
          </>
        ) : null}

        {action.type === 'tag' ? (
          <Autocomplete
            freeSolo
            multiple
            onChange={(_e, tags) => onChange({ ...action, tags: tags.map((t) => t.trim().toLowerCase()).filter(Boolean) })}
            options={['overweight', 'osd', 'needs_review', 'missing_seal', 'paid_lumper']}
            renderInput={(params) => <TextField {...params} helperText="Press Enter to add a tag" label="Tags" size="small" />}
            value={action.tags}
          />
        ) : null}

        {action.type === 'webhook' ? (
          <Stack spacing={1}>
            <TextField
              helperText="Receives a JSON POST signed with an X-USCityLink-Signature header (HMAC-SHA256)"
              label="Webhook URL"
              onChange={(e) => onChange({ ...action, url: e.target.value })}
              placeholder="https://tms.example.com/hooks/documents"
              size="small"
              value={action.url}
            />
            <FormControlLabel
              control={
                <Switch
                  checked={!!action.include_image_url}
                  onChange={(e) => onChange({ ...action, include_image_url: e.target.checked })}
                />
              }
              label="Include the photo link"
            />
          </Stack>
        ) : null}
      </Stack>
    </Card>
  );
}

export function ActionListEditor({
  actions,
  fields,
  onChange,
  emptyText,
}: {
  actions: FlowAction[];
  fields: ContextField[];
  onChange: (a: FlowAction[]) => void;
  emptyText: string;
}): React.JSX.Element {
  return (
    <Stack spacing={1.5}>
      {actions.map((action, i) => (
        <ActionRow
          action={action}
          fields={fields}
          // eslint-disable-next-line react/no-array-index-key -- actions have no ids
          key={i}
          onChange={(a) => onChange(actions.map((x, j) => (j === i ? a : x)))}
          onRemove={() => onChange(actions.filter((_x, j) => j !== i))}
        />
      ))}
      {!actions.length ? (
        <Typography color="text.secondary" variant="body2">
          {emptyText}
        </Typography>
      ) : null}
      <Box>
        <Button onClick={() => onChange([...actions, DEFAULTS.reply_driver])} size="small" startIcon={<Plus />}>
          Add action
        </Button>
      </Box>
    </Stack>
  );
}
