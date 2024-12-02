'use client';

import React from 'react';
import { useGetUsersQuery } from '@/redux/UserApiSlice';
import { CircularProgress } from '@mui/material';

import { useParams } from 'next/navigation';
import { TemplateTable } from './tampleteTable';
import { useGetTemplatesQuery } from '@/redux/TemplateApiSlice';

export default function TemplateList() {
  const {role} = useParams()

  const page = 0;
  const rowsPerPage = 5;

  const { data, isLoading } = useGetTemplatesQuery();

  return (
    <>
      {/* <CustomersFilters /> */}
      {isLoading ? (
        <CircularProgress />
      ) : (
        <TemplateTable count={data?.data?.length} page={page} rows={data?.data} rowsPerPage={rowsPerPage}  />
      )}
    </>
  );
}
