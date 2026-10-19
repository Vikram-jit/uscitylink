'use client';

import * as React from 'react';
import { useRouter } from 'next/navigation';
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
  Drawer,
  FormControlLabel,
  Grid,
  IconButton,
  MenuItem,
  Stack,
  Switch,
  TextField,
  Typography,
} from '@mui/material';
import { ArrowLeft, Flask, Plus, Trash, UploadSimple } from '@phosphor-icons/react';
import { toast } from 'react-toastify';

import { paths } from '@/paths';
import {
  useCreateFlowMutation,
  useGetBuilderMetaQuery,
  useGetFlowQuery,
  useTestFlowMutation,
  useUpdateFlowMutation,
} from '@/redux/AutomationApiSlice';
import type { BranchInfo, Flow, FlowBranch, TestFlowResult } from '@/redux/models/AutomationModel';

import { ActionListEditor } from './ActionEditor';
import { ConditionGroupEditor } from './ConditionEditor';
import { ProcessingNotice } from './ProcessingNotice';
import { ActionResultsView, TraceView } from './TraceView';
import { formatValue, humanizeKey } from './utils';

type FlowDraft = Omit<Flow, 'id'>;

const EMPTY_FLOW: FlowDraft = {
  name: '',
  description: '',
  trigger: 'document_analyzed',
  priority: 100,
  active: false,
  shadow_mode: true,
  conditions: { all: [{ field: 'doc.type', op: 'eq', value: '' }] },
  actions: [{ type: 'reply_driver', template: '' }],
  else_actions: [],
  else_if: [],
  cooldown_minutes: 0,
  stop_on_match: false,
};

const NEW_BRANCH: FlowBranch = { name: '', conditions: { all: [] }, actions: [{ type: 'reply_driver', template: '' }] };

export const branchLabel = (branch?: BranchInfo | null): string => {
  if (!branch) return '';
  if (branch.kind === 'if') return 'IF matched — THEN actions ran';
  if (branch.kind === 'else_if') return `ELSE IF "${branch.name || `#${(branch.index ?? 0) + 1}`}" matched`;
  if (branch.kind === 'else') return 'Nothing matched — ELSE actions ran';
  return 'Different document type — no branch ran';
};

const errorMessage = (err: any) => err?.data?.message || err?.message || 'Something went wrong';

function TestPanel({ draft, open, onClose }: { draft: FlowDraft; open: boolean; onClose: () => void }): React.JSX.Element {
  const [testFlow, { isLoading }] = useTestFlowMutation();
  const [messageId, setMessageId] = React.useState('');
  const [result, setResult] = React.useState<TestFlowResult | null>(null);
  const [error, setError] = React.useState<string | null>(null);

  const pending = React.useRef<{ abort: () => void } | null>(null);

  const run = async (file?: File) => {
    setError(null);
    setResult(null);
    const form = new FormData();
    form.append('flow', JSON.stringify(draft));
    if (file) form.append('file', file);
    else form.append('messageId', messageId.trim());
    const request = testFlow(form);
    pending.current = request;
    try {
      const res = await request.unwrap();
      setResult(res.data);
    } catch (err: any) {
      setError(err?.name === 'AbortError' ? 'Cancelled.' : errorMessage(err));
    } finally {
      pending.current = null;
    }
  };

  const doc = result?.context?.doc;

  return (
    <Drawer PaperProps={{ sx: { width: { xs: '100%', md: 560 } } }} anchor="right" onClose={onClose} open={open}>
      <Stack spacing={3} sx={{ p: 3 }}>
        <Stack spacing={0.5}>
          <Typography variant="h6">Test this flow</Typography>
          <Typography color="text.secondary" variant="body2">
            Dry run against a sample photo or a real chat message. Nothing is sent to drivers or dispatch.
          </Typography>
        </Stack>

        <Button component="label" disabled={isLoading} startIcon={<UploadSimple />} variant="contained">
          Upload a sample photo or PDF
          <input
            accept="image/*,application/pdf"
            hidden
            onChange={(e) => {
              const file = e.target.files?.[0];
              if (file) void run(file);
              e.target.value = '';
            }}
            type="file"
          />
        </Button>

        <Stack direction="row" spacing={1}>
          <TextField
            fullWidth
            label="…or a chat message ID"
            onChange={(e) => setMessageId(e.target.value)}
            size="small"
            value={messageId}
          />
          <Button disabled={isLoading || !messageId.trim()} onClick={() => void run()} variant="outlined">
            Run
          </Button>
        </Stack>

        <ProcessingNotice active={isLoading} onCancel={() => pending.current?.abort()} />
        {error ? <Alert severity="error">{error}</Alert> : null}

        {result ? (
          <Stack spacing={2.5}>
            <Alert severity={result.result.branch?.kind === 'if' ? 'success' : result.result.branch?.kind === 'none' ? 'info' : 'warning'}>
              {result.result.branch
                ? `${branchLabel(result.result.branch)} (dry run, nothing sent).`
                : result.result.matched
                  ? 'Conditions matched — the THEN actions would run.'
                  : 'Conditions did not match — the ELSE actions would run.'}
            </Alert>

            <Stack spacing={1}>
              <Typography variant="subtitle2">What the AI read</Typography>
              <Stack direction="row" flexWrap="wrap" gap={1}>
                <Chip label={humanizeKey(doc?.type)} />
                <Chip label={`Confidence ${Math.round((doc?.confidence ?? 0) * 100)}%`} variant="outlined" />
                <Chip label={`Photo: ${doc?.quality ?? '—'}`} variant="outlined" />
              </Stack>
              {result.analysis?.matched_keywords?.length ? (
                <Typography color="text.secondary" variant="body2">
                  {result.analysis.classified_by === 'keywords' ? 'Identified by its words' : 'Words that matched'}:{' '}
                  {result.analysis.matched_keywords.join(', ')}
                </Typography>
              ) : null}
              <Box component="table" sx={{ '& td': { py: 0.5, pr: 2, verticalAlign: 'top', fontSize: 14 } }}>
                <tbody>
                  {Object.entries(doc?.fields || {}).map(([key, value]) => (
                    <tr key={key}>
                      <td>
                        <Typography color="text.secondary" variant="body2">
                          {key}
                        </Typography>
                      </td>
                      <td>{formatValue(value)}</td>
                    </tr>
                  ))}
                </tbody>
              </Box>
              {doc?.notes ? (
                <Typography color="text.secondary" variant="body2">
                  Note: {doc.notes}
                </Typography>
              ) : null}
            </Stack>

            <Divider />
            <Stack spacing={1}>
              <Typography variant="subtitle2">Conditions</Typography>
              <TraceView node={result.result.trace} />
              {result.result.trace?.branch_trace ? (
                <>
                  <Typography color="text.secondary" variant="caption">
                    ELSE IF &quot;{result.result.branch?.name}&quot;
                  </Typography>
                  <TraceView node={result.result.trace.branch_trace} />
                </>
              ) : null}
            </Stack>

            <Divider />
            <Stack spacing={1}>
              <Typography variant="subtitle2">Actions that would run</Typography>
              <ActionResultsView results={result.result.actions} />
            </Stack>
          </Stack>
        ) : null}
      </Stack>
    </Drawer>
  );
}

