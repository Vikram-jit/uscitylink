'use client';

import React, { SetStateAction, useState } from 'react';
import { ArrowBackIos } from '@mui/icons-material';
import { Avatar, Box, Button, IconButton, ListItemIcon, Menu, MenuItem, Typography } from '@mui/material';
import { styled } from '@mui/system';
import { Eye } from '@phosphor-icons/react';
import { FiMoreVertical } from 'react-icons/fi';

interface GroupHeaderProps {
  group: any;
  setViewDetailGroup: (value: boolean) => void;
  isBack: boolean;
  setViewMedia:React.Dispatch<React.SetStateAction<boolean>>
  viewMedia:boolean
}

const HeaderContainer = styled(Box)({
  padding: '10px 16px',
  backgroundColor: '#f0f2f5',
  display: 'flex',
  alignItems: 'center',
  justifyContent: 'space-between',
  '&:hover': {
    cursor: 'pointer',
  },
});

const GroupHeader: React.FC<GroupHeaderProps> = ({ group, setViewDetailGroup, isBack,setViewMedia,viewMedia }) => {
  const [anchorEl, setAnchorEl] = useState<null | HTMLElement>(null);
  const [openMenu, setOpenMenu] = useState(false);

  const handleClick = (event: React.MouseEvent<HTMLElement>) => {
    setAnchorEl(event.currentTarget);
    setOpenMenu(true);
  };

  const handleClose = () => {
    setOpenMenu(false);
    setAnchorEl(null);
  };

  return (
    <HeaderContainer>
      <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
        {isBack && (
          <IconButton onClick={() => setViewDetailGroup(!isBack)}>
            <ArrowBackIos />
          </IconButton>
        )}
        <Avatar>{group?.data?.group?.name?.split('')?.[0]?.toUpperCase()}</Avatar>
        <Box onClick={() => setViewDetailGroup(!isBack)}>
          <Typography variant="subtitle1" sx={{ fontWeight: 'medium' }}>
            {group?.data?.group?.name}
          </Typography>
          <Typography variant="caption" color="text.secondary">
            {group?.data?.members?.length === 0
              ? 'No members yet'
              : ` Members: ${group?.data?.members?.map((e: any) => `${e?.UserProfile?.username} (${e?.UserProfile?.user?.driver_number})`)?.join(', ')}`}
          </Typography>
        </Box>
      </Box>

      {/* Right Side: Menu Icon */}
      {!isBack && (
        <Box sx={{ display: 'flex', gap: 1 }}>
          <Button sx={{ float: 'right' }} variant="outlined" onClick={()=>setViewMedia((prev) => !prev)}>
            {viewMedia ? "View Messages" : "View Media"}
          </Button>
          <IconButton
            onClick={handleClick}
            size="small"
            sx={{ ml: 2 }}
            aria-controls={openMenu ? 'account-menu' : undefined}
            aria-haspopup="true"
            aria-expanded={openMenu ? 'true' : undefined}
          >
            <FiMoreVertical />
          </IconButton>
          <Menu
            anchorEl={anchorEl}
            id="account-menu"
            open={openMenu}
            onClose={handleClose}
            onClick={handleClose}
            slotProps={{
              paper: {
                elevation: 0,
                sx: {
                  overflow: 'visible',
                  filter: 'drop-shadow(0px 2px 8px rgba(0,0,0,0.32))',
                  mt: 1.5,
                  '& .MuiAvatar-root': {
                    width: 32,
                    height: 32,
                    ml: -0.5,
                    mr: 1,
                  },
                  '&::before': {
                    content: '""',
                    display: 'block',
                    position: 'absolute',
                    top: 0,
                    right: 14,
                    width: 10,
                    height: 10,
                    bgcolor: 'background.paper',
                    transform: 'translateY(-50%) rotate(45deg)',
                    zIndex: 0,
                  },
                },
              },
            }}
            transformOrigin={{ horizontal: 'right', vertical: 'top' }}
            anchorOrigin={{ horizontal: 'right', vertical: 'bottom' }}
          >
            <MenuItem onClick={() => setViewDetailGroup(true)}>
              <ListItemIcon>
                <Eye fill="fill" fontSize="small" style={{ fontSize: 18 }} />
              </ListItemIcon>
              View Details
            </MenuItem>
          </Menu>
        </Box>
      )}
    </HeaderContainer>
  );
};

export default GroupHeader;
