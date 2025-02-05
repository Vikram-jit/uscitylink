'use client';

import React, { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { UserModel } from '@/redux/models/UserModel';
import { hideLoader, showLoader } from '@/redux/slices/loaderSlice';
import { useAddQuestionsMutation, useCreateTrainingMutation, useGetTrainingByIdQuery } from '@/redux/TrainingApiSlice';
import { useGetUserWithoutChannelQuery } from '@/redux/UserApiSlice';
import CheckBoxIcon from '@mui/icons-material/CheckBox';
import CheckBoxOutlineBlankIcon from '@mui/icons-material/CheckBoxOutlineBlank';
import {
  Autocomplete,
  Button,
  Card,
  CardContent,
  Checkbox,
  CircularProgress,
  Divider,
  FormControl,
  Grid,
  OutlinedInput,
  Paper,
  TextareaAutosize,
  TextField,
  Typography,
} from '@mui/material';
import { Container } from '@mui/system';
import { Controller, useForm } from 'react-hook-form';
import ReactPlayer from 'react-player';
import { useDispatch } from 'react-redux';
import { toast } from 'react-toastify';

import { paths } from '@/paths';
import useErrorHandler from '@/hooks/use-error-handler';

import QuestionForm from './QuestionForm';
import QuestionList from './QuestionList';

const icon = <CheckBoxOutlineBlankIcon fontSize="small" />;
const checkedIcon = <CheckBoxIcon fontSize="small" />;

export interface Option {
  id: string;
  text: string;
  isCorrect: boolean;
  isDeleted: boolean;
}

export interface Question {
  id: string;
  text: string;
  options: Option[];
  isDeleted: boolean;
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
  const [addQuestions, { isLoading: submitLoader }] = useAddQuestionsMutation();
  const generateId = () => Math.random().toString(36).substr(2, 9);
  const dispatch = useDispatch();
  const [message, setApiResponse] = useErrorHandler();

  const [selectedUsers, setSelectedUsers] = React.useState<UserModel[]>([]);
  const [removedUsers, setRemovedUsers] = React.useState<UserModel[]>([]);

  const handleChange = (event: any, newValue: any) => {
    

    const added = newValue.filter((option:any) => !selectedUsers.includes(option));
    const removed = selectedUsers.filter((option) => !newValue.includes(option));
    if (removed.length > 0) {
      setRemovedUsers((prevRemovedUsers) => {
        // Remove the user from removedUsers if it already exists
        const updatedRemovedUsers = prevRemovedUsers.filter(
          (user) => !removed.some((r) => r.id === user.id)
        );
        return [...updatedRemovedUsers, ...removed];
      });
    }
    if(added.length > 0){
      setRemovedUsers((prevRemovedUsers) => {
        // Remove the user from removedUsers if it already exists
        const updatedRemovedUsers = prevRemovedUsers.filter(
          (user) => !added.some((r:UserModel) => r.id === user.id)
        );
        return [...updatedRemovedUsers];
      });
    }

    // Handle added users after ensuring removed users are handled
   
      setSelectedUsers(newValue);
    
  };

  const { data: userData, isFetching } = useGetUserWithoutChannelQuery({type:"training"});

  useEffect(()=>{
     if(userData?.status && data?.status){
      
         const filterUser = userData.data.filter((user)=> data?.data?.assgin_drivers.some((r) => r.driverId === user.id))
       
        if(filterUser.length > 0){
          setSelectedUsers(filterUser)
        }
     }
  },[userData,data])


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
    setQuestions(questions.map((q) => (q.id == id ? { ...q, isDeleted: true } : q)));
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
      if (data?.data?.questions?.length > 0) {
        const questions: Question[] = [];
        data?.data?.questions?.forEach((el) => {
          const q: Question = { id: el.id, text: el.question, options: [], isDeleted: false };
          el.options.forEach((o) => {
            q.options.push({ id: o.id, text: o.option, isCorrect: o.isCorrect, isDeleted: false });
          });

          questions.push(q);
        });
        setQuestions(questions);
      }
    }
  }, [data]);

  async function updateTraining() {
   
    let drivers:any = [];
    let removedDrivers:any = [];
    if(selectedUsers.length >0 ){
      const type = selectedUsers.filter((e)=> e.id == "all");
      
      if(type.length>0){
          drivers = userData?.data?.map((item)=>item.id) || []
      }else{
        drivers = selectedUsers?.map((item)=>item.id)
      }
    }
    if(removedUsers.length > 0){
      removedDrivers = removedUsers?.map((item)=>item.id)
    }
   dispatch(showLoader());
    const res = await addQuestions({ id, questions,drivers: drivers,removedDrivers:removedDrivers});
    if (res.data) {
      dispatch(hideLoader());
      toast.success('Updated Data Successfully.');

      router.push(paths.dashboard.trainings);
    }
    if (res.error) {
      dispatch(hideLoader());
      setApiResponse(res.error as any);
    }
  }
  const options = [
    { id:"all", username: 'Select All', user: { driver_number: 'all',id:"all" } },  // "Select All" option
    
    ...(userData?.data || []), // Regular user data
  ];

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
          <Grid item xs={12}>
            <Paper elevation={2} sx={{ mt: 3, p: 2 }}>
              <Typography variant="h6" gutterBottom>
                Assgin To Driver
              </Typography>

              <Autocomplete
                value={selectedUsers}
                sx={{ marginTop: 2 }}
                multiple
                id="checkboxes-tags-demo"
                options={options}
                disableCloseOnSelect
                onChange={handleChange}
                getOptionLabel={(option) => {
                  return `${option.username}(${option.user.driver_number})`;
                }}
                renderOption={(props: any, option, { selected }) => {
                  const { key, ...optionProps } = props;
                  return (
                    <li key={key} {...optionProps}>
                      <Checkbox icon={icon} checkedIcon={checkedIcon} style={{ marginRight: 8 }} checked={selected} />
                      {`${option.username}(${option.user.driver_number})`}
                    </li>
                  );
                }}
                fullWidth
                renderInput={(params) => <TextField {...params}  placeholder="Select Drivers" />}
              />
            </Paper>
          </Grid>
          {/* Submit Button */}
          <Grid item xs={12}>
            <Button
              onClick={updateTraining}
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
