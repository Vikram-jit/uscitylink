'use client';

import React, { useEffect } from 'react';
import { useGetMediaQuery } from '@/redux/MessageApiSlice';
import { CalendarMonth, CalendarToday, Close, DateRange, FilterAlt } from '@mui/icons-material';
import {
  Box,
  Button,
  Chip,
  CircularProgress,
  Fade,
  Pagination,
  Paper,
  Stack,
  ToggleButton,
  ToggleButtonGroup,
  Tooltip,
  Typography,
} from '@mui/material';
import { LocalizationProvider } from '@mui/x-date-pickers/LocalizationProvider';
import { AdapterDayjs } from '@mui/x-date-pickers/AdapterDayjs';
import { DatePicker } from '@mui/x-date-pickers/DatePicker';
import dayjs, { Dayjs } from 'dayjs';
import utc from 'dayjs/plugin/utc';

import DocumentDialog from '../DocumentDialog';
import MediaComponent from './MediaComment';

dayjs.extend(utc);

// ── Types ─────────────────────────────────────────────────────
type FilterMode = 'single' | 'range' | null;

// ── Shared picker sx ─────────────────────────────────────────
const pickerSx = {
  '& .MuiInputBase-root': {
    height: 36,
    fontSize: 13,
    borderRadius: '8px',
    bgcolor: '#F8F9FB',
  },
  '& .MuiOutlinedInput-notchedOutline': { borderColor: '#E0E4EC' },
};

// ─────────────────────────────────────────────────────────────

