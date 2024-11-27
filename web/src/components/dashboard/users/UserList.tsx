'use client';

import React from 'react';
import { useGetUsersQuery } from '@/redux/UserApiSlice';
import { CircularProgress } from '@mui/material';

import { CustomersFilters } from '../customer/customers-filters';
import { UsersTable } from './UsersTable';

export default function UserList() {
  const page = 0;
  const rowsPerPage = 5;

  const { data, isLoading } = useGetUsersQuery({});

  return (
    <>
      {/* <CustomersFilters /> */}
      {isLoading ? (
        <CircularProgress />
      ) : (
        <UsersTable count={data?.data?.length} page={page} rows={data?.data} rowsPerPage={rowsPerPage} />
      )}
    </>
  );
}
