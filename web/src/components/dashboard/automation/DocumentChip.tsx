'use client';

import * as React from 'react';
import { Box, Chip, Stack, Tooltip, Typography } from '@mui/material';
import { FileText } from '@phosphor-icons/react';

import { useGetMessageDocumentQuery } from '@/redux/AutomationApiSlice';

import { CorrectionDialog } from './CorrectionDialog';
import { formatValue, humanizeKey } from './utils';

const HEADLINE_FIELDS = ['gross_lb', 'bol_number', 'received_qty', 'amount'];

// Shows what the AI read from a driver's attachment; click to correct it
export function DocumentChip({ messageId }: { messageId: string }): React.JSX.Element | null {
  const { data } = useGetMessageDocumentQuery({ messageId });
  const [open, setOpen] = React.useState(false);
  const doc = data?.data;
  if (!doc || doc.status === 'skipped') return null;

  if (doc.status === 'pending') {
    return <Chip icon={<FileText />} label="Reading document…" size="small" sx={{ mt: 0.5 }} variant="outlined" />;
  }
  if (doc.status === 'failed') {
    return <Chip color="error" icon={<FileText />} label="Couldn't read document" onClick={() => setOpen(true)} size="small" sx={{ mt: 0.5 }} variant="outlined" />;
  }

  const type = doc.corrected_doc_type || doc.doc_type_key;
  if (!type || type === 'other') return null;
  const fields = { ...(doc.fields || {}), ...(doc.corrected_fields || {}) };
  const headlineKey = HEADLINE_FIELDS.find((k) => fields[k] !== null && fields[k] !== undefined);
  const lowConfidence = !doc.corrected_by && (doc.confidence ?? 1) < 0.6;

  return (
    <>
      <Tooltip
        title={
          <Stack spacing={0.25}>
            {Object.entries(fields)
              .filter(([, v]) => v !== null && v !== '')
              .map(([k, v]) => (
                <Typography key={k} variant="caption">
                  {k}: {formatValue(v)}
                </Typography>
              ))}
            <Typography sx={{ mt: 0.5 }} variant="caption">
              {doc.corrected_by ? 'Corrected by staff' : `AI confidence ${Math.round((doc.confidence ?? 0) * 100)}%`} — click to correct
            </Typography>
          </Stack>
        }
      >
        <Box sx={{ mt: 0.5 }}>
          <Chip
            color={lowConfidence ? 'warning' : 'primary'}
            icon={<FileText />}
            label={`${humanizeKey(type)}${headlineKey ? ` · ${formatValue(fields[headlineKey])}` : ''}${(doc.tags || []).length ? ` · ${doc.tags!.join(', ')}` : ''}`}
            onClick={() => setOpen(true)}
            size="small"
            variant="outlined"
          />
        </Box>
      </Tooltip>
      {open ? <CorrectionDialog doc={doc} onClose={() => setOpen(false)} open /> : null}
    </>
  );
}
