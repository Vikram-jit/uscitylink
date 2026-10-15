import * as React from 'react';
import Avatar from '@mui/material/Avatar';
import Box from '@mui/material/Box';
import Button from '@mui/material/Button';
import Chip from '@mui/material/Chip';
import IconButton from '@mui/material/IconButton';
import Stack from '@mui/material/Stack';
import Typography from '@mui/material/Typography';
import CircleIcon from '@mui/icons-material/Circle';
import ArrowBackIosNewRoundedIcon from '@mui/icons-material/ArrowBackIosNewRounded';
import MoreVertRoundedIcon from '@mui/icons-material/MoreVertRounded';
import { formatUtcTime, toggleMessagesPane } from './utils';
import { UserProfile } from '@/redux/models/ChannelModel';
import Menu from '@mui/material/Menu';
import MenuItem from '@mui/material/MenuItem';
import ListItemIcon from '@mui/material/ListItemIcon';

import { PaperPlane } from '@phosphor-icons/react';
import TemplateDialog from '../dashboard/template/TemplateDialog';
import moment from 'moment';
import { MessageModel } from '@/redux/models/MessageModel';
import { RestorePage } from '@mui/icons-material';

type MessagesPaneHeaderProps = {
  sender?: UserProfile;
  mediaPanel:boolean
  pinMessage:string
  unreadMessage:string
  truckNumbers?:string
  setPinMessage:React.Dispatch<React.SetStateAction<string>>
  setUnReadMessage:React.Dispatch<React.SetStateAction<string>>
  setPage:React.Dispatch<React.SetStateAction<number>>
  setMessages:React.Dispatch<React.SetStateAction<MessageModel[]>>
  setMediaPanel:React.Dispatch<React.SetStateAction<boolean>>
  setSelectedTemplate:React.Dispatch<React.SetStateAction<{name:string,body:string,url?:string}>>
  onHandlePin:()=>void
  handleReset:()=>void
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
        py: 1.5,
        px: 2.5,
        borderBottom: '1px solid',
        borderColor: 'divider',
        backgroundColor: 'background.paper',
      }}
    >
      <Stack
        direction="row"
        spacing={1.5}
        sx={{ alignItems: 'center', flex: '1 1 auto', minWidth: 0, pr: 2 }}
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
        <Box sx={{ minWidth: 0 }}>
          <Stack alignItems="center" direction="row" spacing={1}>
            <Typography noWrap sx={{ fontSize: 16, fontWeight: 600, letterSpacing: '-0.01em' }}>
              {sender?.username}
            </Typography>
            <Typography color="text.secondary" noWrap sx={{ fontSize: 13 }}>
              {sender?.user?.driver_number}
            </Typography>
            <Chip
              size="small"
              color={sender?.isOnline ? 'success' : 'default'}
              icon={<CircleIcon sx={{ fontSize: 8 }} />}
              label={sender?.isOnline ? 'Online' : 'Offline'}
            />
          </Stack>
          <Stack
            alignItems="center"
            direction="row"
            divider={<Typography color="text.disabled" component="span">·</Typography>}
            spacing={1}
            sx={{ color: 'text.secondary', fontSize: 13, mt: 0.25, flexWrap: 'wrap', rowGap: 0.25, '& > span': { whiteSpace: 'nowrap' } }}
          >
            {sender?.user?.phone_number ? <span>{sender?.user?.phone_number}</span> : null}
            {props.truckNumbers ? (
              <span>
                Truck <b style={{ color: 'var(--mui-palette-text-primary)', fontWeight: 600 }}>{props.truckNumbers}</b>
              </span>
            ) : null}
            {!sender?.isOnline && sender?.last_login ? <span>Last seen {formatUtcTime(sender?.last_login)}</span> : null}
          </Stack>
        </Box>
      </Stack>
      <Stack spacing={1} direction="row" sx={{ alignItems: 'center', flexShrink: 0 }}>

        <Button
          onClick={()=>setMediaPanel((prev) => !prev)}
          variant="outlined"
          size="small"
          sx={{ display: { xs: 'none', md: 'inline-flex' } }}
        >
         {mediaPanel ? "View Messages"  : "View Media"}
        </Button>
        <Button
          onClick={()=>{
         
            props.setPage(1)
            props.setPinMessage((prev) => prev == "0" ? "1" :"0")
           props.onHandlePin()
          }}
          variant={props.pinMessage == "0" ? "outlined":"contained"}
          size="small"
          sx={{ display: { xs: 'none', md: 'inline-flex' } }}
        >
         {props.pinMessage =="0" ? "View Pin Messages"  : "View All Messages"}
        </Button>
        <Button
          onClick={()=>{
         
           props.handleReset()
          }}
         
          size="small"
          sx={{ display: { xs: 'none', md: 'inline-flex' } }}
        >
        <RestorePage/>
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
