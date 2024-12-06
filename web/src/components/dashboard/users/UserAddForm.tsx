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
import { useAddUserMutation } from '@/redux/UserApiSlice';
import { useSearchParams, useRouter } from 'next/navigation';
import { toast } from 'react-toastify';

const states = [
  { value: 'admin', label: 'admin' },
  { value: 'staff', label: 'staff' },
  { value: 'driver', label: 'driver' },
] as const;

const schema = z
  .object({
    email: z.string().min(1, { message: 'Email is required' }).email().optional(),
    phone_number: z.string().min(1, { message: 'Phone number is required' }).optional(),
    username: z.string().min(1, { message: 'Username is required' }).optional(),
    role: z.string().min(1, { message: 'Role is required' }).optional(),
  })
  .refine((data) => data.email || data.phone_number, {
    message: 'Either email or phone number is required',
    path: ['email', 'phone_number'], // Path to include in the error message
  });

type Values = z.infer<typeof schema>;


export function UserAddForm({role}:{role:string}): React.JSX.Element {


  const defaultValues = {
    email: '',
    phone_number: '',
    username: '',
    role: role,
  } satisfies Values;

  const [addUser,{isLoading}] = useAddUserMutation()
  const router = useRouter();
  const {
    control,
    handleSubmit,
    setError,
    formState: { errors },
  } = useForm<Values>({ defaultValues, resolver: zodResolver(schema) });

  const onSubmit = React.useCallback(async (values: Values): Promise<void> => {

    const res:any = await addUser(values)

    if (res?.error) {
      if ('data' in res?.error) {
        setError('root', { type: 'server', message: res?.error?.data?.message });

        return;
      }
      setError('root', { type: 'server', message: 'SERVER ERROR' });

      return;
    }
    toast.success("User Add Successfully.")
    router.back()

  }, [router,setError]);

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
                <OutlinedInput  {...field}  label="Email" name="email" type="email" />
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
                <OutlinedInput  {...field}  label="Phone Number" name="phone_number" type="text" />
                {errors.phone_number ? <FormHelperText>{errors.phone_number.message}</FormHelperText> : null}
              </FormControl> )}
              />
            </Grid>
            {/* <Grid md={6} xs={12}>
                <Controller
                control={control}
                name="role"
                render={({ field }) => ( <FormControl fullWidth>
                <InputLabel>Role</InputLabel>
                <Select  {...field} label="Role" name="role" variant="outlined">
                  {states.map((option) => (
                    <MenuItem  key={option.value} value={option.value}>
                      {option.label}
                    </MenuItem>
                  ))}
                </Select>
                {errors.role ? <FormHelperText>{errors.role.message}</FormHelperText> : null}
              </FormControl> )}
              />
            </Grid> */}
          </Grid>
        </CardContent>
        <Divider />
        <CardActions sx={{ justifyContent: 'flex-end' }}>
          {isLoading &&  <CircularProgress size={24}/>}
        {errors.root ? <Alert color="error">{errors.root.message}</Alert> : null}
          <Button variant="text" LinkComponent={'a'} href={paths.dashboard.users} color="inherit">
            Cancel
          </Button>
          <Button type='submit' variant="contained">Submit</Button>
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
