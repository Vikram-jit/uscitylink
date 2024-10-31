'use client';

import React from 'react';

import { CircularProgress } from '@mui/material';

import { useGetChannelMembersQuery } from '@/redux/ChannelApiSlice';
import { MemberTable } from './MemberTable';


export default function MemberList() {
  const page = 0;
  const rowsPerPage = 5;

  const { data, isLoading } = useGetChannelMembersQuery();

  return (
    <>
      {/* <CustomersFilters /> */}
      {isLoading ? (
        <CircularProgress />
      ) : (
        <MemberTable count={data?.data?.user_channels?.length} page={page} rows={data?.data?.user_channels} rowsPerPage={rowsPerPage} />
      )}
    </>
  );
}
