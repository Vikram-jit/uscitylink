'use client';

import React from 'react';
import { useGetMediaQuery } from '@/redux/MessageApiSlice';
import { Divider } from '@mui/joy';
import { Box, ImageList, ImageListItem, Typography } from '@mui/material';
import ToggleButton from '@mui/material/ToggleButton';
import ToggleButtonGroup from '@mui/material/ToggleButtonGroup';
import MediaComponent from './MediaComment';

export default function MediaPane({ userId }: { userId: string }) {
  const [alignment, setAlignment] = React.useState('media');

  const { data } = useGetMediaQuery({ channelId: '', type: alignment, userId });

  const handleChange = (event: React.MouseEvent<HTMLElement>, newAlignment: string) => {
    setAlignment(newAlignment);
  };

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
    <Box paddingLeft={8} paddingRight={8} display={"flex"}>
    {/* {alignment == 'media' && ( */}
       <ImageList cols={3}  >
         {data && data?.data?.media?.length > 0 ? (

             data.data.media.map((item) => (
               <ImageListItem key={item.key} style={{border:"1px solid #d9d9d9"}}>
                 <MediaComponent url={`https://ciity-sms.s3.us-west-1.amazonaws.com/${item.key}`} name={item.key} file_name={item.file_name}/>
               </ImageListItem>
             ))

         ) : (
           <div>No media available</div> // Fallback when no data or media is available
         )}
       </ImageList>
     {/* )} */}
    </Box>
    </>
  );
}
