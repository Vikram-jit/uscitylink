'use client';

import React from 'react';

import { CircularProgress } from '@mui/material';

import { useParams } from 'next/navigation';
import { TemplateTable } from './tampleteTable';
import { useGetTemplatesQuery } from '@/redux/TemplateApiSlice';
import { useSelector } from 'react-redux';
import useDebounce from '@/hooks/useDebounce';

export default function TemplateList() {
  const {role} = useParams()
  const {search} = useSelector((state:any)=>state)
  const value = useDebounce(search.search,200)
  const [page, setPage] = React.useState(1);

  const { data, isLoading } = useGetTemplatesQuery({page,search:value});

  return (
    <>
      {/* <CustomersFilters /> */}
      {isLoading ? (
        <CircularProgress />
      ) : (
        <TemplateTable count={data?.data?.data?.length} page={page} rows={data?.data?.data} setPage={setPage} pagination={data?.data?.pagination} />
      )}
    </>
  );
}
