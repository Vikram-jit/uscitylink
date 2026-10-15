import * as React from 'react';
import RouterLink from 'next/link';
import Box from '@mui/material/Box';
import Stack from '@mui/material/Stack';
import Typography from '@mui/material/Typography';

import { paths } from '@/paths';
import { BrandLogo } from '@/components/core/brand-logo';

export interface LayoutProps {
  children: React.ReactNode;
}

export function Layout({ children }: LayoutProps): React.JSX.Element {
  return (
    <Box
      sx={{
        display: { xs: 'flex', lg: 'grid' },
        flexDirection: 'column',
        gridTemplateColumns: '1fr 1fr',
        minHeight: '100%',
      }}
    >
      <Box sx={{ display: 'flex', flex: '1 1 auto', flexDirection: 'column' }}>
        <Box sx={{ p: 3, display: { xs: 'block', lg: 'none' } }}>
          <Box component={RouterLink} href={paths.home} sx={{ display: 'inline-flex' }}>
            <BrandLogo height={44} />
          </Box>
        </Box>
        <Box sx={{ alignItems: 'center', display: 'flex', flex: '1 1 auto', justifyContent: 'center', p: 3 }}>
          <Box sx={{ maxWidth: '450px', width: '100%' }}>{children}</Box>
        </Box>
      </Box>
      <Box
        sx={{
          alignItems: 'center',
          background: 'linear-gradient(150deg, #1e3a8a 0%, #1d4ed8 45%, #2563eb 100%)',
          color: 'var(--mui-palette-common-white)',
          display: { xs: 'none', lg: 'flex' },
          justifyContent: 'center',
          overflow: 'hidden',
          p: 6,
          position: 'relative',
          '&::before': {
            backgroundImage:
              'linear-gradient(rgba(255,255,255,0.07) 1px, transparent 1px), linear-gradient(90deg, rgba(255,255,255,0.07) 1px, transparent 1px)',
            backgroundSize: '44px 44px',
            content: '""',
            inset: 0,
            maskImage: 'radial-gradient(70% 70% at 50% 40%, #000 30%, transparent 100%)',
            position: 'absolute',
          },
        }}
      >
        <Box component={RouterLink} href={paths.home} sx={{ left: 48, position: 'absolute', top: 40 }}>
          <BrandLogo height={56} invert />
        </Box>
        <Stack spacing={5} sx={{ maxWidth: 520, position: 'relative' }}>
          <Stack spacing={2}>
            <Typography sx={{ color: '#bfdbfe', fontSize: 12.5, fontWeight: 600, letterSpacing: '0.08em', textTransform: 'uppercase' }}>
              USCityLink dispatch
            </Typography>
            <Typography
              color="inherit"
              sx={{ fontSize: 44, fontWeight: 700, letterSpacing: '-0.03em', lineHeight: 1.1 }}
            >
              Every driver.
              <br />
              Every load.
              <Box component="span" sx={{ color: '#bfdbfe' }}>
                {' '}
                One inbox.
              </Box>
            </Typography>
            <Typography sx={{ color: 'rgba(255, 255, 255, 0.8)', fontSize: 17, lineHeight: 1.6 }}>
              Chat with drivers, collect paperwork and keep your fleet moving, all from one place.
            </Typography>
          </Stack>
          <Stack spacing={1.5}>
            {[
              ['Live driver chat', 'Messages, photos and documents in real time'],
              ['Truck and group channels', 'Reach one driver or the whole fleet'],
              ['Built for dispatch', 'Fast, clear and made for busy shifts'],
            ].map(([title, text]) => (
              <Stack
                alignItems="center"
                direction="row"
                key={title}
                spacing={2}
                sx={{ backgroundColor: 'rgba(255, 255, 255, 0.1)', border: '1px solid rgba(255, 255, 255, 0.16)', borderRadius: '12px', px: 2.25, py: 1.75, backdropFilter: 'blur(6px)' }}
              >
                <Box sx={{ alignItems: 'center', backgroundColor: '#ffffff', borderRadius: '50%', color: '#1d4ed8', display: 'flex', flex: '0 0 auto', fontSize: 13, fontWeight: 700, height: 22, justifyContent: 'center', width: 22 }}>✓</Box>
                <Box>
                  <Typography color="inherit" sx={{ fontWeight: 700 }} variant="subtitle2">
                    {title}
                  </Typography>
                  <Typography sx={{ color: 'rgba(255, 255, 255, 0.75)', fontSize: 13.5 }}>{text}</Typography>
                </Box>
              </Stack>
            ))}
          </Stack>
        </Stack>
      </Box>
    </Box>
  );
}
