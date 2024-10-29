"use client"

import { Box } from '@mui/material'
import React from 'react'
import MyMessage from './MyMessage'

export default function ChatUi() {
  return (
    <Box component="main" className="MainContent" >
    <MyMessage />
  </Box>
  )
}
