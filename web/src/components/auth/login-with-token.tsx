'use client';

import * as React from 'react';
import { useParams, useRouter } from 'next/navigation';
import { useLoginWithTokenQuery } from '@/redux/AuthApiSlice';
import { CircularProgress, Dialog, DialogContent } from '@mui/material';
import Alert from '@mui/material/Alert';
import Stack from '@mui/material/Stack';
import Typography from '@mui/material/Typography';

import useErrorHandler from '@/hooks/use-error-handler';
import { useUser } from '@/hooks/use-user';

export function LoginWithToken(): React.JSX.Element {
  const router = useRouter();

  const { token } = useParams();
  const { checkSession } = useUser();

  const [message, setApiResponse] = useErrorHandler();

  const [errors, setErrors] = React.useState<string>('');
  const { data, isLoading, error } = useLoginWithTokenQuery({ token: token as string });

  React.useEffect(() => {
    const handleAsyncOperations = async () => {
      localStorage.removeItem('custom-auth-token');
      sessionStorage.clear();
        if (error) {
          setApiResponse(error as any);
        }
    
        if (data?.status ) {
           
          // Assuming this logic is correct: if the role exists, proceed with token handling
          localStorage.setItem('custom-auth-token', data?.data?.access_toke);
    
          try {
            // Ensure checkSession is safely invoked if it's a function
            if (checkSession) {
              await checkSession();
            }
    
            // Refresh the page (or navigate as needed)
            router.refresh();
          } catch (err) {
            console.error("Error during session check or refresh:", err);
          }
        }
      };
    
      handleAsyncOperations();
  }, [data, error,checkSession, router]);

  if (isLoading) {
    return (
      <Dialog open={isLoading} disableEscapeKeyDown>
        <DialogContent style={{ display: 'flex', justifyContent: 'center', alignItems: 'center' }}>
          <CircularProgress />
        </DialogContent>
      </Dialog>
    );
  }

  return (
    <Stack spacing={4}>
      <Alert color={message ? "error":"success"}>
        <Typography sx={{ fontWeight: 700 }} variant="inherit">
          {message? message :"Login successfully wait for redirect to dashboard."}
        </Typography>
      </Alert>
    </Stack>
  );
}
