'use client';

import React, { useState } from 'react';
import Image from 'next/image';
import { DocumentScanner, Download, Upload } from '@mui/icons-material';
import { IconButton, Typography } from '@mui/material';
import { Box } from '@mui/system';
import { FilePdf, PlayCircle } from '@phosphor-icons/react';

import DocumentDialog from '../DocumentDialog';

interface MediaComponent {
  url: string;
  file_name?: string;
  width?: number;
  height?: number;
  thumbnail?: string;
  name: string;
  type?: string;
  messageDirection?: string;
}

export default function MediaComponent({
  url,
  width,
  height,
  file_name,
  name,
  thumbnail,
  type,
  messageDirection,
}: MediaComponent) {
  const [openDocument, setOpenDocument] = useState<boolean>(false);

  const file = name?.split('/');

  const videoExtensions = ['.mp4', '.mkv', '.avi', '.mov', '.flv', '.webm', '.mpeg', '.mpg', '.wmv'];

  switch (getFileExtension(url)) {
    case '.mp4':
    case '.mkv':
    case '.avi':
    case '.mov':
    case '.flv':
    case '.webm':
    case '.mpeg':
    case '.mpg':
    case '.wmv':
      return (
        <>
          <IconButton onClick={() => setOpenDocument(true)} style={{ position: 'relative' }}>
            <Image
              height={height || 60}
              src={thumbnail || ''}
              alt=""
              width={181}
              style={{ height: 200, width: 181, objectFit: 'contain' }}
              objectFit="contain"
            />
            <PlayCircle size={50} style={{ position: 'absolute', color: 'white' }} />
          </IconButton>
          {openDocument && <DocumentDialog open={openDocument} setOpen={setOpenDocument} documentKey={file?.[2]} />}
        </>
      );
    case '.mp3':
    case '.aac':
    case '.m4a':
    case '.wav':
    case '.ogg':
    case '.flac':
    case '.aiff':
    case '.amr':
    case '.ape':
      return (
        <>
          <audio controls>
            <source src={url}></source>
          </audio>
        </>
      );
    case '.3gpp':
      return (
        <>
          <IconButton onClick={() => setOpenDocument(true)}>
            <DocumentScanner />
          </IconButton>
          {openDocument && <DocumentDialog open={openDocument} setOpen={setOpenDocument} documentKey={file?.[1]} />}
        </>
      );

    case '.jpeg ':
      return (
        <>
          {type == 'not-upload' ? (
            <Box
              sx={{
                display: 'flex',
                flexDirection: 'column',
                justifyContent: 'center',
                alignItems: 'center',
              }}
            >
              <Download /> <Typography>receiving</Typography>
            </Box>
          ) : (
            <IconButton onClick={() => setOpenDocument(true)}>
              <img src={url} alt="" />
            </IconButton>
          )}

          {openDocument && <DocumentDialog open={openDocument} setOpen={setOpenDocument} documentKey={file?.[1]} />}
        </>
      );
    case '.jpg':
      return (
        <>
          {' '}
          {type == 'not-upload' ? (
            <Box
              sx={{
                display: 'flex',
                flexDirection: 'column',
                justifyContent: 'center',
                alignItems: 'center',
              }}
            >
              {messageDirection == 'S' ? (
                <>
                  {' '}
                  <Upload /> <Typography>sending...</Typography>
                </>
              ) : (
                <>
                  {' '}
                  <Download /> <Typography>receiving...</Typography>
                </>
              )}
            </Box>
          ) : (
            <IconButton onClick={() => setOpenDocument(true)}>
              <Image
                height={height || 60}
                src={url}
                alt=""
                width={181}
                style={{ height: 200, width: 181, objectFit: 'contain' }}
                objectFit="contain"
              />
            </IconButton>
          )}
          {openDocument && <DocumentDialog open={openDocument} setOpen={setOpenDocument} documentKey={file?.[1]} />}
        </>
      );
    case '.png':
      return (
        <>
          {type == 'not-upload' ? (
            <Box
              sx={{
                display: 'flex',
                flexDirection: 'column',
                justifyContent: 'center',
                alignItems: 'center',
              }}
            >
              {messageDirection == 'S' ? (
                <>
                  {' '}
                  <Upload /> <Typography>sending...</Typography>
                </>
              ) : (
                <>
                  {' '}
                  <Download /> <Typography>receiving...</Typography>
                </>
              )}
            </Box>
          ) : (
            <IconButton onClick={() => setOpenDocument(true)}>
              <img height={height || 60} src={url} alt="" style={{ objectFit: 'contain' }} />
            </IconButton>
          )}

          {openDocument && <DocumentDialog open={openDocument} setOpen={setOpenDocument} documentKey={file?.[1]} />}
        </>
      );
    case '.pdf':
      return (
        <>
          <IconButton
            // LinkComponent={'a'}
            // href={`/dashboard/document-viewer/${file?.[1]}`}
            // target='_blank'
            onClick={() => setOpenDocument(true)}
          >
            <Box display={'flex'} flexDirection={'column'} alignItems={'center'}>
              <FilePdf style={{ color: 'red' }} size={45} />
              <Typography variant="subtitle2">{file_name}</Typography>
            </Box>
          </IconButton>
          {openDocument && <DocumentDialog open={openDocument} setOpen={setOpenDocument} documentKey={file?.[1]} />}
        </>
      );

    case 'application/octet-stream':
      switch (getFileExtension(url)) {
        case '.jpeg':
          return (
            <>
              {type == 'not-upload' ? (
                <Box
                  sx={{
                    display: 'flex',
                    flexDirection: 'column',
                    justifyContent: 'center',
                    alignItems: 'center',
                  }}
                >
                  {messageDirection == 'S' ? (
                <>
                  {' '}
                  <Upload /> <Typography>sending...</Typography>
                </>
              ) : (
                <>
                  {' '}
                  <Download /> <Typography>receiving...</Typography>
                </>
              )}
                </Box>
              ) : (
                <IconButton onClick={() => setOpenDocument(true)}>
                  <img height={height || 60} src={url} alt="" style={{ objectFit: 'contain' }} />
                </IconButton>
              )}

              {openDocument && <DocumentDialog open={openDocument} setOpen={setOpenDocument} documentKey={file?.[1]} />}
            </>
          );
        case '.png':
          return (
            <>
              {type == 'not-upload' ? (
                <Box
                  sx={{
                    display: 'flex',
                    flexDirection: 'column',
                    justifyContent: 'center',
                    alignItems: 'center',
                  }}
                >
                  {messageDirection == 'S' ? (
                <>
                  {' '}
                  <Upload /> <Typography>sending...</Typography>
                </>
              ) : (
                <>
                  {' '}
                  <Download /> <Typography>receiving...</Typography>
                </>
              )}
                </Box>
              ) : (
                <IconButton onClick={() => setOpenDocument(true)}>
                  <img height={height || 60} src={url} alt="" style={{ objectFit: 'contain' }} />
                </IconButton>
              )}

              {openDocument && <DocumentDialog open={openDocument} setOpen={setOpenDocument} documentKey={file?.[1]} />}
            </>
          );
        case '.pdf':
          return (
            <>
              <IconButton onClick={() => setOpenDocument(true)}>
                <FilePdf />
              </IconButton>
              {openDocument && <DocumentDialog open={openDocument} setOpen={setOpenDocument} documentKey={file?.[1]} />}
            </>
          );
      }

    default:
      return <>not matched format</>;
  }
}

function getFileExtension(url: string) {
  // Create a new URL object
  const parsedUrl = new URL(url);

  // Get the pathname from the URL
  const pathname = parsedUrl.pathname;

  // Extract the file extension
  const extension = pathname.split('.').pop();

  // If the last part is not a dot, return it with a dot
  return extension !== pathname ? `.${extension}` : '';
}
