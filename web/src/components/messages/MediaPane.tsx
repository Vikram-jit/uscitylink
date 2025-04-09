'use client';

import React, { useEffect } from 'react';
import { useGetMediaQuery } from '@/redux/MessageApiSlice';
import { Divider } from '@mui/joy';
import { Box, CircularProgress, ImageList, ImageListItem, Pagination, Typography } from '@mui/material';
import ToggleButton from '@mui/material/ToggleButton';
import ToggleButtonGroup from '@mui/material/ToggleButtonGroup';
import MediaComponent from './MediaComment';

export default function MediaPane({ userId,channelId,source,private_chat_id, }: { userId?: string,channelId?:string,source?:string ,private_chat_id?:string}) {
  const [alignment, setAlignment] = React.useState('media');
  const [page,setPage] = React.useState<number>(1)
  const { data ,isLoading,isFetching} = useGetMediaQuery({ channelId: channelId, type: alignment, userId:userId,source:source,private_chat_id,page });

  const handleChange = (event: React.MouseEvent<HTMLElement>, newAlignment: string) => {
    setAlignment(newAlignment);
  };
  useEffect(()=>{

  },[isLoading])
  if(isLoading)
    return <CircularProgress/>
  return (
    <>
    <Box sx={{ display: 'flex', justifyItems: 'center', justifyContent: 'center' ,}}>

    <ToggleButtonGroup
        sx={{ marginTop: 2 }}
        color="primary"
        value={alignment}
        exclusive
        onChange={handleChange}
        aria-label="Platform"
      >
        <ToggleButton value="media">Media</ToggleButton>
        <ToggleButton value="doc">Docs</ToggleButton>
      </ToggleButtonGroup>
      <Divider sx={{ height: 1 }} />


    </Box>
    <Box paddingLeft={8} paddingRight={8} display={"flex"} height={"80vh"} overflow={"scroll"}>
    {/* {alignment == 'media' && ( */}
       <ImageList cols={4} gap={10} >
         {data && data?.data?.media?.length > 0 ? (

             data.data.media.map((item) => (
               <ImageListItem key={item.key} style={{border:"1px solid #d9d9d9"}}>
                 <MediaComponent height={100} thumbnail={`https://ciity-sms.s3.us-west-1.amazonaws.com/${item.thumbnail}`} url={`https://ciity-sms.s3.us-west-1.amazonaws.com/${item.key}`} name={item.key} file_name={item.file_name}/>
               </ImageListItem>
             ))

         ) : (
           <div>No media available</div> // Fallback when no data or media is available
         )}
       </ImageList>
     {/* )} */}
   
    </Box>
    <Pagination count={data?.data?.totalPages} page={page} sx={{alignSelf:"center"}} onChange={(page,v)=>{
      setPage(v)
    }}/>
    </>
  );
}
