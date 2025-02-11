'use client';

import React, { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
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

import { paths } from '@/paths';
import { useSocket } from '@/lib/socketProvider';
import { Box } from '@mui/system';
import LinearProgress, { LinearProgressProps } from '@mui/material/LinearProgress';

type Values = {
  title: string;
  description: string;
};

export default function AddTraining() {
  const defaultValues = {
    title: '',
    description: '',
  } satisfies Values;
  const { socket } = useSocket();

  const [createTraining, { isLoading }] = useCreateTrainingMutation();
  const router = useRouter();
  const {
    control,
    handleSubmit,
    setError,
    formState: { errors },
  } = useForm<Values>({ defaultValues });

  // Use a state to track the selected file and its name
  const [selectedFile, setSelectedFile] = useState<File | null>(null);
  const [progrss,setProgress] = useState<number>(0)
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
      router.push(`${paths.dashboard.trainings}/edit/${res.data?.data?.id}`);
    },
    [setError, setSelectedFile, selectedFile]
  );

  useEffect(() => {
    if (socket) {
      socket.on('UPLOAD_PROGRESS', (data: any) => {
        setProgress(data)
      });
    }
    return () => {
      if (socket) {
        socket.off('UPLOAD_PROGRESS');
      }
    };
  }, [socket]);

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
                <ReactPlayer  width={"100%"} controls url={URL.createObjectURL(selectedFile)} height={300} />
              </Grid>
            )}

            {/* Submit Button */}
            
            <Grid item xs={12}>
          {isLoading &&  <LinearProgressWithLabel value={progrss}/> }
              <Button
                disabled={isLoading}
                sx={{ float: 'right', marginTop: 5, marginBottom: 5 }}
                type="submit"
                variant="contained"
              >
                Save & Next
              </Button>
              {isLoading && <CircularProgress style={{ float: 'right' }} />}
            </Grid>
          </Grid>
        </CardContent>
      </Card>
    </form>
  );
}



function LinearProgressWithLabel(props: LinearProgressProps & { value: number }) {
  return (
    <Box sx={{ display: 'flex', alignItems: 'center' }} marginTop={2}>
      <Box sx={{ width: '100%', mr: 1 }}>
        <LinearProgress variant="determinate" {...props} />
      </Box>
      <Box sx={{ minWidth: 35 }}>
        <Typography
          variant="body2"
          sx={{ color: 'text.primary' }}
        >{`${Math.round(props.value)}%`}</Typography>
      </Box>
    </Box>
  );
}