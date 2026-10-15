'use client';

import * as React from 'react';
import RouterLink from 'next/link';
import {
  Box,
  Button,
  Card,
  Chip,
  CircularProgress,
  Stack,
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableRow,
  Typography,
} from '@mui/material';
import { Plus } from '@phosphor-icons/react';

import { paths } from '@/paths';
import { useGetDocTypesQuery } from '@/redux/AutomationApiSlice';

export function DocTypeList(): React.JSX.Element {
  const { data, isLoading } = useGetDocTypesQuery();

  return (
    <Stack spacing={2}>
      <Stack alignItems="center" direction="row">
        <Typography color="text.secondary" sx={{ flex: 1 }} variant="body2">
          Each document type tells the AI what the paperwork looks like and which fields to read. Add 1–2 corrected
          example photos to each type to improve accuracy.
        </Typography>
        <Button component={RouterLink} href={`${paths.automation.docTypes}/new`} startIcon={<Plus />} variant="contained">
          New document type
        </Button>
      </Stack>
      <Card>
        <Box sx={{ overflowX: 'auto' }}>
          <Table sx={{ minWidth: 800 }}>
            <TableHead>
              <TableRow>
                <TableCell>Name</TableCell>
                <TableCell>Key</TableCell>
                <TableCell>Fields</TableCell>
                <TableCell>Examples</TableCell>
                <TableCell>Status</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {isLoading ? (
                <TableRow>
                  <TableCell align="center" colSpan={5}>
                    <CircularProgress size={24} />
                  </TableCell>
                </TableRow>
              ) : null}
              {data?.data?.map((docType) => (
                <TableRow
                  component={RouterLink}
                  hover
                  href={`${paths.automation.docTypes}/${docType.id}`}
                  key={docType.id}
                  sx={{ textDecoration: 'none' }}
                >
                  <TableCell>
                    <Typography variant="subtitle2">{docType.name}</Typography>
                    <Typography color="text.secondary" variant="body2">
                      {docType.description}
                    </Typography>
                  </TableCell>
                  <TableCell>
                    <code>{docType.key}</code>
                  </TableCell>
                  <TableCell>{docType.fields.length}</TableCell>
                  <TableCell>
                    {docType.exampleCount ? (
                      docType.exampleCount
                    ) : (
                      <Chip color="warning" label="None yet" size="small" variant="outlined" />
                    )}
                  </TableCell>
                  <TableCell>
                    {docType.active ? <Chip color="success" label="Active" size="small" /> : <Chip label="Off" size="small" />}
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </Box>
      </Card>
    </Stack>
  );
}
