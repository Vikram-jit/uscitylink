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

type ChatBubbleProps = MessageModel & {
  variant: 'sent' | 'received';
  attachment:false
  sender:SenderModel
};

export default function ChatBubble(props: ChatBubbleProps) {
  const { body, variant, messageTimestampUtc,messageDirection,attachment,sender,url } = props;
  const isSent = variant === 'sent';
  const [isHovered, setIsHovered] = React.useState<boolean>(false);
  const [isLiked, setIsLiked] = React.useState<boolean>(false);
  const [isCelebrated, setIsCelebrated] = React.useState<boolean>(false);

  return (
    <Box sx={{ maxWidth: '60%', minWidth: 'auto' }}>
      <Stack
        direction="row"
        spacing={2}
        sx={{ justifyContent: 'space-between', mb: 0.25 }}
      >
        <Typography variant="caption">
          {messageDirection === 'S' ? sender?.username : sender?.username }
        </Typography>
        <Typography variant="caption">{moment(messageTimestampUtc).format('YYYY-MM-DD HH:mm:ss')}</Typography>
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
            <MediaComponent url={`https://ciity-sms.s3.us-west-1.amazonaws.com/${url}`} name={url ? url : ' '}/>
            {body &&  <Typography  variant="body2">{body}</Typography>}

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
            <Typography variant="body2">{body}</Typography>
          </Paper>
          {(isHovered || isLiked || isCelebrated) && (
            <Stack
              direction="row"
              spacing={0.5}
              sx={{
                justifyContent: isSent ? 'flex-end' : 'flex-start',
                position: 'absolute',
                top: '50%',
                p: 1.5,
              }}
            >
              <IconButton
                size="small"
                onClick={() => setIsLiked((prevState) => !prevState)}
              >
                {isLiked ? '❤️' : <FavoriteBorderIcon />}
              </IconButton>
              <IconButton
                size="small"
                onClick={() => setIsCelebrated((prevState) => !prevState)}
              >
                {isCelebrated ? '🎉' : <CelebrationOutlinedIcon />}
              </IconButton>
            </Stack>
          )}
        </Box>
      )}
    </Box>
  );
}
