'use client';

import * as React from 'react';
import RouterLink from 'next/link';
import { usePathname } from 'next/navigation';
import Avatar from '@mui/material/Avatar';
import Box from '@mui/material/Box';
import Button from '@mui/material/Button';
import Stack from '@mui/material/Stack';
import Typography from '@mui/material/Typography';
import type { NavItemConfig } from '@/types/nav';
import { paths } from '@/paths';
import { isNavItemActive } from '@/lib/is-nav-item-active';
import { BrandLogo } from '@/components/core/brand-logo';
import { CaretUpDown as CaretUpDownIcon } from '@phosphor-icons/react/dist/ssr/CaretUpDown';

import { navItems } from './config';
import { navIcons } from './nav-icons';
import { groupNavItems, navCssVars, navSurface } from './nav-style';
import { useGetProfileQuery } from '@/redux/UserApiSlice';
import { usePopover } from '@/hooks/use-popover';
import { ChannelPopover } from './channel-popover';
import { useGetActiveChannelQuery } from '@/redux/ChannelApiSlice';
import { useGetAutomationMeQuery } from '@/redux/AutomationApiSlice';
import { Chip, CircularProgress } from '@mui/material';
import { useSocket } from '@/lib/socketProvider';
import { ChannelModel } from '@/redux/models/ChannelModel';

