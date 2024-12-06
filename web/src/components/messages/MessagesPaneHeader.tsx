import * as React from 'react';
import Avatar from '@mui/material/Avatar';
import Button from '@mui/material/Button';
import Chip from '@mui/material/Chip';
import IconButton from '@mui/material/IconButton';
import Stack from '@mui/material/Stack';
import Typography from '@mui/material/Typography';
import CircleIcon from '@mui/icons-material/Circle';
import ArrowBackIosNewRoundedIcon from '@mui/icons-material/ArrowBackIosNewRounded';
import MoreVertRoundedIcon from '@mui/icons-material/MoreVertRounded';
import { toggleMessagesPane } from './utils';
import { UserProfile } from '@/redux/models/ChannelModel';
import Menu from '@mui/material/Menu';
import MenuItem from '@mui/material/MenuItem';
import ListItemIcon from '@mui/material/ListItemIcon';

import { PaperPlane } from '@phosphor-icons/react';
import TemplateDialog from '../dashboard/template/TemplateDialog';
import moment from 'moment';

type MessagesPaneHeaderProps = {
  sender?: UserProfile;
  mediaPanel:boolean
  setMediaPanel:React.Dispatch<React.SetStateAction<boolean>>
  setSelectedTemplate:React.Dispatch<React.SetStateAction<{name:string,body:string,url?:string}>>
};

export default function MessagesPaneHeader(props: MessagesPaneHeaderProps) {
  const { sender,setMediaPanel,mediaPanel } = props;

  const [templateDialog,setTemplateDialog] = React.useState<boolean>(false)
  const [anchorEl, setAnchorEl] = React.useState<null | HTMLElement>(null);
  const open = Boolean(anchorEl);
  const handleClick = (event: React.MouseEvent<HTMLElement>) => {
    setAnchorEl(event.currentTarget);
  };
  const handleClose = () => {
    setAnchorEl(null);
  };
  return (
    <Stack
      direction="row"
      sx={{
        justifyContent: 'space-between',
        py: 2,
        px: 2,
        borderBottom: '1px solid',
        borderColor: 'divider',
        backgroundColor: 'background.paper',
      }}
    >
      <Stack
        direction="row"
        spacing={2}
        sx={{ alignItems: 'center' }}
      >
        <IconButton
          color="default"
          size="small"
          sx={{ display: { xs: 'inline-flex', sm: 'none' } }}
          onClick={() => toggleMessagesPane()}
        >
          <ArrowBackIosNewRoundedIcon />
        </IconButton>
        <Avatar alt={sender?.username} src={sender?.profile_pic || ""} />
        <div>
          <Typography
            variant="h6"
            noWrap
            sx={{ fontWeight: 'fontWeightBold' }}
          >
            {sender?.username}
            {sender?.isOnline && (
              <Chip
                size="small"
                color="success"
                sx={{ ml: 1 }}
                icon={<CircleIcon sx={{ fontSize: 12 }} />}
                label="Online"
              />
            )}
          </Typography>
          <Typography variant="body2">{sender?.isOnline ? "online" :moment(sender?.last_login).format('YYYY-MM-DD HH:mm') }</Typography>
        </div>
      </Stack>
      <Stack spacing={1} direction="row" sx={{ alignItems: 'center' }}>

        <Button
          onClick={()=>setMediaPanel((prev) => !prev)}
          variant="outlined"
          size="small"
          sx={{ display: { xs: 'none', md: 'inline-flex' } }}
        >
         {mediaPanel ? "View Messages"  : "View Media"}
        </Button>
        <IconButton   onClick={handleClick}
            size="small"
            sx={{ ml: 2 }}
            aria-controls={open ? 'account-menu' : undefined}
            aria-haspopup="true"
            aria-expanded={open ? 'true' : undefined}>
          <MoreVertRoundedIcon />
        </IconButton>
        <Menu
        anchorEl={anchorEl}
        id="account-menu"
        open={open}
        onClose={handleClose}
        onClick={handleClose}
        slotProps={{
          paper: {
            elevation: 0,
            sx: {
              overflow: 'visible',
              filter: 'drop-shadow(0px 2px 8px rgba(0,0,0,0.32))',
              mt: 1.5,
              '& .MuiAvatar-root': {
                width: 32,
                height: 32,
                ml: -0.5,
                mr: 1,
              },
              '&::before': {
                content: '""',
                display: 'block',
                position: 'absolute',
                top: 0,
                right: 14,
                width: 10,
                height: 10,
                bgcolor: 'background.paper',
                transform: 'translateY(-50%) rotate(45deg)',
                zIndex: 0,
              },
            },
          },
        }}
        transformOrigin={{ horizontal: 'right', vertical: 'top' }}
        anchorOrigin={{ horizontal: 'right', vertical: 'bottom' }}
      >


        <MenuItem onClick={()=>setTemplateDialog(true)}>
          <ListItemIcon>
            <PaperPlane fontSize="small" />
          </ListItemIcon>
          Templates
        </MenuItem>
      </Menu>
      {templateDialog && <TemplateDialog open={templateDialog} setOpen={setTemplateDialog} setSelectedTemplate={props.setSelectedTemplate}/>}
      </Stack>
    </Stack>
  );
}