export function FlowBuilder({ id }: { id: string }): React.JSX.Element {
  const router = useRouter();
  const isNew = id === 'new';
  const { data: meta } = useGetBuilderMetaQuery();
  const { data: existing, isLoading } = useGetFlowQuery({ id }, { skip: isNew });
  const [createFlow, { isLoading: creating }] = useCreateFlowMutation();
  const [updateFlow, { isLoading: updating }] = useUpdateFlowMutation();
  const [draft, setDraft] = React.useState<FlowDraft>(EMPTY_FLOW);
  const [testOpen, setTestOpen] = React.useState(false);

  React.useEffect(() => {
    if (existing?.data) {
      const { id: _id, last7Days: _stats, updatedAt: _updated, ...rest } = existing.data;
      setDraft({ ...EMPTY_FLOW, ...rest, else_actions: rest.else_actions || [], else_if: rest.else_if || [] });
    }
  }, [existing]);

  const fields = meta?.data?.contextFields || [];
  const set = <K extends keyof FlowDraft>(key: K, value: FlowDraft[K]) => setDraft((d) => ({ ...d, [key]: value }));
  const conditionFields = fields.filter((f) => !f.templateOnly);
  const branches = draft.else_if || [];
  const setBranch = (index: number, next: FlowBranch | null) =>
    setDraft((d) => {
      const list = [...(d.else_if || [])];
      if (next) list[index] = next;
      else list.splice(index, 1);
      return { ...d, else_if: list };
    });

  const save = async () => {
    try {
      if (isNew) {
        const res = await createFlow(draft).unwrap();
        toast.success('Flow created');
        router.replace(`${paths.automation.flows}/${res.data.id}`);
      } else {
        await updateFlow({ id, ...draft }).unwrap();
        toast.success('Flow saved');
      }
    } catch (err) {
      toast.error(errorMessage(err));
    }
  };

  if (!isNew && isLoading) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center', py: 6 }}>
        <CircularProgress />
      </Box>
    );
  }

  return (
    <Stack spacing={3}>
      <Stack alignItems="center" direction="row" spacing={2}>
        <Button onClick={() => router.push(paths.automation.flows)} startIcon={<ArrowLeft />}>
          Flows
        </Button>
        <Box sx={{ flex: 1 }} />
        <Button onClick={() => setTestOpen(true)} startIcon={<Flask />} variant="outlined">
          Test
        </Button>
        <Button disabled={creating || updating} onClick={() => void save()} variant="contained">
          {isNew ? 'Create flow' : 'Save'}
        </Button>
      </Stack>

      <Card>
        <CardContent>
          <Grid container spacing={2}>
            <Grid item md={6} xs={12}>
              <TextField fullWidth label="Flow name" onChange={(e) => set('name', e.target.value)} required size="small" value={draft.name} />
            </Grid>
            <Grid item md={3} xs={6}>
              <TextField
                fullWidth
                label="Runs when"
                onChange={(e) => set('trigger', e.target.value as FlowDraft['trigger'])}
                select
                size="small"
                value={draft.trigger}
              >
                <MenuItem value="document_analyzed">A document has been read</MenuItem>
                <MenuItem value="attachment_received">Any attachment arrives</MenuItem>
              </TextField>
            </Grid>
            <Grid item md={3} xs={6}>
              <TextField
                fullWidth
                helperText="Lower runs first"
                label="Priority"
                onChange={(e) => set('priority', Number(e.target.value))}
                size="small"
                type="number"
                value={draft.priority}
              />
            </Grid>
            <Grid item xs={12}>
              <TextField
                fullWidth
                label="Description (optional)"
                onChange={(e) => set('description', e.target.value)}
                size="small"
                value={draft.description || ''}
              />
            </Grid>
            <Grid item md={3} xs={6}>
              <TextField
                fullWidth
                helperText="Skip repeats for the same driver and document type"
                label="Cooldown (minutes)"
                onChange={(e) => set('cooldown_minutes', Number(e.target.value))}
                size="small"
                type="number"
                value={draft.cooldown_minutes}
              />
            </Grid>
            <Grid item md={9} xs={12}>
              <Stack direction="row" flexWrap="wrap" gap={2}>
                <FormControlLabel
                  control={<Switch checked={draft.active} onChange={(e) => set('active', e.target.checked)} />}
                  label="Active"
                />
                <FormControlLabel
                  control={<Switch checked={draft.shadow_mode} onChange={(e) => set('shadow_mode', e.target.checked)} />}
                  label="Shadow mode (log only, send nothing)"
                />
                <FormControlLabel
                  control={<Switch checked={draft.stop_on_match} onChange={(e) => set('stop_on_match', e.target.checked)} />}
                  label="Stop other flows when this matches"
                />
              </Stack>
            </Grid>
          </Grid>
        </CardContent>
      </Card>

      {draft.active && !draft.shadow_mode ? (
        <Alert severity="warning">This flow is live: drivers and dispatch will receive its messages.</Alert>
      ) : null}

      <Card>
        <CardHeader subheader="Conditions are checked against what the AI read from the document" title="IF" />
        <CardContent>
          <ConditionGroupEditor fields={conditionFields} group={draft.conditions} onChange={(g) => set('conditions', g)} />
        </CardContent>
      </Card>

      <Card>
        <CardHeader title="THEN" />
        <CardContent>
          <ActionListEditor
            actions={draft.actions}
            emptyText="No actions when the conditions match."
            fields={fields}
            onChange={(a) => set('actions', a)}
          />
        </CardContent>
      </Card>

      {branches.map((branch, index) => (
        <Card key={index} sx={{ borderLeft: '4px solid var(--mui-palette-warning-main)' }}>
          <CardHeader
            action={
              <IconButton aria-label="Remove ELSE IF" onClick={() => setBranch(index, null)}>
                <Trash />
              </IconButton>
            }
            subheader="Checked only if everything above did not match. The first branch that matches runs."
            title={`ELSE IF ${branches.length > 1 ? index + 1 : ''}`.trim()}
          />
          <CardContent>
            <Stack spacing={2}>
              <TextField
                label="Branch name (shown in the run log)"
                onChange={(e) => setBranch(index, { ...branch, name: e.target.value })}
                placeholder="e.g. Trailer axle over the limit"
                size="small"
                value={branch.name || ''}
              />
              <ConditionGroupEditor
                fields={conditionFields}
                group={branch.conditions}
                onChange={(g) => setBranch(index, { ...branch, conditions: g })}
              />
              <Divider textAlign="left">
                <Typography color="text.secondary" variant="caption">
                  THEN
                </Typography>
              </Divider>
              <ActionListEditor
                actions={branch.actions}
                emptyText="Add an action for this branch."
                fields={fields}
                onChange={(a) => setBranch(index, { ...branch, actions: a })}
              />
            </Stack>
          </CardContent>
        </Card>
      ))}

      <Box>
        <Button onClick={() => set('else_if', [...branches, NEW_BRANCH])} startIcon={<Plus />} variant="outlined">
          Add ELSE IF
        </Button>
      </Box>

      <Card>
        <CardHeader
          subheader="Optional — runs when nothing above matched (for the right document type). Use {{flow.failed}} to list every check that failed."
          title="ELSE"
        />
        <CardContent>
          <ActionListEditor
            actions={draft.else_actions}
            emptyText="Nothing happens when no branch matches."
            fields={fields}
            onChange={(a) => set('else_actions', a)}
          />
        </CardContent>
      </Card>

      <TestPanel draft={draft} onClose={() => setTestOpen(false)} open={testOpen} />
    </Stack>
  );
}
