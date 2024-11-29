'use client';

import React from 'react';
import { useGetUsersQuery } from '@/redux/UserApiSlice';
import { CircularProgress } from '@mui/material';

import { UsersTable } from './UsersTable';
import { useParams } from 'next/navigation';

export default function UserList() {
  const {role} = useParams()

  const page = 0;
  const rowsPerPage = 5;

  const { data, isLoading } = useGetUsersQuery({role:role as string});

  return (
    <>
      {/* <CustomersFilters /> */}
      {isLoading ? (
        <CircularProgress />
      ) : (
        <UsersTable count={data?.data?.length} page={page} rows={data?.data} rowsPerPage={rowsPerPage}  />
      )}
    </>
  );
}
