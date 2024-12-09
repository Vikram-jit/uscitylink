'use client';

import * as React from 'react';

import { Delete, Edit } from '@mui/icons-material';
import { IconButton, TablePagination, Tooltip } from '@mui/material';
import Box from '@mui/material/Box';
import Card from '@mui/material/Card';
import Divider from '@mui/material/Divider';
import Stack from '@mui/material/Stack';
import Table from '@mui/material/Table';
import TableBody from '@mui/material/TableBody';
import TableCell from '@mui/material/TableCell';
import TableHead from '@mui/material/TableHead';
import TableRow from '@mui/material/TableRow';
import Typography from '@mui/material/Typography';
import { Circle } from '@phosphor-icons/react';
import { pagination } from '@/redux/models/ChannelModel';
import DeleteConfirmationDialog from '@/components/DeleteConfirmationDialog';
import { useDeleteTemplateMutation } from '@/redux/TemplateApiSlice';
import MediaComponent from '@/components/messages/MediaComment';

interface TemplateTable {
  count?: number;
  page?: number;
  rows?: {id:string,name:string,body:string,url?:string}[];
  setPage:React.Dispatch<React.SetStateAction<number>>
  pagination:pagination|undefined
}

export function TemplateTable({ count = 0, rows = [], page = 0,setPage,pagination }: TemplateTable): React.JSX.Element {

  const [dialogOpen, setDialogOpen] = React.useState<boolean>(false);
  const [currentItem, setCurrentItem] = React.useState<string>("");
  const [deleteTemplate,{isLoading}] = useDeleteTemplateMutation()
  return (
    <Card>
      <Box sx={{ overflowX: 'auto' }}>
        <Table sx={{ minWidth: '800px' }}>
          <TableHead>
            <TableRow>
              <TableCell>Title</TableCell>
              <TableCell>Body</TableCell>
              <TableCell>Attachment</TableCell>
              <TableCell>Action</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {rows.map((row) => {
              return (
                <TableRow hover key={row.id}>
                  <TableCell>
                    <Stack sx={{ alignItems: 'center' }} direction="row" spacing={2}>

                      <Typography variant="subtitle2">{row.name}</Typography>
                    </Stack>
                  </TableCell>
                  <TableCell>{row.body}</TableCell>
                  <TableCell>{row?.url ?
              <Box >

              <MediaComponent url={`https://ciity-sms.s3.us-west-1.amazonaws.com/${row.url}`} name={row?.url ??''} width={100} height={100}/>
              </Box> : '-'
              }</TableCell>

                  <TableCell>
                    <Tooltip title="Edit">
                      <IconButton LinkComponent={"a"} href={`/dashboard/templates/edit?id=${row.id}`}>
                        <Edit />
                      </IconButton>

                    </Tooltip>
                    <Tooltip title="Delete">
                      <IconButton onClick={()=>{
                        setCurrentItem(row.id)
                        setDialogOpen(true)
                      }}>
                        <Delete />
                      </IconButton>

                    </Tooltip>
                  </TableCell>

                </TableRow>
              );
            })}
          </TableBody>
        </Table>
      </Box>
      <Divider />
      {pagination &&  <TablePagination
        component="div"
        count={pagination.total}
        onPageChange={(e,page)=>{
          setPage(page+1)
        }}

        page={page-1}
        rowsPerPage={pagination.pageSize}

      />}
      {
        dialogOpen && <DeleteConfirmationDialog  onClose={()=>{
          setDialogOpen(false)
          setCurrentItem("")
        }} onConfirm={async()=>{
          await deleteTemplate({id:currentItem})
          setDialogOpen(false)
          setCurrentItem("")
        }} open={dialogOpen}/>
      }
    </Card>
  );
}
