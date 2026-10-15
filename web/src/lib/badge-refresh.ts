import type { Dispatch } from '@reduxjs/toolkit';

import { apiSlice } from '@/redux/apiSlice';

type Tag = Parameters<typeof apiSlice.util.invalidateTags>[0][number];

// Coalesces bursts of socket events into one refetch: tags requested within the window are
// invalidated together once, so 20 incoming messages cost 1 request instead of 20.
const WINDOW_MS = 2000;
let pending = new Set<Tag>();
let timer: ReturnType<typeof setTimeout> | null = null;

export function scheduleTagRefresh(dispatch: Dispatch, tags: Tag[]): void {
  tags.forEach((tag) => pending.add(tag));
  if (timer) return;
  timer = setTimeout(() => {
    const flush = Array.from(pending);
    pending = new Set();
    timer = null;
    dispatch(apiSlice.util.invalidateTags(flush));
  }, WINDOW_MS);
}

// Sidebar unread badges (GET channel/activeChannel provides 'channels')
export function scheduleBadgeRefresh(dispatch: Dispatch): void {
  scheduleTagRefresh(dispatch, ['channels']);
}
