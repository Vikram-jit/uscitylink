'use client';

import dynamic from 'next/dynamic';
import { Box, CircularProgress } from '@mui/material';

// react-pdf / pdfjs-dist must only ever load in the browser: on the server pdfjs runs browser/Node-22-only
// code at import time, which crashed server rendering. Import the viewer through this wrapper.
const Viewer = dynamic(() => import('./viewer'), {
  ssr: false,
  loading: () => (
    <Box sx={{ display: 'flex', justifyContent: 'center', p: 6 }}>
      <CircularProgress />
    </Box>
  ),
});

export default Viewer;
