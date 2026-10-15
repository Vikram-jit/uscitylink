'use client';

import * as React from 'react';
import {
  Autocomplete,
  Box,
  Button,
  Card,
  IconButton,
  MenuItem,
  Stack,
  TextField,
  ToggleButton,
  ToggleButtonGroup,
  Tooltip,
  Typography,
} from '@mui/material';
import { Plus, Trash } from '@phosphor-icons/react';

import type {
  Condition,
  ConditionGroup,
  ConditionNode,
  ContextField,
  Operator,
} from '@/redux/models/AutomationModel';

import { groupChildren, groupMode, isGroup, OPERATOR_LABELS, VALUELESS_OPERATORS } from './utils';

const MAX_DEPTH = 2;

const operatorsFor = (field?: ContextField): Operator[] => {
  switch (field?.type) {
    case 'number':
      return ['gt', 'gte', 'lt', 'lte', 'between', 'eq', 'neq', 'exists', 'missing'];
    case 'boolean':
      return ['is_true', 'is_false', 'exists', 'missing'];
    case 'enum':
      return ['eq', 'neq', 'in'];
    case 'date':
      return ['eq', 'exists', 'missing'];
    default:
      return ['eq', 'neq', 'contains', 'in', 'exists', 'missing'];
  }
};

function ValueInput({
  condition,
  field,
  onChange,
}: {
  condition: Condition;
  field?: ContextField;
  onChange: (value: any) => void;
}): React.JSX.Element | null {
  if (VALUELESS_OPERATORS.includes(condition.op)) return null;

  if (condition.op === 'between') {
    const [lo, hi] = Array.isArray(condition.value) ? condition.value : ['', ''];
    return (
      <Stack direction="row" spacing={1} sx={{ minWidth: 220 }}>
        <TextField label="Min" onChange={(e) => onChange([Number(e.target.value), hi])} size="small" type="number" value={lo ?? ''} />
        <TextField label="Max" onChange={(e) => onChange([lo, Number(e.target.value)])} size="small" type="number" value={hi ?? ''} />
      </Stack>
    );
  }

  if (field?.type === 'enum' && field.options) {
    if (condition.op === 'in') {
      return (
        <Autocomplete
          multiple
          onChange={(_e, v) => onChange(v)}
          options={field.options}
          renderInput={(params) => <TextField {...params} label="Values" size="small" />}
          size="small"
          sx={{ minWidth: 240 }}
          value={Array.isArray(condition.value) ? condition.value : []}
        />
      );
    }
    return (
      <TextField
        label="Value"
        onChange={(e) => onChange(e.target.value)}
        select
        size="small"
        sx={{ minWidth: 200 }}
        value={condition.value ?? ''}
      >
        {field.options.map((o) => (
          <MenuItem key={o} value={o}>
            {o}
          </MenuItem>
        ))}
      </TextField>
    );
  }

  return (
    <TextField
      helperText={condition.op === 'in' ? 'Comma separated' : undefined}
      label="Value"
      onChange={(e) => onChange(field?.type === 'number' && e.target.value !== '' ? Number(e.target.value) : e.target.value)}
      size="small"
      sx={{ minWidth: 180 }}
      type={field?.type === 'number' ? 'number' : 'text'}
      value={condition.value ?? ''}
    />
  );
}

