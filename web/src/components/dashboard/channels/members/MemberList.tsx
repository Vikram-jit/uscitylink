'use client';

import React from 'react';

import { CircularProgress } from '@mui/material';

import { useGetChannelMembersQuery } from '@/redux/ChannelApiSlice';
import { MemberTable } from './MemberTable';
import { useSelector } from 'react-redux';
import useDebounce from '@/hooks/useDebounce';


export default function MemberList() {

  const {search} = useSelector((state:any)=>state)
  const value = useDebounce(search.search,200)
  const [page, setPage] = React.useState(1);
  const { data, isLoading } = useGetChannelMembersQuery({page:page,pageSize:10,search:value});

  return (
    <>
      {/* <CustomersFilters /> */}
      {isLoading ? (
        <CircularProgress />
      ) : (
        <MemberTable count={data?.data?.user_channels?.length} page={page} rows={data?.data?.user_channels}  pagination={data?.data?.pagination} setPage={setPage} />
      )}
    </>
  );
}
