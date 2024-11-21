'use client'
import React from 'react'

import Image from 'next/image'

import { IconButton, Typography } from '@mui/material'


import 'react-medium-image-zoom/dist/styles.css'
import { DocumentScanner } from '@mui/icons-material'
import { FilePdf } from '@phosphor-icons/react'
import { Box } from '@mui/system'



interface MediaComponent {
  url: string
  file_name?:string
  width?:number,
  height?:number
  name:string
}

export default function MediaComponent({ url,width,height ,file_name,name}: MediaComponent) {

  const file = name?.split("/")

  switch (getFileExtension(url)) {
    case '.3gpp':
      return (
        <IconButton
          LinkComponent={'a'}
          href={`/dashboard/document-viewer/${file?.[1]}`}
          target='_blank'

        >
          <DocumentScanner/>
        </IconButton>
      )

    case '.jpeg ':
      return (
        <IconButton
          LinkComponent={'a'}
          href={`/dashboard/document-viewer/${file?.[1]}`}
          target='_blank'
          onClick={async () => {

          }}
        >
          <img  src={url} alt='' />
        </IconButton>
      )
      case '.jpg':
        return (
          <IconButton
            LinkComponent={'a'}
            href={`/dashboard/document-viewer/${file?.[1]}`}
            target='_blank'
            onClick={async () => {

            }}
          >
            <Image height={height || 60} src={url} alt='' width={181} style={{height:200,width:181,objectFit:"cover"}} objectFit='cover' />
          </IconButton>
        )
    case '.png':
      return (
        <IconButton
          LinkComponent={'a'}
           href={`/dashboard/document-viewer/${file?.[1]}`}
          target='_blank'

        >
          <img height={height || 60} src={url} alt='' />
        </IconButton>
      )
    case '.pdf':
      return (
        <IconButton
          LinkComponent={'a'}
          href={`/dashboard/document-viewer/${file?.[1]}`}
          target='_blank'

        >
          <Box display={"flex"} flexDirection={"column"} alignItems={"center"}>
          <FilePdf style={{color:"red"}} size={45}/>
          <Typography variant='subtitle2'>{file_name}</Typography>
          </Box>
        </IconButton>
      )

    case 'application/octet-stream':
      switch (getFileExtension(url)) {
        case '.jpeg':
          return (
            <IconButton
              LinkComponent={'a'}
              href={`/dashboard/document-viewer/${file?.[1]}`}
              target='_blank'

            >
              <img height={height || 60} src={url} alt='' />
            </IconButton>
          )
          case '.png':
            return (
              <IconButton
                LinkComponent={'a'}
                href={`/dashboard/document-viewer/${file?.[1]}`}
                target='_blank'

              >
                <img height={height || 60} src={url} alt='' />
              </IconButton>
            )
            case '.pdf':
            return (
              <IconButton
                LinkComponent={'a'}
                href={`/dashboard/document-viewer/${file?.[1]}`}
                target='_blank'

              >
                <FilePdf/>
              </IconButton>
            )


      }

    default:
      return <>not matched format</>
  }
}

function getFileExtension(url: string) {
  // Create a new URL object
  const parsedUrl = new URL(url)

  // Get the pathname from the URL
  const pathname = parsedUrl.pathname

  // Extract the file extension
  const extension = pathname.split('.').pop()

  // If the last part is not a dot, return it with a dot
  return extension !== pathname ? `.${extension}` : ''
}
