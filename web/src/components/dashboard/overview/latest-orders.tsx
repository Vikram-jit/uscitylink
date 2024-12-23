import * as React from 'react';
import Box from '@mui/material/Box';
import Button from '@mui/material/Button';
import Card from '@mui/material/Card';
import CardActions from '@mui/material/CardActions';
import CardHeader from '@mui/material/CardHeader';
import Chip from '@mui/material/Chip';
import Divider from '@mui/material/Divider';
import type { SxProps } from '@mui/material/styles';
import Table from '@mui/material/Table';
import TableBody from '@mui/material/TableBody';
import TableCell from '@mui/material/TableCell';
import TableHead from '@mui/material/TableHead';
import TableRow from '@mui/material/TableRow';
import { ArrowRight as ArrowRightIcon } from '@phosphor-icons/react/dist/ssr/ArrowRight';
import dayjs from 'dayjs';
import { User } from '@/redux/models/UserModel';
import { IconButton, Tooltip } from '@mui/material';
import { Edit } from '@mui/icons-material';

const statusMap = {
  pending: { label: 'Pending', color: 'warning' },
  delivered: { label: 'Delivered', color: 'success' },
  refunded: { label: 'Refunded', color: 'error' },
} as const;



export interface LatestOrdersProps {
  orders?: User[];
  sx?: SxProps;
}

export function LatestOrders({ orders = [], sx }: LatestOrdersProps): React.JSX.Element {
  return (
    <Card sx={sx}>
      <CardHeader title="Latest Added drivers" />
      <Divider />
      <Box sx={{ overflowX: 'auto' }}>
        <Table sx={{ minWidth: 800 }}>
          <TableHead>
            <TableRow>
              <TableCell>Name</TableCell>
              <TableCell>Driver Number</TableCell>
              <TableCell sortDirection="desc">Date</TableCell>
              <TableCell>Action</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {orders.map((item) => {
            
              return (
                <TableRow hover key={item.id}>
                  <TableCell>{item.profiles?.[0]?.username}</TableCell>
                  <TableCell>{item.driver_number}</TableCell>
                  <TableCell>{dayjs(item.createdAt).format('MMM D, YYYY')}</TableCell>
                  <TableCell>
                    <Tooltip title="Edit Information">
                      <IconButton LinkComponent={"a"} href={`/dashboard/users/edit/driver/${item.profiles?.[0]?.id}`}>
                        <Edit />
                      </IconButton>
                    </Tooltip>
                    {/* <Tooltip title="View">
                      <IconButton>
                        <RemoveRedEye />
                      </IconButton>
                    </Tooltip> */}
                  </TableCell>
                </TableRow>
              );
            })}
          </TableBody>
        </Table>
      </Box>
      <Divider />
      <CardActions sx={{ justifyContent: 'flex-end' }}>
        <Button
          LinkComponent={"a"}
          href="/dashboard/users/driver"
          color="inherit"
          endIcon={<ArrowRightIcon fontSize="var(--icon-fontSize-md)" />}
          size="small"
          variant="text"
        >
          View all
        </Button>
      </CardActions>
    </Card>
  );
}
