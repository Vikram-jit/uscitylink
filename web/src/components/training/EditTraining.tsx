'use client';

import React, { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { useCreateTrainingMutation, useGetTrainingByIdQuery } from '@/redux/TrainingApiSlice';
import {
  Button,
  Card,
  CardContent,
  CircularProgress,
  Divider,
  FormControl,
 
  Grid,
 
  OutlinedInput,
  TextareaAutosize,
  TextField,
  Typography,
} from '@mui/material';
import { Controller, useForm } from 'react-hook-form';
import ReactPlayer from 'react-player';
import { toast } from 'react-toastify';

import { paths } from '@/paths';
import QuestionList from './QuestionList';
import { Container } from '@mui/system';
import QuestionForm from './QuestionForm';
export interface Option {
    id: string;
    text: string;
    isCorrect: boolean;
  }
  
  export interface Question {
    id: string;
    text: string;
    options: Option[];
  }
type Values = {
  title: string;
  description: string;
};

export default function EditTraining({ id }: { id: string }) {
  const defaultValues = {
    title: '',
    description: '',
  } satisfies Values;

  const { data } = useGetTrainingByIdQuery({ id });
  const [questions, setQuestions] = useState<Question[]>([]);
  const [editingQuestion, setEditingQuestion] = useState<Question | null>(null);

  const generateId = () => Math.random().toString(36).substr(2, 9);

  const handleAddQuestion = (questionData: Omit<Question, 'id'>) => {
    const newQuestion: Question = {
      id: generateId(),
      ...questionData,
      options: questionData.options.map(option => ({
        ...option,
        id: generateId(),
      })),
    };
    setQuestions([...questions, newQuestion]);
  };

  const handleEditQuestion = (question: Question) => {
    setEditingQuestion(question);
  };

  const handleUpdateQuestion = (questionData: Omit<Question, 'id'>) => {
    if (!editingQuestion) return;
    
    const updatedQuestion: Question = {
      ...editingQuestion,
      ...questionData,
      options: questionData.options.map(option => ({
        ...option,
        id: generateId(),
      })),
    };

    setQuestions(questions.map(q => 
      q.id === editingQuestion.id ? updatedQuestion : q
    ));
    setEditingQuestion(null);
  };

  const handleDeleteQuestion = (id: string) => {
    setQuestions(questions.filter(q => q.id !== id));
  };

  const [createTraining, { isLoading }] = useCreateTrainingMutation();
  const router = useRouter();
  const {
    control,
    handleSubmit,
    setError,
    setValue,
    formState: { errors },
  } = useForm<Values>({ defaultValues });

  useEffect(() => {
    if (data?.status) {
      setValue('title', data?.data?.title);
      setValue('description', data?.data?.description);
    }
  }, [data]);

  // Handle form submission
  const onSubmit = React.useCallback(
    async (values: Values): Promise<void> => {
      const formData = new FormData();

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
    [setError]
  );

  return (
    <form onSubmit={handleSubmit(onSubmit)}>
      <Card sx={{ borderRadius: '6px', marginTop: 5 }}>
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
                      readOnly
                    />
                  </FormControl>
                )}
              />
            </Grid>

            {/* Description Input */}
            <Grid item xs={12}>
              <Controller
                control={control}
                name="description"
                render={({ field }) => (
                  <FormControl fullWidth error={!!errors.description}>
                    <TextareaAutosize {...field} minRows={5} placeholder="Enter Description" readOnly />
                  </FormControl>
                )}
              />
            </Grid>

            {/* Display selected file name */}
            {data && data.status && (
              <Grid item xs={12}>
                <ReactPlayer
                  controls
                  url={`https://ciity-sms.s3.us-west-1.amazonaws.com/uscitylink/${data?.data?.key}`}
                  height={300}
                />
              </Grid>
            )}

            <Grid item xs={12} marginTop={3}>
              <Typography variant="h6">Add Quiz Question</Typography>
            </Grid>
            <Grid item xs={12}>
              <Divider />
            </Grid>
            <Grid item xs={12}>
            <Container maxWidth="md" sx={{ py: 4 }}>
        {editingQuestion ? (
          <QuestionForm
            onSubmit={handleUpdateQuestion}
            initialQuestion={editingQuestion}
            isEditing={true}
          />
        ) : (
          <QuestionForm onSubmit={handleAddQuestion} />
        )}
        <QuestionList
          questions={questions}
          onEdit={handleEditQuestion}
          onDelete={handleDeleteQuestion}
        />
      </Container>
            </Grid>


            
            {/* Submit Button */}
            <Grid item xs={12}>
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