export function SideNav(): React.JSX.Element {
  const pathname = usePathname();
  const userPopover = usePopover<HTMLDivElement>();
  const {data,isLoading,isFetching} = useGetActiveChannelQuery()
  const { data: profile } = useGetProfileQuery();
  const { data: me } = useGetAutomationMeQuery();
  // Admin-only items (Automation) are hidden from regular staff
  const visibleNavItems = (navItems as NavItemConfig[]).filter((item) => !item.adminOnly || me?.data?.isAdmin);
  const sections = groupNavItems(visibleNavItems);
  const name = profile?.data?.username || 'Dispatcher';

  return (
    <Box
      sx={{
        ...navCssVars,
        background: navSurface,
        borderRight: '1px solid var(--mui-palette-divider)',
        color: 'var(--mui-palette-text-primary)',
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
      <Stack spacing={2} sx={{ px: 2, pt: 2.5, pb: 2 }}>
        <Stack alignItems="center" component={RouterLink} direction="row" href={paths.home} spacing={1.5} sx={{ px: 0.5, textDecoration: 'none' }}>
          <BrandLogo height={40} />
          <Box>
            <Typography sx={{ color: 'text.primary', fontSize: 15, fontWeight: 700, letterSpacing: '-0.01em', lineHeight: 1.2 }}>
              US City Link
            </Typography>
            <Typography sx={{ color: 'text.secondary', fontSize: 12, lineHeight: 1.3 }}>Dispatch console</Typography>
          </Box>
        </Stack>
        <Box
          sx={{
            alignItems: 'center',
            backgroundColor: 'var(--mui-palette-background-paper)',
            border: '1px solid var(--mui-palette-divider)',
            borderRadius: '8px',
            boxShadow: '0 1px 2px rgba(15, 23, 42, 0.04)',
            cursor: 'pointer',
            display: 'flex',
            gap: 1,
            p: '8px 10px',
            transition: 'border-color 0.15s ease, background-color 0.15s ease',
            '&:hover': { backgroundColor: 'var(--mui-palette-background-level1)', borderColor: 'var(--mui-palette-neutral-300)' },
          }}
          onClick={userPopover.handleOpen}
          ref={userPopover.anchorRef}
        >
          <Box
            sx={{
              alignItems: 'center',
              backgroundColor: 'var(--mui-palette-primary-main)',
              borderRadius: '6px',
              color: '#fff',
              display: 'flex',
              flex: '0 0 auto',
              fontSize: 12,
              fontWeight: 700,
              height: 28,
              justifyContent: 'center',
              width: 28,
            }}
          >
            {(data?.data?.channel?.name || 'C').charAt(0).toUpperCase()}
          </Box>
          <Box sx={{ flex: '1 1 auto', minWidth: 0 }}>
            {isLoading || isFetching ? (
              <CircularProgress size={16} />
            ) : (
              <>
                <Typography sx={{ color: 'text.secondary', fontSize: 11, fontWeight: 500, lineHeight: 1.2 }}>Channel</Typography>
                <Typography noWrap sx={{ color: 'text.primary', fontSize: 13.5, fontWeight: 600, lineHeight: 1.35 }}>
                  {data && data?.data?.channel?.name}
                </Typography>
              </>
            )}
          </Box>
          <Box sx={{ color: 'text.secondary', display: 'flex' }}>
            <CaretUpDownIcon />
          </Box>
        </Box>
      </Stack>
      <Box component="nav" sx={{ flex: '1 1 auto', px: 1.5, pb: 1, overflowY: 'auto' }}>
        {sections.map((section) => (
          <Box key={section.label} sx={{ mb: 2 }}>
            <Typography
              sx={{ color: 'text.disabled', fontSize: 11, fontWeight: 600, letterSpacing: '0.06em', px: 1.5, pb: 0.75, textTransform: 'uppercase' }}
            >
              {section.label}
            </Typography>
            {renderNavItems({ pathname, items: section.items, data: data?.data })}
          </Box>
        ))}
      </Box>
      <Stack
        alignItems="center"
        direction="row"
        spacing={1.25}
        sx={{ borderTop: '1px solid var(--mui-palette-divider)', px: 2, py: 1.75 }}
      >
        <Avatar sx={{ height: 34, width: 34 }}>{name.charAt(0).toUpperCase()}</Avatar>
        <Box sx={{ minWidth: 0 }}>
          <Typography noWrap sx={{ color: 'text.primary', fontWeight: 600 }} variant="subtitle2">
            {name}
          </Typography>
          <Stack alignItems="center" direction="row" spacing={0.75}>
            <Box sx={{ backgroundColor: 'var(--mui-palette-success-main)', borderRadius: '50%', height: 7, width: 7 }} />
            <Typography sx={{ color: 'text.secondary', fontSize: 12 }}>Online</Typography>
          </Stack>
        </Box>
      </Stack>
      <ChannelPopover anchorEl={userPopover.anchorRef.current} onClose={userPopover.handleClose} open={userPopover.open} />
    </Box>
  );
}

function renderNavItems({ items = [], pathname ,data}: { items?: NavItemConfig[]; pathname: string,data?: {channel:ChannelModel,messages:number,group:number,staffcountUnRead:number,systemUnRead:number} }): React.JSX.Element {
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
    <Stack component="ul" spacing={0.5} sx={{ listStyle: 'none', m: 0, p: 0 }}>
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
  data: {channel:ChannelModel,messages:number,group:number,staffcountUnRead:number,truckGroup:number,systemUnRead:number}
}

// Unread counters: solid blue pill so they stand out against the quiet slate menu
const navBadgeSx = (_active: boolean) => ({
  bgcolor: 'var(--mui-palette-primary-main)',
  color: '#ffffff',
  fontWeight: 600,
  fontSize: 11.5,
  height: 20,
  borderRadius: '99px !important',
  '& .MuiChip-label': { px: 0.875 },
});

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
          borderRadius: '6px',
          color: 'var(--NavItem-color)',
          cursor: 'pointer',
          display: 'flex',
          flex: '0 0 auto',
          gap: 1.25,
          p: '4px 12px',
          mb: '2px',
          position: 'relative',
          textDecoration: 'none',
          transition: 'background-color 0.2s ease, color 0.2s ease, transform 0.15s ease',
          whiteSpace: 'nowrap',
          '&:hover': { bgcolor: 'var(--NavItem-hover-background)', color: 'var(--NavItem-hover-color)' },
          ...(disabled && {
            bgcolor: 'var(--NavItem-disabled-background)',
            color: 'var(--NavItem-disabled-color)',
            cursor: 'not-allowed',
          }),
          ...(active && {
            background: 'var(--NavItem-active-background)',
            color: 'var(--NavItem-active-color)',
            '&:hover': { background: 'var(--NavItem-active-background)', color: 'var(--NavItem-active-color)' },
          }),
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
            sx={{ color: 'inherit', fontSize: '0.875rem', fontWeight: active ? 600 : 500, lineHeight: '28px' }}
          >
            {title}
          </Typography>
        {badge && title == "Messages" &&  data?.messages > 0 && <Chip sx={navBadgeSx(active)} label={data?.messages}></Chip> }  
           {badge && title == "Groups" &&  data?.group > 0 && <Chip sx={navBadgeSx(active)} label={data?.group}></Chip> }  
          {badge && title == "Staff Chat" &&  data?.staffcountUnRead > 0 && <Chip sx={navBadgeSx(active)} label={data?.staffcountUnRead}></Chip> }  
          {badge && title == "Truck Chat" &&  data?.truckGroup > 0 && <Chip sx={navBadgeSx(active)} label={data?.truckGroup}></Chip> }
          {badge && title == "System Messages" && data?.systemUnRead > 0 && <Chip sx={navBadgeSx(active)} label={data?.systemUnRead}></Chip> }
        </Box>
      </Box>
    </li>
  );
}

