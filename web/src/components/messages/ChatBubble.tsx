import * as React from 'react';
import { MessageModel, SenderModel } from '@/redux/models/MessageModel';
import { Delete, Done, DoneAll, Forward, PushPin, Reply } from '@mui/icons-material';
import { Divider, List, ListItem, ListItemButton, ListItemIcon, ListItemText, Popover } from '@mui/material';
import Box from '@mui/material/Box';
import IconButton from '@mui/material/IconButton';
import Paper from '@mui/material/Paper';
import Stack from '@mui/material/Stack';
import Typography from '@mui/material/Typography';
import { Eye } from '@phosphor-icons/react';
import { DotsThree } from '@phosphor-icons/react/dist/ssr';
import moment from 'moment';

import { useSocket } from '@/lib/socketProvider';

import LinkifyText from '../LinkifyText';
import ForwardMessageDialog from './ForwardMessageDialog';
import MediaComponent from './MediaComment';
import { formatUtcTime } from './utils';

type ChatBubbleProps = MessageModel & {
  variant: 'sent' | 'received';
  attachment: false;
  sender: SenderModel;
  truckNumbers?: string;
  setSelectedMessageToReply?: React.Dispatch<React.SetStateAction<MessageModel | null>>;
  onClick?: () => void;
  isVisibleThreeDot?: boolean;
  singleMessage?:MessageModel
};

