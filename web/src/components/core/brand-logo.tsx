import * as React from 'react';
import Box from '@mui/material/Box';

// USCityLink logo in ink for light surfaces and white for dark ones; swaps with the color scheme
export function BrandLogo({ height = 40, invert = false }: { height?: number; invert?: boolean }): React.JSX.Element {
  const width = Math.round(height * (487 / 280));
  const common = { height, width, objectFit: 'contain' as const };
  if (invert) {
    return <Box alt="US City Link" component="img" src="/assets/uscitylink-logo-white.png" sx={common} />;
  }
  return (
    <>
      <Box
        alt="US City Link"
        component="img"
        src="/assets/uscitylink-logo-dark.png"
        sx={{ ...common, display: 'block', '[data-mui-color-scheme="dark"] &': { display: 'none' } }}
      />
      <Box
        alt="US City Link"
        component="img"
        src="/assets/uscitylink-logo-white.png"
        sx={{ ...common, display: 'none', '[data-mui-color-scheme="dark"] &': { display: 'block' } }}
      />
    </>
  );
}
