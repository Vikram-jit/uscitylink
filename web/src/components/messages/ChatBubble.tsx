import * as React from 'react';
import Avatar from '@mui/material/Avatar';
import Box from '@mui/material/Box';
import IconButton from '@mui/material/IconButton';
import Stack from '@mui/material/Stack';
import Paper from '@mui/material/Paper';
import Typography from '@mui/material/Typography';
import CelebrationOutlinedIcon from '@mui/icons-material/CelebrationOutlined';
import FavoriteBorderIcon from '@mui/icons-material/FavoriteBorder';
import InsertDriveFileRoundedIcon from '@mui/icons-material/InsertDriveFileRounded';
import { MessageProps } from './types';
import { MessageModel, SenderModel } from '@/redux/models/MessageModel';
import moment from 'moment';
import MediaComponent from './MediaComment';
import { Check, Ticket } from '@phosphor-icons/react';
import { Delete, Done, DoneAll, Pin, PinDrop, PushPin, Replay, Reply } from '@mui/icons-material';
import { Divider, List, ListItem, ListItemButton, ListItemIcon, ListItemText } from '@mui/material';

type ChatBubbleProps = MessageModel & {
  variant: 'sent' | 'received';
  attachment:false
  sender:SenderModel,
  truckNumbers?:string
};

export default function ChatBubble(props: ChatBubbleProps) {
  const { body, variant, messageTimestampUtc,messageDirection,attachment,sender,url,deliveryStatus ,thumbnail,staffPin} = props;
  const isSent = variant === 'sent';
  const [isHovered, setIsHovered] = React.useState<boolean>(false);
  const [isLiked, setIsLiked] = React.useState<boolean>(false);
  const [isCelebrated, setIsCelebrated] = React.useState<boolean>(false);

  return (
    <Box sx={{ maxWidth: '60%', minWidth: 'auto' ,position:"relative"}}>
     
      <Stack
        direction="row"
        spacing={2}
        sx={{ justifyContent: 'space-between', mb: 0.25 }}
      >
        <Typography variant="body2">
          {messageDirection === 'S' ? sender?.username ? `${sender?.username}(staff)` : '(staff)' : `${sender?.username}(driver)` }
        </Typography>
        <Typography variant="caption">{moment(messageTimestampUtc).format('YYYY-MM-DD HH:mm')}</Typography>
        
      </Stack>
      {url ? (
        <Paper
          variant="outlined"
          sx={{
            px: 1.75,
            py: 1.25,
            borderRadius: 'lg',
            borderTopRightRadius: isSent ? 0 : 'lg',
            borderTopLeftRadius: isSent ? 'lg' : 0,

          }}
        >
            <MediaComponent thumbnail={`https://ciity-sms.s3.us-west-1.amazonaws.com/${thumbnail }`} url={`https://ciity-sms.s3.us-west-1.amazonaws.com/${url}`} name={url ? url : ' '}/>
            {body &&  <Typography  sx={{fontSize:16}}>{body}</Typography>}

        </Paper>
      ) : (
        <Box
          sx={{ position: 'relative' }}
          onMouseEnter={() => setIsHovered(true)}
          onMouseLeave={() => setIsHovered(false)}
        >
          <Paper
            sx={{
              p: 1.25,
              borderRadius: 'lg',
              bgcolor: isSent ? 'primary.main' : 'background.paper',
              color: isSent ? 'white' : 'text.primary',
              borderTopRightRadius: isSent ? 0 : 'lg',
              borderTopLeftRadius: isSent ? 'lg' : 0,
            }}
          >
            
             {staffPin == "1" && <Box sx={{
              position:"absolute",
              top:-8,
              ...(messageDirection == "R" && {  right : -5,transform: "rotate(60deg)",}),
              ...(messageDirection == "S" && {  left : -5,transform: "rotate(300deg)",}),
              
              
             }}> 
        <PushPin sx={{color: messageDirection == "R" ? "green": "orange"}}/>
      </Box>}
            <Typography sx={{fontSize:16}}>{body}</Typography>
          </Paper>
          {(isHovered) && (
            <Stack
              direction="column"
              spacing={0.5}
              sx={{
                justifyContent: isSent ? 'flex-end' : 'flex-start',
                position: 'absolute',
                top: '100%',
                p: 1.5,
                background:"white",
                zIndex:999999999999999
              }}
            >
               <List disablePadding>
          <ListItem disablePadding>
            <ListItemButton>
              <ListItemIcon>
                <Reply />
              </ListItemIcon>
              <ListItemText primary="Reply" />
            </ListItemButton>
          </ListItem>
          <Divider/>
          <ListItem disablePadding>
            <ListItemButton>
              <ListItemIcon>
               <PushPin/>
              </ListItemIcon>
              <ListItemText primary="Pin Message" />
            </ListItemButton>
          </ListItem>
          <Divider/>
          <ListItem disablePadding>
            <ListItemButton>
              <ListItemIcon>
               <Delete/>
              </ListItemIcon>
              <ListItemText primary="Delete" />
            </ListItemButton>
          </ListItem>
        </List>
            </Stack>
          )}
        </Box>
      )}
     {props.truckNumbers && messageDirection === "R" &&  <Typography variant="caption"> Assigned trucks:- <strong>{props.truckNumbers}</strong></Typography>}
      {messageDirection === 'S' && <Stack
        direction="row"
        spacing={2}
        sx={{ justifyContent: 'flex-end', mb: 0.25 }}
      >
        { deliveryStatus == "sent" ? <Done sx={{
          fontSize:14
        }}/> : <DoneAll sx={{
          fontSize:14,
          color:"blue"
        }}/>}
      </Stack>}
    </Box>
  );
}
