import * as React from 'react';
import Box from '@mui/material/Box';
import Button from '@mui/material/Button';
import TextField from '@mui/material/TextField';
import IconButton from '@mui/material/IconButton';
import Stack from '@mui/material/Stack';
import FormatBoldRoundedIcon from '@mui/icons-material/FormatBoldRounded';
import FormatItalicRoundedIcon from '@mui/icons-material/FormatItalicRounded';
import StrikethroughSRoundedIcon from '@mui/icons-material/StrikethroughSRounded';
import FormatListBulletedRoundedIcon from '@mui/icons-material/FormatListBulletedRounded';
import SendRoundedIcon from '@mui/icons-material/SendRounded';

export type MessageInputProps = {
  textAreaValue: string;
  setTextAreaValue: (value: string) => void;
  onSubmit: () => void;
};

export default function MessageInput(props: MessageInputProps) {
  const { textAreaValue, setTextAreaValue, onSubmit } = props;

  const handleClick = () => {
    if (textAreaValue.trim() !== '') {
      onSubmit();
      setTextAreaValue('');
    }
  };

  return (
    <Box sx={{ px: 2, pb: 3 }}>
      <TextField
      fullWidth
        placeholder="Type something here…"
        aria-label="Message"
        multiline

        maxRows={10}
        value={textAreaValue}
        onChange={(event) => {
          setTextAreaValue(event.target.value);
        }}
        InputProps={{
          endAdornment: (
            <Stack
              direction="row"
              sx={{
                justifyContent: 'space-between',
                alignItems: 'center',
                flexGrow: 1,
                py: 1,
                pr: 1,
              }}
            >
              {/* <div>
                <IconButton size="small" color="default">
                  <FormatBoldRoundedIcon />
                </IconButton>
                <IconButton size="small" color="default">
                  <FormatItalicRoundedIcon />
                </IconButton>
                <IconButton size="small" color="default">
                  <StrikethroughSRoundedIcon />
                </IconButton>
                <IconButton size="small" color="default">
                  <FormatListBulletedRoundedIcon />
                </IconButton>
              </div> */}
              <Button
                size="small"
                color="primary"
                onClick={handleClick}
                endIcon={<SendRoundedIcon />}
              >
                Send
              </Button>
            </Stack>
          ),
        }}
        onKeyDown={(event) => {
          if (event.key === 'Enter' && (event.metaKey || event.ctrlKey)) {
            handleClick();
          }
        }}
        sx={{
          '& .MuiOutlinedInput-root': {
            minHeight: 50,
          },
        }}
      />
    </Box>
  );
}
