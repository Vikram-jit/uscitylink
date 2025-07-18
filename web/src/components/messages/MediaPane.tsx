'use client';

import React, { useEffect } from 'react';
import { useGetMediaQuery } from '@/redux/MessageApiSlice';
import { Divider } from '@mui/joy';
import { Box, CircularProgress, ImageList, ImageListItem, Pagination, Typography } from '@mui/material';
import ToggleButton from '@mui/material/ToggleButton';
import ToggleButtonGroup from '@mui/material/ToggleButtonGroup';
import MediaComponent from './MediaComment';
import DocumentDialog from '../DocumentDialog';

export default function MediaPane({ userId,channelId,source,private_chat_id, }: { userId?: string,channelId?:string,source?:string ,private_chat_id?:string}) {
  const [alignment, setAlignment] = React.useState('media');
  const [page,setPage] = React.useState<number>(1)
  const { data ,isLoading,isFetching} = useGetMediaQuery({ channelId: channelId, type: alignment, userId:userId,source:source,private_chat_id,page });
  const [currentIndex, setCurrentIndex] = React.useState<number | null>(null);

  const handleChange = (event: React.MouseEvent<HTMLElement>, newAlignment: string) => {
    setAlignment(newAlignment);
  };
  useEffect(()=>{

  },[isLoading])



   const moveNext = () => {
    if(currentIndex != null){
    // 1. If we’re already at the last possible index, nothing to do
    if (currentIndex >= (data?.data?.media?.length || 0) - 1) {
      console.log('No more messages with media.');
      return;
    }
  
    // 2. Scan forward for the next message that has a non‐empty URL
    for (let i = currentIndex + 1; i < (data?.data?.media?.length || 0); i++) {
      const url = data?.data?.media?.[i]?.key?.trim();
      if (url) {
        setCurrentIndex(i);
        console.log('Moved to:', data?.data?.media?.[i]);
        return;
      }
    }
  
    console.log('No more messages with media.');
  }
  };
  
  
  // Move to the previous message with a URL
  const movePrevious = () => {
    if(currentIndex){
    // If we're already at 0, nothing to do
    if (currentIndex <= 0) {
      console.log('Reached the beginning. No previous messages with media.');
      return;
    }
  
    // Walk backwards until we find a message.url
    for (let i = currentIndex - 1; i >= 0; i--) {
      if (data?.data?.media?.[i].key?.trim()) {
        setCurrentIndex(i);
        console.log('Moved to:', data?.data?.media?.[i]);
        return;
      }
    }
  
    console.log('Reached the beginning. No previous messages with media.');
  };
}


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
                 <MediaComponent onClick={()=>{
                  setCurrentIndex(data.data.media.indexOf(item))
                 }} height={100} thumbnail={item.upload_type == 'local' ? `${process.env.SOCKET_URL}/${item.key}` : `https://ciity-sms.s3.us-west-1.amazonaws.com/${item.thumbnail}`} url={item.upload_type == 'local' ? `${process.env.SOCKET_URL}/${item.key}` : `https://ciity-sms.s3.us-west-1.amazonaws.com/${item.key}`} name={item.key} file_name={item.file_name}/>
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

    {currentIndex != null && <DocumentDialog open={currentIndex  != null? true :false} onClose={
           ()=>{
            setCurrentIndex(null)
           }
          } uploadType={data?.data?.media?.[currentIndex]?.upload_type} documentKey={data?.data.media?.[currentIndex]?.key?.split('/')?.[1] == "video"? data?.data.media?.[currentIndex]?.key?.split('/')?.[2] : data?.data.media?.[currentIndex]?.key?.split('/')?.[1] || ''} moveNext={moveNext} movePrev={movePrevious} currentIndex={currentIndex}/> }
    </>
  );
}
