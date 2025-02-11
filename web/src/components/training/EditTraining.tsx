'use client';

import React, { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { useDispatch } from 'react-redux';
import { Controller, useForm } from 'react-hook-form';
import { toast } from 'react-toastify';
import { hideLoader, showLoader } from '@/redux/slices/loaderSlice';
import { useAddQuestionsMutation, useGetTrainingByIdQuery } from '@/redux/TrainingApiSlice';
import { useGetUserWithoutChannelQuery } from '@/redux/UserApiSlice';
import ReactPlayer from 'react-player';
import QuestionForm from './QuestionForm';
import QuestionList from './QuestionList';
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
  Step,
  StepLabel,
  Stepper,
  TextareaAutosize,
  TextField,
  Typography,
} from '@mui/material';
import { UserModel } from '@/redux/models/UserModel';
import useErrorHandler from '@/hooks/use-error-handler';
import { paths } from '@/paths';

const steps = ['Training Details', 'Manage Questions', 'Assign Drivers', 'Review & Submit'];
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

export default function EditTraining({ id }:any) {
  const { data } = useGetTrainingByIdQuery({ id });
  const [questions, setQuestions] = useState<Question[]>([]);
  const [editingQuestion, setEditingQuestion] = useState(null);
  const [selectedUsers, setSelectedUsers] = useState<UserModel[]>([]);
  const [removedUsers, setRemovedUsers] = useState<UserModel[]>([]);
  const [activeStep, setActiveStep] = useState(0);
  const [addQuestions, { isLoading }] = useAddQuestionsMutation();
  const { data: userData } = useGetUserWithoutChannelQuery({ type: 'training' });
  const dispatch = useDispatch();
  const router = useRouter();
  const [message, setApiResponse] = useErrorHandler();

  const { control, handleSubmit, setValue, formState: { errors } } = useForm({
    defaultValues: { title: '', description: '' },
  });



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


  useEffect(()=>{
    if(userData?.status && data?.status){
     
        const filterUser = userData.data.filter((user)=> data?.data?.assgin_drivers.some((r) => r.driverId === user.id))
      
       if(filterUser.length > 0){
         setSelectedUsers(filterUser)
       }
    }
 },[userData,data])


  useEffect(() => {
    if (data?.status) {
      setValue('title', data?.data?.title);
      setValue('description', data?.data?.description);
      if (data?.data?.questions?.length > 0) {
        const loadedQuestions:any = data?.data?.questions.map(el => ({
          id: el.id,
          text: el.question,
          options: el.options.map(o => ({ id: o.id, text: o.option, isCorrect: o.isCorrect, isDeleted: false })),
          isDeleted: false,
        }));
        setQuestions(loadedQuestions);
      }
    }
  }, [data]);

  const handleNext = () => setActiveStep((prev) => prev + 1);
  const handleBack = () => setActiveStep((prev) => prev - 1);
  
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
        <Stepper activeStep={activeStep} alternativeLabel>
          {steps.map((label) => (
            <Step key={label}>
              <StepLabel>{label}</StepLabel>
            </Step>
          ))}
        </Stepper>
        <Grid container spacing={3} sx={{ marginTop: 3 }}>
          {activeStep === 0 && (
            <>
              <Grid item xs={12}>
                <Controller control={control} name="title" render={({ field }) => (
                  <FormControl fullWidth error={!!errors.title}>
                    <OutlinedInput {...field} placeholder="Enter title" readOnly />
                  </FormControl>
                )} />
              </Grid>
              <Grid item xs={12}>
                <Controller control={control} name="description" render={({ field }) => (
                  <FormControl fullWidth error={!!errors.description}>
                    <TextareaAutosize {...field} minRows={5} placeholder="Enter Description" readOnly />
                  </FormControl>
                )} />
              </Grid>
              {data?.status && (
                <Grid item xs={12}>
                  <ReactPlayer width="100%" controls url={`https://ciity-sms.s3.us-west-1.amazonaws.com/${data?.data?.key}`} height={400} />
                </Grid>
              )}
            </>
          )}
          {activeStep === 1 && (
            <>
             <Grid item xs={6}>
             <QuestionForm onSubmit={(q) => setQuestions([...questions, { ...q, id: Math.random().toString(36) }])} />
             </Grid>
             <Grid item xs={6}>
              <QuestionList questions={questions} onDelete={(id) => setQuestions(questions.map((q:any) => q.id === id ? { ...q, isDeleted: true } : q))} />
                </Grid>
            </>
          )}
          {activeStep === 2 && (
             <Grid item xs={12}>
            <Paper elevation={2} sx={{ mt: 3, p: 2 }}>
            
             
              <Autocomplete
                value={selectedUsers}
                multiple
                options={options}
                getOptionLabel={(option) => `${option.username}(${option.user.driver_number})`}
                onChange={handleChange}
                renderInput={(params) => <TextField {...params} placeholder="Select Drivers" />}
              />
            
            </Paper>
            </Grid>
          )}
          {activeStep === 3 && (
           <Grid item xs={12}>
              <Typography variant="h6">Review & Update</Typography>
              <ul>
                <li>Title: {data?.data?.title}</li>
                <li>Description: {data?.data?.description}</li>
             
              
              
                <li>Assigned Drivers: {selectedUsers.map((user)=>user.username)?.join(",")}</li>
              </ul>
              <QuestionList questions={questions} onDelete={(id) => setQuestions(questions.map((q:any) => q.id === id ? { ...q, isDeleted: true } : q))} />
              
            </Grid>
          )}
          <Grid item xs={12} sx={{ display: 'flex', justifyContent: 'space-between', marginTop: 3 }}>
            <Button disabled={activeStep === 0} onClick={handleBack}>Back</Button>
            {activeStep === steps.length - 1 ? (
              <Button variant="contained" onClick={updateTraining} disabled={isLoading}>Update</Button>
            ) : (
              <Button variant="contained" onClick={handleNext}>Next</Button>
            )}
          </Grid>
        </Grid>
      </CardContent>
    </Card>
  );
}
