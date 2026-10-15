'use client';

import * as React from 'react';
import {
  Box,
  Button,
  Checkbox,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  FormControlLabel,
  Grid,
  MenuItem,
  Stack,
  TextField,
  Typography,
} from '@mui/material';
import { toast } from 'react-toastify';

import { useCorrectMessageDocumentMutation, useGetDocTypesQuery } from '@/redux/AutomationApiSlice';
import type { MessageDocument } from '@/redux/models/AutomationModel';

import { FieldValuesEditor } from './FieldValuesEditor';
import { s3Url } from './utils';

export function CorrectionDialog({
  doc,
  open,
  onClose,
}: {
  doc: MessageDocument;
  open: boolean;
  onClose: () => void;
}): React.JSX.Element {
  // Staff can open this from chat; doc type list is admin only, so fall back to the current type
  const { data: docTypes } = useGetDocTypesQuery(undefined, { skip: !open });
  const [correct, { isLoading }] = useCorrectMessageDocumentMutation();
  const [docTypeKey, setDocTypeKey] = React.useState(doc.corrected_doc_type || doc.doc_type_key || 'other');
  const [values, setValues] = React.useState<Record<string, any>>({ ...(doc.fields || {}), ...(doc.corrected_fields || {}) });
  const [saveAsExample, setSaveAsExample] = React.useState(true);

  const docType = docTypes?.data?.find((d) => d.key === docTypeKey);
  const fields =
    docType?.fields ||
    Object.keys(values).map((key) => ({ key, label: key, type: typeof values[key] === 'number' ? ('number' as const) : ('string' as const) }));

  const save = async () => {
    try {
      await correct({
        id: doc.id,
        messageId: doc.message_id,
        doc_type_key: docTypeKey,
        fields: values,
        save_as_example: saveAsExample,
      }).unwrap();
      toast.success('Correction saved');
      onClose();
    } catch (err: any) {
      toast.error(err?.data?.message || 'Could not save correction');
    }
  };

  return (
    <Dialog fullWidth maxWidth="md" onClose={onClose} open={open}>
      <DialogTitle>Correct document</DialogTitle>
      <DialogContent>
        <Grid container spacing={2} sx={{ pt: 1 }}>
          {doc.media_key && !/\.pdf$/i.test(doc.media_key) ? (
            <Grid item md={5} xs={12}>
              <Box
                alt="Document"
                component="img"
                src={s3Url(doc.media_key)}
                sx={{ width: '100%', borderRadius: 1, border: 1, borderColor: 'divider' }}
              />
            </Grid>
          ) : null}
          <Grid item md={doc.media_key ? 7 : 12} xs={12}>
            <Stack spacing={2}>
              {docTypes?.data ? (
                <TextField
                  label="Document type"
                  onChange={(e) => setDocTypeKey(e.target.value)}
                  select
                  size="small"
                  value={docTypeKey}
                >
                  {docTypes.data.map((d) => (
                    <MenuItem key={d.key} value={d.key}>
                      {d.name}
                    </MenuItem>
                  ))}
                  <MenuItem value="other">Other / not paperwork</MenuItem>
                </TextField>
              ) : (
                <Typography variant="body2">Document type: {docTypeKey}</Typography>
              )}
              <FieldValuesEditor fields={fields} onChange={setValues} values={values} />
              <FormControlLabel
                control={<Checkbox checked={saveAsExample} onChange={(e) => setSaveAsExample(e.target.checked)} />}
                label="Suggest as a training example (a admin approves it)"
              />
            </Stack>
          </Grid>
        </Grid>
      </DialogContent>
      <DialogActions>
        <Button onClick={onClose}>Cancel</Button>
        <Button disabled={isLoading} onClick={() => void save()} variant="contained">
          Save correction
        </Button>
      </DialogActions>
    </Dialog>
  );
}
