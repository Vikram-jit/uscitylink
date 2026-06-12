'use client';

import React, { useState } from 'react';
import Image from 'next/image';
import { DocumentScanner, Download, Upload } from '@mui/icons-material';
import { IconButton, Typography } from '@mui/material';
import { Box } from '@mui/system';
import { FilePdf, PlayCircle } from '@phosphor-icons/react';

import DocumentDialog from '../DocumentDialog';
import moment from 'moment';

interface MediaComponent {
  url: string;
  file_name?: string;
  width?: number;
  height?: number;
  thumbnail?: string;
  name: string;
  type?: string;
  messageDirection?: string;
  dateTime?: Date;
  onClick?: () => void;
  createAt?: string | Date
}

// ── UTC timestamp pill overlay ──────────────────────────────
function TimestampBadge({ dateTime }: { dateTime?: string | Date }) {

  return (
    <Box
      sx={{
       position: "absolute",
    bottom: "8px",
    right: "25px",
    width: "75%",
        bgcolor: 'rgba(0,0,0,0.55)',
        // borderRadius: '12px',
        px: '7px',
        py: '3px',
        pointerEvents: 'none',
        zIndex: 1,
      }}
    >
      <Typography
        sx={{
          fontSize: 10,
          color: '#fff',
          lineHeight: 1.3,
          whiteSpace: 'nowrap',
          fontWeight: 400,
          letterSpacing: 0.2,
        }}
      >
        {moment(dateTime).format('MM/DD/YYYY h:mm A')}
      </Typography>
    </Box>
  );
}

