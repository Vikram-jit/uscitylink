'use client';

import React, { useState } from 'react';
import { useCreateTrainingMutation } from '@/redux/TrainingApiSlice';
import {
  Button,
  Card,
  CardContent,
  CircularProgress,
  FormControl,
  FormHelperText,
  Grid,
  Input,
  InputLabel,
  OutlinedInput,
  TextareaAutosize,
  Typography,
} from '@mui/material';
import { Controller, useForm } from 'react-hook-form';
import ReactPlayer from 'react-player';
import { toast } from 'react-toastify';
import { useRouter } from 'next/navigation';
import { paths } from '@/paths';

type Values = {
  title: string;
  description: string;
};

export default function AddTraining() {
  const defaultValues = {
    title: '',
    description: '',
  } satisfies Values;

  const [createTraining,{isLoading}] = useCreateTrainingMutation();
  const router = useRouter();
  const {
    control,
    handleSubmit,
    setError,
    formState: { errors },
  } = useForm<Values>({ defaultValues });

  // Use a state to track the selected file and its name
  const [selectedFile, setSelectedFile] = useState<File | null>(null);

  // Handle file selection
  const handleFileChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    if (event.target.files && event.target.files[0]) {
      setSelectedFile(event.target.files[0]);
    }
  };

  // Handle form submission
  const onSubmit = React.useCallback(
    async (values: Values): Promise<void> => {
      
      const formData = new FormData();
      formData.append('title', values.title);
      formData.append('description', values.description), formData.append('file', selectedFile!);

      const res: any = await createTraining({ formData });
        
      if (res?.error) {
        if ('data' in res?.error) {
          setError('root', { type: 'server', message: res?.error?.data?.message });

          return;
        }
        setError('root', { type: 'server', message: 'SERVER ERROR' });

        return;
      }
      toast.success('Data Saved Successfully.');
      router.push(`${paths.dashboard.trainings}/edit/${res.data?.data?.id}`)
    },
    [setError, setSelectedFile, selectedFile]
  );

  return (
    <form onSubmit={handleSubmit(onSubmit)}>
      <Card sx={{ borderRadius: '6px' }}>
        <CardContent>
          <Grid container spacing={3}>
           
            <Grid item xs={12}>
              <Controller
                control={control}
                name="title"
                render={({ field }) => (
                  <FormControl fullWidth error={!!errors.title}>
                 
                    <OutlinedInput
                      {...field}
                      name="title"
                      title="Title"
                      placeholder="Enter title"
                      type="text"
                      required
                    />
                    {errors.title && <FormHelperText>{errors.title.message}</FormHelperText>}
                  </FormControl>
                )}
                rules={{ required: 'Title is required' }}
              />
            </Grid>

            {/* Description Input */}
            <Grid item xs={12}>
              <Controller
                control={control}
                name="description"
                render={({ field }) => (
                  <FormControl fullWidth error={!!errors.description}>
                    <TextareaAutosize {...field} minRows={5} placeholder="Enter Description" />
                    {errors.description && <FormHelperText>{errors.description.message}</FormHelperText>}
                  </FormControl>
                )}
                rules={{ required: 'Description is required' }}
              />
            </Grid>

            {/* File Upload */}
            <Grid item xs={12}>
              <FormControl fullWidth>
                <Input
                  type="file"
                  onChange={handleFileChange} // Handle file change
                />
              </FormControl>
            </Grid>

            {/* Display selected file name */}
            {selectedFile && (
              <Grid item xs={12}>
                <ReactPlayer controls url={URL.createObjectURL(selectedFile)} height={300} />
              </Grid>
            )}

            {/* Submit Button */}
            <Grid item xs={12}>
              <Button disabled={isLoading} sx={{ float: 'right', marginTop: 5, marginBottom: 5 }} type="submit" variant="contained">
                Save & Next
              </Button>
              {isLoading && <CircularProgress style={{float:"right"}}/>}
            </Grid>
          </Grid>
        </CardContent>
      </Card>
    </form>
  );
}
