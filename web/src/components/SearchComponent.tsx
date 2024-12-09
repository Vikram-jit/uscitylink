"use client"
import useDebounce from '@/hooks/useDebounce'
import { setSearch } from '@/redux/slices/searchSlice'
import { Search } from '@mui/icons-material'
import { InputAdornment, TextField } from '@mui/material'
import React from 'react'
import { useDispatch } from 'react-redux'


export default function SearchComponent() {
  const dispatch = useDispatch()

  return (
    <TextField
    onChange={(e)=>{
      dispatch(setSearch(e.target.value))
    }}
    sx={{ marginRight: 1 }}
    size="small"
    placeholder='search'
    InputProps={{
      startAdornment: (
        <InputAdornment position="start">
          <Search />
        </InputAdornment>
      ),
    }}
  />
  )
}