export default function MediaPane({
  userId,
  channelId,
  source,
  private_chat_id,
}: {
  userId?: string;
  channelId?: string;
  source?: string;
  private_chat_id?: string;
}) {
  const [mediaType, setMediaType] = React.useState<string>('media');
  const [page, setPage] = React.useState<number>(1);
  const [filterMode, setFilterMode] = React.useState<FilterMode>(null);
  const [startDate, setStartDate] = React.useState<Dayjs | null>(null);
  const [endDate, setEndDate] = React.useState<Dayjs | null>(null);
  const [currentIndex, setCurrentIndex] = React.useState<number | null>(null);

  // derived filter strings sent to API
  const startStr = startDate?.format('YYYY-MM-DD');
  const endStr =
    filterMode === 'single'
      ? startStr
      : endDate?.format('YYYY-MM-DD') ?? undefined;

  const { data, isLoading, isFetching } = useGetMediaQuery({
    channelId,
    type: mediaType,
    userId,
    source,
    private_chat_id,
    page,
    startDate: startStr,
    endDate: endStr,
  });

  // reset page when filter changes
  useEffect(() => { setPage(1); }, [startDate, endDate, filterMode, mediaType]);

  // ── Navigation ────────────────────────────────────────────
  const total = data?.data?.media?.length ?? 0;

  const moveNext = () => {
    if (currentIndex == null) return;
    for (let i = currentIndex + 1; i < total; i++) {
      if (data?.data?.media?.[i]?.key?.trim()) { setCurrentIndex(i); return; }
    }
  };

  const movePrevious = () => {
    if (currentIndex == null || currentIndex <= 0) return;
    for (let i = currentIndex - 1; i >= 0; i--) {
      if (data?.data?.media?.[i]?.key?.trim()) { setCurrentIndex(i); return; }
    }
  };

  // ── Filter helpers ────────────────────────────────────────
  const hasFilter = startDate != null;

  const clearFilter = () => {
    setStartDate(null);
    setEndDate(null);
    setFilterMode(null);
    setPage(1);
  };

  const chipLabel = React.useMemo(() => {
    if (!startDate) return null;
    const fmt = (d: Dayjs) => d.format('MMM DD, YYYY');
    if (filterMode === 'single') return fmt(startDate);
    if (endDate) return `${fmt(startDate)}  –  ${fmt(endDate)}`;
    return fmt(startDate);
  }, [startDate, endDate, filterMode]);

  // ── Render ────────────────────────────────────────────────
  return (
    <LocalizationProvider dateAdapter={AdapterDayjs}>
      <Box sx={{ display: 'flex', flexDirection: 'column', flex: 1, minHeight: 0, overflow: 'hidden' }}>

        {/* ── Top bar ─────────────────────────────────────── */}
        <Paper
          elevation={0}
          sx={{
            borderBottom: '1px solid #E8ECF4',
            px: 2,
            py: 1.25,
            bgcolor: '#FAFBFD',
            flexShrink: 0,
          }}
        >
          {/* Row 1: type toggle + filter buttons */}
          <Stack direction="row" alignItems="center" spacing={1.5} flexWrap="wrap" gap={1}>
            {/* Media / Docs toggle */}
            {/* <ToggleButtonGroup
              size="small"
              color="primary"
              value={mediaType}
              exclusive
              onChange={(_, v) => { if (v) { setMediaType(v); setPage(1); } }}
              sx={{ '& .MuiToggleButton-root': { px: 2, py: 0.5, fontSize: 12, fontWeight: 600, borderRadius: '8px !important', border: '1px solid #E0E4EC !important' } }}
            >
              <ToggleButton value="media">Media</ToggleButton>
              <ToggleButton value="doc">Docs</ToggleButton>
            </ToggleButtonGroup> */}

            {/* <Box sx={{ width: 1, height: 24, bgcolor: '#E8ECF4', mx: 0.5 }} /> */}

            {/* Filter label */}
            <Stack direction="row" alignItems="center" spacing={0.5}>
              <FilterAlt sx={{ fontSize: 14, color: 'text.secondary' }} />
              <Typography variant="caption" sx={{ fontWeight: 600, color: 'text.secondary', letterSpacing: 0.8, textTransform: 'uppercase' }}>
                Filter by Date
              </Typography>
            </Stack>

            {/* Single Day */}
            <Tooltip title="Pick a single date">
              <Button
                size="small"
                variant={filterMode === 'single' ? 'contained' : 'outlined'}
                startIcon={<CalendarToday sx={{ fontSize: '14px !important' }} />}
                onClick={() => {
                  setFilterMode('single');
                  setEndDate(null);
                }}
                sx={{
                  borderRadius: '8px',
                  fontSize: 12,
                  fontWeight: 600,
                  px: 1.5,
                  py: 0.5,
                  textTransform: 'none',
                  borderColor: '#E0E4EC',
                }}
              >
                Single Day
              </Button>
            </Tooltip>

            {/* Date Range */}
            <Tooltip title="Pick a date range">
              <Button
                size="small"
                variant={filterMode === 'range' ? 'contained' : 'outlined'}
                startIcon={<DateRange sx={{ fontSize: '14px !important' }} />}
                onClick={() => setFilterMode('range')}
                sx={{
                  borderRadius: '8px',
                  fontSize: 12,
                  fontWeight: 600,
                  px: 1.5,
                  py: 0.5,
                  textTransform: 'none',
                  borderColor: '#E0E4EC',
                }}
              >
                Date Range
              </Button>
            </Tooltip>

            {/* Active filter chip */}
            <Fade in={hasFilter}>
              <Box>
                {chipLabel && (
                  <Chip
                    size="small"
                    icon={<CalendarMonth sx={{ fontSize: '14px !important' }} />}
                    label={chipLabel}
                    onDelete={clearFilter}
                    deleteIcon={<Close sx={{ fontSize: '13px !important' }} />}
                    sx={{
                      bgcolor: '#EEF3FF',
                      color: '#3B6BEF',
                      fontWeight: 600,
                      fontSize: 11,
                      '& .MuiChip-icon': { color: '#3B6BEF' },
                      '& .MuiChip-deleteIcon': { color: '#3B6BEF' },
                      border: '1px solid #C5D5FB',
                    }}
                  />
                )}
              </Box>
            </Fade>

            {/* Clear button */}
            {hasFilter && (
              <Button
                size="small"
                color="error"
                variant="text"
                onClick={clearFilter}
                sx={{ fontSize: 12, textTransform: 'none', minWidth: 0, px: 1 }}
              >
                Clear
              </Button>
            )}

            {/* Loading indicator */}
            {isFetching && <CircularProgress size={16} thickness={4} />}
          </Stack>

          {/* Row 2: date pickers (only shown when a mode is active) */}
          <Fade in={filterMode != null} unmountOnExit>
            <Stack direction="row" alignItems="center" spacing={1.5} mt={1.25}>
              <DatePicker
                label={filterMode === 'range' ? 'Start Date' : 'Date'}
                value={startDate}
                onChange={(v) => { setStartDate(v); setPage(1); }}
                maxDate={dayjs()}
                slotProps={{
                  textField: { size: 'small', sx: pickerSx, placeholder: 'MM/DD/YYYY' },
                }}
              />

              {filterMode === 'range' && (
                <>
                  <Typography variant="body2" color="text.secondary">→</Typography>
                  <DatePicker
                    label="End Date"
                    value={endDate}
                    onChange={(v) => { setEndDate(v); setPage(1); }}
                    minDate={startDate ?? undefined}
                    maxDate={dayjs()}
                    disabled={!startDate}
                    slotProps={{
                      textField: { size: 'small', sx: pickerSx, placeholder: 'MM/DD/YYYY' },
                    }}
                  />
                </>
              )}
            </Stack>
          </Fade>
        </Paper>

        {/* ── Media grid ──────────────────────────────────── */}
        <Box sx={{ flex: 1, minHeight: 0, overflowY: 'auto', p: 2 }}>
          {isLoading ? (
            <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: 200 }}>
              <CircularProgress />
            </Box>
          ) : data?.data?.media?.length ? (
            <Box
              sx={{
                display: 'grid',
                gridTemplateColumns: 'repeat(auto-fill, minmax(150px, 1fr))',
                gap: 1.5,
              }}
            >
              {data.data.media.map((item, index) => {
                const url =
                  item.upload_type === 'local'
                    ? `${process.env.SOCKET_URL}/${item.key}`
                    : `https://ciity-sms.s3.us-west-1.amazonaws.com/${item.key}`;
                const thumb =
                  item.upload_type === 'local'
                    ? `${process.env.SOCKET_URL}/${item.key}`
                    : `https://ciity-sms.s3.us-west-1.amazonaws.com/${item.thumbnail}`;

                return (
                  <Box
                    key={`${item.key}-${index}`}
                    sx={{
                      position: 'relative',
                      aspectRatio: '1',
                      borderRadius: '10px',
                      overflow: 'hidden',
                      border: '1px solid #E8ECF4',
                      cursor: 'pointer',
                      transition: 'box-shadow 0.15s, transform 0.15s',
                      '&:hover': {
                        boxShadow: '0 4px 16px rgba(0,0,0,0.12)',
                        transform: 'translateY(-1px)',
                        '& .media-overlay': { opacity: 1 },
                      },
                    }}
                    onClick={() => setCurrentIndex(index)}
                  >
                    {/* inner wrapper so MediaComponent fills the cell */}
                    <Box sx={{ width: '100%', height: '100%', '& > *': { width: '100% !important', height: '100% !important' }, '& img': { objectFit: 'cover !important', width: '100% !important', height: '100% !important' } }}>
                      <MediaComponent
                        createAt={item.createdAt}
                        onClick={() => setCurrentIndex(index)}
                        height={150}
                        thumbnail={thumb}
                        url={url}
                        name={item.key}
                        file_name={item.file_name}
                      />
                    </Box>

                    {/* hover overlay */}
                    <Box
                      className="media-overlay"
                      sx={{
                        position: 'absolute',
                        inset: 0,
                        bgcolor: 'rgba(0,0,0,0.25)',
                        opacity: 0,
                        transition: 'opacity 0.15s',
                        borderRadius: '10px',
                        pointerEvents: 'none',
                      }}
                    />
                  </Box>
                );
              })}
            </Box>
          ) : (
            /* ── Empty state ── */
            <Box sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', height: 220, gap: 1.5 }}>
              <CalendarMonth sx={{ fontSize: 52, color: '#D0D7E8' }} />
              <Typography variant="body2" color="text.secondary" fontWeight={600}>
                {hasFilter ? 'No media for this date range' : `No ${mediaType === 'media' ? 'media' : 'documents'} yet`}
              </Typography>
              {hasFilter && (
                <Button size="small" variant="outlined" onClick={clearFilter} sx={{ borderRadius: '8px', textTransform: 'none', fontSize: 12 }}>
                  Clear Filter
                </Button>
              )}
            </Box>
          )}
        </Box>

        {/* ── Pagination ──────────────────────────────────── */}
        {(data?.data?.totalPages ?? 0) > 1 && (
          <Box sx={{ display: 'flex', justifyContent: 'center', py: 1.5, borderTop: '1px solid #E8ECF4', flexShrink: 0 }}>
            <Pagination
              count={data?.data?.totalPages ?? 1}
              page={page}
              color="primary"
              size="small"
              onChange={(_, v) => setPage(v)}
            />
          </Box>
        )}

        {/* ── Document viewer dialog ───────────────────────── */}
        {currentIndex != null && (
          <DocumentDialog
            datetime={data?.data?.media?.[currentIndex]?.createdAt ?? ''}
            open
            onClose={() => setCurrentIndex(null)}
            uploadType={data?.data?.media?.[currentIndex]?.upload_type}
            documentKey={
              data?.data?.media?.[currentIndex]?.key?.split('/')?.[1] === 'video'
                ? data?.data?.media?.[currentIndex]?.key?.split('/')?.[2] ?? ''
                : data?.data?.media?.[currentIndex]?.key?.split('/')?.[1] ?? ''
            }
            moveNext={moveNext}
            movePrev={movePrevious}
            currentIndex={currentIndex}
          />
        )}
      </Box>
    </LocalizationProvider>
  );
}
