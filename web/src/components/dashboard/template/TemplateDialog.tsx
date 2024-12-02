'use client';

import * as React from 'react';
import { useGetTemplatesQuery } from '@/redux/TemplateApiSlice';
import { Divider, List, ListItem, ListItemIcon, ListItemText } from '@mui/material';
import Button from '@mui/material/Button';
import Dialog from '@mui/material/Dialog';
import DialogActions from '@mui/material/DialogActions';
import DialogContent from '@mui/material/DialogContent';
import DialogContentText from '@mui/material/DialogContentText';
import DialogTitle from '@mui/material/DialogTitle';
import Slide from '@mui/material/Slide';
import { TransitionProps } from '@mui/material/transitions';

import MediaComponent from '@/components/messages/MediaComment';

const Transition = React.forwardRef(function Transition(
  props: TransitionProps & {
    children: React.ReactElement<any, any>;
  },
  ref: React.Ref<unknown>
) {
  return <Slide direction="up" ref={ref} {...props} />;
});

export default function TemplateDialog({
  open,
  setOpen,
  setSelectedTemplate,
}: {
  open: boolean;
  setOpen: React.Dispatch<React.SetStateAction<boolean>>;
  setSelectedTemplate: React.Dispatch<React.SetStateAction<{ name: string; body: string; url?: string }>>;
}) {
  const { data, isLoading } = useGetTemplatesQuery();

  const handleClose = () => {
    setOpen(false);
  };

  return (
    <React.Fragment>
      <Dialog
        fullWidth
        open={open}
        TransitionComponent={Transition}
        keepMounted
        onClose={handleClose}
        aria-describedby="alert-dialog-slide-description"
      >
        <DialogTitle>{'Templates'}</DialogTitle>
        <DialogContent>
          <List>
            {data &&
              data?.data?.map((e) => {
                return (
                  <>
                    <ListItem
                      key={e.id}
                      secondaryAction={
                        <>
                          <Button
                            size="small"
                            variant="outlined"
                            onClick={() => {
                              setSelectedTemplate({ name: e.name, body: e.body, url: e?.url });
                              setOpen(false);
                            }}
                          >
                            select
                          </Button>
                        </>
                      }
                    >
                      {e.url && (
                        <ListItemIcon>
                          <MediaComponent
                            url={`https://ciity-sms.s3.us-west-1.amazonaws.com/${e.url}`}
                            name={e.url ?? ''}
                            width={100}
                            height={100}
                          />
                        </ListItemIcon>
                      )}
                      <ListItemText primary={`${e.name}`} secondary={e.body} />
                    </ListItem>
                    <Divider />
                  </>
                );
              })}
          </List>
        </DialogContent>
        <DialogActions>
          <Button onClick={handleClose}>Disagree</Button>
          <Button onClick={handleClose}>Agree</Button>
        </DialogActions>
      </Dialog>
    </React.Fragment>
  );
}
