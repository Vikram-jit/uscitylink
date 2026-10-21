'use client';

import * as React from 'react';
import { useRouter } from 'next/navigation';
import {
  Alert,
  Autocomplete,
  Box,
  Button,
  Card,
  CardContent,
  CardHeader,
  Checkbox,
  Chip,
  CircularProgress,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  FormControlLabel,
  Grid,
  IconButton,
  MenuItem,
  Stack,
  Switch,
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableRow,
  TextField,
  Tooltip,
  Typography,
} from '@mui/material';
import { ArrowLeft, Plus, Trash, UploadSimple } from '@phosphor-icons/react';
import { toast } from 'react-toastify';

import { paths } from '@/paths';
import {
  useCreateDocTypeMutation,
  useGetSuggestedKeywordsQuery,
  useCreateExampleMutation,
  useDeleteDocTypeMutation,
  useDeleteExampleMutation,
  useExtractSampleMutation,
  useGetDocTypeQuery,
  useUpdateDocTypeMutation,
  useUpdateExampleMutation,
} from '@/redux/AutomationApiSlice';
import type { DocField, DocType, DocTypeExample } from '@/redux/models/AutomationModel';
import DeleteConfirmationDialog from '@/components/DeleteConfirmationDialog';

import { FieldValuesEditor } from './FieldValuesEditor';
import { ProcessingNotice } from './ProcessingNotice';
import { formatValue, s3Url } from './utils';
import { AdminOnly, ReadOnlyArea } from './AdminGuard';

type Draft = Pick<DocType, 'key' | 'name' | 'description' | 'identify_hints' | 'keywords' | 'fields' | 'active'>;

const EMPTY: Draft = {
  key: '',
  name: '',
  description: '',
  identify_hints: '',
  keywords: [],
  fields: [{ key: '', label: '', type: 'string', description: '' }],
  active: true,
};

const toKey = (label: string) =>
  label
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '_')
    .replace(/^_+|_+$/g, '')
    .replace(/^(\d)/, 'f_$1')
    .slice(0, 63);

const errorMessage = (err: any) => err?.data?.message || err?.message || 'Something went wrong';

