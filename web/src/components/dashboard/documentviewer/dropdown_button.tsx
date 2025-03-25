import { useState } from 'react';
import { Button, Menu, MenuItem } from '@mui/material';
import LoaderDialog from '@/components/LoaderDialog';
import { useDispatch } from 'react-redux';
import { hideLoader, showLoader } from '@/redux/slices/loaderSlice';

export default function DropdownButton({ btnName, fileName }: { btnName: string; fileName: string }) {
    const [anchorEl, setAnchorEl] = useState(null);
   const dispatch = useDispatch()
  const open = Boolean(anchorEl);

  const downloadFile = async (url: string, filename: string, type: string) => {
    try {
        dispatch(showLoader())
      const response = await fetch(url, {
        method: 'GET',
        headers: {
          Authorization: `Bearer ${localStorage.getItem('custom-auth-token')}`,
        },
      });

      if (!response.ok) {
        dispatch(hideLoader())
        throw new Error('Network response was not ok');
      }

      const blob = await response.blob();
      const link = document.createElement('a');
      link.href = URL.createObjectURL(blob);
      link.setAttribute('download', `${filename?.split('.')?.[0]}.${type}`);
      document.body.appendChild(link);
      link.click();
      link.remove();
      dispatch(hideLoader())
      setAnchorEl(null)
    } catch (error) {
        dispatch(hideLoader())
      console.error('Download failed:', error);
    }
  };
  const handleClick = (event: any) => {
    setAnchorEl(event.currentTarget);
  };

  const handleClose = () => {
    setAnchorEl(null);
  };

  return (
    <div>
         <LoaderDialog/>
      <Button
        aria-controls={open ? 'dropdown-menu' : undefined}
        aria-haspopup="true"
        onClick={handleClick}
        variant="contained"
        color={'secondary'}
      >
        {btnName}
      </Button>
      <Menu
        id="dropdown-menu"
        anchorEl={anchorEl}
        open={open}
        onClose={handleClose}
        MenuListProps={{
          'aria-labelledby': 'dropdown-button',
        }}
      >
        <MenuItem
          onClick={() =>
            downloadFile(
              `${process.env.API_URL}media/convertAndDownload/${encodeURIComponent(fileName)}`,
              fileName,
              'jpg'
            )
          }
        >
          As JPG
        </MenuItem>
        <MenuItem
          onClick={() =>
            downloadFile(
              `${process.env.API_URL}media/convertAndDownloadPdf/${encodeURIComponent(fileName)}`,
              fileName,
              'pdf'
            )
          }
        >
          AS PDF
        </MenuItem>
      </Menu>
    </div>
  );
}
