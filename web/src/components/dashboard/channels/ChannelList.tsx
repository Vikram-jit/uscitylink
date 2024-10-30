'use client';

import React from 'react';

import { CircularProgress } from '@mui/material';

import { useGetChannelsQuery } from '@/redux/ChannelApiSlice';
import { ChannelTable } from './ChannelTable';


export default function ChannelList() {
  const page = 0;
  const rowsPerPage = 5;

  const { data, isLoading } = useGetChannelsQuery();

  return (
    <>
      {/* <CustomersFilters /> */}
      {isLoading ? (
        <CircularProgress />
      ) : (
        <ChannelTable count={data?.data?.length} page={page} rows={data?.data} rowsPerPage={rowsPerPage} />
      )}
    </>
  );
}