function FieldsTable({ fields, onChange }: { fields: DocField[]; onChange: (f: DocField[]) => void }): React.JSX.Element {
  const update = (i: number, patch: Partial<DocField>) => onChange(fields.map((f, j) => (j === i ? { ...f, ...patch } : f)));

  return (
    <Stack spacing={1}>
      <Box sx={{ overflowX: 'auto' }}>
        <Table size="small" sx={{ minWidth: 800 }}>
          <TableHead>
            <TableRow>
              <TableCell>Label</TableCell>
              <TableCell>Key</TableCell>
              <TableCell>Type</TableCell>
              <TableCell>Hint for the AI</TableCell>
              <TableCell />
            </TableRow>
          </TableHead>
          <TableBody>
            {fields.map((field, i) => (
              // eslint-disable-next-line react/no-array-index-key -- new rows have no key yet
              <TableRow key={i}>
                <TableCell>
                  <TextField
                    onChange={(e) => {
                      const label = e.target.value;
                      // Keep the key in sync until the admin edits it by hand
                      const autoKey = !field.key || field.key === toKey(field.label);
                      update(i, { label, ...(autoKey ? { key: toKey(label) } : {}) });
                    }}
                    placeholder="Gross weight (lb)"
                    size="small"
                    value={field.label}
                  />
                </TableCell>
                <TableCell>
                  <TextField onChange={(e) => update(i, { key: toKey(e.target.value) })} size="small" value={field.key} />
                </TableCell>
                <TableCell>
                  <TextField
                    onChange={(e) => update(i, { type: e.target.value as DocField['type'] })}
                    select
                    size="small"
                    sx={{ minWidth: 120 }}
                    value={field.type}
                  >
                    <MenuItem value="string">Text</MenuItem>
                    <MenuItem value="number">Number</MenuItem>
                    <MenuItem value="date">Date</MenuItem>
                    <MenuItem value="boolean">Yes / No</MenuItem>
                  </TextField>
                </TableCell>
                <TableCell>
                  <TextField
                    fullWidth
                    onChange={(e) => update(i, { description: e.target.value })}
                    placeholder="Where to find it, format…"
                    size="small"
                    value={field.description || ''}
                  />
                </TableCell>
                <TableCell>
                  <IconButton onClick={() => onChange(fields.filter((_f, j) => j !== i))}>
                    <Trash size={18} />
                  </IconButton>
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </Box>
      <Box>
        <Button onClick={() => onChange([...fields, { key: '', label: '', type: 'string', description: '' }])} size="small" startIcon={<Plus />}>
          Add field
        </Button>
      </Box>
    </Stack>
  );
}

// Upload a sample → see what the AI reads → correct it → save as a training example
function AddExampleDialog({ docType, open, onClose }: { docType: DocType; open: boolean; onClose: () => void }): React.JSX.Element {
  const [extractSample, { isLoading: extracting }] = useExtractSampleMutation();
  const [createExample, { isLoading: saving }] = useCreateExampleMutation();
  const [sample, setSample] = React.useState<{ s3_key: string; detected: string; confidence: number } | null>(null);
  const [values, setValues] = React.useState<Record<string, any>>({});
  const [preview, setPreview] = React.useState<string | null>(null);

  const reset = () => {
    setSample(null);
    setValues({});
    setPreview(null);
  };

  const [error, setError] = React.useState<string | null>(null);
  const [lastFile, setLastFile] = React.useState<File | null>(null);
  const pending = React.useRef<{ abort: () => void } | null>(null);

  const upload = async (file: File) => {
    reset();
    setError(null);
    setLastFile(file);
    setPreview(file.type.startsWith('image/') ? URL.createObjectURL(file) : null);
    const form = new FormData();
    form.append('file', file);
    const request = extractSample(form);
    pending.current = request;
    try {
      const res = await request.unwrap();
      setSample({ s3_key: res.data.s3_key, detected: res.data.analysis.doc_type, confidence: res.data.analysis.confidence });
      setValues(res.data.analysis.doc_type === docType.key ? res.data.analysis.fields : {});
    } catch (err: any) {
      setError(err?.name === 'AbortError' ? 'Cancelled.' : errorMessage(err));
    } finally {
      pending.current = null;
    }
  };

  const save = async () => {
    if (!sample) return;
    try {
      await createExample({ docTypeId: docType.id, s3_key: sample.s3_key, expected_fields: values }).unwrap();
      toast.success('Example saved — the AI will use it from now on');
      reset();
      onClose();
    } catch (err) {
      toast.error(errorMessage(err));
    }
  };

  return (
    <Dialog fullWidth maxWidth="md" onClose={onClose} open={open}>
      <DialogTitle>Add training example — {docType.name}</DialogTitle>
      <DialogContent>
        <Stack spacing={2} sx={{ pt: 1 }}>
          <Button component="label" disabled={extracting} startIcon={<UploadSimple />} variant="outlined">
            Choose a sample photo or PDF
            <input
              accept="image/*,application/pdf"
              hidden
              onChange={(e) => {
                const file = e.target.files?.[0];
                if (file) void upload(file);
                e.target.value = '';
              }}
              type="file"
            />
          </Button>
          <ProcessingNotice active={extracting} label="Reading the sample" onCancel={() => pending.current?.abort()} />
          {error ? (
            <Alert
              action={
                lastFile ? (
                  <Button color="inherit" onClick={() => void upload(lastFile)} size="small">
                    Try again
                  </Button>
                ) : undefined
              }
              severity="error"
            >
              {error}
            </Alert>
          ) : null}
          {sample ? (
            <Grid container spacing={2}>
              {preview ? (
                <Grid item md={5} xs={12}>
                  <Box alt="Sample" component="img" src={preview} sx={{ width: '100%', borderRadius: 1, border: 1, borderColor: 'divider' }} />
                </Grid>
              ) : null}
              <Grid item md={preview ? 7 : 12} xs={12}>
                <Stack spacing={2}>
                  {sample.detected === docType.key ? (
                    <Alert severity="success">
                      Recognized as {docType.name} ({Math.round(sample.confidence * 100)}%). Check every value below and fix
                      anything that is wrong — the AI learns from exactly what you save.
                    </Alert>
                  ) : (
                    <Alert severity="warning">
                      The AI thought this was “{sample.detected}”. Saving it as an example of {docType.name} teaches it the
                      difference. Fill in the correct values below.
                    </Alert>
                  )}
                  <FieldValuesEditor fields={docType.fields} onChange={setValues} values={values} />
                </Stack>
              </Grid>
            </Grid>
          ) : null}
        </Stack>
      </DialogContent>
      <DialogActions>
        <Button onClick={onClose}>Cancel</Button>
        <Button disabled={!sample || saving} onClick={() => void save()} variant="contained">
          Save example
        </Button>
      </DialogActions>
    </Dialog>
  );
}

function ExamplesSection({ docType }: { docType: DocType }): React.JSX.Element {
  const [open, setOpen] = React.useState(false);
  const [updateExample] = useUpdateExampleMutation();
  const [deleteExample] = useDeleteExampleMutation();
  const examples: DocTypeExample[] = docType.examples || [];

  return (
    <Card>
      <CardHeader
        action={
<AdminOnly><Button onClick={() => setOpen(true)} startIcon={<Plus />} variant="contained">
            Add example
          </Button></AdminOnly>
        }
        subheader="Training examples: real photos with the correct values. Up to 2 active examples per type are shown to the AI on every document."
        title="Examples"
      />
      <CardContent>
        {!examples.length ? (
          <Alert severity="info">No examples yet. Add one or two typical photos — clear ones and one messy one work best.</Alert>
        ) : (
          <Grid container spacing={2}>
            {examples.map((ex) => (
              <Grid item key={ex.id} md={4} sm={6} xs={12}>
                <Card variant="outlined">
                  {/\.pdf$/i.test(ex.s3_key) ? (
                    <Box sx={{ p: 2 }}>
                      <a href={s3Url(ex.s3_key)} rel="noreferrer" target="_blank">
                        Open PDF
                      </a>
                    </Box>
                  ) : (
                    <Box alt="Example" component="img" src={s3Url(ex.s3_key)} sx={{ width: '100%', height: 180, objectFit: 'cover' }} />
                  )}
                  <CardContent>
                    <Stack spacing={1}>
                      <Stack direction="row" spacing={1}>
                        <Chip label={ex.source === 'correction' ? 'From correction' : 'Uploaded'} size="small" variant="outlined" />
                      </Stack>
                      {Object.entries(ex.expected_fields || {})
                        .filter(([, v]) => v !== null && v !== '')
                        .slice(0, 6)
                        .map(([k, v]) => (
                          <Typography key={k} variant="body2">
                            <Typography color="text.secondary" component="span" variant="body2">
                              {k}:
                            </Typography>{' '}
                            {formatValue(v)}
                          </Typography>
                        ))}
                      <Stack alignItems="center" direction="row">
                        <FormControlLabel
                          control={<Switch checked={ex.active} onChange={(e) => void updateExample({ id: ex.id, active: e.target.checked })} />}
                          label="Used by AI"
                          sx={{ flex: 1 }}
                        />
                        <Tooltip title="Delete example">
                          <IconButton onClick={() => void deleteExample({ id: ex.id })}>
                            <Trash size={18} />
                          </IconButton>
                        </Tooltip>
                      </Stack>
                    </Stack>
                  </CardContent>
                </Card>
              </Grid>
            ))}
          </Grid>
        )}
      </CardContent>
      <AddExampleDialog docType={docType} onClose={() => setOpen(false)} open={open} />
    </Card>
  );
}

function KeywordsSection({
  id,
  keywords,
  onChange,
}: {
  id?: string;
  keywords: string[];
  onChange: (k: string[]) => void;
}): React.JSX.Element {
  const { data } = useGetSuggestedKeywordsQuery({ id: id || '' }, { skip: !id });
  const suggestions = data?.data?.suggestions || [];
  const add = (word: string) => onChange([...keywords, word]);

  return (
    <Card>
      <CardHeader
        subheader="Words that identify this document no matter how the page is laid out. The AI reads the page and the server also checks these words, so a new template with the same wording is still recognized."
        title="Keywords"
      />
      <CardContent>
        <Stack spacing={2}>
          <Autocomplete
            freeSolo
            multiple
            onChange={(_e, value) => onChange(value.map((v) => v.trim()).filter(Boolean))}
            options={[]}
            renderInput={(params) => (
              <TextField
                {...params}
                helperText="Type a word or phrase and press Enter, e.g. CAT Scale, steer axle, gross weight. Use 3 or more distinctive ones."
                label="Keywords"
                size="small"
              />
            )}
            value={keywords}
          />
          {suggestions.length ? (
            <Stack spacing={1}>
              <Typography variant="subtitle2">
                Suggested from {data?.data?.documents} real documents — click to add
              </Typography>
              <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 0.75 }}>
                {suggestions.map((s) => (
                  <Chip
                    key={s.word}
                    label={`${s.word} (${s.docs})`}
                    onClick={() => add(s.word)}
                    size="small"
                    variant="outlined"
                  />
                ))}
              </Box>
            </Stack>
          ) : id ? (
            <Typography color="text.secondary" variant="body2">
              Suggestions appear here once a few documents of this type have been read or corrected in chat.
            </Typography>
          ) : null}
        </Stack>
      </CardContent>
    </Card>
  );
}

export function DocTypeEditor({ id }: { id: string }): React.JSX.Element {
  const router = useRouter();
  const isNew = id === 'new';
  const { data, isLoading } = useGetDocTypeQuery({ id }, { skip: isNew });
  const [createDocType, { isLoading: creating }] = useCreateDocTypeMutation();
  const [updateDocType, { isLoading: updating }] = useUpdateDocTypeMutation();
  const [deleteDocType] = useDeleteDocTypeMutation();
  const [draft, setDraft] = React.useState<Draft>(EMPTY);
  const [confirmDelete, setConfirmDelete] = React.useState(false);

  React.useEffect(() => {
    if (data?.data) {
      const { key, name, description, identify_hints, keywords, fields, active } = data.data;
      setDraft({ key, name, description, identify_hints, keywords: keywords || [], fields, active });
    }
  }, [data]);

  const set = <K extends keyof Draft>(key: K, value: Draft[K]) => setDraft((d) => ({ ...d, [key]: value }));

  const save = async () => {
    try {
      const body = { ...draft, fields: draft.fields.filter((f) => f.key) };
      if (isNew) {
        const res = await createDocType(body).unwrap();
        toast.success('Document type created');
        router.replace(`${paths.automation.docTypes}/${res.data.id}`);
      } else {
        await updateDocType({ id, ...body }).unwrap();
        toast.success('Document type saved');
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
        <Button onClick={() => router.push(paths.automation.docTypes)} startIcon={<ArrowLeft />}>
          Document types
        </Button>
        <Box sx={{ flex: 1 }} />
        <AdminOnly>
          {!isNew ? (
            <Button color="error" onClick={() => setConfirmDelete(true)}>
              Delete
            </Button>
          ) : null}
          <Button disabled={creating || updating} onClick={() => void save()} variant="contained">
            {isNew ? 'Create' : 'Save'}
          </Button>
        </AdminOnly>
      </Stack>

      <ReadOnlyArea>
      <Stack spacing={3}>
      <Card>
        <CardContent>
          <Grid container spacing={2}>
            <Grid item md={6} xs={12}>
              <TextField
                fullWidth
                label="Name"
                onChange={(e) => {
                  set('name', e.target.value);
                  if (isNew && (!draft.key || draft.key === toKey(draft.name))) set('key', toKey(e.target.value));
                }}
                placeholder="Lumper receipt"
                required
                size="small"
                value={draft.name}
              />
            </Grid>
            <Grid item md={4} xs={8}>
              <TextField
                disabled={!isNew}
                fullWidth
                helperText={isNew ? 'Used in flow conditions; cannot be changed later' : 'Used in flow conditions'}
                label="Key"
                onChange={(e) => set('key', toKey(e.target.value))}
                size="small"
                value={draft.key}
              />
            </Grid>
            <Grid item md={2} xs={4}>
              <FormControlLabel control={<Checkbox checked={draft.active} onChange={(e) => set('active', e.target.checked)} />} label="Active" />
            </Grid>
            <Grid item xs={12}>
              <TextField
                fullWidth
                label="What it is"
                onChange={(e) => set('description', e.target.value)}
                placeholder="Receipt for unloading (lumper) service paid at the receiver."
                size="small"
                value={draft.description || ''}
              />
            </Grid>
            <Grid item xs={12}>
              <TextField
                fullWidth
                helperText="Describe what makes this document different from the others: title, logo, colors, stamps, layout."
                label="How to recognize it"
                minRows={2}
                multiline
                onChange={(e) => set('identify_hints', e.target.value)}
                size="small"
                value={draft.identify_hints || ''}
              />
            </Grid>
          </Grid>
        </CardContent>
      </Card>

      <KeywordsSection id={isNew ? undefined : id} keywords={draft.keywords || []} onChange={(k) => set('keywords', k)} />

      <Card>
        <CardHeader subheader="The values the AI reads from this document. Flows can use every field here." title="Fields" />
        <CardContent>
          <FieldsTable fields={draft.fields} onChange={(f) => set('fields', f)} />
        </CardContent>
      </Card>

      {!isNew && data?.data ? <ExamplesSection docType={data.data} /> : null}

      </Stack>
      </ReadOnlyArea>
      {confirmDelete ? (
        <DeleteConfirmationDialog
          onClose={() => setConfirmDelete(false)}
          onConfirm={async () => {
            await deleteDocType({ id });
            router.push(paths.automation.docTypes);
          }}
          open
        />
      ) : null}
    </Stack>
  );
}
