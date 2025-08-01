'use client';

import * as React from 'react';
import RouterLink from 'next/link';
import { usePathname } from 'next/navigation';
import Box from '@mui/material/Box';
import Button from '@mui/material/Button';
import Divider from '@mui/material/Divider';
import Stack from '@mui/material/Stack';
import Typography from '@mui/material/Typography';
import type { NavItemConfig } from '@/types/nav';
import { paths } from '@/paths';
import { isNavItemActive } from '@/lib/is-nav-item-active';
import { Logo } from '@/components/core/logo';
import { CaretUpDown as CaretUpDownIcon } from '@phosphor-icons/react/dist/ssr/CaretUpDown';

import { navItems } from './config';
import { navIcons } from './nav-icons';
import { usePopover } from '@/hooks/use-popover';
import { ChannelPopover } from './channel-popover';
import { useGetActiveChannelQuery } from '@/redux/ChannelApiSlice';
import { Chip, CircularProgress } from '@mui/material';
import { useSocket } from '@/lib/socketProvider';
import { ChannelModel } from '@/redux/models/ChannelModel';

export function SideNav(): React.JSX.Element {
  const pathname = usePathname();
  const userPopover = usePopover<HTMLDivElement>();
  const {data,isLoading,isFetching} = useGetActiveChannelQuery()

  return (
    <Box
      sx={{
        '--SideNav-background': 'var(--mui-palette-neutral-950)',
        '--SideNav-color': 'var(--mui-palette-common-white)',
        '--NavItem-color': 'var(--mui-palette-neutral-300)',
        '--NavItem-hover-background': 'rgba(255, 255, 255, 0.04)',
        '--NavItem-active-background': 'var(--mui-palette-primary-main)',
        '--NavItem-active-color': 'var(--mui-palette-primary-contrastText)',
        '--NavItem-disabled-color': 'var(--mui-palette-neutral-500)',
        '--NavItem-icon-color': 'var(--mui-palette-neutral-400)',
        '--NavItem-icon-active-color': 'var(--mui-palette-primary-contrastText)',
        '--NavItem-icon-disabled-color': 'var(--mui-palette-neutral-600)',
        bgcolor: 'var(--SideNav-background)',
        color: 'var(--SideNav-color)',
        display: { xs: 'none', lg: 'flex' },
        flexDirection: 'column',
        height: '100%',
        left: 0,
        maxWidth: '100%',
        position: 'fixed',
        scrollbarWidth: 'none',
        top: 0,
        width: 'var(--SideNav-width)',
        zIndex: 'var(--SideNav-zIndex)',
        '&::-webkit-scrollbar': { display: 'none' },
      }}
    >
      <Stack spacing={2} sx={{ p: 3 }}>
        <Box component={RouterLink} href={paths.home} sx={{ display: 'inline-flex' }}>
          <Logo color="light" height={100} width={500} />
        </Box>
        <Box
          sx={{
            alignItems: 'center',
            backgroundColor: 'var(--mui-palette-neutral-950)',
            border: '1px solid var(--mui-palette-neutral-700)',
            borderRadius: '12px',
            cursor: 'pointer',
            display: 'flex',
            p: '4px 12px',
          }}
          onClick={userPopover.handleOpen}
          ref={userPopover.anchorRef}
        >
          <Box sx={{ flex: '1 1 auto' }}>
            {isLoading || isFetching  ? <CircularProgress/> :<><Typography color="var(--mui-palette-neutral-400)" variant="body2">
              Active Channel
            </Typography>
            <Typography color="inherit" variant="subtitle1">
              {data && data?.data?.channel?.name}
            </Typography></>}
          </Box>
          <CaretUpDownIcon />

        </Box>
      </Stack>
      <Divider sx={{ borderColor: 'var(--mui-palette-neutral-700)' }} />
      <Box component="nav" sx={{ flex: '1 1 auto', p: '12px' }}>
        {renderNavItems({ pathname, items: navItems ,data:data?.data})}
      </Box>
      <Divider sx={{ borderColor: 'var(--mui-palette-neutral-700)' }} />
      <Stack spacing={2} sx={{ p: '12px' }}>

        {/* <Button
          fullWidth
          sx={{ mt: 2 }}
          variant="contained"
        >
          Sign out
        </Button> */}
      </Stack>
      <ChannelPopover anchorEl={userPopover.anchorRef.current} onClose={userPopover.handleClose} open={userPopover.open} />
    </Box>
  );
}

