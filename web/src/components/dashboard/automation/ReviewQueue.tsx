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
  Grid,
  Stack,
  TablePagination,
  Typography,
} from '@mui/material';
import moment from 'moment';
import { toast } from 'react-toastify';

import {
  useDeleteExampleMutation,
  useGetCandidateExamplesQuery,
  useGetReviewQueueQuery,
  useReanalyzeMessageMutation,
  useUpdateExampleMutation,
} from '@/redux/AutomationApiSlice';
import type { MessageDocument } from '@/redux/models/AutomationModel';

import { CorrectionDialog } from './CorrectionDialog';
import { formatValue, humanizeKey, s3Url } from './utils';
import { AdminOnly } from './AdminGuard';

const reason = (doc: MessageDocument) => {
  if (doc.status === 'failed') return { label: 'Failed', color: 'error' as const };
  if (doc.image_quality && doc.image_quality !== 'good') return { label: `Photo ${doc.image_quality}`, color: 'warning' as const };
  return { label: `Low confidence ${Math.round((doc.confidence ?? 0) * 100)}%`, color: 'warning' as const };
};

function ReviewCard({ doc }: { doc: MessageDocument }): React.JSX.Element {
  const [correcting, setCorrecting] = React.useState(false);
  const [reanalyze, { isLoading }] = useReanalyzeMessageMutation();
  const r = reason(doc);

  return (
    <Card variant="outlined">
      {doc.media_key && !/\.pdf$/i.test(doc.media_key) ? (
        <Box
          alt="Document"
          component="img"
          src={s3Url(doc.media_key)}
          sx={{ width: '100%', height: 200, objectFit: 'cover', cursor: 'zoom-in' }}
          onClick={() => window.open(s3Url(doc.media_key), '_blank')}
        />
      ) : null}
      <CardContent>
        <Stack spacing={1}>
          <Stack direction="row" flexWrap="wrap" gap={0.5}>
            <Chip color={r.color} label={r.label} size="small" />
            <Chip label={humanizeKey(doc.doc_type_key)} size="small" variant="outlined" />
          </Stack>
          <Typography variant="body2">
            {doc.message?.sender?.username || 'Driver'} · {moment(doc.createdAt).format('MMM D, h:mm a')}
          </Typography>
          {doc.error ? (
            <Typography color="error" variant="body2">
              {doc.error}
            </Typography>
          ) : null}
          {Object.entries(doc.fields || {})
            .filter(([, v]) => v !== null)
            .slice(0, 4)
            .map(([k, v]) => (
              <Typography key={k} variant="body2">
                <Typography color="text.secondary" component="span" variant="body2">
                  {k}:
                </Typography>{' '}
                {formatValue(v)}
              </Typography>
            ))}
          <AdminOnly>
          <Stack direction="row" spacing={1}>
            <Button onClick={() => setCorrecting(true)} size="small" variant="contained">
              Correct
            </Button>
            <Button
              disabled={isLoading}
              onClick={async () => {
                await reanalyze({ messageId: doc.message_id });
                toast.info('Queued for another read');
              }}
              size="small"
            >
              Re-read
            </Button>
          </Stack>
          </AdminOnly>
        </Stack>
      </CardContent>
      {correcting ? <CorrectionDialog doc={doc} onClose={() => setCorrecting(false)} open /> : null}
    </Card>
  );
}

function CandidateExamples(): React.JSX.Element | null {
  const { data } = useGetCandidateExamplesQuery();
  const [updateExample] = useUpdateExampleMutation();
  const [deleteExample] = useDeleteExampleMutation();
  if (!data?.data?.length) return null;

  return (
    <Card>
      <CardHeader
        subheader="Staff corrections suggested as training examples. Approve the clear, typical ones."
        title={`Suggested examples (${data.data.length})`}
      />
      <CardContent>
        <Grid container spacing={2}>
          {data.data.map((ex) => (
            <Grid item key={ex.id} md={3} sm={6} xs={12}>
              <Card variant="outlined">
                {!/\.pdf$/i.test(ex.s3_key) ? (
                  <Box alt="Example" component="img" src={s3Url(ex.s3_key)} sx={{ width: '100%', height: 160, objectFit: 'cover' }} />
                ) : null}
                <CardContent>
                  <Stack spacing={1}>
                    <Typography variant="subtitle2">{ex.docType?.name}</Typography>
                    <AdminOnly>
                    <Stack direction="row" spacing={1}>
                      <Button onClick={() => void updateExample({ id: ex.id, active: true })} size="small" variant="contained">
                        Approve
                      </Button>
                      <Button color="inherit" onClick={() => void deleteExample({ id: ex.id })} size="small">
                        Dismiss
                      </Button>
                    </Stack>
                    </AdminOnly>
                  </Stack>
                </CardContent>
              </Card>
            </Grid>
          ))}
        </Grid>
      </CardContent>
    </Card>
  );
}

export function ReviewQueue(): React.JSX.Element {
  const [page, setPage] = React.useState(1);
  const { data, isFetching } = useGetReviewQueueQuery({ page });

  return (
    <Stack spacing={3}>
      <CandidateExamples />
      <Typography color="text.secondary" variant="body2">
        Documents the AI was unsure about, could not read, or failed on. Correcting them fixes the data and can teach the
        AI.
      </Typography>
      {isFetching ? (
        <Box sx={{ display: 'flex', justifyContent: 'center', py: 4 }}>
          <CircularProgress />
        </Box>
      ) : null}
      {!isFetching && !data?.data?.documents.length ? <Alert severity="success">Nothing to review.</Alert> : null}
      <Grid container spacing={2}>
        {data?.data?.documents.map((doc) => (
          <Grid item key={doc.id} lg={3} md={4} sm={6} xs={12}>
            <ReviewCard doc={doc} />
          </Grid>
        ))}
      </Grid>
      {data?.data?.pagination && data.data.pagination.total > data.data.pagination.pageSize ? (
        <TablePagination
          component="div"
          count={data.data.pagination.total}
          onPageChange={(_e, p) => setPage(p + 1)}
          page={page - 1}
          rowsPerPage={data.data.pagination.pageSize}
          rowsPerPageOptions={[]}
        />
      ) : null}
    </Stack>
  );
}
