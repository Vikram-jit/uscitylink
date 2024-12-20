'use client';

import * as React from 'react';
import { zodResolver } from '@hookform/resolvers/zod';
import { Alert, Avatar, CircularProgress, FormHelperText, MenuItem, Select, Stack, Typography } from '@mui/material';
import Button from '@mui/material/Button';
import Card from '@mui/material/Card';
import CardActions from '@mui/material/CardActions';
import CardContent from '@mui/material/CardContent';
import CardHeader from '@mui/material/CardHeader';
import Divider from '@mui/material/Divider';
import FormControl from '@mui/material/FormControl';
import InputLabel from '@mui/material/InputLabel';
import OutlinedInput from '@mui/material/OutlinedInput';
import Grid from '@mui/system/Unstable_Grid';
import { Controller, useForm } from 'react-hook-form';
import { z } from 'zod';

import { paths } from '@/paths';
import { useAddUserMutation, useGenratePasswordMutation, useGetUserByIdQuery, useUpdateUserMutation } from '@/redux/UserApiSlice';
import {  useRouter } from 'next/navigation';
import { toast } from 'react-toastify';

const states = [
  { value: 'active', label: 'active' },
  { value: 'inactive', label: 'inactive' },
  
] as const;

const schema = z
  .object({

    email: z.string().min(1, { message: 'Email is required' }).email().optional(),
    phone_number: z.string().min(1, { message: 'Phone number is required' }).optional(),
    username: z.string().min(1, { message: 'Username is required' }).optional(),
    role: z.string().min(1, { message: 'Role is required' }).optional(),
    status: z.string().min(1, { message: 'Status is required' }).optional(),
    id: z.string().min(1, { message: 'Id is required' }).optional(),
  })
  .refine((data) => data.email || data.phone_number, {
    message: 'Either email or phone number is required',
    path: ['email', 'phone_number'], // Path to include in the error message
  });

type Values = z.infer<typeof schema>;


