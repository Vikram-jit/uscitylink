'use client';

import React from 'react';

import { CircularProgress } from '@mui/material';

import { GroupTable } from './GroupTable';
import { useGetGroupsQuery } from '@/redux/GroupApiSlice';


export default function GroupList() {
  const page = 0;
  const rowsPerPage = 5;

  const { data, isLoading } = useGetGroupsQuery();

  return (
    <>
      {/* <CustomersFilters /> */}
      {isLoading ? (
        <CircularProgress />
      ) : (
        <GroupTable count={data?.data?.length} page={page} rows={data?.data} rowsPerPage={rowsPerPage} />
      )}
    </>
  );
}