export default function ChatBubble(props: ChatBubbleProps) {
  const {
    body,
    variant,
    messageTimestampUtc,
    messageDirection,
    attachment,
    sender,
    url,
    deliveryStatus,
    thumbnail,
    staffPin,
    r_message,
  } = props;
  const isSent = variant === 'sent';

  const { socket } = useSocket();
  const [openDialog, setOpenDialog] = React.useState<boolean>(false);
  const [anchorEl, setAnchorEl] = React.useState<HTMLButtonElement | null>(null);

  const handleClick = (event: React.MouseEvent<HTMLButtonElement>) => {
    setAnchorEl(event.currentTarget);
  };

  const handleClose = () => {
    setAnchorEl(null);
  };
  const open = Boolean(anchorEl);
  return (
    <Box sx={{ maxWidth: '60%', minWidth: 'auto', position: 'relative' }}>
      <Stack direction="row" spacing={2} sx={{ justifyContent: 'space-between', mb: 0.25 }}>
        <Typography variant="body2">
          {messageDirection === 'S'
            ? sender?.username
              ? `${sender?.username}(staff)`
              : '(staff)'
            : `${sender?.username}(${sender?.user?.driver_number})`}
        </Typography>

        <Typography variant="caption">{formatUtcTime(messageTimestampUtc)}</Typography>
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
          {props.url_upload_type == 'not-upload' || props.url_upload_type == 'local' ? (
            <MediaComponent
              onClick={props.onClick}
              messageDirection={props.messageDirection}
              type={'server'}
              thumbnail={`http://52.9.12.189:4300/${props.url}`}
              url={`http://52.9.12.189:4300/${props.url}`}
              name={url ? url : ' '}
            />
          ) : (
            <MediaComponent
              onClick={props.onClick}
              messageDirection={props.messageDirection}
              type={props.url_upload_type}
              thumbnail={`https://ciity-sms.s3.us-west-1.amazonaws.com/${thumbnail}`}
              url={`https://ciity-sms.s3.us-west-1.amazonaws.com/${url}`}
              name={url ? url : ' '}
            />
          )}
          {body && <LinkifyText text={body} />}
        </Paper>
      ) : (
        <Box
          sx={{ position: 'relative' }}
          // onMouseEnter={() => setIsHovered(true)}
          // onMouseLeave={() => setIsHovered(false)}
        >
          <Paper
            sx={{
              p: 1.25,
              borderRadius: 'lg',
              bgcolor: isSent ? '#343344' : 'background.paper',
              color: isSent ? 'white' : 'text.primary',
              borderTopRightRadius: isSent ? 0 : 'lg',
              borderTopLeftRadius: isSent ? 'lg' : 0,
            }}
          >
            {staffPin == '1' && (
              <Box
                sx={{
                  position: 'absolute',
                  top: -8,
                  ...(messageDirection == 'R' && { right: -5, transform: 'rotate(60deg)' }),
                  ...(messageDirection == 'S' && { left: -5, transform: 'rotate(300deg)' }),
                }}
              >
                <PushPin sx={{ color: messageDirection == 'R' ? 'green' : 'orange' }} />
              </Box>
            )}
            {r_message && (
              <Box>
                <Stack direction="row" spacing={2} sx={{ justifyContent: 'space-between', mb: 0.25 }}>
                  <Typography variant="body2">
                    {r_message.messageDirection === 'S'
                      ? r_message.sender?.username
                        ? `${r_message.sender?.username}(staff)`
                        : '(staff)'
                      : `${r_message.sender?.username}(${r_message?.sender?.user?.driver_number})`}
                  </Typography>
                  <Typography variant="caption">
                    {moment(r_message.messageTimestampUtc).format('MM-DD-YYYY HH:mm A')}
                  </Typography>
                </Stack>
                {r_message.url ? (
                  <Paper
                    variant="outlined"
                    sx={{
                      px: 1.75,
                      py: 1.25,
                      bgcolor: 'background.paper',

                      borderLeft: '4px solid #ffbf00',
                      mb: 2,
                    }}
                  >
                    {r_message.url_upload_type == 'not-upload' || r_message.url_upload_type == 'local' ? (
                      <MediaComponent
                        messageDirection={props.messageDirection}
                        type={'server'}
                        thumbnail={`http://52.9.12.189:4300/${props.url}`}
                        url={`http://52.9.12.189:4300/${props.url}`}
                        name={r_message.url ? r_message.url : ' '}
                      />
                    ) : (
                      <MediaComponent
                        thumbnail={`https://ciity-sms.s3.us-west-1.amazonaws.com/${r_message.thumbnail}`}
                        url={`https://ciity-sms.s3.us-west-1.amazonaws.com/${r_message.url}`}
                        name={r_message.url ? r_message.url : ' '}
                      />
                    )}

                    {r_message.body && <LinkifyText text={r_message.body} />}
                  </Paper>
                ) : (
                  <Box sx={{ position: 'relative', mb: 2 }}>
                    <Paper
                      sx={{
                        p: 1.25,

                        bgcolor: 'background.paper',

                        borderLeft: '4px solid #ffbf00',
                      }}
                    >
                      <LinkifyText text={r_message.body} />
                    </Paper>
                  </Box>
                )}
              </Box>
            )}
            <LinkifyText text={body} />
          </Paper>
        </Box>
      )}
      {props.truckNumbers && messageDirection === 'R' && (
        <Typography variant="caption">
          {' '}
          Assigned trucks:- <strong>{props.truckNumbers}</strong>
        </Typography>
      )}

      <Stack direction="row" spacing={2} sx={{ justifyContent: 'flex-end', mb: 0.25 }}>
        {props.isVisibleThreeDot && (
          <IconButton onClick={handleClick} sx={{ padding: 0 }}>
            <DotsThree />
          </IconButton>
        )}
        {messageDirection === 'S' && deliveryStatus == 'sent' ? (
          <Done
            sx={{
              fontSize: 14,
            }}
          />
        ) : (
          <DoneAll
            sx={{
              fontSize: 14,
              color: 'blue',
            }}
          />
        )}
        <Popover
          id={`${props.id}-popover`}
          open={open}
          anchorEl={anchorEl}
          onClose={handleClose}
          anchorOrigin={{
            vertical: 'bottom',
            horizontal: 'left',
          }}
        >
          <List disablePadding>
            <ListItem disablePadding>
              <ListItemButton
                onClick={() => {
                  props.setSelectedMessageToReply?.(props);
                }}
              >
                <ListItemIcon>
                  <Reply />
                </ListItemIcon>
                <ListItemText primary="Reply" />
              </ListItemButton>
            </ListItem>
            <Divider />
            <ListItem disablePadding>
              <ListItemButton
                onClick={() => {
                  socket.emit('pin_message', {
                    messageId: props.id,
                    value: staffPin == '0' ? '1' : '0',
                    type: 'staff',
                  });
                }}
              >
                <ListItemIcon>
                  <PushPin />
                </ListItemIcon>
                <ListItemText primary={staffPin == '0' ? 'Pin Message' : 'Un-pin Message'} />
              </ListItemButton>
            </ListItem>
            <Divider />
            {props.deliveryStatus == 'sent' && props.messageDirection == 'S' && (
              <ListItem disablePadding>
                <ListItemButton
                  onClick={() => {
                    socket.emit('delete_message', { messageId: props.id });
                  }}
                >
                  <ListItemIcon>
                    <Delete color="error" />
                  </ListItemIcon>
                  <ListItemText primary="Delete" sx={{ color: 'red' }} />
                </ListItemButton>
              </ListItem>
            )}
            {props.url_upload_type == 'not-upload' && (
              <ListItem disablePadding>
                <ListItemButton
                  onClick={() => {
                    window.open(`http://52.9.12.189:4300/${props.url}`, '_blank');

                    handleClose();
                  }}
                >
                  <ListItemIcon>
                    <Eye />
                  </ListItemIcon>
                  <ListItemText primary="View Document" sx={{ color: 'green' }} />
                </ListItemButton>
              </ListItem>
            )}
            <ListItem disablePadding>
              <ListItemButton
                onClick={() => {
                  setOpenDialog(true);
                }}
              >
                <ListItemIcon>
                  <Forward />
                </ListItemIcon>
                <ListItemText primary="Forward" />
              </ListItemButton>
            </ListItem>
            <Divider />
          </List>
        </Popover>
      </Stack>
      {openDialog && (
        <ForwardMessageDialog
          open={openDialog}
          onClose={() => {
            setOpenDialog(false);
          }}
          message={props.singleMessage!}
        />
      )}
    </Box>
  );
}