function renderNavItems({ items = [], pathname ,data}: { items?: NavItemConfig[]; pathname: string,data?: {channel:ChannelModel,messages:number,group:number,staffcountUnRead:number} }): React.JSX.Element {
  // const children = items.reduce((acc: React.ReactNode[], curr: NavItemConfig): React.ReactNode[] => {
  //   const { key, ...item } = curr;

  //   acc.push(<NavItem key={key} pathname={pathname} {...item} />);

  //   return acc;
  // }, []);

  const children = items.reduce(

    (acc, item) => reduceChildRoutes({ acc,pathname, item ,data}),
    []
  )

  return (
    <Stack component="ul" spacing={1} sx={{ listStyle: 'none', m: 0, p: 0 }}>
      {children}
    </Stack>
  );
}

function reduceChildRoutes({
  acc, pathname, item, depth = 0,data
}:any) {
  if (item.items) {
    // const open = matchPath(pathname, {
    //   path: item.href,
    //   exact: false
    // });

    acc.push(
      <NavItem
      key={Math.random() * 10000000}
      pathname={pathname} {...item}
      data={data}
      onC
      >
        {renderNavItems({
          // depth: depth + 1,
          pathname,
          items: item.items
        })}
      </NavItem>
    );
  } else {
    acc.push(
      <NavItem key={Math.random() * 10000000}  pathname={pathname} data={data} {...item}  />
    );
  }

  return acc;
}


interface NavItemProps extends Omit<NavItemConfig, 'items'> {
  pathname: string;
  children?:NavItemConfig[]
  data: {channel:ChannelModel,messages:number,group:number,staffcountUnRead:number,truckGroup:number}
}

function NavItem({ disabled, external, href, icon, matcher, pathname, title,badge,data,key}: NavItemProps): React.JSX.Element {

  const {socket} = useSocket()

  const active = isNavItemActive({ disabled, external, href, matcher, pathname });
  const Icon = icon ? navIcons[icon] : null;


  return (
    <li key={Math.random() * 1000000000} onClick={()=>{
     
      socket?.emit('staff_open_chat', null);
    }}>
      <Box
        {...(href
          ? {
              component: external ? 'a' : RouterLink,
              href,
              target: external ? '_blank' : undefined,
              rel: external ? 'noreferrer' : undefined,
            }
          : { role: 'button' })}
        sx={{
          alignItems: 'center',
          borderRadius: 1,
          color: 'var(--NavItem-color)',
          cursor: 'pointer',
          display: 'flex',
          flex: '0 0 auto',
          gap: 1,
          p: '6px 16px',
          position: 'relative',
          textDecoration: 'none',
          whiteSpace: 'nowrap',
          ...(disabled && {
            bgcolor: 'var(--NavItem-disabled-background)',
            color: 'var(--NavItem-disabled-color)',
            cursor: 'not-allowed',
          }),
          ...(active && { bgcolor: 'var(--NavItem-active-background)', color: 'var(--NavItem-active-color)' }),
        }}
      >
        <Box sx={{ alignItems: 'center', display: 'flex', justifyContent: 'center', flex: '0 0 auto' }}>
          {Icon ? (
            <Icon
              fill={active ? 'var(--NavItem-icon-active-color)' : 'var(--NavItem-icon-color)'}
              fontSize="var(--icon-fontSize-md)"
              weight={active ? 'fill' : undefined}
            />
          ) : null}
        </Box>
        <Box sx={{ flex: '1 1 auto' , display:"flex", flexDirection:"row",justifyContent:"space-between"}}>
          <Typography
            component="span"
            sx={{ color: 'inherit', fontSize: '0.875rem', fontWeight: 500, lineHeight: '28px' }}
          >
            {title}
          </Typography>
        {badge && title == "Messages" &&  data?.messages > 0 && <Chip sx={{
            background:"#fff",
            borderRadius:"10px!important"
          }} label={data?.messages}></Chip> }  
           {badge && title == "Groups" &&  data?.group > 0 && <Chip sx={{
            background:"#fff",
            borderRadius:"10px!important"
          }} label={data?.group}></Chip> }  
          {badge && title == "Staff Chat" &&  data?.staffcountUnRead > 0 && <Chip sx={{
            background:"#fff",
            borderRadius:"10px!important"
          }} label={data?.staffcountUnRead}></Chip> }  
          {badge && title == "Truck Chat" &&  data?.truckGroup > 0 && <Chip sx={{
            background:"#fff",
            borderRadius:"10px!important"
          }} label={data?.truckGroup}></Chip> }  
        </Box>
      </Box>
    </li>
  );
}

