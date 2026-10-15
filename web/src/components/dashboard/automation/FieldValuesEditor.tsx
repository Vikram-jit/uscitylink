'use client';

import * as React from 'react';
import { FormControl, Grid, InputLabel, MenuItem, Select, TextField } from '@mui/material';

import type { DocField } from '@/redux/models/AutomationModel';

interface Props {
  fields: DocField[];
  values: Record<string, any>;
  onChange: (values: Record<string, any>) => void;
}

// Form for a document's field values — used for training examples and staff corrections
export function FieldValuesEditor({ fields, values, onChange }: Props): React.JSX.Element {
  const set = (key: string, value: any) => onChange({ ...values, [key]: value });

  return (
    <Grid container spacing={2}>
      {fields.map((field) => {
        const value = values?.[field.key];
        if (field.type === 'boolean') {
          return (
            <Grid item key={field.key} md={6} xs={12}>
              <FormControl fullWidth size="small">
                <InputLabel>{field.label}</InputLabel>
                <Select
                  label={field.label}
                  onChange={(e) => set(field.key, e.target.value === '' ? null : e.target.value === 'true')}
                  value={value === true ? 'true' : value === false ? 'false' : ''}
                >
                  <MenuItem value="">Not on document</MenuItem>
                  <MenuItem value="true">Yes</MenuItem>
                  <MenuItem value="false">No</MenuItem>
                </Select>
              </FormControl>
            </Grid>
          );
        }
        return (
          <Grid item key={field.key} md={6} xs={12}>
            <TextField
              InputLabelProps={field.type === 'date' ? { shrink: true } : undefined}
              fullWidth
              helperText={field.description || undefined}
              label={field.label}
              onChange={(e) => {
                const raw = e.target.value;
                if (raw === '') return set(field.key, null);
                set(field.key, field.type === 'number' ? Number(raw) : raw);
              }}
              size="small"
              type={field.type === 'number' ? 'number' : field.type === 'date' ? 'date' : 'text'}
              value={value ?? ''}
            />
          </Grid>
        );
      })}
    </Grid>
  );
}
