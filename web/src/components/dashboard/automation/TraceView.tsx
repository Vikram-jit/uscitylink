'use client';

import * as React from 'react';
import { Box, Chip, Stack, Typography } from '@mui/material';
import { CheckCircle, XCircle } from '@phosphor-icons/react';

import type { ActionResult, TraceNode } from '@/redux/models/AutomationModel';

import { ACTION_LABELS, describeAction, formatValue, OPERATOR_LABELS } from './utils';

export function TraceView({ node, depth = 0 }: { node?: TraceNode | null; depth?: number }): React.JSX.Element | null {
  if (!node) return null;
  const icon = node.result ? (
    <CheckCircle color="var(--mui-palette-success-main)" size={18} weight="fill" />
  ) : (
    <XCircle color="var(--mui-palette-error-main)" size={18} weight="fill" />
  );

  if (node.type === 'condition') {
    return (
      <Stack alignItems="flex-start" direction="row" spacing={1} sx={{ pl: depth * 2 }}>
        <Box sx={{ pt: '2px' }}>{icon}</Box>
        <Typography variant="body2">
          <b>{node.field}</b> {node.op ? OPERATOR_LABELS[node.op] : ''}{' '}
          {node.op && !['exists', 'missing', 'is_true', 'is_false'].includes(node.op) ? (
            <b>{formatValue(node.expected)}</b>
          ) : null}
          <Typography color="text.secondary" component="span" variant="body2">
            {' '}
            (actual: {formatValue(node.actual)})
          </Typography>
        </Typography>
      </Stack>
    );
  }

  return (
    <Stack spacing={0.75}>
      <Stack alignItems="center" direction="row" spacing={1} sx={{ pl: depth * 2 }}>
        {icon}
        <Typography variant="subtitle2">{node.type === 'all' ? 'ALL of these' : 'ANY of these'}</Typography>
      </Stack>
      {(node.children || []).map((child, i) => (
        // eslint-disable-next-line react/no-array-index-key -- trace children have no ids
        <TraceView depth={depth + 1} key={i} node={child} />
      ))}
      {!node.children?.length ? (
        <Typography color="text.secondary" sx={{ pl: (depth + 1) * 2 }} variant="body2">
          No conditions — always matches
        </Typography>
      ) : null}
    </Stack>
  );
}

export function ActionResultsView({ results }: { results?: ActionResult[] | null }): React.JSX.Element {
  if (!results?.length) {
    return (
      <Typography color="text.secondary" variant="body2">
        No actions
      </Typography>
    );
  }
  return (
    <Stack spacing={1}>
      {results.map((r, i) => (
        // eslint-disable-next-line react/no-array-index-key -- results are positional
        <Stack alignItems="flex-start" direction="row" key={i} spacing={1}>
          <Chip
            color={!r.ok ? 'error' : r.planned ? 'default' : 'success'}
            label={`${ACTION_LABELS[r.type] || r.type}${r.planned ? ' (not sent)' : ''}`}
            size="small"
          />
          <Typography sx={{ whiteSpace: 'pre-wrap' }} variant="body2">
            {r.error ? `Error: ${r.error}` : describeAction(r)}
          </Typography>
        </Stack>
      ))}
    </Stack>
  );
}
