"use client"
import React from 'react';
import { Typography } from '@mui/material';

interface LinkifyTextProps {
  text: string;
  onClick?:()=>void
}

const LinkifyText: React.FC<LinkifyTextProps> = ({ text,onClick }) => {
  const urlRegex = /(https?:\/\/[^\s]+)/g;

  const parts = text.split(urlRegex);

  return (
    <Typography sx={{ fontSize: 16, whiteSpace: 'pre-wrap' }} onClick={onClick}>
      {parts.map((part, index) =>
        urlRegex.test(part) ? (
          <a
            key={index}
            href={part}
            target="_blank"
            rel="noopener noreferrer"
            style={{ color: '#1976d2', wordBreak: 'break-word' }}
          >
            {part}
          </a>
        ) : (
          <React.Fragment key={index}>{part}</React.Fragment>
        )
      )}
    </Typography>
  );
};

export default LinkifyText;