export default function MediaComponent({
  url,
  height,
  file_name,
  name,
  thumbnail,
  type,
  messageDirection,
  dateTime,
  onClick,
  createAt
}: MediaComponent) {
  const [openDocument, setOpenDocument] = useState<boolean>(false);

  const file = name?.split('/');

  switch (getFileExtension(url)) {
    // ── Video ────────────────────────────────────────────────
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
          <Box sx={{ position: 'relative', display: 'inline-flex' }}>
            <IconButton onClick={() => setOpenDocument(true)} style={{ position: 'relative' }}>
              <Image
                unoptimized={true}
                height={height || 60}
                src={thumbnail || ''}
                alt=""
                width={181}
                style={{ height: height || 200, width: 181, objectFit: 'contain' }}
                objectFit="contain"
              />
              <PlayCircle size={50} style={{ position: 'absolute', color: 'white' }} />
            </IconButton>
            <TimestampBadge dateTime={createAt} />
          </Box>
          {openDocument && (
            <DocumentDialog datetime={createAt ?? ''} open={openDocument} setOpen={setOpenDocument} documentKey={file?.[2]} />
          )}
        </>
      );

    // ── Audio ────────────────────────────────────────────────
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
        <audio controls>
          <source src={url} />
        </audio>
      );

    case '.3gpp':
      return (
        <>
          <IconButton>
            <DocumentScanner />
          </IconButton>
          {openDocument && (
            <DocumentDialog datetime={createAt ?? ''} open={openDocument} setOpen={setOpenDocument} documentKey={file?.[1]} />
          )}
        </>
      );

    // ── JPEG (trailing-space variant) ────────────────────────
    case '.jpeg ':
      return (
        <>
          {type === 'not-upload' ? (
            <Box sx={{ display: 'flex', flexDirection: 'column', justifyContent: 'center', alignItems: 'center' }}>
              <Download />
              <Typography>receiving</Typography>
            </Box>
          ) : (
            <Box sx={{ position: 'relative', display: 'inline-flex' }}>
              <IconButton onClick={onClick}>
                <img src={url} alt="" />
              </IconButton>
              <TimestampBadge dateTime={createAt} />
            </Box>
          )}
        </>
      );

    // ── JPG ─────────────────────────────────────────────────
    case '.jpg':
      return (
        <>
          {type === 'not-upload' ? (
            <Box sx={{ display: 'flex', flexDirection: 'column', justifyContent: 'center', alignItems: 'center' }}>
              {messageDirection === 'S' ? (
                <>
                  <Upload />
                  <Typography>sending...</Typography>
                </>
              ) : (
                <>
                  <Download />
                  <Typography>receiving...</Typography>
                </>
              )}
            </Box>
          ) : (
            <Box sx={{ position: 'relative', display: 'inline-flex' }}>
              <IconButton onClick={onClick}>
                <Image
                  height={height || 60}
                  src={url}
                  alt=""
                  width={181}
                  style={{ height: height || 200, width: 181, objectFit: 'contain' }}
                  objectFit="contain"
                />
              </IconButton>
              <TimestampBadge dateTime={createAt} />
            </Box>
          )}
        </>
      );

    // ── PNG ─────────────────────────────────────────────────
    case '.png':
      return (
        <>
          {type === 'not-upload' ? (
            <Box sx={{ display: 'flex', flexDirection: 'column', justifyContent: 'center', alignItems: 'center' }}>
              {messageDirection === 'S' ? (
                <>
                  <Upload />
                  <Typography>sending...</Typography>
                </>
              ) : (
                <>
                  <Download />
                  <Typography>receiving...</Typography>
                </>
              )}
            </Box>
          ) : (
            <Box sx={{ position: 'relative', display: 'inline-flex' }}>
              <IconButton onClick={onClick}>
                <Image
                  unoptimized={true}
                  height={height || 60}
                  src={url}
                  alt=""
                  width={181}
                  style={{ height: height || 200, width: 181, objectFit: 'contain' }}
                  objectFit="contain"
                />
              </IconButton>
              <TimestampBadge dateTime={createAt} />
            </Box>
          )}
        </>
      );

    // ── PDF ─────────────────────────────────────────────────
    case '.pdf':
      return (
        <>
          <Box sx={{ position: 'relative', display: 'inline-flex' }}>
            <IconButton onClick={onClick}>
              <Box display="flex" flexDirection="column" alignItems="center">
                <FilePdf style={{ color: 'red' }} size={45} />
                <Typography variant="subtitle2">{file_name}</Typography>
              </Box>
            </IconButton>
            <TimestampBadge dateTime={createAt} />
          </Box>
          {openDocument && (
            <DocumentDialog datetime={createAt ?? ''} open={openDocument} setOpen={setOpenDocument} documentKey={file?.[1]} />
          )}
        </>
      );

    // ── application/octet-stream ─────────────────────────────
    case 'application/octet-stream':
      switch (getFileExtension(url)) {
        case '.jpeg':
          return (
            <>
              {type === 'not-upload' ? (
                <Box sx={{ display: 'flex', flexDirection: 'column', justifyContent: 'center', alignItems: 'center' }}>
                  {messageDirection === 'S' ? (
                    <>
                      <Upload />
                      <Typography>sending...</Typography>
                    </>
                  ) : (
                    <>
                      <Download />
                      <Typography>receiving...</Typography>
                    </>
                  )}
                </Box>
              ) : (
                <Box sx={{ position: 'relative', display: 'inline-flex' }}>
                  <IconButton onClick={onClick}>
                    <Image
                      unoptimized={true}
                      height={height || 60}
                      src={url}
                      alt=""
                      width={181}
                      style={{ height: height || 200, width: 181, objectFit: 'contain' }}
                      objectFit="contain"
                    />
                  </IconButton>
                  <TimestampBadge dateTime={createAt} />
                </Box>
              )}
            </>
          );

        case '.png':
          return (
            <>
              {type === 'not-upload' ? (
                <Box sx={{ display: 'flex', flexDirection: 'column', justifyContent: 'center', alignItems: 'center' }}>
                  {messageDirection === 'S' ? (
                    <>
                      <Upload />
                      <Typography>sending...</Typography>
                    </>
                  ) : (
                    <>
                      <Download />
                      <Typography>receiving...</Typography>
                    </>
                  )}
                </Box>
              ) : (
                <Box sx={{ position: 'relative', display: 'inline-flex' }}>
                  <IconButton onClick={onClick}>
                    <Image
                      unoptimized={true}
                      height={height || 60}
                      src={url}
                      alt=""
                      width={181}
                      style={{ height: height || 200, width: 181, objectFit: 'contain' }}
                      objectFit="contain"
                    />
                  </IconButton>
                  <TimestampBadge dateTime={createAt} />
                </Box>
              )}
            </>
          );

        case '.pdf':
          return (
            <>
              <IconButton onClick={() => setOpenDocument(true)}>
                <FilePdf />
              </IconButton>
              {openDocument && (
                <DocumentDialog datetime={createAt ?? ''} open={openDocument} setOpen={setOpenDocument} documentKey={file?.[1]} />
              )}
            </>
          );
      }
    // falls through to default if octet-stream sub-extension not matched

    default:
      return <>{url}</>;
  }
}

function getFileExtension(url: string) {
  const parsedUrl = new URL(url);
  const pathname = parsedUrl.pathname;
  const extension = pathname.split('.').pop();
  return extension !== pathname ? `.${extension}` : '';
}
