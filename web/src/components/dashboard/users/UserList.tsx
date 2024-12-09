'use client';

import React, { useEffect } from 'react';
import { useGetUsersQuery } from '@/redux/UserApiSlice';
import { CircularProgress } from '@mui/material';

import { UsersTable } from './UsersTable';
import { useParams } from 'next/navigation';
import { useSelector } from 'react-redux';
import useDebounce from '@/hooks/useDebounce';

export default function UserList() {
  const {role} = useParams()

  const {search} = useSelector((state:any)=>state)
  const value = useDebounce(search.search,200)
  const [page, setPage] = React.useState(1);

  const { data, isLoading } = useGetUsersQuery({role:role as string,page:page,search:value});

  useEffect(()=>{
    if(page != 1){
      setPage(1)
    }
  },[search])

  return (
    <>
      {/* <CustomersFilters /> */}
      {isLoading ? (
        <CircularProgress />
      ) : (
        <UsersTable count={data?.data?.users.length} page={page} rows={data?.data.users} setPage={setPage} pagination={data?.data?.pagination}  />
      )}
    </>
  );
}
