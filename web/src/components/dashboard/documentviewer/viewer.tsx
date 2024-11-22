'use client';

import React, { useRef, useState } from 'react';
import { Download } from '@mui/icons-material';
import { Box, Button, Grid, IconButton, Paper, Typography } from '@mui/material';
import { Document, Page, pdfjs } from 'react-pdf';

import 'react-pdf/dist/Page/AnnotationLayer.css';

import Image from 'next/image';
import { useParams } from 'next/navigation';

// Set PDF.js worker source
pdfjs.GlobalWorkerOptions.workerSrc = `https://unpkg.com/pdfjs-dist@${pdfjs.version}/legacy/build/pdf.worker.min.mjs`;

const options = {
  cMapUrl: `https://unpkg.com/pdfjs-dist@${pdfjs.version}/cmaps/`,
};

export default function Viewer() {
  const [numPages, setNumPages] = useState<number>(0);
  const [pageNumber, setPageNumber] = useState<number>(1);
  const [pdfWidth, setPdfWidth] = useState<number>(600);

  const { key }: { key: string } = useParams();

  // Handle document load success
  function onDocumentLoadSuccess({ numPages }: { numPages: number }): void {
    setNumPages(numPages);
  }

  // Handle window resizing for responsive layout
  const handleResize = () => {
    if (window.innerWidth < 600) {
      setPdfWidth(window.innerWidth - 40); // adjust width for mobile
    } else {
      setPdfWidth(600); // reset to a default width for larger screens
    }
  };

  // Adjust the layout when the window size changes
  React.useEffect(() => {
    window.addEventListener('resize', handleResize);
    handleResize();
    return () => {
      window.removeEventListener('resize', handleResize);
    };
  }, []);

  // Handle downloading the PDF
  const handleDownload = () => {
    const link = document.createElement('a');
    link.href = `https://ciity-sms.s3.us-west-1.amazonaws.com/uscitylink/${key}`;
    link.download = 'MANISH-K-VERMA-30414869.pdf';
    link.click();
  };
  const pdfRef = useRef<any>(null);
  // Handle printing the PDF
  const handlePrint = () => {
    // Create an iframe to load the entire document for printing
    const iframe = document.createElement('iframe');
    iframe.style.position = 'absolute';
    iframe.style.top = '-9999px'; // Hide iframe offscreen
    document.body.appendChild(iframe);

    const iframeWindow = iframe.contentWindow || iframe.contentDocument?.defaultView;
    if (iframeWindow) {
      const doc = iframeWindow.document;
      doc.open();
      doc.write('<html><head><title>Print PDF</title></head><body>');
      doc.write(
        '<embed width="100%" height="100%" src=`https://ciity-sms.s3.us-west-1.amazonaws.com/uscitylink/${key}` type="application/pdf">'
      );
      doc.write('</body></html>');
      doc.close();
      iframeWindow.print(); // Trigger print
    }
  };
  if (key.split('.')?.[key.split('.').length - 1] != 'pdf') {
    return (
      <Box
        sx={{
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          width: '100%',
          padding: 3,
          background: '#dedede',
        }}
      >
        <Paper sx={{ width: '100%', padding: 3, boxShadow: 3 }}>
          <Box sx={{ display: 'flex', justifyContent: 'center', marginBottom: 2 }}>
            <Image
              src={`https://ciity-sms.s3.us-west-1.amazonaws.com/uscitylink/${key}`}
              alt=""
              width={500}
              height={500}
              objectFit="cover"
            />
          </Box>
        </Paper>
      </Box>
    );
  }

  return (
    <Box
      sx={{
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        width: '100%',
        padding: 3,
        background: '#dedede',
      }}
    >
      <Paper sx={{ width: '100%', padding: 3, boxShadow: 3 }}>
        <Grid container spacing={2} justifyContent="center" alignItems="center">
          <Grid item>
            <Button
              variant="contained"
              color="primary"
              disabled={pageNumber <= 1}
              onClick={() => setPageNumber(pageNumber - 1)}
            >
              &lt; Previous
            </Button>
          </Grid>
          <Grid item>
            <Typography variant="body1">
              Page {pageNumber} of {numPages}
            </Typography>
          </Grid>
          <Grid item>
            <Button
              variant="contained"
              color="primary"
              disabled={pageNumber >= numPages}
              onClick={() => setPageNumber(pageNumber + 1)}
            >
              Next &gt;
            </Button>
          </Grid>
          <Grid item>
            <IconButton
              color="primary"
              onClick={handleDownload}
              sx={{
                backgroundColor: '#1976d2',
                color: '#fff',
                padding: 1.5,
                '&:hover': { backgroundColor: '#1565c0' },
              }}
            >
              <Download />
            </IconButton>
          </Grid>
        </Grid>

        {/* PDF Document Rendering */}
        <Box sx={{ display: 'flex', justifyContent: 'center', marginBottom: 2 }}>
          <Document
            ref={pdfRef}
            options={options}
            file={`https://ciity-sms.s3.us-west-1.amazonaws.com/uscitylink/${key}`}
            onLoadSuccess={onDocumentLoadSuccess}
          >
            <Page pageNumber={pageNumber} width={pdfWidth} renderTextLayer={false} scale={2} />
          </Document>
        </Box>
      </Paper>
    </Box>
  );
}