function ConditionRow({
  condition,
  fields,
  onChange,
  onRemove,
}: {
  condition: Condition;
  fields: ContextField[];
  onChange: (c: Condition) => void;
  onRemove: () => void;
}): React.JSX.Element {
  const field = fields.find((f) => f.path === condition.field);
  const ops = operatorsFor(field);

  return (
    <Stack alignItems="flex-start" direction={{ xs: 'column', md: 'row' }} spacing={1}>
      <Autocomplete
        disableClearable
        getOptionLabel={(o) => o.label}
        groupBy={(o) => (o.docType ? `Fields: ${o.docType}` : o.path.split('.')[0])}
        isOptionEqualToValue={(a, b) => a.path === b.path}
        onChange={(_e, f) => {
          const nextOps = operatorsFor(f);
          onChange({ field: f.path, op: nextOps.includes(condition.op) ? condition.op : nextOps[0], value: undefined });
        }}
        options={fields}
        renderInput={(params) => <TextField {...params} label="When" size="small" />}
        size="small"
        sx={{ minWidth: 280, flex: 1 }}
        value={field ?? { path: condition.field, label: condition.field || 'Choose a field', type: 'string' }}
      />
      <TextField
        label="Is"
        onChange={(e) => onChange({ ...condition, op: e.target.value as Operator })}
        select
        size="small"
        sx={{ minWidth: 170 }}
        value={condition.op}
      >
        {ops.map((op) => (
          <MenuItem key={op} value={op}>
            {OPERATOR_LABELS[op]}
          </MenuItem>
        ))}
      </TextField>
      <ValueInput condition={condition} field={field} onChange={(value) => onChange({ ...condition, value })} />
      <Tooltip title="Remove condition">
        <IconButton onClick={onRemove}>
          <Trash size={18} />
        </IconButton>
      </Tooltip>
    </Stack>
  );
}

export function ConditionGroupEditor({
  group,
  fields,
  onChange,
  onRemove,
  depth = 0,
}: {
  group: ConditionGroup;
  fields: ContextField[];
  onChange: (g: ConditionGroup) => void;
  onRemove?: () => void;
  depth?: number;
}): React.JSX.Element {
  const mode = groupMode(group);
  const children = groupChildren(group);
  const setChildren = (next: ConditionNode[]) => onChange((mode === 'all' ? { all: next } : { any: next }) as ConditionGroup);
  const replaceAt = (index: number, node: ConditionNode) => setChildren(children.map((c, i) => (i === index ? node : c)));
  const removeAt = (index: number) => setChildren(children.filter((_c, i) => i !== index));

  return (
    <Card sx={{ p: 2, bgcolor: depth ? 'var(--mui-palette-background-level1)' : undefined }} variant="outlined">
      <Stack spacing={1.5}>
        <Stack alignItems="center" direction="row" spacing={1}>
          <Typography variant="body2">Match</Typography>
          <ToggleButtonGroup
            exclusive
            onChange={(_e, value) => value && onChange((value === 'all' ? { all: children } : { any: children }) as ConditionGroup)}
            size="small"
            value={mode}
          >
            <ToggleButton value="all">ALL</ToggleButton>
            <ToggleButton value="any">ANY</ToggleButton>
          </ToggleButtonGroup>
          <Typography variant="body2">of these conditions</Typography>
          <Box sx={{ flex: 1 }} />
          {onRemove ? (
            <Tooltip title="Remove group">
              <IconButton onClick={onRemove} size="small">
                <Trash size={18} />
              </IconButton>
            </Tooltip>
          ) : null}
        </Stack>

        {children.map((child, i) =>
          isGroup(child) ? (
            <ConditionGroupEditor
              depth={depth + 1}
              fields={fields}
              group={child}
              // eslint-disable-next-line react/no-array-index-key -- conditions have no ids
              key={i}
              onChange={(g) => replaceAt(i, g)}
              onRemove={() => removeAt(i)}
            />
          ) : (
            <ConditionRow
              condition={child}
              fields={fields}
              // eslint-disable-next-line react/no-array-index-key -- conditions have no ids
              key={i}
              onChange={(c) => replaceAt(i, c)}
              onRemove={() => removeAt(i)}
            />
          )
        )}
        {!children.length ? (
          <Typography color="text.secondary" variant="body2">
            No conditions yet — this flow will match every document.
          </Typography>
        ) : null}

        <Stack direction="row" spacing={1}>
          <Button
            onClick={() => setChildren([...children, { field: 'doc.type', op: 'eq', value: '' }])}
            size="small"
            startIcon={<Plus />}
          >
            Condition
          </Button>
          {depth < MAX_DEPTH - 1 ? (
            <Button
              onClick={() => setChildren([...children, { any: [{ field: 'doc.type', op: 'eq', value: '' }] }])}
              size="small"
              startIcon={<Plus />}
            >
              Group
            </Button>
          ) : null}
        </Stack>
      </Stack>
    </Card>
  );
}
