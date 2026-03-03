"use client";

import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  Table,
  TableHead,
  TableRow,
  TableCell,
  TableBody,
  Typography,
  Chip,
  Avatar,
  Box,
} from "@mui/material";

interface BroadcastDialogProps {
  open: boolean;
  onClose: () => void;
  data: any; // pass single broadcast log object
}

export default function BroadcastDialog({
  open,
  onClose,
  data,
}: BroadcastDialogProps) {
  if (!data) return null;

  return (
    <Dialog
      open={open}
      onClose={onClose}
      fullWidth
      maxWidth="lg"
    >
      <DialogTitle>
        Broadcast Message Details
      </DialogTitle>

      <DialogContent dividers sx={{ maxHeight: 500 }}>
        
        <Table stickyHeader>
          <TableHead>
            <TableRow>
              <TableCell>Name</TableCell>
              <TableCell>Phone</TableCell>
              <TableCell>Driver Number</TableCell>
              <TableCell>Status</TableCell>
            
              <TableCell>Message</TableCell>
            </TableRow>
          </TableHead>

          <TableBody>
            {data?.map((msg: any) => {
              const profile = msg.userProfile;
              const user = profile?.user;

              return (
                <TableRow key={msg.id} hover>
                  <TableCell>
                    <Box display="flex" alignItems="center" gap={1}>
                      <Avatar>
                        {profile?.username?.charAt(0)}
                      </Avatar>
                      {profile?.username}
                    </Box>
                  </TableCell>

                  <TableCell>{user?.phone_number}</TableCell>
                  <TableCell>{user?.driver_number}</TableCell>

                  <TableCell>
                    <Chip
                      label={msg.status}
                      color={
                        msg.status === "sent"
                          ? "success"
                          : "warning"
                      }
                      size="small"
                    />
                  </TableCell>


                 

                  <TableCell>{msg.body}</TableCell>
                </TableRow>
              );
            })}
          </TableBody>
        </Table>
      </DialogContent>

      <DialogActions>
        <Button onClick={onClose} variant="contained">
          Close
        </Button>
      </DialogActions>
    </Dialog>
  );
}