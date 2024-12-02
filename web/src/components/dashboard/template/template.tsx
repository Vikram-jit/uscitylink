'use client';

import React, { useState } from 'react';
import CloudUploadIcon from '@mui/icons-material/CloudUpload';
import { Card, CardActions, CardContent, Grid, OutlinedInput, Typography } from '@mui/material';
import Button from '@mui/material/Button';
import FormLabel from '@mui/material/FormLabel';
import { styled } from '@mui/system';
import { useCreateTemplateMutation } from '@/redux/TemplateApiSlice';
import { useDispatch, useSelector } from 'react-redux';
import { RootState } from '@/redux/slices';
import useErrorHandler from '@/hooks/use-error-handler';
import { hideLoader, showLoader } from '@/redux/slices/loaderSlice';
import { useRouter } from 'next/navigation';
import { paths } from '@/paths';
import { toast } from 'react-toastify';
import { useFileUploadMutation } from '@/redux/MessageApiSlice';

const VisuallyHiddenInput = styled('input')({
  clip: 'rect(0 0 0 0)',
  clipPath: 'inset(50%)',
  height: 1,
  overflow: 'hidden',
  position: 'absolute',
  bottom: 0,
  left: 0,
  whiteSpace: 'nowrap',
  width: 1,
});

const FormGrid = styled(Grid)(() => ({
  display: 'flex',
  flexDirection: 'column',
}));

export default function Template() {

  const [createTemplate] = useCreateTemplateMutation()
 const dispatch = useDispatch()
 const router = useRouter()
 const [message,setApiResponse] = useErrorHandler()
  const [state, setState] = useState({
    name: '',
    body: '',
  });
  const [file,setFile] = useState<any>()
  const [fileUpload] = useFileUploadMutation();

  async function onSubmit(){
    try {
      dispatch(showLoader())
      if(file){
        let formData = new FormData();
        formData.append('file', file);
        formData.append('userId', '');
        formData.append('type', file.type.startsWith('image/')? "media":"doc");
        const res = await fileUpload(formData).unwrap();
        if (res.status) {
          const template = await createTemplate({...state,url:res?.data?.key});
          if(template.data){
           toast.success(template.data.message)
           setState({name:"",body:""})
           router.push(paths.dashboard.templates)
          }
          dispatch(hideLoader())
          if(template.error){
           setApiResponse(template.error as any)
          }
          return
        }
      }

      const res = await createTemplate(state);
       if(res.data){
        toast.success(res.data.message)
        setState({name:"",body:""})
        router.push(paths.dashboard.templates)
       }
       dispatch(hideLoader())
       if(res.error){
        setApiResponse(res.error as any)
       }
    } catch (error) {
      dispatch(hideLoader())
       console.log(error)
    }
  }

  return (
    <Card elevation={5} sx={{ background: '#fff' }}>
      <CardContent>
        <Grid container spacing={3} marginTop={2}>
          <Grid xs={12} md={7}>
            <FormGrid xs={12}>
              <FormLabel htmlFor="first-name" required>
                Title
              </FormLabel>
              <OutlinedInput
                id="first-name"
                name="first-name"
                type="name"
                placeholder="template title"
                autoComplete="first name"
                required
                size="small"
                value={state.name}
                onChange={(e) => setState({ ...state, name: e.target.value })}
              />
            </FormGrid>
            <FormGrid xs={12} style={{ marginTop: 16 }}>
              <FormLabel htmlFor="first-name" required>
                Body
              </FormLabel>
              <OutlinedInput
                multiline
                rows={5}
                id="first-name"
                name="first-name"
                type="text"
                placeholder="template body"
                autoComplete="first name"
                required
                size="small"
                value={state.body}
                onChange={(e) => setState({ ...state, body: e.target.value })}
              />
            </FormGrid>
            <FormGrid xs={4} style={{ marginTop: 16 }}>
              <Button
                component="label"
                role={undefined}
                variant="contained"
                tabIndex={-1}
                startIcon={<CloudUploadIcon />}
              >
                select file
                <VisuallyHiddenInput type="file" onChange={(event) => setFile(event.target.files?.[0])}  />
              </Button>
            </FormGrid>
          </Grid>

        </Grid>
      </CardContent>

      <CardActions sx={{ justifyContent: 'center' }}>
        <Button variant="text" LinkComponent={'a'} href={'#'} color="inherit">
          Cancel
        </Button>
        <Button type="submit" variant="contained" onClick={onSubmit}>
          Submit
        </Button>
      </CardActions>
    </Card>
  );
}
