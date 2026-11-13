import * as React from 'react';
import { MessageModel, SenderModel } from '@/redux/models/MessageModel';
import { Delete, Done, DoneAll, Forward, LocalShipping, PushPin, Reply } from '@mui/icons-material';
import { Divider, List, ListItem, ListItemButton, ListItemIcon, ListItemText, Popover, Tooltip } from '@mui/material';
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
import { chat } from '@/styles/theme/chat-tokens';
import { DocumentChip } from '../dashboard/automation/DocumentChip';
import { formatUtcTime } from './utils';
import { CallBubble } from '@/calls/CallBubble';
import { mediaServerUrl } from '@/lib/serverUrl';
import { DeleteMessageDialog } from '../dashboard/trips/DeleteMessageDialog';
import { RepairLoadDialog } from '../dashboard/trips/RepairLoadDialog';
import { looksLikeLoad } from '../dashboard/trips/loadText';

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
  // Messages sent by the Dispatch Assistant (field exists once the automation module is installed)
  const automated = Boolean((props as { is_automated?: boolean }).is_automated);

  const { socket } = useSocket();
  const [openDialog, setOpenDialog] = React.useState<boolean>(false);
  const [anchorEl, setAnchorEl] = React.useState<HTMLButtonElement | null>(null);
  // Delete asks first when the message made a load
  const [deleting, setDeleting] = React.useState<string | null>(null);
  // A load text that never became a load can be added to Loads from here (nothing is sent again)
  const [converting, setConverting] = React.useState<string | null>(null);
  // …and the assistant's own old load messages ("TRIP #…" / "LOAD #…") can be repaired in place
  const canConvert = !props.url && (automated ? /^\s*(?:TRIP|LOAD)\b/i.test(String(props.body || '')) : looksLikeLoad(String(props.body || '')));

  const handleClick = (event: React.MouseEvent<HTMLButtonElement>) => {
    setAnchorEl(event.currentTarget);
  };

  const handleClose = () => {
    setAnchorEl(null);
  };
  const open = Boolean(anchorEl);
  // Call log ("Voice call · 3:42", "Missed voice call"), see server/src/calls/callLog.ts
  if ((props as { call_id?: string | null }).call_id) {
    return (
      <Box sx={{ maxWidth: '60%', minWidth: 0 }}>
        <CallBubble body={body} sent={messageDirection === 'S'} time={messageTimestampUtc as any} />
      </Box>
    );
  }
  return (
    <Box sx={{ maxWidth: '60%', minWidth: 0, position: 'relative' }}>
      <Stack direction="row" spacing={2} sx={{ justifyContent: 'space-between', mb: 0.25 }}>
        <Typography variant="body2">
          {messageDirection === 'S'
            ? props.is_automated
              ? '🤖 Dispatch Assistant'
              : sender?.username
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
            borderRadius: chat.radius,
            borderTopRightRadius: isSent ? '4px' : chat.radius,
            borderTopLeftRadius: isSent ? chat.radius : '4px',
            borderColor: automated ? 'rgba(var(--mui-palette-warning-mainChannel) / 0.35)' : 'var(--mui-palette-divider)',
            bgcolor: automated ? chat.assistant.bg : chat.driver.bg,
            boxShadow: 'none',
          }}
        >
          {props.url_upload_type == 'not-upload' || props.url_upload_type == 'local' ? (
            <MediaComponent
               createAt={props.messageTimestampUtc}
              onClick={props.onClick}
              messageDirection={props.messageDirection}
              type={'server'}
              thumbnail={`${mediaServerUrl()}/${props.url}`}
              url={`${mediaServerUrl()}/${props.url}`}
              // the local copy is deleted once the upload reaches S3
              fallbackUrl={`https://ciity-sms.s3.us-west-1.amazonaws.com/${props.url}`}
              name={url ? url : ' '}
            />
          ) : (
            <MediaComponent
              createAt={props.messageTimestampUtc}
              onClick={props.onClick}
              messageDirection={props.messageDirection}
              type={props.url_upload_type}
              thumbnail={`https://ciity-sms.s3.us-west-1.amazonaws.com/${thumbnail}`}
              url={`https://ciity-sms.s3.us-west-1.amazonaws.com/${url}`}
              name={url ? url : ' '}
            />
          )}
          {body && <LinkifyText text={body} />}
          {messageDirection === 'R' && props.id ? <DocumentChip messageId={props.id} /> : null}
        </Paper>
      ) : (
        <Box
          sx={{ position: 'relative' }}
          // onMouseEnter={() => setIsHovered(true)}
          // onMouseLeave={() => setIsHovered(false)}
        >
          <Paper
            sx={{
              px: 1.75,
              py: 1.25,
              borderRadius: chat.radius,
              ...(automated
                ? { bgcolor: chat.assistant.bg, color: chat.assistant.fg, border: chat.assistant.border }
                : isSent
                  ? { bgcolor: chat.staff.bg, color: chat.staff.fg, border: chat.staff.border }
                  : { bgcolor: chat.driver.bg, color: chat.driver.fg, border: chat.driver.border }),
              boxShadow: chat.shadow,
              borderTopRightRadius: isSent ? '4px' : chat.radius,
              borderTopLeftRadius: isSent ? chat.radius : '4px',
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
                        createAt={r_message.messageTimestampUtc}
                        messageDirection={props.messageDirection}
                        type={'server'}
                        thumbnail={`${mediaServerUrl()}/${r_message.url}`}
                        url={`${mediaServerUrl()}/${r_message.url}`}
                        fallbackUrl={`https://ciity-sms.s3.us-west-1.amazonaws.com/${r_message.url}`}
                        name={r_message.url ? r_message.url : ' '}
                      />
                    ) : (
                      <MediaComponent
                      createAt={r_message.messageTimestampUtc}
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
        {!props.isVisibleThreeDot && canConvert && (
          <Tooltip title="Add to loads / Repair (nothing is sent)">
            <IconButton onClick={() => setConverting(props.id)} sx={{ padding: 0 }} data-testid="convertToLoadIcon">
              <LocalShipping sx={{ fontSize: 16 }} />
            </IconButton>
          </Tooltip>
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
                    handleClose();
                    setDeleting(props.id);
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
                    window.open(`${mediaServerUrl()}/${props.url}`, '_blank');

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
            {canConvert && (
              <ListItem disablePadding>
                <ListItemButton
                  data-testid="convertToLoad"
                  onClick={() => {
                    handleClose();
                    setConverting(props.id);
                  }}
                >
                  <ListItemIcon>
                    <LocalShipping />
                  </ListItemIcon>
                  <ListItemText primary="Add to loads / Repair" />
                </ListItemButton>
              </ListItem>
            )}
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
      <RepairLoadDialog messageId={converting} onClose={() => setConverting(null)} />
      <DeleteMessageDialog
        messageId={deleting}
        onClose={() => setDeleting(null)}
        deleteMessage={(id) => socket.emit('delete_message', { messageId: id })}
      />
    </Box>
  );
}
