import * as React from 'react';
import { useTheme } from '@mui/material/styles';
import IconButton, { IconButtonProps } from '@mui/material/IconButton';

import DarkModeRoundedIcon from '@mui/icons-material/DarkModeRounded';
import LightModeIcon from '@mui/icons-material/LightMode';

export default function ColorSchemeToggle(props: IconButtonProps) {
  const { onClick, sx, ...other } = props;
  const theme = useTheme();
  const [mounted, setMounted] = React.useState(false);

  React.useEffect(() => {
    setMounted(true);
  }, []);

  // Ensure the component renders correctly on the first mount
  if (!mounted) {
    return (
      <IconButton
        size="small"


        {...other}
        sx={sx}
        disabled
      />
    );
  }

  const toggleColorScheme = () => {
    const newMode:any = theme.palette.mode === 'light' ? 'dark' : 'light';
    document.body.setAttribute('data-theme', newMode); // Example for applying the theme
    onClick?.(newMode);
  };

  return (
    <IconButton
      data-screenshot="toggle-mode"
      size="small"

      color="default"
      {...other}
      onClick={toggleColorScheme}
      sx={[
        theme.palette.mode === 'dark'
          ? { '& > *:first-of-type': { display: 'none' } }
          : { '& > *:first-of-type': { display: 'initial' } },
        theme.palette.mode === 'light'
          ? { '& > *:last-of-type': { display: 'none' } }
          : { '& > *:last-of-type': { display: 'initial' } },
        ...(Array.isArray(sx) ? sx : [sx]),
      ]}
    >
      <DarkModeRoundedIcon />
      <LightModeIcon />
    </IconButton>
  );
}
