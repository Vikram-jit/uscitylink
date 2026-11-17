import * as React from 'react';
import Box from '@mui/material/Box';
import CircularProgress from '@mui/material/CircularProgress';

// Shown the moment a sidebar item is clicked, while the next dashboard page loads
// (before, the old page stayed on screen with no sign the click was taken).
export default function Loading(): React.JSX.Element {
  return (
    <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'center', minHeight: '60vh' }}>
      <CircularProgress />
    </Box>
  );
}
