'use client';

import React, { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { useAddQuestionsMutation, useCreateTrainingMutation, useGetTrainingByIdQuery } from '@/redux/TrainingApiSlice';
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
import { Container } from '@mui/system';
import { Controller, useForm } from 'react-hook-form';
import ReactPlayer from 'react-player';
import { toast } from 'react-toastify';

import { paths } from '@/paths';

import QuestionForm from './QuestionForm';
import QuestionList from './QuestionList';

export interface Option {
  id: string;
  text: string;
  isCorrect: boolean;
  isDeleted:boolean
}

export interface Question {
  id: string;
  text: string;
  options: Option[];
  isDeleted:boolean
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
  const [addQuestions,{isLoading:submitLoader}] = useAddQuestionsMutation()
  const generateId = () => Math.random().toString(36).substr(2, 9);

  const handleAddQuestion = (questionData: Omit<Question, 'id'>) => {
    const newQuestion: Question = {
      id: generateId(),
      ...questionData,
      options: questionData.options.map((option) => ({
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
      options: questionData.options.map((option) => ({
        ...option,
        id: generateId(),
      })),
    };

    setQuestions(questions.map((q) => (q.id === editingQuestion.id ? updatedQuestion : q)));
    setEditingQuestion(null);
  };

  const handleDeleteQuestion = (id: string) => {
    setQuestions(questions.map((q) => q.id == id ? {...q,isDeleted:true}:q));
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
      if(data?.data?.questions?.length > 0){
          const questions:Question[] = [];
        data?.data?.questions?.forEach((el)=>{
          const q:Question = {id:el.id,text:el.question,options:[],isDeleted:false}
             el.options.forEach((o)=>{
              q.options.push({id:o.id,text:o.option,isCorrect:o.isCorrect,isDeleted:false})
             })

             questions.push(q)
        })
        setQuestions(questions)
      }
    }
  }, [data]);


  return (
    <Card sx={{ borderRadius: '6px', marginTop: 5 }}>
      <CardContent>
        <Grid container spacing={3}>
          <Grid item xs={12}>
            <Controller
              control={control}
              name="title"
              render={({ field }) => (
                <FormControl fullWidth error={!!errors.title}>
                  <OutlinedInput {...field} name="title" title="Title" placeholder="Enter title" type="text" readOnly />
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
          
              {editingQuestion ? (
                <QuestionForm onSubmit={handleUpdateQuestion} initialQuestion={editingQuestion} isEditing={true} />
              ) : (
                <QuestionForm onSubmit={handleAddQuestion} />
              )}
              <QuestionList questions={questions} onEdit={handleEditQuestion} onDelete={handleDeleteQuestion} />
           
          </Grid>

          {/* Submit Button */}
          <Grid item xs={12}>
            <Button
            onClick={async()=>{
              await addQuestions({id,questions})
                console.log(questions)
            }}  
              disabled={isLoading}
              sx={{ float: 'right', marginTop: 5, marginBottom: 5 }}
              variant="contained"
            >
             update
            </Button>
            {isLoading && <CircularProgress style={{ float: 'right' }} />}
          </Grid>
        </Grid>
      </CardContent>
    </Card>
  );
}
