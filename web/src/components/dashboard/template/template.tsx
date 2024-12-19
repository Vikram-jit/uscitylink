'use client';

import React, { useEffect, useState } from 'react';
import CloudUploadIcon from '@mui/icons-material/CloudUpload';
import { Card, CardActions, CardContent, Grid, IconButton, OutlinedInput, Typography } from '@mui/material';
import Button from '@mui/material/Button';
import FormLabel from '@mui/material/FormLabel';
import { Box, Stack, styled } from '@mui/system';
import { useCreateTemplateMutation, useGetTemplateByIdQuery, useUpdateTemplateMutation } from '@/redux/TemplateApiSlice';
import { useDispatch, useSelector } from 'react-redux';
import { RootState } from '@/redux/slices';
import useErrorHandler from '@/hooks/use-error-handler';
import { hideLoader, showLoader } from '@/redux/slices/loaderSlice';
import { useRouter, useSearchParams } from 'next/navigation';
import { paths } from '@/paths';
import { toast } from 'react-toastify';
import { useFileUploadMutation } from '@/redux/MessageApiSlice';
import MediaComponent from '@/components/messages/MediaComment';
import { Close } from '@mui/icons-material';

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

  const query = useSearchParams();

  const [createTemplate] = useCreateTemplateMutation()
  const [updateTemplate] = useUpdateTemplateMutation()
  const dispatch = useDispatch()
  const router = useRouter()
  const [message, setApiResponse] = useErrorHandler()
  const [state, setState] = useState({
    name: '',
    body: '',
  });
  const [file, setFile] = useState<any>()
  const [fileUpload] = useFileUploadMutation();

  const { data, isLoading } = useGetTemplateByIdQuery({ id: query.get('id') || '' }, {
    skip: !query.get('id')
  })
  useEffect(() => {
    if (data) {
      if (data.status) {
        setState({
          name: data?.data?.name,
          body: data?.data?.body
        })
      }
    }
  }, [data])
  async function onSubmit() {
    try {
      dispatch(showLoader())
      if (file) {
        let formData = new FormData();
        formData.append('file', file);
        formData.append('userId', '');
        formData.append('type', file.type.startsWith('image/') ? "media" : "doc");
        const res = await fileUpload(formData).unwrap();
        if (res.status) {
          const template = query.get('id') ? await updateTemplate({ id: query.get('id') || '', ...state, url: res?.data?.key }) : await createTemplate({ ...state, url: res?.data?.key });
          if (template.data) {
            toast.success(template.data.message)
            setState({ name: "", body: "" })
            router.push(paths.dashboard.templates)
          }
          dispatch(hideLoader())
          if (template.error) {
            setApiResponse(template.error as any)
          }
          return
        }
      }

      const res = query.get('id') ? await updateTemplate({ id: query.get('id') || '', ...state }) : await createTemplate(state);
      if (res.data) {
        toast.success(res.data.message)
        setState({ name: "", body: "" })
        router.push(paths.dashboard.templates)
      }
      dispatch(hideLoader())
      if (res.error) {
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
        <Grid container marginTop={2}>
          <Grid xs={12} md={12}>
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
            <FormGrid xs={12} style={{ marginTop: 16 }}>
              <Box display={"flex"} flex={1} flexDirection={"row"} justifyContent={"start"} alignItems={"center"}>
                <Button
                  component="label"
                  role={undefined}
                  variant="contained"
                  tabIndex={-1}
                  startIcon={<CloudUploadIcon />}
                >
                  select file
                  <VisuallyHiddenInput type="file" onChange={(event) => setFile(event.target.files?.[0])} />

                </Button>
                {file && <Box display={"flex"} alignItems={"center"}>
                  {
                    ['jpg', 'jpeg', 'png', 'gif', 'bmp'].includes(file.name?.split('.')?.pop()?.toLowerCase()) ? <img src={URL.createObjectURL(file)} width={100} height={200} style={{objectFit:"contain"}}/> : <Typography marginLeft={1}>{file.name}</Typography>
                  }


                  <IconButton onClick={() => setFile(null)}>
                    <Close />
                  </IconButton>
                </Box>}

              </Box>
              {data && data?.data?.url &&
                <Box sx={{
                  marginTop: 5
                }}>
                  <Typography sx={{ fontWeight: 800 }}>Attached Document</Typography>
                  <MediaComponent url={`https://ciity-sms.s3.us-west-1.amazonaws.com/${data?.data?.url}`} name={data?.data?.url ?? ''} width={100} height={100} />
                </Box>
              }
            </FormGrid>

          </Grid>

        </Grid>
      </CardContent>

      <CardActions sx={{ justifyContent: 'end' }}>
        <Button variant="text" LinkComponent={'a'} href={'/dashboard/templates'} color="inherit">
          Cancel
        </Button>
        <Button type="submit" variant="contained" onClick={onSubmit}>
          {query.get('id') ? "Update" : "Submit"}
        </Button>
      </CardActions>
    </Card>
  );
}
