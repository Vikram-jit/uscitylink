"use client"
import React from 'react';
import Dialog from '@mui/material/Dialog';
import DialogContent from '@mui/material/DialogContent';
import CircularProgress from '@mui/material/CircularProgress';
import { useSelector } from 'react-redux';
import { RootState } from '@/redux/slices';

const LoaderDialog: React.FC = () => {
  // Get the loading state from Redux store
  const loading = useSelector((state: RootState) => state.loader.loading);

  return (
    <Dialog open={loading}  disableEscapeKeyDown>
      <DialogContent style={{ display: 'flex', justifyContent: 'center', alignItems: 'center' }}>
        <CircularProgress />
      </DialogContent>
    </Dialog>
  );
};

export default LoaderDialog;