export function UserEditForm({role,id}:{role:string,id:string}): React.JSX.Element {


    const {data,isLoading:detailLoader} = useGetUserByIdQuery({id:id})

   
    const defaultValues = {
        id:id,
        email: '',
        phone_number: '',
        username: '',
        status: 'active',
        role: role,
    } satisfies Values;
  

  const [updateUser,{isLoading}] = useUpdateUserMutation()
  const router = useRouter();
  const {
    control,
    handleSubmit,
    setError,
    setValue,
    formState: { errors },
  } = useForm<Values>({ defaultValues, resolver:  zodResolver(schema) });

  const [genratePassword] = useGenratePasswordMutation()
  React.useEffect(() => {
    if (data?.data && data?.status) {
      // Update form fields dynamically when data is fetched
      setValue('email', data?.data?.user?.email || '');
      setValue('phone_number', data?.data?.user?.phone_number || '');
      setValue('username', data?.data?.username || '');
      setValue('status', data?.data?.status || '');
    }
  }, [data, setValue]); // Re-run this effect when data changes

  const onSubmit = React.useCallback(async (values: Values): Promise<void> => {


    const res:any = await updateUser(values)

    if (res?.error) {
      if ('data' in res?.error) {
        setError('root', { type: 'server', message: res?.error?.data?.message });

        return;
      }
      setError('root', { type: 'server', message: 'SERVER ERROR' });

      return;
    }
    toast.success("User Updated Successfully.")
    router.back()

  }, [router,setError]);

  if(detailLoader) return <Typography>Loading....</Typography>

  return (
    <form onSubmit={handleSubmit(onSubmit)}>
      
      <Card>
        <CardHeader title="Basic information" />
        <CardContent>
          <Stack spacing={2} sx={{ alignItems: 'start' }} direction={'row'} margin={1}>
            <div>
              <Avatar src={''} sx={{ height: '80px', width: '80px' }} />
            </div>
            <Stack spacing={1} sx={{ textAlign: 'left' }}>
              <Typography variant="h5">Avatar</Typography>
              <Typography color="text.secondary" variant="body2">
                Min 400x400px, PNG or JPEG
              </Typography>
              <FileUploadButton />
            </Stack>
          </Stack>
          <Grid container spacing={3} marginTop={2}>
            <Grid md={6} xs={12}>
              <Controller
                control={control}
                name="username"
                render={({ field }) => (
                  <FormControl fullWidth>
                    <InputLabel>User Name</InputLabel>
                    <OutlinedInput {...field} label="User Name" name="username" type="text" required />
                    {errors.username ? <FormHelperText>{errors.username.message}</FormHelperText> : null}
                  </FormControl>
                )}
              />
            </Grid>
            <Grid md={6} xs={12}>
            <Controller
                control={control}
                
                name="email"
                render={({ field }) => ( <FormControl fullWidth>
                <InputLabel>Email</InputLabel>
                <OutlinedInput  readOnly {...field}  label="Email" name="email" type="email" />
                {errors.email ? <FormHelperText>{errors.email.message}</FormHelperText> : null}
              </FormControl> )}
              />
            </Grid>
            <Grid md={6} xs={12}>
               <Controller
                control={control}
                name="phone_number"
                render={({ field }) => (  <FormControl fullWidth>
                <InputLabel>Phone Number</InputLabel>
                <OutlinedInput readOnly  {...field}  label="Phone Number" name="phone_number" type="text" />
                {errors.phone_number ? <FormHelperText>{errors.phone_number.message}</FormHelperText> : null}
              </FormControl> )}
              />
            </Grid>
            <Grid md={6} xs={12}>
                <Controller
                control={control}
                name="status"
                render={({ field }) => ( <FormControl fullWidth>
                <InputLabel>Status</InputLabel>
                <Select  {...field} label="Status" name="status" variant="outlined">
                  {states.map((option) => (
                    <MenuItem  key={option.value} value={option.value}>
                      {option.label}
                    </MenuItem>
                  ))}
                </Select>
                {errors.role ? <FormHelperText>{errors.role.message}</FormHelperText> : null}
              </FormControl> )}
              />
            </Grid>
            <Divider />
            <Grid md={12}>
            <Divider />
            </Grid>
            <Grid md={12}>
              
              <Button onClick={async()=>{
                        const res:any = await genratePassword({id})

                        if (res?.error) {
                          if ('data' in res?.error) {
                            setError('root', { type: 'server', message: res?.error?.data?.message });
                    
                            return;
                          }
                          setError('root', { type: 'server', message: 'SERVER ERROR' });
                    
                          return;
                        }
                        toast.success("New Password Generated Successfully. Send To User Email. ")
                       
              }} style={{marginTop:5}} variant="contained">Generate New Password</Button>
            </Grid>
          </Grid>
        </CardContent>
        <Divider />
        <CardActions sx={{ justifyContent: 'flex-end' }}>
          {isLoading &&  <CircularProgress size={24}/>}
        {errors.root ? <Alert color="error">{errors.root.message}</Alert> : null}
          <Button variant="text" LinkComponent={'a'} href={paths.dashboard.users} color="inherit">
            Cancel
          </Button>
          <Button type='submit' variant="contained">Update</Button>
        </CardActions>
      </Card>
    </form>
  );
}

const FileUploadButton: React.FC = () => {
  const fileInputRef = React.useRef<HTMLInputElement | null>(null);

  const handleClick = () => {
    if (fileInputRef.current) {
      fileInputRef.current.click();
    }
  };

  return (
    <>
      <input
        type="file"
        ref={fileInputRef}
        style={{ display: 'none' }} // Hide the default file input
        accept="image/*" // You can specify the types of files allowed
      />
      <Button variant="outlined" onClick={handleClick} color="inherit">
        Select
      </Button>
    </>
  );
};

export default FileUploadButton;
