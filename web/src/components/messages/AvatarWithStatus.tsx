import * as React from 'react';
import Badge from '@mui/material/Badge';
import Avatar, { AvatarProps } from '@mui/material/Avatar';

type AvatarWithStatusProps = AvatarProps & {
  online?: boolean;
};

export default function AvatarWithStatus(props: AvatarWithStatusProps) {
  const { online = false, ...other } = props;
  return (
    <Badge
      color={online ? 'success' : 'default'}
      variant={online ? 'dot' : 'standard'}
      anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }}
      overlap="circular"
    >
      <Avatar {...other} />
    </Badge>
  );
}
